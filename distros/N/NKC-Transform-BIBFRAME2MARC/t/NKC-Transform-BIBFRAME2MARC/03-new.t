use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use NKC::Transform::BIBFRAME2MARC;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = NKC::Transform::BIBFRAME2MARC->new;
isa_ok($obj, 'NKC::Transform::BIBFRAME2MARC');

# Test.
eval {
	NKC::Transform::BIBFRAME2MARC->new(
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
	NKC::Transform::BIBFRAME2MARC->new(
		'version' => 'bad',
	);
};
is($EVAL_ERROR, "Cannot read XSLT file.\n",
	"Cannot read XSLT file.");
$err_msg_hr = err_msg_hr(0);
like($err_msg_hr->{'XSLT file'}, qr{bibframe2marc-bad\.xsl$},
	"Error 'XSLT file' parameter (.. bibframe2marc-bad.xsl)");
clean();

# Test.
eval {
	NKC::Transform::BIBFRAME2MARC->new(
		'version' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'version' is undefined.\n",
	"Parameter 'version' is undefined.");
clean();
