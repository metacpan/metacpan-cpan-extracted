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
        enable 'AxsLog', ltsv => 1, response_time => 0, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET("/",
                'User-Agent' => 'Plack::Test',
                'Referer' => 'http://example.com/referer'
            ));
            chomp $log;
            my %record = map { split ':', $_, 2 } split "\t", $log;
            like $record{time}, qr!\[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\]!;
            is $record{host}, '127.0.0.1';
            is $record{user}, '-';
            is $record{req}, 'GET / HTTP/1.1';
            is $record{status}, 200;
            is $record{size}, 6;
            is $record{referer}, 'http://example.com/referer';
            is $record{ua}, 'Plack::Test';
            ok ! exists $record{taken}
        };
}

{
    my $log = '';
    my $app = builder {
        enable 'AxsLog', ltsv => 1, response_time => 1, logger => sub { $log .= $_[0] };
        sub{ [ 200, [], [ "Hello "] ] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(GET("/",
                'User-Agent' => 'Plack::Test',
                'Referer' => 'http://example.com/referer'
            ));
            chomp $log;
            my %record = map { split ':', $_, 2 } split "\t", $log;
            like $record{time}, qr!\[\d{2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [+\-]\d{4}\]!;
            is $record{host}, '127.0.0.1';
            is $record{user}, '-';
            is $record{req}, 'GET / HTTP/1.1';
            is $record{status}, 200;
            is $record{size}, 6;
            is $record{referer}, 'http://example.com/referer';
            is $record{ua}, 'Plack::Test';
            ok exists $record{taken}
        };
}

done_testing();

