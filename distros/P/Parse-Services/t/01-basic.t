#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Parse::Services qw(parse_services);

my $content = <<'_';
# Network services, Internet style
#

tcpmux          1/tcp                           # TCP port service multiplexer
echo            7/tcp
echo            7/udp
discard         9/tcp           sink null
systat          11/tcp          users

# comment
rlp             39/udp          resource        # resource location
_

is_deeply(
    parse_services(content => $content),
    [200, "OK", [
        {name=>'tcpmux' , port=> 1, proto=>'tcp', aliases=>[]},
        {name=>'echo'   , port=> 7, proto=>'tcp', aliases=>[]},
        {name=>'echo'   , port=> 7, proto=>'udp', aliases=>[]},
        {name=>'discard', port=> 9, proto=>'tcp', aliases=>['sink','null']},
        {name=>'systat' , port=>11, proto=>'tcp', aliases=>['users']},
        {name=>'rlp'    , port=>39, proto=>'udp', aliases=>['resource']},
    ]]
);

done_testing;
