package Myco::Util::DateTime::Test;

###############################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:06 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Util::DateTime::Test -

unit tests for features of Myco::Util::DateTime

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=head1 DATE

$Date: 2004/11/22 19:16:06 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./testrun [-m] Myco::Util::DateTime::Test
 # run tests, GUI style
 ./tktestrun Myco::Util::DateTime::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Util::DateTime.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::Fodder);

### Module Dependencies and Compiler Pragma
use Myco::Util::DateTime;
use Date::Calc qw( Today Add_Delta_Days );
use strict;
use warnings;

##############################################################################
# Programatic Dependencies
use Date::Calc;

### Class Data

# This class tests features of:
my $class = 'Myco::Util::DateTime';

# It may be helpful to number tests... use testrun's -d flag to view
#   test-specific debug output (see example tests, testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

##############################################################################
#  Test Control Parameters
##############################################################################
my %test_parameters =
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related testsq

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   #standalone => 1,           # don't compile Myco entity classes

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       {
#	name => 'a value',
	# Use a coderef to auto-instantiate sub-objects for ref-type attributes
#	type => sub {
#                   my $test = shift;
#	            my $foo = Myco::Util::DateTime->new(name => 'bar');
#	            # Make sure sub-object gets removed after test
#		    $test->destroy_upon_cleanup($foo);
#		    $foo;
#		},
       },
  );

##############################################################################
# Hooks into Myco test framework.
##############################################################################

sub new {
    # create fixture object and handle related needs (esp. DB connection)
    shift->init_fixture(test_unit_params => [@_],
			myco_params => \%test_parameters,
			class => $class);
}

sub set_up {
    my $test = shift;
    $test->help_set_up(@_);
}

sub tear_down {
    my $test = shift;
    $test->help_tear_down(@_);
}


##############################################################################
###
### Unit Tests for Myco::Util::DateTime
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################

sub test_1_date {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked
    my $datetime = $class;

    my @time = localtime(time);
    my ($yr, $mo, $day) = ($time[5]+1900, $time[4]+1, $time[3]);
    # Have to add leading zeros for later comparison
    for ($mo, $day) {
        $_ = "0$_" if length $_ == 1;
    }
    my $today = "$yr-$mo-$day";

    # Check exception handling with invalid formats
    my $d;
    eval {
        $d = $datetime->date('MMMM-YY-DD');
    };
    $test->assert( $@ =~ /not a valid date/, 'Invalid date format' );

    my $valid_date = $datetime->date('YYYY-MM-DD');
    $test->assert( $valid_date eq $today, 'Got good date' );

    # Check that leading zeros are included - not a valid ISO format otherwise.
    # Run this test from the 1st-9th month of every year or day of every month.
    if ($mo < 10 || $day < 10) {
        $test->assert( $valid_date !~ /(-\d{1}-)|(-\d{1}^)/,
                       'Date needs to include leading zeros' );
    }
}

sub test_2_date_add {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked
    my $datetime = $class;

    my $today = $datetime->date('YYYY-MM-DD');
    my $last_year = join '-', map { /^\d$/ ? '0'.$_ : $_ }
      Add_Delta_Days( Today(), -365);

    $test->assert( $datetime->date_add(-365, $today) eq $last_year,
                   'date_add works '. $last_year );
    $test->assert( $datetime->date_add(-365) eq $last_year,
                   'date_add works still works' );
}

1;
__END__
