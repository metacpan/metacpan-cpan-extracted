package PDF::Builder::Content::Text;

use base 'PDF::Builder::Content';

use strict;
use warnings;

our $VERSION = '3.017'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Content::Text - additional specialized text-related formatting methods. Inherits from L<PDF::Builder::Content>

B<Note:> If you have used some of these methods in PDF::API2 with a I<graphics> 
type object (e.g., $page->gfx()->method()), you may have to change to a I<text> 
type object (e.g., $page->text()->method()).

=head1 METHODS

=cut

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new(@_);
    $self->textstart();
    return $self;
}

=over

=item $width = $content->text_left($text, %opts)

=item $width = $content->text_left($text)

Alias for C<text>. Implemented for symmetry, for those who use a lot of
C<text_center> and C<text_right>, and desire a C<text_left>.

Adds text to the page (left justified). 
The width used (in points) is B<returned>.

=back

=cut

sub text_left {
    my ($self, $text, @opts) = @_;

    return $self->text($text, @opts);
}

=over

=item $width = $content->text_center($text, %opts)

=item $width = $content->text_center($text)

As C<text>, but centered on the current point.

Adds text to the page (centered). 
The width used (in points) is B<returned>.

=back

=cut

sub text_center {
    my ($self, $text, @opts) = @_;

    my $width = $self->advancewidth($text);
    return $self->text($text, -indent => -($width/2), @opts);
}

=over

=item $width = $content->text_right($text, %opts)

=item $width = $content->text_right($text)

As C<text>, but right-aligned to the current point.

Adds text to the page (right justified). 
The width used (in points) is B<returned>.

=back

=cut

sub text_right {
    my ($self, $text, @opts) = @_;

    my $width = $self->advancewidth($text);
    return $self->text($text, -indent => -$width, @opts);
}

=over

=item $width = $content->text_justified($text, $width, %opts)
 
=item $width = $content->text_justified($text, $width)

As C<text>, but stretches text (using C<wordspace>, C<charspace>, and (as a  
last resort) C<hscale>) to fill the desired
(available) C<$width>. Note that if the desired width is I<less> than the
natural width taken by the text, it will be I<condensed> to fit, using the
same three routines.

The unchanged C<$width> is B<returned>, unless there was some reason to
change it (e.g., overflow).

B<Options:>

=over

=item -wordsp => value

The percentage of one space character (default 100) that is the maximum amount
to add to (each) interword spacing to expand the line.

=item -charsp => value

If adding interword space didn't do enough, the percentage of one em (default 
100) that is the maximum amount to add to (each) intercharacter spacing to 
further expand the line.

=item -wordspa => value

If adding intercharacter space didn't do enough, the percentage of one space
character (default 100) that is the maximum I<additional> amount to add to 
(each) interword spacing to further expand the line.

=item -charspa => value

If adding more interword space didn't do enough, the percentage of one em 
(default 100) that is the maximum I<additional> amount to add to (each) 
intercharacter spacing to further expand the line.

=item -condw => value

The percentage of one space character (default 25) that is the maximum amount
to subtract from (each) interword spacing to condense the line.

=item -condc => value

If removing interword space didn't do enough, the percentage of one em
(default 10) that is the maximum amount to subtract from (each) intercharacter
spacing to further condense the line.

=back

If expansion (or reduction) wordspace and charspace changes didn't do enough 
to make the line fit the desired width, use C<hscale()> to finish expanding or 
condensing the line to fit.

=back

=cut

