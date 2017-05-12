package Myco::Base::Entity::Meta::Test;

###############################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:03 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::Test -

unit tests for features of Myco::Base::Entity::Meta

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=head1 DATE

$Date: 2004/11/22 19:16:03 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./testrun [-m] Myco::Base::Entity::Meta::Test
 # run tests, GUI style
 ./tktestrun Myco::Base::Entity::Meta::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Base::Entity::Meta.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Base::Entity::Meta;
use Myco::Base::Entity::SampleEntity;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Base::Entity::Meta';

# Names of sample class packages used by these unit tests
my $testpkg1 = 'Myco::Base::Entity::Meta::TestFoo';
my $testpkg2 = 'Myco::Base::Entity::Meta::TestBar';
my $testpkg3 = 'Myco::Base::Entity::Meta::TestBaz';

my %test_parameters =
  ###  Test Control Prameters ###
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'abstract',

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   standalone => 1,

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       { name => $testpkg1 },
  );

my $test_attr_params =
  { name => 'meat_cooked_pref',
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
    ui => { label => "Cook until..",
	    options => { hidden => 1 },
	  },
  };

# Name of sample entity class used in a number of tests
my $samplepkg = 'Myco::Base::Entity::SampleEntity';

use constant META_UI => 'Myco::Base::Entity::Meta::UI';

# Tests are numbered... set to number for test specific debug output
# or -1 for all
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;


##### Sample class packages used by these unit tests

package Myco::Base::Entity::Meta::TestFoo;
use base qw(Myco::Base::Entity);
use strict;
use warnings;
our $schema =
  {
   table => 'foo',
   fields =>
   { string =>
     { name => { required => 1 },
       foobar => undef,
       valentine => { sql => 'VARCHAR(53)'},
     },
     int => [qw(int_one int_two)],
    },
  };

package Myco::Base::Entity::Meta::TestBar;
use base qw(Myco::Base::Entity);
use strict;
use warnings;

package Myco::Base::Entity::Meta::TestBaz;

use constant BASECLASS => 'Myco::Base::Entity::Meta::TestFoo';
use base BASECLASS;
use strict;
use warnings;
our $schema =
  {
   table => 'baz',
   bases => [ BASECLASS ],
   fields =>
    { string =>
	{
          yowzer => undef,
	},
    },
  };


package Myco::Base::Entity::Meta::TestOof;
use base qw(Myco::Base::Entity);
my $metadata = Myco::Base::Entity::Meta->new(name => __PACKAGE__);


##### Now back to regularly scheduled testing...
package Myco::Base::Entity::Meta::Test;

###
### Unit Tests for Myco::Base::Entity::Meta
###

##
##   Tests for In-Memory Behavior


use constant ENDER => 'Andrew Wiggin';

sub test_get_attributes {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked
    my $meta = Myco::Base::Entity::Meta->new(name => 'Peter Wiggin');
    my $attributes = $meta->get_attributes;
    $test->assert(defined($attributes) && ref($attributes) eq 'HASH',
		  "called with no added attribs returns ref to empty hash");
}

sub test_activate_class_w_previous_schema {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    ### Now testing the activation of schema w/ existing $schema
#    my $meta = Myco::Base::Entity::Meta->new(name => $testpkg1);

#    eval { $meta->activate_class; };
#    $test->assert( ! $@, "exception during schema activation: $@");
    my $meta = $test->_activate_testpkg1;

    # Cool... can we use this class now?
    my $instance = eval { $testpkg1->new(name => ENDER); };
    $test->assert( ! $@, "exception suggests class not activated: $@");
    $test->_activate_class_assertions($instance, $meta, 'foo');
}

sub _activate_testpkg1 {
    my $test = shift;

    # Is it already activated?
    my $meta = eval { $testpkg1->introspect; };
    unless ( defined $meta and $meta->get_name eq $testpkg1 ) {
        $meta = Myco::Base::Entity::Meta->new(name => $testpkg1);
        eval { $meta->activate_class; };
        $test->assert( ! $@, "exception during schema activation: $@");
    }
    return $meta;
}

