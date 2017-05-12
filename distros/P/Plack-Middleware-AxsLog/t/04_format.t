use strict;
use warnings;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Builder;
use Plack::Test;
use Test::More;

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', 
            format => 'foo %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"', 
            logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            chomp $log;
            like $log, qr!^foo [a-z0-9\.]+ - - \[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\] "GET / HTTP/1\.1" 200 6 "-" "-"$!;
        };
}

done_testing();

