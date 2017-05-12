package Reaction::Types::Core;

use MooseX::Types
    -declare => [qw/SimpleStr NonEmptySimpleStr Password StrongPassword
                    NonEmptyStr PositiveNum PositiveInt SingleDigit URI/];

use MooseX::Types::Moose qw/Str Num Int Object/;

subtype SimpleStr,
  as Str,
  where { (length($_) <= 255) && ($_ !~ m/\n/) },
  message { "Must be a single line of no more than 255 chars" };

subtype NonEmptySimpleStr,
  as SimpleStr,
  where { length($_) > 0 },
  message { "Must be a non-empty single line of no more than 255 chars" };

# XXX duplicating constraint msges since moose only uses last message

subtype Password,
  as NonEmptySimpleStr,
  where { length($_) > 3 },
  message { "Must be between 4 and 255 chars" };

subtype StrongPassword,
  as Password,
  where { (length($_) > 7) && (m/[^a-zA-Z]/) },
  message {
       "Must be between 8 and 255 chars, and contain a non-alpha char" };

subtype NonEmptyStr,
  as Str,
  where { length($_) > 0 },
  message { "Must not be empty" };

subtype PositiveNum,
  as Num,
  where { $_ >= 0 },
  message { "Must be a positive number" };

subtype PositiveInt,
  as Int,
  where { $_ >= 0 },
  message { "Must be a positive integer" };

subtype SingleDigit,
  as PositiveInt,
  where { $_ <= 9 },
  message { "Must be a single digit" };

#message will require moose 0.39
class_type 'URI';
#class_type 'URI', message { 'Must be an URI object'};
coerce 'URI', from Str, via { URI->new($_) };

1;

=head1 NAME

Reaction::Types::Core

=head1 SYNOPSIS

=head1 DESCRIPTION

Reaction uses the L<Moose> attributes as a base and adds a few of it's own.

=over

=item * SimpleStr

A Str with no new-line characters.

=item * NonEmptySimpleStr

Does what it says on the tin.

=item * Password

=item * StrongPassword

=item * NonEmptyStr

=item * PositiveNum

=item * PositiveInt

=item * SingleDigit

=back

=head1 SEE ALSO

=over

=item * L<Moose::Util::TypeConstraints>

=item * L<Reaction::Types::DBIC>

=item * L<Reaction::Types::DateTime>

=item * L<Reaction::Types::Email>

=item * L<Reaction::Types::File>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
