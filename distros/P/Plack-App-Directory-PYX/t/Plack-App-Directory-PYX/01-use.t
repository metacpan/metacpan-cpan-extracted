use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('Plack::App::Directory::PYX');
}

# Test.
require_ok('Plack::App::Directory::PYX');

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
