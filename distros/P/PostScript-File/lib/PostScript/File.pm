#---------------------------------------------------------------------
package PostScript::File;
#
# Copyright 2002, 2003 Christopher P Willmot.
# Copyright 2011 Christopher J. Madsen
#
# Author: Chris Willmot         <chris AT willmot.co.uk>
#         Christopher J. Madsen <perl AT cjmweb.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Class for creating Adobe PostScript files
#---------------------------------------------------------------------

use 5.008;
our $VERSION = '2.23';          ## no critic
# This file is part of PostScript-File 2.23 (October 10, 2015)

use strict;
use warnings;
use Carp 'croak';
use File::Spec ();
use Scalar::Util 'openhandle';
use Exporter 5.57 'import';

our %EXPORT_TAGS = (metrics_methods => [qw(
  encode_text decode_text convert_hyphens set_auto_hyphen
)]);

our @EXPORT_OK = (qw(check_tilde check_file incpage_label incpage_roman
                    array_as_string pstr quote_text str),
                  # These are only for PostScript::File::Metrics:
                  @{ $EXPORT_TAGS{metrics_methods} });

# Prototypes for functions only
 ## no critic (ProhibitSubroutinePrototypes)
 sub incpage_label ($);
 sub incpage_roman ($);
 sub check_tilde ($);
 sub check_file ($;$$);
 ## use critic

# global constants
our %encoding_def; # defined near _set_reencode

our ($t1ascii, $ttftotype42);
BEGIN {
  # Program to convert .pfb fonts to .pfa on STDOUT:
  $t1ascii     = 't1ascii'     unless defined $t1ascii;
  # Program to convert .ttf fonts to .pfa on STDOUT:
  $ttftotype42 = 'ttftotype42' unless defined $ttftotype42;
}


# define page sizes here (a4, letter, etc)
# should be Properly Cased
our %size = (
    a0                    => '2384 3370',
    a1                    => '1684 2384',
    a2                    => '1191 1684',
    a3                    => "841.88976 1190.5512",
    a4                    => "595.27559 841.88976",
    a5                    => "420.94488 595.27559",
    a6                    => '297 420',
    a7                    => '210 297',
    a8                    => '148 210',
    a9                    => '105 148',

    b0                    => '2920 4127',
    b1                    => '2064 2920',
    b2                    => '1460 2064',
    b3                    => '1032 1460',
    b4                    => '729 1032',
    b5                    => '516 729',
    b6                    => '363 516',
    b7                    => '258 363',
    b8                    => '181 258',
    b9                    => '127 181 ',
    b10                   => '91 127',

    executive             => '522 756',
    folio                 => '595 935',
    'half-letter'         => '612 397',
    letter                => "612 792",
    'us-letter'           => '612 792',
    legal                 => '612 1008',
    'us-legal'            => '612 1008',
    tabloid               => '792 1224',
    'superb'              => '843 1227',
    ledger                => '1224 792',

    'comm #10 envelope'   => '297 684',
    'envelope-monarch'    => '280 542',
    'envelope-dl'         => '312 624',
    'envelope-c5'         => '461 648',

    'europostcard'        => '298 420',
);


# The 13 standard fonts that are available on all PS 1 implementations:
our @fonts = qw(
    Courier
    Courier-Bold
    Courier-BoldOblique
    Courier-Oblique
    Helvetica
    Helvetica-Bold
    Helvetica-BoldOblique
    Helvetica-Oblique
    Times-Roman
    Times-Bold
    Times-BoldItalic
    Times-Italic
    Symbol
);

# 5.008-compatible version of defined-or:
sub _def { for (@_) { return $_ if defined $_ } undef }

sub new {
    my ($class, @options) = @_;
    my $opt = {};
    if (@options == 1) {
        $opt = $options[0];
    } else {
        %$opt = @options;
    }

    ## Initialization
    my $o = {
        # PostScript DSC sections
        Comments    => "",  # must include leading '%%' and end with '\n'
        DocSupplied => "",
        Preview     => "",
        Defaults    => "",
        Fonts       => "",
        Resources   => "",
        Functions   => "",
        Setup       => "",
        PageSetup   => "",
        Pages       => [],  # indexed by $o->{p}, 0 based
        PageTrailer => "",
        Trailer     => "",

        # internal
        p           => 0,   # current page (0 based)
        pagecount   => 0,   # number of pages
        page        => [],  # array of labels, indexed by $o->{p}
        pagelandsc  => [],  # orientation of each page individually
        pageclip    => [],  # clip to pagebbox
        pagebbox    => [],  # array of bbox, indexed by $o->{p}
        bbox        => [],  # [ x0, y0, x1, y1 ]
        embed_fonts => [],  # fonts that have been embedded
        needed      => {},  # DocumentNeededResources

        vars        => {},  # permanent user variables
        pagevars    => {},  # user variables reset with each new page
    };
    bless $o, $class;

    ## Paper layout
    croak "PNG output is no longer supported.  Use PostScript::Convert instead"
        if $opt->{png};
    $o->{eps}      = !!$opt->{eps} + 0;
    $o->{file_ext} = $opt->{file_ext};
    $o->set_filename(@$opt{qw(file dir)});
    $o->set_paper( $opt->{paper} );
    $o->set_width( $opt->{width} );
    $o->set_height( $opt->{height} );
    $o->set_landscape( $opt->{landscape} );

    ## Debug options
    $o->{debug} = $opt->{debug};        # undefined is an option
    if ($o->{debug}) {
        $o->{db_active}   = _def($opt->{db_active},   1);
        $o->{db_bufsize}  = _def($opt->{db_bufsize},  256);
        $o->{db_font}     = _def($opt->{db_font},     "Courier");
        $o->{db_fontsize} = _def($opt->{db_fontsize}, 10);
        $o->{db_ytop}     = _def($opt->{db_ytop},     ($o->{bbox}[3] - $o->{db_fontsize} - 6));
        $o->{db_ybase}    = _def($opt->{db_ybase},    6);
        $o->{db_xpos}     = _def($opt->{db_xpos},     6);
        $o->{db_xtab}     = _def($opt->{db_xtab},     10);
        $o->{db_xgap}     = _def($opt->{db_xgap},     ($o->{bbox}[2] - $o->{bbox}[0] - $o->{db_xpos})/4);
        $o->{db_color}    = _def($opt->{db_color},    "0 setgray");
    }

    ## Bounding box
    my $x0 = $o->{bbox}[0] + _def($opt->{left},  28);
    my $y0 = $o->{bbox}[1] + _def($opt->{bottom},  28);
    my $x1 = $o->{bbox}[2] - _def($opt->{right},  28);
    my $y1 = $o->{bbox}[3] - _def($opt->{top},  28);
    $o->set_bounding_box( $x0, $y0, $x1, $y1 );
    $o->set_clipping( $opt->{clipping} );

    ## Other options
    $o->{title}      = $opt->{title};
    $o->{version}    = $opt->{version};
    $o->{langlevel}  = $opt->{langlevel};
    $o->{extensions} = $opt->{extensions};
    $o->{order}      = defined($opt->{order}) ? ucfirst lc $opt->{order} : undef;
    $o->set_page_label( $opt->{page} );
    $o->set_incpage_handler( $opt->{incpage_handler} );

    $o->{errx}        = _def($opt->{errx},         72);
    $o->{erry}        = _def($opt->{erry},         72);
    $o->{errmsg}      = _def($opt->{errmsg},       "ERROR:");
    $o->{errfont}     = _def($opt->{errfont},      "Courier-Bold");
    $o->{errsize}     = _def($opt->{errsize},      12);

    $o->{font_suffix} = _def($opt->{font_suffix},  "-iso");
    $o->{clipcmd}     = _def($opt->{clip_command}, "clip");
    $o->{errors}      = _def($opt->{errors},       1);
    $o->{headings}    = _def($opt->{headings},     0);
    $o->set_strip( $opt->{strip} );
    $o->_set_reencode( $opt->{reencode} );
    $o->set_auto_hyphen(_def($opt->{auto_hyphen}, 1));
    $o->need_resource(font => @{ $opt->{need_fonts} }) if $opt->{need_fonts};

    $o->newpage if _def($opt->{newpage}, 1);

    ## Finish
    return $o;
}


sub newpage {
    my ($o, $page) = @_;
    my $oldpage = $o->{page}[$o->{p}];
    # Don't use _def here, because we don't want to call
    # incpage_handler if the user supplied a page label:
    my $newpage = defined $page
        ? $page
        # If this is the very first page, don't increment the page number:
        : ($o->{pagecount}
           ? $o->{incpage}->($oldpage)
           : $oldpage);
    my $p = $o->{p} = $o->{pagecount}++;
    $o->{page}[$p] = $newpage;
    $o->{pagebbox}[$p] = [ @{$o->{bbox}} ];
    $o->{pageclip}[$p] = $o->{clipping};
    $o->{pagelandsc}[$p] = $o->{landscape};
    $o->{Pages}->[$p] = "";
    $o->{pagevars} = {};
}


sub _pre_pages
{
    my ($o, $landscape, $clipping, $filename) = @_;

    if (my $use_functions = $o->{use_functions}) {
      $use_functions->add_to_file($o);
    }

    my $docSupplied = $o->{DocSupplied};
    ## Thanks to Johan Vromans for the ISOLatin1Encoding.
    my $fonts = "";
    if ($o->{reencode}) {
        my $encoding = $o->{reencode};
        my $ext = $o->{font_suffix};
        $fonts = "% Handle font encoding:\n";
        $fonts .= $o->_here_doc(<<"END_FONTS");
            /STARTDIFFENC { mark } bind def
            /ENDDIFFENC {

            % /NewEnc BaseEnc STARTDIFFENC number or glyphname ... ENDDIFFENC -
                counttomark 2 add -1 roll 256 array copy
                /TempEncode exch def

                % pointer for sequential encodings
                /EncodePointer 0 def
                {
                    % Get the bottom object
                    counttomark -1 roll
                    % Is it a mark?
                    dup type dup /marktype eq {
                        % End of encoding
                        pop pop exit
                    } {
                        /nametype eq {
                        % Insert the name at EncodePointer

                        % and increment the pointer.
                        TempEncode EncodePointer 3 -1 roll put
                        /EncodePointer EncodePointer 1 add def
                        } {
                        % Set the EncodePointer to the number
                        /EncodePointer exch def
                        } ifelse
                    } ifelse
                } loop

                TempEncode def
            } bind def
            \n$encoding_def{$encoding}
            % Name: Re-encode Font
            % Description: Creates a new font using the named encoding.

            /REENCODEFONT { % /Newfont NewEncoding /Oldfont
                findfont dup length 4 add dict
                begin
                    { % forall
                        1 index /FID ne
                        2 index /UniqueID ne and
                        2 index /XUID ne and
                        { def } { pop pop } ifelse
                    } forall
                    /Encoding exch def
                    % defs for DPS
                    /BitmapWidths false def
                    /ExactSize 0 def
                    /InBetweenSize 0 def
                    /TransformedChar 0 def
                    currentdict
                end
                definefont pop
            } bind def
END_FONTS
        $fonts .= "\n% Reencode the fonts:\n";
        # If no fonts listed, assume the standard ones:
        $o->{needed}{font} ||= { map { $_ => 1 } @fonts };

        for my $font (sort(keys(%{ $o->{needed}{font} }),
                           @{ $o->{embed_fonts} })) {
            next if $font eq 'Symbol'; # doesn't use StandardEncoding
            $fonts .= "/${font}$ext $encoding /$font REENCODEFONT\n";
        }
        $fonts .= "% end font encoding\n";
    } # end if reencode

    # Prepare the PostScript file
    my $postscript = $o->{eps} ? "\%!PS-Adobe-3.0 EPSF-3.0\n" : "\%!PS-Adobe-3.0\n";
    if ($o->{eps}) {
        $postscript .= $o->_bbox_comment('', $o->{bbox});
    }
    if ($o->{headings}) {
        require Sys::Hostname;
        my $user = getlogin() || (getpwuid($<))[0] || "Unknown";
        my $hostname = Sys::Hostname::hostname();
        $postscript .= $o->_here_doc(<<END_TITLES);
        \%\%For: $user\@$hostname
        \%\%Creator: Perl module ${\( ref $o )} v$PostScript::File::VERSION
        \%\%CreationDate: ${\( scalar localtime )}
END_TITLES
        $postscript .= $o->_here_doc(<<END_PS_ONLY) if (not $o->{eps});
        \%\%DocumentMedia: $o->{paper} $o->{width} $o->{height} 80 ( ) ( )
END_PS_ONLY
    }

    my $landscapefn = "";
    $landscapefn .= $o->_here_doc(<<END_LANDSCAPE) if ($landscape);
                % Rotate page 90 degrees
                % _ => _
                /landscape {
                    $o->{width} 0 translate
                    90 rotate
                } bind def
END_LANDSCAPE

    my $clipfn = "";
    if ($clipping) {
      my $clipcmd = $o->{clipcmd};
      $clipcmd = "gsave 0 setgray 0.5 setlinewidth $clipcmd grestore newpath"
          if $clipcmd eq 'stroke';

      $clipfn .= $o->_here_doc(<<END_CLIPPING);
                % Draw box as clipping path
                % x0 y0 x1 y1 => _
                /cliptobox {
                    4 dict begin
                    /y1 exch def /x1 exch def /y0 exch def /x0 exch def
                    newpath
                    x0 y0 moveto x0 y1 lineto x1 y1 lineto x1 y0 lineto
                    closepath
                    $clipcmd
                    end
                } bind def
END_CLIPPING
    } # end if $clipping

    my $errorfn = "";
    if ($o->{errors}) {
      $o->need_resource(font => $o->{errfont});
      $errorfn .= $o->_here_doc(<<END_ERRORS);
        /errx $o->{errx} def
        /erry $o->{erry} def
        /errmsg ($o->{errmsg}) def
        /errfont /$o->{errfont} def
        /errsize $o->{errsize} def
        % Report fatal error on page
        % _ str => _
        /report_error {
            0 setgray
            errfont findfont errsize scalefont setfont
            errmsg errx erry moveto show
            80 string cvs errx erry errsize sub moveto show
            stop
        } bind def

        % PostScript errors printed on page
        % not called directly
        errordict begin
            /handleerror {
                \$error begin
                false binary
                0 setgray
                errfont findfont errsize scalefont setfont
                errx erry moveto
                errmsg show
                errx erry errsize sub moveto
                errorname 80 string cvs show
                stop
            } def
        end
END_ERRORS
    } # end if $o->{errors}

    my $debugfn = "";
    if ($o->{debug}) {
      $o->need_resource(font => $o->{db_font});
      $debugfn .= $o->_here_doc(<<END_DEBUG_ON);
        /debugdict 25 dict def
        debugdict begin

        /db_newcol {
            debugdict begin
                /db_ypos db_ytop def
                /db_xpos db_xpos db_xgap add def
            end
        } bind def
        % _ db_newcol => _

        /db_down {
            debugdict begin
                db_ypos db_ybase gt {
                    /db_ypos db_ypos db_ygap sub def
                }{
                    db_newcol
                } ifelse
            end
        } bind def
        % _ db_down => _

        /db_indent {
            debug_dict begin
                /db_xpos db_xpos db_xtab add def
            end
        } bind def
        % _ db_indent => _

        /db_unindent {
            debugdict begin
                /db_xpos db_xpos db_xtab sub def
            end
        } bind def
        % _ db_unindent => _

        /db_show {
            debugdict begin
                db_active 0 ne {
                    gsave
                    newpath
                    $o->{db_color}
                    /$o->{db_font} findfont $o->{db_fontsize} scalefont setfont
                    db_xpos db_ypos moveto
                    dup type
                    dup (arraytype) eq {
                        pop db_array
                    }{
                        dup (marktype) eq {
                            pop pop (--mark--) $o->{db_bufsize} string cvs show
                        }{
                            pop $o->{db_bufsize} string cvs show
                        } ifelse
                        db_down
                    } ifelse
                    stroke
                    grestore
                }{ pop } ifelse
            end
        } bind def
        % _ (msg) db_show => _

        /db_nshow {
            debugdict begin
                db_show
                /db_num exch def
                db_num count gt {
                    (Not enough on stack) db_show
                }{
                    db_num {
                        dup db_show
                        db_num 1 roll
                    } repeat
                    (----------) db_show
                } ifelse
            end
        } bind def
        % _ n (str) db_nshow => _

        /db_stack {
            count 0 gt {
                count
                $o->{debug} 2 ge {
                    1 sub
                } if
                (The stack holds...) db_nshow
            } {
                (Empty stack) db_show
            } ifelse
        } bind def
        % _ db_stack => _

        /db_one {
            debugdict begin
                db_temp cvs
                dup length exch
                db_buf exch db_bpos exch putinterval
                /db_bpos exch db_bpos add def
            end
        } bind def
        % _ any db_one => _

        /db_print {
            debugdict begin
                /db_temp $o->{db_bufsize} string def
                /db_buf $o->{db_bufsize} string def
                0 1 $o->{db_bufsize} sub 1 { db_buf exch 32 put } for
                /db_bpos 0 def
                {
                    db_one
                    ( ) db_one
                } forall
                db_buf db_show
            end
        } bind def
        % _ [array] db_print => _

        /db_array {
            mark ([) 2 index aload pop (]) ] db_print pop
        } bind def
        % _ [array] db_array => _

        /db_point {
            [ 1 index (\\() 5 index (,) 6 index (\\)) ] db_print
            pop
        } bind def
        % _ x y (str) db_point => _ x y

        /db_where {
            where {
                pop (found) db_show
            }{
                (not found) db_show
            } ifelse
        } bind def
        % _ var db_where => _

        /db_on {
            debugdict begin
            /db_active 1 def
            end
        } bind def
        % _ db_on => _

        /db_off {
            debugdict begin
            /db_active 0 def
            end
        } bind def
        % _ db_on => _

        /db_active $o->{db_active} def
        /db_ytop  $o->{db_ytop} def
        /db_ybase $o->{db_ybase} def
        /db_xpos  $o->{db_xpos} def
        /db_xtab  $o->{db_xtab} def
        /db_xgap  $o->{db_xgap} def
        /db_ygap  $o->{db_fontsize} def
        /db_ypos  $o->{db_ytop} def
        end
END_DEBUG_ON
    } # end if $o->{debug}

    $debugfn .= $o->_here_doc(<<END_DEBUG_OFF) if (defined($o->{debug}) and not $o->{debug});
        % Define out the db_ functions
        /debugdict 25 dict def
        debugdict begin
        /db_newcol { } bind def
        /db_down { } bind def
        /db_indent { } bind def
        /db_unindent { } bind def
        /db_show { pop } bind def
        /db_nshow { pop pop } bind def
        /db_stack { } bind def
        /db_print { pop } bind def
        /db_array { pop } bind def
        /db_point { pop pop pop } bind def
        end
