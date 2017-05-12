# RCS Status      : $Id: PrinterFontMetrics.pm,v 1.7 2003-10-23 14:12:04+02 jv Exp $
# Author          : Andrew Ford
# Created On      : March 2001
# Last Modified By: Johan Vromans
# Last Modified On: Thu Oct 23 14:12:02 2003
# Update Count    : 45
# Status          : Development

################ Module Preamble ################

package PostScript::PrinterFontMetrics;

use strict;
use Carp;
use Data::Dumper;

BEGIN { require 5.005; }

use IO qw(File);
use File::Spec;

use vars qw($VERSION @ISA $AUTOLOAD);
$VERSION = "0.08";

use PostScript::FontMetrics;
use PostScript::StandardEncoding;

@ISA = qw(PostScript::FontMetrics);

# Definitions of the PFM file layout

use constant PFM_HEADER_LENGTH   => 117;
use constant PFM_HEADER_TEMPLATE => 'vVa60vvvvvvvCCCvCvvCvvCCCCvVVVV';
my @pfm_header_fields 
  = (
     'dfVersion',
     'dfSize',
     'dfCopyright',
     'dfType',
     'dfPoint',
     'dfVertRes',
     'dfHorisRes',
     'dfAscent',                # ATM FontBBox (fourth element)
     'dfInternalLeading',
     'dfExternalLeading',
     'dfItalic',
     'dfUnderline',
     'dfStrikeOut',
     'dfWeight',
     'dfCharSet',
     'dfPixWidth',
     'dfPixHeight',
     'dfPitchAndFamily',
     'dfAvgWidth',
     'dfMaxWidth',
     'dfFirstChar',
     'dfLastChar',
     'dfBreakChar', 
     'dfWidthBytes',
     'dfDevice',
     'dfFace',
     'dfBitsPointer', 
     'dfBitsOffset',
  );

# The PFM Extension table just contains offsets of other structures
# and so its members are not entered into the data hash
 
use constant PFM_EXTENSION_OFFSET     => PFM_HEADER_LENGTH;
use constant PFM_EXTENSION_LENGTH     => 30;
use constant PFM_EXTENSION_TEMPLATE   => 'vVVVVVVV';
my @pfm_extension_fields
  = (
     'dfSizeFields',                    # size of this section
     'dfExtMetricsOffset',              # offset of the Extended Text Metrics section
     'dfExtentTable',                   # offset of the Extent table
     'dfOriginTable',
     'dfPairKernTable',                 # offset of the kern pair table
     'dfTrackKernTable',
     'dfDriverInfo',
     'dfReserved'
    );

use constant PFM_EXT_METRICS_OFFSET   => PFM_EXTENSION_OFFSET + PFM_EXTENSION_LENGTH;
use constant PFM_EXT_METRICS_LENGTH   => 52;
use constant PFM_EXT_METRICS_TEMPLATE => 'v' x 26;
my @pfm_ext_metrics_fields
  = (
     'etmSize',
     'etmPointSize',
     'etmOrientation',
     'etmMasterHeight',
     'etmMinScale',
     'etmMaxScale',
     'etmMasterUnits',
     'etmCapHeight',                    # AFM CapHeight
     'etmXHeight',                      # AFM XHeight
     'etmLowerCaseAscent',              # AFM Ascender
     'etmLowerCaseDescent',             # AFM -Descender
     'etmSlant',
     'etmSuperScript',
     'etmSubScript',
     'etmSuperScriptSize',
     'etmSubScriptSize',
     'etmUnderlineOffset',              # AFM -UnderlinePostition
     'etmUnderlineWidth',               # AFM UnderlineThickness
     'etmDoubleUpperUnderlineOffset',
     'etmDoubleLowerUnderlineOffset',
     'etmDoubleUpperUnderlineWidth',
     'etmDoubleLowerUnderlineWidth',
     'etmStrikeOutOffset',
     'etmStrikeOutWidth',
     'etmKernPairs',                    # number of kern pairs
     'etmKernTracks',
    );

