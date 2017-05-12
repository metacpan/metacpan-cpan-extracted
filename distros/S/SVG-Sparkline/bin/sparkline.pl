#!/usr/bin/env perl

use strict;
use warnings;

use SVG::Sparkline;
use Getopt::Long;
use Pod::Usage;

my $type = shift;
if( !defined $type or $type eq '--help-types' )
{
    print "No Sparkline type specified.\n";
    help_types();
}

pod2usage( -verbose => 2, -exitval => 0 )
    if $type eq '--help' or $type eq '--man';

my %options;
GetOptions(
    'allns' => \$options{'-allns'},
    'sized!' => \$options{'-sized'},
    'bgcolor|bg=s' => \$options{'bgcolor'},
    'padx=f' => \$options{'padx'},
    'pady=f' => \$options{'pady'},
    'height|h=f' => \$options{'height'},
    'width|w=f' => \$options{'width'},
    'values|v=s' => \$options{'values'},
    'mark=s@' => \$options{'mark'},
    'color=s' => \$options{'color'},
    'xscale=f' => \$options{'xscale'},
    'thick=f' => \$options{'thick'},
    'gap=f' => \$options{'gap'},
    'outfile|o=s' => \$options{'outfile'},
    'clobber|c' => \$options{'clobber'},
    'help|man' => \$options{'help'},
    'help-types' => \$options{'help-types'},
) or pod2usage( 'Unrecognized argument' );

pod2usage( -verbose => 2, -exitval => 0 ) if $options{'help'};
help_types() if $options{'help-types'};

my $svg = SVG::Sparkline->new( $type => parameters_from_cmdline( \%options ) );

my $fh = \*STDOUT;
if( defined $options{'outfile'} )
{
    my ($outfile,$clobber) = @options{'outfile','clobber'};

    die "Output file '$outfile' exists, failing.\n" if !$clobber and -e $outfile;
    open( $fh, '>', $outfile ) or die "Unable to create '$outfile': $!\n";
}

print $fh "$svg";

close $fh;

sub help_types
{
    print <<'EOF';
Supported Sparkline types:

  * Area
  * Bar
  * Line
  * RangeArea
  * RangeBar
  * Whisker

Check the help page for descriptions of the types and further information.
EOF
    exit;
}

sub parameters_from_cmdline
{
    my %params;

    die "Missing required --values parameter. No idea what to chart.\n"
        unless defined $options{'values'};

    foreach my $key (keys %options)
    {
        $params{$key} = $options{$key} || 0 if $key eq '-sized';
        $params{$key} = $options{$key} if defined $options{$key};
    }
    # Clean up values parameter
    
    $params{'values'} = [ split ',', $params{'values'} ]
        unless 'Whisker' eq $type && $params{'values'} =~ /^[-+0]+$/;
    $params{'values'} = [ map { [ split ':', $_ ] } @{$params{'values'}} ]
        if $type eq 'RangeArea' or $type eq 'RangeBar';

    # Clean up mark parameter
    $params{'mark'} = [ map { split /[=:]/, $_ } @{$params{'mark'}} ];

    return \%params;
}

__END__
=head1 NAME

sparkline.pl - Command line tool for creating sparklines

=head1 VERSION

This document describes sparkline.pl version 0.03

=head1 Synopsis

    sparkline.pl {type} [options] --values=1,2,3,4,5
    sparkline.pl {type} -o outfile.svg [options] --values=1,2,3,4,5
    sparkline.pl --help

=head1 DESCRIPTION

Create sparklines from a command line, printing either to stdout or
a file. The command line options set the parameters passed to
C<SVG::Sparklines> to create the sparkline.

=head1 TYPES

This program supports the following Sparkline types:

=over 4

=item Area

An C<Area> sparkline is a basic line graph shaded between the line and
the x axis.

=item Bar

The I<Bar> sparkline type is a simple bar graph or histogram.

=item Line

