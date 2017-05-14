package Myco::Entity::Meta::UI::List::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::UI::List::Test -

unit tests for features of Myco::Entity::Meta::UI::List

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Entity::Meta::UI::List::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Entity::Meta::UI::List::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Entity::Meta::UI::List.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Entity::Meta::UI::List;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Entity::Meta::UI::List';

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
   #simple_accessor => 'fooattrib',

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   standalone => 1,

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       {
#	name => 'a value',
	# Use a coderef to auto-instantiate sub-objects for ref-type attributes
#	type => sub {
#                   my $test = shift;
#	            my $foo = Myco::Entity::Meta::UI::List->new(name => 'bar');
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

1;


##############################################################################
###
### Unit Tests for Myco::Entity::Meta::UI::List
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################

# sub test_1_foo {
#     my $test = shift;
#     return if $test->should_skip;    # skip over this test if asked
#
#     ...do something...
#     $test->db_out('hey lookee here') if DEBUG;
#
#     $test->assert( __something__, "oh...mah-gosh..." );
# }


##############################################################################
#   Tests of Persistence Behavior
##############################################################################

# sub test_2_bar {
#     my $test = shift;
#     $test->set_type_persistence(1);  # note that this test uses persistence
#     return if $test->should_skip;    # skip over this test if asked
#
#     ...do something...
#     $test->db_out('groovy') if DEBUG;
#
#     $test->assert( __something__, "no can-do");
#
#     # Use the following to have Entity objects auto-deleted after
#     # test is run
#     $test->destroy_upon_cleanup($obj);
# }



=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::Meta::UI::List|Myco::Entity::Meta::UI::List>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
