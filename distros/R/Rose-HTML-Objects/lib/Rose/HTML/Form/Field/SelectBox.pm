package Rose::HTML::Form::Field::SelectBox;

use strict;

use Carp();

use base 'Rose::HTML::Form::Field::Option::Container';

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  name => '',
  size => 5,
});

__PACKAGE__->add_boolean_html_attrs
(
  'multiple',
  'disabled',
);

__PACKAGE__->add_valid_html_attrs
(
  'onchange',    # %Script;       #IMPLIED  -- the element value was changed --
);

*options_html_attr        = \&Rose::HTML::Form::Field::Group::items_html_attr;
*delete_options_html_attr = \&Rose::HTML::Form::Field::Group::delete_items_html_attr;

sub element       { 'select' }
sub html_element  { 'select' }
sub xhtml_element { 'select' }

sub multiple { shift->html_attr('multiple', @_) }

sub internal_value
{
  my($self) = shift;

  return $self->SUPER::internal_value(@_)  if($self->multiple);

  my($value) =  $self->SUPER::internal_value(@_);
  return $value;
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::SelectBox - Object representation of a select box in an HTML form.

=head1 SYNOPSIS

    $field = Rose::HTML::Form::Field::SelectBox->new(name => 'fruits');

    $field->options(apple  => 'Apple',
                    orange => 'Orange',
                    grape  => 'Grape');

    print $field->value_label('apple'); # 'Apple'

    $field->input_value('orange');
    print $field->internal_value; # 'orange'

    $field->multiple(1);
    $field->add_value('grape');
    print join(',', $field->internal_value); # 'grape,orange'

    $field->has_value('grape'); # true
    $field->has_value('apple'); # false

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::SelectBox> is an object representation of a select box field in an HTML form.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HIERARCHY

All L<child-related|Rose::HTML::Object/HIERARCHY> methods are effectively aliases for the option manipulation methods described below.  See the "hierarchy" sections of the L<Rose::HTML::Form::Field/HIERARCHY> and L<Rose::HTML::Form/HIERARCHY> documentation for an overview of the relationship between field and form objects and the child-related methods inherited from L<Rose::HTML::Object>.

=head1 HTML ATTRIBUTES

Valid attributes:

    accesskey
    class
    dir
    disabled
    id
    lang
    multiple
    name
    onblur
    onchange
    onclick
    ondblclick
    onfocus
    onkeydown
    onkeypress
    onkeyup
    onmousedown
    onmousemove
    onmouseout
    onmouseover
    onmouseup
    size
    style
    tabindex
    title
    value
    xml:lang

Required attributes:

    name
    size

Boolean attributes:

    disabled
    multiple

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::SelectBox> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<add_option OPTION>

Convenience alias for L<add_options()|/add_options>.

=item B<add_options OPTIONS>

Adds options to the select box.  OPTIONS may take the following forms.

A reference to a hash of value/label pairs:

    $field->add_options
    (
      {
        value1 => 'label1',
        value2 => 'label2',
        ...
      }
    );

An ordered list of value/label pairs:

    $field->add_options
    (
      value1 => 'label1',
      value2 => 'label2',
      ...
    );

(Option values and labels passed as a hash reference are sorted by the keys of the hash according to the default behavior of Perl's built-in L<sort()|perlfunc/sort> function.)

A reference to an array of containing B<only> plain scalar values:

    $field->add_options([ 'value1', 'value2', ... ]);

A list or reference to an array of L<Rose::HTML::Form::Field::Option> or L<Rose::HTML::Form::Field::OptionGroup> objects:

    $field->add_options
    (
      Rose::HTML::Form::Field::Option->new(...),
      Rose::HTML::Form::Field::OptionGroup->new(...),
      Rose::HTML::Form::Field::Option->new(...),
      ...
    );

    $field->add_options
    (
      [
      Rose::HTML::Form::Field::Option->new(...),
      Rose::HTML::Form::Field::OptionGroup->new(...),
      Rose::HTML::Form::Field::Option->new(...),
        ...
      ]
    );

A list or reference to an array containing a mix of value/label pairs, value/hashref pairs, and L<Rose::HTML::Form::Field::Option> or L<Rose::HTML::Form::Field::OptionGroup> objects:

    @args = 
    (
      # value/label pair
      value1 => 'label1',

      # option group object
      Rose::HTML::Form::Field::OptionGroup->new(...),

      # value/hashref pair
      value2 =>
      {
        label => 'Some Label',
        id    => 'my_id',
        ...
      },

      # option object
      Rose::HTML::Form::Field::Option->new(...),

      ...
    );

    $field->add_options(@args);  # list
    $field->add_options(\@args); # reference to an array

B<Please note:> the second form (passing a reference to an array) requires that at least one item in the referenced array is not a plain scalar, lest it be confused with "a reference to an array of containing only plain scalar values."

All options are added to the end of the existing list of options.

Option groups may also be added by nesting another level of array references.  For example, this:

    $field = Rose::HTML::Form::Field::SelectBox->new(name => 'fruits');

    $field->options(apple  => 'Apple',
                    orange => 'Orange',
                    grape  => 'Grape');

    $group = Rose::HTML::Form::Field::OptionGroup->new(label => 'Others');

    $group->options(juji  => 'Juji',
                    peach => 'Peach');

    $field->add_options($group);

is equivalent to this:

    $field = 
      Rose::HTML::Form::Field::SelectBox->new(
        name    => 'fruits',
        options =>
        [
          apple  => 'Apple',
          orange => 'Orange',
          grape  => 'Grape',
          Others =>
          [
            juji  => { label => 'Juji' },
            peach => { label => 'Peach' },
          ],
        ]);

    $field->add_options($group);

=item B<add_value VALUE>

Add VALUE to the list of selected values.

=item B<add_values VALUE1, VALUE2, ...>

Add multiple values to the list of selected values.

=item B<choices [OPTIONS]>

This is an alias for the L<options|/options> method.

=item B<delete_items_html_attr NAME>

This is an alias for the L<delete_options_html_attr|/delete_options_html_attr> method.

=item B<delete_option VALUE>

Deletes the first option (according to the order that they are returned from L<options()|/options>) whose "value" HTML attribute is VALUE.  Returns the deleted option or undef if no such option exists.

=item B<delete_options LIST>

Repeatedly calls L<delete_option|/delete_option>, passing each value in LIST as an arugment.

=item B<delete_option_group LABEL>

Deletes the first option group (according to the order that they are returned from L<options()|/options>) whose "label" HTML attribute is LABEL.  Returns the deleted option group or undef if no such option exists.

=item B<delete_option_groups LIST>

Repeatedly calls L<delete_option_group|/delete_option_group>, passing each value in LIST.

=item B<delete_options_html_attr NAME>

Delete the L<HTML attribute|Rose::HTML::Object/html_attr> named NAME from each L<option|/options>.

=item B<has_value VALUE>

Returns true if VALUE is selected in the select box, false otherwise.

=item B<hide_all_options>

Set L<hidden|Rose::HTML::Form::Field::Option/hidden> to true for all L<options|/options>.

=item B<items_html_attr NAME [, VALUE]>

This is an alias for the L<options_html_attr|/options_html_attr> method.

=item B<internal_value>

If L<multiple|/multiple> is true, a reference to an array of selected values is returned in scalar context, and a list of selected values is returned in list context.  Otherwise, the selected value is returned (or undef if no value is selected).

=item B<labels [LABELS]>

Get or set the labels for all values.  If LABELS is a reference to a hash or a list of value/label pairs, then LABELS replaces all existing labels.  Passing an odd number of items in the list version of LABELS causes a fatal error.

Returns a hash of value/label pairs in list context, or a reference to a hash of value/label pairs in scalar context.

=item B<label_ids [LABELS]>

Get or set the integer L<message|Rose::HTML::Object::Messages> ids for all values.  If LABELS is a reference to a hash or a list of value/message id pairs, then LABELS replaces all existing label ids.  

Returns a hash of value/label pairs in list context, or a reference to a hash of value/label pairs in scalar context.

=item B<multiple [BOOL]>

This is just an accessor method for the "multiple" boolean HTML attribute, but I'm documenting it here so that I can warn that trying to select multiple values in a non-multiple-valued select box will cause a fatal error.

=item B<option VALUE>

Returns the first option (according to the order that they are returned from L<options()|/options>) whose "value" HTML attribute is VALUE, or undef if no such option exists.

=item B<options [OPTIONS]>

Get or set the full list of options in the select box.  OPTIONS may be a reference to a hash of value/label pairs, an ordered list of value/label pairs, a reference to an array of values, or a list of objects that are of, or inherit from, the classes L<Rose::HTML::Form::Field::Option> or L<Rose::HTML::Form::Field::OptionGroup>. Passing an odd number of items in the value/label argument list causes a fatal error.  Options passed as a hash reference are sorted by value according to the default behavior of Perl's built-in L<sort()|perlfunc/sort> function.

To set an ordered list of option values along with labels in the constructor, use both the L<options()|/options> and L<labels()|/labels> methods in the correct order. Example:

    $field = 
      Rose::HTML::Form::Field::SelectBox->new(
        name    => 'fruits',
        options => [ 'apple', 'pear' ],
        labels  => { apple => 'Apple', pear => 'Pear' });

Remember that methods are called in the order that they appear in the constructor arguments (see the L<Rose::Object> documentation), so L<options()|/options> will be called before L<labels()|/labels> in the example above.  This is important; it will not work in the opposite order.

Returns a list of the select box's L<Rose::HTML::Form::Field::Option> and/or L<Rose::HTML::Form::Field::OptionGroup> objects in list context, or a reference to an array of the same in scalar context. L<Hidden|Rose::HTML::Form::Field::Option/hidden> options I<will> be included in this list.  These are the actual objects used in the field. Modifying them will modify the field itself.

=item B<option_group LABEL>

Returns the L<Rose::HTML::Form::Field::OptionGroup> object whose "label" HTML attribute is LABEL, or undef if no such option group exists.

=item B<options_html_attr NAME [, VALUE]>

If VALUE is passed, set the L<HTML attribute|Rose::HTML::Object/html_attr> named NAME on all L<options|/options>.  Otherwise, return the value of the  L<HTML attribute|Rose::HTML::Object/html_attr> named NAME on the first option encountered in the list of all L<options|/options>.

=item B<show_all_options>

Set L<hidden|Rose::HTML::Form::Field::Option/hidden> to false for all L<options|/options>.

=item B<value [VALUE]>

Simply calls L<input_value()|Rose::HTML::Form::Field/input_value>, passing all arguments.

=item B<values [VALUE]>

Simply calls L<input_value()|Rose::HTML::Form::Field/input_value>, passing all arguments.

=item B<value_label>

Returns the label of the first selected value (according to the order that they are returned by L<internal_value()|Rose::HTML::Form::Field/internal_value>), or the value itself if it has no label. If no value is selected, undef is returned.

=item B<value_labels>

Returns an array (in list context) or reference to an array (in scalar context) of the labels of the selected values.  If a value has no label, the value itself is substituted.  If no values are selected, then an empty array (in list context) or reference to an empty array (in scalar context) is returned.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
