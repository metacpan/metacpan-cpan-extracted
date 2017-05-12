#!perl
use strict;
use warnings;
use 5.010;
use Test::Most;
use Data::Printer;
use Net::Async::Webservice::Common::SyncAgentWrapper;
use HTTP::Request;
use HTTP::Response;

{package TestUA;
    use Moo;
    has last_call => ( is => 'rw' );
    has next_result => ( is => 'rw' );
    has _ssl_opts => ( is => 'rw' );
    sub request {
        my ($self,$req) = @_;

        $self->last_call($req);
        return $self->next_result;
    }
    sub get {}
    sub post {}
    sub ssl_opts {
        my ($self,%opts) = @_;
        $self->_ssl_opts(\%opts);
    }
};

my $success_res = HTTP::Response->new(200,'ok',[],'foo');
my $fail_res = HTTP::Response->new(400,'bad',[],'ugh');

my $ua = TestUA->new;
my $wua = Net::Async::Webservice::Common::SyncAgentWrapper->new({ua=>$ua});

subtest 'just request' => sub {
    $ua->next_result($success_res);
    my $f = $wua->do_request(
        request => HTTP::Request->new(GET=>'/foo'),
    );
    ok($f->is_done,'success');
    cmp_deeply($f->get, $success_res, 'response ok');
};

subtest '"fail" request' => sub {
    $ua->next_result($fail_res);
    my $f = $wua->do_request(
        request => HTTP::Request->new(GET=>'/foo'),
    );
    ok($f->is_done,'success');
    cmp_deeply($f->get, $fail_res, 'response ok');
};

subtest '"fail" request, actual fail' => sub {
    $ua->next_result($fail_res);
    my $f = $wua->do_request(
        request => HTTP::Request->new(GET=>'/foo'),
        fail_on_error => 1,
    );
    ok(scalar($f->failure),'failed');
    cmp_deeply([$f->failure],
               ['400 bad','http',$fail_res,all(
                   isa('HTTP::Request'),
                   methods(
                       uri => str('/foo'),
                       method => 'GET',
                   ),
               )],
               'failure ok');
};

subtest 'building the request' => sub {
    $ua->next_result($success_res);

    my $f = $wua->do_request(
        uri => 'http://normal.name/path?query',
        method => 'POST',
        content_type => 'application/x-dakkar',
        content => 'random bytes',
        user => 'dakkar',
        pass => 'not-really',
    );
    ok($f->is_done,'success');
    cmp_deeply($f->get, $success_res, 'response ok');

    cmp_deeply($ua->last_call,
               all(
                   isa('HTTP::Request'),
                   methods(
                       method => 'POST',
                       uri => str('http://normal.name/path?query'),
                       protocol => 'HTTP/1.1',
                       headers => methods(
                           content_type => 'application/x-dakkar',
                           authorization_basic => 'dakkar:not-really',
                           ['header','Host'] => 'normal.name',
                       ),
                       content => 'random bytes',
                   ),
               ),
               'request ok');
};

subtest 'SSL' => sub {
    $ua->next_result($success_res);
    my $f = $wua->do_request(
        request => HTTP::Request->new(GET=>'/foo'),
        SSL_something => 12,
    );
    ok($f->is_done,'success');
    cmp_deeply($f->get, $success_res, 'response ok');
    cmp_deeply($ua->_ssl_opts,
               { SSL_something => 12 },
               'SSL options set');
};

done_testing;
