#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use 5.010;
use strict;
use warnings;

package PDF::Table;

# portions (c) copyright 2004 Stone Environmental Inc.
# (c) copyright 2006 Daemmon Hughes
# (c) copyright 2020 - 2025 by Phil M. Perry
 
use Carp;
use List::Util qw[min max];  # core

use PDF::Table::ColumnWidth;
use PDF::Table::Settings;
# can't move text_block() b/c many globals referenced

our $VERSION = '1.007'; # fixed, read by Makefile.PL
our $LAST_UPDATE = '1.007'; # manually update whenever code is changed
# don't forget to update VERSION down in POD area

my $compat_mode = 0; # 0 = new behaviors, 1 = compatible with old
# NOTE that a number of t-tests will FAIL in mode 1 (compatible with old)
#      due to slightly different text placements

# ================ COMPATIBILITY WITH OLDER VERSIONS ===============
my $repeat_default   = 1;  # header repeat: old = change to 0
my $oddeven_default  = 1;  # odd/even lines, use old method = change to 0
my $padding_default  = 2;  # 2 points of padding. old = 0 (no padding)
# ==================================================================
if ($compat_mode) {  # 1: be compatible with older PDF::Table behavior
    ($repeat_default, $oddeven_default, $padding_default) = (0, 0, 0);
} else {  # 0: do not force compatibility with older PDF::Table behavior
    ($repeat_default, $oddeven_default, $padding_default) = (1, 1, 2);
}

# ================ OTHER GLOBAL DEFAULTS =========================== per #7
my $fg_color_default   = 'black';   # foreground text color
#  no bg_color_default (defaults to transparent background)
my $h_fg_color_default = '#000066'; # fg text color for header
my $h_bg_color_default = '#FFFFAA'; # bg color for header
my $font_size_default  = 12; # base font size
my $leading_ratio      = 1.25;  # leading/font_size ratio (if 'lead' not given)
my $border_w_default   = 1;  # line width for borders
my $max_wordlen_default = 20; # split any run of 20 non-space chars
my $empty_cell_text    = '-'; # something to put in an empty cell
my $dashed_rule_default = 2;  # dash/space pattern length for broken rows
my $min_col_width      = 2;  # absolute minimum width of a column, > 0
# ==================================================================
my $ink = 1;  # by default, actually make PDF output

print __PACKAGE__.' is version: '.$VERSION.$/ if ($ENV{'PDF_TABLE_DEBUG'});

############################################################
#
# new - Constructor
#
# Parameters are meta information about the PDF. They may be
# omitted, so long as the information is passed instead to
# the table() method.
#
# $pdf = PDF::Table->new();
# $page = $pdf->page();
# $data
# %options
#
############################################################

sub new {
    my $type = shift(@_);
    my $class = ref($type) || $type;
    my $self  = {};
    bless ($self, $class);

    # Pass all the rest to init for validation and initialization
    $self->_init(@_);

    return $self;
}

sub _init {
    my ($self, $pdf, $page, $data, %options ) = @_;

    # Check and set default values
    $self->set_defaults();

    # Check and set mandatory parameters
    $self->set_pdf($pdf);
    $self->set_page($page);
    $self->set_data($data);
    $self->set_options(\%options);

    return;
}

sub set_defaults {
    my $self = shift;

    $self->{'font_size'} = $font_size_default;
    $min_col_width = max($min_col_width, 1);  # minimum width
    return;
}

sub set_pdf {
    my ($self, $pdf) = @_;
    $self->{'pdf'} = $pdf;
    return;
}

sub set_page {
    my ($self, $page) = @_;
    if ( defined($page) && ref($page) ne 'PDF::API2::Page'
                        && ref($page) ne 'PDF::Builder::Page' ) {

        if (ref($self->{'pdf'}) eq 'PDF::API2' ||
            ref($self->{'pdf'}) eq 'PDF::Builder') {
            $self->{'page'} = $self->{'pdf'}->page();
        } else {
            carp 'Warning: Page must be a PDF::API2::Page or PDF::Builder::Page object but it seems to be: '.ref($page).$/;
            carp 'Error: Cannot set page from passed PDF object either, as it is invalid!'.$/;
        }
        return;
    }
    $self->{'page'} = $page;
    return;
}

sub set_data {
    my ($self, $data) = @_;
    # TODO: implement
    return;
}

sub set_options {
    my ($self, $options) = @_;
    # TODO: implement
    return;
}

################################################################
# table - utility method to build multi-row, multicolumn tables
################################################################