sub test_activate_class_w_previous_schema_and_inheritence {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Hmm... we can't depend on order of test execution
    $test->_activate_testpkg1;

    ### Now testing the activation of schema w/ existing $schema
    my $meta = Myco::Base::Entity::Meta->new(name => $testpkg3);

    eval { $meta->activate_class; };
    $test->assert( ! $@, "exception during schema activation: $@");

    # Cool... can we use this class now?  Inheritence, even
    my $instance = eval { $testpkg3->new(name => ENDER); };
    $test->assert( ! $@, "exception setting inherited attrib 'name': $@");
    $test->_activate_class_assertions($instance, $meta, 'baz');
}

# common assertions for two tests above
sub _activate_class_assertions {
    my ($test, $instance, $meta, $table) = @_;

    my $name = eval { $instance->get_name; };
    $test->assert( ! $@, "exception during getter: $@");
    $test->assert( $name eq ENDER, "getter returns expected value");

    # Do we have class-level metadata specified in the old $schema style?
    my $tangram_opts = $meta->get_tangram;
    $test->assert(defined($tangram_opts)
                  && $tangram_opts->{table} eq $table,
		  'table name metadata');

    # Do we have metadata for inherited attributes ?
    my $attrs = $meta->get_attributes;
    my $attr = $attrs->{name};

    $test->assert(defined($attr) && $attr->get_type eq 'string',
		  'old style string attr has metadata');

    my $attr_name = $attr->get_name;
    $test->assert(defined($attr_name) && $attr_name eq 'name',
		  '"name" from metadata is correct');

    $attr = $attrs->{int_two};
    $test->assert(defined($attr) && $attr->get_type eq 'int',
		  'old style int attr has metadata');
    # ... how about string length parsed from 'sql' option?
    $attr = $attrs->{valentine};
    $test->assert(defined $attr->{type_options}, 'type_option exists');
    $test->assert(defined($attr->{type_options}{string_length})
		  && $attr->{type_options}{string_length} == 53,
		  'type_option has expected value');

    $test->assert(defined $attr->{type_options}, 'type_option exists');
}


sub test_activate_class_no_previous_schema {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    ### Now testing the activation of schema after add_attribute call
    #  package has no previously existing $schema

    my $meta = Myco::Base::Entity::Meta->new(name => $testpkg2);

    eval { $meta->add_attribute(name => 'name', type => 'string'); };
    $test->assert( ! $@, "add_attribute() 'name' call: $@");
    eval { $meta->add_attribute(%$test_attr_params); };
    $test->assert( ! $@, "add_attribute() 'doneness' call: $@");
    eval { $meta->add_attribute(name => 'ramen',
				type => 'string',
				type_options => { string_length => 42 }); };
    $test->assert( ! $@, "add_attribute() 'ramen' call: $@");

    # Wonder Twin Powers, Activate!
    eval { $meta->activate_class; };
    $test->assert( ! $@, "schema activation 2: $@");

    my $testschema;
    {
	no strict "refs";
	$testschema = ${"${testpkg2}::schema"};
    }
    $test->assert( defined $testschema, 'package var $schema now exists');

    # Okay... do we really have a new entity attribute?
    my $instance = eval { $testpkg2->new(name => ENDER); };
    $test->assert( defined($@) && $@ =~ /missing req.*meat_cooked_pref/,
		   "new attribute is required, exception expected");
    $instance = eval { $testpkg2->new(name => ENDER, meat_cooked_pref => 2); };
    $test->assert( ! $@, "new() called with added attribute: $@");
    my $cookpref = eval { $instance->get_meat_cooked_pref ; };
    $test->assert( ! $@, "exception during getter: $@");
    $test->assert( $cookpref == 2, "getter returns expected value");

    # Did $scheam 'sql' option get generated from 'type_options'?
    my $ramen = $testschema->{fields}{string}{ramen};
    my $sqlopt = $testschema->{fields}{string}{ramen}{sql};
    $test->assert( defined $ramen, 'ramen attr in $schema');
    $test->assert( defined $sqlopt, 'sql opt in $schema');
    $test->assert( $sqlopt eq 'VARCHAR(42)', 'sql opt correct value');

    # Did $meta ui attribute_options get set up?
    my $attr_opts = $meta->get_ui->get_attribute_options;
    $test->assert(ref $attr_opts eq 'HASH', 'a hash');
    $test->assert(exists $attr_opts->{hidden}, 'an option is present');
    $test->assert(ref $attr_opts->{hidden} eq 'ARRAY', 'an array');
    $test->assert(@{ $attr_opts->{hidden} } == 1, 'maybe one hidden attr');
    $test->assert(defined $attr_opts->{hidden}[0], 'one hidden attr defined');
    $test->assert($attr_opts->{hidden}[0] eq 'meat_cooked_pref',
                  'the expected hidden attr!');

    # Did correct default widget type get set for an attrib with 'values' set?
    my $widg = eval {
        $meta->get_attributes->{meat_cooked_pref}-> get_ui->get_widget->[0];
    };
    $test->assert(! $@, "no trouble looking up widget name:  $@");
    $test->assert($widg eq 'popup_menu',
                  "got us correct default widget... or not:  $widg");
}

