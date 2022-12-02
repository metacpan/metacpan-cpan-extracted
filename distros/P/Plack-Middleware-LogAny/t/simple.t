#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT is_deeply use_ok ) ], tests => 3;

use HTTP::Request::Common qw( GET );
use Log::Any::Test        qw();
use Log::Any              qw( $logger );
use Plack::Test           qw();

my $middleware;

BEGIN {
  $middleware = 'Plack::Middleware::LogAny';
  use_ok( $middleware ) or BAIL_OUT "Cannot load middleware '$middleware'!";
}

my $messages;

my $app = sub {
  my ( $env ) = @_;
  map { $env->{ 'psgix.logger' }->( $_ ) } @{ $messages };
  return [ 200, [], [] ];
};

$messages = [
  { category => '', level => 'trace', message => 'this is a trace message' },
  { category => '', level => 'debug', message => 'this is a debug message' }
];

Plack::Test->create( $middleware->wrap( $app ) )->request( GET '/' );
is_deeply $logger->msgs, $messages, 'check Log::Any global log buffer';

$logger->clear;

$messages = [
  { category => 'plack.test', level => 'info',    message => 'this is an info message' },
  { category => 'plack.test', level => 'warning', message => 'this is a warning message' }
];

Plack::Test->create( $middleware->wrap( $app, category => 'plack.test' ) )->request( GET '/' );
is_deeply $logger->msgs, $messages, 'check Log::Any global log buffer';
