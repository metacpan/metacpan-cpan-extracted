use Mojo::Base -strict;

use Test::More;
use Mojo::File qw(path tempdir);
use Mojo::Log::Che;
use Mojo::Util qw'decode';
#~ binmode STDERR, ":utf8";

my $time_re = qr/\d{1,2} \w{3} \d{2}:\d{2}:\d{2}/;#\w{2} 
my $line_re = qr/\d+〉t\/02-che.t:\d+/;

# Logging to folder
my $dir  = tempdir();
my $log  = Mojo::Log::Che->new(level => 'error', path => $dir);
$log->error('Just works');
$log->fatal('I ♥ Mojolicious');
$log->debug('Does not work');
$log->foo('Foo level');
is scalar keys %{$log->handlers}, 3, 'right 3 handlers';
my $ls = `ls $dir`;
#~ warn "[$ls]";
like $ls, qr/error\.log/, 'exists error.log file ';
like $ls, qr/fatal\.log/, 'exists fatal.log file ';
unlike $ls, qr/debug\.log/, 'exists debug.log file ';
like $ls, qr/foo\.log/, 'right file ';
undef $log;
my $content_err = decode 'UTF-8', path("$dir/error.log")->slurp;
my $content_i = decode 'UTF-8', path("$dir/fatal.log")->slurp;
my $content_foo = decode 'UTF-8', path("$dir/foo.log")->slurp;
like $content_err,   qr/$time_re $line_re Just works/,        'right error message';
like $content_i,   qr/$time_re $line_re I ♥ Mojolicious/, 'right info message';
like $content_foo,   qr/$time_re $line_re Foo level/,        'right foo message';
eval {path("$dir/debug.log")->slurp};
like $@, qr/No such file or directory/, 'no debug file';
is defined $@, 1, 'no debug file';
undef $dir;

# Logging to folder + set custom relative "paths" level
$dir  = tempdir();
$log  = Mojo::Log::Che->new(level => 'error', path => $dir, paths=>{error=>'err.log', foo=>"bar.log",});
$log->error('Just works');
$log->fatal('I ♥ Mojolicious');
$log->foo('Foo level');
is scalar keys %{$log->handlers}, 3, 'right 3 handlers';
$ls = `ls $dir`;
like $ls, qr/err\.log/, 'right file ';
like $ls, qr/fatal\.log/, 'right file ';
like $ls, qr/bar\.log/, 'right file ';
undef $log;
$content_err = decode 'UTF-8', path("$dir/err.log")->slurp;
my $content_bar = decode 'UTF-8', path("$dir/bar.log")->slurp;
$content_i = decode 'UTF-8', path("$dir/fatal.log")->slurp;
like $content_i,   qr/$time_re $line_re I ♥ Mojolicious/, 'right fatal message';
like $content_err,   qr/$time_re $line_re Just works/,        'right error message';
like $content_bar,   qr/$time_re $line_re Foo level/,        'right foo message';
undef $dir;

# Logging to file + have default "paths" for levels
$dir  = tempdir();
my $file = $dir->child('mojo.log');
$log  = Mojo::Log::Che->new(level => 'error', path => $file);
$log->error('Just works');
$log->fatal('I ♥ Mojolicious');
$log->debug('Does not work');
$log->foo('Foo level');
is scalar keys %{$log->handlers}, 0, 'right 0 handlers';
undef $log;
my $content = decode 'UTF-8', path($file)->slurp;
like $content,   qr/$time_re \[e\] $line_re Just works/,        'right error message';
like $content,   qr/$time_re \[f\] $line_re I ♥ Mojolicious/, 'right fatal message';
unlike $content, qr/$time_re \[d\] $line_re Does not work/,     'no debug message';
like $content,   qr/$time_re \[foo\] $line_re Foo level/,        'right foo message';
undef $dir;

# Logging to file + custom paths for levels
$dir  = tempdir();
$file = $dir->child('mojo.log');
my $file2 = $dir->child('error.log');
my $file3 = $dir->child('debug.log');
$log  = Mojo::Log::Che->new(level => 'error', path => $file, paths=>{error=>$file2, debug=>$file3});
$log->error('Just works');
$log->fatal('I ♥ Mojolicious');
$log->debug('Does not work');
$log->foo('Foo level');
is scalar keys %{$log->handlers}, 1, 'right 1 handlers';
undef $log;
$content = decode 'UTF-8', path($file)->slurp;
like $content,   qr/$time_re \[f\] $line_re I ♥ Mojolicious/, 'right fatal message';
unlike $content, qr/Does not work/,     'no debug message';
like $content,   qr/$time_re \[foo\] $line_re Foo level/,        'right foo level';
$content = decode 'UTF-8', path($file2)->slurp;
like $content,   qr/$time_re $line_re Just works/,        'right error message';
eval {path($file3)->slurp};
like $@, qr/No such file or directory/, 'no debug file';
is defined $@, 1, 'no debug file';
undef $dir;

# Log to STDERR + custom file level
$dir  = tempdir();
$file = $dir->child('тест.log');
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDERR = $handle;
  my $log = Mojo::Log::Che->new(paths => {уникод=>$file, error=>'/dev/null'});
  $log->error('Just works');
  $log->info('I ♥ Mojolicious');
  $log->debug('Works too');
  $log->уникод('Уникод level');
  is scalar keys %{$log->handlers}, 2, 'right 2 handlers';
}
$content = decode 'UTF-8', $buffer;
unlike $content, qr/^$time_re \[e\] $line_re Just works\n/m,        'right error message';
like $content, qr/^$time_re \[i\] $line_re I ♥ Mojolicious\n/m, 'right info message';
like $content, qr/^$time_re \[d\] $line_re Works too\n/m,         'right debug message';
$content = decode 'UTF-8', path($file)->slurp;
like $content,   qr/^$time_re $line_re Уникод level/m,        'right Уникод message';
undef $dir;

# Logging to file + have default "paths" for levels+no trace
$dir  = tempdir();
$file = $dir->child('mojo.log');
$log  = Mojo::Log::Che->new(level => 'error', path => $file, trace=>0);
$log->error('Just works');
$log->fatal('I ♥ Mojolicious');
$log->debug('Does not work');
$log->foo('Foo level');
is scalar keys %{$log->handlers}, 0, 'right 0 handlers';
undef $log;
$content = decode 'UTF-8', path($file)->slurp;
like $content,   qr/$time_re \[e\] Just works/,        'right error message';
like $content,   qr/$time_re \[f\] I ♥ Mojolicious/, 'right fatal message';
unlike $content, qr/$time_re \[d\] Does not work/,     'no debug message';
like $content,   qr/$time_re \[foo\] Foo level/,        'right foo message';
undef $dir;

done_testing();
