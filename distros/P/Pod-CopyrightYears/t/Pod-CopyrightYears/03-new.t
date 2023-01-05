use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Pod::CopyrightYears;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $obj = Pod::CopyrightYears->new(
	'pod_file' => $data_dir->file('Ex1.pm')->s,
);
isa_ok($obj, 'Pod::CopyrightYears');

# Test.
eval {
	Pod::CopyrightYears->new;
};
is($EVAL_ERROR, "Parameter 'pod_file' is required.\n",
	"Parameter 'pod_file' is required.");
clean();

# Test.
eval {
	Pod::CopyrightYears->new(
		'bad_param' => 'foo',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad_param'.\n", "Unknown parameter 'bad_param'.");
clean();
