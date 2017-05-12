package Reaction::Types::Email;

use MooseX::Types
    -declare => [qw/EmailAddress/];

use Reaction::Types::Core 'NonEmptySimpleStr';
use Email::Valid;

subtype EmailAddress,
  as NonEmptySimpleStr,
  where { Email::Valid->address($_) },
  message { "Must be a valid e-mail address" };

1;

=head1 NAME

Reaction::Types::Email

=head1 DESCRIPTION

=over 

=item * EmailAddress

=back

=head1 SEE ALSO

=over 

=item * L<Reaction::Types::Core>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
