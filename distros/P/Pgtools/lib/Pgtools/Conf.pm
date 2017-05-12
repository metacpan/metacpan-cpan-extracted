package Pgtools::Conf;
use strict;
use warnings;

use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(version items));

1;
