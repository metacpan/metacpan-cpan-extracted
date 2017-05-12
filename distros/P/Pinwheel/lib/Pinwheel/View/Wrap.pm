package Pinwheel::View::Wrap;

use strict;
use warnings;

use Pinwheel::View::Wrap::Array;
use Pinwheel::View::Wrap::Scalar;

our $array = bless({}, 'Pinwheel::View::Wrap::Array');
our $scalar = bless({}, 'Pinwheel::View::Wrap::Scalar');


1;