END_DEBUG_OFF

    my $ver = sprintf('%g', $VERSION);
    my $supplied = "";
    if ($landscapefn or $clipfn or $errorfn or $debugfn) {
        $docSupplied .= "\%\%+ procset PostScript_File $ver 0\n";
        $supplied .= $o->_here_doc(<<END_DOC_SUPPLIED);
            \%\%BeginResource: procset PostScript_File $ver 0
            $landscapefn
            $clipfn
            $errorfn
            $debugfn
            \%\%EndResource
END_DOC_SUPPLIED
    }

    my $docNeeded = $o->_build_needed;

    my $title = $o->{title};
    $title = $o->quote_text($filename)
        if not defined $title and defined $filename;

    $postscript .= $o->{Comments} if ($o->{Comments});
    $postscript .= "\%\%Orientation: ${\( $o->{landscape} ? 'Landscape' : 'Portrait' )}\n";
    $postscript .= $docNeeded if $docNeeded;
    $postscript .= "\%\%DocumentSuppliedResources:\n$docSupplied" if $docSupplied;
    $postscript .= $o->encode_text("\%\%Title: $title\n") if defined $title;
    $postscript .= "\%\%Version: $o->{version}\n" if ($o->{version});
    $postscript .= "\%\%Pages: $o->{pagecount}\n" if ((not $o->{eps}) and ($o->{pagecount} > 1));
    $postscript .= "\%\%PageOrder: $o->{order}\n" if ((not $o->{eps}) and ($o->{order}));
    $postscript .= "\%\%Extensions: $o->{extensions}\n" if ($o->{extensions});
    $postscript .= "\%\%LanguageLevel: $o->{langlevel}\n" if ($o->{langlevel});
    $postscript .= "\%\%EndComments\n";

    $postscript .= $o->{Preview} if ($o->{Preview});

    $postscript .= $o->_here_doc(<<END_DEFAULTS) if ($o->{Defaults});
        \%\%BeginDefaults
        $o->{Defaults}
        \%\%EndDefaults
END_DEFAULTS

    $postscript .= $o->_here_doc(<<END_PROLOG);
        \%\%BeginProlog
        $supplied
        $o->{Functions}
        \%\%EndProlog
END_PROLOG

    my $setup = "$o->{Fonts}$fonts$o->{Resources}$o->{Setup}";
    $postscript .= "%%BeginSetup\n$setup%%EndSetup\n" if $setup;

    return $postscript;
}
# Internal method, used by output()

sub _build_needed
{
  my $o = shift;

  my $needed = $o->{needed};

  return unless %$needed;

  my $comment = "%%DocumentNeededResources:\n";

  foreach my $type (sort keys %$needed) {
    if ($type eq 'font') {
      # Remove any embedded fonts from the needed fonts:
      delete $needed->{$type}{$_} for @{ $o->{embed_fonts} };
    } # end if fonts

    next unless %{ $needed->{$type} };

    my $prefix = "%%+ $type";
    my $maxLen = 79 - length $prefix;
    my @list   = '';

    foreach my $resource (sort keys %{ $needed->{$type} }) {
      push @list, ''
          if length $list[-1]
             and length($resource) + length($list[-1]) >= $maxLen;
      $list[-1] .= " $resource";
    } # end foreach $resource

    $comment .= "$prefix$_\n" for @list;
  } # end foreach $type

  $comment;
} # end _build_needed

sub _post_pages
{
    my $o = shift;
    my $postscript = "";

    my $trailer = $o->{Trailer};
    $trailer .= "% Local\ Variables:\n% coding: " .
                $o->{encoding}->mime_name . "\n% End:\n"
        if $o->{encoding};

    $postscript .= "%%Trailer\n$trailer" if $trailer;
    $postscript .= "\%\%EOF\n";

    return $postscript;
}
# Internal method, used by output()

sub output {
    my ($o, $filename, $dir) = @_;
    my $fh = openhandle $filename;
    # Don't permanently change filename:
    local $o->{filename} = $o->{filename};
    $o->set_filename($filename, $dir) if @_ > 1 and not $fh;

    my ($debugbegin, $debugend) = ("", "");
    if (defined $o->{debug}) {
        $debugbegin = "debugdict begin\nuserdict begin";
        $debugend   = "end\nend";
        if ($o->{debug} >= 2) {
            $debugbegin = $o->_here_doc(<<END_DEBUG_BEGIN);
                debugdict begin
                    userdict begin
                        mark
                        (Start of page) db_show
END_DEBUG_BEGIN
            $debugend = $o->_here_doc(<<END_DEBUG_END);
                        (End of page) db_show
                        db_stack
                        cleartomark
                    end
                end
END_DEBUG_END
        }
    } else {
        $debugbegin = "userdict begin";
        $debugend   = "end";
    }

    if ($o->{eps}) {
        my @pages;
        my $p = 0;
        do {
            my $epsfile;
            if (defined $o->{filename}) {
                $epsfile = ($o->{pagecount} > 1) ? "$o->{filename}-$o->{page}[$p]"
                                           : "$o->{filename}";
                $epsfile .= defined($o->{file_ext}) ? $o->{file_ext}
                            : ($o->{Preview} ? ".epsi" : ".epsf");
            }
            my $postscript = "";
            my $page = $o->{page}->[$p];
            my @pbox = $o->get_page_bounding_box($page);
            $o->set_bounding_box(@pbox);
            $postscript .= $o->_pre_pages($o->{pagelandsc}[$p], $o->{pageclip}[$p], $epsfile);
            $postscript .= "landscape\n" if ($o->{pagelandsc}[$p]);
            $postscript .= "$pbox[0] $pbox[1] $pbox[2] $pbox[3] cliptobox\n" if ($o->{pageclip}[$p]);
            $postscript .= "$debugbegin\n";
            $postscript .= $o->{Pages}->[$p];
            $postscript .= "$debugend\n";
            $postscript .= $o->_post_pages();

            push @pages, $o->_print_file( $fh || $epsfile, $postscript );

            $p++;
        } while ($p < $o->{pagecount});
        return wantarray ? @pages : $pages[0];
    } else {
        my $landscape = $o->{landscape};
        foreach my $pl (@{$o->{pagelandsc}}) {
            $landscape |= $pl;
        }
        my $clipping = $o->{clipping};
        foreach my $cl (@{$o->{pageclip}}) {
            $clipping |= $cl;
        }
        my $psfile = $o->{filename};
        $psfile .= defined($o->{file_ext}) ? $o->{file_ext} : '.ps'
            if defined $psfile;
        my $postscript = $o->_pre_pages($landscape, $clipping, $psfile);
        for (my $p = 0; $p < $o->{pagecount}; $p++) {
            my $page = $o->{page}->[$p];
            my @pbox = $o->get_page_bounding_box($page);
            my ($landscape, $pagebb);
            if ($o->{pagelandsc}[$p]) {
                $landscape = "landscape";
                $pagebb = $o->_bbox_comment(Page => [ @pbox[1,0,3,2] ]);
            } else {
                $landscape = "";
                $pagebb = $o->_bbox_comment(Page => \@pbox);
            }
            my $cliptobox = $o->{pageclip}[$p] ? "$pbox[0] $pbox[1] $pbox[2] $pbox[3] cliptobox" : "";
            $postscript .= $o->_here_doc(<<END_PAGE_SETUP);
                \%\%Page: $o->{page}->[$p] ${\($p+1)}
                $pagebb\%\%BeginPageSetup
                    /pagelevel save def
                    $landscape
                    $cliptobox
                    $debugbegin
                    $o->{PageSetup}
                \%\%EndPageSetup
END_PAGE_SETUP
            $postscript .= $o->{Pages}->[$p];
            $postscript =~ s/\n?\z/\n/; # Ensure LF at end
            $postscript .= $o->_here_doc(<<END_PAGE_TRAILER);
                \%\%PageTrailer
                    $o->{PageTrailer}
                    $debugend
                    pagelevel restore
                    showpage
END_PAGE_TRAILER
        }
        $postscript .= $o->_post_pages();
        return $o->_print_file( $fh || $psfile, $postscript );
    }
}


sub as_string { shift->output(undef) }

sub testable_output
{
  my ($o, $verbatim) = @_;

  my $ps = $o->output(undef);

  unless ($verbatim) {
    # Remove PostScript::File generated code:
    $ps =~ s/^%%BeginResource: procset PostScript_File.*?^%%EndResource\n//msg;
    $ps =~ s/^%%\+ procset PostScript_File.*\n//mg;
    $ps =~ s/^% Handle font encoding:\n.*?^% end font encoding\n//ms;
    $ps =~ s/^% Local Variables:\n.*?^% End:\n//ms;
    $ps =~ s/^%%Trailer\n(?=%%EOF\n)//m;
  } # end unless $verbatim

  $ps;
} # end testable_output

#---------------------------------------------------------------------
# Create a BoundingBox: comment,
# and a HiRes version if the box has a fractional part:

sub _bbox_comment
{
  my ($o, $type, $bbox) = @_;

  my $comment = join(' ', @$bbox);

  if ($comment =~ /\./) {
    $comment = sprintf("%d %d %d %d\n%%%%%sHiResBoundingBox: %s",
                       (map { $_ + 0.999999 } @$bbox),
                       $type, $comment);
  } # end if fractional bbox

  "%%${type}BoundingBox: $comment\n";
} # end _bbox_comment

