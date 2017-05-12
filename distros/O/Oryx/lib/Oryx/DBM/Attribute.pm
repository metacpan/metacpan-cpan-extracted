package Oryx::DBM::Attribute;

use Oryx::Value;

use base qw(Oryx::Attribute);

sub create {
    my ($self, $proto) = @_;
    my $attr_name = $self->name;
    $proto->{$attr_name} = $self->deflate($proto->{$attr_name});
}

sub update {
    my ($self, $proto, $object) = @_;
    my $attr_name = $self->name;
    my $value = $object->$attr_name;
    $proto->{$attr_name} = $self->deflate($value);
}

1;
__END__

=head1 NAME

Oryx::DBM::Attribute - DBM implementation of attributes

=head1 SYNOPSIS

See L<Oryx::Attribute>.

=head1 DESCRIPTION

While the L<Oryx::Value> classes ensure that serialization is handled properly, this class actually stores attribute data into the DBM database.

=head1 SEE ALSO

L<Oryx>, L<Oryx::DBM>, L<Oryx::Attribute>, L<Oryx::Value>

=head1 AUTHOR

Richard Hundt E<lt>richard NO SPAM AT protea-systems.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 Richard Hundt.

This library is free software and may be used under the same terms as Perl itself.

=cut
