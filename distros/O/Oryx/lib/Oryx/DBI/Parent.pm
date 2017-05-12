package Oryx::DBI::Parent;

use SQL::Abstract;
use Scalar::Util qw(blessed);

use base qw(Oryx::Parent);

sub create {
    my ($self, $query, $proto) = @_;

    my $sql = SQL::Abstract->new;
    my $lt_name = $self->link_table;
    my $parent = $self->class->create($proto);
    my %fvals = (lc($self->class->name) => $parent->id);

    unless ($query->{_seen_parents}) {
	# insert a new row in the link table
	$fvals{$self->child_field} = $proto->{id};
	my ($stmnt, @bind) = $sql->insert($lt_name, \%fvals);
	my $sth = $self->dbh->prepare($stmnt);

	$sth->execute(@bind);
	$sth->finish;
	$query->{_seen_parents}++;
    } else {
	# the row in the link table has already been created by
	# another superclass instance, so just update link table
	my %where = ( $self->child_field => $proto->{id} );
	my ($stmnt, @bind) = $sql->update($lt_name, \%fvals, \%where);
	my $sth = $self->dbh->prepare($stmnt);

	$sth->execute(@bind);
	$sth->finish;
    }

}

sub retrieve { }

sub update {
    my ($self, $query, $obj) = @_;
    my $parent = $obj->PARENT($self->class);
    return unless (defined $parent and blessed($parent)); # abstract (no attributes)
    $parent->$_($obj->$_) foreach keys %{$self->class->attributes};
    $parent->update;
}

sub delete {
    my ($self, $query, $obj) = @_;

    my $sql = SQL::Abstract->new;
    my $lt_name = $self->link_table;

    my %where = ($self->child_field => $obj->id);
    my ($stmnt, @bind) = $sql->delete($lt_name, \%where);
    my $sth = $obj->dbh->prepare($stmnt);
    $sth->execute(@bind);
    $sth->finish;

    my $parent = $obj->PARENT($self->class);
    $parent->delete() if $parent;
}

sub search { }

sub construct {
    my ($self, $object) = @_;
    # copy the attribute values from the parent to the child instance

    my $sql = SQL::Abstract->new;
    my $lt_name = $self->link_table;

    my %where  = ($self->child_field => $object->id);
    my @fields = ($self->class->name);
    my ($stmnt, @bind) = $sql->select($lt_name, \@fields, \%where);
    my $sth = $self->dbh->prepare_cached($stmnt);

    $sth->execute(@bind);
    my $row  = $sth->fetch;
    my $parent = $self->class->retrieve( $row->[0] );
    $sth->finish;
    unless (defined $parent) {
        $self->_croak(
            "undefined parent for $object [".$object->id.
            "], you may have a diamond inheritance involving".
            "a common, abstract super class"
        );
    }

    $object->$_($parent->$_) foreach keys %{$self->class->attributes};
    $object->PARENT($self->class, $parent);
}

1;
__END__

=head1 NAME

Oryx::DBI::Parent - DBI implementation of parent relationships

=head1 SYNOPSIS

See L<Oryx::Parent>.

=head1 DESCRIPTION

This is the DBI implementation of Oryx subclassing relationships. If one class extends another, then the implementation in this class manages the loading of the parent information into the child.

=head1 GUTS

This is just a quick run-down of implementation details as of this writing to help introduce users to the database internals. These details may change with future releases and might have changed since this documentation was written.

Each class that subclasses one or more Oryx class will have an additional link table associated with it to identify it's parent records. This class then uses that information to load the class data for each parent into a subclass record upon construction.

=head1 SEE ALSO

L<Oryx>, L<Oryx::Parent>, L<Oryx::DBI>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
