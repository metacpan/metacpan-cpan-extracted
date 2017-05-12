#!/usr/bin/perl -c

package Exception::Assertion;

=head1 NAME

Exception::Assertion - Thrown when assertion failed

=head1 SYNOPSIS

  use Exception::Assertion;

  sub assert_foo {
      my $self = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__;
      my ($condition, $message) = @_;
      Exception::Assertion->throw(
          message => $message,
          reason  => 'foo failed',
      ) unless $condition;
  }

  assert_foo( 0, 'assert_foo failed' );

=head1 DESCRIPTION

This class extends standard L<Exception::Base> and is thrown when assertion is
failed.  It contains additional attribute C<reason> which represents detailed
message about reason of failed assertion.  The exception has also raised
verbosity.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0504';


=head1 INHERITANCE

=over 2

=item *

extends L<Exception::Base>

=back

=cut

# Extend Exception::Base class
BEGIN {


=head1 CONSTANTS

=over

=item ATTRS : HashRef

Declaration of class attributes as reference to hash.

See L<Exception::Base> for details.

=back

=head1 ATTRIBUTES

This class provides new attributes.  See L<Exception::Base> for other
descriptions.

=over

=cut

    my %ATTRS = ();
    my @ATTRS_RW = ();


=item reason : Str

Contains the additional message filled by assertion method.

=cut

    push @ATTRS_RW, 'reason';


=item message : Str = "Unknown assertion failed"

Contains the message of the exception.  This class overrides the default value
from L<Exception::Base> class.

=cut

    $ATTRS{message} = 'Unknown assertion failed';


=item verbosity : Int = 3

The default verbosity for assertion exception is raised to 3.  This class
overrides the default value from L<Exception::Base> class.

=cut

    $ATTRS{verbosity} = 3;


=item string_attributes : ArrayRef[Str] = ["message", "reason"]

Meta-attribute contains the format of string representation of exception
object.  This class overrides the default value from L<Exception::Base>
class.

=back

=cut

    $ATTRS{string_attributes} = [ 'message', 'reason' ];


    use Exception::Base 0.21;
    Exception::Base->import(
        'Exception::Assertion' => {
            has   => { rw => \@ATTRS_RW },
            %ATTRS,
        },
    );
};


1;


=begin umlwiki

= Class Diagram =

[                    <<exception>>
                  Exception::Assertion
 ----------------------------------------------------------
 +message : Str = "Unknown assertion failed"
 +verbosity : Int = 3
 +reason : Str {rw}
 #string_attributes : ArrayRef[Str] = ["message", "reason"]
 ----------------------------------------------------------]

[Exception::Assertion] ---|> [Exception::Base]

=end umlwiki

=head1 SEE ALSO

L<Exception::Base>, L<Test::Assertion>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
