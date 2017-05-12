use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use File::Spec::Functions qw( catfile );
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Date ();
use Time::Local qw( timegm ); # core

use Plack::Middleware::Mirror ();

my $time = time();
#sleep 1; # add 1 second to the clock to ensure test works if it takes longer than 1 second

my $epoch = 0;
my $lm    = timegm( 32, 23, 22,  9,  1, 1994 );

my %requests = (
  '/has/lm'               => [ 'Wed, 09 Feb 1994 22:23:32 GMT' => $lm ],
  '/has/lm.plus'          => [ 'Wed, 09 Feb 1994 22:23:32 GMT; extra foo' => $lm ],
  '/has/lm-of-epoch'      => [ HTTP::Date::time2str($epoch)    => $epoch ],
  '/does/not/have/lm'     => [ '' => $time ],
  '/bad/lm'               => [ 'not a valid date' => $time ],
);

plan tests => 4 * keys %requests;

my $dir = tempdir( CLEANUP => 1 );

my $app = Plack::Middleware::Mirror->wrap(
  sub {
    my ($env) = @_;
    my $lm = $requests{ $env->{PATH_INFO} }->[0];
    return [ 200, [ 'Content-Type' => 'text/plain', ( $lm ? ('Last-Modified' => $lm) : ()) ], [ 'time' ] ];
  },
  path => qr/./,
  mirror_dir => $dir,
  debug => $ENV{AUTOMATED_TESTING},
);

test_psgi $app, sub {
  my ($cb) = @_;

  while ( my ($path, $lmtime) = each %requests ) {
    my ($lmheader, $exp) = @$lmtime;
    my $res = $cb->(GET "http://localhost$path");

    # sanity check
    is $res->code, 200;
    is $res->content, 'time';

SKIP: {
    my $file = catfile($dir, split(/\//, $path));
    ok( -e $file, "file '$file' exists" )
      or skip q[can't stat() file that doesn't exist], 1;

    my $now = time;
    my $mtime = (stat $file)[9];
    my $desc = "$path ('$lmheader' => $exp)";

    if ( $path =~ m{^/has} ) {
      is( $mtime,   $exp,                    "correct mtime for $desc" );
    }
    else {
      # use range to allow for the clock to increment to the next second
      ok( $mtime >= $exp && $mtime <= $now, "mtime is now() for $desc" );
    }
}
  }
};