sub text_justified {
    my ($self, $text, $width, %opts) = @_;

    # optional parameters to control how expansion or condensation are done
    # 1. expand interword space up to 100% of 1 space
    my $wordsp = defined($opts{'-wordsp'})? $opts{'-wordsp'}: 100;
    # 2. expand intercharacter space up to 100% of 1em
    my $charsp = defined($opts{'-charsp'})? $opts{'-charsp'}: 100;
    # 3. expand interword space up to another 100% of 1 space
    my $wordspa = defined($opts{'-wordspa'})? $opts{'-wordspa'}: 100;
    # 4. expand intercharacter space up to another 100% of 1em
    my $charspa = defined($opts{'-charspa'})? $opts{'-charspa'}: 100;
    # 5. condense interword space up to 25% of 1 space
    my $condw = defined($opts{'-condw'})? $opts{'-condw'}: 25;
    # 6. condense intercharacter space up to 10% of 1em
    my $condc = defined($opts{'-condc'})? $opts{'-condc'}: 10;
    # 7. if still short or long, hscale()

    # with original wordspace, charspace, and hscale settings
    my $length = $self->advancewidth($text, %opts);
    my $overage = $length - $width;

    my ($i, @chars, $val, $limit);
    my $hs = $self->hscale();   # save old settings and reset to 0
    my $ws = $self->wordspace();
    my $cs = $self->charspace();
    $self->hscale(100); $self->wordspace(0); $self->charspace(0);

    # not near perfect fit? not within .1 pt of fitting
    if (abs($overage) > 0.1) { 

    # how many interword spaces can we change with wordspace?
    my $num_spaces = 0;
    # how many intercharacter spaces can be added to or removed?
    my $num_chars = -1;
    @chars = split //, $text;
    for ($i=0; $i<scalar @chars; $i++) {
	if ($chars[$i] eq ' ') { $num_spaces++; }
	$num_chars++;  # count spaces as characters, too
    }
    my $em = $self->advancewidth('M');
    my $sp = $self->advancewidth(' ');

    if ($overage > 0) {
	# too wide: need to condense it
	# 1. subtract from interword space, up to -$condw/100 $sp
	if ($overage > 0 && $num_spaces > 0) {
	    $val = $overage/$num_spaces;
	    $limit = $condw/100*$sp;
	    if ($val > $limit) { $val = $limit; }
	    $self->wordspace(-$val);
	    $overage -= $val*$num_spaces;
	}
	# 2. subtract from intercharacter space, up to -$condc/100 $em
	if ($overage > 0 && $num_chars > 0) {
	    $val = $overage/$num_chars;
	    $limit = $condc/100*$em;
	    if ($val > $limit) { $val = $limit; }
	    $self->charspace(-$val);
	    $overage -= $val*$num_chars;
	}
	# 3. nothing more to do than scale down with hscale()
    } else {
	# too narrow: need to expand it (usual case)
	$overage = -$overage; # working with positive value is easier
	# 1. add to interword space, up to $wordsp/100 $sp
	if ($overage > 0 && $num_spaces > 0) {
	    $val = $overage/$num_spaces;
	    $limit = $wordsp/100*$sp;
	    if ($val > $limit) { $val = $limit; }
	    $self->wordspace($val);
	    $overage -= $val*$num_spaces;
	}
	# 2. add to intercharacter space, up to $charsp/100 $em
	if ($overage > 0 && $num_chars > 0) {
	    $val = $overage/$num_chars;
	    $limit = $charsp/100*$em;
	    if ($val > $limit) { $val = $limit; }
	    $self->charspace($val);
	    $overage -= $val*$num_chars;
	}
	# 3. add to interword space, up to $wordspa/100 $sp additional
	if ($overage > 0 && $num_spaces > 0) {
	    $val = $overage/$num_spaces;
	    $limit = $wordspa/100*$sp;
	    if ($val > $limit) { $val = $limit; }
	    $self->wordspace($val+$self->wordspace());
	    $overage -= $val*$num_spaces;
	}
	# 4. add to intercharacter space, up to $charspa/100 $em additional
	if ($overage > 0 && $num_chars > 0) {
	    $val = $overage/$num_chars;
	    $limit = $charspa/100*$em;
	    if ($val > $limit) { $val = $limit; }
	    $self->charspace($val+$self->charspace());
	    $overage -= $val*$num_chars;
	}
	# 5. nothing more to do than scale up with hscale()
    }

    # last ditch effort to fill the line: use hscale()
    # temporarily resets hscale to expand width of line to match $width
    # wordspace and charspace are already (temporarily) at max/min
    if ($overage > 0) {
        $self->hscale(100*($width/$self->advancewidth($text)));
    }

    } # original $overage was not near 0
    # do the output, with wordspace, charspace, and possiby hscale changed
    $self->text($text, %opts);

    # restore settings
    $self->hscale($hs); $self->wordspace($ws); $self->charspace($cs);

    return $width;
}

