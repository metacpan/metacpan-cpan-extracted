use Mojo::Base -strict;
use Test::More;

use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Mojo::File 'path';
use Mojolicious;
use Mojolicious::Plugin::Log::Timestamp;

my $dir = tempdir CLEANUP => 1;
my $file = catfile $dir, 'test.log';
my $app = Mojolicious->new;
my $plugin = Mojolicious::Plugin::Log::Timestamp->new;

$plugin->register($app => {pattern => 'xxx', path => $file});
my $log = path($file)->slurp;
like $log, qr{xxx\[debug\] }, q{right message using pattern};

$app->log->pattern('%y%m%d%H%M%S');
$app->log->info('Z');
$log = path($file)->slurp;
like $log, qr{\b\d{12}\[info\] Z}, q{right message using datetime};

done_testing();