use constant PFM_PSINFO_OFFSET   => PFM_EXT_METRICS_OFFSET + PFM_EXT_METRICS_LENGTH;
my @pfm_postscript_info_fields
  = (
     'DeviceType',
     'WindowsName',
     'PostScriptName',          # AFM FontName
    );

my %pfm_field_map = ( map { $_ => \&_pfm_header }         @pfm_header_fields,
                      map { $_ => \&_pfm_extension }      @pfm_extension_fields,
                      map { $_ => \&_pfm_ext_metrics }    @pfm_ext_metrics_fields,
                      map { $_ => \&_pfm_device_section } @pfm_postscript_info_fields );

sub new {
    my $class = shift;
    my $font = shift;
    my %atts = ( error => 'die',
		 verbose => 0, trace => 0, debug => 0,
		 @_ );
    my $self = { file => $font };
    bless $self, $class;

    return $self unless defined $font;

    $self->{debug}   = $atts{debug};
    $self->{trace}   = $self->{debug} || $atts{trace};
    $self->{verbose} = $self->{trace} || $atts{verbose};

    my $error = lc($atts{error});
    $self->{die} = sub {
	die(@_)     if $error eq "die";
	warn(@_)    if $error eq "warn";
    };

    eval { $self->_loadpfm };
    if ( $@ ) {
        $self->_die($@);
        return undef;
    }

    $self;
}

sub FileName  { return $_[0]->{file};    }
sub FontName  { return $_[0]->_pfm_device_section->{PostScriptName}; }
sub CapHeight { return $_[0]->_pfm_extended_text_metrics->{etmCapHeight}; }
sub XHeight   { return $_[0]->_pfm_extended_text_metrics->{etmXHeight}; }
sub Ascender  { return $_[0]->_pfm_extended_text_metrics->{etmLowerCaseAscent}; }
sub Descender { return -$_[0]->_pfm_extended_text_metrics->{etmLowerCaseDescent}; }
sub MetricsData { return $_[0]->{_rawdata}; }

sub HeaderFields     { return @pfm_header_fields; }
sub ExtensionFields  { return @pfm_extension_fields; }
sub ExtMetricsFields { return @pfm_ext_metrics_fields; }
sub DeviceInfoFields { return @pfm_postscript_info_fields; }

sub CharWidthData {
    my $self = shift;
    my $char = $self->_pfm_header->{dfFirstChar};
    my $encoding =
      $self->{encodingvector} ||= PostScript::StandardEncoding->array;
    my $widthdata = {};
    foreach my $width (@{$self->_pfm_extent_table}) {
        my $char = $encoding->[$char++];
        $widthdata->{$char} = $width if $char and $char ne '.notdef';
    }
    $widthdata;
}

sub EncodingVector {
    my $self = shift;
    $self->{encodingvector} ||= PostScript::StandardEncoding->array;
}

sub KernData {
    my $self = shift;
    my $raw_kerndata = $self->_pfm_kerndata;
    my %enc_kerndata;

    my $encoding =
      $self->{encodingvector} ||= PostScript::StandardEncoding->array;
    while (my($pair, $kern) = each(%$raw_kerndata)) {
        my($c1,$c2) = unpack("aa", $pair);
        $enc_kerndata{$encoding->[ord $c1], $encoding->[ord $c2]} = $kern;
    }
    return \%enc_kerndata;
}

# _loadpfm just reads the PFM file into memory (as the _rawdata element)
# The individual file sections are only unpacked as and when they are needed.

sub _loadpfm ($) {
    my($self) = @_;

    my $fn = $self->{file};
    local *FH;					# font file
    my $sz = $self->{filesize} = -s $fn;        # file size

    open(FH, $fn) || $self->_die("$fn: $!\n");
    print STDERR ("$fn: Loading PFM file\n") if $self->{verbose};
    binmode(FH);		# requires a file handle, yuck

    # Read in the pfm data.
    my $len = 0;

    unless ( ($len = sysread (FH, $self->{_rawdata}, $sz, 0)) == $sz ) {
        $self->_die("$fn: Expecting $sz bytes, got $len bytes\n");
    }
}

