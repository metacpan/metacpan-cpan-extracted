package Rose::HTML::Form::Field::OptionGroup;

use strict;

use Rose::HTML::Form::Field::Option::Container;
# XXX: Use runtime inheritance here to avoid race in circular dependency
our @ISA = qw(Rose::HTML::Form::Field::Option::Container);

use Rose::Object::MakeMethods::Generic
(
  scalar  => 'name',
  boolean => 'multiple',
);

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  label => '',
});

__PACKAGE__->add_boolean_html_attrs('disabled');

__PACKAGE__->delete_valid_html_attrs(qw(
  name
  value
  onblur
  onfocus
  accesskey
  tabindex));

sub element       { 'optgroup' }
sub html_element  { 'optgroup' }
sub xhtml_element { 'optgroup' }

sub label { shift->html_attr('label', @_) }

sub html  { shift->html_field(@_) }
sub xhtml { shift->xhtml_field(@_) }

sub init_apply_error_class { 0 }

sub hidden
{
  my($self) = shift;

  if(@_)
  {
    my $bool = shift;

    $self->SUPER::hidden($bool);

    foreach my $option ($self->options)
    {
      $option->hidden($bool);
    }
  }

  return $self->SUPER::hidden(@_);
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::OptionGroup - Object representation of a group of options in a pop-up menu or select box in an HTML form.

=head1 SYNOPSIS

    $field = 
      Rose::HTML::Form::Field::OptionGroup->new(
        name  => 'fruits',
        label => 'Fruits');

    $field->options(apple  => 'Apple',
                    orange => 'Orange',
                    grape  => 'Grape');

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::OptionGroup> is an object representation of a group of options in a pop-up menu or select box in an HTML form.  Yes, this is the often-overlooked (and sometimes ill-supported) "optgroup" HTML tag.

This class inherits from, and follows the conventions of, L<Rose::HTML::Form::Field>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Form::Field> documentation for more information.

=head1 HTML ATTRIBUTES

Valid attributes:

    accesskey
    class
    dir
    disabled
    id
    label
    lang
    name
    onblur
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
    style
    tabindex
    title
    value
    xml:lang

Required attributes:

    label

Boolean attributes:

    disabled

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field::OptionGroup> object based on PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<add_option OPTION>

Convenience alias for L<add_options()|/add_options>.

=item B<add_options OPTIONS>

Adds options to the option group.  OPTIONS may be a reference to a hash of value/label pairs, a reference to an array of values, or a list of L<Rose::HTML::Form::Field::Option> objects. Passing an odd number of items in the value/label argument list causes a fatal error.  Options passed as a hash reference are sorted by the keys of the hash according to the default behavior of Perl's built-in L<sort()|perlfunc/sort> function.  Options are added to the end of the existing list of options.

=item B<choices [OPTIONS]>

This is an alias for the L<options|/options> method.

=item B<has_value VALUE>

Returns true if VALUE is selected in the option group, false otherwise.

=item B<label [VALUE]>

Get or set the value of the "label" HTML attribute.

=item B<labels [LABELS]>

Get or set the labels for all values.  If LABELS is a reference to a hash or a list of value/label pairs, then LABELS replaces all existing labels.  Passing an odd number of items in the list version of LABELS causes a fatal error.

Returns a hash of value/label pairs in list context, or a reference to a hash in scalar context.

=item B<option VALUE>

Returns the first option (according to the order that they are returned from L<options()|/options>) whose "value" HTML attribute is VALUE, or undef if no such option exists.

=item B<options OPTIONS>

Get or set the full list of options in the pop-up menu.  OPTIONS may be a reference to a hash of value/label pairs, a reference to an array of values, or a list of L<Rose::HTML::Form::Field::Option> objects. Passing an odd number of items in the value/label argument list causes a fatal error. Options passed as a hash reference are sorted by the keys of the hash according to the default behavior of Perl's built-in L<sort()|perlfunc/sort> function.

To set an ordered list of option values along with labels in the constructor, use both the L<options()|/options> and L<labels()|/labels> methods in the correct order. Example:

    $field = 
      Rose::HTML::Form::Field::OptionGroup->new(
        name    => 'fruits',
        options => [ 'apple', 'pear' ],
        labels  => { apple => 'Apple', pear => 'Pear' });

Remember that methods are called in the order that they appear in the constructor arguments (see the L<Rose::Object> documentation), so L<options()|/options> will be called before L<labels()|/labels> in the example above.  This is important; it will not work in the opposite order.

Returns a list of the pop-up menu's L<Rose::HTML::Form::Field::Option> objects in list context, or a reference to an array of the same in scalar context. These are the actual objects used in the field. Modifying them will modify the field itself.

=item B<value_label>

Returns the label of the first selected value (according to the order that they are returned by L<internal_value()|Rose::HTML::Form::Field/internal_value>), or the value itself if it has no label. If no value is selected, undef is returned.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
