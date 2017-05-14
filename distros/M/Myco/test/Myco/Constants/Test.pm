package Myco::Constants::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Constants::Test -

unit tests for features of Myco::Constants

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Constants::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Constants::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Constants.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::Fodder);

### Module Dependencies and Compiler Pragma
use Myco::Constants;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Constants';

# It may be helpful to number tests... use myco-testrun's -d flag to view
#   test-specific debug output (see example tests, myco-testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

##############################################################################
#  Test Control Parameters
##############################################################################
my %test_parameters =
  (
   skip_persistence => 0,     # skip persistence tests?  (defaults to false)
   standalone => 0,           # don't compile Myco entity classes
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
### Unit Tests for Myco::Constants
###
##############################################################################

my $PREF_LANG = 'en';

sub test_1_country_codes {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $codes = Myco::Constants->country_codes;

    $test->assert(ref $codes eq 'ARRAY', 'got an arrayref' );
    $test->assert(@$codes > 25, 'array is not empty' );
}


sub test_2_country_hash_by_code {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $chash = Myco::Constants->country_hash_by_code;

    $test->assert(ref $chash eq 'HASH', 'got a hashref' );
    $test->assert(scalar %$chash, 'hash is not empty' );
}



sub test_3_language_codes {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $codes = [ @{Myco::Constants->language_codes} ];


    $test->assert(ref $codes eq 'ARRAY', 'got an arrayref' );
    $test->assert(@$codes > 25, 'array is not empty' );

    # shift off any first array members that aren't real vals
    while (defined($codes->[0]) && $codes->[0] =~ /^__[a-z]+__$/) {
	$_ = shift @$codes;
    }

    $test->assert($codes->[0] eq $PREF_LANG, 'pref_lang is first' );
}


sub test_4_language_hash_by_code {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $lhash = Myco::Constants->language_hash_by_code;

    $test->assert(ref $lhash eq 'HASH', 'got a hashref' );
    $test->assert(scalar %$lhash, 'hash is not empty' );
}





1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Constants|Myco::Constants>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
