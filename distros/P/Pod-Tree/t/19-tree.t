use 5.006;
use strict;
use warnings;
use Test::More tests => 9;

use Pod::Tree;
use Path::Tiny qw(path);

my $Dir = "t/tree.d";
Parse();
HasPod( "cut.pod",   1 );
HasPod( "code.pm",   0 );
HasPod( "empty.pod", 0 );

sub Parse {
	for my $file (qw(cut paragraph list sequence link for)) {
		my $tree = Pod::Tree->new;
		my $pod  = "$Dir/$file.pod";
		$tree->load_file($pod) or die "Can't load $pod: $!\n";

		my $actual   = $tree->dump;
		my $expected = path("$Dir/$file.exp")->slurp;
		is $actual, $expected;

		path("$Dir/$file.act")->spew($actual);
	}
}

sub HasPod {
	my ( $file, $expected ) = @_;

	my $tree = Pod::Tree->new;
	my $pod  = "$Dir/$file";
	$tree->load_file($pod) or die "Can't load $pod: $!\n";

	ok !( $tree->has_pod xor $expected );
}

