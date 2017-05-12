package Rose::HTML::Form::Field::RadioButtonGroup;

use strict;

use Carp;

use Rose::HTML::Form::Field::RadioButton;

use Rose::HTML::Form::Field::Group;
use base 'Rose::HTML::Form::Field::Group::OnOff';

our $VERSION = '0.606';

sub _item_class       { shift->object_type_class_loaded('radio button') }
sub _item_name        { 'radio button' }
sub _item_name_plural { 'radio buttons' }

*radio_buttons               = \&Rose::HTML::Form::Field::Group::items;
*radio_buttons_localized     = \&Rose::HTML::Form::Field::Group::items_localized;
*radio_button                = \&Rose::HTML::Form::Field::Group::OnOff::item;
*visible_radio_buttons       = \&Rose::HTML::Form::Field::Group::visible_items;

*add_radio_buttons           = \&Rose::HTML::Form::Field::Group::add_items;
*add_radio_button            = \&add_radio_buttons;
*add_radio_buttons_localized = \&Rose::HTML::Form::Field::Group::add_items_localized;
*add_radio_button_localized  = \&add_radio_buttons_localized;

*choices           = \&radio_buttons;
*choices_localized = \&radio_buttons_localized;

*show_all_radio_buttons = \&Rose::HTML::Form::Field::Group::show_all_items;
*hide_all_radio_buttons = \&Rose::HTML::Form::Field::Group::hide_all_items;

*delete_radio_button  = \&Rose::HTML::Form::Field::Group::delete_item;
*delete_radio_buttons = \&Rose::HTML::Form::Field::Group::delete_items;

*delete_radio_button_group  = \&Rose::HTML::Form::Field::Group::delete_item_group;
*delete_radio_button_groups = \&Rose::HTML::Form::Field::Group::delete_item_groups;

*radio_buttons_html_attr        = \&Rose::HTML::Form::Field::Group::items_html_attr;
*delete_radio_buttons_html_attr = \&Rose::HTML::Form::Field::Group::delete_items_html_attr;

sub internal_value
{
  my($self) = shift;
  my($value) =  $self->SUPER::internal_value(@_);
  return $value;
}

sub html_table
{
  my($self, %args) = @_;

  $args{'class'} = defined $args{'class'} ? 
    "$args{'class'} radio-button-group" : 'radio-button-group';

  #$args{'cellpadding'} = 2  unless(exists $args{'cellpadding'});
  #$args{'cellspacing'} = 0  unless(exists $args{'cellspacing'});
  #$args{'tr'} = { valign => 'top' }  unless(exists $args{'tr'});

  $args{'tr'} ||= {};
  $args{'td'} ||= {};

  $args{'table'}{'class'} = defined $args{'table'}{'class'} ? 
    "$args{'table'}{'class'} radio-button-group" : 
    defined $args{'class'} ? $args{'class'} : undef;

  #$args{'table'}{'cellpadding'} = $args{'cellpadding'}
  #  unless((exists $args{'table'} && !defined $args{'table'}) || 
  #         exists $args{'table'}{'cellpadding'});

  #$args{'table'}{'cellspacing'} = $args{'cellspacing'}
  #  unless((exists $args{'table'} && !defined $args{'table'}) ||
  #         exists $args{'table'}{'cellspacing'});

  if($args{'_xhtml'})
  {
    return
      $self->SUPER::html_table(items       => scalar $self->visible_radio_buttons,
                               format_item => \&Rose::HTML::Form::Field::Group::_xhtml_item,
                               %args);
  }
  else
  {
    return
      $self->SUPER::html_table(items       => scalar $self->radio_buttons,
                               format_item => \&Rose::HTML::Form::Field::Group::_html_item,
                               %args);
  }
}

sub xhtml_table { shift->html_table(@_, _xhtml => 1) }

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::RadioButtonGroup - A group of radio buttons in an HTML form.

=head1 SYNOPSIS

    $field = 
      Rose::HTML::Form::Field::RadioButtonGroup->new(name => 'fruits');

    $field->radio_buttons(apple  => 'Apple',
                          orange => 'Orange',
                          grape  => 'Grape');

    print $field->value_label('apple'); # 'Apple'

    $field->input_value('orange');
    print $field->internal_value; # 'orange'

    print $field->html_table(columns => 2);

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::RadioButtonGroup> is an object wrapper for a group of radio buttons in an HTML form.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HIERARCHY

A radio button group is an abstraction with no corresponding parent HTML element; the individual L<radio button|Rose::HTML::Form::Field::RadioButton> objects in the group exist as siblings.  As such, the list of L<child|Rose::HTML::Object/HIERARCHY> objects will always be empty and cannot be modified.  To get the list of siblings, use the L<radio_buttons|/radio_buttons> method.

See the "hierarchy" sections of the L<Rose::HTML::Form::Field/HIERARCHY> and L<Rose::HTML::Form/HIERARCHY> documentation for an overview of the relationship between field and form objects and the child-related methods inherited from L<Rose::HTML::Object>.

