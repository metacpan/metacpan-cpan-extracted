package Myco::Base::Entity::Meta::Attribute::UI::Test;

###############################################################################
# $Id: Test.pm,v 1.1.1.1 2004/11/22 19:16:04 owensc Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Base::Entity::Meta::Attribute::UI::Test -

unit tests for features of Myco::Base::Entity::Meta::Attribute::UI

=head1 VERSION

$Revision: 1.1.1.1 $

=cut

our $VERSION = (qw$Revision: 1.1.1.1 $ )[-1];

=head1 DATE

$Date: 2004/11/22 19:16:04 $

=head1 SYNOPSIS

 cd $MYCO_DISTRIB/bin
 # run tests.  '-m': test just in-memory behavior
 ./testrun [-m] Myco::Base::Entity::Meta::Attribute::UI::Test
 # run tests, GUI style
 ./tktestrun Myco::Base::Entity::Meta::Attribute::UI::Test

=head1 DESCRIPTION

Unit tests for features of Myco::Base::Entity::Meta::Attribute::UI.

=cut

### Inheritance
use base qw(Test::Unit::TestCase Myco::Test::EntityTest);

### Module Dependencies and Compiler Pragma
use Myco::Base::Entity::Meta::Attribute::UI;
use Myco::Base::Entity::Meta::Attribute;
use strict;
use warnings;

### Class Data

# This class tests features of:
my $class = 'Myco::Base::Entity::Meta::Attribute::UI';

# It may be helpful to number tests... use testrun's -d flag to view
#   test-specific debug output (see example tests, testrun)
use constant DEBUG => $ENV{MYCO_TEST_DEBUG} || 0;

use constant META_ATTR => 'Myco::Base::Entity::Meta::Attribute';

use constant OHNO => 'MrBill';

