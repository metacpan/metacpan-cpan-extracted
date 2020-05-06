use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Plack::App::Directory::PYX', 'Plack::App::Directory::PYX is covered.');

# XXX RT#132460: Remove warnings of:
# - WWW::Form::UrlEncoded::XS
# - Cookie::Baker::XS
my @warnings = Test::NoWarnings::warnings();
my $warnings_in_tests = scalar @warnings;
foreach my $warning (@warnings) {
	if ($warning->getMessage =~ m/^Cookie::Baker::XS\ \d+\.\d+\ is require\. fallback to PP version at/ms) {
		$warnings_in_tests--;
	}
	if ($warning->getMessage =~ m/^WWW::Form::UrlEncoded::XS\ \d+\.\d+\ is require\. fallback to PP version at/ms) {
		$warnings_in_tests--;
	}
}
if ($warnings_in_tests == 0) {
	Test::NoWarnings::clear_warnings();
}