sub _print_file
{
  my $o        = shift;
  my $filename = shift;

  if (defined $filename) {
    my $outfile = openhandle $filename;
    if ($outfile) {
      print $outfile $_[0];
      return;
    } # end if passed a filehandle

    open($outfile, ">", $filename)
        or die "Unable to write to \'$filename\' : $!\nStopped";

    print $outfile $_[0];

    close $outfile;

    return $filename;
  } else {
    return $_[0];
  } # end else no filename
} # end _print_file
# Internal method, used by output()
# Expects file name and contents
#---------------------------------------------------------------------


sub get_auto_hyphen {
    my $o = shift;
    return $o->{auto_hyphen};
}

sub set_auto_hyphen {
    my ($o, $translate) = @_;
    $o->{auto_hyphen} = $o->{encoding} && $translate;
}

sub get_filename {
    my $o = shift;
    return $o->{filename};
}

sub set_filename {
    my ($o, $filename, $dir) = @_;
    $o->{filename} = ((defined($filename) and length($filename))
                      ? check_file($filename, $dir)
                      : undef);
}


sub get_file_ext {
    shift->{file_ext};
}

sub set_file_ext {
    my ($o, $ext) = @_;
    $o->{file_ext} = $ext;
}

sub get_eps { my $o = shift; return $o->{eps}; }


sub get_paper {
    my $o = shift;
    return $o->{paper};
}

sub set_paper {
    my $o = shift;
    my $paper = shift || "A4";
    my ($width, $height) = split(/\s+/, $size{lc($paper)} || '');

    if (not $height and $paper =~ /^(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)$/i) {
      $width  = $1;
      $height = $2;
      $paper  = 'Custom';
    } # end if $paper is 'WIDTH x HEIGHT'

    if ($height) {
        $o->{paper} = $paper;
        $o->{width} = $width;
        $o->{height} = $height;
        if ($o->{landscape}) {
            $o->{bbox}[0] = 0;
            $o->{bbox}[1] = 0;
            $o->{bbox}[2] = $height;
            $o->{bbox}[3] = $width;
        } else {
            $o->{bbox}[0] = 0;
            $o->{bbox}[1] = 0;
            $o->{bbox}[2] = $width;
            $o->{bbox}[3] = $height;
        }
    }
}


sub get_width {
    my $o = shift;
    return $o->{width};
}

sub set_width {
    my ($o, $width) = @_;
    if (defined($width) and ($width+0)) {
        $o->{width} = $width;
        $o->{paper} = "Custom";
        if ($o->{landscape}) {
            $o->{bbox}[1] = 0;
            $o->{bbox}[3] = $width;
        } else {
            $o->{bbox}[0] = 0;
            $o->{bbox}[2] = $width;
        }
    }
}


sub get_height {
    my $o = shift;
    return $o->{height};
}
sub set_height {
    my ($o, $height) = @_;
    if (defined($height) and ($height+0)) {
        $o->{height} = $height;
        $o->{paper} = "Custom";
        if ($o->{landscape}) {
            $o->{bbox}[0] = 0;
            $o->{bbox}[2] = $height;
        } else {
            $o->{bbox}[1] = 0;
            $o->{bbox}[3] = $height;
        }
    }
}


sub get_landscape {
    my $o = shift;
    return $o->{landscape};
}

sub set_landscape {
    my $o = shift;
    my $landscape = (!!shift) + 0;
    $o->{landscape} = 0 unless (defined $o->{landscape});
    if ($o->{landscape} != $landscape) {
        $o->{landscape} = $landscape;
        ($o->{bbox}[0], $o->{bbox}[1]) = ($o->{bbox}[1], $o->{bbox}[0]);
        ($o->{bbox}[2], $o->{bbox}[3]) = ($o->{bbox}[3], $o->{bbox}[2]);
    }
}


sub get_clipping {
    my $o = shift;
    return $o->{clipping};
}

sub set_clipping {
    my $o = shift;
    $o->{clipping} = (!!shift) + 0;
}

our %encoding_name = qw(
  iso-8859-1 ISOLatin1Encoding
  cp1252     Win1252Encoding
);

%encoding_def = (
  ISOLatin1Encoding => <<'END ISOLatin1Encoding',
% Define ISO Latin1 encoding if it doesnt exist
/ISOLatin1Encoding where {
%   (ISOLatin1 exists!) =
    pop
} {
    (ISOLatin1 does not exist, creating...) =
    /ISOLatin1Encoding StandardEncoding STARTDIFFENC
        45 /minus
        144 /dotlessi /grave /acute /circumflex /tilde
        /macron /breve /dotaccent /dieresis /.notdef /ring
        /cedilla /.notdef /hungarumlaut /ogonek /caron /space
        /exclamdown /cent /sterling /currency /yen /brokenbar
        /section /dieresis /copyright /ordfeminine
        /guillemotleft /logicalnot /hyphen /registered
        /macron /degree /plusminus /twosuperior
        /threesuperior /acute /mu /paragraph /periodcentered
        /cedilla /onesuperior /ordmasculine /guillemotright
        /onequarter /onehalf /threequarters /questiondown
        /Agrave /Aacute /Acircumflex /Atilde /Adieresis
        /Aring /AE /Ccedilla /Egrave /Eacute /Ecircumflex
        /Edieresis /Igrave /Iacute /Icircumflex /Idieresis
        /Eth /Ntilde /Ograve /Oacute /Ocircumflex /Otilde
        /Odieresis /multiply /Oslash /Ugrave /Uacute
        /Ucircumflex /Udieresis /Yacute /Thorn /germandbls
        /agrave /aacute /acircumflex /atilde /adieresis
        /aring /ae /ccedilla /egrave /eacute /ecircumflex
        /edieresis /igrave /iacute /icircumflex /idieresis
        /eth /ntilde /ograve /oacute /ocircumflex /otilde
        /odieresis /divide /oslash /ugrave /uacute
        /ucircumflex /udieresis /yacute /thorn /ydieresis
    ENDDIFFENC
} ifelse
END ISOLatin1Encoding

  Win1252Encoding => <<'END Win1252Encoding',
% Define Windows Latin1 encoding
/Win1252Encoding StandardEncoding STARTDIFFENC
    % LanguageLevel 1 may require these to be mapped somewhere:
    17 /dotlessi /dotaccent /ring /caron
    % Restore glyphs for standard ASCII characters:
    45 /minus
    96 /grave
    % Here are the CP1252 extensions to ISO-8859-1:
    128 /Euro /.notdef /quotesinglbase /florin /quotedblbase
    /ellipsis /dagger /daggerdbl /circumflex /perthousand
    /Scaron /guilsinglleft /OE /.notdef /Zcaron /.notdef
    /.notdef /quoteleft /quoteright /quotedblleft /quotedblright
    /bullet /endash /emdash /tilde /trademark /scaron
    /guilsinglright /oe /.notdef /zcaron /Ydieresis
    % We now return you to your ISO-8859-1 character set:
    /space
    /exclamdown /cent /sterling /currency /yen /brokenbar
    /section /dieresis /copyright /ordfeminine
    /guillemotleft /logicalnot /hyphen /registered
    /macron /degree /plusminus /twosuperior
    /threesuperior /acute /mu /paragraph /periodcentered
    /cedilla /onesuperior /ordmasculine /guillemotright
    /onequarter /onehalf /threequarters /questiondown
    /Agrave /Aacute /Acircumflex /Atilde /Adieresis
    /Aring /AE /Ccedilla /Egrave /Eacute /Ecircumflex
    /Edieresis /Igrave /Iacute /Icircumflex /Idieresis
    /Eth /Ntilde /Ograve /Oacute /Ocircumflex /Otilde
    /Odieresis /multiply /Oslash /Ugrave /Uacute
    /Ucircumflex /Udieresis /Yacute /Thorn /germandbls
    /agrave /aacute /acircumflex /atilde /adieresis
    /aring /ae /ccedilla /egrave /eacute /ecircumflex
    /edieresis /igrave /iacute /icircumflex /idieresis
    /eth /ntilde /ograve /oacute /ocircumflex /otilde
    /odieresis /divide /oslash /ugrave /uacute
    /ucircumflex /udieresis /yacute /thorn /ydieresis
ENDDIFFENC
END Win1252Encoding
); # end %encoding_def

sub _set_reencode
{
  my ($o, $encoding) = @_;

  return unless $encoding;

  if ($encoding eq 'ISOLatin1Encoding') {
    $o->{reencode} = $encoding;
    return;
  } # end if backwards compatible ISOLatin1Encoding

  $o->{reencode} = $encoding_name{$encoding}
      or croak "Invalid reencode setting $encoding";

  require Encode;  Encode->VERSION(2.21); # Need mime_name method
  $o->{encoding} = Encode::find_encoding($encoding)
      or croak "Can't find encoding $encoding";
} # end _set_reencode

our %encode_char = (
  8208 => pack(C => 0xAD), # U+2010 HYPHEN
  8209 => pack(C => 0xAD), # U+2011 NON-BREAKING HYPHEN
  8722 => pack(C => 0x2D), # U+2212 MINUS SIGN
 65533 => pack(C => 0x3F), # U+FFFD REPLACEMENT CHARACTER
);


sub encode_text
{
  my $o = shift;

  my $encoding = $o->{encoding};

  if ($encoding and Encode::is_utf8( $_[0] )) {
    $encoding->encode($_[0], sub {
      $encode_char{$_[0]} || do {
        if ($_[0] < 0x100) {
          pack C => $_[0];      # Unmapped chars stay themselves
        } else {
          warn sprintf("PostScript::File can't convert U+%04X to %s\n",
                       $_[0], $encoding->name);
          '?'
        }
      }; # end invalid character
    });
  } else {
    $_[0];
  }
} # end encode_text


sub decode_text
{
  my $o = shift; # $text, $preserve_minus

  my $encoding = $o->{encoding};

  if ($encoding and not Encode::is_utf8( $_[0] )) {
    my $text = $encoding->decode($_[0], sub { pack U => shift });
    # Protect - from hyphen-minus processing if $preserve_minus:
    $text =~ s/-/\x{2212}/g if $_[1];
    $text;
  } else {
    $_[0];
  }
} # end decode_text


sub convert_hyphens
{
  my $o = shift;
  if ($_[0] =~ /-/) {
    # Text contains at least one hyphen-minus character:
    my $text = $o->decode_text(shift);

    # If it's surrounded by whitespace, or
    # it's preceded by whitespace and followed by a digit,
    # it's a minus sign (U+2212):
    $text =~ s/(?: ^ | (?<=\s) ) - (?= \d | \s | $ ) /\x{2212}/gx;

    # If it's surrounded by digits, or
    # it's preceded by punctuation and followed by a digit,
    # it's a minus sign (U+2212):
    $text =~ s/ (?<=[\d[:punct:]]) - (?=\d) /\x{2212}/gx;

    # If it's followed by a currency symbol, it's a minus sign (U+2212):
    $text =~ s/ - (?=\p{Sc}) /\x{2212}/gx;

    # Otherwise, it's a hyphen (U+2010):
    $text =~ s/-/\x{2010}/gx;

    $text;
  } else {
    shift;                      # Return text unmodified
  }
} # end convert_hyphens


sub get_metrics
{
  my ($o, $font, $size, $encoding) = @_;

  # Figure out what encoding to ask for:
  unless ($encoding) {
    if ($font eq 'Symbol') {
      $encoding = 'sym';
    }
    elsif ($o->{reencode} and $font =~ s/\Q$o->{font_suffix}\E$//) {
      $encoding = $o->{encoding}->name || 'iso-8859-1';
    } else {
      $encoding = 'std';
    }
  } # end unless $encoding supplied as parameter

  # Create the Metrics object:
  require PostScript::File::Metrics;
  my $metrics = PostScript::File::Metrics->new($font, $size, $encoding);

  # Whatever encoding they asked for, make sure that the
  # auto-translation matches what we're doing:
  $metrics->{encoding} = $o->{encoding};
  $metrics->{auto_hyphen} = $o->{auto_hyphen};

  $metrics;
} # end get_metrics
#---------------------------------------------------------------------


sub get_strip {
    my $o = shift;
    return $o->{strip_type};
}

my $eolRE   = qr/(?>\r\n?|\n)/;
my $noeolRE = qr/[^\r\n]/;
my $nonwsRE = qr/[^ \t\r\n]/;

my %strip_re = (
  none     => 0,                             # remove nothing
  space    => qr{\G^\s+}m,                   # remove leading spaces
  # remove leading spaces and single line comments (except %% and %!):
  comments => qr{\G^(?:\s+|%(?![!%])(?:$noeolRE)*(?:$eolRE))}mo,
  # remove leading spaces and all comments (except %% and %!):
  all_comments => qr{\G (?: ^\s+
                          | ^% (?![!%]) (?:$noeolRE)* (?:$eolRE)
                          | [ \t]*%(?![!%]) (?:$noeolRE)* )
                    }mox,
); # end strip_re

sub set_strip {
    my ($o, $strip) = @_;

    if (not defined $strip) { $strip = 'space'   }
    else                    { $strip = lc $strip }

    defined($o->{strip} = $strip_re{$strip})
        or croak "Invalid strip type $strip";
    $o->{strip_type} = $strip;
}

#sub chkpt
#{
#  my $at = substr($_, pos(), 5);
#  $at =~ s/([^ -~])/sprintf '\x%02X', ord $1 /eg;
#  printf "%d: %s\n", pos(), $at;
#} # end chkpt

sub strip
{
  my $o = shift;

  my $re;
  if (@_ > 1) {
    my $strip = shift;
    defined($re = $strip_re{$strip})
        or croak "Invalid strip type $strip";
  } else {
    $re = $o->{strip};
  }

  return unless $re;

  my $pos;

  for (@_) {
    next unless defined $_;
    pos() = 0;
    while (pos() < length) {
      next if m/\G<~[^~]*~>/gc
           or m/\G\( (?: [^\\)]+ | \\. )* \)/sgcx;
      $pos = pos();
      if (s/$re//m) {
        pos() = $pos;
      } else {
        pos() = $pos;
        m/\G[ \t]*(?:$eolRE|(?:$nonwsRE)+(?:$eolRE)?)/ogc;
        die "Infinite loop" if pos() == $pos;
      }
    }
  } # end for @_

  return;
} # end strip
#---------------------------------------------------------------------


