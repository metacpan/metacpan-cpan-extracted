#!perl
use strict;
use warnings;

use Test::More 1.0;
use File::Temp qw(:seekable);

use lib qw(t/lib);
require 'setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

my $release = $class->new;
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

done_testing();
