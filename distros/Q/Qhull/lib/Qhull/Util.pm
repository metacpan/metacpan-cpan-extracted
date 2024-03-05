package Qhull::Util;

# ABSTRACT: Various bits and pieces

use v5.26;
use strict;
use warnings;
use experimental 'signatures', 'lexical_subs', 'declared_refs';
use Ref::Util qw( is_arrayref is_hashref );
use Log::Any '$log';

our $VERSION = '0.01';

use Qhull::Util::Options ':all';

use Exporter::Shiny qw( parse_output supported_output_format );

our @CARP_NOT = qw( Qhull::PP Qhull::Options );

my sub croak {
    require Carp;
    goto \&Carp::croak;
}

my sub parse_output_facets;
my sub parse_output_vertices;

my %Parser = (
    f => {
        func => \&parse_output_facets,
        key  => 'f',
    },
    p => {
        func => \&parse_output_vertices,
        key  => 'p',
    },
    Fx => {
        func => \&parse_extreme_points,
        key  => 'e',
    },
);









sub supported_output_format( $format ) {
    return defined $Parser{$format};
}




























sub parse_output( $options, $output, @output_args ) {

    my $line_no = 1;
    my @output;
    for my $arg ( @output_args ) {
        my $parser = $Parser{$arg} // croak( "unsupported output format: $arg" );
        ( $line_no, my $results ) = $parser->{func}->( $options, \$output, $line_no );
        push @output, $results;
    }

    return @output;
}
## no critic( RegularExpressions::ProhibitEscapedMetacharacters )
my $qr_Record      = qr/\G\n*([^\n]*?)$/mx;
my $qr_Point       = qr/ p(\d+) \(v (\d+) \)  /mx;
my $qr_PointRecord = qr/\G\n*- \h* $qr_Point \h* : \h+ ($Num) \h+ ($Num) \h* $ /mx;
my $qr_Facet       = qr/f(\d+)/mx;
my $qr_FacetHeader = qr/\G\n*- \h $qr_Facet \h* $/mx;
my $qr_FacetAttr   = qr/\G\n* \h+ - \h (?<attr>[^:]+) : \h+ /x;

my %qr_FacetAttr = (
    'flags'              => qr/\G \h* (\w+) \h*/mx,
    'normal'             => qr/\G \h* ($Num) \h*/mx,
    'offset'             => qr/\G \h* ($Num) \h*/mx,
    'vertices'           => qr/\G \h* $qr_Point \h*/mx,
    'neighboring facets' => qr/\G \h* $qr_Facet \h*/mx,
);














































sub parse_output_facets ( $option, $buf_ref, $line_no ) {
    my \$buffer = $buf_ref;

    croak( "end of data in qhull output at line $line_no" )
      if $buffer !~ /$qr_Record/g;

    if ( ( my $contents = $1 ) !~ /^Vertices and facets/ ) {
        croak(
            "out of sync in qhull output at line $line_no;" . " expected 'Vertices and facets', got: $contents",
        );
    }

    # read vertices
    ++$line_no;
    my ( @vertices, @facets );
    while ( $buffer =~ m/$qr_PointRecord/gc ) {
        my ( $point, $vertex, @coords ) = @{^CAPTURE};
        push @vertices,
          {
            ( $option->{trace} ? ( line_no => $line_no ) : () ),
            point  => $point,
            vertex => $vertex,
            coords => \@coords,
          };
    }
    continue {
        ++$line_no;
    }

    croak( "missing vertices at line $line_no" )
      if !@vertices;

    while ( $buffer =~ m/$qr_FacetHeader/gc ) {

        my $id = $1;

        my %line_no = ( id => $line_no );
        my %facet   = ( id => $id, );
        $facet{line_no} = \%line_no if $option->{trace};

        ++$line_no;
        while ( $buffer =~ m/$qr_FacetAttr/gc ) {

            my $attr = $+{attr};
            my $qr   = $qr_FacetAttr{$attr} // croak( "unknown facet attribute at line $line_no: $attr" );

            my @values = $buffer =~ m/$qr/gc;
            @values || croak( "unparseable facet attribute value at line $line_no" );

            $facet{$attr}   = \@values;
            $line_no{$attr} = $line_no;
        }
        continue {
            ++$line_no;
        }

        push @facets, \%facet;
    }

    croak( "missing facets at line $line_no" )
      if !@vertices;

    return $line_no, { vertices => \@vertices, facets => \@facets };
}
















