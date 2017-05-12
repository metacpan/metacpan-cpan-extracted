use strict;
use warnings;
use Test::More tests => 1;
use Cwd;
use POE::Component::SmokeBox::Dists;
use File::Spec ();
use File::Path (qw/mkpath rmtree/);

$ENV{PERL5_SMOKEBOX_DIR} = cwd();

diag("Trying to retrieve a packages file from a CPAN mirror\n");

my $smokebox_dir = File::Spec->catdir( POE::Component::SmokeBox::Dists::_smokebox_dir(), '.smokebox' );

rmtree( $smokebox_dir ) if -d $smokebox_dir;
mkpath( $smokebox_dir ) if ! -d $smokebox_dir;
die "$!\n" unless -d $smokebox_dir;

my $file = POE::Component::SmokeBox::Dists::_fetch( $smokebox_dir );

if ( ! $file ) {
  open FH, "> no.network" or die "$!\n";
  print FH "Bleh\n";
  close FH;
}

rmtree( $smokebox_dir ) if -d $smokebox_dir;

pass("We were only checking for network access");
