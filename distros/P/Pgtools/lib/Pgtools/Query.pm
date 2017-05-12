package Pgtools::Query;
use strict;
use warnings;

use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(datname xact_start query_start state query));

1;
