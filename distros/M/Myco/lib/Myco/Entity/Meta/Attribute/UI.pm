package Myco::Entity::Meta::Attribute::UI;

###############################################################################
# $Id: UI.pm,v 1.6 2006/03/19 19:34:07 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Entity::Meta::Attribute::UI

=head1 SYNOPSIS

 # For typical construction see

L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>

 # Retrieving from entity attribute metadata
 #   (for fictional attribute 'clue')
 $ui_meta = $entity->introspect->get_attributes->{clue}->get_ui;

 # Attribute access
 $label = $ui_meta->get_label;
 $options = $ui_meta->get_options;
 $suffix = $ui_meta->get_suffix;
 $suffix = $ui_meta->get_suffix;
 $widget_specification = $ui_meta->get_widget;

 # Widget closure
 #   creation ( happens automatically via set_widget() )
 $ui_meta->create_closure;

 #   usage
 my $cgi = CGI->new;
 print $ui_meta->get_closure->( $cgi, $entity_attribute_value,
                                formname => 'fooForm',
                                %CGI_method_params );

=head1 DESCRIPTION

Container for metadata describing and facilitating appropriate user interface
behavior for an entity class attribute.

This class is designed such that each of its objects normally has a "part-of"
relationship with an object of class
L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
#use Myco::Entity::Meta;
use Myco::Exceptions;

##############################################################################
# Programatic Dependencies
use CGI qw(-compile :all);


##############################################################################
# Constants
##############################################################################
use constant DEBUG => 0;

# Default max textfield chars for string typed attribs unless specifed
#   otherwise in schema definition
use constant FIELD_MAXLEN_STR => 255;
# Default max textfield chars for non-string typed attribs unless specifed
#   otherwise in schema definition
use constant FIELD_MAXLEN => 20;
# Limit for visible length of texfields unless explicitly overridden
#  in ui widget spec (via '-maxlength => #')
use constant FIELD_DEFSIZE => 50;

# Closures of CGI.pm form-related methods.
my $CGImethods;
{
    my @_CGImethodNames = qw(button checkbox checkbox_group defaults end_form
			     endform filefield hidden image_button
			     password_field popup_menu radio_group reset
                             scrolling_list start_form startform submit
			     textarea textfield
			    );
    my $cgi = CGI->new;
    for my $meth (@_CGImethodNames) {
	# create closure
	my $methref = UNIVERSAL::can('CGI',$meth);
	print "##     No methref!!! ##\n" if (DEBUG and !defined $methref);
	$CGImethods->{$meth} = sub { $methref->(@_) }
	  if ref $methref;
    }
    sub get_CGIclosures {
	wantarray ? ($CGImethods, @_CGImethodNames) : $CGImethods;
    }
}

my $chk_widget = sub {
    my $widget = ${$_[0]};
    Myco::Exception::DataValidation->throw(error => "must be arrayref")
      unless ref $widget eq 'ARRAY';
    Myco::Exception::DataValidation->throw
      (error => "widget spec must not have empty first element")
      unless defined $widget->[0];
    Myco::Exception::DataValidation->throw
      (error => "unknown CGI form method '$widget->[0]'")
      unless exists $CGImethods->{$widget->[0]};
};

my %valid_options = ( hidden => undef,
		      value_default => undef,
		      value_select => undef );

my $chk_options = sub {
    my $options = ${$_[0]};
    Myco::Exception::DataValidation->throw(error => "must be hashref")
      unless ref $options eq 'HASH';
    for my $opt (keys %$options) {
        Myco::Exception::DataValidation->throw(error => "unknown option: $opt")
	  unless exists $valid_options{$opt};
    }
};

##############################################################################
# Inheritance
##############################################################################
use base qw(Class::Tangram);

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Entity.

=head2 Extended Constructor Behavior

If the constructor (C<new()>) is called without a C<widget> parameter then a
default value for the corresponding attribute is automatically established.

The constructor is not normally called directly, rather, it is called during
attribute metadata definition via calls to method C<add_attribute()> of
class
L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>.
As such, this extended behavior is more fully documented in the
description of the C<ui> attribute of said class.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

our $schema =
  { fields => {
#      ref => { 
#                         attr   => { required => 1 },
#      },
                transient => { closure => {},
                               label  => {},
                               do_query => {},
                               popup_menu => {},
                               iset_box => {},
                               suffix => {},
                               attr => {},
			       options => { check_func => $chk_options },
			       widget => { check_func => $chk_widget },
                             },
              }
  };


=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *

Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *

Get attribute value

 $value = $obj->get_attribute;

=back

Attributes belonging to this class that are interest to the typical developer
are documented in the description of the C<ui> attribute of class
L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>.

A listing of other available attributes follows:

=head2 attr

 type: ref   required:  not undef

Utilitatrian attribute that stores the reference to the
L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>
object of which this object is a "part".

=cut

sub get_closure {
    my $closure = $_[0]->SUPER::get_closure;
    return defined $closure ? $closure : $_[0]->create_closure;
}


