# Pod::Dsr -- Convert POD data to formatted Digital Standard Runoff input.
# $Id: Dsr.pm,v 0.01 2001/01/16 13:39:45 pvhp Exp $
#
# Copyright 2001 by Peter Prymmer <pvhp@best.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# This module uses Pod::Parser and is designed to be easy
# to subclass.
#
# Based upon: Pod::Man 1.14 by Russ Allbery

############################################################################
# Modules and declarations
############################################################################

package Pod::Dsr;

require 5.004;

use Carp qw(carp croak);
use Pod::Parser ();

use strict;
use subs qw(makespace);
use vars qw(@ISA %ESCAPES $PREAMBLE $VERSION);

@ISA = qw(Pod::Parser);

# Don't use the CVS revision as the version, since this module is also in
# Perl core and too many things could munge CVS magic revision strings.
# This number should ideally be the same as the CVS revision in podlators,
# however.
$VERSION = 0.01;


############################################################################
# Preamble and *roff output tables
############################################################################

# The following is the static preamble which starts all dsr output we
# generate.  It's completely static except for the .LAYOUT to use,
# designated by @LAYOUT@.  Hence, $PREAMBLE should therefore be run 
# through s/\@LAYOUT\@/.LAYOUT $n1,$n2/g before output.

$PREAMBLE = <<'----END OF PREAMBLE----';
@LAYOUT@
.! We need .CONTROL CHARACTERS in order to accept 255 (also 0-31,127-159).
.CONTROL CHARACTERS
.! The % character can often appear in documentation.
.DISABLE OVERSTRIKING
.! Turn on ^*bold\* recognition
.FLAGS BOLD
.! and ^&underlining\& (for italics)
.FLAGS UNDERLINE
----END OF PREAMBLE----

# This table is adapted from Tom Christiansen's pod2man.  It
# assumes that _ can be used as the accept character, and that 
# eight bit Latin-1 characters (derived from the DEC Multnational
# Character Set) are acceptable to your version of runoff.
%ESCAPES = (
    'amp'       =>    '_&',  # ampersand
    'lt'        =>    '_<',  # left chevron "angle bracket", less-than
    'gt'        =>    '_>',  # right chevron "angle bracket", greater-than
    'quot'      =>    '"',   # double quotation mark
    'sol'       =>    '/',   # solidus (forward slash)
    'verbar'    =>    '_|',  # vertical bar

    'Aacute'    =>    'Á',   # capital A, acute accent
    'aacute'    =>    'á',   # small a, acute accent
    'Acirc'     =>    'Â',   # capital A, circumflex accent
    'acirc'     =>    'â',   # small a, circumflex accent
    'AElig'     =>    'Æ',   # capital AE diphthong (ligature)
    'aelig'     =>    'æ',   # small ae diphthong (ligature)
    'Agrave'    =>    'À',   # capital A, grave accent
    'agrave'    =>    'à',   # small a, grave accent
    'Aring'     =>    'Å',   # capital A, ring
    'aring'     =>    'å',   # small a, ring
    'Atilde'    =>    'Ã',   # capital A, tilde
    'atilde'    =>    'ã',   # small a, tilde
    'Auml'      =>    'Ä',   # capital A, dieresis or umlaut mark
    'auml'      =>    'ä',   # small a, dieresis or umlaut mark
    'Ccedil'    =>    'Ç',   # capital C, cedilla
    'ccedil'    =>    'ç',   # small c, cedilla
    'Eacute'    =>    'É',   # capital E, acute accent
    'eacute'    =>    'é',   # small e, acute accent
    'Ecirc'     =>    'Ê',   # capital E, circumflex accent
    'ecirc'     =>    'ê',   # small e, circumflex accent
    'Egrave'    =>    'È',   # capital E, grave accent
    'egrave'    =>    'è',   # small e, grave accent
    'ETH'       =>    'Ð',   # capital Eth, Icelandic
    'eth'       =>    'ð',   # small eth, Icelandic
    'Euml'      =>    'Ë',   # capital E, dieresis or umlaut mark
    'euml'      =>    'ë',   # small e, dieresis or umlaut mark
    'Iacute'    =>    'Í',   # capital I, acute accent
    'iacute'    =>    'í',   # small i, acute accent
    'Icirc'     =>    'Î',   # capital I, circumflex accent
    'icirc'     =>    'î',   # small i, circumflex accent
    'Igrave'    =>    'Ì',   # capital I, grave accent
    'igrave'    =>    'ì',   # small i, grave accent
    'Iuml'      =>    'Ï',   # capital I, dieresis or umlaut mark
    'iuml'      =>    'ï',   # small i, dieresis or umlaut mark
    'Ntilde'    =>    'Ñ',   # capital N, tilde
    'ntilde'    =>    'ñ',   # small n, tilde
    'Oacute'    =>    'Ó',   # capital O, acute accent
    'oacute'    =>    'ó',   # small o, acute accent
    'Ocirc'     =>    'Ô',   # capital O, circumflex accent
    'ocirc'     =>    'ô',   # small o, circumflex accent
    'Ograve'    =>    'Ò',   # capital O, grave accent
    'ograve'    =>    'ò',   # small o, grave accent
    'Oslash'    =>    'Ø',   # capital O, slash
    'oslash'    =>    'ø',   # small o, slash
    'Otilde'    =>    'Õ',   # capital O, tilde
    'otilde'    =>    'õ',   # small o, tilde
    'Ouml'      =>    'Ö',   # capital O, dieresis or umlaut mark
    'ouml'      =>    'ö',   # small o, dieresis or umlaut mark
    'szlig'     =>    'ß',   # small sharp s, German (sz ligature)
    'THORN'     =>    'Þ',   # capital THORN, Icelandic
    'thorn'     =>    'þ',   # small thorn, Icelandic
    'Uacute'    =>    'Ú',   # capital U, acute accent
    'uacute'    =>    'ú',   # small u, acute accent
    'Ucirc'     =>    'Û',   # capital U, circumflex accent
    'ucirc'     =>    'û',   # small u, circumflex accent
    'Ugrave'    =>    'Ù',   # capital U, grave accent
    'ugrave'    =>    'ù',   # small u, grave accent
    'Uuml'      =>    'Ü',   # capital U, dieresis or umlaut mark
    'uuml'      =>    'ü',   # small u, dieresis or umlaut mark
    'Yacute'    =>    'Ý',   # capital Y, acute accent
    'yacute'    =>    'ý',   # small y, acute accent
    'yuml'      =>    'ÿ',   # small y, dieresis or umlaut mark
);