sub parse_output_vertices( $option, $buf_ref, $line_no ) {
    my \$buffer = $buf_ref;

    my @results;
    for ( 0, 1 ) {
        croak( "end of data in qhull output at line $line_no" )
          if $buffer !~ /$qr_Record \n/gx;

        if ( ( my $contents = $1 ) !~ /\h* ($Int) \h*/x ) {
            croak( "out of sync in qhull output at line $line_no;" . " expected an integer, got: $contents", );
        }
        ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
        push @results, $1;
    }
    continue {
        ++$line_no;
    }

    my $nelem = $results[-1];

    # read vertices
    my ( @vertices );
    while ( $nelem-- and my @coords = $buffer =~ m/\G \h* ($Num) \h*?/xmgc ) {
        push @vertices, [ ( $option->{trace} ? $line_no : () ), ( map 0+ $_, @coords ), ];
        $buffer =~ /\n+/gc;
    }
    continue {
        ++$line_no;
    }

    croak( "missing vertices at line $line_no" )
      if !@vertices;

    return $line_no, \@vertices;

}
















sub parse_extreme_points( $option, $buf_ref, $line_no ) {
    my \$buffer = $buf_ref;

    croak( "end of data in qhull output at line $line_no" )
      if $buffer !~ /$qr_Record \n/gx;

    if ( ( my $contents = $1 ) !~ /\h* ($Int) \h*/x ) {
        croak( "out of sync in qhull output at line $line_no;" . " expected an integer, got: $contents", );
    }

    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
    my $nelem = $1;
    ++$line_no;

    # read vertex indices
    my ( @vertices );
    while ( $nelem-- and $buffer =~ m/\G \h* ($Int) \h*?\n/xgm ) {
        push @vertices, $option->{trace} ? [ $line_no, $1 ] : $1;
    }
    continue {
        ++$line_no;
    }

    croak( "missing vertices at line $line_no" )
      if !@vertices;

    return $line_no, \@vertices;

}

1;

#
# This file is part of Qhull
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory coords qhull

=head1 NAME

Qhull::Util - Various bits and pieces

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 SUBROUTINES

=head2 supported_output_format

  $bool = supported_output_format( $format );

Returns true if parsing for C<$format> (a Qhull output format flag) is supported.

=head2 parse_output

  @results = parse_output( \%options, $output, @output_formats );

Parses output from B<qhull> based on the specified B<output_formats> (e.g. C<p>, C<f>, C<Fx>), which must be
in the same order as specified to B<qhull>.

Returns a list of parsed data, one element per output format.  See the
B<parse_output_*> routines for the structure of the parsed data.

The following options are available:

=over

=item *

trace

Add line number information to the parsed output which identifies the
input line containing the data.  Each output format will record it
differently.

=back

=head2 parse_output_facets

  ( $line_no, \%parsed_data ) = parse_output_facets( \%option, \$buffer, $line_no );

Parse C<f> (facets & vertices) formatted output.  B<pos($buffer)> must
be the offset into B<$buffer> where the data start.  B<$line_no> is
the line number corresponding to that offset.  The updated line number
is returned as well as the parsed data.

The parsed data are in the following structure:

  { vertices => \@vertices, facets => \@facets }

B<@vertices> is an array of hashes, on per vertex, each with the following elements:

=over

=item *
  point id

=item *

vertex id

=item *

coords - an arrayref of coordinate values

=item *

line_no - only present if the trace option is set;

=back

B<@facets> is an array of hashes, on per facet.  The entries in a
facet hash will depend upon the format parameters passed to B<qhull>.

If the B<trace> option is specified, then there will be an additional
entry B<line_no> which is a hash keyed off of the names of the facet
entry attributes, whose values are the line numbers in the input they
appear on.

=head2 parse_output_vertices

  ( $line_no, \@vertices ) = parse_output_vertices( \%option, \$buffer, $line_no );

Parse C<p> (vertices) formatted output.  B<pos($buffer)> must be the
offset into B<$buffer> where the data start.  B<$line_no> is the line
number corresponding to that offset.  The updated line number is
returned as well as the parsed data.

B<@vertices> is an array of coordinate arrayrefs, one per vertex.  If
the B<trace> option is specified, the first element in the coordinate
array is the line number in the output the data were parsed from.

=head2 parse_extreme_points

  ( $line_no, \@indices ) = parse_extreme_points( \%option, \$buffer, $line_no );

Parse C<Fx> (extreme point) formatted output.  B<pos($buffer)> must be the
offset into B<$buffer> where the data start.  B<$line_no> is the line
number corresponding to that offset.  The updated line number is
returned as well as the parsed data.

B<@indices> is an array of indices, one per extreme point.  If
the B<trace> option is specified, the elements in B<@indices> are array refs,
with the first element the line number in the output the indices were parsed from.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-qhull@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull>

=head2 Source

Source is available at

  https://gitlab.com/djerius/p5-qhull

and may be cloned from

  https://gitlab.com/djerius/p5-qhull.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Qhull|Qhull>

=item *

L<<=cut|<=cut>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
