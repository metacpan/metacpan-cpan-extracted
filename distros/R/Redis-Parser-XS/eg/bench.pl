
use strict;
use warnings;
no  warnings 'uninitialized';

use Benchmark qw(:all);

use Protocol::Redis::XS;
use Redis::Parser::XS;

my $CRLF = "\x0d\x0a";

my $status    = "+OK"    . $CRLF  ;
my $multibulk = "*2"     . $CRLF .
                "\$5"    . $CRLF .
                "test1"  . $CRLF .
                "\$5"    . $CRLF .
                "test2"  . $CRLF  ;


my $redis = Protocol::Redis::XS->new(api => 1);
$redis->on_message (sub { });
my @out;
my $buf;

sub compete {
    cmpthese -1, {

        'Protocol::Redis::XS' => 
            sub { $redis->parse($buf); },

        'Redis::Parser::XS'   => 
            sub { @out = ();
                  parse_redis ($buf, \@out); }
    };
}

print "Status reply\n";
$buf = $status;

compete();

print "Multibulk reply\n";
$buf = $multibulk;

compete();