############################################################################
# Static helper functions
############################################################################

# Protect leading periods against interpretation as commands.
# Also protect flags:
# _ Accept
# * Bold
# | Break
# < Capitolize
# ! Comment
# . Control, DSR command
# = Hyphenate
# > Index
# \ Lowercase
# % Overstrike
# + Period
# # Space
# > Subindex
# $$ Substitute
# & Underline
# ^ Uppercase next char
sub protect {
    local $_ = shift;
#    s/^([.\*\|\<!=\>\\\%+\#\^])/_$1/mg;
    s/^([.])/_$1/mg;
    $_;
}

# Translate a font string into an escape.
sub toescape { 
#    (length ($_[0]) > 1 ? '\f(' : '\f') . $_[0] 
    return(@_);
}


############################################################################
# Initialization
############################################################################

# Initialize the object.  Here, we also process any additional options
# passed to the constructor or set up defaults if none were given.  center
# is the centered title, release is the version number, and date is the date
# for the documentation.  Note that we can't know what file name we're
# processing due to the architecture of Pod::Parser, so that *has* to either
# be passed to the constructor or set separately with Pod::Dsr::name().
sub initialize {
    my $self = shift;

    # Figure out the fixed-width font.  If user-supplied, make sure that
    # they are the right length.
    for (qw/chapter layout fixed fixedbold fixeditalic fixedbolditalic/) {
        if (defined $$self{$_}) {
            if (length ($$self{$_}) < 1 || length ($$self{$_}) > 2) {
               # croak qq(roff font should be 1 or 2 chars,)
               #     . qq( not "$$self{$_}");
            }
        } else {
            $$self{$_} = '';
        }
    }

    # Set the default .LAYOUT.
    $$self{layout}          ||= '.LAYOUT 0';

    # Set the default .CHAPTER.
#    $$self{chapter}          ||= '';

    # Set the default fonts.  We can't be sure what fixed bold-italic is
    # going to be called, so default to just bold.
    $$self{fixed}           ||= 'CW';
    $$self{fixedbold}       ||= 'CB';
    $$self{fixeditalic}     ||= 'CI';
    $$self{fixedbolditalic} ||= 'CB';

    # Set up a table of font escapes.  First number is fixed-width, second
    # is bold, third is italic.
    $$self{FONTS} = { '000' => '\fR', '001' => '\fI',
                      '010' => '\fB', '011' => '\f(BI',
                      '100' => toescape ($$self{fixed}),
                      '101' => toescape ($$self{fixeditalic}),
                      '110' => toescape ($$self{fixedbold}),
                      '111' => toescape ($$self{fixedbolditalic})};

    # Extra stuff for page titles.
    $$self{center} = 'User Contributed Perl Documentation'
        unless defined $$self{center};
    $$self{indent}  = 4 unless defined $$self{indent};

    # We used to try first to get the version number from a local binary,
    # but we shouldn't need that any more.  Get the version from the running
    # Perl.  Work a little magic to handle subversions correctly under both
    # the pre-5.6 and the post-5.6 version numbering schemes.
    if (!defined $$self{release}) {
        my @version = ($] =~ /^(\d+)\.(\d{3})(\d{0,3})$/);
        $version[2] ||= 0;
        $version[2] *= 10 ** (3 - length $version[2]);
        for (@version) { $_ += 0 }
        $$self{release} = 'perl v' . join ('.', @version);
    }

    # Double quotes in things that will be quoted.
    #for (qw/center date release/) {
    #    $$self{$_} =~ s/\"/\"\"/g if $$self{$_};
    #}

    # Figure out what quotes we'll be using for C<> text.
    $$self{quotes} ||= '"';
    if ($$self{quotes} eq 'none') {
        $$self{LQUOTE} = $$self{RQUOTE} = '';
    } elsif (length ($$self{quotes}) == 1) {
        $$self{LQUOTE} = $$self{RQUOTE} = $$self{quotes};
    } elsif ($$self{quotes} =~ /^(.)(.)$/
             || $$self{quotes} =~ /^(..)(..)$/) {
        $$self{LQUOTE} = $1;
        $$self{RQUOTE} = $2;
    } else {
        croak qq(Invalid quote specification "$$self{quotes}");
    }

    # Double the first quote; note that this should not be s///g as two
    # double quotes is represented in *roff as three double quotes, not
    # four.  Weird, I know.
    $$self{LQUOTE} =~ s/\"/\"\"/;
    $$self{RQUOTE} =~ s/\"/\"\"/;

    $$self{INDENT}  = 0;        # Current indentation level.
    $$self{INDENTS} = [];       # Stack of indentations.
    $$self{INDEX}   = [];       # Index keys waiting to be printed.
    $$self{ITEMS}   = 0;        # The number of consecutive =items.

    $self->SUPER::initialize;
}

