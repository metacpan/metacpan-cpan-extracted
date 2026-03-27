use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use NKC::Transform::MARC2BIBFRAME;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = NKC::Transform::MARC2BIBFRAME->new;
isa_ok($obj, 'NKC::Transform::MARC2BIBFRAME');

# Test.
eval {
	NKC::Transform::MARC2BIBFRAME->new(
		'xslt_transformation_file' => 'bad',
	);
};
is($EVAL_ERROR, "Cannot read XSLT file.\n",
	"Cannot read XSLT file.");
my $err_msg_hr = err_msg_hr(0);
is($err_msg_hr->{'XSLT file'}, 'bad', "Error 'XSLT file' parameter (bad)");
clean();

# Test.
eval {
	NKC::Transform::MARC2BIBFRAME->new(
		'version' => 'bad',
	);
};
is($EVAL_ERROR, "Cannot read XSLT file.\n",
	"Cannot read XSLT file.");
$err_msg_hr = err_msg_hr(0);
like($err_msg_hr->{'XSLT file'}, qr{bad/marc2bibframe2\.xsl$},
	"Error 'XSLT file' parameter (.. bad/marc2bibframe2.xsl)");
clean();

# Test.
eval {
	NKC::Transform::MARC2BIBFRAME->new(
		'version' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'version' is undefined.\n",
	"Parameter 'version' is undefined.");
clean();
