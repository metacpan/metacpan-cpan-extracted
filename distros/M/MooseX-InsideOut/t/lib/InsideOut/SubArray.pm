use strict;
use warnings;

package InsideOut::SubArray;

use MooseX::InsideOut;
extends 'InsideOut::BaseArray';

has sub_foo => ( is => 'rw' );

1;

