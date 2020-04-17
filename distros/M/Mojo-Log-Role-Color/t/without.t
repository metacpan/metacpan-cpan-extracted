#!perl
use Mojo::Base -strict;
use Mojo::Log;
use Mojo::Util 'term_escape';
use Test::More;

open my $FH, '>', \my $logged;
my $log = Mojo::Log->with_roles('+Color')->new(handle => $FH, level => 'debug');

$ENV{MOJO_LOG_COLORS} = 0;
$log->debug('Rendering template');
$log->info('Creating process');
$log->warn('Stopping worker');
$log->error('Zero downtime software upgrade failed');
$log->fatal('Boom');

my @logged = split /\r?\n/, $logged;
is @logged, 5, 'logged five times';

for my $line (@logged) {
  like $line, qr{^\[.*\w$}, 'msg:' . term_escape $line;
}

done_testing;