=head1 HTML ATTRIBUTES

None.  This class is simply an aggregator of L<Rose::HTML::Form::Field::RadioButton> objects.

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::RadioButtonGroup> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<add_radio_button OPTION>

Convenience alias for L<add_radio_buttons()|/add_radio_buttons>.

=item B<add_radio_buttons RADIO_BUTTONS>

Adds radio buttons to the radio button group.  RADIO_BUTTONS may take the following forms.

A reference to a hash of value/label pairs:

    $field->add_radio_buttons
    (
      {
        value1 => 'label1',
        value2 => 'label2',
        ...
      }
    );

An ordered list of value/label pairs:

    $field->add_radio_buttons
    (
      value1 => 'label1',
      value2 => 'label2',
      ...
    );

(Radio button values and labels passed as a hash reference are sorted by value according to the default behavior of Perl's built-in L<sort()|perlfunc/sort> function.)

A reference to an array of containing B<only> plain scalar values:

    $field->add_radio_buttons([ 'value1', 'value2', ... ]);

A list or reference to an array of L<Rose::HTML::Form::Field::RadioButton> objects:

    $field->add_radio_buttons
    (
      Rose::HTML::Form::Field::RadioButton->new(...),
      Rose::HTML::Form::Field::RadioButton->new(...),
      ...
    );

    $field->add_radio_buttons
    (
      [
        Rose::HTML::Form::Field::RadioButton->new(...),
        Rose::HTML::Form::Field::RadioButton->new(...),
        ...
      ]
    );

A list or reference to an array containing a mix of value/label pairs, value/hashref pairs, and L<Rose::HTML::Form::Field::RadioButton> objects:

    @args = 
    (
      # value/label pair
      value1 => 'label1',

      # value/hashref pair
      value2 =>
      {
        label => 'Some Label',
        id    => 'my_id',
        ...
      },

      # object
      Rose::HTML::Form::Field::RadioButton->new(...),

      ...
    );

    $field->add_radio_buttons(@args);  # list
    $field->add_radio_buttons(\@args); # reference to an array

All radio buttons are added to the end of the existing list of radio buttons.

B<Please note:> the second form (passing a reference to an array) requires that at least one item in the referenced array is not a plain scalar, lest it be confused with "a reference to an array of containing only plain scalar values."

=item B<choices [RADIO_BUTTONS]>

This is an alias for the L<radio_buttons|/radio_buttons> method.

=item B<columns [COLS]>

Get or set the default number of columns to use in the output of the L<html_table()|/html_table> and L<xhtml_table()|/xhtml_table> methods.

=item B<delete_items_html_attr NAME>

This is an alias for the L<delete_radio_buttons_html_attr|/delete_radio_buttons_html_attr> method.

=item B<delete_radio_button VALUE>

Deletes the first radio button (according to the order that they are returned from L<radio_buttons()|/radio_buttons>) whose "value" HTML attribute is VALUE.  Returns the deleted radio button or undef if no such radio button exists.

=item B<delete_radio_buttons LIST>

Repeatedly calls L<delete_radio_button|/delete_radio_button>, passing each value in LIST.

=item B<delete_radio_buttons_html_attr NAME>

Delete the HTML attribute named NAME from each L<radio button|/radio_buttons>.

=item B<has_value VALUE>

Returns true if the radio button whose value is VALUE is selected, false otherwise.

=item B<hide_all_radio_buttons>

Set L<hidden|Rose::HTML::Form::Field::RadioButton/hidden> to true for all L<radio_buttons|/radio_buttons>.

=item B<html>

Returns the HTML for radio button group, which consists of the L<html()|/html> for each radio button object joined by L<html_linebreak()|/html_linebreak> if L<linebreak()|/linebreak> is true, or single spaces if it is false.

=item B<html_linebreak [HTML]>

Get or set the HTML linebreak string.  The default is "E<lt>brE<gt>\n"

=item B<html_table [ARGS]>

Returns an HTML table containing the radio buttons.  The table is constructed according ARGS, which are name/value pairs.  Valid arguments are:

=over 4

=item class

The value of the "table" tag's "class" HTML attribute.  Defaults to C<radio-button-group>.  Any value passed for this attribute joined to C<radio-button-group> with a single space.

=item columns

The number of columns in the table.  Defaults to L<columns()|/columns>, or 1 if L<columns()|/columns> is false.

=item format_item

The name of the method to call on each radio button object in order to fill each table cell.  Defaults to "html"

=item rows

The number of rows in the table.  Defaults to L<rows()|/rows>, or 1 if L<rows()|/rows> is false.

=item table

A reference to a hash of HTML attribute/value pairs to be used in the "table" tag.

=item td

A reference to a hash of HTML attribute/value pairs to be used in the "td" tag, or an array of such hashes to be used in order for the table cells of each row.  If the array contains fewer entries than the number of cells in each row of the table, then the last entry is used for all of the remaining cells in the row.  Defaults to a reference to an empty hash, C<{}>.

=item tr

A reference to a hash of HTML attribute/value pairs to be used in the "tr" tag, or an array of such hashes to be used in order for the table rows.  If the array contains fewer entries than the number of rows in the table, then the last entry is used for all of the remaining rows.  Defaults to a reference to an empty hash, C<{}>.

=back

Specifying "rows" and "columns" values (either as ARGS or via L<rows()|/rows> and L<columns()|/columns>) that are both greater than 1 leads to undefined behavior if there are not exactly "rows x columns" radio buttons.  For predictable behavior, set either rows or columns to a value greater than 1, but not both.

=item B<internal_value>

The selected value is returned (or undef if no value is selected).

=item B<items_html_attr NAME [, VALUE]>

This is an alias for the L<radio_buttons_html_attr|/radio_buttons_html_attr> method.

=item B<labels [LABELS]>

Get or set the labels for all radio buttons.  If LABELS is a reference to a hash or a list of value/label pairs, then LABELS replaces all existing labels. Passing an odd number of items in the list version of LABELS causes a fatal error.

Returns a hash of value/label pairs in list context, or a reference to a hash in scalar context.

=item B<linebreak [BOOL]>

Get or set the flag that determines whether or not the string stored in L<html_linebreak()|/html_linebreak> or L<xhtml_linebreak()|/xhtml_linebreak> is used to separate radio buttons in the output of L<html()|/html> or L<xhtml()|/xhtml>, respectively.  Defaults to true.

=item B<radio_button VALUE>

Returns the first radio button (according to the order that they are returned from L<radio_buttons()|/radio_buttons>) whose "value" HTML attribute is VALUE, or undef if no such radio button exists.

=item B<radio_buttons [RADIO_BUTTONS]>

Get or set the full list of radio buttons in the group.  RADIO_BUTTONS may be a reference to a hash of value/label pairs, an ordered list of value/label pairs, a reference to an array of values, or a list of L<Rose::HTML::Form::Field::RadioButton> objects. Passing an odd number of items in the value/label argument list causes a fatal error. Radio button values and labels passed as a hash reference are sorted by value according to the default behavior of Perl's built-in L<sort()|perlfunc/sort> function.

To set an ordered list of radio buttons along with labels in the constructor, use both the L<radio_buttons()|/radio_buttons> and L<labels()|/labels> methods in the correct order. Example:

    $field = 
      Rose::HTML::Form::Field::RadioButtonGroup->new(
        name          => 'fruits',
        radio_buttons => [ 'apple', 'pear' ],
        labels        => { apple => 'Apple', pear => 'Pear' });

Remember that methods are called in the order that they appear in the constructor arguments (see the L<Rose::Object> documentation), so L<radio_buttons()|/radio_buttons> will be called before L<labels()|/labels> in the example above. This is important; it will not work in the opposite order.

Returns a list of the radio button group's L<Rose::HTML::Form::Field::RadioButton> objects in list context, or a reference to an array of the same in scalar context.  L<Hidden|Rose::HTML::Form::Field::RadioButton/hidden> radio buttons I<will> be included in this list.  These are the actual objects used in the field. Modifying them will modify the field itself.

=item B<radio_buttons_html_attr NAME [, VALUE]>

If VALUE is passed, set the L<HTML attribute|Rose::HTML::Object/html_attr> named NAME on all L<radio buttons|/radio_buttons>.  Otherwise, return the value of the  L<HTML attribute|Rose::HTML::Object/html_attr> named NAME on the first radio button encountered in the list of all L<radio buttons|/radio_buttons>.

=item B<rows [ROWS]>

Get or set the default number of rows to use in the output of the L<html_table()|/html_table> and L<xhtml_table()|/xhtml_table> methods.

=item B<show_all_radio_buttons>

Set L<hidden|Rose::HTML::Form::Field::RadioButton/hidden> to false for all L<radio_buttons|/radio_buttons>.

=item B<value [VALUE]>

Simply calls L<input_value()|Rose::HTML::Form::Field/input_value>, passing all arguments.

=item B<value_label [VALUE [, LABEL]>

If no arguments are passed, it returns the label of the selected radio button, or the value itself if it has no label.  If no radio button is selected, undef is returned.

With arguments, it will get or set the label for the radio button whose value is VALUE.  The label for that radio button is returned.  If the radio button exists, but has no label, then the value itself is returned.  If the radio button does not exist, then undef is returned.

=item B<xhtml>

Returns the XHTML for radio button group, which consists of the L<xhtml()|/xhtml> for each radio button object joined by L<xhtml_linebreak()|/xhtml_linebreak> if L<linebreak()|/linebreak> is true, or single spaces if it is false.

=item B<xhtml_linebreak [XHTML]>

Get or set the XHTML linebreak string.  The default is "E<lt>br /E<gt>\n"

=item B<xhtml_table>

Equivalent to L<html_table()|/html_table> but using XHTML markup for each radio button.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