sub set_attr {
    my ($self, $attr) = @_;

    $self->SUPER::set_attr($attr);

    # If widget is defined but there's no closure then let's create it
    #   ... it was previously skipped because create_closure requires this
    #   attrib ('attr') to be set and presumably it wasn't until now
#    $self->create_closure
#      if defined $attr && ref $self->get_widget && ref $self->get_attr;
}


=head2 do_query

 type: int

Boolean value (1 | 0) that flags an attribute of type 'ref' to be included
in UI generation, providing a way for
L<Myco::UI::MVC::Controller|Myco::UI::MVC::Controller> to hook into
L<Myco::Query|Myco::Query>, to search for a 'ref' attribute.

=cut

sub set_do_query {
    my ($self, $do_query) = @_;
    if ($do_query && $self->get_attr->get_type) {
        # Ignore the do_query directive if the attribute's not a 'ref' type
        $self->SUPER::set_do_query(1) if $self->get_attr->get_type eq 'ref';
    }
}


=head2 popup_menu

 type: int

Boolean value (1 | 0) that flags an attribute of type 'ref' to be included
in UI generation with a popup_menu of object IDs/display names. Used primarily
by L<Myco::UI::MVC::Controller|Myco::UI::MVC::Controller>.

=cut

sub set_popup_menu {
    my ($self, $popup_menu) = @_;
    if ($popup_menu && $self->get_attr->get_type) {
        # Ignore the popup_menu directive if the attribute's not a 'ref' type
        $self->SUPER::set_popup_menu( $popup_menu )
          if $self->get_attr->get_type eq 'ref';
    }
}


=head2 iset_box

 type: int

Name of a Myco class that flags an attribute of type 'iset' to be included
in UI generation via a box of object IDs/display names. Used
primarily by L<Myco::UI::MVC::Controller|Myco::UI::MVC::Controller>.

=cut

sub set_iset_box {
    my ($self, $iset_box) = @_;
    if ($iset_box && $self->get_attr->get_type) {
        # Ignore the iset_box directive if the attribute's not a 'iset'
        $self->SUPER::set_iset_box( $iset_box )
          if $self->get_attr->get_type eq 'iset';
    }
}


# Custom widget setter
sub set_widget {
    my ($self, $widg) = @_;

    $self->SUPER::set_widget($widg);
#    $self->create_closure if defined($widg) && ref($self->get_attr);
}


# _parse_widget()
#
#     $cgi_meth = _parse_widget($widget_ref, $cgi_args_hashref);
#
# Parse 'widget' key from metadata ::Attribute::UI object
#   If not non-empty hash or array ref returns undef
#   Otherwise returns name of CGI method and merges CGI method args
#   into $cgi_args_hashref
sub _parse_widget {
    my ($widg, $cgi_args) = @_;
    my $widg_type = ref $widg;
    if (ref $widg eq 'ARRAY' && @$widg) {
	my ($cgi_meth, %_args) = @$widg;
	# merge in cgi_meth parmeters from widg spec
	while (my ($key, $val) = each %_args) {
	    $cgi_args->{$key} = $val unless exists $cgi_args->{$key};
	}
	return $cgi_meth;
    }
    return undef;
}



##############################################################################
# Methods
##############################################################################

# Custom new

sub _new {
    my $referent = shift;
    my %params = @_;

    my $class = ref $referent || $referent;


    my $obj = $class->SUPER::new(@_);

    return $obj;
}


=head1 ADDED CLASS / INSTANCE METHODS

=head2 create_closure

 $instance->create_closure;

Causes the creation of an anonymous subroutine capable of creating a user
interface element for the entity object attribute described by this ::Attribute
object.  The anonymous subroutine is a closure containing all relenvant
user-interface related attribute metadata (from ::Attribute::UI: 'widget',
'label'; from ::Attribute: 'values', 'value_labels', etc.
See ATTRIBUTES section from both classes).  The subroutine code reference
is saved via a call to C<$instance-E<gt>set_closure>.

The generated closure leverages a method from L<CGI.pm|CGI> to do the actual
user interface element generation.  The closure may be called as illustrated
below

 $instance->get_closure->($CGI, $value, -name=>$attr_name, %params);

...where C<$CGI> is a CGI.pm object and C<%params> are valid parameters
for the CGI.pm method being employed (in addition to those already
stored in the closure).

It should be possible, in the future, to generalize this mechanism to work
in other (non HTML) user interface contexts (eg. Perl/Tk, curses).

=cut

