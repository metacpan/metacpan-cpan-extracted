
use strict;
use warnings;
no  warnings 'uninitialized';

use Data::Dumper;
use Test::More 'no_plan';

BEGIN { 
    use_ok('Redis::Parser::XS') 
};


foreach ( 
    [ ""         => 0     ],
    [ "\x0d\x0a" => undef ],
    [ "asdf"     => undef ],

) {
    my ($buf, $rv) = @$_;
    my $out = [];
    my $len = parse_redis $buf, $out;

    if ( !defined $rv ) {
        ok  !defined $len,  'undefs'
            or 
                diag Dumper ($out->[0]);
    }


    ok  $len == $rv,   'incompleteness'
        or 
            diag Dumper ($out->[0]);
}



