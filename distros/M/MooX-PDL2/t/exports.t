#! perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test::API;

use MooX::PDL2;

class_api_ok(
    'MooX::PDL2',
    qw[
    new
      ] );

done_testing;




