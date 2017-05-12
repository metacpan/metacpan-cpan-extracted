package MooseX::Types::EmailAddress; # -*-perl-*-
use strict;
use warnings;

our $VERSION = '1.1.2';

use Email::Address ();
use Email::Valid   ();

use MooseX::Types -declare => [qw(EmailAddress EmailAddressList)];
use MooseX::Types::Moose qw(Str ArrayRef);

subtype EmailAddress,
  as Str,
  where { Email::Valid->address( -address => $_ ) },
  message { 'Must be a valid email address' };

subtype EmailAddressList,
  as ArrayRef[EmailAddress];

coerce EmailAddressList,
  from Str,
  via { [ map { $_->format } Email::Address->parse($_) ] },
  from ArrayRef,
  via { [ map { $_->format } map { Email::Address->parse($_) } @{$_} ] };

1;
__END__

=head1 NAME

MooseX::Types::EmailAddress - Valid email address type constraint for Moose.

=head1 VERSION

This documentation refers to MooseX::Types::EmailAddress version 1.1.2

=head1 SYNOPSIS

    package FooBar;
    use Moose;
    use MooseX::Types::EmailAddress qw/EmailAddress EmailAddressList/;
    use namespace::autoclean;

    has address  => ( isa => EmailAddress, required => 1, is => "ro" );

    has addrlist => (
         traits    => ["Array"],
         is        => "ro",
         isa       => EmailAddressList,
         coerce    => 1,
         default   => sub { [] },
         handles   => {
            "addr_count" => "count",
         }
     );

=head1 DESCRIPTION

This module provides Moose type constraints for valid email
addresses. There is support for a type which represents a single valid
email address and a type which represents a list of valid email
addresses. The validation is done using the L<Email::Valid> module.

This module is similar to L<MooseX::Types::Email> but deliberately
focuses only on email addresses. This module also provides an
additional type to handle lists of addresses.

=head1 DEPENDENCIES

This module requires L<MooseX::Types> to build the Moose types. It
uses L<Email::Valid> to check if a string is a valid email address. It
also uses L<Email::Address> for parsing and splitting strings which
might contain more than one address into a list.

=head1 SEE ALSO

L<Moose>, L<Moose::Util::TypeConstraints>, L<MooseX::Types::Email>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

If you find a bug please either email the author, or add
the bug to cpan-RT L<http://rt.cpan.org>.

=head1 AUTHOR

Stephen Quinney C<< <squinney@inf.ed.ac.uk> >>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012-2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
