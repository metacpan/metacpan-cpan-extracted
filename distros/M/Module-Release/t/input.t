#!perl
use strict;
use warnings;

use Test::More 1.0 tests => 3;
use File::Temp qw(:seekable);

use Module::Release;

BEGIN {
	use File::Spec::Functions qw(rel2abs catfile);
	my $file = rel2abs( catfile( qw( t lib setup_common.pl) ) );
	require $file;
	}

my $release = Module::Release->new;
my $temp_fh = File::Temp->new;
$temp_fh->write("to be or not to be\n");
$temp_fh->flush();
$temp_fh->seek( 0, SEEK_SET );

$release->{input_fh} = $temp_fh;
my $input = $release->_slurp;

is(
    $input,
    "to be or not to be\n",
    '_slurp returns content from input file handle'
	);
