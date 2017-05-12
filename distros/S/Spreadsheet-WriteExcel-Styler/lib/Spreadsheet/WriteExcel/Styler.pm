package Spreadsheet::WriteExcel::Styler;
use warnings;
use strict;
use Carp;

our $VERSION = '1.02';

# shorthand notation: $styler->(..) instead of $styler->format(..)
use overload
  '&{}' => sub {my $self = shift; return sub {$self->format(@_)}};


sub new {
  my $class    = shift;
  my $workbook = shift;

  ref $workbook && $workbook->can('add_format') 
    or croak "improper 'workbook' arg (has no 'add_format' method)";

  my $self = { workbook => $workbook, # ref to workbook
               style    => {},        # hash of styles and features
               format   => {},        # cache of created formats
             };
  bless $self, $class;
}

sub add_styles {
  my $self = shift;

  while (my ($style_name, $features) = splice(@_, 0, 2)) {
    carp "overriding style $style_name" if $self->{style}{$style_name};
    croak "features for style $style_name should be expressed as a hashref"
                                        if ref $features ne 'HASH';
    $self->{style}{$style_name} = $features;
  }
}


sub format {
  my $self = shift;

  # get styles from args (can be array, single arrayref or single hashref)
  my @styles;
  my $first_arg = shift;
  my $ref       = ref $first_arg;
  if ($ref) {
    not @_ or croak "too many args to format() when first arg is a ref";
    @styles = $ref eq 'ARRAY' ? @$first_arg
            : $ref eq 'HASH'  ? (grep {$first_arg->{$_}} keys %$first_arg)
            : croak "unexpected arg to format() ($ref)";
  }
  else {
    @styles = ($first_arg, @_);
  }

  # retrieve format for that combination of styles ... or create a new one
  my $format_name = join $;, sort @styles;
  $self->{format}{$format_name} ||= do {
    my @unknown = grep {!$self->{style}{$_}} @styles;
    !@unknown
      or croak "unknown style : " . join ", ", @unknown;
    $self->{workbook}->add_format(map {%{$self->{style}{$_}}} @styles);
  };
  return $self->{format}{$format_name};
}

sub workbook {
  my $self = shift;
  return $self->{workbook};
}

sub styles {
  my $self = shift;
  return keys %{$self->{style}};
}

sub style {
  my ($self, $style_name) = @_;
  return $self->{style}{style_name};
}

1; # End of Spreadsheet::WriteExcel::Styler

__END__


=head1 NAME

Spreadsheet::WriteExcel::Styler - Styles for formatting generated Excel files

=head1 SYNOPSIS

  use Spreadsheet::WriteExcel; # or use Excel::Writer::XLSX
  use Spreadsheet::WriteExcel::Styler;

  # Create an Excel workbook and worksheet
  my $workbook = Spreadsheet::WriteExcel->new('output.xls');
               # or Excel::Writer::XLSX->new('output.xls');
  $worksheet = $workbook->add_worksheet();

  # Create a styler with some styles 
  my $styler = Spreadsheet::WriteExcel::Styler->new($workbook);
  $styler->add_styles(
    title        => {align       => "center",
                     border      => 1,
                     bold        => 1,
                     color       => 'white',
                     bg_color    => 'blue'},
    right_border => {right       => 6,         # double line
                     right_color => 'blue'},
    highlighted  => {bg_color    => 'silver'},
    rotated      => {rotation    => 90},
  );

  # Write data into a cell, with a list of cumulated styles
  $worksheet->write($row, $col, $data, 
                    $styler->(qw/highlighted right_border/));

  # same thing, but styles are expressed as toggles in a hashref
  $worksheet->write($row, $col, $data,
                    $styler->({ highlighted  => 1,
                                rotated      => 0,
                                right_border => should_border($row, $col) }));


=head1 DESCRIPTION

This is a small utility to help formatting cells while
creating Excel workbooks through L<Spreadsheet::WriteExcel>
or L<Excel::Writer::XLSX>.

When working interactively within the Excel application, users often
change one format feature at a time (highlight a row, add a border to
a column, etc.); these changes do not affect other format features
(for example if you change the background color, it does not affect
fonts, borders, or cell alignment).  By contrast, when generating a
workbook programmatically through L<Spreadsheet::WriteExcel> or
L<Excel::Writer::XLSX>, formats express complete sets of features, and
they cannot be combined together. This means that the programmer has
to prepare in advance all formats for all possible combinations of
format features, and has to invent a way of cataloguing those
combinations.

Styler objects from the current module come to the rescue: they hold a
catalogue of I<styles>, where each style is a collection of format
features.  Then, for any combination of styles, the styler generates a
L<Spreadsheet::WriteExcel::Format> or L<Excel::Writer::XLSX::Format>
on the fly, or, if a similar combination was already encountered,
retrieves the format from its internal cache.

=head1 METHODS

=head2 C<new>

  my $styler = Spreadsheet::WriteExcel::Styler->new($workbook);

Creates a styler object, associated to a given workbook.

=head2 C<add_styles>

  $styler->add_styles(
    $style_name_1 => \%format_properties_1,
    $style_name_2 => \%format_properties_2,
    ...
   );

Defines a number of styles within the styler. Each style has a name
and a hashref containing format properties (like for 
C<Spreadsheet::WriteExcel>'s
L<add_format|Spreadsheet::WriteExcel/"add_format"> method).


=head2 C<format> or function dereferencing operator

  # explicit calls to the 'format()' method
  my $format = $styler->format($style_name_1, $style_name_2, ...);
  my $format = $styler->format({$style_name_1 => $toggle_1,
                                $style_name_2 => $toggle_2,
                                ...});

  # same as above, but in shorthand notation
  my $format = $styler->($style_name_1, $style_name_2, ...);
  my $format = $styler->({$style_name_1 => $toggle_1,
                          $style_name_2 => $toggle_2,
                          ...});

The C<format> method can be invoked either as a regular method call,
or, in shorthand notation, as a simple coderef call (arrow operator and
parentheses). It returns a C<Format> object,
either retrieved from cache, or created on the fly, that can then be
passed as argument to any of the worksheet's write methods.

Arguments to C<format()> can be either :

=over

=item *

a list of style names

=item *

a single arrayref containing a list of style names

=item *

a single hashref where keys are style names and values
are boolean toggles that specify whether that style should
be applied or not

=back

The array form is useful when one knows statically the list
of styles to apply. The hashref form is useful when decisions
about styles depend on the context, as for example in :

  my $format = $styler->({
    highlighted  => ($row % 2),
    right_border => $is_end_of_group{$col},
    emphasized   => is_very_important($data),
   });


=head2 C<workbook>

Returns the workbook to which this styler is bound.

=head2 C<styles>

Returns the list of style names defined in this styler.

=head2 C<style>

  my $props_hashref = $styler->style($style_name);

Returns the hashref of format properties that were defined
for the given C<$style_name> through a previous call to the
L</"add_styles"> method.



=head1 AUTHOR

Laurent Dami, C<< <laurent.dami AT etat ge ch> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-spreadsheet-writeexcel-styler at rt.cpan.org>, or through the
web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-WriteExcel-Styler>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::WriteExcel::Styler

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-WriteExcel-Styler>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spreadsheet-WriteExcel-Styler>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-WriteExcel-Styler>

=item METACPAN

L<https://metacpan.org/dist/Spreadsheet-WriteExcel-Styler/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to John McNamara and to all other contributors for
the wonderful L<Spreadsheet::WriteExcel> 
and L<Excel::Writer::XLSX> modules.


=head1 LICENSE AND COPYRIGHT

Copyright 2010, 2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


