#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT is is_deeply use_ok ) ], tests => 5;

use HTTP::Request::Common qw( GET );
use Log::Any::Test        qw();
use Log::Any              qw( $logger );    # Log::Any global log buffer category is "main"
use Plack::Test           qw();

my $middleware;

BEGIN {
  $middleware = 'Plack::Middleware::LogAny';
  use_ok( $middleware ) or BAIL_OUT "Cannot load middleware '$middleware'!";
}

my $category;
my $messages;

my $app = sub {
  my ( $env ) = @_;
  map { $env->{ 'psgix.logger' }->( $_ ) } @{ $messages };
  return [ 200, [], [] ];
};

$category = '';
$messages = [
  { category => $category, level => 'trace', message => 'this is a trace message' },
  { category => $category, level => 'debug', message => 'this is a debug message' }
];

my $header_name  = 'X-Request-ID';
my $header_value = '77e1c83b-7bb0-437b-bc50-a7a58e5660ac';
my $wrapped_app =
  Plack::Test->create( $middleware->wrap( $app, context => [ 'Content-Type', 'X-B3-TraceId', $header_name ] ) );

$wrapped_app->request( GET '/' );
is_deeply $logger->msgs, $messages, 'check Log::Any global log buffer (root logger based logging)';
is scalar %{ Log::Any->get_logger( category => $category )->context }, 0, 'empty logging context';

$logger->clear;

$wrapped_app->request( GET '/', $header_name => $header_value );
is_deeply $logger->msgs,
  [ map { $_->{ message } = $_->{ message } . " {\"$header_name\" => \"$header_value\"}"; $_ } @$messages ],
  'check Log::Any global log buffer';
is scalar %{ Log::Any->get_logger( category => $category )->context }, 0, 'empty logging context';
