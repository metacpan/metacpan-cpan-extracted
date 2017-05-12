package Rose::HTML::Form::Field::Time::Split::HourMinuteSecond;

use strict;

use Rose::HTML::Form::Field::Time::Hours;
use Rose::HTML::Form::Field::Time::Minutes;
use Rose::HTML::Form::Field::Time::Seconds;
use Rose::HTML::Form::Field::PopUpMenu;

use base 'Rose::HTML::Form::Field::Time::Split';

our $VERSION = '0.606';

sub build_field
{
  my($self) = shift;

  $self->add_fields
  (
    hour => 
    {
      type      => 'time hours',
      size      => 2, 
      maxlength => 2,
      class     => 'hour',
    },

    minute =>
    {
      type      => 'time minutes',
      size      => 2, 
      maxlength => 2,
      class     => 'minute',
    },

    second =>
    {
      type      => 'time seconds',
      size      => 2, 
      maxlength => 2,
      class     => 'second',
    },

    ampm =>
    {
      type    => 'pop-up menu',
      choices => [ '', 'AM', 'PM' ],
      class   => 'ampm',
      default => '',
    },                        
  );
}

sub is_full
{
  no warnings;
  return (length $_[0]->field('hour')->internal_value && 
          length $_[0]->field('ampm')->internal_value) ? 1 : 0;
}

sub decompose_value
{
  my($self, $value) = @_;

  return undef  unless(defined $value);

  my $time = $self->inflate_value($value);

  unless($time =~ /^(\d\d):(\d\d):(\d\d) ([AP]M)$/)
  {
    no warnings;
    return
    {
      hour   => substr($value, 0, 2) || '',
      minute => substr($value, 3, 2) || '',
      second => substr($value, 6, 2) || '',
      ampm   => '',
    }
  }

  return
  {
    hour   => $1,
    minute => $2,
    second => $3,
    ampm   => $4,
  };
}

sub coalesce_value
{
  my($self) = shift;

  return 
    sprintf("%02d:%02d:%02d %s", 
      $self->field('hour')->internal_value,
      $self->field('minute')->internal_value || 0,
      $self->field('second')->internal_value || 0,
      $self->field('ampm')->internal_value);
}

sub html_field
{
  my($self) = shift;

  return '<span class="time">' .
         $self->field('hour')->html_field . ':' .
         $self->field('minute')->html_field   . ':' .
         $self->field('second')->html_field .
         $self->field('ampm')->html_field .
         '</span>';
}

sub xhtml_field
{
  my($self) = shift;

  return '<span class="time">' .
         $self->field('hour')->xhtml_field . ':' .
         $self->field('minute')->xhtml_field   . ':' .
         $self->field('second')->xhtml_field .
         $self->field('ampm')->xhtml_field .
         '</span>';
}

1;

__END__

=head1 NAME

Rose::HTML::Form::Field::Time::Split::HourMinuteSecond - Compound field for times with separate text fields for hour, minute, and second, and a pop-up menu for selecting AM or PM.

=head1 SYNOPSIS

    $field =
      Rose::HTML::Form::Field::Time::Split::HourMinuteSecond->new(
        label   => 'Time',
        name    => 'time',  
        default => '8am');

    print $field->field('hour')->internal_value; # "08"

    $field->input_value('13:00:00 PM');

    # "AM/PM only valid with hours less than 12"
    $field->validate or warn $field->error;

    $field->input_value('blah');

    # "Invalid time"
    $field->validate or warn $field->error;

    $field->input_value('6:30 a.m.');

    print $field->internal_value; # "06:30:00 AM"

    print $field->html;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field::Time::Split::HourMinuteSecond> is a compound field for times with separate text fields for hour, minute, and second, and a pop-up menu for selecting AM or PM.

This class inherits (indirectly) from both L<Rose::HTML::Form::Field::Time> and L<Rose::HTML::Form::Field::Compound>.  This doesn't quite work out as expected without a bit of tweaking.  We'd like L<inflate_value()|Rose::HTML::Form::Field/inflate_value> and L<validate()|Rose::HTML::Form::Field/validate> methods to be inherited from L<Rose::HTML::Form::Field::Time>, but everything else to be inherited from L<Rose::HTML::Form::Field::Compound>.

To solve this problem, there's an intermediate class that imports the correct set of methods.  This class then inherits from the intermediate class.  To solve this problem, there's an intermediate class that imports the correct set of methods.  This class then inherits from the intermediate class.  This works, and isolates the tricky bits to a single intermediate class, but it also demonstrates the problems that can crop up when multiple inheritance is combined with a strong aversion to code duplication.

A simpler example of a compound field can be found in L<Rose::HTML::Form::Field::PhoneNumber::US::Split>.  It too uses multiple inheritance, but its family tree is more conveniently built, saving it from selective method importing shenanigans.

This field also overrides the C<is_full()|Rose::HTML::Form::Field::Compound/is_full> method.  A valid time can be extracted from the field as long as both the hour and AM/PM subfields are not empty.  All other empty fields will be treated as if they contained zeros (00).

It is important that this class (indirectly) inherits from L<Rose::HTML::Form::Field::Compound>. See the L<Rose::HTML::Form::Field::Compound> documentation for more information.

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
