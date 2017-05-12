use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::App::GitHub::WebHook;

my $app = Plack::App::GitHub::WebHook->new( 
    access => 'all',
    safe => 1,
    hook => sub { die "WTF?!\n"; },
)->to_app;

my $env = req_to_psgi( POST '/', Content => '{}' );
my $errors = "";
open my $fh, ">", \$errors;
$env->{'psgi.errors'} = $fh;

my $res = $app->($env); 
is $errors, "WTF?!\n", "safe mode, catching errors";
is $res->[0], 202, "202 Accept";

$app = Plack::App::GitHub::WebHook->new( 
    access => [ allow => 'all' ],
    hook => sub { die "WTF?!\n"; },
);

$res = $app->($env);
is $res->[0], '500', 'not safe: 500 response';
is $res->[2]->[0], "WTF?!\n", 'not safe: return error';

note explain $res;

done_testing;    
