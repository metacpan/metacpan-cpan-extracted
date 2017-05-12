#!perl
use strict;
use warnings;
use 5.010;
use Test::Most;
use Data::Printer;
use HTTP::Request;
use HTTP::Response;

{package TestUA;
    use Moo;
    use Future;
    has last_call => ( is => 'rw' );
    has next_result => ( is => 'rw' );
    sub do_request {
        my ($self,%call) = @_;

        $self->last_call(\%call);
        my ($kind,@args) = @{$self->next_result};
        return Future->new->$kind(@args);
    }
};

{package TestPkg;
    use Moo;

    has user_agent => ( is => 'ro' );
    with 'Net::Async::Webservice::Common::WithRequestWrapper';
};

my $ua = TestUA->new();
my $t = TestPkg->new({user_agent=>$ua});

ok($t->can('request'),'methods installed');

subtest 'GET request' => sub {
    $ua->next_result([
        'done',
        HTTP::Response->new(200,'ok',[],'some content'),
    ]);
    my $f = $t->get('/foo');
    cmp_deeply($ua->last_call,
               {
                   request => all(
                       isa('HTTP::Request'),
                       methods(
                           uri => str('/foo'),
                           method => 'GET',
                       ),
                   ),
                   fail_on_error => 1,
               },
               'request ok')
        or diag p $ua->last_call;
    ok($f->is_done,'success');
    cmp_deeply($f->get,
               'some content',
               'correct output');
};

subtest 'POST request, HTTP fail' => sub {
    $ua->next_result([
        'fail',
        '404 bad','http',
        HTTP::Response->new(404,'bad',[],''),
    ]);
    my $f = $t->post('/bar','some content');
    cmp_deeply($ua->last_call,
               {
                   request => all(
                       isa('HTTP::Request'),
                       methods(
                           uri => str('/bar'),
                           method => 'POST',
                           content => 'some content',
                       ),
                   ),
                   fail_on_error => 1,
               },
               'request ok')
        or diag p $ua->last_call;
    ok(scalar($f->failure),'failure');
    cmp_deeply([$f->failure],
               [all(
                   isa('Net::Async::Webservice::Common::Exception::HTTPError'),
                   methods(
                       request => $ua->last_call->{request},
                       response => all(
                           isa('HTTP::Response'),
                           methods(
                               code => 404,
                               message => 'bad',
                           ),
                       ),
                       more_info => '',
                   ),
               ),'webservice'],
               'correct exception')
        or diag p $f->failure;
};

subtest 'raw request, other fail' => sub {
    $ua->next_result([
        'fail',
        'random failure',
    ]);
    my $f = $t->request(HTTP::Request->new(HEAD=>'/baz'));
    cmp_deeply($ua->last_call,
               {
                   request => all(
                       isa('HTTP::Request'),
                       methods(
                           uri => str('/baz'),
                           method => 'HEAD',
                       ),
                   ),
                   fail_on_error => 1,
               },
               'request ok')
        or diag p $ua->last_call;
    ok(scalar($f->failure),'failure');
    cmp_deeply([$f->failure],
               [all(
                   isa('Net::Async::Webservice::Common::Exception::HTTPError'),
                   methods(
                       request => $ua->last_call->{request},
                       response => undef,
                       more_info => 'random failure',
                   ),
               ),'webservice'],
               'correct exception')
        or diag p $f->failure;
};

my $has_ssl = eval "require IO::Socket::SSL";

subtest 'SSL' => sub {
    $ua->next_result([
        'done',
        HTTP::Response->new(200,'ok',[],'some content'),
    ]);
    my $f = $t->get('https://foo/');
    cmp_deeply($ua->last_call,
               {
                   request => all(
                       isa('HTTP::Request'),
                       methods(
                           uri => str('https://foo/'),
                           method => 'GET',
                       ),
                   ),
                   ( $has_ssl ? ( SSL_verify_mode => ignore() ) : () ),
                   fail_on_error => 1,
               },
               'request ok')
        or diag p $ua->last_call;
};

subtest 'SSL, custom options' => sub {
    my $t2 = TestPkg->new({user_agent=>$ua,ssl_options=>{SSL_something=>12}});
    $ua->next_result([
        'done',
        HTTP::Response->new(200,'ok',[],'some content'),
    ]);
    my $f = $t2->get('https://foo/');
    cmp_deeply($ua->last_call,
               {
                   request => all(
                       isa('HTTP::Request'),
                       methods(
                           uri => str('https://foo/'),
                           method => 'GET',
                       ),
                   ),
                   SSL_something => 12,
                   fail_on_error => 1,
               },
               'request ok')
        or diag p $ua->last_call;
};

done_testing;
