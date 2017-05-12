package MooseX::ExpiredAttribute::Role::Object;

use Moose::Role;

has '_expiration_time_for_attrs' => (
    is          => 'rw',
    isa         => 'HashRef[Num]',
    predicate   => '_has_expiration_time_for_attrs',
    default     => sub { {} },
);

no Moose::Role;

1;
__END__

=pod

=head1 NAME

MooseX::ExpiredAttribute::Role::Object - the attached role to objects which have expired attributes

=head1 DESCRIPTION

This role to be attached by L<MooseX::ExpiredAttribute> module. You don't need to use it directly.

=head1 SEE ALSO

=over

=item L<MooseX::ExpiredAttribute>

=item L<MooseX::ExpiredAttribute::Role::Meta::Attribute>

=back

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.

=cut
