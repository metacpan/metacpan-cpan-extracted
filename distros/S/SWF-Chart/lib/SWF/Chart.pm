package SWF::Chart;

=pod

=head1 NAME

SWF::Chart - Perl interface to the SWF Chart generation tool

=head1 SYNOPSIS

  use SWF::Chart;

  my $g = SWF::Chart->new;

  $g->set_titles(qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec));

  # Add a single data set
  $g->add_dataset(1, 3, 5, 7, 2, 4, 6);

  # Add multiple datasets
  $g->add_dataset([qw(1 3 5 7 11 13 17 23 29 31 37 41)],
                  [qw(1 1 2 3 5 8 13 21 34 55 89 144)]);

  # Add multiple datasets with labels
  $g->add_dataset('Label 1' => \@set1,
                  'Label 2' => \@set2);

  $g->text_properties(bold  => 0,
                      size  => 10,
                      color => '333333');

  $g->chart_rect(positive_color => '555555',
                 positive_alpha => 100);

  $g->series_color('DEADBE');

  print $g->xml;

=head1 DESCRIPTION

This module is the Perl interface to the SWF Charts flash graphing tool.  It constructs the XML file this flash movie requires via an OO interface.  Each configurable option that is listed on the SWF Charts reference page has a companion method in this module.  See:

  http://www.maani.us/charts/index.php?menu=Reference

When using this module, please be sure to use the latest version of the XML/SWF
Charts flash movie.  Earlier versions of that flash movie supported a different
XML structure for which this module is not backward compatible.

Note that there are a few extra helper functions that this module provides:

=over 4

=item chart_data (set_titles/add_dataset)

The 'chart_data' option has been split into two different methods, 'set_titles' and 'add_dataset'.  The original 'chart_data' option held all of this information, but from an interface standpoint, it makes more sense to separate these.

=item text_properties

This method sets the 'font', 'bold', 'size' and 'color' properties of all options that effect text ('axis_category', 'axis_value', 'chart_value', 'legend_label' and 'draw_text').  See "L<text_properties|/"MODULE SPECIFIC METHODS">" for more information.

=item hide_legend

This method employes a hack to hide the legend of a graph since this option does not currently exist in SWF Chart.

=back

=head1 MODULE SPECIFIC METHODS

The following methods do not have a direct analog to any SWF Chart option.

=over 4

=cut

#--------------------------------------#
# Dependencies

use strict;

#--------------------------------------#
# Global Variables

our $VERSION = '1.4';

# What version of the XML/SWF Charts flash module do we support?
our $SWF_VERSION = '4.5';

#--------------------------------------#
# Constants

# The OPTIONS hash keeps track of how all the options are represented in XML.
# If the first value is 'elem' it means that the option is a single element.
# For 'elem', if there is no second value, then that option is an empty content
# element that uses parameters, ie:
#
#   foobar => ['elem']
#
# and if the set call for this option looks like:
#
#   $g->foobar(param1 => 'value1', param2 => 'value2')
#
# then this XML will be produced:
#
#   <foobar param1="value1" param2="value2" />
#
# For 'elem', if the second value is 1, then the element has content, ie:
#
#   fizpow => ['elem', 1]
#
# and if the set call for this option looks like:
#
#   $g->fizpow('value')
#
# then this XML will be produced:
#
#   <fizpow>value</fizpow>
#
# If the first value if 'container' then the second value will be another option
# in OPTIONS that gives the format for the elements contained by this container.
# For example, if the option definition is:
#
#   mumblyjoe => ['container', 'fizpow']
#
# and if the set call for this option looks like:
#
#   $g->mumblyjoe('foo');
#   $g->mumblyjoe('bar');
#
# then this XML will be produced:
#
#   <mumblyjoe><fizpow>foo</fizpow><fizpow>bar</fizpow></mumblyjoe>
#
# To get different behavior, override the default AUTOLOAD method.

use constant OPTIONS => {
                         axis_category    => ['elem'],
                         axis_ticks       => ['elem'],
                         axis_value       => ['elem'],
                         axis_value_text  => ['container', 'string'],

                         chart_border     => ['elem'],
                         chart_data       => ['elem'],
                         chart_grid_h     => ['elem'],
                         chart_grid_v     => ['elem'],
                         chart_pref       => ['elem'],
                         chart_rect       => ['elem'],
                         chart_transition => ['elem'],
                         chart_type       => ['elem', 1],
                         chart_value      => ['elem'],
                         chart_value_text => ['container', 'string'],

                         legend_label      => ['elem'],
                         legend_rect       => ['elem'],
                         legend_transition => ['elem'],

                         link             => ['elem'],
                         link_data        => ['elem'],
                         live_update      => ['elem'],

                         series_color     => ['container', 'color'],
                         series_explode   => ['container', 'number'],
                         series_gap       => ['elem'],
                         series_switch    => ['elem'],

                         circle           => ['elem'],
                         line             => ['elem'],
                         rect             => ['elem'],
                         text             => ['elem'],
                         string           => ['elem', 1],
                         color            => ['elem', 1],
                         number           => ['elem', 1],
                        };