sub test_add_attribute {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $meta = Myco::Base::Entity::Meta->new(name => $testpkg1);

    eval { $meta->add_attribute(%$test_attr_params); };
    $test->assert( ! $@, "exception during add_attribute() call: $@");
    $test->assert(exists $meta->{attributes},
		  "attribute hash exists after add_attribute()");
    $test->assert(exists $meta->{attributes}{meat_cooked_pref},
		  "new attribute entry exists after add_attribute()");
    $test->assert(UNIVERSAL::isa($meta->{attributes}{meat_cooked_pref},
				 'Myco::Base::Entity::Meta::Attribute'),
		  "new attribute isa ::Attribute");
    $test->assert($meta->{attributes}{meat_cooked_pref}->get_name
                  eq 'meat_cooked_pref',
		  "new attribute object has name initialized");
}

sub test_add_query {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $meta = Myco::Base::Entity::Meta->new( name => $testpkg1 );

    eval {
        $meta->add_query( name => 'default',
                          description => 'the default query',
                          remotes => { '$testfoo_' => $testpkg1 },
                          result_remote => '$testfoo_',
                          filter => { parts =>
                                      [ { remote => '$testfoo_',
                                          attr => 'meat_cooked_pref',
                                          oper => '==',
                                          param => 'rare_med_done' }
                                      ]
                                    }
                        );
    };
    $test->assert( ! $@, "exception during add_query() call: $@");
}


#     Yep... I've been a bit cut-and-paste happy...

# Let's test this for real!
sub test_basic_behavior_with_real_class {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $testschema;
    {
	no strict "refs";
	$testschema = ${"${samplepkg}::schema"};
    }
    # Let's get ourselves an instance
    my $instance = eval { $samplepkg->new(name => ENDER); };
    $test->assert( ! $@, "creating instance: $@");

    # Test use of attrib defined via $schema
    my $name = eval { $instance->get_name; };
    $test->assert( ! $@, "exception during getter: $@");
    $test->assert( $name eq ENDER, "getter returns expected value");
    # Test use of attrib defined via add_attribute()
    my $fish = eval { $instance->set_fish('carp'); };
    $test->assert( ! $@, "exception during set of added attr: $@");
    $fish = eval { $instance->get_fish; };
    $test->assert( $fish eq 'carp', "fish getter returns expected value");

    # Fetch metadata
    my $meta = eval { $instance->introspect; };
    $test->assert( ! $@, "retrieved class metadata object: $@");

    # Verify metadata basics
    my $m_name = $meta->get_name;
    $test->assert(( defined $m_name and $m_name eq $samplepkg ),
                   "metadata knows class name");
    my $m_syn = $meta->get_synopsis;
    $test->assert(( defined $m_syn and $m_syn eq 'FOO!' ),
                   "metadata knows class synopsis");

    #### Test inherited class level metadata

    #  At present this access_list is the only one
    my $acl = eval { $meta->get_access_list };
    $test->assert( (ref $acl eq 'HASH') && exists $acl->{rw},
                  'got inherited access_list');

    #### Test inherited attribute metadata

    # Test old-style inherited attribute
    #   Did our metadata tangram_option => bases ...   get handled?
    $test->assert(defined $testschema->{bases}, 'bases $schema key defined');
    $test->assert($testschema->{bases}[0] eq "${samplepkg}Base",
		  'bases schema key looks good');
    #   Can we use it?
    $test->_grok_inherited_attrib($meta, $instance,
                                  'heybud', 'string', 'Larry', 'textfield');

    # Test Meta-defined inherited attribute - let's play chicken
    my $attrmeta = $test->_grok_inherited_attrib($meta, $instance,
                                                 'chicken', 'int', '3',
                                                 'radio_group');
    $test->assert($attrmeta->get_value_labels->{3} eq 'Leghorn',
                  'got some chicken val labels');
    $test->assert($attrmeta->get_ui->get_label eq 'Yummy',
                  'got some chicken ui metadata');


    ## Test Meta-defined inherited attribute with override

    $attrmeta = $test->_grok_inherited_attrib($meta, $instance,
                                              'color', 'string', 'blue',
                                              'popup_menu');
    # a metadatum inherited as is
    $test->assert($attrmeta->get_synopsis eq 'Gimme Color',
                  'color synopsis happily inherited');


# After Class::Tangram overhaul - why doesn't this pass?

    # snoop the override
#    $test->assert($attrmeta->get_ui->get_label eq 'Gotcha!',
#                  'color label happily overridden in subclass');

}


