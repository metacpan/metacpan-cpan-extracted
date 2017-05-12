package Myco::Base::Entity::Meta::UI::Test;

###############################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:04 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::UI::Test -

unit tests for features of Myco::Base::Entity::Meta::UI

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=head1 DATE

$Date: 2004/11/22 19:16:04 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./testrun [-m] Myco::Base::Entity::Meta::UI::Test
 # run tests, GUI style
 ./tktestrun Myco::Base::Entity::Meta::UI::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Base::Entity::Meta::UI.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Base::Entity::Meta::UI;
use Myco::Base::Entity::SampleEntity;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Base::Entity::Meta::UI';

use constant UI_LIST => 'Myco::Base::Entity::Meta::UI::List';
use constant UI_VIEW => 'Myco::Base::Entity::Meta::UI::View';
use constant ENTITY => 'Myco::Base::Entity::SampleEntity';

# It may be helpful to number tests... use testrun's -d flag to view
#   test-specific debug output (see example tests, testrun)
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
#	            my $foo = Myco::Base::Entity::Meta::UI->new(name => 'bar');
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
### Unit Tests for Myco::Base::Entity::Meta::UI
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

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::Meta::UI|Myco::Base::Entity::Meta::UI>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<testrun|testrun>,
L<tktestrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<mkentity|mkentity>