sub get_page_landscape {
    my $o = shift;
    my $p = $o->_get_ordinal( shift );
    return $o->{pagelandsc}[$p];
}

sub set_page_landscape {
    my $o = shift;
    my $p = (@_ == 2) ? $o->_get_ordinal(shift) : $o->{p};
    my $landscape = (!!shift) + 0;
    $o->{pagelandsc}[$p] = 0 unless (defined $o->{pagelandsc}[$p]);
    if ($o->{pagelandsc}[$p] != $landscape) {
        ($o->{pagebbox}[$p][0], $o->{pagebbox}[$p][1]) = ($o->{pagebbox}[$p][1], $o->{pagebbox}[$p][0]);
        ($o->{pagebbox}[$p][2], $o->{pagebbox}[$p][3]) = ($o->{pagebbox}[$p][3], $o->{pagebbox}[$p][2]);
    }
    $o->{pagelandsc}[$p] = $landscape;
}

#---------------------------------------------------------------------


sub get_page_clipping {
    my $o = shift;
    my $p = $o->_get_ordinal( shift );
    return $o->{pageclip}[$p];
}

sub set_page_clipping {
    my $o = shift;
    my $p = (@_ == 2) ? $o->_get_ordinal(shift) : $o->{p};
    $o->{pageclip}[$p] = (!!shift) + 0;
}


sub get_page_label {
    my $o = shift;
    return $o->{page}[$o->{p}];
}

sub set_page_label {
    my $o = shift;
    my $page = shift || 1;
    $o->{page}[$o->{p}] = $page;
}


sub get_incpage_handler {
    my $o = shift;
    return $o->{incpage};
}

sub set_incpage_handler {
    my $o = shift;
    $o->{incpage} = shift || \&incpage_label;
}


sub get_order {
    my $o = shift;
    return $o->{order};
}


sub get_title {
    my $o = shift;
    return $o->{title};
}


sub get_version {
    my $o = shift;
    return $o->{version};
}


sub get_langlevel {
    my $o = shift;
    return $o->{langlevel};
}

sub set_min_langlevel
{
  my ($o, $level) = @_;
  $o->{langlevel} = $level unless ($o->{langlevel} || 0) >= $level;
  return $o->{langlevel};
}


sub get_extensions {
    my $o = shift;
    return $o->{extensions};
}


sub get_bounding_box {
    my $o = shift;
    return @{$o->{bbox}};
}

sub set_bounding_box {
    my ($o, $x0, $y0, $x1, $y1) = @_;
    $o->{bbox} = [ $x0, $y0, $x1, $y1 ] if (defined $y1);
    $o->set_clipping(1);
}


sub get_printable_width
{
  my $bb = shift->{bbox};
  return $bb->[2] - $bb->[0];
} # end get_printable_width

sub get_printable_height
{
  my $bb = shift->{bbox};
  return $bb->[3] - $bb->[1];
} # end get_printable_height


sub get_page_bounding_box {
    my $o = shift;
    my $p = $o->_get_ordinal( shift );
    return @{$o->{pagebbox}[$p]};
}

sub set_page_bounding_box {
    my $o = shift;
    my $page = (@_ == 5) ? shift : "";
    if (@_ == 4) {
        my $p = $o->_get_ordinal($page);
        $o->{pagebbox}[$p] = [ @_ ];
        $o->set_page_clipping($page, 1);
    }
}


sub get_page_printable_width
{
  my $o = shift;
  my $bb = $o->{pagebbox}[$o->_get_ordinal( shift )];
  return $bb->[2] - $bb->[0];
} # end get_page_printable_width

sub get_page_printable_height
{
  my $o = shift;
  my $bb = $o->{pagebbox}[$o->_get_ordinal( shift )];
  return $bb->[3] - $bb->[1];
} # end get_page_printable_height


sub set_page_margins {
    my $o = shift;
    my $page = (@_ == 5) ? shift : "";
    if (@_ == 4) {
        my ($left, $bottom, $right, $top) = @_;
        my $p = $o->_get_ordinal($page);
        if ($o->{pagelandsc}[$p]) {
            $o->{pagebbox}[$p] = [ $left, $bottom, $o->{height}-$right, $o->{width}-$top ];
        } else {
            $o->{pagebbox}[$p] = [ $left, $bottom, $o->{width}-$right, $o->{height}-$top ];
        }
        $o->set_page_clipping($page, 1);
    }
}

# =method-access get_ordinal
#
#   $index = $ps->get_ordinal( [$page] )
#
# Returns the internal number for the page label specified.  (Default:
# current page)
#
# Example
#
# Say pages are labeled "i", "ii", "iii, "iv", "1", "2", "3".
#
#     get_ordinal("i") == 0
#     get_ordinal("iv") == 3
#     get_ordinal("1") == 4
#
# =cut

sub _get_ordinal
{
    my ($o, $page) = @_;
    if ($page) {
        for (my $i = 0; $i <= $o->{pagecount}; $i++) {
            my $here = $o->{page}->[$i] || "";
            return $i if ($here eq $page);
        }
    }
    return $o->{p};
}


sub get_pagecount {
    my $o = shift;
    return $o->{pagecount};
}


sub set_variable {
    my ($o, $key, $value) = @_;
    $o->{vars}{$key} = $value;
}


sub get_variable {
    my ($o, $key) = @_;
    return $o->{vars}{$key};
}


sub set_page_variable {
    my ($o, $key, $value) = @_;
    $o->{pagevars}{$key} = $value;
}


sub get_page_variable {
    my ($o, $key) = @_;
    return $o->{pagevars}{$key};
}


sub get_comments {
    my $o = shift;
    return $o->{Comments};
}


sub add_comment {
    my ($o, $entry) = @_;
    $o->{Comments} .= "\%\%$entry\n" if defined($entry);
}


sub get_preview {
    my $o = shift;
    return $o->{Preview};
}


sub add_preview {
  my ($o, $width, $height, $depth, $lines, $entry) = @_;
  if (defined $entry) {
    $entry .= "\n";
    $o->strip(space => $entry);
    $o->{Preview} =
      "%%BeginPreview: $width $height $depth $lines\n$entry%%EndPreview\n";
  }
} # end add_preview


sub get_defaults {
    my $o = shift;
    return $o->{Defaults};
}


sub add_default {
    my ($o, $entry) = @_;
    $o->{Defaults} .= "\%\%$entry\n" if defined($entry);
}


sub get_resources {
    my $o = shift;
    return $o->{Fonts} . $o->{Resources};
}

our %supplied_type = (qw(
  Document  file
  Feature) => ''
);

our %add_resource_accepts = map { $_ => 1 } qw(
  encoding file font form pattern
);
# add_resource does not accept procset, but need_resource does:
$add_resource_accepts{procset} = undef;

sub add_resource {
    my ($o, $type, $name, $params, $resource) = @_;

    my $suptype = $supplied_type{$type};
    my $restype = '';

    croak "add_resource does not accept type $type"
        unless defined($suptype) or $add_resource_accepts{lc $type};

    unless (defined $suptype) {
      $suptype = lc $type;
      $restype = "$suptype ";
      $type    = 'Resource';
    } # end unless Document or Feature

    if (defined($resource)) {
        $o->strip($resource);
        $name = $o->quote_text($name);
        $o->{DocSupplied} .= $o->encode_text("\%\%+ $suptype $name\n")
            if $suptype;

        # Store fonts separately, because they need to come first:
        my $storage = 'Resources';

        if ($suptype eq 'font') {
          $storage = 'Fonts';
          push @{ $o->{embed_fonts} }, $name; # Remember to reencode it
        } # end if adding Font

        $name .= " $params" if defined $params and length $params;

        $o->{$storage} .= $o->_here_doc(<<END_USER_RESOURCE);
            \%\%Begin${type}: $restype$name
            $resource
            \%\%End$type
END_USER_RESOURCE
    }
}



sub get_procsets
{
    my $o = shift;
    return $o->{Functions};
}

sub add_procset
{
    my ($o, $name, $entry, $version, $revision) = @_;
    if (defined($name) and defined($entry)) {
        return if $o->has_procset($name);
        $o->strip($entry);
        $name = sprintf('%s %g %d', $o->quote_text($name),
                        $version||0, $revision||0);
        $o->{DocSupplied} .= $o->encode_text("\%\%+ procset $name\n");
        $o->{Functions} .= $o->_here_doc(<<END_USER_FUNCTIONS);
            \%\%BeginResource: procset $name
            $entry
            \%\%EndResource
END_USER_FUNCTIONS
        return 1;
    }
    return;
}


sub has_procset
{
    my ($o, $name) = @_;
    $name = $o->quote_text($name);
    return ($o->{DocSupplied} =~ /^\%\%\+ procset \Q$name\E /m);
}

# Retain the old names for backwards compatibility:
*add_function  = \&add_procset;
*get_functions = \&get_procsets;
*has_function  = \&has_procset;


sub use_functions
{
  my $o = shift;

  (
    $o->{use_functions} ||= do {
      require PostScript::File::Functions;

      PostScript::File::Functions->new;
    }
  )->add(@_);

  return $o;
} # end use_functions


sub embed_document
{
  my ($o, $filename) = @_;

  my $id = $o->quote_text(substr($filename, -234)); # in case it's long
  my $supplied = $o->encode_text("%%+ file $id\n");
  $o->{DocSupplied} .= $supplied
      unless index($o->{DocSupplied}, $supplied) >= 0;

  local $/;                     # Read entire file
  open(my $in, '<:raw', $filename) or croak "Unable to open $filename: $!";
  my $content = <$in>;
  close $in;

  # Remove TIFF or WMF preview image:
  if ($content =~ /^\xC5\xD0\xD3\xC6/) {
    my ($pos, $len) = unpack('V2', substr($content, 4, 8));
    $content = substr($content, $pos, $len);
  } # end if EPS file with TIFF or WMF preview image

  # Do CR or CRLF -> LF processing, since we read in RAW mode:
  $content =~ s/\r\n?/\n/g;

  # Remove EPSI preview:
  $content =~ s/^\s*%%BeginPreview:.*\n
                (?:\s*%(?!%).*\n)*
                \s*%%EndPreview.*\n//gmx;

  return "\%\%BeginDocument: $id\n$content\n\%\%EndDocument\n";
} # end embed_document


sub embed_font
{
  my ($o, $filename, $type) = @_;

  unless ($type) {
    $filename =~ /\.([^\\\/.]+)$/ or croak "No extension in $filename";
    $type = $1;
  }
  $type = uc $type;

  my $in;
  if ($type eq 'PFA') {
    open($in, '<:raw', $filename) or croak "Unable to open $filename: $!";
  } elsif ($type eq 'PFB') {
    open($in, '-|:raw', $t1ascii, $filename)
        or croak "Unable to run $t1ascii $filename: $!";
  } elsif ($type eq 'TTF') {
    open($in, '-|:raw', $ttftotype42, $filename)
        or croak "Unable to run $ttftotype42 $filename: $!";
    # Type 42 was introduced in LanguageLevel 2:
    $o->set_min_langlevel(2);
  }

  my $content = do { local $/; <$in> }; # Read entire file
  close $in;

  $content =~ s/\r\n?/\n/g;     # CR or CRLF to LF

  $content =~ m!/FontName\s+/(\S+)\s+def\b!
      or croak "Unable to find font name in $filename";
  my $fontName = $1;

  $o->add_resource(Font => $fontName, undef, $content);

  return $fontName;
} # end embed_font


sub need_resource
{
  my $o    = shift;
  my $type = shift;

  croak "Unknown resource type $type"
      unless exists $add_resource_accepts{$type};

  my $hash = $o->{needed}{$type} ||= {};

  foreach my $res (@_) {

    $hash->{ $o->encode_text(
      join(' ', map { $o->quote_text($_) } (ref $res ? @$res : $res))
    )} = 1;
  } # end foreach $res
} # end need_resource


sub get_setup {
    my $o = shift;
    return $o->{Setup};
}


sub add_setup {
    my ($o, $entry) = @_;
    $o->strip($entry);
    $o->{Setup} .= $o->encode_text($entry) if (defined $entry);
}


sub get_page_setup {
    my $o = shift;
    return $o->{PageSetup};
}


sub add_page_setup {
    my ($o, $entry) = @_;
    $o->strip($entry);
    $o->{PageSetup} .= $o->encode_text($entry) if (defined $entry);
}


sub get_page {
    my $o = shift;
    my $page = shift || $o->get_page_label();
    my $ord = $o->_get_ordinal($page);
    return $o->{Pages}->[$ord];
}


sub add_to_page {
    my $o = shift;
    my $page = (@_ == 2) ? shift : "";
    my $entry = shift || "";
    if ($page) {
        my $ord = $o->_get_ordinal($page);
        if (($ord == $o->{p}) and ($page ne $o->{page}[$ord])) {
            $o->newpage($page);
        } else {
            $o->{p} = $ord;
        }
    }
    $o->strip($entry);
    $o->{Pages}[$o->{p}] .= $o->encode_text($entry);
}


sub get_page_trailer {
    my $o = shift;
    return $o->{PageTrailer};
}


sub add_page_trailer {
    my ($o, $entry) = @_;
    $o->strip($entry);
    $o->{PageTrailer} .= $o->encode_text($entry) if (defined $entry);
}


sub get_trailer {
    my $o = shift;
    return $o->{Trailer};
}


sub add_trailer {
    my ($o, $entry) = @_;
    $o->strip($entry);
    $o->{Trailer} .= $o->encode_text($entry) if (defined $entry);
}

#=============================================================================


sub draw_bounding_box {
    my $o = shift;
    $o->{clipcmd} = "stroke";
}

sub clip_bounding_box {
    my $o = shift;
    $o->{clipcmd} = "clip";
}

# Strip leading spaces off a here document:

sub _here_doc
{
  my ($o, $text) = @_;

  if ($o->{strip_type} ne 'none') {
    $o->strip($text);
  } elsif ($text =~ /^([ \t]+)/) {
    my $space = $1;

    $text =~ s/^$space//gm;
    $text =~ s/^[ \t]+\n/\n/gm;
  } # end elsif no strip but $text is indented

  $o->encode_text($text);
} # end _here_doc


