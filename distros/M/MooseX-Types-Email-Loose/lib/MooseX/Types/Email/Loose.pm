package MooseX::Types::Email::Loose;

use strict;
use warnings;
our $VERSION = '0.01';

use MooseX::Types -declare => [qw{EmailAddress EmailMessage EmailAddressLoose}];
use MooseX::Types::Email ();
use MooseX::Types::Common::String 'NonEmptySimpleStr';
use Email::Valid::Loose;

subtype EmailAddress,
    as MooseX::Types::Email::EmailAddress;

subtype EmailMessage,
    as MooseX::Types::Email::EmailMessage;

subtype EmailAddressLoose,
    as NonEmptySimpleStr,
    where { Email::Valid::Loose->address($_) },
    message { "Must be a valid e-mail address" };

1;
__END__

=head1 NAME

MooseX::Types::Email::Loose - Email address loose validation type constraint for Moose.

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::Types::Email::Loose qw/EmailAddress EmailMessage EmailAddressLoose/;

  has email        => ( isa => EmailAddress,      required => 1, is => 'ro' );
  has message      => ( isa => EmailMessage,      required => 1, is => 'ro' );
  has email_mobile => ( isa => EmailAddressLoose, required => 0, is => 'rw' );

=head1 DESCRIPTION

MooseX::Types::Email::Loose is a subclass of MooseX::Types::Email, which uses Email::Valid::Loose to check for valid email addresses.

=head1 IMPLEMENTATION

This module implements only EmailAddressLoose.

Also can export EmailAddress and EmailMessage, but they are implemented in MooseX::Types::Email.

=head1 AUTHOR

hayajo <hayajo@cpan.org>

=head1 SEE ALSO

L<MooseX::Types::Email>, L<Email::Valid::Loose>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
