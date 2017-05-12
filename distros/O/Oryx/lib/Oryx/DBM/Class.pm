package Oryx::DBM::Class;

use DBM::Deep;
use Oryx::DBM::Association;
use Oryx::DBM::Attribute;
use Oryx::DBM::Method;
use Oryx::DBM::Parent;
use Carp;

use base qw(Oryx::MetaClass);

our $DEBUG = 0;

__PACKAGE__->mk_classdata('_dbm');

sub dbh { $_[0]->storage }

sub dbm {
    my $class = ref $_[0] || $_[0];
    unless ($class->_dbm) {
	Carp::confess('no catalog entry for table : '.$class->table)
	    unless defined $class->dbh->catalog->get($class->table);
	$class->_dbm(
	    DBM::Deep->new(%{ $class->dbh->catalog->get($class->table) })
        );
    }
    $class->_dbm;
}

sub create {
    my ($class, $param) = @_;

    $param->{id} = $class->nextId();
    $param->{_isa} ||= $class;

    $class->notify_observers('before_create', { param => $param });
    $_->create($param) foreach $class->members;
    $_->create($param) foreach @{$class->parents};

    # grab out the attributes that this class knows about
    my @keys = ('id', keys %{$class->attributes});
    push @keys, '_isa' if $class->is_abstract;
    push @keys, '_parent_ids' if @{ $class->parents };

    my $proto = { };
    @$proto{@keys} = @$param{@keys};

    $class->dbm->push( $proto );

    $class->notify_observers('after_create', { param => $param, proto => $proto });

    return $class->construct($proto);
}

sub retrieve {
    my ($class, $id) = @_;

    # fetch the object from the cache if it exists
    my $key = $class->_mk_cache_key($id);
    my $object;
    return $object if ($object = $Live_Objects{$key});

    $DEBUG && $class->_carp("retrieve : id => $id");
    my $proto = $class->dbm->get( $id );
    return undef unless $proto;
    $proto = $proto->export;

    $class->notify_observers('before_retrieve', { proto => $proto, id => $id });
    $_->retrieve($proto, $id) foreach $class->members;
    $_->retrieve($proto, $id) foreach @{$class->parents};

    if ($proto) {
	if ($class->is_abstract and $proto->{_isa} ne $class) {
	    # abstract classes are never instantiated directly, so we
	    # need to retrieve the decendant instead. The descendant's
	    # ID is the same as the abstract class' ID because we used
	    # the abstract class' sequence when the decendant instance
	    # was created...
	    $DEBUG>1 && $class->_carp("RETRIEVE subclass : "
                .$proto->{_isa}." for abstract class : $class");
	    eval "use ".$proto->{_isa};
	    $class->_croak($@) if $@;
	    return $proto->{_isa}->retrieve($proto->{id});
	}
        $class->notify_observers('after_retrieve', { proto => $proto, id => $id });
	return $class->construct($proto);
    } else {
	return undef;
    }
}

sub update {
    my ($self) = @_;
    return if $self->is_abstract;

    #$self->dbm->lock;

    my $proto = $self->dbm->get( $self->id );
    return undef unless $proto;
    $proto = $proto->export;

    $self->notify_observers('before_update', { proto => $proto });
    $_->update($proto, $self) foreach $self->members;
    $_->update($proto, $self) foreach @{$self->parents};
    $self->dbm->put( $self->id, $proto );

    $self->notify_observers('after_update');
    #$self->dbm->unlock;

    return $self;
}

sub delete {
    my ($self) = @_;
    my $proto = $self->dbm->get( $self->id )->export;
    $self->notify_observers('before_delete', { proto => $proto });
    $_->delete($proto, $self) foreach $self->members;
    $_->delete($proto, $self) foreach @{$self->parents};
    $self->dbm->delete($self->id);
    $self->remove_from_cache;
    $self->notify_observers('after_delete');
    return $self;
}

sub search {
    my ($class, $param, $order, $limit, $offset) = @_;
    $class->notify_observers('before_search', {
            param => $param,
            order => $order,
            limit => $limit
        }
    );

    my ($found, @objs);
    SEARCH: foreach my $proto (@{ $class->dbm }) {
        next unless defined $proto->{id};

	$found = 1;
	foreach my $field (keys %$param) {
	    next SEARCH if ref $proto->{$field};

	    my $value = $param->{$field};
	    $value =~ /%?([^%]*)%?/;
	    unless ($proto->{$field} =~ /$1/) {
		$found = 0;
	    }
	}
	push @objs, $class->construct($proto->export) if $found;
    }
    if ($order) {
        foreach my $field (@$order) {
            @objs = sort {
                $a->$field cmp $b->$field
            } @objs;
        }
    }

    shift @objs while ( $offset-- > 0 );
    pop   @objs while ( defined $limit and (@objs > $limit) );

    $class->notify_observers('after_search', {
            param => $param,
            order => $order,
            limit => $limit,
            objects => \@objs
        }
    );
    return @objs;
}

# next id in sequence
sub nextId {
    my $nextId = $_[0]->dbm->length;
    $DEBUG && $_[0]->_carp("next id => $nextId");
    return $nextId;
}

1;
__END__

=head1 NAME

Oryx::DBM::Class - DBM implementation of Oryx metaclasses

=head1 SYNOPSIS

See L<Oryx::Class>.

=head1 DESCRIPTION

When an Oryx metaclass is stored via L<Oryx::DBM> storage connection, the implementation in this class is used to implement data storage.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBM>, L<Oryx::Class>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
