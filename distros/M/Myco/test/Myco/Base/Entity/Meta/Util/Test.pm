package Myco::Base::Entity::Meta::Util::Test;

###############################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:04 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::Util::Test -

unit tests for features of Myco::Base::Entity::Meta::Util

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=head1 DATE

$Date: 2004/11/22 19:16:04 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./testrun [-m] Myco::Base::Entity::Meta::Util::Test
 # run tests, GUI style
 ./tktestrun Myco::Base::Entity::Meta::Util::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Base::Entity::Meta::Util.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::Fodder);

### Module Dependencies and Compiler Pragma
use Myco::Base::Entity::Meta;
use Myco::Base::Entity::Meta::Util;
use Myco::Base::Entity::Meta::Attribute;
use Myco::Base::Entity::Meta::Attribute::UI;

use Myco::Base::Entity::SampleEntityBase;

use Data::Dumper;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Base::Entity::Meta::Util';

# It may be helpful to number tests... use testrun's -d flag to view
#   test-specific debug output (see example tests, testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;
use constant META => 'Myco::Base::Entity::Meta';
use constant META_ATTR => META . '::Attribute';
use constant META_ATTR_UI => META_ATTR . '::UI';
use constant SAMPENT => 'Myco::Base::Entity::SampleEntityBase';

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
#	name => 'a value',
	# Use a coderef to auto-instantiate sub-objects for ref-type attributes
#	type => sub {
#                   my $test = shift;
#	            my $foo = Myco::Base::Entity::Meta::Util->new(name => 'bar');
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
### Unit Tests for Myco::Base::Entity::Meta::Util
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################

sub test_1_clone_basic {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $cloned = $test->_test_1_2_assertions;
    $test->assert( ref $cloned->{ui} eq META_ATTR_UI,
                   "GRACE, he wants you to say DAH BLESSING" );
}


sub test_2_clone_basic_dont_bless {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $cloned = $test->_test_1_2_assertions( dont_bless => 1 );
    $test->assert( ref $cloned->{ui} eq 'HASH', 'no blessing for you!' );
}


sub _test_1_2_assertions {
    my ($test, %params) = @_;

    my $sample = _samp_attr_spec();
    my $typedef = _samp_typedef();

#    bless $typedef, META_ATTR;

    # Before... 'ui' not blessed
    $test->assert( ref $sample->{ui} eq 'HASH', "no blessing" );

    $test->db_out( "Data before cloning:\n" . Dumper($sample) ) if DEBUG;

    # Lets be ethically questionable!  ;-)
    my $cloned = $class->clone( $sample, $typedef, %params );

    $test->db_out( "Cloned result:\n" . Dumper($cloned) ) if DEBUG;

    ### First level

    # Scalar - inhertited
    $test->assert( defined $cloned->{synopsis}, "got synopsis" );
    # Scalar - overriden
    $test->assert( scalar $cloned->{name} =~ /^date/,
                   "name spec overrides default" );
    # Array of scalars - inherited
    $test->assert( $cloned->{array}[0] eq 'copied', "array val correct" );
    $test->assert( $cloned->{array} != $typedef->{array},
                   "array copied by _value_, not reference" );
    # Array of scalars - overridden
    $test->assert( $cloned->{array2}[0] eq 'yes', "array val: override" );

    # Hash of scalars - inherited w/ some override
    $test->assert( $cloned->{hash}{local} eq 'thingy', "local thing" );
    $test->assert( exists $cloned->{hash}{over}, "override" );
    $test->assert( $cloned->{hash}{over} eq 'ridden', "override val" );
    $test->assert( exists $cloned->{hash}{copied}, "inherited" );
    $test->assert( $cloned->{hash}{copied} eq 'directly', "inherited" );

    ### Next level

    $test->assert( defined $cloned->{ui}{widget}, "got widget" );
    $test->assert( scalar $cloned->{ui}{label} =~ /^Got/,
                   "ui label spec overrides default" );

    return $cloned;
}


sub test_3_clone__enter_objects {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $sample = _samp_attr_spec();
    my $typedef = _samp_typedef();

    bless $sample, META_ATTR;
    bless $typedef, META_ATTR;

    my $cloned = $class->clone( $sample, $typedef, enter_objects => 0 );
    $test->db_out( "Cloned result:\n" . Dumper($cloned) ) if DEBUG;

    $test->assert( ! exists $cloned->{ui}{widget}, "no inherited widget" );
    $test->assert( scalar $cloned->{ui}{label} =~ /^Got/, "ui label" );
}


# Valid... but no assertions at present
sub _test_4_clone_w_real_metadata {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $super = SAMPENT->introspect;

    my $int_typedef = { ui => [ 'textbox' ] };
    my $sub = bless( { name => 'Treebeard',
                       attributes => { ent => bless( { name => 'ent',
                                                       type => 'string',
                                                     }, META_ATTR ),
                                     },
                    }, META);

    my $cloned = $class->clone( $sub, $super );
    $test->db_out( "Cloned result:\n" . Dumper($cloned) ) if DEBUG;

    $test->assert( ! exists $cloned->{ui}{widget}, "no inherited widget" );
};

##############################################################################
### Util functions

sub _samp_attr_spec {
    return {
            name => 'date_married',
            type => 'rawdate',
            ui => {
                   label => 'Got hitched on',
                  },
            hash => { over => 'ridden',
                      local => 'thingy', },
            array2 => [qw(yes please)],
           };
}

sub _samp_typedef {
    return {
            name => 'some_date',
            synopsis => "fer storin' dates",
            ui => bless( { widget => ['textfield', -size => '12',
                                              -maxlength => '10', ],
                                   label => 'dah date',
                         }, META_ATTR_UI ),
            array => [qw(copied directly)],
            array2 => [qw(no thanks)],
            hash => { copied => 'directly',
                      over => 'water' },
           };
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

L<Myco::Base::Entity::Meta::Util|Myco::Base::Entity::Meta::Util>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<testrun|testrun>,
L<tktestrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<mkentity|mkentity>
