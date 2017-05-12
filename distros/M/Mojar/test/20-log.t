use Mojo::Base -strict;

use Test::More;
use File::Spec::Functions 'catdir';
use File::Temp 'tempdir';
my $dir;
BEGIN {
  $dir = tempdir CLEANUP => 1;
  $bp02R_77tM::dir = tempdir CLEANUP => 1;
}
use Mojar::Log (
  level => 'debug',
  path => catdir $dir, 'm.log'
);
use Mojo::File 'path';

subtest q{Basic} => sub {
  my $path = catdir $dir, 'c.log';
  ok my $log = Mojar::Log->new(level => 'error', path => $path), 'new';
  is $log->level, 'error', 'expected level';
  is $log->path, $path, 'expected path';
  $log->error('An error');
  ok -f $path, 'log file exists';
  ok -s $path, 'log file contains something';

  ok $log->level('warn')->info('INFO')->warn('Chained WARN'), 'Chainable';
  my $content = path($path)->slurp;
  like $content, qr/\[error\] An error/, 'contains expected string';
  like $content, qr/^\d{4}\d{2}\d{2} \d\d:\d\d:\d\d\[error/,
      'uses expected timestamp pattern';

  $log->pattern('[%F %H:%M:%S]');
  $log->fatal('Terminal');
  $content = path($path)->slurp;
  like $content, qr/\[\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d\]\[fatal\] Terminal/,
      'uses expected timestamp pattern';

  unlike $content, qr/\bINFO\b/, 'omitted info';
  like $content, qr/\bChained WARN\b/, 'chained warn';
};

subtest q{Helper} => sub {
  my $path = catdir $bp02R_77tM::dir, 'i.log';
  my $o = bp02R_77tM->new;
  my $log = $o->log;
  is $log->level, 'info', 'expected level';
  is $log->path, $path, 'expected path';
  $log->info('A message');
  ok -f $path, 'log file exists';
  ok -s $path, 'log file contains something';
  my $content = path($path)->slurp;
  like $content, qr/\[info\] A message/, 'contains expected string';

  $log->pattern('[%F %H:%M:%S]');
  $log->fatal('Terminal');
  $content = path($path)->slurp;
  like $content, qr/\[\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d\]\[fatal\] Terminal/,
      'uses expected timestamp pattern';

  $log->debug('Debugging');
  $content = path($path)->slurp;
  unlike $content, qr/\]\[debug\] Debug/, 'log omits irrelevance';
};

subtest q{main} => sub {
  my $path = catdir $dir, 'm.log';
  my $log = main->log;
  is $log->level, 'debug', 'expected level';
  is $log->path, $path, 'expected path';
  $log->error('An error');
  ok -f $path, 'log file exists';
  ok -s $path, 'log file contains something';
  my $content = path($path)->slurp;
  like $content, qr/\[error\] An error/, 'contains expected string';

  $log->pattern('[%F %H:%M:%S]');
  $log->fatal('Terminal');
  $content = path($path)->slurp;
  like $content, qr/\[\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d\]\[fatal\] Terminal/,
      'uses expected timestamp pattern';

  $log->debug('Debugging');
  $content = path($path)->slurp;
  like $content, qr/\]\[debug\] Debug/, 'contains expected string';
};

done_testing();

package bp02R_77tM;
use Mojo::Base -base;

use File::Spec::Functions 'catdir';

use Mojar::Log (
  level => 'info',
  path => catdir $bp02R_77tM::dir, 'i.log'
);
