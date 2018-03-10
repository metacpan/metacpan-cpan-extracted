use strict;
use warnings;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;
use Plack::ServerTiming;

my $app = builder {
    enable "ServerTiming";
    sub {
        my $env = shift;
        my $t = Plack::ServerTiming->new($env);
        $t->record_timing('miss');
        $t->record_timing('db', {dur  => 53});
        $t->record_timing('dc', {desc => 'atl'});
        $t->record_timing('da', {dur => 99, desc => 'A B C'});
        return [200, ['Content-Type'=>'text/html'], ["Hello"]];
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    is $res->header('Server-Timing'), 'miss, db;dur=53, dc;desc=atl, da;dur=99;desc="A B C"';
};

done_testing;
