use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

BEGIN {
    eval "use Test::LeakTrace";
    plan skip_all => 'This test requires Test::LeakTrace' if $@;
}

use Try::Tiny;
use RedisDB::Parser;

no_leaks_ok {
    my $master = {};
    my $parser = RedisDB::Parser->new( master => $master );
    $parser->push_callback( sub { 1 } );
    my $lf = "\015\012";
    $parser->parse( "*3${lf}"
          . "*4${lf}:5${lf}:1336734898${lf}:43${lf}"
          . "*2${lf}\$3${lf}get${lf}\$4${lf}test${lf}"
          . "*4${lf}:4${lf}:1336734895${lf}:175${lf}"
          . "*3${lf}\$3${lf}set${lf}\$4${lf}test${lf}\$2${lf}43${lf}"
          . "*4${lf}:3${lf}:1336734889${lf}:20${lf}"
          . "*2${lf}\$7${lf}slowlog${lf}\$3${lf}len${lf}" );
}
"didn't leak on parsing a complex structure";

no_leaks_ok {
    my $master = {};
    my $parser = RedisDB::Parser->new( master => $master );
    $parser->push_callback( sub { 1 } );
    my $lf = "\015\012";
    try {
        $parser->parse( "*3${lf}"
              . "*4${lf}:5${lf}:1336734898${lf}:43${lf}"
              . "*2${lf}\$3${lf}gets${lf}\$4${lf}tests${lf}" );
        1;
    } and fail "parser didn't die";
}
"didn't leak after throwing exception";

no_leaks_ok {
    my $master = {};
    my $parser = RedisDB::Parser->new( master => $master );
    $parser->push_callback( sub { die "Oops" } );
    my $lf = "\015\012";
    try {
        $parser->parse("\$4${lf}test${lf}");
        1;
    } and fail "callback didn't die";
}
"didn't leak after callback thrown an exception";

no_leaks_ok {
    my $master = {};
    my $parser = RedisDB::Parser->new( master => $master );
    $parser->push_callback( sub { 1 } );
    $parser->propagate_reply( RedisDB::Parser::Error->new("Oops") );
}
"didn't leak after propagating reply";

no_leaks_ok {
    my $master = {};
    my $parser = RedisDB::Parser->new( master => $master );
    $parser->push_callback( sub { 1 } ) for 1 .. 3;
    $parser->parse("+OK");
    $parser->parse("\015\012:123\015");
    $parser->parse("\012\$6\015\012foobar\015\012");
}
"didn't leak after parsing multiple replies";

done_testing;