# For each document we process, output the preamble first.
sub begin_pod {
    my $self = shift;

    # Try to figure out the name and section from the file name.
    my $section = $$self{section} || 1;
    my $name = $$self{name};
    if (!defined $name) {
        $name = $self->input_file;
        $section = 3 if (!$$self{section} && $name =~ /\.pm\z/i);
        $name =~ s/\.p(od|[lm])\z//i;
        if ($section =~ /^1/) {
            require File::Basename;
            $name = uc File::Basename::basename ($name);
        } else {
            # Lose everything up to the first of
            #     */lib/*perl*      standard or site_perl module
            #     */*perl*/lib      from -D prefix=/opt/perl
            #     */*perl*/         random module hierarchy
            # which works.  Should be fixed to use File::Spec.  Also handle
            # a leading lib/ since that's what ExtUtils::MakeMaker creates.
            for ($name) {
                s%//+%/%g;
                if (     s%^.*?/lib/[^/]*perl[^/]*/%%si
                      or s%^.*?/[^/]*perl[^/]*/(?:lib/)?%%si) {
                    s%^site(_perl)?/%%s;      # site and site_perl
                    s%^(.*-$^O|$^O-.*)/%%so;  # arch
                    s%^\d+\.\d+%%s;           # version
                }
                s%^lib/%%;
                s%/%::%g;
            }
        }
    }

    # If $name contains spaces, quote it; this mostly comes up in the case
    # of input from stdin.
    $name = '"' . $name . '"' if ($name =~ /\s/);

    # Modification date header.  Try to use the modification time of our
    # input.
    # Note that DSR .DATE and $$ are for appearence in text, whereas
    # this date may appear in .! comments.
    if (!defined $$self{date}) {
        my $time = (stat $self->input_file)[9] || time;
        my ($day, $month, $year) = (localtime $time)[3,4,5];
     #   $month++;
        $month = ('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','NOV','DEC')[$month];
        $year += 1900;
     #   $$self{date} = sprintf ('%4d-%02d-%02d', $year, $month, $day);
        $$self{date} = sprintf ('%02d-%s-%4d', $day, $month, $year);
    }

    # Now, print out the preamble and the title.
    local $_ = $PREAMBLE;
    s/\@LAYOUT\@/$$self{layout}/;
#    s/\@CFONT\@/$$self{fixed}/;
#    s/\@LQUOTE\@/$$self{LQUOTE}/;
#    s/\@RQUOTE\@/$$self{RQUOTE}/;
    chomp $_;
    print { $self->output_handle } <<"----END OF HEADER----";
.! Automatically generated by Pod::Dsr version $VERSION
.! @{[ scalar localtime ]}
.!
.! Standard preamble:
.! ======================================================================
$_
.! ======================================================================
.!
.INDEX $name
.TITLE $name
.SUBTITLE "$$self{release}" "$$self{date}" "$$self{center}"
----END OF HEADER----
#"# for cperl-mode
    my $chapter = $$self{chapter};
    if ($chapter =~ /\d/) {
        print { $self->output_handle } <<"----END OF CHAPTER----";
.NUMBER CHAPTER $chapter
.CHAPTER $name
----END OF CHAPTER----
#"# for cperl-mode
    }
# .INDEX is probably preferable to .ENTRY here.  Did we want $name>$section?
# Did we want .FIRST TITLE or instead ?
# What to do with $section ?

    # Initialize a few per-file variables.
    $$self{INDENT} = 0;
    $$self{NEEDSPACE} = 0;
}


############################################################################
# Core overrides
############################################################################

# Called for each command paragraph.  Gets the command, the associated
# paragraph, the line number, and a Pod::Paragraph object.  Just dispatches
# the command to a method named the same as the command.  =cut is handled
# internally by Pod::Parser.
sub command {
    my $self = shift;
    my $command = shift;
    return if $command eq 'pod';
    return if ($$self{EXCLUDE} && $command ne 'end');
    if ($self->can ('cmd_' . $command)) {
        $command = 'cmd_' . $command;
        $self->$command (@_);
     } else {
        my ($text, $line, $paragraph) = @_;
        my $file;
        ($file, $line) = $paragraph->file_line;
        $text =~ s/\n+\z//;
        $text = " $text" if ($text =~ /^\S/);
        warn qq($file:$line: Unknown command paragraph "=$command$text"\n);
        return;
    }
}

# Called for a verbatim paragraph.  Gets the paragraph, the line number, and
# a Pod::Paragraph object.  Rofficate backslashes, untabify, put a
# zero-width character at the beginning of each line to protect against
# commands, and wrap in .LITERAL/.END LITERAL.
sub verbatim {
    my $self = shift;
    return if $$self{EXCLUDE};
    local $_ = shift;
    return if /^\s+$/;
    s/\s+$/\n/;
#    my $lines = tr/\n/\n/;
##    1 while s/^(.*?)(\t+)/$1 . ' ' x (length ($2) * 8 - length ($1) % 8)/me;
#    s/\\/\\e/g;
#    s/^(\s*\S)/'\&' . $1/gme;
    $self->makespace;
    $self->output (".LITERAL\n$_.END LITERAL\n");
    $$self{NEEDSPACE} = 0;
}