# A list of properties that if passed to any of the above options should be
# considered text properties.
use constant TEXT_PROPS => {font  => 1,
                            bold  => 1,
                            size  => 1,
                            color => 1,
                           };

#--------------------------------------#
# Public Class Methods

=pod

=item $g = SWF::Chart->new

Creates a new SWF Chart object.  Does not take any parameters.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    return $self;
}

sub DESTROY { }

#--------------------------------------#
# Public Instance Methods

=pod

=item $g->set_titles

Sets the titles for each column of data.  There should be as many titles as data points you pass to 'add_dataset'. If this method is called multiple times, only the last set of titles given will be used.

=cut

sub set_titles {
    my $self = shift;
    my (@titles) = @_;

    # Allow either an array ref or an actual array to be passed in
    $self->{rows}->[0] = ref $titles[0] ? $titles[0] : \@titles;

    # Make sure to include the required empty cell for the title row
    unshift @{$self->{rows}->[0]},  undef;

    return 1;
}

=pod

=item $g->add_dataset(@row);

=item $g->add_dataset(\@row1, \@row2, \@row3)

=item $g->add_dataset('Region A' => \@row1,
                      'Region B' => \@row2)

Adds rows of data to be charted.  Accepts a list of values for a single row, a list of array references for multiple rows or a hash where the key is the row label and the value is an array reference of values for that row.  If this method is called more than once, each row is added after the existing rows rather than replacing them.

=cut

sub add_dataset {
    my $self = shift;
    my (@set) = @_;

    # Initialize rows with a blank first row saved for the titles
    $self->{rows} ||= [undef];

    # Reformat to be in the form (label => \@row)
    if ($set[0] and ref $set[0]) {
        @set = map { undef, [@$_] } @set;
    } elsif ($set[1] and not ref $set[1]) {
        @set = (undef, [@set]);
    }

    while (@set) {
        my ($label, $r) = (shift @set, shift @set);

        # Add the label
        unshift @$r, $label;
        push @{$self->{rows}}, $r;
    }

    return 1;
}

=pod

=item $g->chart_value_text(@row);

=item $g->chart_value_text(\@row1, \@row2, \@row3)

Adds alternate text for the values displayed.  Accepts a list of values for a single row or a list of array references for multiple rows.  If this method is called more than once, each row's alternate text is added after the existing rows rather than replacing them.

=cut

sub chart_value_text {
    my $self = shift;
    my (@text) = @_;
    my @add_rows = ref $text[0] ? @text : (\@text);

    return unless @add_rows;

    my @rows = ['row', undef, [(['null']) x (scalar(@{$add_rows[0]})+1)]];
    my $data = $self->{opts}->{'chart_value_text'} ||=
               ['chart_value_text', undef, \@rows];

    foreach my $r (@add_rows) {
        my @str;
        push @{$data->[2]}, ['row', undef, \@str];

        foreach my $t (undef, @$r) {
            if (defined $t) {
                push @str, ['string', undef, $t];
            } else {
                push @str, ['null'];
            }
        }
    }

    return 1;
}

=pod

=item $g->hide_legend

This method is a hack to allow easy hiding of the legend.  It achives this by setting the legend y-coordinate to -9999, placing it (hopefully) far off canvas.  If at some point a native 'hide_legend' is implimented, that will be used instead.

=cut

sub hide_legend {
    my $self = shift;

    # This is the ordained way to remove the legend...yuk
    $self->legend_rect(y => -9999);
}

=pod

=item $g->text_properties(%param)

This method sets text properties for all options that affect text.  This makes it easy to sets the font for all text in a graph to be 'Arial', or all to a particular point size.  The keys to %param are the properties that can be changed:

=over 4

=item font

The font face to use for all text.  Arial is the default font and is the only one embedded in the flash movie.  If any other font is set here it must be installed on the clients machine or SWF Chart will default to the closest font.

=item bold

A boolean that determines whether the font is bold or not

=item size

The font size in points

=item color

The hex color for text

=back

This method acts as a convience method to set all text properties at once.  This means that if you call this after setting font properties for a specific option, those values will be overwritten. If you would prefer this to operate as a way to set defaults, then call this method first and then set the additional font prorperites.

=cut

