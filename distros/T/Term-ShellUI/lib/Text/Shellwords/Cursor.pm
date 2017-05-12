# Text::Shellwords::Cursor.pm
# Scott Bronson
# 27 Jan 2003
# Covered by the MIT license.

package Text::Shellwords::Cursor;

use strict;

use vars qw($VERSION);
$VERSION = '0.81';

=head1 NAME

Text::Shellwords::Cursor - Parse a string into tokens

=head1 SYNOPSIS

 use Text::Shellwords::Cursor;
 my $parser = Text::Shellwords::Cursor->new();
 my $str = 'ab cdef "ghi"    j"k\"l "';
 my ($tok1) = $parser->parse_line($str);
   $tok1 = ['ab', 'cdef', 'ghi', 'j', 'k"l ']
 my ($tok2, $tokno, $tokoff) = $parser->parse_line($str, cursorpos => 6);
    as above, but $tokno=1, $tokoff=3  (under the 'f')

DESCRIPTION

This module is very similar to Text::Shellwords and Text::ParseWords.
However, it has one very significant difference: it keeps track of
a character position in the line it's parsing.  For instance, if you
pass it ("zq fmgb", cursorpos=>6), it would return
(['zq', 'fmgb'], 1, 3).  The cursorpos parameter
tells where in the input string the cursor resides
(just before the 'b'), and the result tells you that
the cursor was on token 1 ('fmgb'), character 3 ('b').
This is very useful when computing command-line completions
involving quoting, escaping, and tokenizing characters (like '(' or '=').

A few helper utilities are included as well.  You can escape a string to
ensure that parsing it will produce the original string (L<parse_escape>).
You can also reassemble the tokens with a visually pleasing amount of
whitespace between them (L<join_line>).

This module started out as an integral part of Term::GDBUI using
code loosely based on Text::ParseWords.  However,
it is now basically a ground-up reimplementation.  It was
split out of Term::GDBUI for version 0.8.

=head1 METHODS

=over 3

=item new

Creates a new parser.  Takes named arguments on the command line.

=over 4

=item keep_quotes

Normally all unescaped, unnecessary quote marks are stripped.
If you specify C<keep_quotes=E<gt>1>, however, they are preserved.
This is useful if you need to know whether the string was quoted
or not (string constants) or what type of quotes was around it
(affecting variable interpolation, for instance).

=item token_chars

This argument specifies the characters that should be considered
tokens all by themselves.  For instance, if I pass
token_chars=>'=', then 'ab=123' would be parsed to ('ab', '=', '123').
Without token_chars, 'ab=123' remains a single string.

