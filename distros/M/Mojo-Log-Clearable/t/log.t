use Mojo::Base -strict;

use Test::More;
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Mojo::Log::Clearable;
use Mojo::Util 'decode';

# Logging to file
my $dir = tempdir CLEANUP => 1;
my $wrongpath = catfile $dir, 'wrong.log';
my $log = Mojo::Log::Clearable->new(level => 'error', path => $wrongpath);
$log->error('wrong file');
my $path = catfile $dir, 'test.log';
$log->path($path);
$log->error('Just works');
$log->fatal('I ♥ Mojolicious');
$log->debug('Does not work');
my $content;
{
  open my $slurper, '<:raw', $path or die "Failed to open '$path' for reading: $!";
  local $/;
  $content = decode 'UTF-8', scalar readline $slurper;
}
like $content,   qr/\[.*\] \[error\] Just works/,        'right error message';
like $content,   qr/\[.*\] \[fatal\] I ♥ Mojolicious/, 'right fatal message';
unlike $content, qr/\[.*\] \[debug\] Does not work/,     'no debug message';

# Logging to STDERR
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDERR = $handle;
  $log->path(undef)->level('debug');
  $log->error('Just works');
  $log->fatal('I ♥ Mojolicious');
  $log->debug('Works too');
}
$content = decode 'UTF-8', $buffer;
like $content, qr/\[.*\] \[error\] Just works\n/,        'right error message';
like $content, qr/\[.*\] \[fatal\] I ♥ Mojolicious\n/, 'right fatal message';
like $content, qr/\[.*\] \[debug\] Works too\n/,         'right debug message';

# Clear handle
$log->clear_handle;
ok !exists $log->{handle}, 'log handle is cleared';

done_testing();
