package Oryx::DBI::Class;

use SQL::Abstract;

use Oryx::DBI::Association;
use Oryx::DBI::Attribute;
use Oryx::DBI::Method;
use Oryx::DBI::Parent;

use base qw(Oryx::MetaClass);

# Other MetaClass constructs are true instances and save their meta
# data as $self->{meta}. Class meta objects are different because
# their state is saved as class data instead of as instances of the
# MetaClass class.

# make some noise
our $DEBUG = 0;

sub dbh { $_[0]->storage->dbh }

sub create {
    my ($class, $param) = @_;
    my %query = ( table => $class->table );
    $param->{_isa} ||= $class;

    $class->notify_observers('before_create', { param => $param, query => \%query });

    $_->create(\%query, $param) foreach $class->members;

    # grab out the attributes that this class knows about
    my @keys = (keys %{$class->attributes});
    push @keys, '_isa' if $class->is_abstract;
    my $proto = { };
    @$proto{@keys} = @$param{@keys};

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->insert($query{table}, $proto);

    my $sth;
    eval { $sth = $class->dbh->prepare_cached($stmnt) };
    die "ERROR: statement $stmnt $@" if $@;
    $sth->execute(@bind);
    $sth->finish;

    $param->{id} = $class->lastId();
    $proto->{id} = $class->lastId();

    $_->create(\%query, $param) foreach @{$class->parents};
    $class->notify_observers('after_create', { param => $param, proto => $proto });

    return $class->construct($proto);
}

sub retrieve {
    my ($class, $id) = @_;

    # fetch the object from the cache if it exists
    my $key = $class->_mk_cache_key($id);
    my $object;
    return $object if ($object = $Live_Objects{$key});

    my %query = (
        table  => $class->table,
	fields => [ 'id' ],
	where  => { id => $id },
    );

    if ($class->is_abstract) {
	$DEBUG && $class->_carp("ABSTRACT CLASS retrieve $class");
	push @{$query{fields}}, '_isa';
    }
    $DEBUG && $class->_carp("retrieve : id => $id");
    $class->notify_observers('before_retrieve', { query => \%query, id => $id });
    $_->retrieve(\%query, $id) foreach $class->members;
    $_->retrieve(\%query, $id) foreach @{$class->parents};

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->select(@query{
        qw(table fields where order)
    });
    my $sth = $class->dbh->prepare_cached($stmnt);

    eval { $sth->execute(@bind) };
    $class->_croak("execute failed [$stmnt], bind => "
        .join(", ", @bind)." $@") if $@;

    my $values = $sth->fetch;
    $sth->finish;

    if ($values and @$values) {
	my $proto = $class->row2proto($query{fields}, $values);

	if ($class->is_abstract and $proto->{_isa} ne $class) {
	    # abstract classes are never instantiated directly, so we
	    # need to retrieve the decendant instead. The descendant's
	    # ID is the same as the abstract class' ID because we used
	    # the abstract class' sequence when the decendant instance
	    # was created... so no need for a JOIN here
	    $DEBUG>1 && $class->_carp("RETRIEVE subclass : "
                .$proto->{_isa}." for abstract class : $class");
	    eval "use ".$proto->{_isa};
	    $class->_croak($@) if $@;
	    return $proto->{_isa}->retrieve($proto->{id});
	}
        $class->notify_observers('after_retrieve', { proto => $proto });
	return $class->construct($proto);
    } else {
	return undef;
    }
}

sub update {
    my ($self) = @_;
    return if $self->is_abstract;
    my %query = (
	table => $self->table,
	fieldvals => { },
        where => { id => $self->id },
    );
    $self->notify_observers('before_update', { query => \%query });
    $_->update(\%query, $self) foreach $self->members;
    $_->update(\%query, $self) foreach @{$self->parents};

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->update(@query{
        qw(table fieldvals where)
    });
    my $sth = $self->dbh->prepare_cached($stmnt);

    eval { $sth->execute(@bind) };
    $self->_croak("execute failed for $stmnt, bind => "
        .join(", ", @bind)." $@") if $@;

    $sth->finish;

    $self->notify_observers('after_update');
    return $self;
}

sub delete {
    my ($self) = @_;
    my %query = (
	table => $self->table,
        where => { id => $self->id },
    );
    $self->notify_observers('before_delete', { query => \%query });
    $_->delete(\%query, $self) foreach $self->members;
    $_->delete(\%query, $self) foreach @{$self->parents};

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->delete(@query{qw(table where)});
    my $sth = $self->dbh->prepare_cached($stmnt);

    $sth->execute(@bind);
    $sth->finish;

    $self->remove_from_cache;
    $self->notify_observers('after_delete');
    return $self;
}

sub search {
    my ($class, $param, $order, $limit, $offset) = @_;
    my %query = (
	table  => $class->table,
	fields => [ 'id' ],
        where  => $param,
        order  => $order || [ ],
    );
    $limit = -1 unless defined $limit;

    push @{$query{fields}}, '_isa' if $class->is_abstract;

    $class->notify_observers('before_search', {
            query => \%query,
            param => $param,
            order => $order,
            limit => $limit,
        }
    );

    $_->search(\%query) foreach $class->members;
    $_->search(\%query) foreach @{$class->parents};

    my $sql = SQL::Abstract->new(cmp => 'like');
    my ($stmnt, @bind) = $sql->select(@query{
        qw(table fields where order)
    });
    #warn 'SEARCH STATEMENT => '.$stmnt;
    my $sth = $class->dbh->prepare_cached($stmnt);
    $sth->execute(@bind);

    my (@objs, @row);
    if (defined $offset) {
        @row = $sth->fetch while ($offset-- > 0);
    }
    while ($limit-- and (@row = $sth->fetch)) {
	my $proto = $class->row2proto($query{fields}, \@row);
	push @objs, $class->construct($proto);
    }
    $sth->finish;

    $class->notify_observers('after_search', {
            query => \%query,
            param => $param,
            order => $order,
            limit => $limit,
            objects => \@objs
        }
    );

    return @objs;
}

sub row2proto {
    my ($class, $fields, $values) = @_;
    my $proto = { };
    @$proto{ @$fields } = @$values;
    return $proto;
}

sub lastId {
    my $class = shift;
    $class->storage->util->lastval($class->dbh, $class->table);
}


1;
__END__

=head1 NAME

Oryx::DBI::Class - DBI metaclass implementation

=head1 SYNOPSIS

See L<Oryx::Class>.

=head1 DESCRIPTION

This is the DBI implementation of L<Oryx::Class>. This does the majority of the work for an L<Oryx::Class> subclass stored in L<Oryx::DBI> storage.

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>, L<Oryx::DBI>

=head1 AUTHORS

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
