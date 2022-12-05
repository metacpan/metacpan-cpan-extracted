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

Plack::Test->create( $middleware->wrap( $app ) )->request( GET '/' );
is_deeply $logger->msgs, $messages, 'check Log::Any global log buffer (root logger based logging)';

$logger->clear;

$category = 'plack.test';
$messages = [
  { category => $category, level => 'info',    message => 'this is an info message' },
  { category => $category, level => 'warning', message => 'this is a warning message' }
];

Plack::Test->create( $middleware->wrap( $app, category => $category ) )->request( GET '/' );
is_deeply $logger->msgs, $messages, 'check Log::Any global log buffer';
