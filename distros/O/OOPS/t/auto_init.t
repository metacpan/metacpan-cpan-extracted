#!/usr/bin/perl -I../lib

delete $ENV{OOPS_INIT};

use FindBin;
use lib $FindBin::Bin;
use OOPS::TestSetup qw(:filter);
use OOPS::TestCommon;  # creates database

print "1..4\n";

nocon;
db_drop();
nocon;

my %args2 = %args;
delete $args2{no_front_end};

eval { $fe = OOPS->new(%args2) };

# print "# error = $@\n";
test($@ =~ /DBMS not initialized/, "error = '$@'");
undef $fe;

db_drop();

nocon;
print "#			the test begins...\n";

eval {
	$fe = OOPS->new(%args2, auto_initialize => 1);

	$fe->{xyz} = { abc => 123 };

	$fe->commit;

	undef $fe;
};
test(! $@, $@);

eval {
	$fe = OOPS->new(%args2, auto_initialize => 1);

	test($fe && $fe->{xyz} && $fe->{xyz}{abc} && $fe->{xyz}{abc} == 123);

	undef $fe;
};
test(! $@, $@);

1;
