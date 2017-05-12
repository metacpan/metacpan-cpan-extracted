use Mojo::Base -strict;
use Test::More tests => 7;

use File::Spec::Functions 'catdir';
use File::Temp 'tempdir';
use Mojo::Asset::File;
use MojoX::Log::Log4perl;

# Logging to file
my $dir = tempdir CLEANUP => 1;
my $path = catdir $dir, 'test.log';
my $log = MojoX::Log::Log4perl->new({
  'log4perl.rootLogger'             => 'DEBUG, FILE',
  'log4perl.appender.FILE'          => 'Log::Log4perl::Appender::File',
  'log4perl.appender.FILE.filename' => $path,
  'log4perl.appender.FILE.layout'   => 'PatternLayout',
  'log4perl.appender.FILE.layout.ConversionPattern' => '[%p] %C:%L - %m%n',
});

ok $log->is_debug, 'debug level';
is_deeply $log->debug('Just works.'), $log, 'got the same object in return';
is_deeply $log->log( debug => 'told ya!' ), $log, 'log() also returns self';

$log->level( 'fatal' );
ok !$log->is_debug, 'not in debug level anymore';
$log->debug('And only logs what we want!');

undef $log;
my $content = Mojo::Asset::File->new(path => $path)->slurp;

like(
  $content,
  qr/\[DEBUG\] main:21 - Just works\./,
  'right content (1)',
);

like(
  $content,
  qr/\[DEBUG\] main:22 - told ya!/,
  'right content (2)',
);

unlike(
  $content,
  qr/only logs what we want/,
  'no debug messages after changing log level'
);