sub table {
#use Storable qw( dclone );
# can't use Storable::dclone because can't handle CODE. would like to deep
# clone %arg so that modifications (remove leading '-' and/or substitute for
# deprecated names) won't modify original %arg hash on the outside.
    my $self    = shift;
    my $pdf     = shift;
    my $page    = shift;
    my $data    = shift;
    my %arg     = @_;

    #=====================================
    # Mandatory Arguments Section
    #=====================================
    unless ($pdf and $page and $data) {
        carp "Error: Mandatory parameter is missing PDF/page/data object!\n";
        return ($page, 0, 0);
    }

    # Validate mandatory argument data type
    croak "Error: Invalid PDF object received."  
        unless (ref($pdf) eq 'PDF::API2' ||
                ref($pdf) eq 'PDF::Builder');
    croak "Error: Invalid page object received." 
        unless (ref($page) eq 'PDF::API2::Page' || 
                ref($page) eq 'PDF::Builder::Page');
    croak "Error: Invalid data received." 
        unless ((ref($data) eq 'ARRAY') && scalar(@$data));
    croak "Error: Missing required settings." 
        unless (scalar(keys %arg));

    # ==================================================================
    # did client code ask to redefine?
    ($repeat_default, $oddeven_default, $padding_default) =
      @{$arg{'compatibility'}} if defined $arg{'compatibility'};

    # set some defaults  !!!!
    $arg{'cell_render_hook' } ||= undef; 

    # $ink is whether or not to output PDF, as opposed to sizing
    $ink = $arg{'ink'} if defined $arg{'ink'}; # 1 yes, 0 no (size)
    my @vsizes;

    # Validate settings key
    my %valid_settings_key = (
        'x'                     => 1,  # global, mandatory
        'w'                     => 1,  # global, mandatory
        'y'                     => 1,  # global, mandatory
          'start_y'             => 1,  #  deprecated
        'h'                     => 1,  # global, mandatory
          'start_h'             => 1,  #  deprecated
        'ink'                   => 1,  # global
        'next_y'                => 1,  # global
        'next_h'                => 1,  # global
        'leading'               => 1,  #         text_block
          'lead'                => 1,  #  deprecated
        'padding'               => 1,  # global
         'padding_right'        => 1,  # global
         'padding_left'         => 1,  # global
         'padding_top'          => 1,  # global
         'padding_bottom'       => 1,  # global
        'bg_color'              => 1,  # global, header, row, column, cell
          'background_color'    => 1,  #  deprecated
        'bg_color_odd'          => 1,  # global, column, cell
          'background_color_odd'=> 1,  #  deprecated
        'bg_color_even'         => 1,  # global, column, cell
          'background_color_even'=> 1,  # deprecated
        'fg_color'              => 1,  # global, header, row, column, cell
          'font_color'          => 1,  #  deprecated
        'fg_color_odd'          => 1,  # global, column, cell
          'font_color_odd'      => 1,  #  deprecated
        'fg_color_even'         => 1,  # global, column, cell
          'font_color_even'     => 1,  #  deprecated
        'border_w'              => 1,  # global
          'border'              => 1,  #  deprecated
        'h_border_w'            => 1,  # global
          'horizontal_borders'  => 1,  #  deprecated
        'v_border_w'            => 1,  # global
          'vertical_borders'    => 1,  #  deprecated
        'border_c'              => 1,  # global
          'border_color'        => 1,  #  deprecated
        # possibly in future, separate h_border_c and v_border_c
        'rule_w'                => 1,  # global, row, column, cell
         'h_rule_w'             => 1,  # global, row, column, cell
         'v_rule_w'             => 1,  # global, row, column, cell
        'rule_c'                => 1,  # global, row, column, cell
         'h_rule_c'             => 1,  # global, row, column, cell
         'v_rule_c'             => 1,  # global, row, column, cell
        'font'                  => 1,  # global, header, row, column, cell
        'font_size'             => 1,  # global, header, row, column, cell
        'underline'             => 1,  # global, header, row, column, cell
          'font_underline'      => 1,  #  deprecated
        'min_w'                 => 1,  # global, header, row, column, cell
        'max_w'                 => 1,  # global, header, row, column, cell
        'min_rh'                 => 1,  # global, header, row, column, cell
          'row_height'          => 1,  # deprecated
        'new_page_func'         => 1,  # global
        'header_props'          => 1,   # includes sub-settings like repeat
        'row_props'             => 1,   # includes sub-settings like fg_color
        'column_props'          => 1,   # includes sub-settings like fg_color
        'cell_props'            => 1,   # includes sub-settings like fg_color
        'max_word_length'       => 1,  # global, text_block
        'cell_render_hook'      => 1,  # global
        'default_text'          => 1,  # global
        'justify'               => 1,  # global
      # 'repeat'                       #         header
      # 'align'                        #         text_block
      # 'parspace'                     #         text_block
      # 'hang'                         #         text_block
      # 'flindent'                     #         text_block
      # 'fpindent'                     #         text_block
      # 'indent'                       #         text_block
        'size'                  => 1,  # global
    );
    foreach my $key (keys %arg) {
        # Provide backward compatibility
        $arg{$key} = delete $arg{"-$key"} if $key =~ s/^-//;

        croak "Error: Invalid setting key '$key' received."
            unless exists $valid_settings_key{$key};
    }


    my ( $xbase, $ybase, $width, $height ) = ( undef, undef, undef, undef );
    # TBD eventually deprecated start_y and start_h go away
    # special treatment here because haven't yet copied deprecated names
    $xbase  = $arg{'x'} || -1;
    $ybase  = $arg{'y'} || $arg{'start_y'} || -1;
    $width  = $arg{'w'} || -1;
    $height = $arg{'h'} || $arg{'start_h'} || -1;

    # Global geometry parameters are also mandatory.
    unless ( $xbase  > 0 ) {
        carp "Error: Left Edge of Table is NOT defined!\n";
        return ($page, 0, $ybase);
    }
    unless ( $ybase  > 0 ) {
        carp "Error: Base Line of Table is NOT defined!\n";
        return ($page, 0, $ybase);
    }
    unless ( $width  > 0 ) {
        carp "Error: Width of Table is NOT defined!\n";
        return ($page, 0, $ybase);
    }
    unless ( $height > 0 ) {
        carp "Error: Height of Table is NOT defined!\n";
        return ($page, 0, $ybase);
    }
    my $bottom_margin = $ybase - $height;

    my $pg_cnt      = 1;
    my $cur_y       = $ybase;
    my $cell_props  = $arg{'cell_props'} || [];   # per cell properties

    # If there is no valid data array reference, warn and return!
    if (ref $data ne 'ARRAY') {
        carp "Passed table data is not an ARRAY reference. It's actually a ref to ".ref($data);
        return ($page, 0, $cur_y);
    }

    # Ensure default values for next_y and next_h 
    my $next_y  = $arg{'next_y'} || undef;
    my $next_h  = $arg{'next_h'} || undef;
    my $size    = $arg{'size'}   || undef;

    # Create Text Object
    my $txt     = $page->text();  # $ink==0 still needs for font size, etc.
    # doing sizing or actual output?
    if (!$ink) {
        @vsizes = (0, 0, 0);  # overall, header, footer (future)
        # push each row onto @vsizes as defined
        # override y,h to nearly infinitely large (will never paginate)
        $ybase = $height = 2147000000;
    }

    #=====================================
    # Table Header Section
    #
    # order of precedence: header_props, column_props, globals, defaults
    # here, header settings are initialized to globals/defaults
    #=====================================
    # Disable header row into the table
    my $header_props = undef;
    my $do_headers = 0;  # not doing headers

    # Check if the user enabled it ?
    if (defined $arg{'header_props'} and ref( $arg{'header_props'}) eq 'HASH') {
        # Transfer the reference to local variable
        $header_props = $arg{'header_props'};

        # Check other parameters and put defaults if needed
        $header_props->{'repeat'   } //= $repeat_default;

        $do_headers = 1;  # do headers, no repeat
        $do_headers = 2 if $header_props->{'repeat'};  # do headers w/ repeat
    }

    my $header_row  = undef;
    # Copy the header row (text) if header is enabled
    @$header_row = $$data[0] if $do_headers;
    # Determine column widths based on content

    # an arrayref whose values are a hashref holding
    # the minimum and maximum width of that column
    my $col_props = $arg{'column_props'} || [];

    # an arrayref whose values are a hashref holding
    # various row settings for a specific row
    my $row_props = $arg{'row_props'} || [];

    # deprecated setting (globals) names, copy to new names
    PDF::Table::Settings::deprecated_settings(
         $data, $row_props, $col_props, $cell_props, $header_props, \%arg);
    # check settings values as much as possible
    PDF::Table::Settings::check_settings(%arg);

    #=====================================
    # Set Global Default Properties
    #=====================================
    # geometry-related global settings checked, last value for find_value()
    my $fnt_obj        = $arg{'font'            } ||
                         $pdf->corefont('Times-Roman',-encode => 'latin1');
    my $fnt_size       = $arg{'font_size'       } || $font_size_default;
    my $min_leading    = $fnt_size * $leading_ratio;
    my $leading        = $arg{'leading'} || $min_leading;
    if ($leading < $fnt_size) {
        carp "Warning: Global leading value $leading is less than font size $fnt_size, increased to $min_leading\n";
        $arg{'leading'} = $leading = $min_leading;
    }

    # can't condense $border_w to || because border_w=>0 gets default of 1!
    my $border_w        = defined $arg{'border_w'}? $arg{'border_w'}: 1;
    my $h_border_w = $arg{'h_border_w'} || $border_w;
    my $v_border_w  = $arg{'v_border_w'} || $border_w;

    # non-geometry global settings
    my $border_c        = $arg{'border_c'} || $fg_color_default;
    # global fallback values for find_value() call
    my $underline       = $arg{'underline'       } || 
                          undef; # merely stating undef is the intended default
    my $max_word_len    = $arg{'max_word_length' } || $max_wordlen_default;
    my $default_text    = $arg{'default_text'  } || $empty_cell_text;

    # An array ref of arrayrefs whose values are
    # the actual widths of the column/row intersection
    my $row_col_widths = [];
    # An array ref with the widths of the header row
    my $h_row_widths = [];

    # Scalars that hold sum of the maximum and minimum widths of all columns
    my ( $max_col_w, $min_col_w ) = ( 0,0 );
    my ( $row, $space_w );

    my $word_widths   = {};
    my $rows_height   = [];
    my $first_row     = 1;
    my $is_header_row = 0;

    # per-cell values
    my ($cell_font, $cell_font_size, $cell_underline, $cell_justify, 
        $cell_height, $cell_pad_top, $cell_pad_right, $cell_pad_bot, 
        $cell_pad_left, $cell_leading, $cell_max_word_len, $cell_bg_color,
        $cell_fg_color, $cell_bg_color_even, $cell_bg_color_odd,
        $cell_fg_color_even, $cell_fg_color_odd, $cell_min_w, $cell_max_w,
        $cell_h_rule_w, $cell_v_rule_w, $cell_h_rule_c, $cell_v_rule_c,
        $cell_def_text, $cell_markup);

    # for use by find_value()
    my $GLOBALS = [$cell_props, $col_props, $row_props, -1, -1, \%arg];
    # ----------------------------------------------------------------------
    # GEOMETRY
    # figure row heights and column widths, 
    # update overall table width if necessary
    # here we're only interested in things that affect the table geometry
    #
    # $rows_height->[$row_idx] array overall height of each row
    # $calc_column_widths overall width of each column
    my $col_min_width   = []; # holds the running width of each column
    my $col_max_content = []; #  min and max (min_w & longest word,
                              #  length of content)
    my $max_w           = []; # each column's max_w, if defined
    for ( my $row_idx = 0; $row_idx < scalar(@$data) ; $row_idx++ ) {
        $GLOBALS->[3] = $row_idx;
        my $column_widths = []; # holds the width of each column
        # initialize the height for this row
        $rows_height->[$row_idx] = 0;

        for ( my $col_idx = 0; 
              $col_idx < scalar(@{$data->[$row_idx]}); 
              $col_idx++ ) {
            $GLOBALS->[4] = $col_idx;
            # initialize min and max column content widths to 0
            $col_min_width->[$col_idx]=0 if !defined $col_min_width->[$col_idx];
            $col_max_content->[$col_idx]=0 if !defined $col_max_content->[$col_idx];

            # determine if this content is a simple string for normal usage,
            # or it is markup
            my $bad_markup = ''; 
            if (ref($data->[$row_idx][$col_idx]) eq '') {
                # it is a scalar string for normal usage
                # (or some data easily stringified)
                $cell_markup = '';
            } elsif (ref($data->[$row_idx][$col_idx]) eq 'ARRAY') {
                # it is an array for markup usage. exact type is the first 
                # element.
                if (!defined $data->[$row_idx][$col_idx]->[0]) {
                    $bad_markup = 'array has no data';
                } else {
                    $cell_markup = $data->[$row_idx][$col_idx]->[0];

                    # [0] should be none, md1, html, or pre
                    if ($cell_markup ne 'none' && $cell_markup ne 'md1' &&
                        $cell_markup ne 'html' && $cell_markup ne 'pre') {
                        $bad_markup = "markup type '$cell_markup' unsupported";
                    # [1] should be string or array of strings
                    } elsif (defined $data->[$row_idx][$col_idx]->[1] &&
                             ref($data->[$row_idx][$col_idx]->[1]) ne ''  &&
                             ref($data->[$row_idx][$col_idx]->[1]) ne 'ARRAY') {
                        $bad_markup = 'data not string or array of strings';
                    # [2] should be hash reference (possibly empty)
                    } elsif (defined $data->[$row_idx][$col_idx]->[2] &&
                             ref($data->[$row_idx][$col_idx]->[2]) ne 'HASH') {
                        $bad_markup = 'options not hash ref';
                    }
                    # [3+] additional elements ignored
                }
            } else {
                # um, is not a legal data type for this purpose, even if it
                # IS able to stringify to something reasonable.
                # See if we can stringify it... better than a total failure?
                my $string = '';  # in case stringification fails
                $bad_markup = ''; # in case stringification succeeds
                eval { $string = ''.$data->[$row_idx][$col_idx]; };
                    $bad_markup = 'is not a string or array reference' if $@;
                $data->[$row_idx][$col_idx] = $string;
                # if fatal error in eval, $string will be empty, and $bad_markup
                #   will cause it to be ignored anyway
            }
            if ($bad_markup ne '') {
                # replace bad markup with a simple string
                carp "Cell $row_idx,$col_idx $bad_markup.\n";
                $data->[$row_idx][$col_idx] = '(invalid)';
                $cell_markup = '';
            }

            if ( !$row_idx && $do_headers ) {
                # header row
                $is_header_row     = 1;
                $GLOBALS->[3] = 0;
                $cell_font         = $header_props->{'font'};
                $cell_font_size    = $header_props->{'font_size'};
                $cell_leading      = $header_props->{'leading'};
                $cell_height       = $header_props->{'min_rh'};
                $cell_pad_top      = $header_props->{'padding_top'} ||
                                     $header_props->{'padding'};
                $cell_pad_right    = $header_props->{'padding_right'} ||
                                     $header_props->{'padding'};
                $cell_pad_bot      = $header_props->{'padding_bottom'} ||
                                     $header_props->{'padding'};
                $cell_pad_left     = $header_props->{'padding_left'} ||
                                     $header_props->{'padding'};
                $cell_max_word_len = $header_props->{'max_word_length'};
                $cell_min_w        = $header_props->{'min_w'};
                $cell_max_w        = $header_props->{'max_w'};
                $cell_def_text     = $header_props->{'default_text'};
               # items not of interest for determining geometry
               #$cell_underline    = $header_props->{'underline'};
               #$cell_justify      = $header_props->{'justify'};
               #$cell_bg_color     = $header_props->{'bg_color'};
               #$cell_fg_color     = $header_props->{'fg_color'};
               #$cell_bg_color_even= undef;
               #$cell_bg_color_odd = undef;
               #$cell_fg_color_even= undef;
               #$cell_fg_color_odd = undef;
               #$cell_h_rule_w     = header_props->{'h_rule_w'}; 
               #$cell_v_rule_w     = header_props->{'v_rule_w'}; 
               #$cell_h_rule_c     = header_props->{'h_rule_c'}; 
               #$cell_v_rule_c     = header_props->{'v_rule_c'};
            } else {
                # not a header row, so uninitialized
                $is_header_row     = 0;
                $cell_font         = undef;
                $cell_font_size    = undef;
                $cell_leading      = undef;
                $cell_height       = undef;
                $cell_pad_top      = undef;
                $cell_pad_right    = undef;
                $cell_pad_bot      = undef;
                $cell_pad_left     = undef;
                $cell_max_word_len = undef;
                $cell_min_w        = undef;
                $cell_max_w        = undef;
                $cell_def_text     = undef;
               # items not of interest for determining geometry
               #$cell_underline    = undef;
               #$cell_justify      = undef;
               #$cell_bg_color     = undef;
               #$cell_fg_color     = undef;
               #$cell_bg_color_even= undef;
               #$cell_bg_color_odd = undef;
               #$cell_fg_color_even= undef;
               #$cell_fg_color_odd = undef;
               #$cell_h_rule_w     = undef; 
               #$cell_v_rule_w     = undef; 
               #$cell_h_rule_c     = undef; 
               #$cell_v_rule_c     = undef;
            }

            # Get the most specific value if none was already set from header_props
            # TBD should header_props be treated like a row_props (taking
            # precedence over row_props), but otherwise like a row_props? or
            # should anything in header_props take absolute precedence as now?

            $cell_font         = find_value($cell_font, 
                                            'font', '', $fnt_obj, $GLOBALS);
            $cell_font_size    = find_value($cell_font_size, 
                                           'font_size', '', 0, $GLOBALS);
            if ($cell_font_size == 0) { 
                if ($is_header_row) {
                    $cell_font_size = $fnt_size + 2; 
                } else {
                    $cell_font_size = $fnt_size;
                }
            }
            $cell_leading      = find_value($cell_leading, 'leading', 
                                            '', -1, $GLOBALS);
            $cell_height       = find_value($cell_height, 
                                            'min_rh', '', 0, $GLOBALS);
            $cell_pad_top      = find_value($cell_pad_top, 'padding_top', 
                                            'padding', $padding_default, 
                                            $GLOBALS);
            $cell_pad_right    = find_value($cell_pad_right, 'padding_right', 
                                            'padding', $padding_default, 
                                            $GLOBALS);
            $cell_pad_bot      = find_value($cell_pad_bot, 'padding_bottom', 
                                            'padding', $padding_default, 
                                            $GLOBALS);
            $cell_pad_left     = find_value($cell_pad_left, 'padding_left', 
                                            'padding', $padding_default, 
                                            $GLOBALS);
            $cell_max_word_len = find_value($cell_max_word_len, 'max_word_len', 
                                            '', $max_word_len, $GLOBALS);
            $cell_min_w        = find_value($cell_min_w, 'min_w', 
                                            '', undef, $GLOBALS);
            $cell_max_w        = find_value($cell_max_w, 'max_w', 
                                            '', undef, $GLOBALS);
            if (defined $cell_max_w && defined $cell_min_w) {
                $cell_max_w = max($cell_max_w, $cell_min_w);
            }
            $cell_def_text  = find_value($cell_def_text, 'default_text', '', 
                                         $default_text, $GLOBALS);
           # items not of interest for determining geometry
           #$cell_underline = find_value($cell_underline, 
           #                             'underline', '', $underline, $GLOBALS);
           #$cell_justify   = find_value($cell_justify, 
           #                             'justify', '', 'left', $GLOBALS);
           #$cell_bg_color  = find_value($cell_bg_color, 'bg_color',
           #                             '', undef, $GLOBALS);
           #$cell_fg_color  = find_value($cell_fg_color, 'fg_color',
           #                             '', $fg_color_default, $GLOBALS);
           #$cell_bg_color_even = find_value($cell_bg_color_even, 
           #                             'bg_color_even', '', undef, $GLOBALS);
           #$cell_bg_color_odd = find_value($cell_bg_color_odd, 
           #                             'bg_color_odd', '', undef, $GLOBALS);
           #$cell_fg_color_even = find_value($cell_fg_color_even, 
           #                             'fg_color_even', '', undef, $GLOBALS);
           #$cell_fg_color_odd = find_value($cell_fg_color_odd, 
           #                             'fg_color_odd', '', undef, $GLOBALS);
           #$cell_h_rule_w = find_value($cell_h_rule_w, 'h_rule_w',
           #                             'rule_w', $h_border_w, $GLOBALS);
           #$cell_v_rule_w = find_value($cell_v_rule_w, 'v_rule_w',
           #                             'rule_w', $v_border_w, $GLOBALS);
           #$cell_h_rule_c = find_value($cell_h_rule_c, 'h_rule_c',
           #                             'rule_c', $border_c, $GLOBALS);
           #$cell_v_rule_c = find_value($cell_v_rule_c, 'v_rule_c',
           #                             'rule_c', $border_c, $GLOBALS);

            my $min_leading    = $cell_font_size * $leading_ratio;
            if ($cell_leading <= 0) {
                # leading left at default, silently set to minimum
                $cell_leading = $min_leading;
            } else {
                # leading specified, but is too small?
                if ($cell_leading < $cell_font_size) {
                    carp "Warning: Cell[$row_idx][$col_idx] leading value $cell_leading is less than font size $cell_font_size, increased to $min_leading\n";
                    $cell_leading = $min_leading;
                }
            }

            # Set Font
            $txt->font( $cell_font, $cell_font_size );

            # Set row height to biggest font size from row's cells
            # Note that this assumes just one line of text per cell
            $rows_height->[$row_idx] = max($rows_height->[$row_idx], 
                $cell_leading + $cell_pad_top + $cell_pad_bot, $cell_height);

            # This should fix a bug with very long words like serial numbers,
            # etc. TBD: consider splitting ONLY on end of line, and adding a
            # hyphen (dash) at split. would have to track split words (by
            # index numbers?) and glue them back together when there's space
            # to do so (including hyphen).
            # update: split words only if simple strings (not calling column())
            if ( $cell_max_word_len > 0 && $data->[$row_idx][$col_idx] &&
                 ref($data->[$row_idx][$col_idx]) eq '') {
                $data->[$row_idx][$col_idx] =~ s#(\S{$cell_max_word_len})(?=\S)#$1 #g;
            }

            # Init cell size limits (per row)
            $space_w                   = $txt->advancewidth( "\x20" );
                # font/size can change for each cell, so space width can vary
            $column_widths->[$col_idx] = 0;  # per-row basis
            $max_col_w                 = 0;
            $min_col_w                 = 0;

            my @words;
            @words = split( /\s+/, $data->[$row_idx][$col_idx] )
                if $data->[$row_idx][$col_idx];
            # TBD count up spaces instead of assuming one between each word,
            #       don't know what to do about \t (not defined!). NBSP would
            #       be treated as non-space for these calculations, not sure
            #       how it would render. \r, \n, etc. no space? then there is
            #       check how text is split into lines in text_block if 
            #       multiple spaces between words.

            # for cell, minimum width is longest word, maximum is entire text
            # treat header row like any data row for this
            # increase minimum width to (optional) specified column min width
            # keep (optional) specified column max width separate
            # NOTE that cells with only blanks will be treated as empty (no
            #   words) and have only L+R padding for a width!
            foreach ( @words ) {
                unless ( exists $word_widths->{$_} ) {
                    # Calculate the width of every word and add the space width to it
                    # caching each word so only figure width once
                    $word_widths->{$_} = $txt->advancewidth($_);
                }

                # minimum width is longest word or fragment
                $min_col_w = max($min_col_w, $word_widths->{$_});
                # maximum width is total text in cell 
                if ($max_col_w) {
                    # already have text, so add a space first
                    # note that multiple spaces between words become one!
                    $max_col_w += $space_w;
                } else {
                    # first word, so no space [before]
                }
                $max_col_w += $word_widths->{$_};
            }

            # don't forget any default text! it's not split on max_word_len
            # TBD should default_text be split like other text?
            $min_col_w = max($min_col_w, $txt->advancewidth($cell_def_text));

            # at this point we have longest word (min_col_w), overall length
            # (max_col_w) of this cell. add L+R padding
            # cell_min/max_w are optional settings
            # TBD what if $cell_def_text is longer?
            $min_col_w                 += $cell_pad_left + $cell_pad_right;
            $min_col_w = max($min_col_w, $cell_min_w) if defined $cell_min_w;
            $max_col_w                 += $cell_pad_left + $cell_pad_right;
            $max_col_w = max($min_col_w, $max_col_w);
            $col_min_width->[$col_idx] = max($col_min_width->[$col_idx], 
                                             $min_col_w);
            $col_max_content->[$col_idx] = max($col_max_content->[$col_idx], 
                                             $max_col_w);

            if (!defined $max_w->[$col_idx]) { $max_w->[$col_idx] = -1; }
            $max_w->[$col_idx] = max($max_w->[$col_idx], $cell_max_w) if
                defined $cell_max_w; # otherwise -1
            $column_widths->[$col_idx] = $col_max_content->[$col_idx];

        } # (End of cols) for (my $col_idx....

        $row_col_widths->[$row_idx] = $column_widths;

        # Copy the calculated row properties of header row.
        @$h_row_widths = @$column_widths if !$row_idx && $do_headers;

    } # (End of rows) for ( my $row_idx   row heights and column widths

    # Calc real column widths and expand table width if needed.
    my $calc_column_widths;
    my $em_size = $txt->advancewidth('M');
    my $ex_size = $txt->advancewidth('x');

    if (defined $size) {
        ($calc_column_widths, $width) = 
            PDF::Table::ColumnWidth::SetColumnWidths( 
                   $width, $size, $em_size, $ex_size );
    } else {
        ($calc_column_widths, $width) = 
            PDF::Table::ColumnWidth::CalcColumnWidths( 
                   $width, $col_min_width, $col_max_content, $max_w );
    }

    # ----------------------------------------------------------------------
    # Let's draw what we have!
    my $row_idx      = 0;  # first row (might be header)
    my $row_is_odd   = 0;  # first data row output (row 0) is "even"
    # Store header row height for later use if headers have to be repeated
    my $header_min_rh = $rows_height->[0]; # harmless if no header
    # kind of top border to draw, depending on start or continuation
    my $next_top_border = 0;

    my ( $gfx, $gfx_bg, $bg_color, $fg_color, 
         $bot_margin, $table_top_y, $text_start_y);

    # Each iteration adds a new page as necessary
    while (scalar(@{$data})) {  # still row(s) remaining to output
        my ($page_header, $columns_number);

        if ($pg_cnt == 1) {
            # on first page output
            $table_top_y = $ybase;
            $bot_margin = $table_top_y - $height;

            # Check for safety reasons
            if ( $bot_margin < 0 ) {
                carp "!!! Warning: !!! Incorrect Table Geometry! h ($height) greater than remaining page space y ($table_top_y). Reducing height to fit on page.\n";
                $bot_margin = 0;
                $height = $table_top_y;
            }

        } else {
            # on subsequent (overflow) pages output
            if (ref $arg{'new_page_func'}) {
                $page = &{ $arg{'new_page_func'} };
            } else {
                $page = $pdf->page();
            }

            # we NEED next_y and next_h! if undef, complain and use 
            # 90% and 80% respectively of page height
            if (!defined $next_y) {
                my @page_dim = $page->mediabox();
                $next_y = ($page_dim[3] - $page_dim[1]) * 0.9;
                carp "!!! Error: !!! Table spills to next page, but no next_y was given! Using $next_y.\n";
            }
            if (!defined $next_h) {
                my @page_dim = $page->mediabox();
                $next_h = ($page_dim[3] - $page_dim[1]) * 0.8;
                carp "!!! Error: !!! Table spills to next page, but no next_h was given! Using $next_h.\n";
            }

            $table_top_y = $next_y;
            $bot_margin = $table_top_y - $next_h;

            # Check for safety reasons
            if ( $bot_margin < 0 ) {
                carp "!!! Warning: !!! Incorrect Table Geometry! next_h ($next_h) greater than remaining page space next_y ($next_y), must be reduced to fit on page.\n";
                $bot_margin = 0;
                $next_h = $table_top_y;
            }

            # push copy of header onto remaining table data, if repeated hdr
            if ( $do_headers == 2 ) {
                # Copy Header Data
                @$page_header = @$header_row;
                my $hrw ;
                @$hrw = @$h_row_widths ;
                # Then prepend it to master data array
                unshift @$data, @$page_header;
                unshift @$row_col_widths, $hrw;
                unshift @$rows_height, $header_min_rh;

                $first_row = 1; # Means YES
                # Roll back the row_idx because a new header row added
                $row_idx--; 
            }
             
        }
        # ----------------------------------------------------------------
        # should be at top of table for current page
        # either start of table, or continuation
        # pg_cnt >= 1
        # do_headers = 0 not doing headers
        #              1 non-repeating header
        #              2 repeating header

        # check if enough vertical space for first data row (row 0 or 1), AND 
        # for header (0) if doing a header row! increase height, decrease 
        # bot_margin. possible that bot_margin goes < 0 (warning message).
        # TBD if first page (pg_cnt==1), and sufficient space on next page,
        # just skip first page and go on to second
        # For degenerate cases where there is only a header row and no data
        # row(s), don't try to make use of missing rows height [1]
        my $min_height = $rows_height->[0]; 
        $min_height += $rows_height->[1] if 
            ($do_headers && $pg_cnt==1 || $do_headers==2 && $pg_cnt>1) &&
            defined $rows_height->[1];
        if ($min_height >= $table_top_y - $bot_margin) {
            # Houston, we have a problem. height isn't enough
            my $delta = $min_height - ($table_top_y - $bot_margin) + 1;
            if ($delta > $bot_margin) {
                carp "!! Error !! Insufficient space (by $delta) to get minimum number of row(s) on page. Some content may be lost off page bottom";
            } else {
                carp "!! Warning !! Need to expand allotted vertical height by $delta to fit minimum number of row(s) on page";
            }
            $bot_margin -= $delta;
            if ($pg_cnt == 1) {
                $height += $delta;
            } else {
                $next_h += $delta;
            }
        }

        # order is important -- cell background layer must be rendered
        # before text layer and then other graphics (rules, borders)
        $gfx_bg = $page->gfx() if $ink;
        $txt = $page->text();

        $cur_y = $table_top_y;

        # let's just always go ahead and create $gfx (for drawing borders
        # and rules), as it will almost always be needed
        $gfx = $page->gfx() if $ink;  # for borders, rules, etc.
        $gfx->strokecolor($border_c) if $ink;

        # Draw the top line (border), only if h_border_w > 0, as we
        # don't know what rules are doing
        if ($ink && $h_border_w) {
            if      ($next_top_border == 0) {
                # first top border (page 1), use specified border
                $gfx->linewidth($h_border_w);
            } elsif ($next_top_border == 1) {
                # solid thin line at start of a row
                $gfx->linewidth($border_w_default);
            } else {  # == 2
                # dashed thin line at continuation in middle of row
                $gfx->linewidth($border_w_default);
                $gfx->linedash($dashed_rule_default);
            }
            $gfx->move( $xbase-$v_border_w/2 , $cur_y );
            $gfx->hline($xbase + $width + $v_border_w/2);
            $gfx->stroke();
            $gfx->linedash();
        }

        my @actual_column_widths;
        my %colspanned;

        # Each iteration adds a row to the current page until the page is full
        #  or there are no more rows to add
        # Row_Loop
        while (scalar(@{$data}) and $cur_y-$rows_height->[0] > $bot_margin) {
            # Remove the next item from $data
            my $data_row = shift @{$data};

            # Get max columns number to know later how many vertical lines to draw
            $columns_number = scalar(@$data_row);

            # Get the next set of row related settings
            # Row Height (starting point for $current_min_rh)
            my $current_min_rh = shift @$rows_height;
            my $actual_row_height = $current_min_rh;

            # Row cell widths
            my $data_row_widths = shift @$row_col_widths;

            # remember, don't have cell_ stuff yet, just row items ($row_idx)!
            my $cur_x        = $xbase;
            my $leftovers    = undef;   # Reference to text that is returned from text_block()
            my $do_leftovers = 0; # part of a row spilled to next page

            # Process every cell(column) from current row
            # due to colspan, some rows have fewer columns than others
            my @save_bg_color; # clear out for each row
            my @save_fg_color; 
            my (@save_v_rule_w, @save_v_rule_c, @save_h_rule_w, @save_h_rule_c);
            for ( my $col_idx = 0; $col_idx < $columns_number; $col_idx++ ) {
                $GLOBALS->[3] = $row_idx;
                $GLOBALS->[4] = $col_idx;
                # now have each cell[$row_idx][$col_idx]
                next if $colspanned{$row_idx.'_'.$col_idx};
                $leftovers->[$col_idx] = undef;

                # look for font information for this cell
                my ($cell_font, $cell_font_size, $cell_leading, $cell_underline,
                    $cell_pad_top, $cell_pad_right, $cell_pad_bot, 
                    $cell_pad_left, $cell_justify, $cell_fg_color, 
                    $cell_bg_color, $cell_def_text, $cell_min_w, $cell_max_w);

                if ($first_row and $do_headers) {
                    $is_header_row     = 1;
                    $GLOBALS->[3] = 0;
                    $cell_font         = $header_props->{'font'};
                    $cell_font_size    = $header_props->{'font_size'};
                    $cell_leading      = $header_props->{'leading'};
                    $cell_height       = $header_props->{'min_rh'};
                    $cell_pad_top      = $header_props->{'padding_top'} ||
                                         $header_props->{'padding'};
                    $cell_pad_right    = $header_props->{'padding_right'} ||
                                         $header_props->{'padding'};
                    $cell_pad_bot      = $header_props->{'padding_bottom'} ||
                                         $header_props->{'padding'};
                    $cell_pad_left     = $header_props->{'padding_left'} ||
                                         $header_props->{'padding'};
                    $cell_max_word_len = $header_props->{'max_word_length'};
                    $cell_min_w        = $header_props->{'min_w'};
                    $cell_max_w        = $header_props->{'max_w'};
                    $cell_underline    = $header_props->{'underline'};
                    $cell_def_text     = $header_props->{'default_text'};
                    $cell_justify      = $header_props->{'justify'};
                    $cell_bg_color     = $header_props->{'bg_color'};
                    $cell_fg_color     = $header_props->{'fg_color'};
                    $cell_bg_color_even= undef;
                    $cell_bg_color_odd = undef;
                    $cell_fg_color_even= undef;
                    $cell_fg_color_odd = undef;
                    $cell_h_rule_w     = $header_props->{'h_rule_w'}; 
                    $cell_v_rule_w     = $header_props->{'v_rule_w'}; 
                    $cell_h_rule_c     = $header_props->{'h_rule_c'}; 
                    $cell_v_rule_c     = $header_props->{'v_rule_c'};
                } else {
                    # not header row, so initialize to undefined
                    $is_header_row     = 0;
                    $cell_font         = undef;
                    $cell_font_size    = undef;
                    $cell_leading      = undef;
                    $cell_height       = undef;
                    $cell_pad_top      = undef;
                    $cell_pad_right    = undef;
                    $cell_pad_bot      = undef;
                    $cell_pad_left     = undef;
                    $cell_max_word_len = undef;
                    $cell_min_w        = undef;
                    $cell_max_w        = undef;
                    $cell_underline    = undef;
                    $cell_def_text     = undef;
                    $cell_justify      = undef;
                    $cell_bg_color     = undef;
                    $cell_fg_color     = undef;
                    $cell_bg_color_even= undef;
                    $cell_bg_color_odd = undef;
                    $cell_fg_color_even= undef;
                    $cell_fg_color_odd = undef;
                    $cell_h_rule_w     = undef; 
                    $cell_v_rule_w     = undef; 
                    $cell_h_rule_c     = undef; 
                    $cell_v_rule_c     = undef;
                }

                # Get the most specific value if none was already set from header_props
                $cell_font       = find_value($cell_font, 
                                              'font', '', $fnt_obj, $GLOBALS);
                $cell_font_size  = find_value($cell_font_size, 
                                              'font_size', '', 0, $GLOBALS);
                if ($cell_font_size == 0) { 
                    if ($is_header_row) {
                        $cell_font_size = $fnt_size + 2; 
                    } else {
                        $cell_font_size = $fnt_size;
                    }
                }
                $cell_leading    = find_value($cell_leading, 'leading', 
                                              'leading', -1, $GLOBALS);
                if ($cell_leading <= 0) {
                    $cell_leading = $cell_font_size * $leading_ratio;
                }
                $cell_height     = find_value($cell_height, 
                                              'min_rh', '', 0, $GLOBALS);
                $cell_pad_top    = find_value($cell_pad_top, 'padding_top', 
                                              'padding', $padding_default, 
                                              $GLOBALS);
                $cell_pad_right  = find_value($cell_pad_right, 'padding_right', 
                                              'padding', $padding_default, 
                                              $GLOBALS);
                $cell_pad_bot    = find_value($cell_pad_bot, 'padding_bottom', 
                                              'padding', $padding_default, 
                                              $GLOBALS);
                $cell_pad_left   = find_value($cell_pad_left, 'padding_left', 
                                              'padding', $padding_default, 
                                              $GLOBALS);
                $cell_max_word_len = find_value($cell_max_word_len, 
                                                'max_word_len', '', 
                                                $max_word_len, $GLOBALS);
                $cell_min_w        = find_value($cell_min_w, 'min_w', 
                                                '', undef, $GLOBALS);
                $cell_max_w        = find_value($cell_max_w, 'max_w', 
                                                '', undef, $GLOBALS);
                if (defined $cell_max_w && defined $cell_min_w) {
                    $cell_max_w = max($cell_max_w, $cell_min_w);
                }
                $cell_underline  = find_value($cell_underline, 
                                              'underline', '', $underline, 
                                              $GLOBALS);
                $cell_def_text   = find_value($cell_def_text, 'default_text', 
                                              '', $default_text, $GLOBALS);
                $cell_justify    = find_value($cell_justify, 'justify', 
                                              'justify', 'left', $GLOBALS);

                # cell bg may still be undef after this, fg must be defined
                if ($is_header_row) {
                    $cell_bg_color   = find_value($cell_bg_color, 'bg_color', 
                                            '', $h_bg_color_default, 
                                            $GLOBALS);
                    $cell_fg_color   = find_value($cell_fg_color, 'fg_color',
                                            '', $h_fg_color_default, 
                                            $GLOBALS);
                    # don't use even/odd colors in header
                } else {
                    $cell_bg_color   = find_value($cell_bg_color, 'bg_color', 
                                            '', undef, $GLOBALS);
                    $cell_fg_color   = find_value($cell_fg_color, 'fg_color',
                                            '', undef, $GLOBALS);
                    $cell_bg_color_even = find_value($cell_bg_color_even, 
                                            'bg_color_even', '', undef, $GLOBALS);
                    $cell_bg_color_odd = find_value($cell_bg_color_odd, 
                                            'bg_color_odd', '', undef, $GLOBALS);
                    $cell_fg_color_even = find_value($cell_fg_color_even, 
                                            'fg_color_even', '', undef, $GLOBALS);
                    $cell_fg_color_odd = find_value($cell_fg_color_odd, 
                                            'fg_color_odd', '', undef, $GLOBALS);
                }
                $cell_h_rule_w = find_value($cell_h_rule_w, 'h_rule_w',
                                            'rule_w', $h_border_w, $GLOBALS);
                $cell_v_rule_w = find_value($cell_v_rule_w, 'v_rule_w',
                                            'rule_w', $v_border_w, $GLOBALS);
                $cell_h_rule_c = find_value($cell_h_rule_c, 'h_rule_c',
                                            'rule_c', $border_c, $GLOBALS);
                $cell_v_rule_c = find_value($cell_v_rule_c, 'v_rule_c',
                                            'rule_c', $border_c, $GLOBALS);

                # Choose colors for this row. may still be 'undef' after this!
                # cell, column, row, global color settings always override
                #   whatever _even/odd sets
                $bg_color = $cell_bg_color;
                $fg_color = $cell_fg_color;
                if ($oddeven_default) {  # new method with consistent odd/even
                    if (!defined $bg_color) {
                        $bg_color = $row_is_odd ? $cell_bg_color_odd : $cell_bg_color_even;
                    }
                    if (!defined $fg_color) {
                        $fg_color = $row_is_odd ? $cell_fg_color_odd : $cell_fg_color_even;
                    }
                    # don't toggle odd/even yet, wait til end of row
                } else {  # old method with inconsistent odd/even
                    if (!defined $bg_color) {
                        $bg_color = $row_idx % 2 ? $cell_bg_color_even : $cell_bg_color_odd;
                    }
                    if (!defined $fg_color) {
                        $fg_color = $row_idx % 2 ? $cell_fg_color_even : $cell_fg_color_odd;
                    }
                }
                # force fg_color to have a value, but bg_color may remain undef
                $fg_color ||= $fg_color_default; 

               ## check if so much padding that baseline forced below cell 
               ## bottom, possibly resulting in infinite loop!
               #if ($cell_pad_top + $cell_pad_bot + $cell_leading > $cell_height) {
               #    my $reduce = $cell_pad_top + $cell_pad_bot - 
               #                  ($cell_height - $cell_leading);
               #    carp "Warning! Vertical padding reduced by $reduce to fit cell[$row_idx][$col_idx]";
               #    $cell_pad_top -= $reduce/2;
               #    $cell_pad_bot -= $reduce/2;
               #}

                # Define the font y base position for this line.
                $text_start_y = $cur_y - $cell_pad_top - $cell_font_size;

                # VARIOUS WIDTHS:
                #  $col_min_w->[$col_idx] the minimum needed for a column,
                #    based on requested min_w and maximum word size (longest
                #    word just fits). this is the running minimum, not the
                #    per-row value.
                #  $col_max_w->[$col_idx] the maximum needed for a column,
                #    based on requested max_w and total length of text, as if
                #    the longest entire cell is to be written out as one line.
                #    this is the running maximum, not the per-row value.
                #    
                #  $calc_column_widths->[$col_idx] = calculated column widths
                #    (at least the minimum requested and maximum word size)
                #    apportioned across the full requested width. these are the
                #    column widths you'll actually see drawn (before colspan).
                #  $actual_column_widths[$row_idx][$col_idx] = calculated width
                #    for this cell, increased by colspan (cols to right).
                #
                #  $data_row_widths->[$col_idx] = cell content width list for 
                #    a row, first element of row_col_widths. could vary down a
                #    column due to differing length of content.
                #  $row_col_widths->[$row_idx] = list of max widths per row, 
                #    which can vary down a column due to differing length of 
                #    content.
                #  $column_widths->[$col_idx] = list of maximum cell widths 
                #    across this row, used to load up $row_col_widths and
                #    $h_row_widths (header).

                # Initialize cell font object
                $txt->font( $cell_font, $cell_font_size );
                $txt->fillcolor($fg_color) if $ink;

                # make sure cell's text is never undef
                $data_row->[$col_idx] //= $cell_def_text;

                # Handle colspan
                my $c_cell_props = $is_header_row ?
                    $cell_props->[0][$col_idx] :
                    $cell_props->[$row_idx][$col_idx];
                my $this_cell_width = $calc_column_widths->[$col_idx];
                if ($c_cell_props && $c_cell_props->{'colspan'} && $c_cell_props->{'colspan'} > 1) {
                    my $colspan = $c_cell_props->{'colspan'};
                    for my $offset (1 .. $colspan - 1) {
                        $this_cell_width += $calc_column_widths->[$col_idx + $offset] 
                            if $calc_column_widths->[$col_idx + $offset];
                        if ($is_header_row) {
                            $colspanned{'0_'.($col_idx + $offset)} = 1;
                        } else {
                            $colspanned{$row_idx.'_'.($col_idx + $offset)} = 1;
                        }
                    }
                }
                $this_cell_width = max($this_cell_width, $min_col_width);
                $actual_column_widths[$row_idx][$col_idx] = $this_cell_width;

                my %text_options;
                if ($cell_underline) {
                    $text_options{'-underline'} = $cell_underline;
                    $text_options{'-strokecolor'} = $fg_color;
                }
                # If the content is wider than the specified width, 
                # we need to add the text as a text block
                # Otherwise just use the $page->text() method
                my $content = $data_row->[$col_idx];
                $content = $cell_def_text if (ref($content) eq '' && 
                                              $content eq '');
                # empty content? doesn't seem to do any harm
                if ( ref($content) eq 'ARRAY') {
                    # it's a markup cell
                    $cell_markup = $content->[0];
                    # if it's "leftover" content, markup is 'pre'
                     
                    my ($rc, $next_y, $remainder);
                    # upper left corner, width, and max height of this column?
                    my $ULx = $cur_x + $cell_pad_left;
                    my $ULy = $cur_y - $cell_pad_top;
                    my $width = $actual_column_widths[$row_idx][$col_idx] - 
                                $cell_pad_right - $cell_pad_left;
                    my $max_h = $cur_y - $bottom_margin - 
                                $cell_pad_top - $cell_pad_bot;
                    ($rc,  $next_y, $remainder) =
                        $txt->column($page, $txt, $gfx, $cell_markup,
                                     $content->[1],
                                     'rect'=>[$ULx, $ULy, $width, $max_h],
                                     'font_size'=>$cell_font_size,
                                     %{$content->[2]});
                    if ($rc) {
                        # splitting cell
                        $actual_row_height = max($actual_row_height,
                            $cur_y - $bottom_margin);
                    } else {
                        # got entire content onto this page
                        $actual_row_height = max($actual_row_height,
                           $cur_y - $next_y + $cell_pad_bot +
                           ($cell_leading - $cell_font_size)*1.0);
                    }
                    # 1.0 multiplier is a good-looking fudge factor to add a 
                    # little space between bottom of text and bottom of cell

                    # at this point, actual_row_height is the used
                    # height of this row, for purposes of background cell
                    # color and left rule drawing. current_min_rh is left as
                    # the height of one line + padding.

                    if ( $rc ) {
                        $leftovers->[$col_idx] = [ 'pre', $remainder, 
                            $content->[2] ];
                        $do_leftovers = 1;
                    }

                } elsif ( $content !~ m/(.\n.)/ and
                          $data_row_widths->[$col_idx] and
                          $data_row_widths->[$col_idx] <= 
                              $actual_column_widths[$row_idx][$col_idx] ) {
                    # no embedded newlines (no multiple lines)
                    # and the content width is <= calculated column width?
                    # content will fit on one line, use text_* calls
                    if ($ink) {
                        if      ($cell_justify eq 'right') {
                            # right justified before right padding
                            $txt->translate($cur_x + $actual_column_widths[$row_idx][$col_idx] - $cell_pad_right, $text_start_y);
                            $txt->text_right($content, %text_options);
                        } elsif ($cell_justify eq 'center') {
                            # center text within the margins (padding)
                            $txt->translate($cur_x + $cell_pad_left + ($actual_column_widths[$row_idx][$col_idx] - $cell_pad_left - $cell_pad_right)/2, $text_start_y);
                            $txt->text_center($content, %text_options);
                        } else { 
                            # left justified after left padding
                            # (text_left alias for text, in PDF::Builder only)
                            $txt->translate($cur_x + $cell_pad_left, $text_start_y);
                            $txt->text($content, %text_options);
                        }
                    }
                    
                } else {
                    my ($width_of_last_line, $ypos_of_last_line, 
                          $left_over_text) 
                      = $self->text_block(
                          $txt,
                          $content,
                          $row_idx, $col_idx,
                          # mandatory args
                          'x'         => $cur_x + $cell_pad_left,
                          'y'         => $text_start_y,
                          'w'         => $actual_column_widths[$row_idx][$col_idx] - 
                                          $cell_pad_left - $cell_pad_right,
                          'h'         => $cur_y - $bot_margin - 
                                          $cell_pad_top - $cell_pad_bot,
                          # non-mandatory args
                          'font_size' => $cell_font_size,
                          'leading'   => $cell_leading,
                          'align'     => $cell_justify,
                          'text_opt'  => \%text_options,
                    );
                    # Desi - Removed $leading because of 
                    #        fixed incorrect ypos bug in text_block
                    $actual_row_height = max($actual_row_height,
                               $cur_y - $ypos_of_last_line + $cell_pad_bot +
                               ($cell_leading - $cell_font_size)*2.5);
                    # 2.5 multiplier is a good-looking fudge factor to add a 
                    # little space between bottom of text and bottom of cell

                    # at this point, actual_row_height is the used
                    # height of this row, for purposes of background cell
                    # color and left rule drawing. current_min_rh is left as
                    # the height of one line + padding.

                    if ( $left_over_text ) {
                        $leftovers->[$col_idx] = $left_over_text;
                        $do_leftovers = 1;
                    }
                }

                # Hook to pass coordinates back - http://www.perlmonks.org/?node_id=754777
                if (ref $arg{'cell_render_hook'} eq 'CODE') {
                   $arg{'cell_render_hook'}->(
                                            $page,
                                            $first_row,
                                            $row_idx,
                                            $col_idx,
                                            $cur_x,
                                            $cur_y-$actual_row_height,
                                            $actual_column_widths[$row_idx][$col_idx],
                                            $actual_row_height
                                           );
                }

                $cur_x += $actual_column_widths[$row_idx][$col_idx];
                # otherwise lose track of column-related settings
                $save_bg_color[$col_idx] = $bg_color;
                $save_fg_color[$col_idx] = $fg_color;
                $save_v_rule_w[$col_idx] = $cell_v_rule_w;
                $save_h_rule_w[$col_idx] = $cell_h_rule_w;
                $save_v_rule_c[$col_idx] = $cell_v_rule_c;
                $save_h_rule_c[$col_idx] = $cell_h_rule_c;
            } # done looping through columns for this row
            if ( $do_leftovers ) {
                # leftover text in row to output later as new-ish row?
                unshift @$data, $leftovers;
                unshift @$row_col_widths, $data_row_widths;
                unshift @$rows_height, $current_min_rh;
                # if push actual_row_height back onto rows_height, it will be
                # far too much in some cases, resulting in excess blank space at bottom.
            }
            if ($oddeven_default) {  # new method with consistent odd/even
                if ( !($first_row and $do_headers) ) {
                    # only toggle if not a header
                    $row_is_odd = ! $row_is_odd;
                }
            }

            # Draw cell bgcolor
            # This has to be done separately from the text loop
            #  because we do not know the final height of the cell until 
            #  all text has been drawn. Nevertheless, it ($gfx_bg) will
            #  still be rendered before text ($txt).
            $cur_x = $xbase;
            for (my $col_idx = 0; 
                 $col_idx < scalar(@$data_row); 
                 $col_idx++) {
                # restore cell_bg_color, etc.
                $bg_color = $save_bg_color[$col_idx];
                $fg_color = $save_fg_color[$col_idx];
                $cell_v_rule_w = $save_v_rule_w[$col_idx];
                $cell_h_rule_w = $save_h_rule_w[$col_idx];
                $cell_v_rule_c = $save_v_rule_c[$col_idx];
                $cell_h_rule_c = $save_h_rule_c[$col_idx];

        # TBD rowspan!
                if ($ink) {
                    if (defined $bg_color && 
                        $bg_color ne 'transparent' && $bg_color ne 'trans' &&
                        !$colspanned{$row_idx.'_'.$col_idx}) {
                        $gfx_bg->rect( $cur_x, $cur_y-$actual_row_height,  
                                       $actual_column_widths[$row_idx][$col_idx], $actual_row_height);
                        $gfx_bg->fillcolor($bg_color);
                        $gfx_bg->fill();
                    }

                    # draw left vertical border of this cell unless leftmost
                    if ($gfx && $cell_v_rule_w && $col_idx &&
                        !$colspanned{$row_idx.'_'.$col_idx}) {
                        $gfx->linewidth($cell_v_rule_w);
                        $gfx->strokecolor($cell_v_rule_c);
                        $gfx->move($cur_x, $cur_y-$actual_row_height);
                        $gfx->vline( $cur_y - ($row_idx? 0: $h_border_w/2));
                        $gfx->stroke(); # don't confuse different widths and colors
                    }

                    # draw bottom horizontal rule of this cell unless bottom
                    # of page (no more data or not room for at least one line).
                    # TBD fix up when implement rowspan
                    if ($gfx && $cell_h_rule_w && scalar(@{$data}) && 
                        $cur_y-$actual_row_height-$current_min_rh > $bot_margin ) {
                        $gfx->linewidth($cell_h_rule_w);
                        $gfx->strokecolor($cell_h_rule_c);
                        $gfx->move($cur_x, $cur_y-$actual_row_height);
                        $gfx->hline( $cur_x + $actual_column_widths[$row_idx][$col_idx] );
                        $gfx->stroke(); # don't confuse different widths and colors
                    }
                }

                $cur_x += $calc_column_widths->[$col_idx];
            } # End of for (my $col_idx....

            $cur_y -= $actual_row_height;
            if (!$ink) {
                if ($first_row && $do_headers) {
                    # this was a header row
                    $vsizes[1] = $actual_row_height;
                } else {
                    # this was a non-header row
                    push @vsizes, $actual_row_height;
                }
                # if implement footer, it will go in [2]
            }

            if ($do_leftovers) {
                # a row has been split across pages. undo bg toggle
                $row_is_odd = !$row_is_odd;
                $next_top_border = 2; # dashed line
            } else {
                $row_idx++;
                $next_top_border = 1; # solid line
            }
            $first_row = 0;
        } # End of Row_Loop for this page, and possibly whole table

        # draw bottom border on this page. first, is this very last row?
        # The line overlays and hides any odd business with vertical rules
        # in the last row
        if (!scalar(@{$data})) { $next_top_border = 0; }
        if ($ink) {
            if ($gfx && $h_border_w) {
                if      ($next_top_border == 0) {
                    # last bottom border, use specified border
                    $gfx->linewidth($h_border_w);
                } elsif ($next_top_border == 1) {
                    # solid thin line at start of a row
                    $gfx->linewidth($border_w_default);
                } else {  # == 2
                    # dashed thin line at continuation in middle of row
                    $gfx->linewidth($border_w_default);
                    $gfx->linedash($dashed_rule_default);
                }
                # leave next_top_border for next page top of continued table
                $gfx->strokecolor($border_c);
                $gfx->move( $xbase-$v_border_w/2 , $cur_y );
                $gfx->hline($xbase + $width + $v_border_w/2);
                $gfx->stroke();
                $gfx->linedash();
            }

            if ($gfx) {
                if ($v_border_w) {
                    # Draw left and right table borders
                    # These overlay and hide any odd business with horizontal 
                    # rules at the left or right edge
                    $gfx->linewidth($v_border_w);
                    $gfx->move(  $xbase,          $table_top_y);
                    $gfx->vline( $cur_y );
                    $gfx->move(  $xbase + $width, $table_top_y);
                    $gfx->vline( $cur_y );
                }

                # draw all the unrendered lines
                $gfx->stroke();
            }
        }
        $pg_cnt++;  # on a spillover page
    } # End of while (scalar(@{$data}))   next row, adding new page if necessary

    if ($ink) {
        return ($page, --$pg_cnt, $cur_y);
    } else {
        # calculate overall table height as sum of 1..$#vsizes
        for (my $i = 1; $i < @vsizes; $i++) {
            $vsizes[0] += $vsizes[$i];
        }
        # might need to account for really thick horizontal border rules
        return @vsizes;
    }
} # end of table()