sub text_properties {
    my $self = shift;
    my (%param) = @_;

    # Clean the values on the way in so we don't inadvertantly overwrite stuff
    foreach my $k (keys %param) {
        delete $param{$k} unless exists TEXT_PROPS->{$k};
    }
    $self->{defaults}->{text_props} = \%param;

    # Set the defaults for attribute only tags
    $self->axis_category(%param);
    $self->axis_value(%param);
    $self->chart_value(%param);
    $self->legend_label(%param);

    # Set the defaults for the draw_text tags
    if (exists $self->{opts}->{draw_text}) {

        # Get the array of <text> elements and loop through them
        my $text = $self->{opts}->{draw_text}->[2];
        foreach my $t (@$text) {

            # Iterate over each attribute currently set on this <text> element
            foreach my $k (keys %param) {

                # Update it unless its already set
                next if exists $t->[1]->{$k};
                $t->[1]->{$k} = $param{$k};
            }
        }
    }
}

=pod

=back

=head1 SWF CHART METHODS

The following methods have a direct relationship to the options SWF Charts accepts.  Please refer to the SWF Chart reference page for details on these options.  These methods are split into three categories:

=head2 Parameter Methods

These methods take a hash of parameters that map to the parameters given on the SWF Chart reference page.  If called more than once, each call overwrites the previous parameter values.  If a particular parameter is not given, then the previous value for that parameter is retained.  Example:

  $g->chart_border(color            => '00FF00',
                   top_thickness    => 0,
                   bottom_thickness => 0);

The 'chart_border' option now has a border color of '00FF00' and zero top and bottom thickness.  After this call:

  $g->chart_border(top_thickness    => 5,
                   bottom_thickness => 5);

The top and bottom thickness will become 5, but the color will remain '00FF00'.

=over 4

=item *

$g->axis_category(%param)

=item *

$g->axis_ticks(%param)

=item *

$g->axis_value(%param)

=item *

$g->chart_border(%param)

=item *

$g->chart_data(%param)

=item *

$g->chart_grid_h(%param)

=item *

$g->chart_grid_v(%param)

=item *

$g->chart_pref(%param)

=item *

$g->chart_rect(%param)

=item *

$g->chart_value(%param)

=item *

$g->chart_value_text(%param)

=item *

$g->legend_bg(%param)

=item *

$g->legend_label(%param)

=item *

$g->legend_rect(%param)

=item *

$g->link(%param)

=item *

$g->link_data(%param)

=item *

$g->live_update(%param)

=item *

$g->series_gap(%param)

=item *

$g->series_switch(%param)

=back

=head2 Value Methods

These methods take a scalar value.  If called more than once, each call overwrites the previous value.

=over 4

=item *

$g->chart_type($value)

=back

=head2 Repeatable Methods

These methods can be called more than once.  Each time they are called they add additional data rather than replace existing data.  Currently there is no way to change the parameters given on previous calls.

=over 4

=item *

$g->draw($thing1 => $param, $thing2 => $param, ...)

Draw one or more primitives to the chart.  Options for $thing are:

=over 4

=item circle

=item image

=item line

=item rect

=item text

=back

Valid options for the $param hash are the parameters given for the elements of
the same name within the 'draw' command L<http://www.maani.us/xml_charts/index.php?menu=Reference&submenu=draw>

The only difference is when drawing 'text' you must pass the value for the text
via a 'value' key to the $param hash.  Example:

  $g->draw(text => {bold  => 1,
                    x     => 20,
                    y     => 20,
                    value => 'The quick brown fox',
                   },
           line => { ... },
           ...
          )

=item *

$g->draw_circle(%param)

Same as $g->draw(circle => \%param)

=item *

$g->draw_image(%param)

Same as $g->draw(image => \%param)

=item *

$g->draw_line(%param)

Same as $g->draw(line => \%param)

=item *

$g->draw_rect(%param)

Same as $g->draw(rect => \%param)

=item *

$g->draw_text($text, %param)

Same as $g->draw(text => \%param)

=item *

$g->series_color($value)

=item *

$g->series_explode($value)

=back

=cut

sub draw {
    my $self = shift;
    my (%items) = @_;

    foreach my $type (keys %items) {
        my $opts  = $items{$type};
        my $value = $opts->{value};
        $value = delete $opts->{value} if $type eq 'text';
        $self->_draw_thing($type, $value, $opts);
    }
}

sub draw_circle { shift->_draw_thing('circle', undef, @_) }

sub draw_image  { shift->_draw_thing('image', undef, @_)  }

sub draw_line   { shift->_draw_thing('line', undef, @_)   }

sub draw_rect   { shift->_draw_thing('rect', undef, @_)   }

sub draw_text {
    my $self = shift;
    my ($text, %param) = @_;
    my $text_defaults = $self->{defaults}->{text_props};

    # If there are defaults copy them to the unset values
    if ($text_defaults) {
        foreach my $k (keys %$text_defaults) {
            next if exists $param{$k};
            $param{$k} = $text_defaults->{$k};
        }
    }

    $self->_draw_thing('text', $text, \%param);
}

