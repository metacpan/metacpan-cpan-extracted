use 5.006;
use strict;
use warnings;
use HTML::Stream;
use Path::Tiny qw(path);
use Test::More tests => 8;

use Pod::Tree;
use Pod::Tree::HTML;

Option( "toc", 0, 0 );
Option( "toc", 1, 1 );
Option( "hr",  0, 0 );
Option( "hr",  1, 1 );
Option( "hr",  2, 2 );
Option( "hr",  3, 3 );
Option( "base", "U" );
Option( "base", "D", "http://www.site.com/dir/" );

sub Option {
	my ( $option, $suffix, $value ) = @_;

	my $dir  = "t/option.d";
	my $tree = Pod::Tree->new;
	my $pod  = "$dir/$option.pod";
	$tree->load_file($pod) or die "Can't load $pod: $!\n";

	my $actual = '';
	my $html = Pod::Tree::HTML->new( $tree, \$actual );
	$html->set_options( $option => $value );
	$html->translate;

	my $expected = path("$dir/$option$suffix.exp")->slurp;
	is $actual, $expected;

	path("$dir/$option$suffix.act")->spew($actual);

	#   WriteFile("$ENV{HOME}/public_html/pod/$option$suffix.html", $actual);
}

