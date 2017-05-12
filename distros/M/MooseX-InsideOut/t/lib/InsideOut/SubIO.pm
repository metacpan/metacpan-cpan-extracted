use strict;
use warnings;

package InsideOut::SubIO;

use MooseX::InsideOut;
extends 'InsideOut::BaseIO';

has sub_foo => ( is => 'rw' );

1;
