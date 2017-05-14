package Myco::Test::EntityTest;

###############################################################################
# $Id: EntityTest.pm,v 1.3 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Test::EntityTest - base class for Myco entity test classes

---these docs need expansion---

=head1 SYNOPSIS

 ### Set up an entity test class (don't do this by hand!  Use myco-mkentity!)
 ###

 package Myco::Foo::Test;

 use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

 # This class tests features of:
 my $class = 'Myco::Foo';

 my %test_parameters =
  ###  Test Control Prameters ###
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'fooattrib',

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       {
	name => 'a value',
	# Use a coderef to auto-instantiate sub-objects for ref-type
	#   attributes
	type => sub {
                   my $test = shift;
	            my $foo = Myco::Foo->new(name => 'bar');
	            # Make sure sub-object gets removed after test
		    $test->destroy_upon_cleanup($foo);
		    $foo;
		},
      },
  );

 # Example test method
 sub test_bar {
     my $test = shift;
     $test->set_type_persistence(1);  # note that this test uses the db
     return if $test->should_skip;    # skip over this test if asked

     # Create entity object with any required attributes as specified
     # in %test_parameters{defaults}
     my $obj = $test->new_testable_entity;
     $obj->save;           # save to persistent storage, if you like

     # ...do something...
     $test->assert( __something__, "no can-do");

     # Use the following to have Entity objects auto-deleted after
     # test is run
     $test->destroy_upon_cleanup($obj);
 }


 ### Running tests
 ###

 $ cd $MYCO_DISTRIB/driver
 $ ./myco-testrun Myco::Foo::Test [-T]       # run tests
                                        # '-T' enables Tangram trace mode
 $ ./tkmyco-testrun Myco::Foo::Test          # run tests, GUI style

=cut

use strict;
use base qw(Myco::Test::Fodder);
use constant ACCESSOR_VAL => 123456;

###
### Unit Tests for all Myco classes!
###

##
##   Tests of In-Memory Behavior

sub test_new_empty {
    my $test = shift;
    my $class = $test->get_class;
    my $obj;
    my $reqs = $class->required_attributes;
    if (my $numreq = keys %$reqs) {
	my $reqs_w_init = 0;
	my $inits = $class->init_defaults;
	for my $reqattr (keys %$reqs) {
	    if (exists $inits->{$reqattr}) {
		$reqs_w_init++;  # Count number of $reqs having an init_default
	    }
	}
	# There are required attributes.
	eval { $obj = $class->new };
	$test->assert($@ || $reqs_w_init == $numreq,
		      "calling new() without required attributes "
		      ."should result in an exception");
	eval { $obj = $test->new_testable_entity };
	$test->assert(! $@, "exception when calling new() with default "
		           ."test attributes:  $@");
	$test->assert(defined $obj, 'no object returned by new() test args');
    } else {
	eval { $obj = $class->new };
	$test->assert(! $@, "unexpected exception when calling new() "
		           ."called with no args: $@");
	$test->assert(defined $obj, 'no object returned by new() w/no args');
    }
}

sub test_new_bogus_args {
    my $test = shift;
    eval { $test->new_testable_entity(foo => "blah"); };
    $test->assert($@);
}

sub test_accessor {
    my $test = shift;
    my $obj = $test->new_testable_entity;
    my $simple_accessor = $test->get_params->{simple_accessor};
    return unless $simple_accessor;
    my $simple_setter = 'set_' . $simple_accessor;
    my $simple_getter = 'get_' . $simple_accessor;
    my $val = $obj->$simple_getter;
    $val = '' unless defined $val;
    $test->assert($val ne "5551212");
    $obj->$simple_setter("5551212");
    $test->assert($obj->$simple_getter eq "5551212");
}

##
##   Tests of Persistence Behavior

sub test_save {
    my $test = shift;
    $test->set_type_persistence(1);
    return if $test->should_skip;    # skip over this test if asked

    my ($id, $id2, @create_args, $attrib, $setter, $getter);
    if ($attrib = $test->get_params->{simple_accessor}) {
	@create_args = ($attrib => ACCESSOR_VAL);
	$setter = 'set_'.$attrib;
	$getter = 'get_'.$attrib;
    };

    {
	my $obj = $test->new_testable_entity(@create_args);
	$test->assert( $id = $obj->save, 'false return from ->save' );
	Myco->unload($obj);
    }
    $test->assert(! Myco->is_transient($id),
		  '$obj is was not removed from transient storage' );

    {
#        DBI->trace(2);
	my $obj = Myco->load($id);
#        DBI->trace(0);
	$test->assert(defined $obj, 'object not reloaded');
	if ($attrib) {
	    $test->assert((my $val = $obj->$getter) == ACCESSOR_VAL,
			  'object missing expected attribute');
	    $obj->$setter($val - 2000);
	    $id2 = $obj->save;
	    $test->assert($id == $id2,
			  'unexpected id returned upon object update');
	}
	Myco->unload($obj);
    }

    my $obj = Myco->load($id);
    $test->assert(defined $obj, 'object not reloaded at last stage');
    if ($attrib) {
	$test->assert($obj->$getter == ACCESSOR_VAL - 2000,
		      'object update failed');
    }
    $test->destroy_upon_cleanup($obj);
}


# Testing both $obj->destroy and Myco->destroy($obj) usage;
sub test_destroy {
    my $test = shift;
    $test->set_type_persistence(1);
    return if $test->should_skip;    # skip over this test if asked

    my $obj = $test->new_testable_entity;
    my $class = $test->get_class;
    $test->assert($obj->isa($class),
		  "m'obj ain't of class $class, it's a". ref $obj );
    my $id = Myco->insert($obj);
    # Instance method syntax
    $obj->destroy;
    $test->assert(! Myco->is_transient($id),
		  'not cleared from transient storage' );
    $test->assert( ! defined Myco->load($id),
		   'not cleared from persistent storage' );
    $test->assert( ! defined $obj, '$obj still defined' );
    # Class (Myco) method syntax
    undef $obj;
    $obj = $test->new_testable_entity;
    $id = Myco->insert($obj);
    Myco->destroy($obj);
    $test->assert( ! defined $obj, 'Class meth:  $obj made undef' );
    $test->assert(! Myco->is_transient($obj),
		  'Class meth:  not cleared from transient storage' );
    $test->assert(! defined Myco->load($id),
		   'Class meth:  not cleared from persistent storage' );
}


sub test_id {
    my $test = shift;
    $test->set_type_persistence(1);
    return if $test->should_skip;    # skip over this test if asked

    my $id = Myco->insert( my $obj = $test->new_testable_entity );
    my $id2 = $obj->id;
    $test->assert( $id == $id2,
		   "incorrect id value returned:  $id\n\t\texpecting:  $id" );
    $test->destroy_upon_cleanup($obj);
}


1;
__END__


=head1 DESCRIPTION

Base class for all Myco entity test classes.  An entity test class benefits
in two ways:

=over 3

=item *

It is tied into a Test::Unit::TestCase-based framework which takes care of
database connection worries and various other concerns.

=item *

It inherits a collection of canned tests that will automatically get run along
with any tests unique to a given entity.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Charles Owens <owensc@enc.edu>

=head1 SEE ALSO

L<Myco::Entity|Myco::Entity>,
L<Myco::Test::Suite|Myco::Test::Suite>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>

=cut

