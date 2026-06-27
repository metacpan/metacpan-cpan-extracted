use strict;
use warnings;

use Test2::V0;
use Future::AsyncAwait;
use FindBin;

use PAGI::App::WrapCGI;

plan skip_all => 'fork not supported'
    unless eval { my $p = fork; defined $p and ($p == 0 ? exit : waitpid($p, 0)); 1 };

my $app = PAGI::App::WrapCGI->new(
    script => "$FindBin::Bin/cgi-bin/env.cgi",
)->to_app;

my @sent;
my $send = sub { my ($msg) = @_; push @sent, $msg; Future->done };
my $receive = sub { Future->done({ type => 'http.request', body => '', more => 0 }) };

$app->({
    type      => 'http',
    method    => 'GET',
    path      => '/info',
    root_path => '/cgi',
    headers   => [],
}, $receive, $send)->get;

is $sent[0]{status}, 200, 'CGI ran';
like $sent[1]{body}, qr/SCRIPT_NAME=\/cgi;/, 'SCRIPT_NAME comes from spec root_path';
like $sent[1]{body}, qr/PATH_INFO=\/info/, 'PATH_INFO from path';

done_testing;