##############################################################################
#  Test Control Parameters
##############################################################################
my %test_parameters =
  (
   # A scalar attribute that can be used for testing... set to undef
   #    to disable related tests
   simple_accessor => 'label',

   skip_persistence => 1,     # skip persistence tests?  (defaults to false)
   standalone => 1,           # don't compile Myco entity classes

   # Default attribute values for use when constructing objects
   #    Needed for any 'required' attributes
   defaults =>
       {
        attr => META_ATTR->new( name => 'flavor', type => 'string' )
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
### Unit Tests for Myco::Base::Entity::Meta::Attribute::UI
###
##############################################################################
#   Tests of In-Memory Behavior
##############################################################################


sub test_cgi_closures {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Do we have all expected closures?
    my ($meths, @names) = $class->get_CGIclosures;
    my @missing = grep {!exists $meths->{$_}} @names;
    $test->assert(! @missing, "closure generation failed for: "
		               .join(', ', @missing) );
    # Can we use one?
    my $html = $meths->{button}->(CGI->new, formname=>'baloney',
				  -name => 'foo', -onClick => 'bar');
    $test->assert(scalar $html =~ /type="button"/, "CGI meth closure works" );
}


sub test_chk_options {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $foo_attr = META_ATTR->new( name => 'ring_ding', type => 'string' );

    eval { $class->new( options => '', attr => $foo_attr ); };
    $test->assert(scalar $@ =~ /must be hashref/, 'scalar not nice');

    eval { $class->new( options => [], attr => $foo_attr ); };
    $test->assert(scalar $@ =~ /must be hashref/, 'arrayref not nice');

    # empty is okay
    eval { $class->new( options => {}, attr => $foo_attr ); };
    $test->assert(! $@, 'empty is hunkydory');

    # bogus opt
    my $obj;
    eval { $obj = $class->new( options => { Doh => 1 }, attr => $foo_attr ); };
    $test->assert(scalar $@ =~ /unknown option/,
		  'no thanks');

    # valid opt
    eval { $obj = $class->new( options => { hidden => 1},
                               attr => $foo_attr );
       };
    $test->assert(! $@, 'empty is hunkydory');
}


sub test_chk_widget {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    eval {
	$class->new( widget => ['dingo', -columns=>2, -rows=>3] );
    };
    $test->assert(scalar $@ =~ /unknown CGI form method/,
		  'bogus ui method');
}


sub test_1_prepare_widget {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $attr = META_ATTR->new
      ( name => 'doneness',
	tangram_options => { required => 1},
	type => 'int',
	synopsis => "How you'd like your meat cooked",
	syntax_msg => "correct format, please!",
	values => [qw(__select__ 0 1 2 3 4 5)],
	value_labels => {0 => 'rare',
			 1 => 'medium-rare',
			 2 => 'medium',
			 3 => 'medium-well',
			 4 => 'well',
			 5 => 'charred'},
	ui => { widget => ['popup_menu'] }
      );

    my $CGI = CGI->new;
    my $code = $attr->get_ui->get_closure;
    $test->assert( ref $code eq 'CODE',
		   "ui_closure is now defined" );
    my $html = $code->($CGI, '', -name=>'foo', formname=>'Zippy');

    $test->db_out($html) if DEBUG;

    # expecting 7 option elements... one per value plus the '<Select>' choice
    $test->assert( @{[$html =~ m{[^/](option)}gs]} == 7, 'correct number of option elems');

    my $ui = $attr->get_ui;
    # Test with cgi method args
    $ui->set_widget(['radio_group', -columns=>2, -rows=>3]);
    $ui->create_closure;
    $code = $ui->get_closure;
    $html = $code->($CGI, '', -name=>'foo', formname=>'Zippy');
    $test->db_out($html) if DEBUG;
    $test->assert( @{[$html =~ m{[^/](tr)}gs]} == 3, 'correct number of rows');
    $test->assert( scalar $html !~ m{size}, 'no size attrib');
}



sub test_2_prepare_ui_whacked_radio_group_bug {
    # Here we learn that the -value parameter doesn't have exactly the same
    # effect for all CGI form methods.  So, in the end, not really a bug,
    # just not what was expected.

    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $CGI = CGI->new;

    my $attr = META_ATTR->new
                 (name => 'gender',
		  type => 'string',
		  type_options => { string_length => 1 },
		  tangram_options => { sql => 'CHAR(1)' },
		  values => [qw(m f)],
		  value_labels => { m => 'male', f => 'female' },
		  ui => { label => 'Yer gendre ?',
			  widget => [ 'radio_group', -default => 'none' ] }
		 );
    my $code = $attr->get_ui->get_closure;

    # Passing -value to attempt to set 'm' as the default... but
    # this gets interpreted as the singular version of -values, overriding
    # that parameter.
    my $html = $code->($CGI, '', -name  => 'gender',
		             -value => 'm',
		             formname => 'Sir_NotAppearingInThisFilm');
    $test->assert($html =~ /(<input ){1}/g, 'just one input widget!');
    $test->db_out($html) if DEBUG;

    # This time we set the default via presetting the form param.
    $CGI->param('gender', 'm');
    $html = $code->($CGI, '', -name  => 'gender',
		             formname => 'Sir_NotAppearingInThisFilm');
    $test->assert($html =~ /(<input ){2}/g, 'a choice is provided!');
    $test->db_out($html) if DEBUG;
}


sub test_3_prepare_ui_string_default {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $CGI = CGI->new;

    # Test textfield as a default for this type
    my $attr = META_ATTR->new
      ( name => 'name',
	type => 'string',
	type_options => { string_length => 32 },
	synopsis => "your john hancock",
	syntax_msg => "correct format, please!",
	ui => { suffix => "bogus text" },
      );
    my $ui = $attr->get_ui;

    my $code = $ui->get_closure;
    $test->assert(defined $code && ref $code eq 'CODE',
                  'got ui closure coderef');
    my $html = $code->($CGI, '', -name=>'foo', formname=>'Zippy');

    $test->db_out($html) if DEBUG;

    $test->assert(scalar $html =~ m{size="32"}, 'field size set from string_length');

    # Test generation of proper metadata for this default widget
    my $widget = $ui->get_widget;
    $test->assert(defined $widget, 'got something');
    $test->assert(ref $widget eq 'ARRAY', 'looks widgety');
    $test->assert(@$widget, 'looks widgety and not empty!');
    $test->assert($widget->[0] eq 'textfield', 'happy widget!');
}


sub test_4_prepare_ui_string_default_w_values {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $CGI = CGI->new;

    # Test popup_menu as default if 'values' is set
    my $attr = META_ATTR->new
      ( name => 'name',
	type => 'string',
	type_options => { string_length => 32 },
	synopsis => "your john hancock",
	syntax_msg => "correct format, please!",
	values => [qw(__select__ a b c)],
	ui => { suffix => "bogus text" },
      );
    my $ui = $attr->get_ui;
    $test->assert(defined $ui, 'got ui');
		
    my $code = $ui->get_closure;
    $test->assert(defined $code && ref $code eq 'CODE',
                  'got ui closure coderef');

    my $html = $code->($CGI, '', -name=>'foo', formname=>'Zippy');
    $test->db_out($html) if DEBUG;

    $test->assert(defined $html
		  && scalar $html =~ /value="__select__">&lt;Select/,
		  'select choice is there');
    # expecting 4 option elements
    $test->assert( @{[$html =~ m{<(option)}gs]} == 4,
		   'correct number of option elems');
}


sub test_5_prepare_ui_string_default_w_other_values {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $CGI = CGI->new;

    # Test popup_menu as default if 'values' is set
    my $attr = META_ATTR->new
      ( name => 'attr_ui_test',
	type => 'string',
	type_options => { string_length => 32 },
	synopsis => "your john hancock",
	syntax_msg => "correct format, please!",
	values => [qw(a b c d e __other__)],
	ui => { suffix => "bogus text", },
      );
    my $ui = $attr->get_ui;
    my $code = $ui->get_closure;

    $test->assert(defined $code && ref $code eq 'CODE',
                  'got ui closure coderef');
    my $html = $code->($CGI, '', -name=>'attr_ui_test', formname=>'Zippy');
    $test->db_out($html) if DEBUG;

    # expecting 6 option elements... one per value plus the '<Other>' choice
    $test->assert( @{[$html =~ m{<(option)}gs]} == 6,
		   'correct number of option elems');

    # is choice 'other' NOT selected?
    $test->assert(scalar $html !~ /selected [^>]+
		                      value="__other__"  /x,
		  'other is NOT selected');

    # is the 'other' textfield element present?
    $test->assert(scalar $html =~ /Other: .+
	                           type="text"[^>]+
		                   name="\*otherValue_attr_ui_test"/x,
		  'got me some *otherValue_[attrname]');

    $test->assert(scalar $html =~ /erValue_attr_ui_test[^>]+
		                   maxlength="32"  /x,
		  'textfield size is good');


    ## Now calling as if attr already has value
    $html = $code->($CGI, OHNO, -name=>'attr_ui_test', formname=>'Zippy');
    $test->db_out($html) if DEBUG;

    $test->assert(defined $html, 'got some output');

    $test->assert(scalar $html =~ /selected [^>]+
		                      value="__other__"  /x,
		  'other is selected');
    my $mrbill = OHNO;
    $test->assert(scalar $html =~ /name="\*otherValue_attr_ui_test"[^>]+
		                   value="$mrbill"/xo,
		  '*otherValue_attr_ui_test correct');
}


sub test_6_prepare_ui_rawdate {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $CGI = CGI->new;

    # Test popup_menu as default if 'values' is set
    my $attr = META_ATTR->new
      ( name => 'name',
	type => 'rawdate',
      );
    my $ui = $attr->get_ui;
    my $code = $ui->get_closure;

    my $html = $code->($CGI, '', -name=>'foo', formname=>'Zippy');
    $test->db_out($html) if DEBUG;

    $test->assert(defined $html
		  && scalar $html =~ /size="12"
                                      .*
                                      href="javascript:.*"/x,
		  'looks suspiciously like what is expected');
    # ;-)  ...just can't help myself
}


sub test_7_do_query {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    my $attr = META_ATTR->new( name => 'corporation_name',
                               type => 'ref',
                               ui => { do_query => 1 },
                             );
    my $ui = $attr->get_ui;
    $test->assert( $ui->get_do_query,
                   "'do_query' was set for a 'ref' attribute" );


    $attr->set_type('string');
    $attr->set_ui( undef );
    $ui = $attr->get_ui;
    $test->assert( ! $ui->get_do_query,
                   "'do_query' was ignored 'cause the attribute's not a ref" );

}


sub test_8_popup_menu_with_ref_attr {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Test that a CGI spec for popup_menu is handled with a ref attribute.
    # Actually, the spec will be generated in MVC.
    my $attr = META_ATTR->new( name => 'fool',
                               type => 'string',
                               ui => { popup_menu => 1 },
                             );
    my $ui = $attr->get_ui;
    $test->assert( ! $ui->get_popup_menu, "won't work for string attributes" );

    $attr = META_ATTR->new( name => 'fool',
                            type => 'ref',
                            ui => { popup_menu => 1 },
                          );
    $ui = $attr->get_ui;
    $test->assert( $ui->get_popup_menu, "but does work for ref attributes" );

}

sub test_9_box_with_iset_attr {
    my $test = shift;
    return if $test->should_skip;    # skip over this test if asked

    # Test that a CGI spec for a UI box handled with an iset attr
    # Actually, the spec will be generated in MVC.
    my $attr = META_ATTR->new( name => 'bunch-o-fools',
                               type => 'string',
                               ui => { iset_box => 1 },
                             );
    my $ui = $attr->get_ui;
    $test->assert( ! $ui->get_iset_box,
                   "won't work for string attributes" );

    $attr = META_ATTR->new( name => 'bunch-o-fools',
                            type => 'iset',
                            ui => { iset_box => 1 },
                          );
    $ui = $attr->get_ui;
    $test->assert( $ui->get_iset_box,
                   "but does work for iset attributes" );

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

L<Myco::Base::Entity::Meta::Attribute::UI|Myco::Base::Entity::Meta::Attribute::UI>,
L<Myco::Test::EntityTest|Myco::Test::EntityTest>,
L<testrun|testrun>,
L<tktestrun|tktestrun>,
L<Test::Unit::TestCase|Test::Unit::TestCase>,
L<mkentity|mkentity>
