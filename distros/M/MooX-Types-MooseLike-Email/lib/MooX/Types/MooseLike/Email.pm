package MooX::Types::MooseLike::Email;
use strict;
use warnings;
our $VERSION = '0.03';

use MooX::Types::MooseLike qw/exception_message/;
use MooX::Types::MooseLike::Base;
use Email::Valid;
use Email::Valid::Loose;
use Email::Abstract;
use Exporter qw/import/;
our @EXPORT_OK = ();

my $type_definitions = [
    {
        name       => 'EmailAddress',
        subtype_of => 'Str',
        from       => 'MooX::Types::MooseLike::Base',
        test       => sub { Email::Valid->address($_[0]) },
        message    => sub { return exception_message( $_[0], 'a valid e-mail address' ) },
    },
    {
        name       => 'EmailAddressLoose',
        subtype_of => 'Str',
        from       => 'MooX::Types::MooseLike::Base',
        test       => sub { Email::Valid::Loose->address($_[0]) },
        message    => sub { return exception_message( $_[0], 'a valid e-mail address' ) },
    },
    {
        name       => 'EmailMessage',
        subtype_of => 'Object',
        from       => 'MooX::Types::MooseLike::Base',
        test       => sub { Email::Abstract->new($_[0]) },
        message    => sub { return exception_message( $_[0], 'recognized by Email::Abstract' ) },
    },
];

MooX::Types::MooseLike::register_types($type_definitions, __PACKAGE__, 'MooseX::Types::Email::Loose');
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;
__END__

=head1 NAME

MooX::Types::MooseLike::Email - Email address validation type constraint for Moo.

=head1 SYNOPSIS

  package MyClass;
  use Moo;
  use MooX::Types::MooseLike::Email qw/:all/;

  has 'email'   => ( isa => EmailAddress, is => 'ro', required => 1 );
  has 'message' => ( isa => EmailMessage, is => 'ro', required => 1 );

=head1 DESCRIPTION

MooX::Types::MooseLike::Email is Moo type constraints which uses Email::Valid, Email::Valid::Loose and Email::Abstract to check for valid email addresses and messages.

=head1 TYPES

=head2 EmailAddress

An email address

=head2 EmailAddressLoose

An email address, which allows . (dot) before @ (at-mark)

=head2 EmailMessage

An object, which is a Mail::Internet, MIME::Entity, Mail::Message, Email::Simple or Email::MIME

=head1 TIPS

=over 2

=item * coerce the attribute

  use Scalar::Util qw(blessed);

  has 'message' => (
      is       => 'ro',
      isa      => EmailMessage,
      required => 1,
      coerce   => sub {
          return ( $_[0] and blessed( $_[0] ) and blessed( $_[0] ) ne 'Regexp' )
              ? $_[0]
              : Email::Simple->new( $_[0] );
      },
  );

=back

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<MooX::Types::MooseLike>, L<MooseX::Types::Email>, L<MooseX::Types::Email::Loose>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