sub incpage_label ($) { ## no critic (ProhibitSubroutinePrototypes)
    my $page = shift;
    return ++$page;
}
#---------------------------------------------------------------------


our $roman_max = 40;
our @roman = qw(0 i ii iii iv v vi vii viii ix x xi xii xiii xiv xv xvi xvii xviii xix
                xx xi xxii xxii xxiii xxiv xxv xxvi xxvii xxviii xxix
                xxx xxi xxxii xxxii xxxiii xxxiv xxxv xxxvi xxxvii xxxviii xxxix );
our %roman = ();
for (my $i = 1; $i <= $roman_max; $i++) {
    $roman{$roman[$i]} = $i;
}

sub incpage_roman ($) { ## no critic (ProhibitSubroutinePrototypes)
    my $page = shift;
    my $pos = $roman{$page};
    return $roman[++$pos];
}
#---------------------------------------------------------------------


sub check_file ($;$$) { ## no critic (ProhibitSubroutinePrototypes)
    my ($filename, $dir, $create) = @_;
    $create = 0 unless (defined $create);

    if (not defined $filename or not length $filename) {
        $filename = File::Spec->devnull();
    } else {
        $filename = check_tilde($filename);
        $filename = File::Spec->canonpath($filename);
        unless (File::Spec->file_name_is_absolute($filename)) {
            if (defined($dir)) {
                $dir = check_tilde($dir);
                $dir = File::Spec->canonpath($dir);
                $dir = File::Spec->rel2abs($dir) unless (File::Spec->file_name_is_absolute($dir));
                $filename = File::Spec->catfile($dir, $filename);
            } else {
                $filename = File::Spec->rel2abs($filename);
            }
        }

        my @subdirs = ();
        my ($volume, $directories, $file) = File::Spec->splitpath($filename);
        @subdirs = File::Spec->splitdir( $directories );

        my $path = $volume;
        foreach my $dir (@subdirs) {
            $path = File::Spec->catdir( $path, $dir );
            mkdir $path unless (-d $path);
        }

        $filename = File::Spec->catfile($path, $file);
        if ($create) {
            unless (-e $filename) {
                open(my $file, ">", $filename)
                    or die "Unable to open \'$filename\' for writing : $!\nStopped";
                close $file;
            }
        }
    }

    return $filename;
}


sub check_tilde ($) { ## no critic (ProhibitSubroutinePrototypes)
    my ($dir) = @_;
    $dir = "" unless defined $dir;
    $dir =~ s{^~([^/]*)}{$1 ? (getpwnam($1))[7] : ($ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7]) }ex;
    return $dir;
}


sub array_as_string (@) { ## no critic (ProhibitSubroutinePrototypes)
    my $array = "[ ";
    foreach my $f (@_) { $array .= "$f "; }
    $array .= "]";
    return $array;
}


sub str ($) { ## no critic (ProhibitSubroutinePrototypes)
    my $arg = shift;
    if (ref($arg) eq "ARRAY") {
        return array_as_string( @$arg );
    } else {
        return $arg;
    }
}
#---------------------------------------------------------------------

my %special = (
  "\n" => '\n', "\r" => '\r', "\t" => '\t', "\b" => '\b',
  "\f" => '\f', "\\" => "\\\\", "("  => '\(', ")"  => '\)',
);
my $specialKeys = join '', keys %special;
$specialKeys =~ s/\\/\\\\/;     # Have to quote backslash

sub pstr {
  my $o;
  $o = shift if @_ > 1;         # We were called as a method
  my $string = shift;
  my $nowrap = shift;           # Pass this ONLY when method call

  # Possibly convert \x2D (hyphen-minus) to hyphen or minus sign:
  $string = $o->convert_hyphens($string)
      if ref $o and $o->{auto_hyphen} and $string =~ /-/;

  # Now form the parenthesized string:
  $string =~ s/([$specialKeys])/$special{$1}/go;
  $string = "($string)";
  # A PostScript file should not have more than 255 chars per line:
  $string =~ s/(.{240}[^\\])/$1\\\n/g unless $nowrap;
  $string =~ s/^([ %])/\\$1/mg; # Make sure it doesn't get stripped

  $string;
} # end pstr


