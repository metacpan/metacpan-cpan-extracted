##############################################################################
# Package/use statements
##############################################################################

package Params::Check::Item;

use 5.006;
use strict;
use warnings;

use Carp::Assert qw(assert);
use Scalar::Util qw(blessed looks_like_number);

BEGIN {
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(
    checkNumber
    checkInteger
    checkIndex
    checkClass
    checkNumEQ
    checkNumNEQ
    checkNumLT
    checkNumLTE
    checkOneOf
    checkImpl
  );
  our $VERSION = '0.02';
}

##############################################################################
# private definitions
##############################################################################

sub _report {
  my ($res, $msg) = @_[0..1];
  if($msg) { assert($res, $msg) if !$ENV{PARAMS_CHECK_ITEM_OFF}; } 
  else     { assert($res)       if !$ENV{PARAMS_CHECK_ITEM_OFF}; }
  return 1;
}

##############################################################################
# public definitions 
##############################################################################

sub checkNumber {
  my ($a, $msg) = @_[0..1];
  return _report(looks_like_number($a), $msg);
}

sub checkInteger {
  my ($a, $msg) = @_[0..1];
  return _report(($a =~ /^-?\d+$/) || 0, $msg);
}

sub checkIndex {
  my ($a, $msg) = @_[0..1];
  return _report(($a =~ /^\d+$/) || 0, $msg);
}

sub checkClass {
  my ($arg, $type, $msg) = @_[0..2];
  _report((blessed($arg) && $arg->isa($type)), $msg);
}

sub checkNumEQ {
  my ($a, $b, $msg) = @_[0..2];
  _report($a == $b, $msg);
}

sub checkNumNEQ {
  my ($a, $b, $msg) = @_[0..2];
  _report($a != $b, $msg);
}

sub checkNumLT {
  my ($a, $b, $msg) = @_[0..2];
  _report($a < $b, $msg);
}

sub checkNumLTE {
  my ($a, $b, $msg) = @_[0..2];
  _report($a <= $b, $msg);
}

sub checkOneOf {
  my ($a, $listRef, $msg) = @_[0..2];
  _report(scalar(grep(/^$a$/, @{$listRef})), $msg);
}

sub checkImpl {
  my ($msg) = ($_[0] || "");
  _report(0, "Not Implemented: $msg");
}

1; # End of Params::Check::Item

##############################################################################
# Perldoc 
##############################################################################

=head1 NAME

Params::Check::Item - checks the type or value of an item at any point
during execution

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Params::Check::Items exports a bunch of utility functions for checking the
values of items through Carp::Assert. It is different than other parameter
checking modules since it has low configuration overhead and you are
expected to check one parameter at a time, instead of creating a giant hash
of all the valid values for all the parameters, such as Params::Check.
All exported functions optionally take in a message parameter at the end
that is displayed if Carp::Assert fails. 

If you would like to disable the checks, you must set the environment 
variable PARAMS_CHECK_ITEM_OFF=1. Note that this can be toggled on and
off during runtime.

An example:

    use Params::Check::Item;
    sub myFunc {
      my ($row, $col, $matrix) = @_[0..2];
      checkIndex($row, "row not an index");
      checkIndex($col, "col not an index");
      checkClass($matrix, "My::Matrix::Type", "invalid matrix");
      $matrix->get($row, $col);
    }

=head1 SUBROUTINES

All exported subroutines take in an optional string message, [MSG], 
to display on failure. Addtionally, the subroutines will not perform the
check if the environment variable PARAMS_CHECK_ITEM_OFF is set.

=head2 checkNumber NUM,[MSG]

checks that NUM is numeric type

=head2 checkInteger NUM,[MSG]

checks that NUM is an integer

=head2 checkIndex NUM,[MSG]

checks that NUM is a valid index (e.g., 0,1,2,3...)

=head2 checkClass OBJECT,CLASSNAME,[MSG]

checks that OBJECT is a blessed object from class of name CLASSNAME

=head2 checkNumEQ NUM1,NUM2,[MSG]

checks that NUM1 == NUM2

=head2 checkNumNEQ NUM1,NUM2,[MSG]

checks that NUM1 != NUM2

=head2 checkNumLT NUM1,NUM2,[MSG]
 
checks that NUM1 < NUM2

=head2 checkNumLTE NUM1,NUM2,[MSG]

checks that NUM1 <= NUM2

=head2 checkOneOf ITEM,ARRAYREF,[MSG]

checks that simple item ITEM is present in the array referenced by
ARRAYREF. This simply performs string comparison. It must be an exact
match with one of the items in the array to pass.

=head2 checkImpl [MSG]

simply fails and says "Not Implemented: [MSG]". good for stubbing out
functions.

=head1 SEE ALSO

  Params::Check

=head1 AUTHOR

Samuel Steffl, C<sam@ssteffl.com>

=head1 BUGS

Please report any bugs or feature requests through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Check-Item>.
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Params::Check::Item

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Samuel Steffl.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

