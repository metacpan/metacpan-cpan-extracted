package Rose::HTML::Form::Field::DateTime::Range;

use strict;

use Rose::HTML::Object::Errors qw(:date);

use Rose::HTML::Object::Messages 
  qw(FIELD_ERROR_LABEL_MINIMUM_DATE FIELD_ERROR_LABEL_MAXIMUM_DATE);

use Rose::HTML::Form::Field::DateTime::StartDate;
use Rose::HTML::Form::Field::DateTime::EndDate;

use base 'Rose::HTML::Form::Field::Compound';

use Rose::Object::MakeMethods::Generic
(
  'scalar --get_set_init' => 
  [
    'range_separator_regex',
    'min_prefix_html',
    'max_prefix_html',
    'separator_html',
  ]
);

our $VERSION = '0.606';

sub build_field
{
  my($self) = shift;

  $self->add_fields
  (
    min => 
    {
      type           => 'datetime start',
      error_label_id => FIELD_ERROR_LABEL_MINIMUM_DATE,
      size           => 21,
      maxlength      => 25,
    },

    max =>
    {
      type           => 'datetime end',
      error_label_id => FIELD_ERROR_LABEL_MAXIMUM_DATE,
      size           => 21,
      maxlength      => 25,
    },
  );
}

sub size
{
  my($self) = shift;

  if(@_)
  {
    $self->field('min')->size(@_);
    $self->field('max')->size(@_);
  }

  return $self->field('min')->size(@_);
}

sub output_format
{
  my($self) = shift;

  if(@_)
  {
    $self->field('min')->output_format(@_);
    $self->field('max')->output_format(@_);
  }

  return $self->field('min')->output_format(@_);
}

