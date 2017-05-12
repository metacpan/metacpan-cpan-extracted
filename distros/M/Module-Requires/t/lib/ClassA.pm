package ClassA;
use strict;
use warnings;
our $VERSION = '0.02';

my @params;
sub import { @params = @_ }
sub params { join ', ', @params }
sub package { __PACKAGE__ }
1;