# Return the PFM file Header section (unpacking if necessary)

sub _pfm_header {
    my $self = shift;
    my $header = $self->{_pfm_header} ||= {};

    if (! keys %$header) {
        @$header{@pfm_header_fields}
          = unpack(PFM_HEADER_TEMPLATE,
                   substr($self->{_rawdata}, 0, PFM_HEADER_LENGTH));
        $header->{dfCopyright} =~ s/\0.*//;

        die "$self->{file}: file size is $self->{filesize} but dfSize = $header->{dfsize}"
          unless $header->{dfSize} == $self->{filesize};
    }
    $header;
}

# Unpack the PFM Extension

sub _pfm_extension {
    my $self = shift;
    my $extension = $self->{_pfm_extension} ||= {};

    if (! keys %$extension) {
        @$extension{@pfm_extension_fields} 
          = unpack(PFM_EXTENSION_TEMPLATE, 
                   substr($self->{_rawdata}, PFM_EXTENSION_OFFSET, PFM_EXTENSION_LENGTH));
    }
    $extension;
}

# Unpack PFM extended text metrics

sub _pfm_extended_text_metrics {
    my $self = shift;
    my $ext_metrics = $self->{_ext_metrics} = {};
    if (! keys %$ext_metrics) {
        my $extension = $self->_pfm_extension;
        my $ext_metrics_offset = $extension->{dfExtMetricsOffset}
          || PFM_EXT_METRICS_OFFSET;
        die "$self->{file}: dfDriverInfo points outside file"
          if $ext_metrics_offset > $self->{filesize};

        @$ext_metrics{@pfm_ext_metrics_fields}
          = unpack(PFM_EXT_METRICS_TEMPLATE,
                   substr($self->{_rawdata}, $ext_metrics_offset, PFM_EXT_METRICS_LENGTH));
        delete($extension->{dfExtMetricsOffset})
          unless $self->{_keep_raw_data};
        # delete($self->{_rawdata}) unless keys $self->{_pfm_extension}
    }
    $ext_metrics
}

# Unpack the PFM Device Section

sub _pfm_device_section {
    my $self = shift;
    my $psinfo = $self->{_pfm_device} = {};
    if (! keys %$psinfo) {
        my $header = $self->_pfm_header;
        my $psinfo_offset = $header->{dfDevice} || PFM_PSINFO_OFFSET;
        die "$self->{file}: dfDevice points outside file ($psinfo_offset > $self->{filesize})"
          if $psinfo_offset > $self->{filesize};
        @$psinfo{@pfm_postscript_info_fields}
          = split(/\0/, substr($self->{_rawdata}, $psinfo_offset), 4);
    }
    $psinfo;
}

# Extent table (2 bytes x (1 + dfLastChar - dfFirstChar))
# location is defined by dfExtentTable field in extension table

sub _pfm_extent_table {
    my $self = shift;
    my $extent_table = $self->{_pfm_extent_table} ||= [];
    if (! @$extent_table) {
        my $header    = $self->_pfm_header;
        my $extension = $self->_pfm_extension;
        my $extent_offset = $extension->{dfExtentTable};
        my $extent_entries = 1 + $header->{dfLastChar} - $header->{dfFirstChar};
        @$extent_table = unpack('v' x $extent_entries,
                                substr($self->{_rawdata}, $extent_offset));
    }
    $extent_table;
}

# Return the raw kern data (unpacking if necessary)

sub _pfm_kerndata {
    my $self = shift;
    my $kerndata = $self->{_pfm_kerndata} ||= {};
    if (! keys %$kerndata) {
        my $extension = $self->_pfm_extension;
        my $kerntable_offset = $extension->{dfPairKernTable};
        if ($kerntable_offset) {
            my($kerntable_len) = unpack('v', substr($self->{_rawdata},
                                                    $kerntable_offset, 2));
            foreach (unpack('a4' x $kerntable_len,
                            substr($self->{_rawdata},
                                   $kerntable_offset + 2,
                                   4 * $kerntable_len))) {
                my($pair, $kern) = unpack('a2v', $_);
                $kern -= 65536 if $kern > 32768;
                $kerndata->{$pair} = int $kern;
            }
        }
    }
    $kerndata;
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /::DESTROY$/;
    die "Undefined subroutine $AUTOLOAD" 
      unless exists $pfm_field_map{$AUTOLOAD};
    my $struct = &{$pfm_field_map{$AUTOLOAD}};
    $struct->{$AUTOLOAD};
}