=head2 Multiple Lines from a String

The string is split at regular blanks (spaces), x20, to find the longest 
substring that will fit the C<$width>. 
If a single word is longer than C<$width>, it will overflow. 
To stay strictly within the desired bounds, set the option
C<-spillover>=>0 to disallow spillover.

=head3 Hyphenation

If hyphenation is enabled, those methods which split up a string into multiple
lines (the "text fill", paragraph, and section methods) will attempt to split
up the word that overflows the line, in order to pack the text even more
tightly ("greedy" line splitting). There are a number of controls over where a
word may be split, but note that there is nothing language-specific (i.e.,
following a given language's rules for where a word may be split). This is left
to other packages.

There are hard coded minimums of 2 letters before the split, and 2 letters after
the split. See C<Hyphenate_basic.pm>. Note that neither hyphenation nor simple
line splitting makes any attempt to prevent widows and orphans, prevent 
splitting of the last word in a column or page, or otherwise engage in 
I<paragraph shaping>.

=over

=item -hyphenate => value

0: no hyphenation (B<default>), 1: do basic hyphenation. Always allows
splitting at a soft hyphen (\xAD). Unicode hyphen (U+2010) and non-splitting
hyphen (U+2011) are ignored as split points.

=item -spHH => value

0: do I<not> split at a hard hyphen (x\2D), 1: I<OK to split> (B<default>)

=item -spOP => value

0: do I<not> split after most punctuation, 1: I<OK to split> (B<default>)

=item -spDR => value

0: do I<not> split after a run of one or more digits, 1: I<OK to split> (B<default>)

=item -spLR => value

0: do I<not> split after a run of one or more ASCII letters, 1: I<OK to split> (B<default>)

=item -spCC => value

0: do I<not> split in camelCase between a lowercase letter and an
uppercase letter, 1: I<OK to split> (B<default>)

=back

=head3 Methods

=cut

# splits input text (on spaces) into words, glues them back together until 
# have filled desired (available) width. return the new line and remaining 
# text. runs of spaces should be preserved. if the first word of a line does
# not fit within the alloted space, and cannot be split short enough, just 
# accept the overflow.
sub _text_fill_line {
    my ($self, $text, $width, $over, %opts) = @_;

    # options of interest
    my $hyphenate = defined($opts{'-hyphenate'})? $opts{'-hyphenate'}: 0; # default off
   #my $lang = defined($opts{'-lang'})? $opts{'-lang'}: 'en';  # English rules by default
    my $lang = 'basic';
   #my $nosplit = defined($opts{'-nosplit'})? $opts{'-nosplit'}: '';  # indexes NOT to split at, given
                                            # as string of integers
   #       my @noSplit = split /[,\s]+/, $nosplit;  # normally empty array
	# 1. indexes start at 0 (split after character N not permitted)
	# 2. SHYs (soft hyphens) should be skipped
	# 3. need to map entire string's indexes to each word under
	#    consideration for splitting (hyphenation)

    # TBD should we consider any non-ASCII spaces?
    # don't split on non-breaking space (required blank).
    my @txt = split(/\x20/, $text);
    my @line = ();
    local $";  # intent is that reset of separator ($") is local to block
    $"=' ';   ## no critic
    my $lastWord = '';  # the one that didn't quite fit
    my $overflowed = 0;

    while (@txt) {
	 # build up @line from @txt array until overfills line.
	 # need to remove SHYs (soft hyphens) at this point.
	 $lastWord = shift @txt;  # preserve any SHYs in the word
         push @line, (_removeSHY($lastWord));
	 # one space between each element of line, like join(' ', @line)
         $overflowed = $self->advancewidth("@line") > $width;
	 last if $overflowed;
    }
    # if overflowed, and overflow not allowed, remove the last word added, 
    # unless single word in line and we're not going to attempt word splitting.
    if ($overflowed && !$over) {
	if ($hyphenate && @line == 1 || @line > 1) {
	    pop @line;  # discard last (or only) word
            unshift @txt,$lastWord; # restore with SHYs intact
        }
	# if not hyphenating (splitting words), just leave oversized 
	# single-word line. if hyphenating, could have empty @line.
    }

    my $Txt = "@txt";   # remaining text to put on next line
    my $Line = "@line"; # line that fits, but not yet with any split word
                        # may be empty if first word in line overflows

    # if we try to hyphenate, try splitting up that last word that
    # broke the camel's back. otherwise, will return $Line and $Txt as is.
    if ($hyphenate && $overflowed) {
	my $space;
	# @line is current whole word list of line, does NOT overflow because
	# $lastWord was removed. it may be empty if the first word tried was
	# too long. @txt is whole word list of the remaining words to be output 
	# (includes $lastWord as its first word).
	#
	# we want to try splitting $lastWord into short enough left fragment
	# (with right fragment remainder as first word of next line). if we
	# fail to do so, just leave whole word as first word of next line, IF
	# @line was not empty. if @line was empty, accept the overflow and
	# output $lastWord as @line and remove it from @txt.
	if (@line) {
	    # line not empty. $space is width for word fragment, not
	    # including blank after previous last word of @line.
	    $space = $width - $self->advancewidth("@line ");
	} else {
	    # line empty (first word too long, and we can try hyphenating).
	    # $space is entire $width available for left fragment.
	    $space = $width;
	}

	if ($space > 0) {
	    my ($wordLeft, $wordRight);
	    # @line is word(s) (if any) currently fitting within $width.
	    # @txt is remaining words unused in this line. $lastWord is first
	    # word of @txt. $space is width remaining to fill in line.
            $wordLeft = ''; $wordRight = $lastWord; # fallbacks

	    # if there is an error in Hyphenate_$lang, the message may be
	    # that the splitWord() function can't be found. debug errors by
	    # hard coding the require and splitWord() calls.

           ## test that Hyphenate_$lang exists. if not, use Hyphenate_en
	   ## TBD: if Hyphenate_$lang is not found, should we fall back to
	   ##      English (en) rules, or turn off hyphenation, or do limited
	   ##      hyphenation (nothing language-specific)?
	    # only Hyphenate_basic. leave language support to other packages
            require PDF::Builder::Content::Hyphenate_basic;
 	   #eval "require PDF::Builder::Content::Hyphenate_$lang";
           #if ($@) { 
	       #print "something went wrong with require eval: $@\n"; 
	       #$lang = 'en';  # perlmonks 27443   fall back to English
               #require PDF::Builder::Content::Hyphenate_en;
	   #}
            ($wordLeft,$wordRight) = PDF::Builder::Content::Hyphenate_basic::splitWord($self, $lastWord, $space, %opts);
           #eval '($wordLeft,$wordRight) = PDF::Builder::Content::Hyphenate_'.$lang.'::splitWord($self, "$lastWord", $space, %opts)';
	    if ($@) { print "something went wrong with eval: $@\n"; }

	    # $wordLeft is left fragment of $lastWord that fits in $space.
	    # it might be empty '' if couldn't get a small enough piece. it
	    # includes a hyphen, but no leading space, and can be added to
	    # @line.
	    # $wordRight is the remainder of $lastWord (right fragment) that
	    # didn't fit. it might be the entire $lastWord. it shouldn't be
	    # empty, since the whole point of the exercise is that $lastWord
	    # didn't fit in the remaining space. it will replace the first
	    # element of @txt (there should be at least one).
	    
	    # see if have a small enough left fragment of $lastWord to append
	    # to @line. neither left nor right Word should have full $lastWord,
	    # and both cannot be empty. it is highly unlikely that $wordLeft
	    # will be the full $lastWord, but quite possible that it is empty
	    # and $wordRight is $lastWord.

	    if (!@line) {
		# special case of empty line. if $wordLeft is empty and 
		# $wordRight is presumably the entire $lastWord, use $wordRight 
		# for the line and remove it ($lastWord) from @txt.
		if ($wordLeft eq '') {
		    @line = ($wordRight);  # probably overflows $width.
		    shift @txt;  # remove $lastWord from @txt.
		} else {
		    # $wordLeft fragment fits $width.
		    @line = ($wordLeft);  # should fit $width.
		    shift @txt; # replace first element of @txt ($lastWord)
		    unshift @txt, $wordRight;
		}
	    } else {
		# usual case of some words already in @line. if $wordLeft is 
		# empty and $wordRight is entire $lastWord, we're done here.
		# if $wordLeft has something, append it to line and replace
		# first element of @txt with $wordRight (unless empty, which
		# shouldn't happen).
	        if ($wordLeft eq '') {
	            # was unable to split $lastWord into short enough fragment.
		    # leave @line (already has words) and @txt alone.
	        } else {
                    push @line, ($wordLeft);  # should fit $space.
		    shift @txt; # replace first element of @txt (was $lastWord)
		    unshift @txt, $wordRight if $wordRight ne '';
	        }
	    }

	    # rebuild $Line and $Txt, in case they were altered.
            $Txt = "@txt";
            $Line = "@line";
	}  # there was $space available to try to fit a word fragment
    }  # we had an overflow to clean up, and hyphenation (word splitting) OK
    return ($Line, $Txt);
}