NOTE: you cannot change token_chars after the constructor has been
called!  The regexps that use it are compiled once (m//o).
Also, until the Gnu Readline library can accept "=[]," without
diving into an endless loop, we will not tell history expansion
to use token_chars (it uses " \t\n()<>;&|" by default).

=item debug

Turns on rather copious debugging to try to show what the parser is
thinking at every step.

=item space_none

=item space_before

=item space_after

These variables affect how whitespace in the line is normalized and
it is reassembled into a string.  See the L<join_line> routine.

=item error

This is a reference to a routine that should be called to display
a parse error.  The routine takes two arguments: a reference to the
parser, and the error message to display as a string.

=cut

sub new
{
    my $type = shift;
    bless {
        keep_quotes => 0,
        token_chars => '',
        debug => 0,
        space_none => '(',
        space_before => '[{',
        space_after => ',)]}',
        error => undef,
        @_
    }, $type
}

=item parsebail(msg)

If the parsel routine or any of its subroutines runs into a fatal
error, they call parsebail to present a very descriptive diagnostic.

=cut

sub parsebail
{
    my $self = shift;
    my $msg = shift;

    die "$msg at char " . pos() . ":\n",
    "    $_\n    " . (' ' x pos()) . '^' . "\n";

}


=item parsel

This is the heinous routine that actually does the parsing.
You should never need to call it directly.  Call
L<parse_line|/"parse_line(line, named args)">
instead.

=cut

sub parsel
{
    my $self = shift;
    $_ = shift;
    my $cursorpos = shift;
    my $fixclosequote = shift;

    my $deb = $self->{debug};
    my $tchrs = $self->{token_chars};

    my $usingcp = (defined($cursorpos) && $cursorpos ne '');
    my $tokno = undef;
    my $tokoff = undef;
    my $oldpos;

    my @pieces = ();

    # Need to special case the empty string.  None of the patterns below
    # will match it yet we need to return an empty token for the cursor.
    return ([''], 0, 0) if $usingcp && $_ eq '';

    /^/gc;  # force scanning to the beginning of the line

    do {
        $deb && print "-- top, pos=" . pos() .
            ($usingcp ? " cursorpos=$cursorpos" : "") . "\n";

        # trim whitespace from the beginning
        if(/\G(\s+)/gc) {
            $deb && print "trimmed " . length($1) . " whitespace chars, " .
                ($usingcp ? "cursorpos=$cursorpos" : "") . "\n";
            # if pos passed cursorpos, then we know that the cursor was
            # surrounded by ws and we need to create an empty token for it.
            if($usingcp && (pos() >= $cursorpos)) {
                # if pos == cursorpos and we're not yet at EOL, let next token accept cursor
                unless(pos() == $cursorpos && pos() < length($_)) {
                    # need to special-case at end-of-line as there are no more tokens
                    # to take care of the cursor so we must create an empty one.
                    $deb && print "adding bogus token to handle cursor.\n";
                    push @pieces, '';
                    $tokno = $#pieces;
                    $tokoff = 0;
                    $usingcp = 0;
                }
            }
        }

        # if there's a quote, then suck to the close quote
        $oldpos = pos();
        if(/\G(['"])/gc) {
            my $quote = $1;
            my $adjust = 0; # keeps track of tokoff bumps due to subs, etc.
            my $s;

            $deb && print "Found open quote [$quote]  oldpos=$oldpos\n";

            # adjust tokoff unless the cursor sits directly on the open quote
            if($usingcp && pos()-1 < $cursorpos) {
                $deb && print "  lead quote increment   pos=".pos()." cursorpos=$cursorpos\n";
                $adjust += 1;
            }

            if($quote eq '"') {
                if(/\G((?:\\.|(?!["])[^\\])*)["]/gc) {
                    $s = $1;    # string without quotes
                } else {
                    unless($fixclosequote) {
                        pos() -= 1;
                        $self->parsebail("need closing quote [\"]");
                    }
                    /\G(.*)$/gc;    # if no close quote, just suck to the end of the string
                    $s = $1;    # string without quotes
                    if($usingcp && pos() == $cursorpos) { $adjust -= 1; }   # make cursor think cq was there
                }
                $deb && print "  quoted string is \"$s\"\n";
                while($s =~ /\\./g) {
                    my $ps = pos($s) - 2;   # points to the start of the sub
                    $deb && print "  doing substr at $ps on '$s'  oldpos=$oldpos adjust=$adjust\n";
                    $adjust += 1 if $usingcp && $ps < $cursorpos - $oldpos - $adjust;
                    substr($s, $ps, 1) = '';
                    pos($s) = $ps + 1;
                    $deb && print "  s='$s'  usingcp=$usingcp  pos(s)=" . pos($s) . "  cursorpos=$cursorpos  oldpos=$oldpos adjust=$adjust\n";
                }
            } else {
                if(/\G((?:\\.|(?!['])[^\\])*)[']/gc) {
                    $s = $1;    # string without quotes
                } else {
                    unless($fixclosequote) {
                        pos() -= 1;
                        $self->parsebail("need closing quote [']");
                    }
                    /\G(.*)$/gc;    # if no close quote, just suck to the end of the string
                    $s = $1;
                    if($usingcp && pos() == $cursorpos) { $adjust -= 1; }   # make cursor think cq was there
                }
                $deb && print "  quoted string is '$s'\n";
                while($s =~ /\\[\\']/g) {
                    my $ps = pos($s) - 2;   # points to the start of the sub
                    $deb && print "  doing substr at $ps on '$s'  oldpos=$oldpos adjust=$adjust\n";
                    $adjust += 1 if $usingcp && $ps < $cursorpos - $oldpos - $adjust;
                    substr($s, $ps, 1) = '';
                    pos($s) = $ps + 1;
                    $deb && print "  s='$s'  usingcp=$usingcp  pos(s)=" . pos($s) . "  cursorpos=$cursorpos  oldpos=$oldpos adjust=$adjust\n";
                }
            }

            # adjust tokoff if the cursor if it sits directly on the close quote
            if($usingcp && pos() == $cursorpos) {
                $deb && print "  trail quote increment  pos=".pos()." cursorpos=$cursorpos\n";
                $adjust += 1;
            }

            $deb && print "  Found close, pushing '$s'  oldpos=$oldpos\n";
            if($self->{keep_quotes}) {
                $adjust -= 1;   # need to move right 1 for opening quote
                $s = $quote.$s.$quote;
            }
            push @pieces, $s;

            # Set tokno and tokoff if this token contained the cursor
            if($usingcp && pos() >= $cursorpos) {
                # Previous block contains the cursor
                $tokno = $#pieces;
                $tokoff = $cursorpos - $oldpos - $adjust;
                $usingcp = 0;
            }
        }

        # suck up as much unquoted text as we can
        $oldpos = pos();
        if(/\G((?:\\.|[^\s\\"'\Q$tchrs\E])+)/gco) {
            my $s = $1;     # the unquoted string
            my $adjust = 0; # keeps track of tokoff bumps due to subs, etc.

            $deb && print "Found unquoted string '$s'\n";
            while($s =~ /\\./g) {
                my $ps = pos($s) - 2;   # points to the start of substitution
                $deb && print "  doing substr at $ps on '$s'  oldpos=$oldpos adjust=$adjust\n";
                $adjust += 1 if $usingcp && $ps < $cursorpos - $oldpos - $adjust;
                substr($s, $ps, 1) = '';
                pos($s) = $ps + 1;
                $deb && print "  s='$s'  usingcp=$usingcp  pos(s)=" . pos($s) . "  cursorpos=$cursorpos  oldpos=$oldpos adjust=$adjust\n";
            }
            $deb && print "  pushing '$s'\n";
            push @pieces, $s;

            # Set tokno and tokoff if this token contained the cursor
            if($usingcp && pos() >= $cursorpos) {
                # Previous block contains the cursor
                $tokno = $#pieces;
                $tokoff = $cursorpos - $oldpos - $adjust;
                $usingcp = 0;
            }
        }

        if(length($tchrs) && /\G([\Q$tchrs\E])/gco) {
            my $s = $1; # the token char
            $deb && print "  pushing '$s'\n";
            push @pieces, $s;

            if($usingcp && pos() == $cursorpos) {
                # Previous block contains the cursor
                $tokno = $#pieces;
                $tokoff = 0;
                $usingcp = 0;
            }
        }
    } until(pos() >= length($_));

    $deb && print "Result: (", join(", ", @pieces), ") " .
        (defined($tokno) ? $tokno : 'undef') . " " .
        (defined($tokoff) ? $tokoff : 'undef') . "\n";

    return ([@pieces], $tokno, $tokoff);
}


=item parse_line(line, I<named args>)

This is the entrypoint to this module's parsing functionality.  It converts
a line into tokens, respecting quoted text, escaped characters,
etc.  It also keeps track of a cursor position on the input text,
returning the token number and offset within the token where that position
can be found in the output.

This routine originally bore some resemblance to Text::ParseWords.
It has changed almost completely, however, to support keeping track
of the cursor position.  It also has nicer failure modes, modular
quoting, token characters (see token_chars in L</new>), etc.  This
routine now does much more.

Arguments:

=over 3

=item line

This is a string containing the command-line to parse.

=back

This routine also accepts the following named parameters:

=over 3

=item cursorpos

This is the character position in the line to keep track of.
Pass undef (by not specifying it) or the empty string to have
the line processed with cursorpos ignored.

Note that passing undef is I<not> the same as passing
some random number and ignoring the result!  For instance, if you
pass 0 and the line begins with whitespace, you'll get a 0-length token at
the beginning of the line to represent the cursor in
the middle of the whitespace.  This allows command completion
to work even when the cursor is not near any tokens.
If you pass undef, all whitespace at the beginning and end of
the line will be trimmed as you would expect.

If it is ambiguous whether the cursor should belong to the previous
token or to the following one (i.e. if it's between two quoted
strings, say "a""b" or a token_char), it always gravitates to
the previous token.  This makes more sense when completing.

=item fixclosequote

Sometimes you want to try to recover from a missing close quote
(for instance, when calculating completions), but usually you
want a missing close quote to be a fatal error.  fixclosequote=>1
will implicitly insert the correct quote if it's missing.
fixclosequote=>0 is the default.

=item messages

parse_line is capable of printing very informative error messages.
However, sometimes you don't care enough to print a message (like
when calculating completions).  Messages are printed by default,
so pass messages=>0 to turn them off.

=back

This function returns a reference to an array containing three
items:

=over 3

=item tokens

A the tokens that the line was separated into (ref to an array of strings).

=item tokno

The number of the token (index into the previous array) that contains
cursorpos.

=item tokoff

The character offet into tokno of cursorpos.

=back

If the cursor is at the end of the token, tokoff will point to 1
character past the last character in tokno, a non-existant character.
If the cursor is between tokens (surrounded by whitespace), a zero-length
token will be created for it.

=cut

sub parse_line
{
    my $self = shift;
    my $line = shift;
    my %args = (
        messages => 1,      # true if we should print errors, etc.
        cursorpos => undef, # cursor to keep track of, undef to ignore.
        fixclosequote => 0,
        @_
    );

    my @result = eval { $self->parsel($line,
        $args{'cursorpos'}, $args{'fixclosequote'}) };
    if($@) {
        $self->{error}->($self, $@) if $args{'messages'} && $self->{error};
        @result = (undef, undef, undef);
    }

    return @result;
}


=item parse_escape(lines)

Escapes characters that would be otherwise interpreted by the parser.
Will accept either a single string or an arrayref of strings (which
will be modified in-place).

=cut

sub parse_escape
{
    my $self = shift;
    my $arr = shift;    # either a string or an arrayref of strings

    my $wantstr = 0;
    if(ref($arr) ne 'ARRAY') {
        $arr = [$arr];
        $wantstr = 1;
    }

    foreach(@$arr) {
        my $quote;
        if($self->{keep_quotes} && /^(['"])(.*)\1$/) {
            ($quote, $_) = ($1, $2);
        }
        s/([ \\"'])/\\$1/g;
        $_ = $quote.$_.$quote if $quote;
    }

    return $wantstr ? $arr->[0] : $arr;
}


=item join_line(tokens)

This routine does a somewhat intelligent job of joining tokens
back into a command line.  If token_chars (see L</new>) is empty
(the default), then it just escapes backslashes and quotes, and
joins the tokens with spaces.

However, if token_chars is nonempty, it tries to insert a visually
pleasing amount of space between the tokens.  For instance, rather
than 'a ( b , c )', it tries to produce 'a (b, c)'.  It won't reformat
any tokens that aren't found in $self->{token_chars}, of course.

To change the formatting, you can redefine the variables
$self->{space_none}, $self->{space_before}, and $self->{space_after}.
Each variable is a string containing all characters that should
not be surrounded by whitespace, should have whitespace before,
and should have whitespace after, respectively.  Any character
found in token_chars, but non in any of these space_ variables,
will have space placed both before and after.

=cut

sub join_line
{
    my $self = shift;
    my $intoks = shift;

    my $tchrs = $self->{token_chars};
    my $s_none = $self->{space_none};
    my $s_before = $self->{space_before};
    my $s_after = $self->{space_after};

    # copy the input array so we don't modify it
    my $tokens = $self->parse_escape([@$intoks]);

    my $str = '';
    my $sw = 0; # space if space wanted after token.
    my $sf = 0; # space if space should be forced after token.
    for(@$tokens) {
        if(length == 1 && index($tchrs,$_) >= 0) {
            if(index($s_none,$_) >= 0)   { $str .= $_;     $sw=0; next; }
            if(index($s_before,$_) >= 0) { $str .= $sw.$_; $sw=0; next; }
            if(index($s_after,$_) >= 0)  { $str .= $_;     $sw=1; next; }
            # default: force space on both sides of operator.
            $str .= " $_ "; $sw = 0; next;
        }
        $str .= ($sw ? ' ' : '') . $_;
        $sw = 1;
    }

    return $str;
}


=back

=back

=head1 BUGS

None known.

=head1 LICENSE

Copyright (c) 2003-2011 Scott Bronson, all rights reserved.
This program is covered by the MIT license.

=head1 AUTHOR

Scott Bronson E<lt>bronson@rinspin.comE<gt>

=cut

1;
