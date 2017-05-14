package Myco::Entity::Meta::UI::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::UI::Test -

unit tests for features of Myco::Entity::Meta::UI

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Entity::Meta::UI::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Entity::Meta::UI::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Entity::Meta::UI.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Entity::Meta::UI;
use Myco::Entity::SampleEntity;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Entity::Meta::UI';

use constant UI_LIST => 'Myco::Entity::Meta::UI::List';
use constant UI_VIEW => 'Myco::Entity::Meta::UI::View';
use constant ENTITY => 'Myco::Entity::SampleEntity';

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
   simple_accessor => 'displayname',

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
#	            my $foo = Myco::Entity::Meta::UI->new(name => 'bar');
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
### Unit Tests for Myco::Entity::Meta::UI
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################

sub test_1_list {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $ui = $test->new_testable_entity;
    $ui->set_list;
    my $list = $ui->get_list;
    $test->assert(defined($list)
		  && UNIVERSAL::isa($list, UI_LIST), "oh...mah-gosh..." );
}

sub test_2_view {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $ui = $test->new_testable_entity;
    $ui->set_view;
    my $view = $ui->get_view;
    $test->assert(defined($view)
		  && UNIVERSAL::isa($view, UI_VIEW), "oh...mah-gosh..." );
}

sub test_3_sort {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my @entities;
    for my $name ( qw(Ben Rhonda Elizabeth Samuel) ) { # sorted by first name
        push @entities, ENTITY->new( name => $name );
    }
    push @entities,  ENTITY->new( name => 'Ben', fish => 'Pike' );

    # sorting by last, first
    my $ui_md = ENTITY->introspect->get_ui;
    @entities = sort { $a->get_last cmp $b->get_last
                    || $a->get_first cmp $b->get_first } @entities;

    my @entities_sorted_by_meth = $ui_md->sort_objs(@entities);

    for (my $i=0; $i<@entities; $i++) {
        $test->assert( $entities_sorted_by_meth[$i]->displayname
                       eq $entities[$i]->displayname, 'peeps are matching' );
    }

}

##############################################################################
#   Tests of Persistence Behavior
##############################################################################

# None


1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::Meta::UI|Myco::Entity::Meta::UI>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