sub _grok_inherited_attrib {
    my ($test, $meta, $instance, $attr, $type, $value, $widget_name) = @_;

    #   See if we can use the attrib
    my $setter = 'set_'.$attr;
    my $getter = 'get_'.$attr;
    eval { $instance->$setter($value); };
    $test->assert( ! $@, "exception during set of inherited attr $attr: $@");
    my $gotval = eval { $instance->$getter; };
    $test->assert( $gotval eq $value, "$attr getter returns expected value");

    #   Do we have metadata for this inherited attribute?
    $test->assert(UNIVERSAL::isa($meta, 'Myco::Base::Entity::Meta'),
		  'we have us a ::Meta object');
    my $attrmeta = $meta->get_attributes->{$attr};
    $test->assert(defined $attrmeta, "attr $attr has metadata");
    $test->assert($attrmeta->get_type eq $type,
                  "attr '$attr' metadatum 'type'");

    #   Poke about the ui attr metadata
    my $ui = eval { $attrmeta->get_ui };
    $test->assert(UNIVERSAL::isa($ui,
                                 'Myco::Base::Entity::Meta::Attribute::UI'),
		  "for attr '$attr' we have us a ::Meta::Attr::UI object. "
                  .'ref $ui=='. ref $ui);
    my $widget = $ui->get_widget;
    $test->assert(defined(@$widget) && @$widget,
                  "widget is set for attr $attr");
    $test->assert($widget->[0] eq $widget_name,
                "for attr '$attr' inherited widget spec looks good...\n"
                  ."\tor not:  wanted '$widget_name', got '$widget->[0]'")
      if $widget_name;

    return $attrmeta;
}


sub test_displayname {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $instance = eval { $samplepkg->new(name => ENDER); };
    $test->assert( ! $@, "creating instance: $@");

    ## Use the displayname... on a class/instance without one set
    my $ident = eval { $instance->displayname; };
    $test->assert( !$@,
		   "no exception for non-displayname-customized object: $@");
    $test->assert(( defined $ident && $ident eq $samplepkg ),
                  "class name returned");


    my $md = $samplepkg->introspect;

    ## Use the ui_displayname... specified with bogus setting
    eval {
	$test->_metadata_dibble($md, {});
    };
    $test->assert( $@ , "exception with dname not scalar or codref");

    ## Use the ui_displayname... specified as an attribute name
    $test->_metadata_dibble($md, 'name');
    $ident = eval { $instance->displayname; };
    $test->assert( !$@ , "no exception for ui_displayname-capable object: $@");
    $test->assert( $ident eq ENDER, "expected value, dname as attribute name");

    ## Use the ui_displayname... specified as a code ref
    $test->_metadata_dibble($md, sub { shift->get_name });
    $ident = eval { $instance->displayname; };
    $test->assert( !$@ , "no exception w/ ui_displayname-capable object: $@");
    $test->assert( $ident eq ENDER, "expected value, dname as coderef");
}


