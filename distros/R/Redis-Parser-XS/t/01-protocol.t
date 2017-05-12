
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


foreach (@IN) {
    my ($buf, $reply) = @$_;
    my $out = [];
    my $len = parse_redis $buf, $out;

    is         $len, length ($buf),     'length';
    is_deeply  $out, [ $reply ],        'reply'
        or 
            diag Dumper ($out->[0], $reply), 
                BAIL_OUT('');
}

{
    my $buf = join('', map { $_->[0] } @IN);
    my $out = [];
    my $len = parse_redis ($buf, $out);

    my $reply = [ map { $_->[1] } @IN ];
   
    is         $len, length ($buf),     'length';
    is_deeply  $out, $reply,            'reply'
        or 
            diag Dumper ($out, $reply),
                BAIL_OUT('');
}

{
    my $buf = join('', map { $_->[0] } reverse @IN);
    my $out = [];
    my $len = parse_redis ($buf, $out);

    my $reply = [ map { $_->[1] } reverse @IN ];
   
    is         $len, length ($buf),     'length';
    is_deeply  $out, $reply,            'reply'
        or 
            diag Dumper ($out, $reply),
                BAIL_OUT('');
}


foreach (@IN) {
    for my $i (0 .. length($_->[0]) - 1) {
        my $buf = substr($_->[0], 0, $i);
        my $out = [];
        my $len = parse_redis $buf, $out;

        $buf =~ s/\x0d/`r/g;
        $buf =~ s/\x0a/`n/g;

        ok  $len == 0,   'incompleteness'
            or 
                diag Dumper ($_, length($_->[0]), $i, $buf, $out),
                    BAIL_OUT('');
    }
}



