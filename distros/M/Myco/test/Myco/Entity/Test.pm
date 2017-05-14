package Myco::Entity::Test;

###############################################################################
# $Id: Test.pm,v 1.4 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Test -

unit tests for features of Myco::Entity

=head1 DATE

$Date: 2006/03/19 19:34:08 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./myco-testrun [-m] Myco::Entity::Test
 # run tests, GUI style
 ./tkmyco-testrun Myco::Entity::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Entity.

=cut

### Inheritance
#  Myco::Test::Entity is not itself an entity class, so
#  for testing we mustn't inherit from Myco::Test::EntityTest
use base qw(Test::Unit::TestCase Myco::Test::Fodder);

### Module Dependencies and Compiler Pragma
use Myco::Entity;
use Myco::Entity::SampleEntity;
use Data::Dumper;
use Myco::Util::DateTime;
use strict;
use warnings;

### Class Data
my $testpkg = 'Myco::Entity::TestFoo';
my $samp_ent = 'Myco::Person';
use constant DATETIME => 'Myco::Util::DateTime';

my $test_attr_params = {
   name => 'meat_cooked_pref',
   tangram_options => {required => 1},
   type => 'int',
   synopsis => "How you'd like your meat cooked",
   syntax_msg => "single number: 0 through 5",
   values => [qw(0 1 2 3 4 5)],
   value_labels => {0 => 'rare',
		    1 => 'medium-rare',
		    2 => 'medium',
		    3 => 'medium-well',
		    4 => 'well',
		    5 => 'charred'},
   ui => { widget => [ popup_menu => undef ] },
 };

# This class tests features of:
my $class = 'Myco::Entity';

my %test_parameters =
  ###  Test Control Prameters ###
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'abstract',
   skip_persistence => 0,

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       { name => $testpkg },
  );


##### Sample class package used by these unit tests
package Myco::Entity::TestFoo;
use base qw(Myco::Entity);
use strict;
use warnings;
my $metadata = Myco::Entity::Meta->new(name => __PACKAGE__);

$metadata->add_attribute(name => 'name', type => 'transient');
$metadata->add_attribute(name => 'foobar', type => 'transient');
$metadata->activate_class;

##### Now back to regularly scheduled testing...
package Myco::Entity::Test;

###
### Unit Tests for Myco::Entity
###

##
##   Tests for In-Memory Behavior


use constant ENDER => 'Ender Wiggin';


sub test_introspect {
    my $test = shift;
    return if $test->should_skip;  # skip over this test if asked

    # Class method usage
    my $testmeta = eval { $testpkg->introspect; };
    $test->assert( ! $@, "call to new_metadata(): $@");
    $test->assert( defined($testmeta), '$testmeta defined');
    $test->assert( UNIVERSAL::isa($testmeta,'Myco::Entity::Meta'),
				  'we have a ::Meta object');
    $test->assert( $testmeta->name eq $testpkg, '$testmeta knows his name');

    # Instance method usage
    my $instance = eval { $testpkg->new(name => 'Valentine Wiggen'); };
    $test->assert( UNIVERSAL::isa($instance, $testpkg),
                   'we have a $testpkg object');
    $testmeta = eval { $instance->introspect; };
    $test->assert( ! $@, "call to new_metadata() as instance method: $@");
    $test->assert( defined($testmeta), '$testmeta defined');
    $test->assert( UNIVERSAL::isa($testmeta,'Myco::Entity::Meta'),
				  'we have a ::Meta object');
}

##
##   Tests for Persistence Behavior
#

sub _test_createdate_template_attr {
    my $test = shift;
    return if $test->should_skip;  # skip over this test if asked

    my $date = DATETIME->date('YYYY-MM-DD');
    my $entity = $samp_ent->new( last => 'cod' );
    $entity->save;
    Myco->unload($entity);
    my $ent_ = Myco->remote($samp_ent);
    my @ents = Myco->select($ent_, $ent_->{last} eq 'cod');

    $test->assert( ($ents[0]->get_createdate_ || '') eq $date,
                   'create date was set' );

#    $test->destroy_upon_cleanup( @ents );
}


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

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity|Myco::Entity>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<myco-testrun|testrun>,
L<tkmyco-testrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<myco-mkentity|mkentity>
