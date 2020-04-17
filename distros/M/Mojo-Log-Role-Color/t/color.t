#!perl
use Mojo::Base -strict;
use Mojo::Log;
use Mojo::Util 'term_escape';
use Test::More;

open my $FH, '>', \my $logged;
my $log = Mojo::Log->with_roles('+Color')->new(handle => $FH, level => 'debug');

$log->on(
  message => sub {
    my ($log, $level, @lines) = @_;
    my $msg = join ' ', @lines;
    like $msg, qr{^\w.*\w$}, "message event $level has no color";
  }
);

$ENV{MOJO_LOG_COLORS} = 1;
$log->debug('Rendering template');
$log->info('Creating process');
$log->warn('Stopping worker');
$log->error('Zero downtime software upgrade failed');
$log->fatal('Boom');

my @logged = split /\r?\n/, $logged;
is @logged, 5, 'logged five times';

for my $line (@logged) {
  like $line, qr{^\x1b.*\x1b\[0m$}, 'msg:' . term_escape $line;
}

is $log->history->[-1][2], 'Boom', 'history has no colors';

done_testing;
