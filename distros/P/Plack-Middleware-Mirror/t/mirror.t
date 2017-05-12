use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use File::Spec::Functions qw( catfile );
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Mirror ();

my %requests = (
  '/helper' => "rubber\nducky",
  '/ba/na/na' => 'tasty',
  '/nothing' => 'at all',
  '/monkey/island.txt' => "I want to be\na mighty pirate."
);

plan tests => (4 * keys %requests) - 1;

my $dir = tempdir( CLEANUP => 1 );

my $app = Plack::Middleware::Mirror->wrap(
  sub {
    my ($env) = @_;
    #diag explain $env;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ $requests{ $env->{PATH_INFO} } ] ];
  },
  path => sub { return 1 if /helper|monkey/; s/a/A/g; },
  mirror_dir => $dir,
  debug => $ENV{AUTOMATED_TESTING},
);

test_psgi $app, sub {
  my ($cb) = @_;

  while ( my ($path, $content) = each %requests ) {
    my $res = $cb->(GET "http://localhost$path");

    # basics
    is $res->code, 200;
    is $res->content, $content;

    #diag explain [`find $dir`];
    $path = '/bA/nA/nA' if $path eq '/ba/na/na';

    my $file = catfile($dir, split(/\//, $path));

    if ( $path eq '/nothing' ) {
      ok( !-e $file, "file '$file' does not exist: path not mirrored" );
      next;
    }

SKIP: {
    ok( -e $file, "file '$file' exists" )
      or skip q[don't try to read file that doesn't exist], 1;

    is slurp( $file ), $content, 'file contains "downloaded" content';
}
  }
};

sub slurp {
  my ($file) = @_;
  open(my $fh, '<', $file)
    or die "Failed to open mirrored '$file'";
  local $/;
  return <$fh>;
}
