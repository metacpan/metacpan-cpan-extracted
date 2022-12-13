#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT is_deeply use_ok ) ], tests => 3;

use HTTP::Request::Common       qw( GET );
use Log::Any::Adapter           qw();
use Log::Any::Adapter::Log4perl qw();
use Plack::Test                 qw();

my $middleware;

BEGIN {
  $middleware = 'Plack::Middleware::LogAny';
  use_ok( $middleware ) or BAIL_OUT "Cannot load middleware '$middleware'!";
}

my $conf = q(
  log4perl.rootLogger             = TRACE, BUFFER
  log4perl.appender.BUFFER        = Log::Log4perl::Appender::TestBuffer
  log4perl.appender.BUFFER.name   = buffer
  log4perl.appender.BUFFER.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.BUFFER.layout.ConversionPattern = %c,%p,%M,%m%n
);
Log::Log4perl->init( \$conf );
Log::Any::Adapter->set( 'Log::Log4perl' );

my $app_name = 'My::PSGI::app';    # Issuer of the logging request (%M)
my $category;
my $messages;

my $app = sub {
  local *__ANON__ = $app_name;
  my ( $env ) = @_;
  map { $env->{ 'psgix.logger' }->( $_ ) } @{ $messages };
  return [ 200, [], [] ];
};

$category = '';
$messages = [
  { level => 'trace', message => 'this is a trace message' },
  { level => 'debug', message => 'this is a debug message' }
];

Plack::Test->create( $middleware->wrap( $app ) )->request( GET '/' );

my $test_appender = Log::Log4perl::Appender::TestBuffer->by_name( 'buffer' );

is_deeply [ split( "\n", $test_appender->buffer ) ],
  [ map { join( ',', ( $category, uc $_->{ level }, $app_name, $_->{ message } ) ) } @$messages ],
  'check Log::Log4perl::Appender::TestBuffer (root logger based logging)';
$test_appender->clear;

$category = 'plack.test';
$messages = [
  { level => 'info', message => 'this is an info message' },
  { level => 'warn', message => 'this is a warn message' }
];

Plack::Test->create( $middleware->wrap( $app, category => $category ) )->request( GET '/' );

is_deeply [ split( "\n", $test_appender->buffer ) ],
  [ map { join( ',', ( $category, uc $_->{ level }, $app_name, $_->{ message } ) ) } @$messages ],
  'check Log::Log4perl::Appender::TestBuffer';
$test_appender->clear;