The I<Line> sparkline type is a simple line graph.

=item RangeArea

An C<RangeArea> sparkline type shows high/low continuous values by displaying
shading the area between two lines of continuous data.

=item RangeBar

The I<RangeBar> sparkline type shows high/low pairs of related values that define
a range at each of the supplied data points.

=item Whisker

The I<Whisker> sparkline type shows a sequence of events that can have one
of two outcomes (e.g. win/loss).

=back

See L<SVG::Sparkline::Manual> for more details.

=head1 OPTIONS 

=over 4

=item --allns

Provide all of the xmlns attributes on the root svg element, the default is to
only supply the default SVG namespace.

=item --sized

Add the I<height> and I<width> attributes on the root svg element. This is
currently the default behavior.

=item --nosized

Do not add the I<height> and I<width> attributes to the root svg element.

=item --bgcolor={color}

Specify a background color for the sparkline. By default, the sparkline will
have a transparent background.

=item --bg={color}

Synonym for C<--bgcolor>.

=item --padx={length}

Provide {length} pixels of padding on the left and right of the sparkline.

=item --pady={length}

Provide {length} pixels of padding on the top and bottom of the sparkline.

=item --height={length}

Specify the height of the sparkline. The default height is 10 pixels.

=item --h={length}

Synonym for C<--height>.

=item --width={length}

Specify the width of the sparkling in pixels. The default width depends on the
sparkline type and the number of data values.

=item --w={length}

Synonym for C<--width>.

=item --values={comma separated list of values}

This required parameter specifies the data to display on the sparkline. The
supplied data can take one of three forms.

=over 4

=item All but RangeArea and RangeBar

Almost all sparkline types support the default data format which is a series
of numbers separated by commas. The C<Whisker> type has limits on the values
allowed. Other than that, all specified types work the same way.

  --values=1,2,3,4,5,6,7,8,9

=item Whisker

The C<Whisker> sparkline type supports another format which is more condensed.
This is a series of '+', '-', and '0' characters that represent the high, low,
and neutral ticks on the Whisker graph.

   --values=+--+-0+---+++

=item RangeArea and RangeBar

These two sparkline types require a pair of data values for each point on the
sparkline. To accomplish this, we comma-separated list of pairs of values. Each
pair consists of two values separated by a colon, with the smaller value first.

   --values=1:1,2:4,3:9,4:16,5:25

=back

=item --v={comma separated list of values}

Synonym for C<--values>.

=item --mark={mark}

This parameter can be supplied multiple times to define multiple marks. Each mark
has an index value and a color separated by a colon (or equals). The index value
can be either a numeric index or one of the named indexes described in
L<SVG::Sparkline::Manual> under I<mark>.

=item --color={color}

Specify the color of the data line.

=item --xscale={length}

Specify the distance between individual data points in the absence of a
a I<--width>. If neither I<--width> or I<--xscale> are supplied, the default
is 2.

=item --thick={length}

Thickness of the line for those sparklines that have lines. For a Bar or
RangeBar sparkline, this specifies the thickness of the bar.

=item --gap={length}

Gap between the bars of the Bar sparkline or the whiskers of the
Whisker sparkline.

=item --outfile={filename}

Specify the name of a file where the sparkline should be written. The file
must not exist unless the C<--clobber> parameter is supplied.

By default, the sparkline is written to stdout.

=item --o=s

Synonym for C<--outfile>.

=item --clobber

If the file specified by C<--outfile> does exist, this parameter gives permission
for the program to overwrite the file.

=item --c

Synonym for C<--clobber>.

=item --help

Display the full help documentation for sparkline.pl.

=item --man

Synonym for C<--help>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

sparkline.pl requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<SVG::Sparkline>, L<Getopt::Long>, and L<Pod::Usage>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 ACKNOWLEDGEMENTS

Thanks to Gabor Szabo for pointing out some deficiencies in the parameter
handling and usability of the sparkline.pl program.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.0. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