sub quote_text
{
  my $o;
  $o = shift if @_ > 1;         # We were called as a method

  my $string = shift;

  return $string if $string =~ m(^[-+_./*A-Za-z0-9]+\z);

  __PACKAGE__->pstr($string, 1);
} # end quote_text

#=============================================================================
1;

__END__

=head1 NAME

PostScript::File - Class for creating Adobe PostScript files

=head1 VERSION

This document describes version 2.23 of PostScript::File,
released October 10, 2015 as part of PostScript-File version 2.23.

Attributes and methods added since version 2.00 are marked with the
version they were added in (e.g. "(v2.10)").  Because there were
significant API changes in 2.00, I recommend that any code using
PostScript::File specify a minimum version of at least 2.

=head1 SYNOPSIS

=head2 Simplest

A 'hello world' program:

    use PostScript::File 2;

    my $ps = PostScript::File->new(reencode => 'cp1252');

    $ps->add_to_page( <<END_PAGE );
        /Helvetica findfont
        12 scalefont
        setfont
        72 300 moveto
        (hello world) show
    END_PAGE

    $ps->output( "test" );

=head2 All options

    my $ps = PostScript::File->new(
        paper => 'Letter',
        height => 500,
        width => 400,
        bottom => 30,
        top => 30,
        left => 30,
        right => 30,
        clip_command => 'stroke',
        clipping => 1,
        eps => 1,
        dir => '~/foo',
        file => "bar",
        landscape => 0,

        headings => 1,
        reencode => 'cp1252',
        font_suffix => '-iso',
        need_fonts  => [qw(Helvetica Helvetica-Bold)],

        errors => 1,
        errmsg => 'Failed:',
        errfont => 'Helvetica',
        errsize => 12,
        errx => 72,
        erry => 300,

        debug => 2,
        db_active => 1,
        db_xgap => 120,
        db_xtab => 8,
        db_base => 300,
        db_ytop => 500,
        db_color => '1 0 0 setrgbcolor',
        db_font => 'Times-Roman',
        db_fontsize => 11,
        db_bufsize => 256,
    );

=head1 DESCRIPTION

PostScript::File is a class that writes PostScript files following
Adobe's Document Structuring Conventions (DSC).  You should be
familiar with the DSC if you're using this class directly; consult the
I<PostScript Language Document Structuring Conventions Specification>
linked to in L</"SEE ALSO">.

There are also a number of modules that build upon PostScript::File to
produce various kinds of documents without requiring knowledge of
PostScript.  These are listed in L</"SEE ALSO">.

It is possible to construct and output files in either normal
PostScript (*.ps files) or as Encapsulated PostScript (*.epsf or
*.epsi files).  By default a minimal file is output, but support for
font encoding, PostScript error reporting and debugging can be built
in if required.

Documents can typically be built using only these functions:

    new           The constructor, with many options
    add_procset   Add PostScript functions to the prolog
    add_to_page   Add PostScript to construct each page
    newpage       Begins a new page in the document
    output        Construct the file and saves it

The rest of the module involves fine-tuning this.  Some settings only really make sense when given once, while
others can control each page independently.  See C<new> for the functions that duplicate option settings, they all
have C<get_> counterparts.  The following provide additional support.

    get/set_bounding_box
    get/set_page_bounding_box
    get/set_page_clipping
    get/set_page_landscape
    set_page_margins
    get_pagecount
    draw_bounding_box
    clip_bounding_box

The functions which insert entries into each of the DSC sections all begin with 'add_'.  They also have C<get_>
counterparts.

    add_comment
    add_preview
    add_default
    add_resource
    add_procset
    add_setup
    add_page_setup
    add_to_page
    add_page_trailer
    add_trailer

Finally, there are a few stand-alone functions.  These are not methods and are available for export if requested.

    check_tilde
    check_file
    incpage_label
    incpage_roman

=head2 Hyphens and Minus Signs

In ASCII, the character C<\x2D> (C<\055>) is used as both a hyphen and
a minus sign.  Unicode calls this character HYPHEN-MINUS (U+002D).
PostScript has two characters, which it calls C</hyphen> and
C</minus>.  The difference is that C</minus> is usually wider than
C</hyphen> (except in Courier, of course).

In PostScript's StandardEncoding (what you get if you don't use
L</reencode>), character C<\x2D> is C</hyphen>, and C</minus> is not
available.  In the Latin1-based encodings created by C<reencode>,
character C<\x2D> is C</minus>, and character C<\xAD> is C</hyphen>.
(C<\xAD> is supposed to be a "soft hyphen" (U+00AD) that appears only
if the line is broken at that point, but it doesn't work that way in
PostScript.)

Unicode has additional non-ambiguous characters: HYPHEN (U+2010),
NON-BREAKING HYPHEN (U+2011), and MINUS SIGN (U+2212).  The first two
always indicate C</hyphen>, and the last is always C</minus>.  When you set
C<reencode> to C<cp1252> or C<iso-8859-1>, those characters will be
handled automatically.

To make it easier to handle strings containing HYPHEN-MINUS,
PostScript::File provides the L</auto_hyphen> attribute.  When this is
true (the default when using C<cp1252> or C<iso-8859-1>), the L</pstr>
method will automatically translate HYPHEN-MINUS to either HYPHEN or
MINUS SIGN.  (This happens only when C<pstr> is called as an object method.)

The rule is that if a HYPHEN-MINUS is surrounded by whitespace, or
surrounded by digits, or it's preceded by whitespace or punctuation
and followed by a digit, or it's followed by a currency symbol, it's
translated to MINUS SIGN.  Otherwise, it's translated to HYPHEN.

=head1 ATTRIBUTES

Unlike many classes that use the same method for reading and writing
an attribute's value, PostScript::File has separate methods for
reading and writing.  The read accessor is prefixed with C<get_>, and
the write accessor is prefixed with C<set_>.  If no write accessor is
mentioned, then the attribute is read-only.



=head3 auto_hyphen

  $ps = PostScript::File->new( auto_hyphen => $translate )

  $translate = $ps->get_auto_hyphen

  $ps->set_auto_hyphen( $translate )

If C<$translate> is a true value, then L</pstr> will do automatic
hyphen-minus translation when called as an object method (but only if
the document uses character set translation).  (Default: true)
See L</"Hyphens and Minus Signs">.


=head3 clipping

  $ps = PostScript::File->new( clipping => $clipping )

  $clipping = $ps->get_clipping

  $ps->set_clipping( $clipping )

If C<$clipping> is true, printing will be clipped to each page's
bounding box.  This is the document's default value.  Each page has
its own L</page_clipping> attribute, which is initialized to this
default value when the page is created.  (Default: false)


=head3 eps

  $ps = PostScript::File->new( eps => $eps )

  $eps = $ps->get_eps

C<$eps> is true if this is an Encapsulated PostScript document.
False indicates an ordinary PostScript document.


=head3 extensions

  $ps = PostScript::File->new( extensions => $extensions )

  $extensions = $ps->get_extensions

The PostScript extensions required by this document, for use in the
C<%%Extensions> DSC comment.  (Default: C<undef>, meaning omit the
C<%%Extensions> comment)


=head3 file_ext

  $ps = PostScript::File->new( file_ext => $file_ext )

  $file_ext = $ps->get_file_ext

  $ps->set_file_ext( $file_ext )

If C<$file_ext> is undef (the default), then the extension is set
automatically based on the output type.  C<.ps> will be added for
ordinary PostScript files.  EPS files have an extension of C<.epsf>
without or C<.epsi> with a preview image.

If C<$file_ext> is the empty string, then no
extension will be added to the filename.  Otherwise, it should be a
string like '.ps' or '.eps'.  (But setting this has no effect on the
actual type of the output file, only its name.)


=head3 filename

  $ps = PostScript::File->new( file => $file, [dir => $dir] )

  $filename = $ps->get_filename

  $ps->set_filename( $file, [$dir] )

=over 4

=item C<$file>

An optional fully qualified path-and-file, a simple file name, the
empty string (which stands for the special file C<< File::Spec->devnull >>),
or C<undef> (which indicates the document has no associated filename).

=item C<$dir>

An optional directory name.  If present (and C<$file> is not already
an absolute path), it is prepended to C<$file>.  If no C<$file> was
specified, C<$dir> is ignored.

=back

The base filename for the output file(s).  When the filename is set,
if that filename includes a directory component, the directories are
created immediately (if they don't already exist).

See L</file_ext> for details on how the filename extension is handled.

If L</eps> has been set, multiple pages will have the page label
appended to the file name.

Example:

    $ps = PostScript::File->new( eps => 1 );
    $ps->set_filename( "pics", "~/book" );
    $ps->newpage("vi");
        ... draw page
    $ps->newpage("7");
        ... draw page
    $ps->newpage();
        ... draw page
    $ps->output();

The three pages for user 'chris' on a Unix system would be:

    /home/chris/book/pics-vi.epsf
    /home/chris/book/pics-7.epsf
    /home/chris/book/pics-8.epsf

It would be wise to use C<set_page_bounding_box> explicitly for each page if using multiple pages in EPS files.


=head3 incpage_handler

  $ps = PostScript::File->new( incpage_handler => \&handler )

  $handler = $ps->get_incpage_handler

  $ps->set_incpage_handler( [\&handler] )

The function used to increment the page label when creating a new
page.  C<\&handler> is a reference to a subroutine that takes the
current page label as its only argument and returns the new label.

This module provides the L</incpage_label> (which uses Perl's
autoincrement operator) and L</incpage_roman> (which handles lowercase
Roman numberals from i to xxxix, 1-39) functions for use as
C<incpage_handler>.  (Default: C<\&incpage_label>)


=head3 langlevel

  $ps = PostScript::File->new( langlevel => $langlevel )

  $langlevel = $ps->get_langlevel

  $ps->set_min_langlevel( $langlevel ) # added in v2.20

The level of the PostScript language used in this document, for use in
the C<%%LanguageLevel> DSC comment.  The L</set_min_langlevel> method
can be used to raise the language level, but it cannot be decreased.
(Default: C<undef>, meaning omit the C<%%LanguageLevel> comment)


=head3 order

  $ps = PostScript::File->new( order => $order )

  $order = $ps->get_order

The order the pages are defined in the document, for use in the
C<%%PageOrder> DSC comment.  It must be one of "Ascend", "Descend" or
"Special" (meaning a document manager must not reorder the pages).
The default is C<undef>, meaning omit the C<%%PageOrder> comment.


=head3 strip (attribute)

  $ps = PostScript::File->new( strip => $strip )

  $strip = $ps->get_strip

  $ps->set_strip( $strip )

Determine whether the PostScript code is filtered.  C<$strip> must be
one of the following values:
C<space> strips leading spaces so the user can indent freely without
increasing the file size.  C<comments> removes lines beginning with
'%' as well.  C<all_comments> (v2.20) also removes
comments that aren't at the beginning of a line.
See also the L<strip|/"strip (method)"> method, which actually does
the filtering described here.

Passing C<undef> or omitting C<$strip> sets it to the default value,
C<space>.


=head3 title

  $ps = PostScript::File->new( title => $title )

  $title = $ps->get_title

The document's title for use in the C<%%Title> DSC comment.  The
default (C<undef>) means to use the document's filename as the title.
If no filename is available when the document is output, the
C<%%Title> comment wil be omitted.


=head3 version

  $ps = PostScript::File->new( version => $version )

  $version = $ps->get_version

The document's version for use in the C<%%Version> DSC comment.  The
C<$version> should be a string in the form S<C<VERNUM REV>>, where
C<VERNUM> is a floating point number and C<REV> is an unsigned
integer.  (Default: C<undef>, meaning omit the C<%%Version> comment)


=head2 Paper Size and Margins

These attributes are interrelated, and changing one may change the
others.


=head3 bounding_box

  ( $llx, $lly, $urx, $ury ) = $ps->get_bounding_box

  $ps->set_bounding_box( $llx, $lly, $urx, $ury )

The bounding box for the whole document.  The lower left corner is
S<C<($llx, $lly)>>, and the upper right corner is S<C<($urx, $ury)>>.

Setting the bounding box automatically enables clipping.  Call
C<< $ps->set_clipping(0) >> afterwards to undo that.

The default C<bounding_box> is calculated from the paper size (taken
from the L</paper>, L</height>, and L</width> attributes) and the
L</left>, L</right>, L</top>, and L</bottom> margins.

Each page also has an individual L</page_bounding_box>, which is
initialized from the document's C<bounding_box> when the page is
created.


=head3 height

  $ps = PostScript::File->new( height => $height )

  $height = $ps->get_height

  $ps->set_height( $height )

The page height in points.  This is normally the longer dimension of the
paper.  Note that in landscape mode this is actually the width of the
bounding box.

Setting this sets L</paper> to "Custom" and the L</bounding_box> is
expanded to the full height.


=head3 landscape

  $ps = PostScript::File->new( landscape => $landscape )

  $landscape = $ps->get_landscape

  $ps->set_landscape( $landscape )

If C<$landscape> is true, the page is rotated 90 degrees
counter-clockwise, swapping the meaning of height & width.  (Default: false)

In landscape mode the coordinates are rotated 90 degrees and the origin moved to the bottom left corner.  Thus the
coordinate system appears the same to the user, with the origin at the bottom left.


=head3 paper

  $ps = PostScript::File->new( paper => $paper_size )

  $paper_size = $ps->get_paper

  $ps->set_paper( $paper_size )

Set the paper size of each page.  A document can be created using a
standard paper size without having to remember the size of paper using
PostScript points. Valid choices are currently A0, A1, A2, A3, A4, A5,
A6, A7, A8, A9, B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10,
Executive, Folio, Half-Letter, Letter, US-Letter, Legal,
US-Legal, Tabloid, SuperB, Ledger, 'Comm #10 Envelope',
Envelope-Monarch, Envelope-DL, Envelope-C5, and EuroPostcard.
(Default: "A4")

You can also give a string in the form 'WIDTHxHEIGHT', where WIDTH and
HEIGHT are numbers (in points).  This sets the paper size to "Custom".

Setting this also sets L</bounding_box>, L</height>, and L</width>
to the full height and width of the paper.


=head3 width

  $ps = PostScript::File->new( width => $width )

  $width = $ps->get_width

  $ps->set_width( $width )

The page width in points.  This is normally the shorter dimension of
the paper.  Note that in landscape mode this is actually the height of
the bounding box.

Setting this sets L</paper> to "Custom" and the L</bounding_box> is
expanded to the full width.


=head2 Page Attributes

The following attributes can have a different value for every page.
You can't set them directly in the constructor, but they all have a
document-wide default value that each page inherits when it is created.
When accessing or setting them, C<$page> is the page label.  If
C<$page> is omitted, it defaults to the current page.


=head3 page_bounding_box

  ( $llx, $lly, $urx, $ury ) = $ps->get_page_bounding_box( [$page] )

  $ps->set_page_bounding_box( [$page,] $llx, $lly, $urx, $ury )

The bounding box for this page.  The lower left corner is
S<C<($llx, $lly)>>, and the upper right corner is S<C<($urx, $ury)>>.

Note that calling C<set_page_bounding_box> automatically enables
clipping for that page.  If this isn't what you want, call
C<< $ps->set_page_clipping(0) >> afterwards.

When a page is created, C<page_bounding_box> is initialized from the
document's L</bounding_box> attribute.


=head3 page_clipping

  $clipping = $ps->get_page_clipping( [$page] )

  $ps->set_page_clipping( [[$page,] $clipping] )

If C<$clipping> is true, printing will be clipped to this page's
bounding box. (Default: false)

When a page is created, C<page_clipping> is initialized from the
document's L</clipping> attribute.


=head3 page_label

  $ps = PostScript::File->new( page => $page )

  $page = $ps->get_page_label

  $ps->set_page_label( [$page] )

The label for the current page (used in the C<%%Page> comment).  (Default: "1")

Unlike the other page attributes, you can only access the C<page_label> of
the current page.  (Since pages are specified by label, it makes no
sense to ask for the label of a different page.)

When a page is created, C<page_label> is initialized by passing the
previous page's label to the L</incpage_handler>.  For the first page,
it's initialized from the C<page> given to the constructor.


=head3 page_landscape

  $landscape = $ps->get_page_landscape( [$page] )

  $ps->set_page_landscape( [[$page,] $landscape] )

If C<$landscape> is true, this page is using landscape mode. (Default:
false)

When a page is created, C<page_landscape> is initialized from the
document's L</landscape> attribute.

=head1 METHODS

Note: In the following descriptions, C<[]> are used to denote optional
parameters, I<not> array references.


=head2 Constructor


=head3 new

  $ps = PostScript::File->new(options)

Create a new PostScript::File object, either a set of pages or an Encapsulated PostScript (EPS) file. Options are
hash keys and values.  All values should be in the native PostScript units of 1/72 inch.

Example

    $ps = PostScript::File->new(
            eps       => 1,
            landscape => 1,
            width     => 216,
            height    => 288,
            left      => 36,
            right     => 44,
            clipping  => 1,
          );

This creates an Encapsulated PostScript document, 4 by 3 inch pages printing landscape with left and right margins of
around half an inch.  The width is always the shortest side, even in landscape mode.  3*72=216 and 4*72=288.
Being in landscape mode, these would be swapped.  The bounding box used for clipping would then be from
(50,0) to (244,216).

C<options> may be a single hash reference instead of an options list, but the hash must have the same structure.
This is more convenient when used as a base class.

The following keys are recognized options:

=head3 Attributes

The following attributes can be set through the constructor:
L</auto_hyphen>, L</clipping>, L</eps>, L</extensions>, L</file_ext>,
L</filename>, L</height>, L</incpage_handler>, L</landscape>,
L</langlevel>, L</order>, L</page_label>, L</paper>,
L<strip|/"strip (attribute)">, L</title>, L</version>, and L</width>.

=head3 File size keys

There are four options which control how much gets put into the resulting file.

=head4 debug

=over 6

=item C<undef>

No debug code is added to the file.  Of course there must be no calls
to debug functions in the PostScript code.  This is the default.

=item C<0>

B<db_> functions are replaced by dummy functions which do nothing.

=item C<1>

A range of functions are added to the file to support debugging PostScript.  This switch is similar to the 'C'
C<NDEBUG> macro in that debugging statements may be left in the PostScript code but their effect is removed.

Of course, being an interpreted language, it is not quite the same as the calls still takes up space - they just
do nothing.  See L</"POSTSCRIPT DEBUGGING SUPPORT"> for details of the functions.

=item C<2>

Loads the debug functions and gives some reassuring output at the start and a stack dump at the end of each page.

A mark is placed on the stack at the beginning of each page and 'cleartomark' is given at the end, avoiding
potential C<invalidrestore> errors.  Note, however, that if the page does not end with a clean stack, it will fail
when debugging is turned off.

=back

=head4 errors

PostScript has a nasty habit of failing silently. If C<errors> is
true, code that prints fatal error messages on the bottom left of the
paper is added to the file.  For user functions, a PostScript function
B<report_error> is defined.  This expects a message string on the
stack, which it prints before stopping.  (Default: true)

=head4 headings

If true, add PostScript DSC comments recording the date of creation and user's
name.  (Default: false)

The comments inserted when C<headings> is true are:

  %%For: USER@HOSTNAME
  %%Creator: Perl module PostScript::File v2.23
  %%CreationDate: Sun Jan  1 00:00:00 2012
  %%DocumentMedia: US-Letter 612 792 80 ( ) ( )

USER comes from C<getlogin() || getpwuid($<)>, and HOSTNAME comes from
L<Sys::Hostname>.  The DocumentMedia values come from the
L<paper size attributes|/"Paper Size and Margins">.  The
DocumentMedia comment is omitted from EPS files.

If you want different values, leave C<headings> false and use
L</add_comment> to add whatever you want.

=head4 reencode

Requests that a font re-encode function be added and that the fonts
used by this document get re-encoded in the specified encoding.
The only allowed values are C<cp1252>, C<iso-8859-1>, and
C<ISOLatin1Encoding>.  You should almost always set this to C<cp1252>,
even if you are not using Windows.

The list of fonts to re-encode comes from the L</need_fonts> parameter,
the L</need_resource> method, and all fonts added using L</embed_font>
or L</add_resource>.  The Symbol font is never re-encoded, because it
uses a non-standard character set.

Setting this to C<cp1252> or C<iso-8859-1> also causes the document to
be encoded in that character set.  Any strings you add to the document
that have the UTF-8 flag set will be re-encoded automatically.  Strings
that do not have the UTF-8 flag are expected to be in the correct
character set already.  This means that you should be able to set this
to C<cp1252>, use Unicode characters in your code and the "-iso"
versions of the fonts, and just have it do the right thing.

Windows code page 1252 (a.k.a. WinLatin1) is a superset of the printable
characters in ISO-8859-1 (a.k.a. Latin1).  It adds a number of characters
that are not in Latin1, especially common punctuation marks like the
curly quotation marks, en & em dashes, Euro sign, and ellipsis.  These
characters exist in the standard PostScript fonts, but there's no easy
way to access them when using the standard or ISOLatin1 encodings.
L<http://en.wikipedia.org/wiki/Windows-1252>

For backwards compatibility with versions of PostScript::File older
than 1.05, setting this to C<ISOLatin1Encoding> re-encodes the fonts,
but does not do any character set translation in the document.

=head3 Initialization keys

There are a few initialization settings that are only relevant when the file object is constructed.

=head4 bottom

The margin in from the paper's bottom edge, specifying the non-printable area.  Remember to specify C<clipping> if
that is what is wanted.  (Default: 28)

=head4 clip_command

The bounding box is used for clipping if this is set to "clip" or is drawn with "stroke".  This also makes the
whole page area available for debugging output.  (Default: "clip").

=head4 font_suffix

This string is appended to each font name as it is re-encoded.  (Default: "-iso")

The string value is appended to these to make the new names.

Example:

    $ps = PostScript::File->new(
            font_suffix => "-iso",
            reencode => "cp1252"
          );

"Courier" still has the standard mapping while "Courier-iso" includes the additional European characters.

=head4 left

The margin in from the paper's left edge, specifying the non-printable area.
Remember to specify C<clipping> if that is what is wanted.  (Default: 28)

=head4 need_fonts

An arrayref of font names required by this document.  This is
equivalent to calling C<< $ps->need_resource(font => @$arrayref) >>.
See L</need_resource> for details.

=head4 newpage

(v2.10) Normally, an initial page is created automatically (using the label
specified by C<page>).  But starting with PostScript::File 2.10, you
can pass S<C<< newpage => 0 >>> to override this.  This makes for more
natural loops:

    use PostScript::File 2.10;
    my $ps = PostScript::File->new(newpage => 0);
    for (@pages) {
      $ps->newpage;  # don't need "unless first page"
      ...
    }

It's important to require PostScript::File 2.10 if you do this, because
older versions would produce an initial blank page.

If you don't pass a page label to the first call to C<newpage>, it
will be taken from the C<page> option.  After the first page, the page
label will increment as specified by L</incpage_handler>.

=head4 right

The margin in from the paper's right edge.  It is a positive offset, so C<right=36> will leave a half inch no-go
margin on the right hand side of the page.  Remember to specify C<clipping> if that is what is wanted.  (Default: 28)

=head4 top

The margin in from the paper's top edge.  It is a positive offset, so C<top=36> will leave a half inch no-go
margin at the top of the page.  Remember to specify C<clipping> if that is what is wanted.  (Default: 28)

=head3 Debugging support keys

This makes most sense in the PostScript code rather than Perl.  However, it is convenient to be able to set
defaults for the output position and so on.  See L</"POSTSCRIPT DEBUGGING SUPPORT"> for further details.

=head4 db_active

Set to 0 to temporarily suppress the debug output.  (Default: 1)

=head4 db_base

Debug printing will not occur below this point.  (Default: 6)

=head4 db_bufsize

The size of string buffers used.  Output must be no longer than this.  (Default: 256)

=head4 db_color

This is the whole PostScript command (with any parameters) to specify the colour of the text printed by the debug
routines.  (Default: "0 setgray")

=head4 db_font

The name of the font to use.  (Default: "Courier")

    Courier
    Courier-Bold
    Courier-BoldOblique
    Courier-Oblique
    Helvetica
    Helvetica-Bold
    Helvetica-BoldOblique
    Helvetica-Oblique
    Times-Roman
    Times-Bold
    Times-BoldItalic
    Times-Italic
    Symbol

=head4 db_fontsize

The size of the font.  PostScript uses its own units, but they are almost points.  (Default: 10)

=head4 db_xgap

Typically, the output comprises single values such as a column showing the stack contents.  C<db_xgap> specifies
the width of each column.  By default, this is calculated to allow 4 columns across the page.

=head4 db_xpos

The left edge, where debug output starts.  (Default: 6)

=head4 db_xtab

The amount indented by C<db_indent>.  (Default: 10)

=head4 db_ytop

The top line of debugging output.  Defaults to 6 below the top of the page.

=head3 Error handling keys

If C<errors> is set, the position of any fatal error message can be controlled with the following options.  Each
value is placed into a PostScript variable of the same name, so they can be overridden from within the code if
necessary.

=head4 errfont

The name of the font used to show the error message.  (Default: "Courier-Bold")

=head4 errmsg

The error message comprises two lines.  The second is the name of the PostScript error.  This sets the first line.
(Default: "ERROR:")

=head4 errsize

Size of the error message font.  (Default: 12)

=head4 errx

X position of the error message on the page.  (Default: (72))

=head4 erry

Y position of the error message on the page.  (Default: (72))


=head2 Main Methods


=head3 newpage

  $ps->newpage( [$page] )

Generate a new PostScript page, unless in a EPS file when it is ignored.

If C<$page> is not specified the previous page's label is incremented
using the L</incpage_handler>.


=head3 output

  $ps->output( [$file, [$dir]] )

If C<$file> is an open filehandle, write the PostScript document to
that filehandle and return nothing.

If a filename has been given either here, to C<new>, or to
C<set_filename>, write the PostScript document to that file and return
its pathname.  (C<$file> and C<$dir> have the same meaning here as
they do in L<set_filename|/filename>.)

If no filename has been given, or C<$file> is undef, return the
PostScript document as a string.

In C<eps> mode, each page of the document becomes a separate EPS file.
In list context, returns a list of these files (either the pathname or
the PostScript code as explained above).  In scalar context, only the
first page is returned (but all pages will still be processed).  If
you pass a filehandle when you have multiple pages, all the documents
are written to that filehandle, which is probably not what you want.

Use this option whenever output is required to disk. The current PostScript document in memory is not cleared, and
can still be extended or output again.


=head3 as_string

  $postscript_code = $ps->as_string

This returns the PostScript document as a string.  It is equivalent to
C<< $ps->output(undef) >>.


=head3 testable_output

  $postscript_code = $ps->testable_output( [$verbatim] )

This returns the PostScript document as a string, but with the
PostScript::File generated code removed (unless C<$verbatim> is true).
This is intended for use in test scripts, so they won't see changes in
the output caused by different versions of PostScript::File.  The
PostScript code returned by this method will probably not work in a
PostScript interpreter.

If C<$verbatim> is true, this is equivalent to C<< $ps->output(undef) >>.


=head2 Access Methods

Use these C<get_> and C<set_> methods to access a PostScript::File object's data.


=head3 get_metrics

  $metrics = $ps->get_metrics( $font, [$size, [$encoding]] )

Construct a L<PostScript::File::Metrics> object for C<$font>.
The C<$encoding> is normally determined automatically from the font
name and the document's encoding.  The default C<$size> is 1000.

If this document uses L</reencode>, and the font ends with
L</font_suffix>, then the Metrics object will use that encoding.
Otherwise, the encoding is C<std> (except for the Symbol font, which
always uses C<sym>).

No matter what encoding the font uses, the Metrics object will always
use the same Unicode translation setting as this document.  It also
inherits the current value of the L</auto_hyphen> attribute.


=head3 set_min_langlevel

  $new_langlevel = $ps->set_min_langlevel( $langlevel )

(v2.20) Set the L</langlevel> attribute of this document to
C<$langlevel>, but only if the current level is less than
C<$langlevel>.  It returns the value of C<langlevel>, which will be
greater than or equal to C<$langlevel>.


=head3 set_page_margins

  $ps->set_page_margins( [$page,] $left, $bottom, $right, $top )

This sets the L</page_bounding_box> based on the paper size and the
specified margins.  It also automatically enables clipping for the
page.  If this isn't what you want, call C<< $ps->set_page_clipping(0) >>
afterwards.


=head3 get_page_printable_height

  $height = $ps->get_page_printable_height( [$page] )

(v2.10) Returns the height of the page's bounding box (S<C<ury - lly>>).


=head3 get_page_printable_width

  $width = $ps->get_page_printable_width( [$page] )

(v2.10) Returns the width of the page's bounding box (S<C<urx - llx>>.


=head3 get_page_variable

  $value = $ps->get_page_variable( $key )

Retrieve a user defined value previously assigned by L</set_page_variable>.


=head3 set_page_variable

  $ps->set_page_variable( $key, $value )

Assign a user defined hash key and value only valid on the current
page.  Provided to keep track of states within the PostScript code,
such as which styles are currently active.  PostScript::File does not
use this (except to clear it at the start of each page).  It is
recommended that C<$key> is the module name to avoid clashes.  The
C<$value> could then be a hash holding any number of user variables.


=head3 get_pagecount

  $pages = $ps->get_pagecount

Returns the number of pages currently in the document.


=head3 get_printable_height

  $height = $ps->get_printable_height

(v2.10) Returns the height of the document's bounding box (S<C<ury - lly>>).


=head3 get_printable_width

  $width = $ps->get_printable_width

(v2.10) Returns the width of the document's bounding box (S<C<urx - llx>>).


=head3 get_variable

  $value = $ps->get_variable( $key )

Retrieve a user defined value previously assigned by L</set_variable>.


=head3 set_variable

  $ps->set_variable( $key, $value )

Assign a user defined hash key and value.  Provided to keep track of
states within the PostScript code, such as which dictionaries are
currently open.  PostScript::File does not use this - it is provided
for client programs.  It is recommended that C<$key> is the module
name to avoid clashes.  The C<$value> could then be a hash holding any
number of user variables.


=head2 Content Methods


=head3 add_comment

  $ps->add_comment( $comment )

Append a comment to the document's DSC comments section.  Most of the
required and recommended comments are set directly from the document's
attributes, so this method should rarely be needed.  It is provided
for completeness so that comments not otherwise supported can be
added.  C<$comment> should contain the bare PostScript DSC name and
value, with additional lines merely prefixed by C<+>.  It should NOT
end with a newline.

Programs written for older versions of PostScript::File might use this
to add a C<DocumentNeededResources> comment.  That is now deprecated;
you should use L</need_resource> instead.

Examples:

    $ps->add_comment("ProofMode: NotifyMe");
    $ps->add_comment("Requirements: manualfeed");


=head3 get_comments

  $comments = $ps->get_comments

Retrieve any extra DSC comments added by L</add_comment>.


=head3 add_default

  $ps->add_default( $default )

Use this to append a PostScript DSC comment to the Defaults section.
These would be typically values like C<PageCustomColors:> or
C<PageRequirements:>.  The format is the same as for L</add_comment>.


=head3 get_defaults

  $comments = $ps->get_defaults

Returns the contents of the DSC Defaults section, if any.


=head3 embed_document

  $code = $ps->embed_document( $filename )

This reads the contents of C<$filename>, which should be a PostScript
file.  It returns a string with the contents of the file surrounded by
C<%%BeginDocument> and C<%%EndDocument> comments, and adds
C<$filename> to the list of document supplied resources.

You must pass the returned string to add_to_page or some other method
that will actually include it in the document.


=head3 embed_font

  $font_name = $ps->embed_font( $filename, [$type] )

This reads the contents of C<$filename>, which must contain a
PostScript font.  It calls L</add_resource> to add the font to the
document, and returns the name of the font (without a leading slash).

If C<$type> is omitted, the C<$filename>'s extension is used as the
type.  Type names are not case sensitive.  The currently supported
types are:

=over

=item PFA

A PostScript font in ASCII format

=item PFB

A PostScript font in binary format.  This requires the t1ascii program
from L<http://www.lcdf.org/type/#t1utils>.  (You can set
C<$PostScript::File::t1ascii> to the name of the program to use.  It
defaults to F<t1ascii>.)

=item TTF

A TrueType font.  This requires the ttftotype42 program from
L<http://www.lcdf.org/type/#typetools>.  (You can set
C<$PostScript::File::ttftotype42> to the name of the program to use.
It defaults to F<ttftotype42>.)

Since TrueType (a.k.a. Type42) font support was introduced in PostScript
level 2, embedding a TTF font automatically sets C<langlevel> to 2
(unless it was already set to a higher level).  Be aware that not all
printers can handle Type42 fonts.  (Even PostScript level 2 printers
need not support them.)  Ghostscript does support Type42 fonts (when
compiled with the C<ttfont> option).

=back


=head3 need_resource

  $ps->need_resource( $type, @resources )

This adds resources to the DocumentNeededResources comment.  C<$type>
is one of C<encoding>, C<file>, C<font>, C<form>, C<pattern>, or
C<procset> (case sensitive).

Any number of resources (of a single type) may be added in one call.
For most types, C<$resource[N]> is just the resource name.  But for
C<procset>, each element of C<@resources> should be an arrayref of 3 elements:
C<[$name, $version, $revision]>.  Names that contain special characters
such as spaces will be quoted automatically.

If C<need_resource> is never called for the C<font> type (and
L</need_fonts> is not used), it assumes the document requires all 13 of
the standard PostScript fonts: Courier, Courier-Bold,
Courier-BoldOblique, Courier-Oblique, Helvetica, Helvetica-Bold,
Helvetica-BoldOblique, Helvetica-Oblique, Times-Roman, Times-Bold,
Times-BoldItalic, Times-Italic, and Symbol.  But this behaviour is
deprecated; a document should explicitly list the fonts it requires.
If you don't use any of the standard fonts, pass S<C<< need_fonts => [] >>>
to the constructor (or call C<< $ps->need_resource('font') >>) to
indicate that.


=head3 add_to_page

  $ps->add_to_page( [$page,] $code )

This appends C<$code> to the specified C<$page>, which can be any page
label.  (Default: the current page)

If the specified C<$page> does not exist, a new page is added with
that label.  Note that this is added on the end, not in the order you
might expect.  So adding "vi" to page set "iii, iv, v, 6, 7, 8" would
create a new page after "8" not after "v".

Examples

    $ps->add_to_page( <<END_PAGE );
        ...PostScript building this page
    END_PAGE

    $ps->add_to_page( "3", <<END_PAGE );
        ...PostScript building page 3
    END_PAGE

The first example adds code onto the end of the current page.  The
second one either adds additional code to page 3 if it exists, or
starts a new one.


=head3 get_page

  $code = $ps->get_page( [$page] )

Returns the PostScript code from the body of the page.


=head3 add_page_setup

  $ps->add_page_setup( $code )

Appends C<$code> to the DSC PageSetup section.  Note that this is a
document-global value, although the code will be repeated on each
page.

Also note that any settings defined here will be active for each page
separately.  Use L</add_setup> if you want to carry settings from one
page to another.


=head3 get_page_setup

  $setup = $ps->get_page_setup

Returns the contents of the DSC PageSetup section, if any.  Note that
this is a document-global value, although the code will be repeated on
each page.


=head3 add_page_trailer

  $ps->add_page_trailer( $code )

Appends C<$code> to the DSC PageTrailer section.  Note that this is a
document-global value, although the code will be repeated on each
page.

Code added here is output after each page.  It may refer to settings
made during L</add_page_setup> or L</add_to_page>.


=head3 get_page_trailer

  $code = $ps->get_page_trailer

Returns the contents of the DSC PageTrailer section, if any.  Note that
this is a document-global value, although the code will be repeated on
each page.


=head3 add_preview

  $ps->add_preview( $width, $height, $depth, $lines, $preview )

Sets the EPSI format preview for this document - an ASCII
representation of a bitmap.  Only EPS files should have a preview, but
that is not enforced.  If an EPS file has a preview it becomes an EPSI
file rather than EPSF.


=head3 get_preview

  $preview = $ps->get_preview

Returns the EPSI preview of the document, if any, including the
C<%%BeginPreview> and C<%%EndPreview> comments.


=head3 add_procset

  $ps->add_procset( $name, $code, [$version, [$revision]] )

(v2.20) Add a ProcSet containing user defined functions to the PostScript
prolog.  C<$name> is an arbitrary identifier of this resource.  C<$code>
is a block of PostScript code, usually from a 'here' document.  If the
document already contains ProcSet C<$name> (as reported by
C<has_procset>, then C<add_procset> does nothing.

C<$version> is a real number, and C<$revision> is an unsigned integer.
They both default to 0.  PostScript::File does not make any use of
these, but a PostScript document manager may assume that a procset
with a higher revision number may be substituted for a procset with
the same name and version but a lower revision.

Returns true if the ProcSet was added, or false if it already existed.

Example

    $ps->add_procset( "My_Functions", <<END_FUNCTIONS );
        % PostScript code can be freely indented
        % as leading spaces and blank lines
        % (and comments, if desired) are stripped

        % foo does this...
        /foo {
            ... definition of foo
        } bind def

        % bar does that...
        /bar {
            ... definition of bar
        } bind def
    END_FUNCTIONS

Note that C<get_procsets> (in common with the others) will return I<all> user defined functions possibly
including those added by other classes.


=head3 has_procset

  $exists = $ps->has_procset( $name )

(v2.20) This returns true if C<$name> has already been included in the
file.  The name should be identical to that given to
L</add_procset>.

=for Pod::Coverage
add_function
get_functions
has_function


=head3 get_procsets

  $code = $ps->get_procsets

(v2.20) Return all the procsets defined in this document.


=head3 add_resource

  $ps->add_resource( $type, $name, $params, $resource )

=over 4

=item C<$type>

A string indicating the DSC type of the resource.  It should be one of
C<Document>, C<Feature>, C<encoding>, C<file>, C<font>, C<form>, or
C<pattern> (case sensitive).

=item C<$name>

An arbitrary identifier of this resource.  (For a Font, it must be the
PostScript name of the font, without a leading slash.)

=item C<$params>

Some resource types require parameters.  See the Adobe documentation for details.

=item C<$resource>

A string containing the PostScript code. Probably best provided a 'here' document.

=back

Use this to add fonts or images (although you may prefer L</embed_font>
or L</embed_document>).  L</add_procset> is provided for functions.

Example

    $ps->add_resource( "File", "My_File1",
                       "", <<END_FILE1 );
        ...PostScript resource definition
    END_FILE1


=head3 get_resources

  $resources = $ps->get_resources

Returns all resources provided by this document.  This does not
include procsets.


=head3 add_setup

 $ps->add_setup( $code )

This appends C<$code> to the DSC Setup section.  Use this for
C<setpagedevice>, C<statusdict> or other settings that initialize the
device or document.


=head3 get_setup

  $setup = $ps->get_setup

Returns the contents of the DSC Setup section, if any.


=head3 add_trailer

  $ps->add_trailer( $code )

Appends C<$code> to the document's DSC Trailer section.  Use this for
any tidying up after all the pages are output.


=head3 get_trailer

  $code = $ps->get_trailer

Returns the contents of the document's DSC Trailer section, if any.


=head3 use_functions

  $ps->use_functions( @function_names )

This requests that the PostScript functions listed in
C<@function_names> be included in this document.  See
L<PostScript::File::Functions> for a list of available functions.


=head2 Text Processing Methods



=head3 convert_hyphens

  $converted_text = $ps->convert_hyphens( $text )

Converts any HYPHEN-MINUS (U+002D) characters in C<$text> to either
HYPHEN (U+2010) or MINUS SIGN (U+2212) according to the rules
described in L</"Hyphens and Minus Signs">.  This has the side-effect
of setting the UTF-8 flag on C<$converted_text>.

If C<$text> does not have the UTF-8 flag set, it is assumed to be in
the document's character encoding.

If C<$text> does not contain any HYPHEN-MINUS characters, it is
returned as-is.


=head3 decode_text

  $text = $ps->decode_text( $encoded_text, [$preserve_minus] )

This is the inverse of L</encode_text>.  It converts C<$encoded_text>
from the document's character encoding into Unicode.  If
C<$encoded_text> already has the UTF-8 flag set, or the document is
not using character translation, then it returns C<$encoded_text>
as-is.

If the optional argument C<$preserve_minus> is true (and
C<$encoded_text> is not being returned as-is), then any HYPHEN-MINUS
(U+002D) characters in C<$encoded_text> are decoded as MINUS SIGN
(U+2212).  This ensures that C<encode_text> will treat them as minus
signs instead of hyphens.


=head3 encode_text

  $encoded_text = $ps->encode_text( $text )

This returns C<$text> converted to the document's character encoding.
If C<$text> does not have the UTF-8 flag set, or the document is not
using character translation, then it returns C<$text> as-is.


=head3 pstr

  $code = $ps->pstr( $string, [$nowrap] )

  $code = PostScript::File->pstr( $string, [$nowrap] )

  $code = pstr( $string )

Converts the string to a PostScript string literal.  If the result is
more than 240 characters, it will be broken into multiple lines.  (A
PostScript file should not contain lines with more than 255
characters.)

When called as a class or object method,
you can pass a second parameter C<$nowrap>.  If this optional parameter
is true, then the string will not be wrapped, no matter how long it is.

When called as an object method, C<pstr> will do automatic
hyphen-minus translation if L</auto_hyphen> is true.  This has the
side-effect of setting the UTF-8 flag on the returned string.  (If the
UTF-8 flag was not set on the input string, it will be decoded using
the document's character set.)  See L</"Hyphens and Minus Signs">.
For this reason, C<pstr> should normally be called as an object method.


=head3 strip (method)

  $ps->strip( $code )

  $ps->strip( $strip => @code )

The C<strip> method filters PostScript code according to the value of
C<$strip>, which can be any valid value for the L<strip|/"strip (attribute)">
attribute.  The code is modified in-place; there is no return value.
If C<$code> is C<undef>, it is left unchanged.

When called with a single argument, strips C<$code> according to the
current value of the C<strip> attribute.

=head1 SUBROUTINES

=head2 array_as_string

  $code = array_as_string( @array )

Converts a Perl array to a PostScript array literal.  The array
elements are used as-is.  If you want an array of strings, you should
do something like:

  $code = array_as_string( map { $ps->pstr($_) } @array )


=head2 check_file

  $pathname = check_file( $file, [$dir, [$create]] )

=over 4

=item C<$file>

An optional fully qualified path-and-file or a simple file name. If
omitted or the empty string, the special file C<< File::Spec->devnull >>
is returned.

=item C<$dir>

An optional directory path.  If defined (and C<$file> is not already
an absolute path), it is prepended to C<$file>.

=item C<$create>

If true, create the file if it doesn't exist already.  (Default: false)

=back

This converts a filename and optional directory to an absolute path,
and then creates any directories that don't already exist.  Any
leading C<~> is expanded to the user's home directory using
L</check_tilde>.

If C<$create> is true, and C<$pathname> does not exist, it is created
as an empty file.

L<File::Spec> is used throughout so file access should be portable.


=head2 check_tilde

  $expanded_path = check_tilde( $path )

Expands a leading C<~> or C<~user> in C<$path> to the home directory.


=head2 incpage_label

  $next_label = incpage_label( $label )

This function applies Perl's autoincrement operator to C<$label> and
returns the result.  (This means that the magic string autoincrement
applies to values that match C</^[a-zA-Z]*[0-9]*\z/>.)

This function is the default value of the L</incpage_handler> attribute.


=head2 incpage_roman

  $next_label = incpage_roman( $label )

This function increments lower case Roman numerals.  C<$label> must be
a value between "i" and "xxxviii" (1 to 38), and C<$next_label> will
be "ii" to "xxxix" (2 to 39).  That should be quite enough for
numbering the odd preface.

This function is normally used as the value of the L</incpage_handler>
attribute:

  $ps->set_incpage_handler( \&PostScript::File::incpage_roman )


=head2 quote_text

  $quoted = quote_text( $string )

  $quoted = PostScript::File->quote_text( $string )

  $quoted = $ps->quote_text( $string )

Quotes the string if it contains special characters, making it
suitable for a DSC comment.  Strings without special characters are
returned unchanged.

This may also be called as a class or object method, but it does not
do hyphen-minus translation, even if L</auto_hyphen> is true.


=head2 str

  $code = str( $value )

If C<$value> is an arrayref, returns C<array_as_string(@$value)>.
Otherwise, returns C<$value> as-is.  This function was designed to
simplify passing colors to the PostScript function
L<PostScript::File::Functions/setColor>, which expects either an RGB
array or a greyscale decimal.

=head1 POSTSCRIPT DEBUGGING SUPPORT

This section documents the PostScript functions which provide debugging output.  Please note that any clipping or
bounding boxes will also hide the debugging output which by default starts at the top left of the page.  Typical
C<new> options required for debugging would include the following.

    $ps = PostScript::File->new (
            errors => "page",
            debug => 2,
            clipcmd => "stroke" );

The debugging output is printed on the page being drawn.  In practice this works fine, especially as it is
possible to move the output around.  Where the text appears is controlled by a number of PostScript variables,
most of which may also be given as options to C<new>.

The main controller is C<db_active> which needs to be non-zero for any output to be seen.  It might be useful to
set this to 0 in C<new>, then at some point in your code enable it.  Remember that the C<debugdict> dictionary
needs to be selected in order for any of its variables to be changed.  This is better done with C<db_on> but it
illustrates the point.

    /debugdict begin
        /db_active 1 def
    end
    (this will now show) db_show

At any time, the next output will appear at C<db_xpos> and C<db_ypos>.  These can of course be set directly.
However, after most prints, the equivalent of a 'newline' is executed.  It moves down C<db_fontsize> and left to
C<db_xpos>.  If, however, that would take it below C<db_ybase>, C<db_ypos> is reset to C<db_ytop> and the
x coordinate will have C<db_xgap> added to it, starting a new column.

The positioning of the debug output is changed by setting C<db_xpos> and C<db_ytop> to the top left starting
position, with C<db_ybase> guarding the bottom.  Extending to the right is controlled by not printing too much!
Judicious use of C<db_active> can help there.

=head2 PostScript functions

=head3 x0 y0 x1 y1 B<cliptobox>

This function is only available if 'clipping' is set.  By calling the Perl method C<draw_bounding_box> (and
resetting with C<clip_bounding_box>) it is possible to use this to identify areas on the page.

    $ps->draw_bounding_box();
    $ps->add_to_page( <<END_CODE );
        ...
        my_l my_b my_r my_t cliptobox
        ...
    END_CODE
    $ps->clip_bounding_box();

=head3 msg B<report_error>

If 'errors' is enabled, this call allows you to report a fatal error from within your PostScript code.  It expects
a string on the stack and it does not return.

All the C<db_> variables (including function names) are defined within their own dictionary (C<debugdict>).  But
this can be ignored by all calls originating from within code passed to C<add_to_page> (usually including
C<add_procset> code) as the dictionary is automatically put on the stack before each page and taken off as each
finishes.

=head3 any B<db_show>

The workhorse of the system.  This takes the item off the top of the stack and outputs a string representation of
it.  So you can call it on numbers or strings and it will show them.  Arrays are printed using C<db_array> and
marks are shown as '--mark--'.

=head3 n msg B<db_nshow>

This shows top C<n> items on the stack.  It requires a number and a string on the stack, which it removes.  It
prints out C<msg> then the top C<n> items on the stack, assuming there are that many.  It can be used to do
a labelled stack dump.  Note that if C<new> was given the option C<debug => 2>, There will always be a '--mark--'
entry at the base of the stack.  See L</debug>.

    count (at this point) db_nshow

=head3 B<db_stack>

Prints out the contents of the stack.  No stack requirements.

The stack contents is printed top first, the last item printed is the lowest one inspected.

=head3 array B<db_print>

The closest this module has to a print statement.  It takes an array of strings and/or numbers off the top of the
stack and prints them with a space in between each item.

    [ (myvar1=) myvar1 (str2=) str2 ] db_print

will print something like the following.

    myvar= 23.4 str2= abc

When printing something from the stack you need to take into account the array-building items, too.  In the next
example, at the point '2 index' fetches 111, the stack holds '222 111 [ (top=)' but 'index' requires 5 to get at
222 because the stack now holds '222 111 [ (top=) 111 (next=)'.

    222 111
    [ (top=) 2 index (next=) 5 index ] db_print

willl output this.

    top= 111 next= 222

It is important that the output does not exceed the string buffer size.  The default is 256, but it can be changed
by giving C<new> the option C<bufsize>.

=head3 x y msg B<db_point>

It is common to have coordinates as the top two items on the stack.  This call inspects them.  It pops the message
off the stack, leaving x and y in place, then prints all three.

    450 666
    (starting point=) db_print
    moveto

would produce:

    starting point= ( 450 , 666 )

=head3 array B<db_array>

Like L</db_print> but the array is printed enclosed within square brackets.

=head3 var B<db_where>

A 'where' search is made to find the dictionary containing C<var>.  The messages 'found' or 'not found' are output
accordingly.  Of course, C<var> should be quoted with '/' to put the name on the stack, otherwise it will either
be executed or force an error.

=head3 B<db_newcol>

Starts the next debugging column.  No stack requirements.

=head3 B<db_on>

Enable debug output

=head3 B<db_off>

Disable debug output

=head3 B<db_down>

Does a 'carriage-return, line-feed'.  No stack requirements.

=head3 B<db_indent>

Moves output right by C<db_xtab>.  No stack requirements.  Useful for indenting output within loops.

=head3 B<db_unindent>

Moves output left by C<db_xtab>.  No stack requirements.

=for Pod::Coverage
clip_bounding_box
draw_bounding_box

=head1 EXPORTS

No functions are exported by default.  All the functions listed in
L</SUBROUTINES> may be exported by request.

In addition, the C<pstr> method may be exported as a subroutine, but
this usage is deprecated.

=head1 BUGS AND LIMITATIONS

When making EPS files, the landscape transformation throws the coordinates off.  To work around this, avoid the
landscape flag and set width and height differently.

Most of these functions have only had a couple of tests, so please feel free to report all you find.

=head1 AUTHOR

Chris Willmot   S<C<< <chris AT willmot.co.uk> >>>

Thanks to Johan Vromans for the ISOLatin1Encoding.

As of September 2009, PostScript::File is now being maintained by
Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>.

Please report any bugs or feature requests to
S<C<< <bug-PostScript-File AT rt.cpan.org> >>>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-File>

You can follow or contribute to PostScript::File's development at
L<https://github.com/madsen/postscript-file>.

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2003 Christopher P Willmot.  All rights reserved.

Copyright 2015 Christopher J. Madsen. All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

I<PostScript Language Document Structuring Conventions Specification
Version 3.0> and I<Encapsulated PostScript File Format Specification
Version 3.0> published by Adobe, 1992.
L<http://partners.adobe.com/asn/developer/technotes/postscript.html>

L<PostScript::Convert>, for PDF or PNG output.

L<PostScript::Calendar>, for creating monthly calendars.

L<PostScript::Report>, for creating tabular reports.

L<PostScript::ScheduleGrid>, for printing schedules in a grid format.

L<PostScript::ScheduleGrid::XMLTV>, for printing TV listings in a grid format.

L<PostScript::Graph::Paper>,
L<PostScript::Graph::Style>,
L<PostScript::Graph::Key>,
L<PostScript::Graph::XY>,
L<PostScript::Graph::Bar>,
L<PostScript::Graph::Stock>.



=for Pod::Coverage
get_auto_hyphen
get_bounding_box
get_clipping
get_eps
get_extensions
get_file_ext
get_filename
get_height
get_incpage_handler
get_landscape
get_langlevel
get_order
get_page_bounding_box
get_page_clipping
get_page_label
get_page_landscape
get_paper
get_strip
get_title
get_version
get_width
set_auto_hyphen
set_bounding_box
set_clipping
set_file_ext
set_filename
set_height
set_incpage_handler
set_landscape
set_page_bounding_box
set_page_clipping
set_page_label
set_page_landscape
set_paper
set_strip
set_width

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