############################################################
# find a value that might be set in a default or in a global
# or column/row/cell specific parameter. fixed order of search
# is cell/header properties, column properties, row properties,
# fallback sequences (e.g., padding_left inherits from padding),
# global default
############################################################

sub find_value {
    my ($cell_val, $name, $fallback, $default, $GLOBALS) = @_;
    # $fallback can be '' (will be skipped)

    my ($cell_props, $col_props, $row_props, $row_idx, $col_idx, $argref) = 
        @$GLOBALS;
    # $row_idx should be 0 for a header entry
    my %arg = %$argref;
    # $default should never be undefined, except for specific cases!
    if (!defined $default &&
        ($name ne 'underline' && 
         $name ne 'bg_color' && $name ne 'fg_color' && 
         $name ne 'bg_color_even' && $name ne 'bg_color_odd' &&
         $name ne 'fg_color_even' && $name ne 'fg_color_odd' &&
         $name ne 'min_w' && $name ne 'max_w') ) {
        carp "Error! find_value() default value undefined for '$name'\n";
    }

    # upon entry, $cell_val is usually either undefined (data row) or 
    # header property setting (in which case, already set and we're done here)
    $cell_val = $cell_props->[$row_idx][$col_idx]->{$name} if 
        !defined $cell_val;
    $cell_val = $cell_props->[$row_idx][$col_idx]->{$fallback} if 
        !defined $cell_val && $fallback ne '';
    $cell_val = $col_props->[$col_idx]->{$name} if 
        !defined $cell_val;
    $cell_val = $col_props->[$col_idx]->{$fallback} if 
        !defined $cell_val && $fallback ne '';
    $cell_val = $row_props->[$row_idx]->{$name} if 
        !defined $cell_val;
    $cell_val = $row_props->[$row_idx]->{$fallback} if 
        !defined $cell_val && $fallback ne '';
    $cell_val = $arg{$name} if 
        !defined $cell_val;
    $cell_val = $arg{$fallback} if 
        !defined $cell_val && $fallback ne '';

    # final court of appeal is the global default (usually defined)
    if (!defined $cell_val) {
        $cell_val = $default;
    }

    return $cell_val;
} # end of find_value()

