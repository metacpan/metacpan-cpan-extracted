use strict;
use warnings;

package InsideOut::SubHash;

use MooseX::InsideOut;
extends 'InsideOut::BaseHash';

has sub_foo => ( is => 'rw' );

1;
