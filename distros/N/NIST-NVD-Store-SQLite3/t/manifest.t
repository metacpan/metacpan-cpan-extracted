#!perl -T

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use File::Spec;
use Cwd;


(my $test_dir)       = $Bin;
(my $dist_dir)       = Cwd::realpath( File::Spec->catfile($Bin, '..') );

unless ( $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;

open( my $exclude_fh, q{<}, File::Spec->catfile( $dist_dir, 'ignore.txt' ) )
  or die "couldn't open ignore.txt: $!";

my @exclude_files = map{
  chomp;
  /\*/ ?
    glob( File::Spec->catfile( $dist_dir, $_ ) ) :
    File::Spec->catfile( $dist_dir, $_ )
} ( <$exclude_fh> );

ok_manifest({
	exclude =>  \@exclude_files ,
	filter  => [
		qr/\.svn/,
		qr/\.git/,
		qr/^.*~$/,
		],
		bool    => 'or',
			});

done_testing();
