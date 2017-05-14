package Myco::Query::Part::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Query::Part::Test -

unit tests for features of Myco::Query::Part

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Query::Part::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Query::Part::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Query::Part.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Query::Part;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Query::Part';

# It may be helpful to number tests... use myco-testrun's -d flag to view
#   test-specific debug output (see example tests, myco-testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

##############################################################################
#  Test Control Parameters
##############################################################################
my %test_parameters =
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => undef,

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   standalone => 1,           # don't compile Myco entity classes

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
   {
#    name => 'name',
	# Use a coderef to auto-instantiate sub-objects for ref-type attributes
#	type => sub {
#                   my $test = shift;
#	            my $foo = Myco::Query::Part::Clause->new(name => 'bar');
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
### Unit Tests for Myco::Query::Part
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################




1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Query::Part|Myco::Query::Part>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
