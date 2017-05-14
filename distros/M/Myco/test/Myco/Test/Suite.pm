#
# $Id: Suite.pm,v 1.3 2006/03/17 22:41:32 sommerb Exp $

package Myco::Test::Suite;
use Test::Unit::TestRunner;
use Test::Unit::TestSuite;
use File::Find;
use File::Path;

our $TESTROOT = "../lib";

BEGIN {
    # Set a flag to let any classes that need to know know that they're running
    # as part of the suite.
    my $VERSION = (qw$Revision: 1.3 $ )[-1];
    $ENV{MYCO_TEST_SUITE} = "Myco::Test::Suite $VERSION";

    # Now set up a temporary temp directory specification.
    $ENV{TMPDIR} = '/tmp/myco_test';
    File::Path::mkpath($ENV{TMPDIR}, 0, 0777);
}

END {
    # Now delete the temporary directory structure.
    File::Path::rmtree($ENV{TMPDIR});
}

sub new { bless {}, ref $_[0] || $_[0] }

sub suite {
    # Create an empty suite
    my $suite = Test::Unit::TestSuite->empty_new("Myco Test Suite");

    # Find all of the relevant tests.
    my $test_classes = find_tests($TESTROOT);

    for my $test_class (@$test_classes) {
	$suite->add_test(Test::Unit::TestSuite->new($test_class));
    }

    # get and add an existing suite
#    $suite->add_test(Test::Unit::TestSuite->new("Myco::Person::Test"));

    # extract suite by way of suite method and add
#    $suite->add_test(Myco::Test::Suite2->suite());


#        # get and add another existing suite
#        $suite->add_test(Test::Unit::TestSuite->new("MyModule::TestCase_2"));


    # return the suite built
    return $suite;
}


sub find_tests {
    my $root = shift;
    my @pm;
    my $wanted = sub {
	return if -d;
	return unless $_ eq 'Test.pm' or $_ eq 'TxTest.pm';
	(my $file = $File::Find::name) =~ s{^.*/test/}{};
	$file =~ s/\.pm//;
	$file =~ s/\//::/g;
	push @pm, $file;
    };
    find($wanted, $root);
    return unless @pm;
    return wantarray ? @pm : \@pm;
}

1;