sub test_readonly {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $instance = eval { $samplepkg->new(name => ENDER); };
    my $attrs = eval { $instance->introspect->get_attributes; };
    $test->assert( ! $@, "retrieved attributes metadata hash: $@");

    ### grok metadata
    #  fish is not readonly (by default)
    my $is_readonly = eval { $attrs->{fish}->get_readonly; };
    $test->assert( ! $@, 'got readonly meta');
    $test->assert(defined $is_readonly && ! $is_readonly, 'fish RW');

    #  chips is readonly
    $is_readonly = eval { $attrs->{chips}->get_readonly; };
    $test->assert( ! $@, 'got readonly meta');
    $test->assert( $is_readonly, 'chips RO');

    ### try forbidden accessors
    eval { $instance->set_chips(27) };
    $test->assert(my $err = $@, "Call of set_chips() choked");
    $test->assert(UNIVERSAL::isa($err, 'Myco::Exception::MNI'),
                  "Correct exception thrown");

    eval { $instance->chips };
    $test->assert($err = $@, "Call of chips() choked");
    $test->assert(UNIVERSAL::isa($err, 'Myco::Exception::MNI'),
                  "Correct exception thrown again");
}


sub test_attr_accessor_coderef {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $instance = eval { $samplepkg->new(name => ENDER); };
    my $attrs = eval { $instance->introspect->get_attributes; };
    $test->assert( ! $@, "retrieved attributes metadata hash: $@");

    # getter
    my $val = eval { $attrs->{name}->get_getter->($instance) };
    $test->assert( ! $@, "getter call: $@");
    $test->assert( $val eq ENDER, "getter got good");
    # setter
    eval { $attrs->{name}->get_setter->($instance, 'Geddy Lee') };
    $test->assert( ! $@, "setter call: $@");
    $test->assert($instance->get_name eq 'Geddy Lee', "setter sot sood"); # ;-)
}

sub test_attr_setget_meths {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $instance = eval { $samplepkg->new(name => ENDER); };
    $test->assert( ! $@, "instantiation: $@");
    my $attrs = eval { $instance->introspect->get_attributes; };
    $test->assert( ! $@, "retrieved attributes metadata hash: $@");

    # get
    my $val = eval { $attrs->{name}->getval($instance) };
    $test->assert( ! $@, "getval call: $@");
    $test->assert( $val eq ENDER, "getval got good");
    # setter
    eval { $attrs->{name}->setval($instance, 'Geddy Lee') };
    $test->assert( ! $@, "setval call: $@");
    $test->assert($instance->get_name eq 'Geddy Lee', "setval sot sood"); # ;-)
}

sub test_get_ui {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $meta = $test->new_testable_entity;
    # does get_ui construct new ::UI obj if none exists?
    my $ui = $meta->get_ui;
    $test->assert(defined($ui)
		  && UNIVERSAL::isa($ui, META_UI), "oh...mah-gosh..." );
}


sub test_set_ui {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $meta = $test->new_testable_entity;
    $meta->set_ui;
    my $ui = $meta->get_ui;
    $test->assert(defined($ui)
		  && UNIVERSAL::isa($ui, META_UI), "oh...mah-gosh..." );
}


sub _metadata_dibble {
    my ($test, $md, $idspec) = @_;
    # tweak our sample class def on the fly (unthinkable!) to
    #  make it ui_displayname happy
    $md->get_ui->set_displayname($idspec);
    {
	# suppress squawking about introspect() getting redefined
	local %SIG;
	$SIG{__WARN__} = sub {};
	# make it so
	$md->activate_class;
    }
    # my head hurts
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

Copyright (c) 2004 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Base::Entity::Meta|Myco::Base::Entity::Meta>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<testrun|testrun>,
L<tktestrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<mkentity|mkentity>
