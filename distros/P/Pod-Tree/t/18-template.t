use 5.006;
use strict;
use warnings;
use HTML::Stream;
use Path::Tiny qw(path);
use Test::More tests => 12;

use Pod::Tree;
use Pod::Tree::HTML;

my $Dir = 't/template.d';

Template1();
Template2();

sub Template1 {
	for my $file (qw(cut paragraph list sequence for link)) {
		my $act = "$Dir/$file.act";
		unlink $act;

		{
			my $html = Pod::Tree::HTML->new( "$Dir/$file.pod", $act );
			$html->translate("$Dir/template.txt");
		}

		my $expected = path("$Dir/$file.exp")->slurp;
		my $actual   = path($act)->slurp;
		is $actual, $expected;
	}
}

sub Template2 {
	for my $file (qw(cut paragraph list sequence for link)) {
		my $act = "$Dir/$file.act";
		unlink $act;

		{
			my $dest = IO::File->new("> $act");
			my $html = Pod::Tree::HTML->new( "$Dir/$file.pod", $dest );
			$html->translate("$Dir/template.txt");
		}

		my $expected = path("$Dir/$file.exp")->slurp;
		my $actual   = path("$act")->slurp;
		is $actual, $expected;
	}
}

