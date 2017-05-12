use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

# Prove that 'Static' lines will appears in the app's logfile if plugin configured to 'info' log-level.
#
$ENV{MOJO_LOG_LEVEL} = 'info';  
plugin StaticLog => {level=>'info'};

get '/' => sub { shift->render(text => 'dynamic content') };

my $t = Test::Mojo->new;

# log-intercept technique as seen in mainstream mojo tests..
my $log = '';
$t->app->log->on(message => sub { $log .= pop });

my $msg_re = qr[Static 200    151 /one-eyed.txt];

$t->get_ok('/one-eyed.txt');
like $log, $msg_re, 'The "Static" message is generated at "info" log level';

done_testing();