sub _draw_thing {
    my $self = shift;
    my ($thing, $value) = (shift, shift);

    # Accept either a hash or a hash ref as the fourth arg of @_
    my $param = ref $_[0] ? $_[0] : {@_};
    my $data  = $self->{opts}->{draw} ||= ['draw', undef, []];

    if ($thing eq 'text') {
        push @{$data->[2]}, [$thing, $param, $value];
    } else {
        push @{$data->[2]}, [$thing, $param];
    }
}

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    my $obj = $_[0];
    (my $option = $AUTOLOAD) =~ s!.+::!!;
    no strict 'refs';

    my $type = OPTIONS->{$option};

    die "No such graph option '$option'" unless $type;

    if ($type->[0] eq 'elem') {
        # This type just sets a single value with no attributes
        if ($type->[1]) {
            *$AUTOLOAD = sub {
                my $self = shift;
                my ($value) = @_;
                $self->{opts}->{$option} = [$option, undef, $value];
            };
        }
        # This type just sets attributes with no value
        else {
            *$AUTOLOAD = sub {
                my $self = shift;
                my (%param) = @_;
                my $elem = $self->{opts}->{$option} ||= [$option, {}];

                # Update each attribute
                foreach my $k (keys %param) {
                    $elem->[1]->{$k} = $param{$k};
                }
            };
        }
    } elsif ($type->[0] eq 'container') {
        *$AUTOLOAD = sub {
            my $self = shift;
            my $data = $self->{opts}->{$option} ||= [$option, undef, []];

            push @{$data->[2]}, (@_ % 2 ? [$type->[1], undef, $_[0]]
                                        : [$type->[1], {@_}]);
        };
    }

    goto &$AUTOLOAD;
}

sub xml {
    my $self = shift;
    my (%param) = @_;
    my $format = $param{format} || 0;

    my $output = '<?xml version="1.0" encoding="utf-8"?><chart>';
    $output .= "\n" if $format;

    # Output all the chart preferences and settings
    foreach my $opt (keys %{$self->{opts}}) {
        $output .= $self->_elem_as_string($self->{opts}->{$opt});
        $output .= "\n" if $format;
    }

    # Output the data for this chart
    $output .= '<chart_data>';
    $output .= "\n" if $format;
    my $rows = $self->{rows};

    # Write the labels for the chart
    $output .= $self->_xml_chart_data_labels($rows->[0]);
    $output .= "\n" if $format;

    # Write the rows
    foreach my $r (@$rows[1..$#$rows]) {
        $output .= $self->_xml_chart_data_row($r);
        $output .= "\n" if $format;
    }

    $output .= '</chart_data>';
    $output .= "\n" if $format;

    $output .= '</chart>';

    return $output;
}

#--------------------------------------#
# Private Instance Methods

sub _xml_chart_data_labels {
    my $self = shift;
    my ($row) = @_;
    my $output = '<row><null/>';

    foreach my $t (@$row[1..$#$row]) {
        $output .= "<string>$t</string>";
    }

    $output .= '</row>';

    return $output;
}

sub _xml_chart_data_row {
    my $self = shift;
    my ($row) = @_;
    my $output = '<row>';

    if ($row->[0]) {
        $output .= '<string>'.$row->[0].'</string>';
    } else {
        $output .= '<null/>';
    }

    foreach my $n (@$row[1..$#$row]) {
        $n ||= '' unless defined $n;
        $output .= "<number>$n</number>";
    }

    $output .= '</row>';

    return $output;
}

# ['name', {param => 1}, [$child1, $child2, $child3]]
sub _elem_as_string {
    my $self = shift;
    my ($node) = @_;
    my ($name, $attr, $value) = @$node;
    my $out = "<$name";

    $out .= ' '.join(' ', map { $_.'="'.$attr->{$_}.'"' } keys %$attr) if $attr;

    if ($value) {
        $out .= '>';

        if (ref $value) {
            foreach my $child (@$value) {
                $out .= $self->_elem_as_string($child);
            }
        } else {
            $out .= $value;
        }

        $out .= "</$name>";
    } else {
        $out .= ' />';
    }

    return $out;
}

1;

__END__

=pod

=head1 BUGS

No known bugs

=head1 AUTHOR

Garth Webb <garth@sixapart.com>

=head1 VERSION

Version 1.3 (11 Jan 2006)

=head1 SEE ALSO

L<perl>, L<http://www.maani.us/charts/index.php>

=head1 COPYRIGHT AND LICENSE

Copyright 2005, Six Apart, Ltd.

=cut
