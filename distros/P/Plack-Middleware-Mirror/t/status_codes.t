use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use File::Spec::Functions qw( catfile );
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Mirror ();

my %requests = (
  '/not/here' => [ 404, [ 'Content-type' => 'text/plain' ], [ 'what are you looking for?' ] ],
  '/ok'       => [ 200, [ 'Content-type' => 'text/plain' ], [ 'okee dokee' ] ],
  '/saved'    => [ 379, [ 'Content-type' => 'text/plain' ], [ 'what is this status?' ] ],
);

plan tests => (3 * keys %requests) + 11;

my $dir = tempdir( CLEANUP => 1 );

my $response;
my $app = Plack::Middleware::Mirror->wrap(
  sub { $response },
  path => qr/./,
  mirror_dir => $dir,
  status_codes => [ 379 ], # ignoring 200 (contrived)
  debug => $ENV{AUTOMATED_TESTING},
);

test_psgi $app, sub {
  my ($cb) = @_;

  while ( my ($path, $fake) = each %requests ) {
    $response = $fake;
    my $res = $cb->(GET "http://localhost$path");

    # basics
    is $res->code, $fake->[0];
    is $res->content, $fake->[2]->[0];

    my $file = catfile($dir, split(/\//, $path));

    if ( $fake->[0] == 379 ) {
      ok(  -e $file, "file '$file' mirrored according to configuration" );
    }
    else {
      ok( !-e $file, "file '$file' does not exist: path not mirrored" );
    }
  }
};

$app = Plack::Middleware::Mirror->new();
ok( $app->should_mirror_status( 200 ), 'mirror ok by default' );
ok(!$app->should_mirror_status( 302 ), 'do not 302 by default' );

$app = Plack::Middleware::Mirror->new( status_codes => [ 379 ] );
ok( $app->should_mirror_status( 379 ), 'mirror specified status' );
ok(!$app->should_mirror_status( 479 ), 'do not mirror unaccepted status' );
ok(!$app->should_mirror_status( 200 ), 'not even 200' );

$app = Plack::Middleware::Mirror->new( status_codes => [ 200, 379 ] );
ok( $app->should_mirror_status( 379 ), 'mirror specified status' );
ok( $app->should_mirror_status( 200 ), 'including 200' );
ok(!$app->should_mirror_status( 479 ), 'do not mirror unaccepted status' );

$app = Plack::Middleware::Mirror->new( status_codes => [] );
ok( $app->should_mirror_status( 200 ), 'mirror everything' );
ok( $app->should_mirror_status( 302 ), 'mirror everything' );
ok( $app->should_mirror_status( 579 ), 'mirror everything' );
