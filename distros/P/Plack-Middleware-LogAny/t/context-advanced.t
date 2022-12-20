#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT is is_deeply use_ok ) ], tests => 3;

use HTTP::Request::Common       qw( GET );
use Log::Any::Adapter           qw();
use Log::Any::Adapter::Log4perl qw();
use Plack::Test                 qw();

my $middleware;

BEGIN {
  $middleware = 'Plack::Middleware::LogAny';
  use_ok( $middleware ) or BAIL_OUT "Cannot load middleware '$middleware'!";
}

my $header_name  = 'X-Request-ID';
my $header_value = '77e1c83b-7bb0-437b-bc50-a7a58e5660ac';

my $conf = qq(
  log4perl.rootLogger             = TRACE, BUFFER
  log4perl.appender.BUFFER        = Log::Log4perl::Appender::TestBuffer
  log4perl.appender.BUFFER.name   = buffer
  log4perl.appender.BUFFER.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.BUFFER.layout.ConversionPattern = %c,%p,%X{$header_name},%M,%m%n
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

Plack::Test->create( $middleware->wrap( $app, context => [ 'Content-Type', 'X-B3-TraceId', $header_name ] ) )
  ->request( GET '/', $header_name => $header_value );

my $test_appender = Log::Log4perl::Appender::TestBuffer->by_name( 'buffer' );

is_deeply [ split( "\n", $test_appender->buffer ) ],
  [ map { join( ',', ( $category, uc $_->{ level }, $header_value, $app_name, $_->{ message } ) ) } @$messages ],
  'check Log::Log4perl::Appender::TestBuffer (root logger based logging)';
is scalar %{ Log::Any->get_logger( category => $category )->context }, 0, 'empty logging context';
