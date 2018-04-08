use strict;
use warnings;

use File::Basename qw( dirname );
use File::Spec;
use Test::More tests => 25;

use_ok('Test::PLP');

$PLP::use_cache = 0 if $PLP::use_cache;
#TODO: caching on (change file names)

chdir File::Spec->catdir(dirname($0), '50-cgi')
	or BAIL_OUT('cannot change to test directory ./50-cgi/');

# 0*: permission checks using generated dummy files
SKIP:
for my $file (glob '0*.html') {
	$file =~ s/[.]html$/.plp/;
	my ($mode) = $file =~ /^..-(\d*)\b/;
	eval {
		if ($mode eq 404) {
			return 1;  # do not create
		}

		# prepare input
		open my $out, '>', $file or die "cannot generate source file ($!)\n";
		print {$out} 'ok';

		if ($mode eq 403) {
			chmod 0244, $file or die "cannot change permissions ($!)\n";
		}

		return -e $file;
	} or chomp $@, skip("$file: $@", 1);  # ignore generation failure

	plp_ok($file);
	eval { unlink $file };  # clean up
}

# 1*-2*: generic tests with standard environment
plp_ok($_) for glob '[12]*.html';

# 3*: error tests depending on warning message
SKIP: {
	my @inctests = glob '3*.html';

	my $INCFILE = File::Spec->rel2abs("./missinginclude");
	if (open my $dummy, "<", $INCFILE) {  # like PLP::source will
		fail("file missinginclude shouldn't exist");
		skip("missinginclude tests (3*)", @inctests - 1);
	}
	my $INCWARN = qq{Can't open "$INCFILE" ($!)};

	plp_ok($_, INCWARN => $INCWARN) for @inctests;
}

# 4*-6*: apache environment (default)
plp_ok($_) for glob '[4-6]*.html';

#TODO: %fields
#TODO: %cookie

# 7*: multipart posts
TODO: {
	local $TODO = 'future feature';
	plp_ok($_, -env => {
		CONTENT_TYPE => 'multipart/form-data; boundary=knip',
	}) for glob '7*.html';
}

# 8*: lighttpd environment
plp_ok($_, -env => {
	# lighttpd/1.4.7 CGI environment
	REQUEST_METHOD => 'GET',
	REQUEST_URI => "/$_/test/123",
	QUERY_STRING => 'test=1&test=2',
	GATEWAY_INTERFACE => 'CGI/1.1',
	
	SCRIPT_NAME => "/$_", #XXX: .plp?
	SCRIPT_FILENAME => "./$_",
	PATH_INFO => '/test/123',
	PATH_TRANSLATED => undef,
	DOCUMENT_ROOT => undef,
}) for glob '8*.plp';

