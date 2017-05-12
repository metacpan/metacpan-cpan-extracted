use strict;
use warnings;

package InsideOut::SubMoose;

use MooseX::InsideOut;
extends 'InsideOut::BaseMoose';

has sub_foo => ( is => 'rw' );

1;

