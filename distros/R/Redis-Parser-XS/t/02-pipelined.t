
use strict;
use warnings;
no  warnings 'uninitialized';

use Data::Dumper;
use Test::More 'no_plan';

BEGIN { 
    use_ok('Redis::Parser::XS') 
};


my $CRLF = "\x0d\x0a";

my @IN = (
    [ "+OK"        . $CRLF  => [ '+', 'OK'    ] ],
    [ "-ERROR"     . $CRLF  => [ '-', 'ERROR' ] ], 
    [ "\$-1"       . $CRLF  => [ '$', undef   ] ], 
    [ "*-1"        . $CRLF  => [ '*', undef   ] ], 
    [ "*0"         . $CRLF  => [ '*', []      ] ], 

    [ "\$0"        . $CRLF .
                     $CRLF  => [ '$', ''      ] ], 

    [ "*1"         . $CRLF .
      "\$6"        . $CRLF .
      "foobar"     . $CRLF  => [ '*', ['foobar'] ] ], 

    [ "*2"         . $CRLF .
      "\$3"        . $CRLF .
      "bar"        . $CRLF .
      "\$4"        . $CRLF .
      "fooo"       . $CRLF  => [ '*', ['bar', 'fooo'] ] ], 

    [ "*3"         . $CRLF .
      "\$3"        . $CRLF .
      "bar"        . $CRLF .
      "\$-1"       . $CRLF .
      "\$4"        . $CRLF .
      "fooo"       . $CRLF  => [ '*', ['bar', undef, 'fooo'] ] ], 

    [ "*4"         . $CRLF .
      "\$3"        . $CRLF .
      "bar"        . $CRLF .
      ":123"       . $CRLF .
      "\$-1"       . $CRLF .
      "\$4"        . $CRLF .
      "fooo"       . $CRLF  => [ '*', ['bar', [':', '123'], undef, 'fooo'] ] ], 

    [ "*5"         . $CRLF .
      "\$3"        . $CRLF .
      "bar"        . $CRLF .
      "-ERR"       . $CRLF .
      "+OK"        . $CRLF .
      "\$-1"       . $CRLF .
      "\$4"        . $CRLF .
      "fooo"       . $CRLF  => [ '*', ['bar', ['-', 'ERR'], ['+', 'OK'], 
                                undef, 'fooo'] ] ], 


);


for my $size (1..50) {
    my $data = join('', map { $_->[0] } reverse @IN);
    my $out = [];
    my $buf;
    my $len;

  LOOP: 
    while (length($data) > 0) {
        $buf .= substr($data, 0, $size, '');

        while (1) {
            $len = parse_redis ($buf, $out)
                or 
                    last LOOP;

            if ($len == 0) {
                last;
            } 

            $buf = substr($buf, $len);
        }
    }

    my $reply = [ map { $_->[1] } reverse @IN ];

    ok  length ($buf) == 0,    'parsed entire buffer'
        or
            diag ($buf), BAIL_OUT('');
   
    is_deeply  $out, $reply,   'reply'
        or 
            diag Dumper ($out, $reply), BAIL_OUT('');
}

