package Oryx::DBM::Parent;

use Scalar::Util qw(blessed);

use base qw(Oryx::Parent);

sub create {
    my ($self, $param) = @_;
    my $parent = $self->class->create($param);
    $param->{_parent_ids} = { } unless defined $param->{_parent_ids};
    $param->{_parent_ids}->{$self->class} = $parent->id;
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
    my $parent = $obj->PARENT($self->class);
    $parent->delete() if $parent;
}

sub search { }

sub construct {
    my ($self, $obj) = @_;
    my $parent = $self->class->retrieve($obj->{_parent_ids}->{$self->class});

    # copy the attribute values from the parent to the child instance
    $obj->$_($parent->$_) foreach keys %{$self->class->attributes};
    $obj->PARENT($self->class, $parent);
}

1;
__END__

=head1 NAME

Oryx::DBM::Parent - DBM implementation of parent relationships

=head1 SYNOPSIS

See L<Oryx::Parent>.

=head1 DESCRIPTION

This class contains the implementation used whenever one Oryx metaclass subclasses another over an L<Oryx::DBM> storage connection.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBM>, L<Oryx::Parent>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
