#!perl

use v5.10.1;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 27;

my @MODULES;
BEGIN {
    no strict 'refs';
    @MODULES = sort map {
        s|^lib/||;
        s|/|::|g;
        s|.pm$||;
        $_;
    } split(/\n/, qx(find lib -name "*.pm" -print));
    for my $module (@MODULES) {
        use_ok($module) || BAIL_OUT "Can't use $module";
        my $v = "$module" . "::VERSION";
        my $version = eval { $$v };
		if ($version) {
			$version .= ' from module';
		}
		else {
			$version = "$Sport::Analytics::NHL::VERSION from base";
		}
		diag("Testing $module $module version $version Perl $], $^X");
	}
}