# Called for a regular text block.  Gets the paragraph, the line number, and
# a Pod::Paragraph object.  Perform interpolation and output the results.
sub textblock {
    my $self = shift;
    return if $$self{EXCLUDE};
    $self->output ($_[0]), return if $$self{VERBATIM};

    # Perform a little magic to collapse multiple L<> references.  We'll
    # just rewrite the whole thing into actual text at this part, bypassing
    # the whole internal sequence parsing thing.
    my $text = shift;
    $text =~ s{
        (L<                     # A link of the form L</something>.
              /
              (
                  [:\w]+        # The item has to be a simple word...
                  (\(\))?       # ...or simple function.
              )
          >
          (
              ,?\s+(and\s+)?    # Allow lots of them, conjuncted.
              L<
                  /
                  ( [:\w]+ ( \(\) )? )
              >
          )+
        )
    } {
        local $_ = $1;
        s{ L< / ( [^>]+ ) > } {$1}xg;
        my @items = split /(?:,?\s+(?:and\s+)?)/;
        my $string = 'the ';
        my $i;
        for ($i = 0; $i < @items; $i++) {
            $string .= $items[$i];
            $string .= ', ' if @items > 2 && $i != $#items;
            $string .= ' ' if @items == 2 && $i == 2;
            $string .= 'and ' if ($i == $#items - 1);
        }
        $string .= ' entries elsewhere in this document';
        $string;
    }gex;

    # Parse the tree and output it.  collapse knows about references to
    # scalars as well as scalars and does the right thing with them.
    $text = $self->parse ($text, @_);
    $text =~ s/\n\s*$/\n/;
    $self->makespace;
    $self->output (protect $self->textmapfonts ($text));
    $self->outindex;
    $$self{NEEDSPACE} = 1;
}

# Called for an interior sequence.  Takes a Pod::InteriorSequence object and
# returns a reference to a scalar.  This scalar is the final formatted text.
# It's returned as a reference so that other interior sequences above us
# know that the text has already been processed.
sub sequence {
    my ($self, $seq) = @_;
    my $command = $seq->cmd_name;

    # Zero-width characters.
    if ($command eq 'Z') {
        # Workaround to generate a blessable reference, needed by 5.005.
#        my $tmp = '\&';
        my $tmp = '#';
        return bless \ "$tmp", 'Pod::Dsr::String';
    }

    # C<>, L<>, X<>, and E<> don't apply guesswork to their contents.  C<>
    # needs some additional special handling.
    my $literal = ($command =~ /^[CELX]$/);
    $literal++ if $command eq 'C';
    local $_ = $self->collapse ($seq->parse_tree, $literal);

    # Handle E<> escapes.
    if ($command eq 'E') {
        if (/^\d+$/) {
            return bless \ chr ($_), 'Pod::Dsr::String';
        } elsif (exists $ESCAPES{$_}) {
            return bless \ "$ESCAPES{$_}", 'Pod::Dsr::String';
        } else {
            carp "Unknown escape E<$1>";
            return bless \ "E<$_>", 'Pod::Dsr::String';
        }
    }

    # For all the other sequences, empty content produces no output.
    return '' if $_ eq '';

    # Handle formatting sequences.
    if ($command eq 'B') {
#        return bless \ ('\f(BS' . $_ . '\f(BE'), 'Pod::Dsr::String';
        return bless \ ('^*' . $_ . '\*'), 'Pod::Dsr::String';
    } elsif ($command eq 'F') {
#        return bless \ ('\f(IS' . $_ . '\f(IE'), 'Pod::Dsr::String';
        return bless \ ( $_ ), 'Pod::Dsr::String';
    } elsif ($command eq 'I') {
#        return bless \ ('\f(IS' . $_ . '\f(IE'), 'Pod::Dsr::String';
        return bless \ ('^&' . $_ . '\&'), 'Pod::Dsr::String';
    } elsif ($command eq 'C') {
#        return bless \ ('\f(FS\*(C`' . $_ . "\\*(C'\\f(FE"),
        return bless \ ($_),
            'Pod::Dsr::String';
    }

    # Handle links.
    if ($command eq 'L') {
        # A bug in lvalue subs in 5.6 requires the temporary variable.
        my $tmp = $self->buildlink ($_);
        return bless \ "$tmp", 'Pod::Dsr::String';
    }

    # Whitespace protection replaces whitespace with "\ ".
    if ($command eq 'S') {
#        s/\s+/\\ /g;
        return bless \ "$_", 'Pod::Dsr::String';
    }

    # Add an index entry to the list of ones waiting to be output.
    if ($command eq 'X') { push (@{ $$self{INDEX} }, $_); return '' }

    # Anything else is unknown.
    carp "Unknown sequence $command<$_>";
}


############################################################################
# Command paragraphs
############################################################################

# All command paragraphs take the paragraph and the line number.

# .SH
# already uses small caps, so remove any E<> sequences that would cause
# them.
sub cmd_head1 {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\\s-?\d//g;
    s/\s*\n\s*/ /g;
    if ($$self{ITEMS} > 1) {
        $$self{ITEMS} = 0;
    }
    $self->output ($self->switchquotes ('.HEADER LEVEL 1', $self->mapfonts ($_)));
    $self->outindex (($_ eq 'NAME') ? () : ($_));
    $$self{NEEDSPACE} = 0;
}

# Second level heading.
sub cmd_head2 {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\s*\n\s*/ /g;
    if ($$self{ITEMS} > 1) {
        $$self{ITEMS} = 0;
    }
    $self->output ($self->switchquotes ('.HEADER LEVEL 2', $self->mapfonts ($_)));
    $self->outindex ($_);
    $$self{NEEDSPACE} = 0;
}

# Third level heading.
sub cmd_head3 {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\s*\n\s*/ /g;
    if ($$self{ITEMS} > 1) {
        $$self{ITEMS} = 0;
    }
    $self->makespace;
    $self->output ($self->switchquotes ('.HEADER LEVEL 3', $self->mapfonts ($_)));
    $self->outindex ($_);
    $$self{NEEDSPACE} = 1;
}

# Fourth level heading.  DSR only offsets from test to .HEADER LEVEL 3
sub cmd_head4 {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\s*\n\s*/ /g;
    if ($$self{ITEMS} > 1) {
        $$self{ITEMS} = 0;
    }
    $self->makespace;
    $self->output ($self->switchquotes ('.HEADER LEVEL 3', $self->mapfonts ($_)));
    $self->outindex ($_);
    $$self{NEEDSPACE} = 1;
}

# Fifth level heading ->  .HEADER LEVEL 4
sub cmd_head5 {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\s*\n\s*/ /g;
    if ($$self{ITEMS} > 1) {
        $$self{ITEMS} = 0;
    }
    $self->makespace;
    $self->output ($self->switchquotes ('.HEADER LEVEL 4', $self->mapfonts ($_)));
    $self->outindex ($_);
    $$self{NEEDSPACE} = 1;
}

# Sixth level heading.  .HEADER LEVEL 5
sub cmd_head6 {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\s*\n\s*/ /g;
    if ($$self{ITEMS} > 1) {
        $$self{ITEMS} = 0;
    }
    $self->makespace;
    $self->output ($self->switchquotes ('.HEADER LEVEL 5', $self->mapfonts ($_)));
    $self->outindex ($_);
    $$self{NEEDSPACE} = 1;
}

# Start a list.
sub cmd_over {
    my $self = shift;
    local $_ = shift;
    unless (/^[-+]?\d+\s+$/) { $_ = $$self{indent} }
    if (@{ $$self{INDENTS} } > -1) {
        $self->output (".LIST\n");
    }
    push (@{ $$self{INDENTS} }, $$self{INDENT});
    $$self{INDENT} = ($_ + 0);
}

# End a list.  If we've closed an embedded indent, we've mangled the hanging
# paragraph indent, so temporarily replace it with .RS and set WEIRDINDENT.
# We'll close that .RS at the next =back or =item.
sub cmd_back {
    my $self = shift;
    $$self{INDENT} = pop @{ $$self{INDENTS} };
    unless (defined $$self{INDENT}) {
        carp "Unmatched =back";
        $$self{INDENT} = 0;
    }
#    if ($$self{WEIRDINDENT}) {
#        $self->output (".END LIST\n");
#        $$self{WEIRDINDENT} = 0;
#    }
    if (@{ $$self{INDENTS} } > -1) {
        $self->output (".END LIST\n");
        $$self{WEIRDINDENT} = 1;
    }
    $$self{NEEDSPACE} = 1;
}

# An individual list item.  Emit an index entry for anything that's
# interesting, but don't emit index entries for things like bullets and
# numbers.  Turn * bullets into center dot characters (DEC MNCS) so use
# * for your lists rather than o or . or - or some other thing.  Newlines
# in an item title are turned into spaces since RUNOFF can't handle them
# embedded.
sub cmd_item {
    my $self = shift;
    local $_ = $self->parse (@_);
    s/\s+$//;
    s/\s*\n\s*/ /g;
    my $index;
    if (/\w/ && !/^\w[.\)]\s*$/) {
        $index = $_;
        $index =~ s/^\s*[-*+o.]?(?:\s+|\Z)//;
    }
    s/^\*(\s|\Z)/·$1/;
#    if ($$self{WEIRDINDENT}) {
#        $self->output (".LIST ELEMENT;");
#        $$self{WEIRDINDENT} = 0;
#    }
    $_ = $self->textmapfonts ($_);
    $self->output ($self->switchquotes ('.LIST ELEMENT;', $_ ));
    $self->outindex ($index ? ('Item', $index) : ());
    $$self{NEEDSPACE} = 0;
    $$self{ITEMS}++;
}