# remove soft hyphens (SHYs) from a word. assume is always #173 (good for
# Latin-1, CP-1252, UTF-8; might not work for some encodings)  TBD
sub _removeSHY {
    my ($word) = @_;

    my @chars = split //, $word;
    my $out = '';
    foreach (@chars) {
        next if ord($_) == 173;
	$out .= $_;
    }
    return $out;
}

=over

=item ($width, $leftover) = $content->text_fill_left($string, $width, %opts)

=item ($width, $leftover) = $content->text_fill_left($string, $width)

Fill a line of 'width' with as much text as will fit, 
and outputs it left justified.
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

=item ($width, $leftover) = $content->text_fill($string, $width, %opts)

=item ($width, $leftover) = $content->text_fill($string, $width)

Alias for text_fill_left().

=back

=cut

sub text_fill_left {
    my ($self, $text, $width, %opts) = @_;

    my $over = (not(defined($opts{'-spillover'}) and $opts{'-spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    $width = $self->text($line, %opts);
    return ($width, $ret);
}

sub text_fill { 
    my $self = shift;
    return $self->text_fill_left(@_); 
}

=over

=item ($width, $leftover) = $content->text_fill_center($string, $width, %opts)

=item ($width, $leftover) = $content->text_fill_center($string, $width)

Fill a line of 'width' with as much text as will fit, 
and outputs it centered.
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

=back

=cut

sub text_fill_center {
    my ($self, $text, $width, %opts) = @_;

    my $over = (not(defined($opts{'-spillover'}) and $opts{'-spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    $width = $self->text_center($line, %opts);
    return ($width, $ret);
}

=over

=item ($width, $leftover) = $content->text_fill_right($string, $width, %opts)

=item ($width, $leftover) = $content->text_fill_right($string, $width)

Fill a line of 'width' with as much text as will fit, 
and outputs it right justified.
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

=back

=cut

sub text_fill_right {
    my ($self, $text, $width, %opts) = @_;

    my $over = (not(defined($opts{'-spillover'}) and $opts{'-spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    $width = $self->text_right($line, %opts);
    return ($width, $ret);
}

=over

=item ($width, $leftover) = $content->text_fill_justified($string, $width, %opts)

=item ($width, $leftover) = $content->text_fill_justified($string, $width)

Fill a line of 'width' with as much text as will fit, 
and outputs it fully justified (stretched or condensed).
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

Note that the entire line is fit to the available 
width via a call to C<text_justified>. 
The last line is unjustified (normal size) and left aligned by default, although
the option

B<Options:>

=over

=item -last_align => place

where place is 'left' (default), 'center', or 'right' allows you to specify
the alignment of the last line output.

=back

=back

=cut

sub text_fill_justified {
    my ($self, $text, $width, %opts) = @_;

    my $align = 'l'; # default left align last line
    if (defined($opts{'-last_align'})) {
	if    ($opts{'-last_align'} =~ m/^l/i) { $align = 'l'; }
	elsif ($opts{'-last_align'} =~ m/^c/i) { $align = 'c'; }
	elsif ($opts{'-last_align'} =~ m/^r/i) { $align = 'r'; }
	else { die "Unknown -last_align for justified fill\n"; }
    }

    my $over = (not(defined($opts{'-spillover'}) and $opts{'-spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    # if last line, use $align (don't justify)
    if ($ret eq '') {
	my $lw = $self->advancewidth($line);
	if      ($align eq 'l') {
	    $width = $self->text($line, %opts);
	} elsif ($align eq 'c') {
	    $width = $self->text($line, -indent => ($width-$lw)/2, %opts);
	} else {  # 'r'
	    $width = $self->text($line, -indent => ($width-$lw), %opts);
	}
    } else {
        $width = $self->text_justified($line, $width, %opts);
    }
    return ($width, $ret);
}

=over

=item ($overflow_text, $unused_height) = $txt->paragraph($text, $width,$height, $continue, %opts)

=item ($overflow_text, $unused_height) = $txt->paragraph($text, $width,$height, $continue)

=item $overflow_text = $txt->paragraph($text, $width,$height, $continue, %opts)

=item $overflow_text = $txt->paragraph($text, $width,$height, $continue)

Print a single string into a rectangular area on the page, of given width and
maximum height. The baseline of the first (top) line is at the current text
position.

Apply the text within the rectangle and B<return> any leftover text (if could 
not fit all of it within the rectangle). If called in an array context, the 
unused height is also B<returned> (may be 0 or negative if it just filled the 
rectangle).

If C<$continue> is 1, the first line does B<not> get special treatment for
indenting or outdenting, because we're printing the continuation of the 
paragraph that was interrupted earlier. If it's 0, the first line may be 
indented or outdented.

B<Options:>

=over

=item -pndnt => $indent

Give the amount of indent (positive) or outdent (negative, for "hanging")
for paragraph first lines). This setting is ignored for centered text.

=item -align => $choice

C<$choice> is 'justified', 'right', 'center', 'left'; the default is 'left'.

=item -underline => $distance

=item -underline => [ $distance, $thickness, ... ]

If a scalar, distance below baseline,
else array reference with pairs of distance and line thickness.

=item -spillover => $over

Controls if words in a line which exceed the given width should be 
"spilled over" the bounds, or if a new line should be used for this word.

C<$over> is 1 or 0, with the default 1 (spills over the width).

=back

B<Example:>

    $txt->font($font,$fontsize);
    $txt->lead($lead);
    $txt->translate($x,$y);
    $overflow = $txt->paragraph( 'long paragraph here ...',
                                 $width,
                                 $y+$lead-$bottom_margin );

B<Note:> if you need to change any text treatment I<within> a paragraph 
(B<bold> or I<italicized> text, for instance), this can not handle it. Only 
plain text (all the same font, size, etc.) can be typeset with C<paragraph()>.
Also, there is currently very limited line splitting (hypenation) to better 
fit to a given width, and nothing is done for "widows and orphans".

=back

=cut

# TBD for LTR languages, does indenting on left make sense for right justified?
# TBD for bidi languages, should indenting be on right?

sub paragraph {
    my ($self, $text, $width,$height, $continue, %opts) = @_;

    my @line = ();
    my $nwidth = 0;
    my $lead = $self->lead();
    my $align = 'l'; # default left
    if (defined($opts{'-align'})) {
	if    ($opts{'-align'} =~ /^l/i) { $align = 'l'; }
	elsif ($opts{'-align'} =~ /^c/i) { $align = 'c'; }
	elsif ($opts{'-align'} =~ /^r/i) { $align = 'r'; }
	elsif ($opts{'-align'} =~ /^j/i) { $align = 'j'; }
	else { die "Unknown -align value for paragraph()\n"; }
    } # default stays at 'l'
    my $indent = defined($opts{'-pndnt'})? $opts{'-pndnt'}: 0;
    if ($align eq 'c') { $indent = 0; } # indent/outdent makes no sense centered
    my $first_line = !$continue;
    my $lw;
    my $em = $self->advancewidth('M');

    while (length($text) > 0) { # more text to go...
	# indent == 0 (flush) all lines normal width
	# indent (>0) first line moved in on left, subsequent normal width
	# outdent (<0) first line is normal width, subsequent moved in on left
	$lw = $width;
	if ($indent > 0 && $first_line) { $lw -= $indent*$em; }
	if ($indent < 0 && !$first_line) { $lw += $indent*$em; }
	# now, need to indent (move line start) right for 'l' and 'j'
	if ($lw < $width && ($align eq 'l' || $align eq 'j')) {
        $self->cr($lead); # go UP one line
	    $self->nl(88*abs($indent)); # come down to right line and move right
	}

        if      ($align eq 'j') {
            ($nwidth,$text) = $self->text_fill_justified($text, $lw, %opts);
        } elsif ($align eq 'r') {
            ($nwidth,$text) = $self->text_fill_right($text, $lw, %opts);
        } elsif ($align eq 'c') {
            ($nwidth,$text) = $self->text_fill_center($text, $lw, %opts);
        } else {  # 'l'
            ($nwidth,$text) = $self->text_fill_left($text, $lw, %opts);
        }

        $self->nl();
	$first_line = 0;

	# bail out and just return remaining $text if run out of vertical space
        last if ($height -= $lead) < 0;
    }

    if (wantarray) {
	# paragraph() called in the context of returning an array
        return ($text, $height);
    }
    return $text;
}

=over

=item ($overflow_text, $continue, $unused_height) = $txt->section($text, $width,$height, $continue, %opts)

=item ($overflow_text, $continue, $unused_height) = $txt->section($text, $width,$height, $continue)

=item $overflow_text = $txt->section($text, $width,$height, $continue, %opts)

=item $overflow_text = $txt->section($text, $width,$height, $continue)

The C<$text> contains a string with one or more paragraphs C<$width> wide, 
starting at the current text position, with a newline \n between each 
paragraph. Each paragraph is output (see C<paragraph>) until the C<$height> 
limit is met (a partial paragraph may be at the bottom). Whatever wasn't 
output, will be B<returned>.
If called in an array context, the 
unused height and the paragraph "continue" flag are also B<returned>.

C<$continue> is 0 for the first call of section(), and then use the value 
returned from the previous call (1 if a paragraph was cut in the middle) to 
prevent unwanted indenting or outdenting of the first line being printed.

B<Options:>

=over

=item -pvgap => $vertical

Additional vertical space (unit: pt) between paragraphs (default 0). Note that this space
will also be added after the last paragraph printed.

=back

See C<paragraph> for other C<%opts> you can use, such as -align and -pndnt.

=back

=cut

sub section {
    my ($self, $text, $width,$height, $continue, %opts) = @_;

    my $overflow = ''; # text to return if height fills up
    my $pvgap = defined($opts{'-pvgap'})? $opts{'-pvgap'}: 0;
    # $continue =0 if fresh paragraph, or =1 if continuing one cut in middle

    foreach my $para (split(/\n/, $text)) {
	# regardless of whether we've run out of space vertically, we will
	# loop through all the paragraphs requested
	
	# already seen inability to output more text?
	# just put unused text back together into the string
	# $continue should stay 1
        if (length($overflow) > 0) {
            $overflow .= "\n" . $para;
            next;
        }
        ($para, $height) = $self->paragraph($para, $width,$height, $continue, %opts);
	$continue = 0;
	if (length($para) > 0) {
	    # we cut a paragraph in half. set flag that continuation doesn't
	    # get indented/outdented
            $overflow .= $para;
	    $continue = 1;
	}

	# inter-paragraph vertical space?
	# note that the last paragraph will also get the extra space after it
	if (length($para) == 0 && $pvgap != 0) { 
	    $self->cr(-$pvgap);
	    $height -= $pvgap;
        }
    }

    if (wantarray) {
	# section() called in the context of returning an array
        return ($overflow, $continue, $height);
    }
    return $overflow;
}

=over

=item $width = $txt->textlabel($x,$y, $font, $size, $text, %opts)

=item $width = $txt->textlabel($x,$y, $font, $size, $text)

Place a line of text at an arbitrary C<[$x,$y]> on the page, with various text 
settings (treatments) specified in the call.

=over

=item $font

A previously created font.

=item $size

The font size (points).

=item $text

The text to be printed (a single line).

=back

B<Options:>

=over

=item -rotate => $deg

Rotate C<$deg> degrees counterclockwise from due East.

=item -color => $cspec

A color name or permitted spec, such as C<#CCE840>, for the character I<fill>.

=item -strokecolor => $cspec

A color name or permitted spec, such as C<#CCE840>, for the character I<outline>.

=item -charspace => $cdist

Additional distance between characters.

=item -wordspace => $wdist

Additional distance between words.

=item -hscale => $hfactor

Horizontal scaling mode (percentage of normal, default is 100).

=item -render => $mode

Character rendering mode (outline only, fill only, etc.). See C<render> call.

=item -left => 1

Left align on the given point. This is the default.

=item -center => 1

Center the text on the given point.

=item -right => 1

Right align on the given point.

=item -align => $placement

Alternate to -left, -center, and -right. C<$placement> is 'left' (default),
'center', or 'right'.

=back

Other options available to C<text>, such as underlining, can be used here.

The width used is B<returned>.

=back

=cut

sub textlabel {
    my ($self, $x,$y, $font, $size, $text, %opts) = @_;
    # removed: $wht was in parameter list after %opts, but is not an input
    my $wht;

    my %trans_opts = ( -translate => [$x,$y] );
    my %text_state = ();
    $trans_opts{'-rotate'} = $opts{'-rotate'} if defined($opts{'-rotate'});

    my $wastext = $self->_in_text_object();
    if ($wastext) {
        %text_state = $self->textstate();
        $self->textend();
    }
    $self->save();
    $self->textstart();

    $self->transform(%trans_opts);

    $self->fillcolor(ref($opts{'-color'}) ? @{$opts{'-color'}} : $opts{'-color'}) if defined($opts{'-color'});
    $self->strokecolor(ref($opts{'-strokecolor'}) ? @{$opts{'-strokecolor'}} : $opts{'-strokecolor'}) if defined($opts{'-strokecolor'});

    $self->font($font, $size);

    $self->charspace($opts{'-charspace'}) if defined($opts{'-charspace'});
    $self->hscale($opts{'-hscale'})       if defined($opts{'-hscale'});
    $self->wordspace($opts{'-wordspace'}) if defined($opts{'-wordspace'});
    $self->render($opts{'-render'})       if defined($opts{'-render'});

    if      (defined($opts{'-right'}) && $opts{'-right'} ||
	     defined($opts{'-align'}) && $opts{'-align'} =~ /^r/i) {
        $wht = $self->text_right($text, %opts);
    } elsif (defined($opts{'-center'}) && $opts{'-center'} ||
	     defined($opts{'-align'}) && $opts{'-align'} =~ /^c/i) {
        $wht = $self->text_center($text, %opts);
    } elsif (defined($opts{'-left'}) && $opts{'-left'} ||
	     defined($opts{'-align'}) && $opts{'-align'} =~ /^l/i) {
        $wht = $self->text($text, %opts);  # explicitly left aligned
    } else {
        $wht = $self->text($text, %opts);  # left aligned by default
    }

    $self->textend();
    $self->restore();

    if ($wastext) {
        $self->textstart();
        $self->textstate(%text_state);
    }
    return $wht;
}

1;
