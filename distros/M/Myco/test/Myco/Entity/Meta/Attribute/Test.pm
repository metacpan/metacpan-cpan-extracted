package Myco::Entity::Meta::Attribute::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::Attribute::Test -

unit tests for features of Myco::Entity::Meta::Attribute

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Entity::Meta::Attribute::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Entity::Meta::Attribute::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Entity::Meta::Attribute.

=cut

#    next line moved here for dubugging convenience
use Myco::Entity::Meta::Attribute;


### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
#use Myco::UI::MVC::Controller;
use Myco::Entity::Meta::Attribute::UI;
use strict;
use warnings;

### Class Data

# Tests are numbered... set to number for test specific debug output
# or -1 for all
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

# This class tests features of:
my $class = 'Myco::Entity::Meta::Attribute';

my %test_parameters =
  ###  Test Control Prameters ###
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'synopsis',

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   standalone => 1,

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults => { name => 'tuber',
		 type => 'string',
		 values => [qw(potato rutabaga yam)]
	       },
  );


###
### Unit Tests for Myco::Entity::Meta::Attribute
###

#
# !!! NOTE: most tests for Myco::Entity::Meta::Attribute are in
# !!!     Myco::Entity::Meta::Test
#

##
##   Tests for In-Memory Behavior

sub test_type_check_func {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $attr = $test->new_testable_entity;
    eval { $attr->set_type('iset'); };
    $test->assert( ! $@, "set valid type 'iset'");
    eval { $attr->set_type('flat_hash'); };
    $test->assert( ! $@, "set valid type 'flat_hash'");

    eval { $attr->set_type('wingNut'); };
    $test->assert( $@, "set bogus type 'wingNut'");

    my $type = eval { $attr->get_type; };
    $test->assert( ! $@, "getter executes happily");
    $test->assert( (defined $type and $type eq 'flat_hash'),
		   "getter returns expected value");
}

sub test_type_defaults {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $attr = eval {
        $class->new( name => 'confirm',
                     type => 'yesno' );
    };
    $test->assert( ! $@, "attr construction with custom type okay, or not:\n\t$@");

    # What type actually got set?
    my $type = eval { $attr->get_type; };
    $test->assert( ! $@, "getter executes happily");
    $test->assert( (defined $type and $type eq 'int'),
		   "getter returns expected value");
}


sub test_sort_type_for_use_in_mvc_list {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Tests sorting options for use doing client-side sorting of a
    # MVC-generated list. This case uses a value=>label combo - i.e. the value
    # should be sorted, not the printed value.

    my %shoe_sizes = map { $_ => "Size $_" } qw(8 9 10 11 12 13 14 15 16 17);

    my $attr = $class->new
      ( name => 'size_of_my_addiddas',
	type => 'int',
        values => [ '__select__', sort keys %shoe_sizes ],
        value_labels => { %shoe_sizes },
        # sort_type would be deduced from the attribute type in any case
        # the javascript sort class uses java-style class/meth syntax,
        # i.e. SortableTable.getNumber( ['blahblah'] )
        sort_type => 'number',
        ui => { label => "yo' shoe size. word up:" }
      );
    my $sort_type = $attr->get_sort_type;
    my $sort_types_hash = $attr->get_sort_types_hash;
    $test->assert( $sort_type eq 'number' &&
                   $sort_types_hash->{$sort_type} eq 'Number',
                   'got ui sort type' );

    # See MVC::Controller::Test for further testing of this attr's behaviour

}

##
##   Tests for Persistence Behavior

# None


### Hooks into Myco test framework

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

=cut

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