# Begin a block for a particular translator.  Setting VERBATIM triggers
# special handling in textblock().
sub cmd_begin {
    my $self = shift;
    local $_ = shift;
    my ($kind) = /^(\S+)/ or return;
    if ($kind eq 'man' || $kind eq 'roff' ||
        $kind eq 'dsr' || $kind eq 'rno') {
        $$self{VERBATIM} = 1;
    } else {
        $$self{EXCLUDE} = 1;
    }
}

# End a block for a particular translator.  We assume that all =begin/=end
# pairs are properly closed.
sub cmd_end {
    my $self = shift;
    $$self{EXCLUDE} = 0;
    $$self{VERBATIM} = 0;
}

# One paragraph for a particular translator.  Ignore it unless it's intended
# for dsr, rno, man or roff; in which case we output it verbatim.
sub cmd_for {
    my $self = shift;
    local $_ = shift;
    return unless s/^(?:dsr|rno|man|roff)\b[ \t]*\n?//;
    $self->output ($_);
}


############################################################################
# Link handling
############################################################################

# Handle links.  We can't actually make real hyperlinks, so this is all to
# figure out what text and formatting we print out.
sub buildlink {
    my $self = shift;
    local $_ = shift;

    # Smash whitespace in case we were split across multiple lines.
    s/\s+/ /g;

    # If we were given any explicit text, just output it.
    if (m{ ^ ([^|]+) \| }x) { return $1 }

    # Okay, leading and trailing whitespace isn't important.
    s/^\s+//;
    s/\s+$//;

    # Default to using the whole content of the link entry as a section
    # name.  Note that L<manpage/> forces a manpage interpretation, as does
    # something looking like L<manpage(section)>.  Do the same thing to
    # L<manpage(section)> as we would to manpage(section) without the L<>;
    # see guesswork().  If we've added italics, don't add the "manpage"
    # text; markup is sufficient.
    # DSR note: s/manpage/document/g; in the above.
    my ($manpage, $section) = ('', $_);
    if (/^"\s*(.*?)\s*"$/) {
        $section = $1;
    } elsif (m{ ^ [-:.\w]+ (?: \( \S+ \) )? $ }x) {
        ($manpage, $section) = ($_, '');
        $manpage =~ s/^([^\(]+)\(/'^&' . $1 . '\&('/e;
    } elsif (m%/%) {
        ($manpage, $section) = split (/\s*\/\s*/, $_, 2);
        if ($manpage =~ /^[-:.\w]+(?:\(\S+\))?$/) {
#            $manpage =~ s/^([^\(]+)\(/'\f(IS' . $1 . '\f(IE\|'/e;
        }
        $section =~ s/^\"\s*//;
        $section =~ s/\s*\"$//;
    }
    if ($manpage && $manpage !~ /\^\&/) {
        $manpage = "the $manpage document";
    }

    # Now build the actual output text.
    my $text = '';
    if (!length ($section) && !length ($manpage)) {
        carp "Invalid link $_";
    } elsif (!length ($section)) {
        $text = $manpage;
    } elsif ($section =~ /^[:\w]+(?:\(\))?/) {
        $text .= 'the ' . $section . ' entry';
        $text .= (length $manpage) ? " in $manpage"
                                   : " elsewhere in this document";
    } else {
        if ($section !~ /^".*"$/) { $section = '"' . $section . '"' }
        $text .= 'the section on ' . $section;
        $text .= " in $manpage" if length $manpage;
    }
    $text;
}


############################################################################
# Escaping and fontification
############################################################################

# At this point, we'll have embedded font codes of the form \f(<font>[SE]
# where <font> is one of B, I, or F.  Turn those into the right font start
# or end codes.  The old pod2man didn't get B<someI<thing> else> right;
# after I<> it switched back to normal text rather than bold.  We take care
# of this by using variables as a combined pointer to our current font
# sequence, and set each to the number of current nestings of start tags for
# that font.  Use them as a vector to look up what font sequence to use.
#
# \fP changes to the previous font, but only one previous font is kept.  We
# don't know what the outside level font is; normally it's R, but if we're
# inside a heading it could be something else.  So arrange things so that
# the outside font is always the "previous" font and end with \fP instead of
# \fR.  Idea from Zack Weinberg.
sub mapfonts {
    my $self = shift;
    local $_ = shift;

    my ($fixed, $bold, $italic) = (0, 0, 0);
    my %magic = (F => \$fixed, B => \$bold, I => \$italic);
    my $last = '\fR';
    s { \\f\((.)(.) } {
        my $sequence = '';
        my $f;
        if ($last ne '\fR') { $sequence = '\fP' }
        ${ $magic{$1} } += ($2 eq 'S') ? 1 : -1;
        $f = $$self{FONTS}{($fixed && 1) . ($bold && 1) . ($italic && 1)};
        if ($f eq $last) {
            '';
        } else {
            if ($f ne '\fR') { $sequence .= $f }
            $last = $f;
            $sequence;
        }
    }gxe;
    $_;
}

# Unfortunately, there is a bug in Solaris 2.6 nroff (not present in GNU
# groff) where the sequence \fB\fP\f(CW\fP leaves the font set to B rather
# than R, presumably because \f(CW doesn't actually do a font change.  To
# work around this, use a separate textmapfonts for text blocks where the
# default font is always R and only use the smart mapfonts for headings.
sub textmapfonts {
    my $self = shift;
    local $_ = shift;

    my ($fixed, $bold, $italic) = (0, 0, 0);
    my %magic = (F => \$fixed, B => \$bold, I => \$italic);
    s { \\f\((.)(.) } {
        ${ $magic{$1} } += ($2 eq 'S') ? 1 : -1;
        $$self{FONTS}{($fixed && 1) . ($bold && 1) . ($italic && 1)};
    }gxe;
    $_;
}


############################################################################
# *roff-specific parsing
############################################################################

# Called instead of parse_text, calls parse_text with the right flags.
sub parse {
    my $self = shift;
    $self->parse_text ({ -expand_seq   => 'sequence',
                         -expand_ptree => 'collapse' }, @_);
}

# Takes a parse tree and a flag saying whether or not to treat it as literal
# text (not call guesswork on it), and returns the concatenation of all of
# the text strings in that parse tree.  If the literal flag isn't true,
# guesswork() will be called on all plain scalars in the parse tree.
# Otherwise, just escape backslashes in the normal case.  If collapse is
# being called on a C<> sequence, literal is set to 2, and we do some
# additional cleanup.  Assumes that everything in the parse tree is either a
# scalar or a reference to a scalar.
sub collapse {
    my ($self, $ptree, $literal) = @_;
    if ($literal) {
        return join ('', map {
            if (ref $_) {
                $$_;
            } else {
                s/\\/\\e/g;
                s/-/\\-/g    if $literal > 1;
                s/__/_\\|_/g if $literal > 1;
                $_;
            }
        } $ptree->children);
    } else {
        return join ('', map {
            ref ($_) ? $$_ : $self->guesswork ($_)
        } $ptree->children);
    }
}

# Takes a text block to perform guesswork on; this is guaranteed not to
# contain any interior sequences.  Returns the text block with remapping
# done.
sub guesswork {
    my $self = shift;
    local $_ = shift;

    # rofficate backslashes.
#    s/\\/\\e/g;

    # Ensure double underbars have a tiny space between them.
#    s/__/_\\|_/g;

    # Make all caps a little smaller.  Be careful here, since we don't want
    # to make @ARGV into small caps, nor do we want to fix the MIME in
    # MIME-Version, since it looks weird with the full-height V.
#    s{
#        ( ^ | [\s\(\"\'\`\[\{<>] )
#        ( [A-Z] [A-Z] [/A-Z+:\d_\$&-]* )
#        (?: (?= [\s>\}\]\)\'\".?!,;:] | -- ) | $ )
#    } { $1 . '\s-1' . $2 . '\s0' }egx;

    # Turn PI into a pretty pi.
#    s{ (?: \\s-1 | \b ) PI (?: \\s0 | \b ) } {\\*\(PI}gx;

    # Underline functions in the form func().
    s{
        \b
        (
            [:\w]+ (?:\\s-1)? \(\)
        )
    } { '^&' . $1 . '\&' }egx;

    # func(n) is a reference to a manual page.  Make it ^&func\&(n).
    s{
        \b
        (\w[-:.\w]+ (?:\\s-1)?)
        (
            \( [^\)] \)
        )
    } { '^&' . $1 . '\&' . $2 }egx;

    # Convert simple Perl variable references to a fixed-width font.
#    s{
#        ( \s+ )
#        ( [\$\@%] [\w:]+ )
#        (?! \( )
#    } { $1 . '\f(FS' . $2 . '\f(FE'}egx;

    # Translate -- into a real em dash if it's used like one and fix up
    # dashes, but keep hyphens hyphens.
#    s{ (\G|^|.) (-+) (\b|.) } {
#        my ($pre, $dash, $post) = ($1, $2, $3);
#        if (length ($dash) == 1) {
#            ($pre =~ /[a-zA-Z]/) ? "$pre-$post" : "$pre\\-$post";
#        } elsif (length ($dash) == 2
#                 && ((!$pre && !$post)
#                     || ($pre =~ /\w/ && !$post)
#                     || ($pre eq ' ' && $post eq ' ')
#                     || ($pre eq '=' && $post ne '=')
#                     || ($pre ne '=' && $post eq '='))) {
#            "$pre\\*(--$post";
#        } else {
#            $pre . ('\-' x length $dash) . $post;
#        }
#    }egxs;

    # All done.
    $_;
}


############################################################################
# Output formatting
############################################################################

# Make vertical whitespace.
sub makespace {
    my $self = shift;
    $self->output (".BREAK\n") if ($$self{ITEMS} > 1);
    $$self{ITEMS} = 0;
    $self->output ($$self{INDENT} > 0 ? ".PARAGRAPH\n" : ".PARAGRAPH\n")
        if $$self{NEEDSPACE};
}

# Output any pending index entries, and optionally an index entry given as
# an argument.  Support multiple index entries in X<> separated by slashes,
# and strip special escapes from index entries.
sub outindex {
    my ($self, $section, $index) = @_;
    my @entries = map { split m%\s*/\s*% } @{ $$self{INDEX} };
    return unless ($section || @entries);
    $$self{INDEX} = [];
    my $output;
    if (@entries) {
        my $output = '.INDEX '
            . join (' ', @entries)
            . "\n";
    }
    if ($section) {
        if (defined($index) && $index ne '') {
            $index =~ s/\\-/-/g;
            $index =~ s/\\(?:s-?\d|.\(..|.)//g;
            $output .= ".INDEX $section>$index\n";
        }
        else {
            $output .= ".INDEX $section\n";
        }
    }
    $self->output ($output);
}

# Output text to the output device.
sub output { print { $_[0]->output_handle } $_[1] }

# Given a command and a single argument that may or may not contain double
# quotes, handle double-quote formatting for it.  If there are no double
# quotes, just return the command followed by the argument in double quotes.
# If there are double quotes, use an if statement to test for nroff, and for
# nroff output the command followed by the argument in double quotes with
# embedded double quotes doubled.  For other formatters, remap paired double
# quotes to LQUOTE and RQUOTE.
sub switchquotes {
    my $self = shift;
    my $command = shift;
    local $_ = shift;
    my $extra = shift;
    s/\\\*\([LR]\"/\"/g;

    # We also have to deal with \*C` and \*C', which are used to add the
    # quotes around C<> text, since they may expand to " and if they do this
    # confuses the .SH macros and the like no end.  Expand them ourselves.
    # If $extra is set, we're dealing with =item, which in most nroff macro
    # sets requires an extra level of quoting of double quotes.
    my $c_is_quote = ($$self{LQUOTE} =~ /\"/) || ($$self{RQUOTE} =~ /\"/);
    if (/\"/ || ($c_is_quote && /\\\*\(C[\'\`]/)) {
        s/\"/\"\"/g;
        my $troff = $_;
        $troff =~ s/\"\"([^\"]*)\"\"/\`\`$1\'\'/g;
        s/\\\*\(C\`/$$self{LQUOTE}/g;
        s/\\\*\(C\'/$$self{RQUOTE}/g;
        $troff =~ s/\\\*\(C[\'\`]//g;
        s/\"/\"\"/g if $extra;
        $troff =~ s/\"/\"\"/g if $extra;
        $_ = qq("$_") . ($extra ? " $extra" : '');
        $troff = qq("$troff") . ($extra ? " $extra" : '');
        return ".if n $command $_\n.el $command $troff\n";
    } else {
        $_ = qq("$_") . ($extra ? " $extra" : '');
        return "$command $_\n";
    }
}

__END__


############################################################################
# Documentation
############################################################################

=head1 NAME

Pod::Dsr - Convert POD data to formatted DSR input

=head1 SYNOPSIS

    use Pod::Dsr;
    my $parser = Pod::Dsr->new (release => $VERSION, section => 8);

    # Read POD from STDIN and write to STDOUT.
    $parser->parse_from_filehandle;

    # Read POD from file.pod and write to file.1.
    $parser->parse_from_file ('file.pod', 'file.1');

=head1 DESCRIPTION

Pod::Dsr is a module to convert documentation in the POD format (the
preferred language for documenting Perl) into Digital Standard Runoff (DSR) 
input.  The resulting DSR code is suitable for display on a terminal
using RUNOFF(1) and TYPE(1), or printing using RUNOFF(1) and PRINT(1).  It is
conventionally invoked using the driver script B<pod2rno>, but it can also
be used directly.

As a derived class from Pod::Parser, Pod::Dsr supports the same methods and
interfaces.  See L<Pod::Parser> for all the details; briefly, one creates a
new parser with C<Pod::Dsr-E<gt>new()> and then calls either
parse_from_filehandle() or parse_from_file().

new() can take options, in the form of key/value pairs that control the
behavior of the parser.  See below for details.

If no options are given, Pod::Dsr uses the name of the input file with any
trailing C<.pod>, C<.pm>, or C<.pl> stripped as the man page title, to
section 1 unless the file ended in C<.pm> in which case it defaults to
section 3, to a centered title of "User Contributed Perl Documentation", to
a centered footer of the Perl version it is run with, and to a left-hand
footer of the modification date of its input (or the current date if given
STDIN for input).

Besides the obvious pod conversions, Pod::Dsr also takes care of formatting
func(), func(n), and simple variable references like $foo or @bar so you
don't have to use code escapes for them; complex expressions like
C<$fred{'stuff'}> will still need to be escaped, though.  It also translates
dashes that aren't used as hyphens into en dashes, makes long dashes--like
this--into proper em dashes, fixes "paired quotes," makes C++ and PI look
right, puts a little space between double underbars, and escapes stuff that 
runoff treats as special so that you don't have to.

The recognized options to new() are as follows.  All options take a single
argument.

=over 4

=item center

Sets the centered page header to use instead of "User Contributed Perl
Documentation".

=item date

Sets the left-hand footer.  By default, the modification date of the input
file will be used, or the current date if stat() can't find that file (the
case if the input is from STDIN), and the date will be formatted as
DD-MMM-YYYY.

=item quotes

Sets the quote marks used to surround CE<lt>> text.  If the value is a
single character, it is used as both the left and right quote; if it is two
characters, the first character is used as the left quote and the second as
the right quoted; and if it is four characters, the first two are used as
the left quote and the second two as the right quote.  This may also be set 
to the special value C<none>, in which case no quote marks are added around 
CE<lt>> text.

=item release

Set the centered footer.  By default, this is the version of Perl you run
Pod::Dsr under.

=item section

Set the section for the C<.HEADER LEVEL> command.  The standard section 
numbering convention is to use 1 for user commands, 2 for system calls, 3 for
functions, 4 for devices, 5 for file formats, 6 for games, 7 for
miscellaneous information, and 8 for administrator commands.  There is a lot
of variation here, however; some systems (like Solaris) use 4 for file
formats, 5 for miscellaneous information, and 7 for devices.  Still others
use 1m instead of 8, or some mix of both.  About the only section numbers
that are reliably consistent are 1, 2, and 3.  By default, section 1 will 
be used unless the file ends in .pm in which case section 3 will be selected.

=back

The standard Pod::Parser method parse_from_filehandle() takes up to two
arguments, the first being the file handle to read POD from and the second
being the file handle to write the formatted output to.  The first defaults
to STDIN if not given, and the second defaults to STDOUT.  The method
parse_from_file() is almost identical, except that its two arguments are the
input and output disk files instead.  See L<Pod::Parser> for the specific
details.

=head1 DIAGNOSTICS

=over 4

=item Invalid link %s

(W) The POD source contained a C<LE<lt>E<gt>> sequence that Pod::Dsr was
unable to parse.  You should never see this error message; it probably
indicates a bug in Pod::Dsr.

=item Invalid quote specification "%s"

(F) The quote specification given (the quotes option to the constructor) was
invalid.  A quote specification must be one, two, or four characters long.

=item %s:%d: Unknown command paragraph "%s".

(W) The POD source contained a non-standard command paragraph (something of
the form C<=command args>) that Pod::Dsr didn't know about.  It was ignored.

=item Unknown escape EE<lt>%sE<gt>

(W) The POD source contained an C<EE<lt>E<gt>> escape that Pod::Dsr didn't
know about.  C<EE<lt>%sE<gt>> was printed verbatim in the output.

=item Unknown sequence %s

(W) The POD source contained a non-standard interior sequence (something of
the form C<XE<lt>E<gt>>) that Pod::Dsr didn't know about.  It was ignored.

=item %s: Unknown command paragraph "%s" on line %d.

(W) The POD source contained a non-standard command paragraph (something of
the form C<=command args>) that Pod::Dsr didn't know about. It was ignored.

=item Unmatched =back

(W) Pod::Man encountered a C<=back> command that didn't correspond to an
C<=over> command.

=back

=head1 BUGS

The lint-like features and strict POD format checking done by B<pod2man> are
not yet implemented and should be, along with the corresponding C<lax>
option.

The NAME section should be recognized specially and index entries emitted
for everything in that section.

The preamble added to each output file is a bit verbose, and should be
made to be more flexible (e.g. support optional .LAYOUT commands).

Some of the automagic applied to file names assumes Unix directory
separators.

Pod::Dsr is excessively slow.

=head1 SEE ALSO

L<Pod::Parser|Pod::Parser>, perlpod(1), pod2rno(1), runoff(1), type(1),
print(1), DSR(1)

Please see the file F<README.runoff> in the Pod2VMSHlp distribution
for more information on RUNOFF and the DSR language.

Also, please see pod2man(1) for extensive documentation on
writing manual pages if you've not done it before and aren't familiar with
the conventions.

=head1 AUTHOR

Peter Prymmer pvhp@best.com, based I<very> heavily on Pod::Man by
Russ Allbery which was in turn based upon the original B<pod2man> 
by Tom Christiansen and Larry Wall.

=cut

