use 5.10.1;
use strict;
use warnings;


$SIG{__WARN__} = sub { die @_ };


use Test::Synopsis;

all_synopsis_ok();
