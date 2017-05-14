package Myco::Entity::SampleEntityBase::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::SampleEntityBase::Test -

unit tests for features of Myco::Entity::SampleEntityBase

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Entity::SampleEntityBase::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Entity::SampleEntityBase::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Entity::SampleEntityBase.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Entity::SampleEntityBase;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Entity::SampleEntityBase';

my %test_parameters =
  ###  Test Control Prameters ###
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'heybud',

   skip_persistence => 0,     # skip persistence tests?  (defaults to false)

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       {
#	name => 'a value',
	# Use a coderef to auto-instantiate sub-objects for ref-type attributes
#	type => sub {
#                   my $test = shift;
#	            my $foo = Myco::Entity::SampleEntityBase->new(name => 'bar');
#	            # Make sure sub-object gets removed after test
#		    $test->destroy_upon_cleanup($foo);
#		    $foo;
#		},
       },
  );


###
### Unit Tests for Myco::Entity::SampleEntityBase
###

##
##   Tests for In-Memory Behavior


##
##   Tests for Persistence Behavior

# sub test_bar {
#     my $test = shift;
#     $test->set_type_persistence(1);  # note that this test uses persistence
#     return if $test->should_skip;    # skip over this test if asked
#
#     $test->assert( __something__, "no can-do");
#
#     # Use the following to have Entity objects auto-deleted after
#     # test is run
#     $test->destroy_upon_cleanup($obj);
# }

### Hooks into Myco test framework

sub new {
    my $testclass = shift;
    # create fixture object and handle related needs (esp. DB connection)
    my $test = $testclass->init_fixture(@_);
    $test->set_class($class);
    $test->set_params(\%test_parameters);
    return $test;
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

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::SampleEntityBase|Myco::Entity::SampleEntityBase>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