sub init_range_separator       { '#' }
sub init_range_separator_regex { qr(#|\s+to\s+) }

sub range_separator
{
  my($self) = shift;

  if(@_)
  {
    $self->invalidate_output_value;
    return $self->{'range_separator'} = shift;
  }

  return (defined $self->{'range_separator'}) ? $self->{'range_separator'} :
         ($self->{'range_separator'} = $self->init_range_separator);
}

sub deflate_value
{
  my($self, $value) = @_;
  return $value  unless(ref $value && @$value == 2);
  return join($self->range_separator, 
              map { $_->strftime('%Y-%m-%d %H:%M:%S') } @$value);
}

sub coalesce_value
{
  my($self) = shift;
  return join($self->range_separator, map { defined($_) ? $_ : '' } 
                   map { $self->field($_)->output_value } 
                   qw(min max));
}

sub decompose_value
{
  my($self, $value) = @_;

  return undef  unless(defined $value);

  my($min, $max);

  if(ref $value eq 'ARRAY' && @$value == 2)
  {
    ($min, $max) = @$value;
  }
  elsif(!ref $value)
  {
    ($min, $max) = split($self->range_separator_regex, $value, 2);
  }
  else
  {
    Carp::croak ref($self), " can't handle the input value '$value'";
  }

  my $min_date = $self->field('min')->inflate_value($min) || $min;
  my $max_date = $self->field('max')->inflate_value($max) || $max;

  return
  {
    min => $min_date,
    max => $max_date,
  };
}

sub inflate_value
{
  my($self, $value) = @_;

  if(ref $value eq 'ARRAY')
  {
    $self->subfield_input_value(min => $value->[0]);
    $self->subfield_input_value(max => $value->[1]);

    #$self->field('min')->_set_input_value($value->[0]);
    #$self->field('max')->_set_input_value($value->[1]);

    return [ $self->field('min')->internal_value, $self->field('max')->internal_value ];
  }
  else
  {
    my $values = $self->decompose_value($value); 
    return [ $values->{'min'}, $values->{'max'} ];
  }
}

sub init_min_prefix_html { '' }
sub init_max_prefix_html { '' }
sub init_separator_html { ' - ' }

sub html_field
{
  my($self) = shift;

  return '<span class="date-range">' .
         $self->field('min')->html_label . $self->min_prefix_html . $self->field('min')->html_field . $self->separator_html .
         $self->field('max')->html_label . $self->max_prefix_html . $self->field('max')->html_field .
         '</span>';
}

sub xhtml_field
{
  my($self) = shift;

  return '<span class="date-range">' .
         $self->field('min')->xhtml_label . $self->min_prefix_html . $self->field('min')->xhtml_field . $self->separator_html .
         $self->field('max')->xhtml_label . $self->max_prefix_html . $self->field('max')->xhtml_field .
         '</span>';
}

sub html
{
  my($self) = shift;

  return '<table class="date-range">' .
         '<tr><td class="min">' .
         $self->field('min')->html_label . $self->min_prefix_html . $self->field('min')->html . '</td><td>' . $self->separator_html . '</td><td class="max">' .
         $self->field('max')->html_label . $self->max_prefix_html . $self->field('max')->html . '</td></tr>' .
         ($self->has_errors ? '<tr><td colspan="3">' . $self->html_errors . '</td></tr>' : '') .
         '</table>';
}

sub xhtml
{
  my($self) = shift;

  return '<table class="date-range">' .
         '<tr><td class="min">' .
         $self->field('min')->xhtml_label . $self->min_prefix_html . $self->field('min')->xhtml . '</td><td>' . $self->separator_html . '</td><td class="max">' .
         $self->field('max')->xhtml_label . $self->max_prefix_html . $self->field('max')->xhtml . '</td></tr>' .
         ($self->has_errors ? '<tr><td colspan="3">' . $self->xhtml_errors . '</td></tr>' : '') .
         '</table>';
}

sub validate
{
  my($self) = shift;

  my $ret = $self->SUPER::validate(@_);

  return $ret  unless($ret);

  my @errors;

  foreach my $field (qw(min max))
  {
    unless($self->field($field)->validate)
    {
      push(@errors, $self->field($field)->errors);
      $self->field($field)->set_error;
    }
  }

  unless(@errors)
  {
    my($min, $max) = $self->internal_value;

    if($min && $max && $min > $max)
    {
      $self->add_error_id(DATE_MIN_GREATER_THAN_MAX);
      return 0;
    }
  }

  if(@errors)
  {
    $self->add_errors(map { $_->clone } @errors);
    return 0;
  }

  return $ret;
}

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

DATE_MIN_GREATER_THAN_MAX = "The min date cannot be later than the max date."

FIELD_ERROR_LABEL_MINIMUM_DATE = "minimum date"
FIELD_ERROR_LABEL_MAXIMUM_DATE = "maximum date"

[% LOCALE de %]

# von/bis oder doch min/max?
DATE_MIN_GREATER_THAN_MAX = "Das Von-Datum darf nicht größer sein, als das Bis-Datum."

[% LOCALE fr %]

DATE_MIN_GREATER_THAN_MAX = "La date min ne peut pas être postérieure à la date max."

[% LOCALE bg %]

DATE_MIN_GREATER_THAN_MAX = "Началната дата трябва да бъде преди крайната."

__END__

=head1 NAME

Rose::HTML::Form::Field::DateTime::Range - Compound field for date ranges with separate text fields for the minimum and maximum dates.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::DateTime::Range->new(
        label   => 'Date',
        name    => 'date',
        default => [ '1/2/2003', '4/5/2006' ]);

    my($min, $max) = $field->internal_value; # DateTime objects

    print $min->strftime('%Y-%m-%d'); # "2003-01-02"
    print $max->strftime('%Y-%m-%d'); # "2006-04-05"

    $field->input_value('5/6/1980 3pm to 2003-01-06 20:19:55');

    my $dates = $field->internal_value;

    print $dates->[0]->hour; # 15
    print $dates->[1]->hour; # 20

    print $dates->[0]->day_name; # Tuesday

    print $field->html;

    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::DateTime::Range> is a compound field that represents a date range.  It is made up of two subfields: a L<Rose::HTML::Form::Field::DateTime::StartDate> field and a L<Rose::HTML::Form::Field::DateTime::EndDate> field.

The internal value of this field is a list (in list context) or reference to an array (in scalar context) of two L<DateTime> objects.  The first object is the start date and the second is the end date.  If either of fields are not filled in or are otherwise invalid, then the internal value is undef.

The input value can be a reference to an array of L<DateTime> objects, or strings that can be inflated into L<DateTime> objects by the L<Rose::HTML::Form::Field::DateTime::StartDate> and L<Rose::HTML::Form::Field::DateTime::EndDate> classes.  The input value can also be a concatenation of two such strings, joined by a string that matches the field's L<range_separator_regex|/range_separator_regex>.

This class is a good example of a compound field whose internal value consists of more than one object.  See L<below|/"SEE ALSO"> for more compound field examples.

It is important that this class inherits from L<Rose::HTML::Form::Field::Compound>. See the L<Rose::HTML::Form::Field::Compound> documentation for more information.

=head1 OBJECT METHODS

=over 4

=item B<range_separator [STRING]>

Get or set the string used to join the output values of the start and end date subfields in order to produce this field's output value.  The default string is "#".  Example:

    $field->input_value([ '1/2/2003', '4/5/2006' ]);

    # "2003-01-02 00:00:00#2006-04-05 00:00:00"
    print $field->output_value; 

=item B<range_separator_regex [REGEX]>

Get or set the regular expression used to split an input string into start date and end date portions.  The default value is C<qr(#|\s+to\s+)>.  Example:

    $field->input_value('2005-04-20 8pm to 1/7/2006 3:05 AM');

    my($min, $max) = $field->internal_value;

    print $min->day_name; # Wednesday
    print $max->day_name; # Saturday

    # Change regex, adding support for " - "
    $field->range_separator_regex(qr(#|\s+(?:to|-)\s+));

    $field->input_value('2005-04-20 8pm - 1/7/2006 3:05 AM');

    ($min, $max) = $field->internal_value;

    print $min->day_name; # Wednesday
    print $max->day_name; # Saturday

Note that the C<range_separator_regex> B<must> match the C<range_separator> string.

When setting C<range_separator_regex>, you should use the C<qr> operator to create a pre-compiled regex (as shown in the example above)  If you do not, then the regex will be recompiled each time it's used.

=back

=head1 SEE ALSO

Other examples of custom fields:

=over 4

=item L<Rose::HTML::Form::Field::Email>

A text field that only accepts valid email addresses.

=item L<Rose::HTML::Form::Field::Time>

Uses inflate/deflate to coerce input into a fixed format.

=item L<Rose::HTML::Form::Field::DateTime>

Uses inflate/deflate to convert input to a L<DateTime> object.

=item L<Rose::HTML::Form::Field::PhoneNumber::US::Split>

A simple compound field that coalesces multiple subfields into a single value.

=item L<Rose::HTML::Form::Field::DateTime::Split::MonthDayYear>

A compound field that uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Split::MDYHMS>

A compound field that includes other compound fields and uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