sub create_closure {
    my $self = shift;

    # Parse widget ui attrib and related and determine cgi method, args
    my $widget_meta = $self->get_widget;
    my $widget = $widget_meta || return undef;
    my $widget_suffix = $self->get_suffix || '';
    my @new_widget;

    my $cgimeths = $self->get_CGIclosures;
    my $attr = $self->get_attr;
    my $type = $attr->get_type;
    my $options = $self->get_options || {};
    my $values = $attr->get_values;

    my %cgi_args;
    my $cgi_meth = _parse_widget($widget, \%cgi_args);

    ## Handle @$values
    my ($value_labels, $val_blank, $val_other);
    if (ref $values eq 'ARRAY' and @$values
        and $cgi_meth ne 'checkbox') {
	if (defined $options->{value_default}) {
	    $cgi_args{-default} ||= $options->{value_default};
	}

	$value_labels = $attr->get_value_labels || {};

	# Handle @$values magic strings
	my $val_select;
	if ($cgi_meth eq 'popup_menu') {

	    for my $val (@$values) {
		$val_select = 1 if $val eq '__select__';
		$val_other = 1 if $val eq '__other__';
		$val_blank = 1 if $val eq '__blank__';
	    }
	    $value_labels->{__other__} = '<Other>' if $val_other;
	    $value_labels->{__blank__} = '' if $val_blank;
	    $value_labels->{__select__} = '<Select>' if $val_select;
	    if ($val_select) {
		$options->{value_select} = 1;   # record for posterity
		$value_labels->{__select__} = '<Select>';
	    }
	}

	$cgi_args{-values} ||= $values;
    } else {
	undef $values;
    }

    if (defined $value_labels and $cgi_meth ne 'checkbox') {
	$cgi_args{-labels} ||= $value_labels;
    }


    # Parse attrmeta 'type_options' sub hash
    my $str_len;
    my $t_opt = $attr->get_type_options;
    if (ref $t_opt eq 'HASH') {
	# grab string_length if appropriate
	$str_len = ( defined($t_opt->{string_length})
		     ? $t_opt->{string_length} : FIELD_MAXLEN_STR)
	  if $val_other || $cgi_meth =~ /^(?:text|password_)field$/;

    }

    my %cgi_other_args = ();

    # For text/pass elements wrangle up proper size and maxlength attribs
    _compute_text_field_sizes(\%cgi_args, $cgi_meth, $type, $str_len);
    #   do the same for the __other__ text widget
    _compute_text_field_sizes(\%cgi_other_args, 'textfield', $type, $str_len)
      if $val_other;

    ## Create the closure!
    ##
    my $CGI_code = $CGImethods->{$cgi_meth};
    my $CGI_other_code = $CGImethods->{'textfield'};

    # Set up optional code for dealing with attrib value lists that
    #   include '__other__'
    my $other_widget_code = '';
    my $other_widget_precode = '';
    my $other_table_end = '';
    if ($val_other) {
	$other_widget_precode = q~
           # is entity_val among $values?
	   my $val_found_in_values = 0;
	   my $other_val = '';
	   my $attr_name = $params{-name} || '';
	   for my $val (@$values) {
	       if (!defined $entity_val or $entity_val eq ''
		   or $entity_val eq $val) {
		   $val_found_in_values = 1;
		   last;          # nope... entity_val is among $@values
	       }
	   }
	   unless ( $val_found_in_values ) {
	       $other_val = $entity_val;
	       $cgi_obj->param($attr_name, '__other__');
	   }
	~;

	$other_widget_code = q|
	  $params{-name} = '*otherValue_'.$attr_name;
	  $out = '<table class="other_val_tbl"><tr><td>'
	    .$out.'<br><span class="other_val_widg">&nbsp;&nbsp;&nbsp;Other: '
	    .$CGI_other_code->($cgi_obj, -override=>1, -value=>$other_val,
			       %cgi_other_args, %params)
	    .'</span>';
	|;
	$other_table_end = '</td></tr></table>';
    }

    # main closure code string
    my $closure_code = q|
		    sub {
			my ($cgi_obj, $entity_val, %params) = @_;
			my $formname;
			if (exists $params{formname}) {
			    $formname = $params{formname};
			    delete $params{formname};
			}
			|. $other_widget_precode .q|
			my $out = $CGI_code->($cgi_obj, %cgi_args, %params);
			|. $other_widget_code .q|
			$out.qq~|.$widget_suffix.$other_table_end.q|~;
		      }|;
    $self->set_closure( my $code = eval $closure_code );

    return $code;
}


sub _compute_text_field_sizes {
    my ($cgi_args, $cgi_meth, $type, $str_len) = @_;
    if ($cgi_meth =~ /^(?:text|password_)field$/) {
        if ($type eq 'string') {
	    $cgi_args->{-maxlength} = $str_len || FIELD_MAXLEN_STR
	      unless defined $cgi_args->{-maxlength};
	} else {
	    $cgi_args->{-maxlength} = FIELD_MAXLEN
	      unless defined $cgi_args->{-maxlength};
	}
	$cgi_args->{-size} = ($cgi_args->{-maxlength} < FIELD_DEFSIZE
			    ? $cgi_args->{-maxlength}
			    : FIELD_DEFSIZE )
	  unless defined $cgi_args->{-size};
    }
}
	



1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Entity::Meta::Attribute::UI::Test|Myco::Entity::Meta::Attribute::UI::Test>,
L<Myco::Entity::Meta::Attribute|Myco::Entity::Meta::Attribute>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
