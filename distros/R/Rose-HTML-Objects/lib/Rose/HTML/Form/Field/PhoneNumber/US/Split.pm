package Rose::HTML::Form::Field::PhoneNumber::US::Split;

use strict;

use Carp();

use Rose::HTML::Form::Field::Text;

use base qw(Rose::HTML::Form::Field::Compound
            Rose::HTML::Form::Field::PhoneNumber::US);

# Multiple inheritence never quite works out the way I want it to...
Rose::HTML::Form::Field::PhoneNumber::US->import_methods
(
  'validate',
  'inflate_value',
  'deflate_value',
);

Rose::HTML::Form::Field::Compound->import_methods
(
  'name',
);

our $VERSION = '0.606';

sub build_field
{
  my($self) = shift;

  $self->add_fields
  (
    area_code => { type => 'text', size => 3, maxlength => 3, class => 'area-code' },
    exchange  => { type => 'text', size => 3, maxlength => 3, class => 'exchange' },
    number    => { type => 'text', size => 4, maxlength => 4, class => 'number' },
  );
}

sub decompose_value
{
  my($self, $value) = @_;

  return undef  unless(defined $value);

  my $phone = $self->inflate_value($value);

  unless($phone)
  {
    $phone =~ s/[- ]+//g;

    no warnings;
    return
    {
      area_code => substr($phone, 0, 3) || '',
      exchange  => substr($phone, 3, 6) || '',
      number    => substr($phone, 6, 4) || '',
    }
  }

  $phone =~ /^(\d{3})-(\d{3})-(\d{4})$/;


  return
  {
    area_code => $1,
    exchange  => $2,
    number    => $3,
  };
}

sub coalesce_value
{
  my($self) = shift;
  return join('-', map { defined($_) ? $_ : '' } 
                   map { $self->field($_)->internal_value }  qw(area_code exchange number));
}

sub html_field
{
  my($self) = shift;

  return '<span class="phone">' .
         $self->field('area_code')->html_field . '-' .
         $self->field('exchange')->html_field  . '-' .
         $self->field('number')->html_field .
         '</span>';
}

sub xhtml_field
{
  my($self) = shift;

  return '<span class="phone">' .
         $self->field('area_code')->xhtml_field . '-' .
         $self->field('exchange')->xhtml_field  . '-' .
         $self->field('number')->xhtml_field .
         '</span>';
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::PhoneNumber::US::Split - Compound field for US phone numbers with separate fields for area code, exchange, and number.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::PhoneNumber::US::Split->new(
        label   => 'Phone',
        name    => 'phone',  
        default => '123-321-1234');

    print $field->field('area_code')->internal_value; # "123"

    $field->input_value('555-5555');

    # "Phone number must be 10 digits, including area code"
    $field->validate or warn $field->error;

    $field->input_value('(555) 456-7890');

    print $field->field('exchange')->internal_value; # "456"
    print $field->internal_value; # "555-456-7890"

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::PhoneNumber::US::Split> is a compound field that contains three separate text fields for US phone numbers: one each for area code, exchange, and number.  It inherits from both L<Rose::HTML::Form::Field::PhoneNumber::US> and L<Rose::HTML::Form::Field::Compound>.  It overrides the following methods: L<build_field()|Rose::HTML::Form::Field::Compound/build_field>, L<coalesce_value()|Rose::HTML::Form::Field::Compound/coalesce_value>, L<decompose_value()|Rose::HTML::Form::Field::Compound/decompose_value>, L<html_field()|Rose::HTML::Form::Field/html_field>, and L<xhtml_field()|Rose::HTML::Form::Field/xhtml_field>.

This is a good example of a compound field that combines separate fields into a single value through simple concatenation (plus a separator character). By inheriting from L<Rose::HTML::Form::Field::PhoneNumber::US>, it gets the validation and inflate/deflate features "for free", leaving it to concentrate on the coalesce/decompose features and the building and printing of the separate fields that make up the compound field.

It is important that this class inherits from L<Rose::HTML::Form::Field::Compound>. See the L<Rose::HTML::Form::Field::Compound> documentation for more information.

=head1 SEE ALSO

Other examples of custom fields:

=over 4

=item L<Rose::HTML::Form::Field::Email>

A text field that only accepts valid email addresses.

=item L<Rose::HTML::Form::Field::Time>

Uses inflate/deflate to coerce input into a fixed format.

=item L<Rose::HTML::Form::Field::DateTime>

Uses inflate/deflate to convert input to a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Range>

A compound field whose internal value consists of more than one object.

=item L<Rose::HTML::Form::Field::DateTime::Split::MonthDayYear>

A compound field that uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=item L<Rose::HTML::Form::Field::DateTime::Split::MDYHMS>

A compound field that includes other compound fields and uses inflate/deflate convert input from multiple subfields into a L<DateTime> object.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