############################################################
# text_block - utility method to build multi-paragraph blocks of text
#
# Parameters:
#   $text_object  the TEXT object used to output to the PDF
#   $text         the text to be formatted
#   %arg          settings to control the formatting and
#                  output.
#       mandatory: x, y, w, h (block position and dimensions)
#       defaults are provided for:
#         font_size (global $font_size_default)
#         leading   (font_size * global $leading_ratio)
#       no defaults for:
#         text_opt  (such as underline flag and color)
#         parspace  (extra vertical space before a paragraph)
#         hang      (text for ?)
#         indent    (indentation amount)
#         fpindent  (first paragraph indent amount)
#         flindent  (first line indent amount)
#         align     (justification left|center|right|fulljustify|justify)
#
# $text comes in as one string, possibly with \n embedded.
# split at \n to form 2 or more @paragraphs. each @paragraph
# is a @paragraphs element split on ' ' (list of words to
# fill the available width). one word at a time is moved
# from @paragraph to @line, until the width of the joined
# @line (with ' ' between words) can't be any larger.
# TBD: deal with multiple spaces between words
############################################################

sub text_block {
    my $self        = shift;
    my $text_object = shift;
    my $text        = shift;    # The text to be displayed
    my $row_idx     = shift;    # cell row,col for debug
    my $col_idx     = shift;
    my %arg         = @_;       # Additional Arguments

    my  ( $align, $xpos, $ypos, $xbase, $ybase, $line_width, $wordspace, $endw , $width, $height) =
        ( undef , undef, undef, undef , undef , undef      , undef     , undef , undef , undef  );
    my @line        = ();       # Temp data array with words on one line
    my %width       = ();       # The width of every unique word in the given text
    my %text_options = %{ $arg{'text_opt'} };

    # Try to provide backward compatibility. "-" starting key name is optional
    foreach my $key (keys %arg) {
        my $newkey = $key;
        if ($newkey =~ s#^-##) {
            $arg{$newkey} = $arg{$key};
            delete $arg{$key};
        }
    }
    #####

    #---
    # Let's check mandatory parameters with no default values
    #---
    $xbase  = $arg{'x'} || -1;
    $ybase  = $arg{'y'} || -1;
    $width  = $arg{'w'} || -1;
    $height = $arg{'h'} || -1;
    unless ( $xbase  > 0 ) {
        carp "Error: Left Edge of Block is NOT defined!\n";
        return (0, $ybase, '');
    }
    unless ( $ybase  > 0 ) {
        carp "Error: Base Line of Block is NOT defined!\n";
        return (0, $ybase, '');
    }
    unless ( $width  > 0 ) {
        carp "Error: Width of Block is NOT defined!\n";
        return (0, $ybase, '');
    }
    unless ( $height > 0 ) {
        carp "Error: Height of Block is NOT defined!\n";
        return (0, $ybase, '');
    }

    # Check if any text to display. If called from table(), should have
    # default text by the time of the call, so this is really as a failsafe
    # for standalone text_block() calls. Note that '' won't work!
    unless ( defined( $text) and length($text) > 0 ) {
   #    carp "Warning: No input text found. Use dummy '-'.\n";
   #    $text = $empty_cell_text;
$text = ' ';
    }

    # Strip any <CR> and Split the text into paragraphs
    # if you're on a platform that uses \r to end a line (old Macs?)...
    # we're in text_block() only if long line or \n's seen
    # @paragraphs is list of paragraphs (long lines)
    # @paragraph is list of words within present paragraph (long line)
    $text =~ s/\r//g;
    my @paragraphs  = split(/\n/, $text);

    # Width between lines (leading) in points
    my $font_size = $arg{'font_size'} || $font_size_default;
    my $line_space = defined $arg{'leading'} && $arg{'leading'} > 0 ? $arg{'leading'} : undef;
    $line_space ||= $font_size * $leading_ratio;
    # leading must be at least font size
    $line_space = $font_size * $leading_ratio if $font_size > $line_space;

    # Calculate width of all words
    my $space_width = $text_object->advancewidth("\x20");
    my %word_width;
    my @text_words = split(/\s+/, $text);
    foreach (@text_words) {
        next if exists $word_width{$_};
        $word_width{$_} = $text_object->advancewidth($_);
    }

    # get word list for first paragraph
    my @paragraph = split(' ', shift(@paragraphs));
    my $first_line = 1; # first line of THIS paragraph
    my $paragraph_number = 1;

    # Little Init
    $xpos = $xbase;
    $ypos = $ybase;
    $ypos = $ybase + $line_space;
    # bottom_border doesn't need to consider pad_bot, as we're only considering
    # the space actually available within the cell, already reduced by padding.
    my $bottom_border = $ypos - $height;

    # While we can add another line. No handling of widows and orphans.
    while ( $ypos >= $bottom_border + $line_space ) {
        # Is there any text to render ?
        unless (@paragraph) {
            # Finish if nothing left of all the paragraphs in text
            last unless scalar @paragraphs; # another paragraph to process?
            # Else take one paragraph (long line) from the text
            @paragraph = split(' ', shift( @paragraphs ) );
            $paragraph_number++;

            # extra space between paragraphs? only if a previous paragraph
            $ypos -= $arg{'parspace'} if $arg{'parspace'} and 
                                         $paragraph_number > 1;
            last unless $ypos >= $bottom_border;
        }
        $ypos -= $line_space;
        $xpos = $xbase;

        # While there's room on the line, add another word
        @line = ();
        $line_width = 0;
        # TBD what exactly is hang supposed to do, interaction with
        # indent, flindent, fpindent AND effect on min cell width
        if      ( $first_line && exists $arg{'hang'} ) {
            # fixed text to output first, for first line of a paragraph
            # TBD Note that hang text is not yet checked for min_col_width or 
            #  max_word_len, and other indents could make line too wide for col!
            my $hang_width = $text_object->advancewidth($arg{'hang'});

            $text_object->translate( $xpos, $ypos ) if $ink;
            $text_object->text( $arg{'hang'} ) if $ink;

            $xpos         += $hang_width;
            $line_width   += $hang_width;
            $arg{'indent'} += $hang_width if $paragraph_number == 1;
        } elsif ( $first_line && exists $arg{'flindent'} &&
                  $arg{'flindent'} > 0 ) {
            # amount to indent on first line of a paragraph
            $xpos += $arg{'flindent'};
            $line_width += $arg{'flindent'};
        } elsif ( $paragraph_number == 1 && exists $arg{'fpindent'} &&
                  $arg{'fpindent'} > 0 ) {
            # amount to indent first paragraph's first line TBD ??
            $xpos += $arg{'fpindent'};
            $line_width += $arg{'fpindent'};
        } elsif ( exists $arg{'indent'} &&
                  $arg{'indent'} > 0 ) {
            # amount to indent first line of following paragraphs
            $xpos += $arg{'indent'};
            $line_width += $arg{'indent'};
        }

        # Let's take from paragraph as many words as we can put
        # into $width - $indent. repeatedly test with "just one more" word
        # from paragraph list, until overflow. 
        # TBD might be more efficient (as originally intended?) to build 
        # library of word widths and add them together until "too big", 
        # back off. 
        # TBD don't forget to properly handle runs of more than one space.
        while ( @paragraph ) { 
            if ( !@line ) {
                # first time through, @line is empty
                # first word in paragraph SHOULD fit!!
                # TBD: what if $line_width > 0??? due to indent, etc.?
                # add 0.01 as safety
                if ( $text_object->advancewidth( $paragraph[0] ) +
                     $line_width <= $width+0.01 ) {
                    push(@line, shift(@paragraph));
                    next if @paragraph;
                } else {
                    # this should never happen, but just in case, to
                    # prevent an infinite loop...
                    die("!!! Error !!! first word in paragraph for row $row_idx, col $col_idx '$paragraph[0]' doesn't fit into empty line!");
                }
            } else {
                # @line has text in it already
                if ( $text_object->advancewidth( join(" ", @line)." " . $paragraph[0] ) +
                     $line_width <= $width ) {
                    push(@line, shift(@paragraph));
                    next if @paragraph;
                }
            }
            last;
        }
        $line_width += $text_object->advancewidth(join(' ', @line));

        # calculate the space width (width to use for a space)
        $align = $arg{'align'} || 'left';
        if ( $align eq 'fulljustify' or
            ($align eq 'justify' and @paragraph)) {
            @line = split(//,$line[0]) if scalar(@line) == 1;
            if (scalar(@line) > 1) {
                $wordspace = ($width - $line_width) / (scalar(@line) - 1);
            } else {
                $wordspace = 0; # effectively left-aligned for single word
            }
            $align = 'justify';
        } else {
            # not adding extra spacing between words, just real space
            $align = 'left' if $align eq 'justify';
            $wordspace = $space_width;
        }

        $line_width += $wordspace * (scalar(@line) - 1);

        if ( $align eq 'justify') {
            foreach my $word (@line) {
                $text_object->translate( $xpos, $ypos ) if $ink;
                $text_object->text( $word ) if $ink;
                $xpos += ($word_width{$word} + $wordspace) if (@line);
            }
            $endw = $width;
        } else {
            # calculate the left hand position of the line
#           if      ( $align eq 'right' ) {
#               $xpos += $width - $line_width;
#           } elsif ( $align eq 'center' ) {
#               $xpos += ( $width - $line_width ) / 2;
#           }

            if ($ink) {
                # render the line. TBD This may not work right with indents!
                if      ($align eq 'right') {
                    $text_object->translate( $xpos+$width, $ypos );
                    $endw = $text_object->text_right(join(' ', @line), %text_options);
                } elsif ($align eq 'center') {
                    $text_object->translate( $xpos + $width/2, $ypos );
                    $endw = $text_object->text_center(join(' ', @line), %text_options);
                } else {
                    $text_object->translate( $xpos, $ypos );
                    $endw = $text_object->text(join(' ', @line), %text_options);
                }
            }
        }
        $first_line = 0;
    } # End of while (fitting within vertical space)

    # any leftovers of current paragraph? will return as first new paragraph
    unshift(@paragraphs, join(' ',@paragraph)) if scalar(@paragraph);

    return ($endw, $ypos, join("\n", @paragraphs))
}  # End of text_block()

1;

__END__

=pod

For documentation, see Table/Table.pod. A copy of table.html is included in
the library for your convenience, or you can use a tool such as pod2html to
create the HTML.
