#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use overload
    q{+}  => sub { 0 },
    q{""} => sub { 'A' };

use Scalar::In
    string_in  => { -as => 'in' },
    numeric_in => { -as => 'num_in' };

our $VERSION = '0.001';

my $object = bless {}, __PACKAGE__;

() = print
    'eq: ',
    0 + in( $object, 'A' ),
    "\n==: ",
    0 + num_in( $object, 0 ),
    "\n";

# $Id$

__END__

Output:

eq: 1
==: 1