sub _die {
    my ($self, @msg) = @_;
    $self->{die}->(@msg);
}

1;

__END__

################ Documentation ################

=head1 NAME

PostScript::PrinterFontMetrics - module to fetch data from Printer Font Metrics files

=head1 SYNOPSIS

  my $info = new PostScript::PrinterFontMetrics (filename, options);
  print STDOUT ("Name = ", $info->FontName, "\n");
  print STDOUT ("Width of LAV = ", $info->kstringwidth("LAV", 10), "\n");

=head1 DESCRIPTION

This package allows printer font metric files for PostScript files (so
called C<.pfm> files) to be read and (partly) parsed.  PFM files
contain information that overlaps with that contained in AFM files and
can be used with the font files to generate missing AFM files.

=head1 CONSTRUCTOR

=over 4

=item new ( FILENAME [ , OPTIONS ])

The constructor will read the file and parse its contents.

=back

=head1 OPTIONS

=over 4

=item error => [ 'die' | 'warn' | 'ignore' ]

B<DEPRECATED>. Please use 'eval { ... }' to intercept errors.

How errors must be handled. Default is to call die().
In any case, new() returns a undefined result.
Setting 'error' to 'ignore' may cause surprising results.

=item verbose => I<value>

Prints verbose info if I<value> is true.

=item trace => I<value>

Prints tracing info if I<value> is true.

=item debug => I<value>

Prints debugging info if I<value> is true.
Implies 'trace' and 'verbose'.

=back

=head1 INSTANCE METHODS

B<Note:> Most of the info from the PFM file can be obtained by calling
a method of the same name, e.g. C<dfMaxWidth> and C<etmCapHeight>.
Fields that overlap with fields in the AFM file are also available
using the AFM name, e.g. C<etmCapHeight> can be referred to as
C<CapHeight>, and C<PostScriptName> as C<FontName>.

Each of these methods returns C<undef> if the corresponding
information could not be found in the file.

=over 4

=item FileName

The name of the file, e.g. 'tir_____.pfm'.
This is not derived from the metrics data, but the name of the file as
passed to the C<new> method.

=item MetricsData

The complete contents of the file -- note though that PFM files are binary files.

=item CharWidthData

Returns a reference to a hash with the character widths for each glyph.

=item EncodingVector

Returns a reference to an array with the glyph names for each encoded
character.

=item KernData

Returns a reference to a hash with the kerning data for glyph pairs.
It is indexed by two glyph names (two strings separated by a comma,
e.g. $kd->{"A","B"}).

=back

This module also inherits methods from PostScript::FontMetrics.

=head1 NOTES

PFM files contain information that overlaps with AFM files, including
character widths and kerning pairs.  

The PFM file specification is available in the Microsoft Windows
Device Development Kit (DDK) (for Windows 3.1), however I have been
unable to locate this document.  Details of the structure of PFM were
gleaned from an Adobe technical note and by examining sample PFM
files.

=head1 SEE ALSO

=over 4

=item http://partners.adobe.com/asn/developers/pdfs/tn/5178.PFM.pdf

I<Building PFM Files for PostScript-Language CJK Fonts> describes the
structure of PFM files for CJK files, but the information appears to
be applicable for western fonts too.

=back

=head1 AUTHOR

Andrew Ford, Ford & Mason Ltd <A.Ford@ford-mason.co.uk>

This module draws heavily on the C<PostScript::FontMetrics> module by
Johan Vromans.

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2001 by Andrew Ford and Ford & Mason Ltd.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
