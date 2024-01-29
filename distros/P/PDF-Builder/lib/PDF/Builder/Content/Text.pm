package PDF::Builder::Content::Text;

use base 'PDF::Builder::Content';

use strict;
use warnings;
use Carp;
use List::Util qw(min max);
#use Data::Dumper;  # for debugging
#  $Data::Dumper::Sortkeys = 1;  # hash keys in sorted order

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Content::Text - additional specialized text-related formatting methods. Inherits from L<PDF::Builder::Content>

B<Note:> If you have used some of these methods in PDF::Builder with a 
I<graphics> 
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

=head2 Single Lines from a String

=head3 text_left

    $width = $content->text_left($text, %opts)

=over

Alias for C<text>. Implemented for symmetry, for those who use a lot of
C<text_center> and C<text_right>, and desire a matching C<text_left>.

Adds text to the page (left justified), at the current position. 
Note that there is no maximum width, and nothing to keep you from overflowing
the physical page on the right!
The width used (in points) is B<returned>.

=back

=cut

sub text_left {
    my ($self, $text, @opts) = @_;

    # override any stray 'align' that got through to here
    return $self->text($text, @opts, 'align'=>'l');
}

=head3 text_center

    $width = $content->text_center($text, %opts)

=over

As C<text>, but I<centered> on the current point.

Adds text to the page (centered). 
The width used (in points) is B<returned>.

=back

=cut

sub text_center {
    my ($self, $text, @opts) = @_;

    # override any stray 'align' that got through to here
    return $self->text($text, @opts, 'align'=>'c');
}

=head3 text_right

    $width = $content->text_right($text, %opts)

=over

As C<text>, but right-aligned to the current point.

Adds text to the page (right justified). 
Note that there is no maximum width, and nothing to keep you from overflowing
the physical page on the left!
The width used (in points) is B<returned>.

=back

=cut

sub text_right {
    my ($self, $text, @opts) = @_;

    # override any stray 'align' that got through to here
    return $self->text($text, @opts, 'align'=>'r');
}

=head3 text_justified

    $width = $content->text_justified($text, $width, %opts)

=over
 
As C<text>, but stretches text using C<wordspace>, C<charspace>, and (as a  
last resort) C<hscale>, to fill the desired
(available) C<$width>. Note that if the desired width is I<less> than the
natural width taken by the text, it will be I<condensed> to fit, using the
same three routines.

The unchanged C<$width> is B<returned>, unless there was some reason to
change it (e.g., overflow).

B<Options:>

=over

=item 'nocs' => value

If this option value is 1 (default 0), do B<not> use any intercharacter
spacing. This is useful for connected characters, such as fonts for Arabic,
Devanagari, Latin cursive handwriting, etc. You don't want to add additional
space between characters during justification, which would disconnect them.

I<Word> (interword) spacing values (explicit or default) are doubled if
nocs is 1. This is to make up for the lack of added/subtracted intercharacter
spacing.

=item 'wordsp' => value

The percentage of one space character (default 100) that is the maximum amount
to add to (each) interword spacing to expand the line.
If C<nocs> is 1, double C<value>.

=item 'charsp' => value

If adding interword space didn't do enough, the percentage of one em (default 
100) that is the maximum amount to add to (each) intercharacter spacing to 
further expand the line.
If C<nocs> is 1, force C<value> to 0.

=item 'wordspa' => value

If adding intercharacter space didn't do enough, the percentage of one space
character (default 100) that is the maximum I<additional> amount to add to 
(each) interword spacing to further expand the line.
If C<nocs> is 1, double C<value>.

=item 'charspa' => value

If adding more interword space didn't do enough, the percentage of one em 
(default 100) that is the maximum I<additional> amount to add to (each) 
intercharacter spacing to further expand the line.
If C<nocs> is 1, force C<value> to 0.

=item 'condw' => value

The percentage of one space character (default 25) that is the maximum amount
to subtract from (each) interword spacing to condense the line.
If C<nocs> is 1, double C<value>.

=item 'condc' => value

If removing interword space didn't do enough, the percentage of one em
(default 10) that is the maximum amount to subtract from (each) intercharacter
spacing to further condense the line.
If C<nocs> is 1, force C<value> to 0.

=back

If expansion (or reduction) wordspace and charspace changes didn't do enough 
to make the line fit the desired width, use C<hscale()> to finish expanding or 
condensing the line to fit.

=back

=cut

sub text_justified {
    my ($self, $text, $width, %opts) = @_;
    # copy dashed option names to the preferred undashed names
    if (defined $opts{'-wordsp'} && !defined $opts{'wordsp'}) { $opts{'wordsp'} = delete($opts{'-wordsp'}); }
    if (defined $opts{'-charsp'} && !defined $opts{'charsp'}) { $opts{'charsp'} = delete($opts{'-charsp'}); }
    if (defined $opts{'-wordspa'} && !defined $opts{'wordspa'}) { $opts{'wordspa'} = delete($opts{'-wordspa'}); }
    if (defined $opts{'-charspa'} && !defined $opts{'charspa'}) { $opts{'charspa'} = delete($opts{'-charspa'}); }
    if (defined $opts{'-condw'} && !defined $opts{'condw'}) { $opts{'condw'} = delete($opts{'-condw'}); }
    if (defined $opts{'-condc'} && !defined $opts{'condc'}) { $opts{'condc'} = delete($opts{'-condc'}); }
    if (defined $opts{'-nocs'} && !defined $opts{'nocs'}) { $opts{'nocs'} = delete($opts{'-nocs'}); }

    # optional parameters to control how expansion or condensation are done
    # 1. expand interword space up to 100% of 1 space
    my $wordsp = defined($opts{'wordsp'})? $opts{'wordsp'}: 100;
    # 2. expand intercharacter space up to 100% of 1em
    my $charsp = defined($opts{'charsp'})? $opts{'charsp'}: 100;
    # 3. expand interword space up to another 100% of 1 space
    my $wordspa = defined($opts{'wordspa'})? $opts{'wordspa'}: 100;
    # 4. expand intercharacter space up to another 100% of 1em
    my $charspa = defined($opts{'charspa'})? $opts{'charspa'}: 100;
    # 5. condense interword space up to 25% of 1 space
    my $condw = defined($opts{'condw'})? $opts{'condw'}: 25;
    # 6. condense intercharacter space up to 10% of 1em
    my $condc = defined($opts{'condc'})? $opts{'condc'}: 10;
    # 7. if still short or long, hscale()

    my $nocs = defined($opts{'nocs'})? $opts{'nocs'}: 0;
    if ($nocs) {
        $charsp = $charspa = $condc = 0;
	$wordsp *= 2;
	$wordspa *= 2;
	$condw *= 2;
    }

    # with original wordspace, charspace, and hscale settings
    # note that we do NOT change any existing charspace here
    my $length = $self->advancewidth($text, %opts);
    my $overage = $length - $width; # > 0, raw text is too wide, < 0, narrow

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
	if ($chars[$i] eq ' ') { $num_spaces++; } # TBD other whitespace?
	$num_chars++;  # count spaces as characters, too
    }
    my $em = $self->advancewidth('M');
    my $sp = $self->advancewidth(' ');

    if ($overage > 0) {
	# too wide: need to condense it
	# 1. subtract from interword space, up to -$condw/100 $sp
	if ($overage > 0 && $num_spaces > 0 && $condw > 0) {
	    $val = $overage/$num_spaces;
	    $limit = $condw/100*$sp;
	    if ($val > $limit) { $val = $limit; }
	    $self->wordspace(-$val);
	    $overage -= $val*$num_spaces;
	}
	# 2. subtract from intercharacter space, up to -$condc/100 $em
	if ($overage > 0 && $num_chars > 0 && $condc > 0) {
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
	if ($overage > 0 && $num_spaces > 0 && $wordsp > 0) {
	    $val = $overage/$num_spaces;
	    $limit = $wordsp/100*$sp;
	    if ($val > $limit) { $val = $limit; }
	    $self->wordspace($val);
	    $overage -= $val*$num_spaces;
	}
	# 2. add to intercharacter space, up to $charsp/100 $em
	if ($overage > 0 && $num_chars > 0 && $charsp > 0) {
	    $val = $overage/$num_chars;
	    $limit = $charsp/100*$em;
	    if ($val > $limit) { $val = $limit; }
	    $self->charspace($val);
	    $overage -= $val*$num_chars;
	}
	# 3. add to interword space, up to $wordspa/100 $sp additional
	if ($overage > 0 && $num_spaces > 0 && $wordspa > 0) {
	    $val = $overage/$num_spaces;
	    $limit = $wordspa/100*$sp;
	    if ($val > $limit) { $val = $limit; }
	    $self->wordspace($val+$self->wordspace());
	    $overage -= $val*$num_spaces;
	}
	# 4. add to intercharacter space, up to $charspa/100 $em additional
	if ($overage > 0 && $num_chars > 0 && $charspa > 0) {
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
    if ($overage > 0.1) {
        $self->hscale(100*($width/$self->advancewidth($text, %opts)));
    }

    } # original $overage was not near 0
    # do the output, with wordspace, charspace, and possiby hscale changed
    # override any stray 'align' that got through to here
    $self->text($text, %opts, 'align'=>'l');

    # restore settings
    $self->hscale($hs); $self->wordspace($ws); $self->charspace($cs);

    return $width;
}

=head2 Multiple Lines from a String

The string is split at regular blanks (spaces), x20, to find the longest 
substring that will fit the C<$width>. 
If a single word is longer than C<$width>, it will overflow. 
To stay strictly within the desired bounds, set the option
C<spillover>=E<gt>0 to disallow spillover.

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
more desirable I<paragraph shaping>.

=over

=item 'hyphenate' => value

0: no hyphenation (B<default>), 1: do basic hyphenation. Always allows
splitting at a soft hyphen (\xAD). Unicode hyphen (U+2010) and non-splitting
hyphen (U+2011) are ignored as split points.

=item 'spHH' => value

0: do I<not> split at a hard hyphen (x\2D), 1: I<OK to split> (B<default>)

=item 'spOP' => value

0: do I<not> split after most punctuation, 1: I<OK to split> (B<default>)

=item 'spDR' => value

0: do I<not> split after a run of one or more digits, 1: I<OK to split> (B<default>)

=item 'spLR' => value

0: do I<not> split after a run of one or more ASCII letters, 1: I<OK to split> (B<default>)

=item 'spCC' => value

0: do I<not> split in camelCase between a lowercase letter and an
uppercase letter, 1: I<OK to split> (B<default>)

=item 'spRB' => value

0: do I<not> split on a Required Blank (&nbsp;), is B<default>.
1: I<OK to split on Required Blank.> Try to avoid this; it is a desperation 
move!

=item 'spFS' => value

0: do I<not> split where it will I<just> fit (middle of word!), is B<default>.
1: I<OK to split to just fit the available space.> Try to avoid this; it is a 
super desperation move, and the split will probably make no linguistic sense!

=item 'min_prefix' => value

Minimum number of letters I<before> word split point (hyphenation point).
The B<default> is 2.

=item 'min_suffix' => value

Minimum number of letters I<after> word split point (hyphenation point).
The B<default> is 3.

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
    # copy dashed option names to the preferred undashed names
    if (defined $opts{'-hyphenate'} && !defined $opts{'hyphenate'}) { $opts{'hyphenate'} = delete($opts{'-hyphenate'}); }
    if (defined $opts{'-lang'} && !defined $opts{'lang'}) { $opts{'lang'} = delete($opts{'-lang'}); }
    if (defined $opts{'-nosplit'} && !defined $opts{'nosplit'}) { $opts{'nosplit'} = delete($opts{'-nosplit'}); }

    # options of interest
    my $hyphenate = defined($opts{'hyphenate'})? $opts{'hyphenate'}: 0; # default off
   #my $lang = defined($opts{'lang'})? $opts{'lang'}: 'en';  # English rules by default
    my $lang = 'basic';
   #my $nosplit = defined($opts{'nosplit'})? $opts{'nosplit'}: '';  # indexes NOT to split at, given
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
         $overflowed = $self->advancewidth("@line", %opts) > $width;
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
	    $space = $width - $self->advancewidth("@line ", %opts);
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

=head4 text_fill_left, text_fill

    ($width, $leftover) = $content->text_fill_left($string, $width, %opts)

=over

Fill a line of 'width' with as much text as will fit, 
and outputs it left justified.
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

=back

    ($width, $leftover) = $content->text_fill($string, $width, %opts)

=over

Alias for text_fill_left().

=back

=cut

sub text_fill_left {
    my ($self, $text, $width, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-spillover'} && !defined $opts{'spillover'}) { $opts{'spillover'} = delete($opts{'-spillover'}); }

    my $over = (not(defined($opts{'spillover'}) and $opts{'spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    # override any stray 'align' that got through to here
    $width = $self->text($line, %opts, 'align'=>'l');
    return ($width, $ret);
}

sub text_fill { 
    my $self = shift;
    return $self->text_fill_left(@_); 
}

=head4 text_fill_center

    ($width, $leftover) = $content->text_fill_center($string, $width, %opts)

=over

Fill a line of 'width' with as much text as will fit, 
and outputs it centered.
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

=back

=cut

sub text_fill_center {
    my ($self, $text, $width, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-spillover'} && !defined $opts{'spillover'}) { $opts{'spillover'} = delete($opts{'-spillover'}); }

    my $over = (not(defined($opts{'spillover'}) and $opts{'spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    $width = $self->text_center($line, %opts);
    return ($width, $ret);
}

=head4 text_fill_right

    ($width, $leftover) = $content->text_fill_right($string, $width, %opts)

=over

Fill a line of 'width' with as much text as will fit, 
and outputs it right justified.
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

=back

=cut

sub text_fill_right {
    my ($self, $text, $width, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-spillover'} && !defined $opts{'spillover'}) { $opts{'spillover'} = delete($opts{'-spillover'}); }

    my $over = (not(defined($opts{'spillover'}) and $opts{'spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    $width = $self->text_right($line, %opts);
    return ($width, $ret);
}

=head4 text_fill_justified

    ($width, $leftover) = $content->text_fill_justified($string, $width, %opts)

=over

Fill a line of 'width' with as much text as will fit, 
and outputs it fully justified (stretched or condensed).
The width actually used, and the leftover text (that didn't fit), 
are B<returned>.

Note that the entire line is fit to the available 
width via a call to C<text_justified>. 
See C<text_justified> for options to control stretch and condense.
The last line is unjustified (normal size) and left aligned by default, 
although the option

B<Options:>

=over

=item 'last_align' => place

where place is 'left' (default), 'center', or 'right' (may be shortened to
first letter) allows you to specify the alignment of the last line output.

=back

=back

=cut

sub text_fill_justified {
    my ($self, $text, $width, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-last_align'} && !defined $opts{'last_align'}) { $opts{'last_align'} = delete($opts{'-last_align'}); }
    if (defined $opts{'-spillover'} && !defined $opts{'spillover'}) { $opts{'spillover'} = delete($opts{'-spillover'}); }

    my $align = 'l'; # default left align last line
    if (defined($opts{'last_align'})) {
	if    ($opts{'last_align'} =~ m/^l/i) { $align = 'l'; }
	elsif ($opts{'last_align'} =~ m/^c/i) { $align = 'c'; }
	elsif ($opts{'last_align'} =~ m/^r/i) { $align = 'r'; }
	else { warn "Unknown last_align for justified fill, 'left' used\n"; }
    }

    my $over = (not(defined($opts{'spillover'}) and $opts{'spillover'} == 0));
    my ($line, $ret) = $self->_text_fill_line($text, $width, $over, %opts);
    # if last line, use $align (don't justify)
    if ($ret eq '') {
	my $lw = $self->advancewidth($line, %opts);
        # override any stray 'align' that got through to here
	if      ($align eq 'l') {
	    $width = $self->text($line, %opts, 'align'=>'l');
	} elsif ($align eq 'c') {
	    $width = $self->text($line, 'indent' => ($width-$lw)/2, %opts, 'align'=>'l');
	} else {  # 'r'
	    $width = $self->text($line, 'indent' => ($width-$lw), %opts, 'align'=>'l');
	}
    } else {
        $width = $self->text_justified($line, $width, %opts);
    }
    return ($width, $ret);
}

=head2 Larger Text Segments

=head3 paragraph

    ($overflow_text, $unused_height) = $txt->paragraph($text, $width,$height, $continue, %opts)

    ($overflow_text, $unused_height) = $txt->paragraph($text, $width,$height, %opts)

    $overflow_text = $txt->paragraph($text, $width,$height, $continue, %opts)

    $overflow_text = $txt->paragraph($text, $width,$height, %opts)

=over

Print a single string into a rectangular area on the page, of given width and
maximum height. The baseline of the first (top) line is at the current text
position.

Apply the text within the rectangle and B<return> any leftover text (if could 
not fit all of it within the rectangle). If called in an array context, the 
unused height is also B<returned> (may be 0 or negative if it just filled the 
rectangle).

C<$continue> is optional, with a default value of 0. An C<%opts> list may be
given after the fixed parameters, whether or not C<$continue> is explicitly
given.

If C<$continue> is 1, the first line does B<not> get special treatment for
indenting or outdenting, because we're printing the continuation of the 
paragraph that was interrupted earlier. If it's 0, the first line may be 
indented or outdented.

B<Options:>

=over

=item 'pndnt' => $indent

Give the amount of indent (positive) or outdent (negative, for "hanging")
for paragraph first lines). This setting is ignored for centered text.

=item 'align' => $choice

C<$choice> is 'justified', 'right', 'center', 'left'; the default is 'left'.
See C<text_justified> call for options to control how a line is expanded or
condensed if C<$choice> is 'justified'. C<$choice> may be shortened to the
first letter.

=item 'last_align' => place

where place is 'left' (default), 'center', or 'right' (may be shortened to
first letter) allows you to specify the alignment of the last line output,
but applies only when C<align> is 'justified'.

=item 'underline' => $distance

=item 'underline' => [ $distance, $thickness, ... ]

If a scalar, distance below baseline,
else array reference with pairs of distance and line thickness.

=item 'spillover' => $over

Controls if words in a line which exceed the given width should be 
"spilled over" the bounds, or if a new line should be used for this word.

C<$over> is 1 or 0, with the default 1 (spills over the width).

=back

B<Example:>

    $txt->font($font,$fontsize);
    $txt->leading($leading);
    $txt->translate($x,$y);
    $overflow = $txt->paragraph( 'long paragraph here ...',
                                 $width,
                                 $y+$leading-$bottom_margin );

B<Note:> if you need to change any text treatment I<within> a paragraph 
(B<bold> or I<italicized> text, for instance), this can not handle it. Only 
plain text (all the same font, size, etc.) can be typeset with C<paragraph()>.
Also, there is currently very limited line splitting (hyphenation) to better 
fit to a given width, and nothing is done for "widows and orphans".

=back

=cut

# TBD for LTR languages, does indenting on left make sense for right justified?
# TBD for bidi/RTL languages, should indenting be on right?

sub paragraph {
    my ($self, $text, $width,$height, @optsA) = @_;
    # if odd number of elements in optsA, it contains $continue flag and
    #   remainder is %opts. if even, paragraph is being called PDF::API2 style
    #   with no $continue (default to 0).
    my $continue = 0;
    if (@optsA % 2) {
	$continue = splice(@optsA, 0, 1);
    }
    my %opts = @optsA;

    # copy dashed option names to preferred undashed names
    if (defined $opts{'-align'} && !defined $opts{'align'}) { $opts{'align'} = delete($opts{'-align'}); }
    if (defined $opts{'-pndnt'} && !defined $opts{'pndnt'}) { $opts{'pndnt'} = delete($opts{'-pndnt'}); }

    my @line = ();
    my $nwidth = 0;
    my $leading = $self->leading();
    my $align = 'l'; # default left
    if (defined($opts{'align'})) {
	if    ($opts{'align'} =~ /^l/i) { $align = 'l'; }
	elsif ($opts{'align'} =~ /^c/i) { $align = 'c'; }
	elsif ($opts{'align'} =~ /^r/i) { $align = 'r'; }
	elsif ($opts{'align'} =~ /^j/i) { $align = 'j'; }
	else { warn "Unknown align value for paragraph(), 'left' used\n"; }
    } # default stays at 'l'
    my $indent = defined($opts{'pndnt'})? $opts{'pndnt'}: 0;
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
        $self->cr($leading); # go UP one line
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
        last if ($height -= $leading) < 0;
    }

    if (wantarray) {
	# paragraph() called in the context of returning an array
        return ($text, $height);
    }
    return $text;
}

=head3 section, paragraphs

    ($overflow_text, $continue, $unused_height) = $txt->section($text, $width,$height, $continue, %opts)

    $overflow_text = $txt->section($text, $width,$height, $continue, %opts)

=over

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

For compatibility with recent changes to PDF::API2, B<paragraphs> is accepted
as an I<alias> for C<section>.

B<Options:>

=over

=item 'pvgap' => $vertical

Additional vertical space (unit: pt) between paragraphs (default 0). Note that this space
will also be added after the last paragraph printed.

=back

See C<paragraph> for other C<%opts> you can use, such as C<align> and C<pndnt>.

B<Alternate name:> paragraphs

This is for compatibiity with PDF::API2.

=back

=cut

# alias for compatibility
sub paragraphs {
    return section(@_);
}

sub section {
    my ($self, $text, $width,$height, $continue, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-pvgap'} && !defined $opts{'pvgap'}) { $opts{'pvgap'} = delete($opts{'-pvgap'}); }

    my $overflow = ''; # text to return if height fills up
    my $pvgap = defined($opts{'pvgap'})? $opts{'pvgap'}: 0;
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

=head3 textlabel

    $width = $txt->textlabel($x,$y, $font, $size, $text, %opts)

=over

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

=item 'rotate' => $deg

Rotate C<$deg> degrees counterclockwise from due East.

=item 'color' => $cspec

A color name or permitted spec, such as C<#CCE840>, for the character I<fill>.

=item 'strokecolor' => $cspec

A color name or permitted spec, such as C<#CCE840>, for the character I<outline>.

=item 'charspace' => $cdist

Additional distance between characters.

=item 'wordspace' => $wdist

Additional distance between words.

=item 'hscale' => $hfactor

Horizontal scaling mode (percentage of normal, default is 100).

=item 'render' => $mode

Character rendering mode (outline only, fill only, etc.). See C<render> call.

=item 'left' => 1

Left align on the given point. This is the default.

=item 'center' => 1

Center the text on the given point.

=item 'right' => 1

Right align on the given point.

=item 'align' => $placement

Alternate to left, center, and right. C<$placement> is 'left' (default),
'center', or 'right'.

=back

Other options available to C<text>, such as underlining, can be used here.

The width used (in points) is B<returned>.

=back

B<Please note> that C<textlabel()> was not designed to interoperate with other
text operations. It is a standalone operation, and does I<not> leave a "next 
write" position (or any other setting) for another C<text> mode operation. A 
following write will likely be at C<(0,0)>, and not at the expected location.

C<textlabel()> is intended as an "all in one" convenience function for single 
lines of text, such as a label on some
graphics, and not as part of putting down multiple pieces of text. It I<is>
possible to figure out the position of a following write (either C<textlabel>
or C<text>) by adding the returned width to the original position's I<x> value
(assuming left-justified positioning).

=cut

sub textlabel {
    my ($self, $x,$y, $font, $size, $text, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-rotate'} && !defined $opts{'rotate'}) { $opts{'rotate'} = delete($opts{'-rotate'}); }
    if (defined $opts{'-color'} && !defined $opts{'color'}) { $opts{'color'} = delete($opts{'-color'}); }
    if (defined $opts{'-strokecolor'} && !defined $opts{'strokecolor'}) { $opts{'strokecolor'} = delete($opts{'-strokecolor'}); }
    if (defined $opts{'-charspace'} && !defined $opts{'charspace'}) { $opts{'charspace'} = delete($opts{'-charspace'}); }
    if (defined $opts{'-hscale'} && !defined $opts{'hscale'}) { $opts{'hscale'} = delete($opts{'-hscale'}); }
    if (defined $opts{'-wordspace'} && !defined $opts{'wordspace'}) { $opts{'wordspace'} = delete($opts{'-wordspace'}); }
    if (defined $opts{'-render'} && !defined $opts{'render'}) { $opts{'render'} = delete($opts{'-render'}); }
    if (defined $opts{'-right'} && !defined $opts{'right'}) { $opts{'right'} = delete($opts{'-right'}); }
    if (defined $opts{'-center'} && !defined $opts{'center'}) { $opts{'center'} = delete($opts{'-center'}); }
    if (defined $opts{'-left'} && !defined $opts{'left'}) { $opts{'left'} = delete($opts{'-left'}); }
    if (defined $opts{'-align'} && !defined $opts{'align'}) { $opts{'align'} = delete($opts{'-align'}); }
    my $wht;

    my %trans_opts = ( 'translate' => [$x,$y] );
    my %text_state = ();
    $trans_opts{'rotate'} = $opts{'rotate'} if defined($opts{'rotate'});

    my $wastext = $self->_in_text_object();
    if ($wastext) {
        %text_state = $self->textstate();
        $self->textend();
    }
    $self->save();
    $self->textstart();

    $self->transform(%trans_opts);

    $self->fillcolor(ref($opts{'color'}) ? @{$opts{'color'}} : $opts{'color'}) if defined($opts{'color'});
    $self->strokecolor(ref($opts{'strokecolor'}) ? @{$opts{'strokecolor'}} : $opts{'strokecolor'}) if defined($opts{'strokecolor'});

    $self->font($font, $size);

    $self->charspace($opts{'charspace'}) if defined($opts{'charspace'});
    $self->hscale($opts{'hscale'})       if defined($opts{'hscale'});
    $self->wordspace($opts{'wordspace'}) if defined($opts{'wordspace'});
    $self->render($opts{'render'})       if defined($opts{'render'});

    if      (defined($opts{'right'}) && $opts{'right'} ||
	     defined($opts{'align'}) && $opts{'align'} =~ /^r/i) {
        $wht = $self->text_right($text, %opts);
    } elsif (defined($opts{'center'}) && $opts{'center'} ||
	     defined($opts{'align'}) && $opts{'align'} =~ /^c/i) {
        $wht = $self->text_center($text, %opts);
    } elsif (defined($opts{'left'}) && $opts{'left'} ||
	     defined($opts{'align'}) && $opts{'align'} =~ /^l/i) {
        # override any stray 'align' that got through to here
        $wht = $self->text($text, %opts, 'align'=>'l');  # explicitly left aligned
    } else {
        # override any stray 'align' that got through to here
        $wht = $self->text($text, %opts, 'align'=>'l');  # left aligned by default
    }

    $self->textend();
    $self->restore();

    if ($wastext) {
        $self->textstart();
        $self->textstate(%text_state);
    }
    return $wht;
}

=head2 Complex Column Output with Markup

=head3 column

    ($rc, $next_y, $unused) = $text->column($page, $text, $grfx, $markup, $txt, %opts)

=over

This method fills out a column of text on a page, returning any unused portion
that could not be fit, and where it left off on the page.

Tag names, CSS entries, markup type, etc. are case-sensitive (usually 
lower-case letters only). For example, you cannot give a <P> paragraph in
HTML or a B<P> selector in CSS styling.

B<$page> is the page context. Currently, its only use is for page annotations
for links ('md1' []() and 'html' E<lt>aE<gt>), so if you're not using those, 
you may pass anything such as C<undef> for C<$page> if you wish.

B<$text> is the text context, so that various font and text-output operations
may be performed. It is often, but not necessarily always, the same as the
object containing the "column" method.

B<$grfx> is the graphics (gfx) context. It may be a dummy (e.g., undef) if
I<no> graphics are to be drawn, but graphical items such as the column outline 
('outline' option) and horizontal rule (<hr> in HTML markup) use it. 
Currently, I<text-decoration> underline (default for links, 'md1' C<[]()> and 
'html' C<E<lt>aE<gt>>) or line-through or overline use the text context, but
may in the future require a valid graphics context. Images (when implemented)
will require a graphics context.

B<$markup> is information on what sort of I<markup> is being used to format
and lay out the column's text:

=over

=item  'pre'

The input material has already been processed and is already in the desired
form. C<$txt> is an array reference to the list of hashes. This I<must> be used 
when you are calling C<column()> a second (or later)
time to output material left over from the first call. It may also be used when
the caller application has already processed the text into the appropriate
format, and other markup isn't being used.

=item  'none'

If I<none> is specified, there is no markup in use. At most, a blank line or
a new text array element specifies a new paragraph, and that's it. C<$txt> may
be a single string, or an array (list) of strings.

The input B<txt> is a list (anonymous array reference) of strings, each 
containing one or more paragraphs. A single string may also be given. An empty 
line between paragraphs may be used to separate the paragraphs. Paragraphs may 
not span array elements.  

=item  'md1'

This specifies a certain flavor of Markdown compatible with Text::Markdown: 

    * or _ italics, ** bold, *** bold+italic; 
    bulleted list *, numbered list 1. 2. etc.; 
    #, ## etc. headings and subheadings; 
    ---, ===, ___ horizontal rule;
    [label](URL) external links (to HTML page or within this document, see 'a')
    ` (backticks) enclose a "code" section

HTML (see below) may be mixed in as desired (although not within "code" blocks 
marked by backticks, where <, >, and & get turned into HTML entities, disabling 
the intended tags).
Markdown will be converted into HTML, which will then be interpreted into PDF.
I<Note that Text::Markdown may produce HTML for certain features, that is not 
yet supported by HTML processing (see 'html' section below). Let us know if 
you need such a feature!>

The input B<txt> is a list (anonymous array reference) of strings, each 
containing one or more paragraphs and other markup. A single string may also be 
given. Per Markdown formatting, an empty line between paragraphs may be used to 
separate the paragraphs. Separate array elements will first be glued together 
into a single string before processing, permitting paragraphs to span array 
elements if desired.  

There are other flavors of Markdown, so other mdI<n> flavors I<may> be defined 
in the future, such as POD from Perl code.

=item  'html'

This specifies that a subset of HTML markup is used, along with some attributes
and CSS. Currently, HTML tags 

    'i'/'em' (italic), 'b'/'strong' (bold), 
    'p' (paragraph),
    'font' (font face->font-family, color, size->font-size), 
    'span' (needs style= attribute with CSS to do anything useful), 
    'ul', 'ol', 'li' (bulleted, numbered lists), 
    'img' (TBD, image, empty. hspace->margin-left/right, 
           vspace->margin-top/bottom, width, height), 
    'a' (anchor/link, web page URL or this document target #p[-x-y[-z]]), 
    'pre', 'code' (TBD, preformatted and code blocks),
    'h1' through 'h6' (headings)
    'hr' (horizontal rule)
    'br' (TBD, line break, empty)
    'sup', 'sub' (TBD superscript and subscript)
    's', 'strike', 'del' (line-through)
    'u', 'ins' (underline)
    'ovl' (TBD -- non-HTML, overline)
    'k' (TBD -- non-HTML, kerning left/right shift)
    'blockquote' (block quote)

are supported (fully or in part I<unless> "TBD"), along with limited CSS for 
color, font-size, font-family, etc. 
E<lt>styleE<gt> tags may be placed in an optional E<lt>headE<gt> section, or
within the E<lt>bodyE<gt>. In the latter case, style tags will be pulled out
of the body and added (in order) on to the end of any style tag(s) defined in 
a head section. Multiple style tags will be condensed into a single collection 
(later definitions of equal precedence overriding earlier). These stylings will
have global effect, as though they were defined in the head. As with normal CSS,
the hierarchy of a given property (in decreasing precedence) is

    appearance in a style= tag attribute
    appearance in a tag attribute (possibly a different name than the property)
    appearance in a #IDname selector in a <style>
    appearance in a .classname selector in a <style>
    appearance in a tag name selector in a <style>

Selectors are quite simple: a single tag name (e.g., B<body>),
a single class (.cname), or a single ID (#iname). 
There are I<no> combinations (e.g., 
C<p.abstract> or C<ol, ul>), hierarchies (e.g., C<ol E<gt> li>), specified 
number of appearance, or other such complications as found in a browser's CSS. 
Sorry!

Supported CSS properties: 

    border-* TBD
    color (foreground color)
    display (inline/block)
    font-family (name as defined to FontManager, e.g. Times)
    font-size (pt, bare number = pt, % of current size)
    font-style (normal/italic) 
    font-weight (normal/bold)
    height (pt, bare number) thickness of horizontal rule
    list-style-position (outside) TBD inside
    list-style-type (marker description, see also _marker-before/after)
    margin-top/right/bottom/left (pt, bare number = pt, % of font-size)
      margin TBD update four margin-* properties
    text-decoration (none, underline, line-through, overline)
    text-height (leading, as ratio of baseline-spacing to font-size)
    text-indent (pt, bare number = pt, % of current font-size)
    text-align (left/right) TBD, future also center/justify?
    width (pt, bare number) width of horizontal rule

Non-standard CSS "properties". You may want to set these in CSS:

    _marker-before (text to insert before <ol> marker, default nothing)
    _marker-after (text to insert after <ol> marker, default period)

Non-standard CSS "properties". You normally would not set these in CSS:

    _fs (current running font size, in points, on the properties stack)
    _href (URL for <a>, normally provided by href= attribute)
    _left (running number of points to indent on the left, from margin-left and list nesting)
    _right (running number of points to indent on the right, from margin-right)

Sizes may be '%' (of font-size), or 'pt' (the default unit). 
More support may be added over time. B<CAUTION:> comments /* and */ are NOT
currently supported in CSS -- perhaps in the future.

Numeric entities (decimal &#nnn; and hexadecimal &#xnnn;) are supported, 
as well as named entities (&mdash; for example).

The input B<txt> is a list (anonymous array reference) of strings, each 
containing one or more paragraphs and other markup. A single string may also be 
given. Per normal HTML practice, paragraph tags should be used to mark
paragraphs. I<Note that HTML::TreeBuilder is configured to automatically
mark top body-level text with paragraph tags, in case you forget to do so,
although it is probably better to do it yourself, to maintain more control
over the processing.>
Separate array elements will first be glued together into a single string 
before processing, permitting paragraphs to span array elements if desired.  

=back

I<There are other markup languages out there, such as HTML-like Pango, and
man page (troff), that 
might be supported in the future. It is very unlikely that TeX or LaTeX will 
ever be supported, as they both already have excellent PDF output.>

B<$txt> is the input text: a string, an array reference to multiple strings,
or an array reference to hashes. See C<$markup> for details.

B<%opts> Options -- a number of these are of course, mandatory.

=over

=item 'rect' => [x, y, width, height]

This defines a column as a rectangular area of a given width and height (both
in points) on the current page. I<In the future, it is expected that more
elaborate non-rectangular areas will be definable, but for now, a simple
rectangle is all that is permitted.> The column's upper left coordinate is
C<x, y>.

The top text baseline is assumed to be relative to the UL corner (based on the
determined line height), and the column outline
clips that baseline, as it does additional baselines down the page (interline
spacing is C<leading> multiplied by the largest C<font_size> or image height
needed on that line).

I<Currently, 'rect' is required, as it is the only column shape supported.>

=item 'relative' => [ x, y, scale(s) ]

C<'relative'> defaults to C<[ 0, 0, 1, 1 ]>, and allows a column outline
(currently only 'rect') to be either absolute or relative. C<x> and C<y> are
added to each C<x,y> coordinate pair, I<after> scaling. Scaling values:

=over

=item (none)  The scaling defaults to 1 in both x and y dimensions (no change).

=item scale (one value)  The scaling in both the x (width) and y (height)
dimensions uses this value.

=item scale_x, scale_y (two values)  There are two separate scaling factors
for the x dimension (width) and y dimension (height).

=back

This permits a generically-shaped outline to be defined, scaled (perhaps
not preserving the aspect ratio) and placed anywhere on the page. This could
save you from having to define similarly-shaped columns from scratch multiple 
times.
If you want to define a relative outline, the lower left corner (whether or
not it contains a point, and whether or not it's the first one listed) would 
usually be C<0, 0>, to have scaling work as expected. In other works, your
outline template should be in the lower left corner of the page.

=item 'start_y' => $start_y

If omitted, it is assumed that you want to start at the top of the defined
column (the maximum C<y> value minus the maximum vertical extent of this line).
If used, the normal value is the C<next_y> returned from the previous 
C<column()> call. It is the deepest extent reached by the previous line (plus
leading), and is the top-most point of the new first line of this C<column()>
call.

Note that the C<x> position will be determined by the column shape and size
(the left-most point of the baseline), so there is no place to explicitly set 
an C<x> position to start at.

=item 'font_size' => $font_size

This is the starting font size (in points) to be used. Over the course of
the text, it may be modified by markup.

The starting font size may be set in a number of ways. It may be inherited from
a previous C<$text-E<gt>font(..., font-size)> statement; it may be set via the
C<font_size> option (overriding any font method inheritance); it may default to 
12pt (if neither explicit way is given). For HTML markup, it may of course be 
modified by the C<font> tag or by CSS styling C<font-size>. For Markdown, it
may be modified by CSS styling.

=item 'marker_width' => $marker_width

This is the width of the gutter to the left of a list item, where (for the
first line of the item) the marker lives. The marker contains the symbol (for
bulleted/unordered lists) or formatted number and "before" and "after" text
(for numbered/ordered lists). Both have a single space before the item text
starts. The number is a length, in points.

The default is 2 times the font_size passed to C<column()>, and is not adjusted
for any changes of font_size in the markup. An explicit value passed in is 
also not changed -- the gutter width for the marker will be the same in all 
lists (keeping them aligned). If you plan to have exceptionally long markers, 
such as an ordered list of years in Roman numerals, such as B<(MCMXCIX)>, you 
may want to make this gutter a bit wider.

=item 'leading' => $leading

This is the leading I<ratio> used throughout the column text.
The C<$x, $y> position through C<$x + width> is assumed to be the first
text baseline. The next line down will be C<$y - $leading*$font_size>. If the
font_size changes for any reason over the course of the column, the baseline
spacing (leading * font_size) will also change. The B<default> leading ratio
is 1.125 (12.5% added to font).

=item 'para' => [ $indent, $top-margin ]

When starting a new paragraph, these are the default indentation (in points),
and the extra vertical spacing for a top margin on a paragraph. The default is
C<[ 1*$font_size, 0 ]>. Either may be overridden by the appropriate CSS 
settings. An I<outdent> may be defined with a negative indentation value. 
These apply to all C<$markup> types.

=item 'outline' => "color string"

You may optionaly request that the column be outlined in a given color, to aid
in debugging fitting problems.

=item 'color' => "color string"

The color to draw the text (or rule or other graphic) in. The default is 
black (#000000).

=item 'style' => "CSS styling"

You may define CSS (selectors and properties lists) to override the built-in
CSS defaults. These will be applied for the entire C<column()> call. You can
use this, or C<style> tags in 'html', but for 'none' or 'md1', you will need to
use this method to set styling.

=item 'substitute' => [ [ 'char or string', 'before', 'replace', 'after'],... ]

When a certain Unicode code point (character) or string is found, insert 
I<before> text before the character, replace the character or string with
I<replace> text, and insert I<after> text after the character. This may make
it easier to insert HTML code (font, color, etc.) into Markdown text, if the
desired settings and character can not be produced by your Markdown editor.
This applies both to 'md1' and 'html' markup. Multiple substitutions may be 
defined via multiple array elements.
If you want to leave the original character or string I<itself> unchanged, you
should define the I<replace> text to be the same as C<'char or string'>. 
'before' and/or 'after' text may be empty strings if you don't want to insert
some sort of markup there.

Example: to insert a red cross (X-out) and green tick (check) mark

    'substitute' => [
      [ '%cross%', '<font face="ZapfDingbats" color="red">', '8', '</font>' ],
      [ '%tick%', '<font face="ZapfDingbats" color="green">', '4', '</font>' ],
    ]

should change C<%cross%> in Markdown text ('md1') or HTML text ('html')
to C<E<lt>font face="ZapfDingbats" color="green"E<gt>8E<lt>/fontE<gt>> 
and similarly for C<%tick%>. This is done I<after> the Markdown is converted 
to HTML (but before HTML is parsed), so make sure that your macro text (e.g., 
C<%tick%>) isn't something that Markdown will try to interpret by itself! Also, 
Perl's regular expression parser seems to get upset with some characters, such 
as C<|>, so don't use them as delimiters (e.g., C<|cross|>). You don't I<have> 
to wrap your macro name in delimiters, but it can make the text structure
clearer, and may be necessary in order not to do substitutions in the wrong 
place.

=item 'restore' => flag

This integer flag determines what sort of cleanup C<column()> will do upon
exit, to restore (or not) the font state (face, bold or normal weight, 
italic or normal style, size, and color).

=over

=item for rc = 0 (all input markup was used up, without running out of column)

=over

=item restore => 0

This is the B<default>. Upon exiting, C<column()> will attempt to restore the 
state to what one would see if there was yet more text to be output. Note that
this is I<not> necessarily what one would see if the entire state was restored
to entry conditions. The intent is that another C<column()> call can be 
immediately made, using whatever font state was left by the previous call, as
though the two calls' markup inputs were concatenated.

=item restore => 1

This value of C<restore> commands that I<no> change be made to the font state,
that is, C<column()> exits with the font state left in the last text output.
This may or may not be desirable, especially if the last text output left the
text in an unexpected state.

=item restore => 2

This value of C<restore> attempts to bring the font state all the way back to
what it was upon I<entry> to the routine, as if it had never been called. Note
that if C<column()> was called with no global font settings, that can not be
undone, although the color I<can> be changed back to its original state, 
usually black.

B<CAUTION:> The Font Manager is not synchronized with whatever state the font
is returned to. You should not request the 'current' font, but should instead
explicitly set it to a specific face, etc., which resets 'current'.

=back

=item for rc = 1 (ran out of column space before all the input markup was used up)

=over

=item restore => 0

This is the B<default>. Upon exiting, no changes will be made to the font
state. As the code will be in the middle of some output, the font state is
kept the same, so the next C<column()> call (for the overflow) can pick up 
where the previous call left off, with regards to the font state.

It is equivalent to C<restore = 1>.

=item restore => 1

This is the same as C<restore = 0>.

=item restore => 2

This value of C<restore> attempts to bring the font state all the way back to
what it was upon I<entry> to the routine, as if it had never been called. Note
that if C<column()> was called with no global font settings, that can not be
undone, although the color I<can> be changed back to its original state, 
usually black.

B<CAUTION:> The Font Manager is not synchronized with whatever state the font
is returned to. You should not request the 'current' font, but should instead
explicitly set it to a specific face, etc., which resets 'current'.

=back

=back

=back

The Font Manager system is used to supply the requested fonts, so it is up to
the application to pre-load the desired font information I<before> C<column()>
is called. Any request to change the encoding within C<column()> will be
ignored, as the fonts have already been specified for a specific encoding.
Needless to say, the encoding used in creating the input text needs to match
the specified font encoding.

Absent any markup changing the font face or styling, whatever is defined by
Font Manager as the I<current> font will be what is used. This way, you may
inherit the font from the previous C<column()>, or call 
C<$text->font($pdf-E<gt>get_font(), size)> to set both the font and size, or 
just call C<$pdf->get_font()> to set only the font, relying on the C<font_size> 
option or CSS markup to set the size.

Line fitting (paragraph shaping) is currently quite primitive. Words will
not be split (hyphenated).  I<It is planned to eventually add Knuth-Plass 
paragraph shaping, along with proper language-dependent hyphenation.>

Each change of font automatically supplies its maximum ascender and minimum
descender, the B<extents> above and below the text line's baseline. Each block
of text with a given face and variant, or change of font size, will be given
the same I<vertical> extents -- the extents are font-wide, and not determined 
on a per-glyph basis. So, unfortunately, a block of text "acemnorsuvwz" will 
have the same vertical extents as a block of text "bdfghijklpqty". For a given
line of text, the highest ascender and the lowest descender (plus leading) will
be used to position the line at the appropriate distance below the previous 
line (or the top of the column). No attempt is made to "fit" projections into
recesses (jigsaw-puzzle like). If there is an inset into the side of a column,
or it is otherwise not a straight vertical line,
so long as the baseline fits within the column outline, no check is made 
whether descenders or ascenders will fall outside the defined column (i.e., 
project into the inset). We suggest that you try to keep font sizes fairly
consistent, to keep reasonably consistent text vertical extents.

B<Data returned by this call>

If there is more text than can be accommodated by the column size, the unused
portion is returned, with a return code of 1. It is an empty list if all the 
text could be formatted, and the return code is 0.
C<next_y> is the y coordinate where any additional text (C<column()> call) 
could be added to a column (as C<start_y>) that wasn't completely filled.
This would be at the starting point of a new column (i.e., the
last paragraph is ended). Note that the application code should check if this
position is too far down the page (in the bottom margin) and not blindly use
it! Also, as 'md1' is first converted to HTML, any unused portion will be 
returned as 'pre' markup, rather than Markdown or HTML. Be sure to specify 
'pre' for any continuation of the column (with one or more additional 
C<column()> calls), rather than 'none', 'md1', or 'html'.

=over

=item $rc

The return code.

=over

=item '0'

A return code of 0 indicates that the call completed, while using up all the
input C<$txt>. It did I<not> run out of defined column space.

B<NOTE:> if C<restore> has a value of 1, the C<column()> call makes no effort 
to "restore" conditions to any
starting values. If your last bit of text left the "current" font with some
"odd" face/family, size, I<italicized>, B<bolded>, or colored; that will be
what is used by the next column call (or other PDF::Builder text calls). This
is done in order to allow you to easily chain from one column to the next,
without having to manually tell the system what font, color, etc. you want
to return to. On the other hand, in some cases you may want to start from the
same initial coditions as usual. You
may want to add C<get_font()>, C<font()>, C<fillcolor()>, and
C<strokecolor()> calls as necessary before the next text output, to get the
expected text characteristics. Or, you can simply let C<restore> default to
0 to get the same effect.

=item '1'

A return code of 1 indicates that the call completed by filling up the defined
column space. It did I<not> run out of input C<$txt>. You will need to make
one or more calls with empty column space (to fill), to use up the remaining
input text (with "pre" I<$markup>).

If C<restore> defaults to 0 (or is set to 1), the text settings in the 
"current" font are left as-is, so that whatever you
were doing when you ran out of defined column (as regards to font face/family,
size, italic and bold states, and color) should automatically be the same when 
you make the next C<column()> call to make more output.

=back

Additional return codes I<may> be added in the future, to indicate failures
of one sort or another.

=item $next_y

The next page "y" coordinate to start at, if using the same column definition
as the previous C<column()> definition did (i.e., you didn't completely fill
the column, and received a return code of 0). In that case, C<$next_y> would
give the page "y" coordinate to pass to C<column()> (as C<start_y>) to start a 
new paragraph at.

If the return code C<$rc> was 1 (column was used up), the C<$next_y> returned
will be -1, as it would be meaningless to use it.

=item $unused

This is the unused portion of the input text (return code C<$rc> is 1), in a 
format ("pre" C<$markup>) suitable for input as C<$txt>. It will be a
I<reference> to an array of hashes.

If C<$rc> is 0 (all input was used up), C<$unused> is an empty anonymous array.
It contains nothing to be used.

=back

=back

=cut

# TBD, future:
#  * = not official HTML5 or CSS (i.e., extension)
# perhaps 3.027?  
#   arbitrary paragraph shapes (path)
#   at a minimum, hyphenate-basic usage including &SHY;
#   <hr>, <img>, <sup>, <sub>, <pre>, <nobr>, <br>, <dl>/<dt>/<dd>, <center>*
#   <big>*, <bigger>*, <smaller>*, <small> 
#   <cite>, <q>, <code>, <kbd>, <samp>, <var>
#   CSS _expand* to call hscale() and/or condensed/expanded type in get_font()
#        (if not doing synfont() call)
#   CSS text transform, such as uppercase and lowercase flavors
#   CSS em and ex sizes relative to current font size (like %), 
#        other absolute sizes such as in, cm, mm, px (?)
#
#  possibly...
#   <abbr>, <base>, <wbr>
#   <article>, <aside>, <section>  as predefined page areas?
#
#  extensions to HTML and CSS...
#   <sl>* simple list (no markers)
#   <sc>* preprocess: around runs of lowercase put <span style="font-size: 80%;
#        expand: 110%"> and fold to UPPER CASE. this is post-mytext creation!
#   <pc>* (Petite case) like <sc> but 1ex font-size, expand 120%
#   <dc>* drop caps
#   <ovl>* overline (similar to underline) using CSS text-decoration: overline
#   <k>* kern text (shift left or right) with CSS _kern, or general positioning:
#     ability to form (La)TeX logo through character positioning
#        what to do at HTML level? x+/- %fs, y+/- %fs
#     also useful for <sup>4</sup><sub>2</sub>He notation
#   <vfrac>* vulgar fraction, using sup, sup, kern
#   HTML attributes to tune (force end) of something, such as early </sc> 
#        after X words and/or end of line. flag to ignore next </sc> coming up,
#        or just make self-closing with children?
#   <endc>* force end of column here (at this y, while still filling line)
#        e.g., to prevent an orphan. optional conditional (e.g., less than 1"
#        of vertical space left in column)
#   <keep>* material to keep together, such as headings and paragraph text
#   leading (line-height) as a dimension instead of a ratio, convert to ratio
#
# 3.028 or later?
#  left/right auto margins? <center> may need this
#  Text::KnuthLiang hyphenation
#  <hyp>*, <nohyp>* control hypenation in a word (and remember
#        rules when see this word again)
#  <lang>* define language of a span of text, for hyphenation/audio purposes
#  Knuth-Plass paragraph shaping (with proper hyphenation) 
#  HarfBuzz::Shaper for ligatures, callout of specific glyphs (not entities), 
#        RTL and non-Western language support. <bdi>, <bdo>
#  <nolig></nolig>* forbid ligatures in this range
#  <lig gid='nnn'> </lig>* replace character(s) by a ligature
#  <alt gid='nnn'> </alt>* replace character(s) by alternate glyph
#        such as a swash. font-dependent
#  <eqn>* (needs image support, SVG processing)

sub column {
    my ($self, $page, $text, $grfx, $markup, $txt, %opts) = @_;
    my $pdf = $self->{' api'}->{' FM'}->{' pdf'};

    my $rc = 0; # so far, a normal call with input completely consumed
    my $unused = undef;
    # array[1] will be consolidated CSS from any <style> tags
    my ($x, $y);

    my $font_size = 12; # basic default, override with font-size
    if ($text->{' fontsize'} > 0) { $font_size = $text->{' fontsize'}; }
    if (defined $opts{'font_size'}) { $font_size = $opts{'font_size'}; }
    
    my $leading = 1.125; # basic default, override with text-height
    if (defined $opts{'leading'}) { $leading=$opts{'leading'}; }
    my $marker_width = 2*$font_size;
    if (defined $opts{'marker_width'}) { $marker_width=$opts{'marker_width'}; }

    my $restore = 0; # restore text state and color at end
    if (defined $opts{'restore'}) { $restore = $opts{'restore'}; }
    my @entry_state = (); # font state, color and graphics color
    push @entry_state, $text->{' font'};  # initially may be undef, then hashref
    push @entry_state, $text->{' fontsize'};  # initially 0
    push @entry_state, $text->{' fillcolor'};  # an arrayref, often single number or string
    push @entry_state, $text->{' strokecolor'};  # an arrayref, often single number or string
    if (defined $grfx && ref($grfx) =~ m/^PDF::Builder::Content=HASH/){
	# we have a valid grfx, so can use its values
        push @entry_state, $grfx->{' fillcolor'};  # an array, often single number or string
        push @entry_state, $grfx->{' strokecolor'};  # an array, often single number or string
    } else {
        # no grfx, so use undef for values
	push @entry_state, undef;
	push @entry_state, undef;
    }

    # fallback CSS properties, inserted at array[0]
    my $default_css = _default_css($pdf, $text, $font_size, $leading, %opts); # per-tag properties
    # dump @mytext list within designated column @outline
    # for now, the outline is a simple rectangle
    my $outline_color = 'none';  # optional outline of the column
    $outline_color = $opts{'outline'} if defined $opts{'outline'};

    # define coordinates of column, currently just 'rect' rectangle, but
    # in future could be very elaborate
    my @outline = _get_column_outline($grfx, $outline_color, %opts);
    my ($col_min_x, $col_min_y, $col_max_x, $col_max_y) = 
        _get_col_extents(@outline);
    my $start_y = $col_max_y; # default is a top of column
    my $para = 1; # paragraph is at top of column, don't use margin-top
    $start_y = $opts{'start_y'} if defined $opts{'start_y'};
    if ($start_y != $col_max_y) { 
	# para reset to 0 b/c not at top of column
	$para = 0; # go ahead with any extra top margin
    }

    # what is the content of $text: string, array, or array of hashes?
    # (or already set up, per 'pre' markup)
    # break up text into array of hashes so we have one common input
    my @mytext = _break_text($txt, $markup, %opts);
    unshift @mytext, $default_css;

    # each element of mytext is an anonymous hash, with members text=>text
    # content, font_size, color, font, variants, etc.
    #
    # if markup=pre, it's already in final form (array of hashes)
    # if none, separate out paragraphs into array of hashes
    # if md1, convert to HTML (error if no converter)
    # if html, need to interpret (error if no converter)
    # finally, resulting array of hashes is interpreted and fit in column
    # process style attributes, tag attributes, style tags, column() options,
    # and fixed default attributes in that order to fill in each tag's
    # attribute list. on exit from tag, set attributes to restore settings
    _tag_attributes(@mytext);

    ($rc, $start_y, $unused) = _output_text($start_y, $col_min_y, \@outline, $pdf, $page, $text, $grfx, $restore, $para, $font_size, $marker_width, $leading, @mytext);

    if ($rc > 1) {
	# restore = 2 request restore to @entry_state for rc=0, 3 for 1
        $text->{' font'} = $entry_state[0]; 
        $text->{' fontsize'} = $entry_state[1]; 
        $text->{' fillcolor'} = $entry_state[2];
        $text->{' strokecolor'} = $entry_state[3];
        if (defined $grfx && ref($grfx) =~ m/^PDF::Builder::Content=HASH/){
	    # we have a valid grfx, so can use its values
            $grfx->{' fillcolor'} = $entry_state[4];
            $grfx->{' strokecolor'} = $entry_state[5];
        } else {
            # no grfx, so do nothing
        }
	$rc -= 2;
    }

    return ($rc, $start_y, $unused);
} # end of column()

# set up an element containing all the default settings, as well as those
# passed in by column() parameters and options. this is generated once for
# each call to column, in case any parameters or options change.
sub _default_css {
    my ($pdf, $text, $font_size, $leading, %opts) = @_;

    my @cur_font = $pdf->get_font();
    my @cur_color = $text->fillcolor();
    my $current_color;
   #my $cur_color = 'black';
    if (@cur_color == 1) { 
	# 'name', '#rrggbb' etc. suitable for CSS usage
	# TBD: single gray scale value s/b changed to '#rrggbb'
	#       (might be 0..1, 0..100, 0..ff)?
	$current_color = $cur_color[0];
    } else {
	# returned an array of values, unsuitable for CSS
	# TBD: 3 values 0..1 turn into #rrggbb
	# TBD: 3 values 0..100 turn into #rrggbb
	# TBD: 3 values 0..ff turn into #rrggbb
	# TBD: 4 values like 3, but CMYK
	# for now, default to 'black'
	$current_color = 'black';
    }

    my %style;
    $style{'tag'} = 'defaults';
    $style{'text'} = '';

    $style{'body'} = {};
    $style{'p'} = {};
    $style{'ol'} = {};
    $style{'ul'} = {};
    $style{'h1'} = {};
    $style{'h2'} = {};
    $style{'h3'} = {};
    $style{'h4'} = {};
    $style{'h5'} = {};
    $style{'h6'} = {};
    $style{'a'} = {};
    $style{'i'} = {};
    $style{'em'} = {};
    $style{'b'} = {};
    $style{'strong'} = {};
    $style{'hr'} = {};

    $style{'body'}->{'font-size'} = $font_size;
    $style{'body'}->{'_fs'} = $font_size; # carry current value
    $style{'body'}->{'text-height'} = $leading;

    my $para = [ 1, 1*$font_size, 0 ]; 
    # if font_size changes, change indentation
    if (defined $opts{'para'}) {
       #$para->[0]  # flag: 0 = <p> is normal top of paragraph (with indent
       #    and margin), 1 = at top of column, so suppress extra top margin
       #    (and reset once past this first line)
        $para->[1] = $opts{'para'}->[0]; # indentation
        $para->[2] = $opts{'para'}->[1]; # extra top margin
    }
    # $para flag determines whether these settings are used or ignored (=1, 
    # we are at the top of a column, ignore text-indent and margin-top)
    $style{'p'}->{'text-indent'} = $para->[1];
    $style{'p'}->{'margin-top'} = $para->[2];

    my $color = $current_color;  # text default color
    $color = $opts{'color'} if defined $opts{'color'};
    $style{'body'}->{'color'} = $color;

    # now for fixed settings
    $style{'body'}->{'font-family'} = $cur_font[0]; # face
   #$style{'body'}->{'font-style'} = $cur_font[1]? 'italic': 'normal';
   #$style{'body'}->{'font-weight'} = $cur_font[2]? 'bold': 'normal';
    $style{'body'}->{'font-style'} = 'normal';
    $style{'body'}->{'font-weight'} = 'normal';
   #$style{'body'}->{'font-variant'} = 'normal'; # small-caps
    $style{'body'}->{'margin-top'} = '0'; 
    $style{'body'}->{'margin-right'} = '0'; 
    $style{'body'}->{'margin-bottom'} = '0'; 
    $style{'body'}->{'margin-left'} = '0'; 
    $style{'body'}->{'_left'} = '0'; 
    $style{'body'}->{'_right'} = '0'; 
    $style{'body'}->{'text-indent'} = '0'; 
   #$style{'body'}->{'text-align'} = 'left'; # TBD center, right
   #$style{'body'}->{'text-transform'} = 'none'; # capitalize, uppercase, lowercase
   #$style{'body'}->{'border-style'} = 'none'; # solid, dotted, dashed... TBD
   #$style{'body'}->{'border-width'} = '1pt'; 
   #$style{'body'}->{'border-color'} = 'inherit'; 
   #   TBD border-* individually specify for top/right/bottom/left
    $style{'body'}->{'text-decoration'} = 'none';
    $style{'body'}->{'display'} = 'block'; 
    $style{'body'}->{'width'} = '-1';  # TBD currently unused
    $style{'body'}->{'height'} = '-1';  # TBD currently unused ex. hr size
    $style{'body'}->{'_href'} = ''; 

    $style{'p'}->{'display'} = 'block';
    $style{'font'}->{'display'} = 'inline';
    $style{'span'}->{'display'} = 'inline';

    $style{'a'}->{'text-decoration'} = 'underline'; 
          # none, underline, overline, line-through or a combination
	  # separated by spaces
    $style{'a'}->{'color'} = 'blue'; 
    $style{'a'}->{'display'} = 'inline'; 
    $style{'a'}->{'_href'} = ''; 

    $style{'ul'}->{'list-style-type'} = '.u'; # disc, circle, square, box, none
    $style{'ul'}->{'list-style-position'} = 'outside'; # inside
    $style{'ul'}->{'display'} = 'block'; 
    $style{'ul'}->{'margin-bottom'} = '50%'; 
    $style{'ol'}->{'list-style-type'} = '.o'; # decimal, lower-roman, upper-roman, lower-alpha, upper-alpha, none
    $style{'ol'}->{'list-style-position'} = 'outside'; # inside TBD
    $style{'ol'}->{'display'} = 'block'; 
    $style{'ol'}->{'margin-bottom'} = '50%'; 
    $style{'ol'}->{'_marker-before'} = ''; # content to add before marker
    $style{'ol'}->{'_marker-after'} = '.'; # content to add after marker
   #$style{'sl'}->{'list-style-type'} = 'none'; TBD
    $style{'li'}->{'display'} = 'block';  # should inherit from ul or ol
    $style{'li'}->{'margin-top'} = '50%';  # relative to text's font-size

   #$style{'h6'}->{'text-transform'} = 'uppercase'; # heading this level CAPS
    $style{'h6'}->{'font-weight'} = 'bold'; # all headings bold
    $style{'h6'}->{'font-size'} = '75%'; # % of original font-size
    $style{'h6'}->{'margin-top'} = '200%'; # relative to the font-size
    $style{'h6'}->{'margin-bottom'} = '200%'; # relative to the font-size
    $style{'h6'}->{'display'} = 'block'; # block (start on new line)

    $style{'h5'}->{'font-weight'} = 'bold';
    $style{'h5'}->{'font-size'} = '85%';
    $style{'h5'}->{'margin-top'} = '175%';
    $style{'h5'}->{'margin-bottom'} = '175%';
    $style{'h5'}->{'display'} = 'block';

    $style{'h4'}->{'font-weight'} = 'bold';
    $style{'h4'}->{'font-size'} = '100%';
    $style{'h4'}->{'margin-top'} = '150%';
    $style{'h4'}->{'margin-bottom'} = '150%';
    $style{'h4'}->{'display'} = 'block';

    $style{'h3'}->{'font-weight'} = 'bold';
    $style{'h3'}->{'font-size'} = '115%';
    $style{'h3'}->{'margin-top'} = '130%';
    $style{'h3'}->{'margin-bottom'} = '130%';
    $style{'h3'}->{'display'} = 'block';

    $style{'h2'}->{'font-weight'} = 'bold';
    $style{'h2'}->{'font-size'} = '150%';
    $style{'h2'}->{'margin-top'} = '100%';
    $style{'h2'}->{'margin-bottom'} = '100%';
    $style{'h2'}->{'display'} = 'block';

    $style{'h1'}->{'font-weight'} = 'bold';
    $style{'h1'}->{'font-size'} = '200%';
    $style{'h1'}->{'margin-top'} = '75%';
    $style{'h1'}->{'margin-bottom'} = '75%';
    $style{'h1'}->{'display'} = 'block';

    $style{'i'}->{'font-style'} = 'italic';
    $style{'i'}->{'display'} = 'inline';
    $style{'b'}->{'font-weight'} = 'bold';
    $style{'b'}->{'display'} = 'inline';
    $style{'em'}->{'font-style'} = 'italic';
    $style{'em'}->{'display'} = 'inline';
    $style{'strong'}->{'font-weight'} = 'bold';
    $style{'strong'}->{'display'} = 'inline';

    $style{'u'}->{'display'} = 'inline';
    $style{'u'}->{'text-decoration'} = 'underline';
    $style{'ins'}->{'display'} = 'inline';
    $style{'ins'}->{'text-decoration'} = 'underline';

    $style{'s'}->{'display'} = 'inline';
    $style{'s'}->{'text-decoration'} = 'line-through';
    $style{'strike'}->{'display'} = 'inline';
    $style{'strike'}->{'text-decoration'} = 'line-through';
    $style{'del'}->{'display'} = 'inline';
    $style{'del'}->{'text-decoration'} = 'line-through';

    # non-standard tag for overline TBD
   #$style{'ovl'}->{'display'} = 'inline';
   #$style{'ovl'}->{'text-decoration'} = 'overline';
    
    # non-standard tag for kerning (+ font-size fraction to move left, - right)
    # e.g., for vulgar fraction adjust / and denominator <sub> TBD
   #$style{'k'}->{'display'} = 'inline';
   #$style{'k'}->{'_kern'} = '0.2';

    $style{'hr'}->{'display'} = 'block';
    $style{'hr'}->{'height'} = '0.5'; # 1/2 pt default thickness
    $style{'hr'}->{'width'} = '-1'; # default width is full column
    $style{'hr'}->{'margin-top'} = '100%'; 
    $style{'hr'}->{'margin-bottom'} = '100%'; 

    $style{'blockquote'}->{'display'} = 'block';
    $style{'blockquote'}->{'margin-top'} = '56%';
    $style{'blockquote'}->{'margin-bottom'} = '56%';
    $style{'blockquote'}->{'margin-left'} = '300%';  # want 3em TBD
    $style{'blockquote'}->{'margin-right'} = '300%';
    $style{'blockquote'}->{'text-height'} = '1.00'; # close spacing
    $style{'blockquote'}->{'font-size'} = '80%'; # smaller type

   #$style{'sc'}->{'font-size'} = '80%'; # smaller type TBD
   #$style{'sc'}->{'_expand'} = '110%'; # wider type   TBD _expand
   #likewise for pc (petite caps) TBD

    return \%style;
} # end of _default_css()

# make sure each tag's attributes are proper property names 
# consolidate attributes and style attribute (if any)
# mark empty tags (no explicit end tag will be found)
sub _tag_attributes {
    my (@mytext) = @_;
    
    # start at [2], so defaults and styles skipped
    for (my $el=2; $el < @mytext; $el++) {
	if (ref($mytext[$el]) ne 'HASH') { next; }
	if ($mytext[$el]->{'tag'} eq '') { next; }

        my $tag = $mytext[$el]->{'tag'};
	if (!defined $tag) { next; }
	if ($tag =~ m#^/#) { next; }

	# we have a tag that might have one or more attributes that may
	# need to be renamed as a CSS property
	if ($tag eq 'font') {
	    if (defined $mytext[$el]->{'face'}) {
		$mytext[$el]->{'font-family'} = delete($mytext[$el]->{'face'});
	    }
	    if (defined $mytext[$el]->{'size'}) {
		$mytext[$el]->{'font-size'} = delete($mytext[$el]->{'size'});
		# TBD some sizes may need to be converted to points. for now,
		#   assume is a bare number (pt), pt, or % like font-size CSS
	    }
	}
	if ($tag eq 'ol') {
	    if (defined $mytext[$el]->{'type'}) {
	        $mytext[$el]->{'list-style-type'} = delete($mytext[$el]->{'type'});
	    }
	}
	if ($tag eq 'ul') {
	    if (defined $mytext[$el]->{'type'}) {
	        $mytext[$el]->{'list-style-type'} = delete($mytext[$el]->{'type'});
	    }
	}
	if ($tag eq 'li') {
	    if (defined $mytext[$el]->{'type'}) {
	        $mytext[$el]->{'list-style-type'} = delete($mytext[$el]->{'type'});
	    }
	}
	if ($tag eq 'a') {
	    if (defined $mytext[$el]->{'href'}) {
	        $mytext[$el]->{'_href'} = delete($mytext[$el]->{'href'});
	    }
	}
	if ($tag eq 'hr') {
	    if (defined $mytext[$el]->{'size'}) {
	        $mytext[$el]->{'height'} = delete($mytext[$el]->{'size'});
	    }
	}
	 
	# process any style attribute and override attribute values
	if (defined $mytext[$el]->{'style'}) {
	    my $style_attr = _process_style_string({}, $mytext[$el]->{'style'});
	    # hash of property_name => value pairs
	    foreach (keys %$style_attr) {
		# create or override any existing property by this name
		$mytext[$el]->{$_} = $style_attr->{$_};
	    }
	}

	# VOID elements (br, hr, img, area, base, col, embed, input,
	# link, meta, source, track, wbr) do not have a separate end
	# tag. also incude style and defaults in this list in case a stray 
	# one shows up (does not have an end tag)
	if ($tag eq 'br' || $tag eq 'hr' || $tag eq 'img' || $tag eq 'area' ||
	    $tag eq 'base' || $tag eq 'col' || $tag eq 'embed' || 
	    $tag eq 'input' || $tag eq 'link' || $tag eq 'meta' ||
	    $tag eq 'source' || $tag eq 'track' || $tag eq 'wbr' ||
            $tag eq 'defaults' || $tag eq 'style') {
	    $mytext[$el]->{'empty_element'} = 1;
        }
    }
    return;
} # end of _tag_attributes()

# the workhorse of the library: output text (modified by tags) in @mytext
sub _output_text {
    my ($start_y, $min_y, $outl, $pdf, $page, $text, $grfx, $restore, $para, 
	$font_size, $marker_width, $leading, @mytext) = @_;
    my @outline = @$outl;

    # start_y is the lowest extent of the previous line, or the highest point
    # of the column outline, and is where we start the next one. 
    # min_y is the lowest y available within the column outline, outl.
    # pdf is the pdf top-level object. 
    # text is the text context. 
    # para is a flag that we are at the top of a column (no margin-top added).
    # font_size is the default font size to use.
    # leading is the default leading ratio to use.
    # mytext is the array of hashes containing tags, attributes, and text.
      
    my ($start_x, $x,$y, $width, $endx); # current position of text
    my ($asc, $desc, $desc_leading); 
    my $next_y = $start_y;
    # we loop to fill next line, starting with a y position baseline set when
    #   encounter the next text, and know the font, font_size, and thus the
    #   ascender/descender extents (which may grow). from that we can find
    #   the next baseline (which could be moved downwards).
    # we loop until we either run out of input text, or run out of column
    my $need_line = 1; # need to start a new line? always 'yes' (1) on
                       # call to column(). set to 'yes' if tag is for a block
		       # level display (treat like a paragraph)
    my $add_x = 0; # amount to add for indent
    my $add_y = 0; # amount to drop for first line's top margin
    my @line_extents = (); # for dealing with changes to vertical extents
                           # changes mid-line

    my $start = 1; # counter for ordered lists
    my $list_depth = 0; # nesting level of ol and ul
    my $list_marker = ''; # li marker text
    my $reversed_ol = 0; # count down from start

    my $phrase='';
    my $remainder='';
    my $topm = 0; # adjoining top margin
    my $botm = 0; # adjoining bottom margin
    my $current_prop = _init_current_prop(); # determine if a property has 
    #           changed and PDF::Builder routines need calling
    my @properties = ({}); # stack of properties from tags
    _update_properties($properties[0], $mytext[0], 'body');
    my $call_get_font = 0;

    # mytext[0] should be default css values
    # mytext[1] should be any <style> tags (consolidated)
    # user input tags/text start at mytext[2]
    for (my $el = 2; $el < scalar @mytext; $el++) {
	# discard any empty elements
	if (ref($mytext[$el]) ne 'HASH') { next; }
	if (!keys %{$mytext[$el]}) { next; }
	
	if ($mytext[$el]->{'text'} eq '') {
            # ===================================== tags/end-tags
	    # should be a tag or end-tag element defined
	    # for the most part, just set properties at stack top. sometimes
	    # special actions need to be taken, with actual output (e.g.,
	    # <hr> or <img>). remember that the properties stack includes
	    # any units (%, pt, etc.), while current_prop has been converted
	    # to points.
	    my $tag = $mytext[$el]->{'tag'};

	    if (substr($tag, 0, 1) ne '/') {
	        # take care of 'beginning' tags. dup the top of the properties
		# stack, update properties in the stack top element. note that
		# current_prop usually isn't updated until the text is being
		# processed. some tags need some special processing if they 
		# do something that isn't just a property change

                # special directives such as TBD
		# <endc> force end of column here (while still filling line)
		#   e.g., to prevent an orphan
		# <nolig></nolig> forbid ligatures in this range
		# <lig gid='nnn'> </lig> replace character(s) by a ligature
		# <alt gid='nnn'> </alt> replace character(s) by alternate glyph
		#   such as a swash. font-dependent
		# <hyp>, <nohyp> control hypenation in a word (and remember
		#   rules when see this word again)

	        # 1. dup the top of the properties stack for a new set of
	        #   properties to be modified by attributes and CSS
                push @properties, {};
	        foreach (keys %{$properties[-2]}) {
	            $properties[-1]->{$_} = $properties[-2]->{$_};
	        }
	        # current_prop is still previous text's properties

	        # 2. update properties top with element [0] (default CSS) 
		#   per $tag
	        _update_properties($properties[-1], $mytext[0], $tag);

	        # 3. update properties top with element [1] (styles CSS)
		#   per $tag
	        _update_properties($properties[-1], $mytext[1], $tag);

	        # 4. update properties top with element [1] per any .class
		#   (styles CSS, which is only one with .class selectors)
	        if (defined $mytext[$el]->{'class'}) {
	            _update_properties($properties[-1], $mytext[1], 
		                       '.'.$mytext[$el]->{'class'});
	        }
	    
	        # 5. update properties top with element [1] per any #id
		#   (styles CSS, which is only one with #id selectors)
	        if (defined $mytext[$el]->{'id'}) {
	            _update_properties($properties[-1], $mytext[1], 
		                       '#'.$mytext[$el]->{'id'});
	        }
	    
	        # 6. update properties top with any tag/style attributes.
		#   these come from the tag itself: its attributes, 
		#   overridden by any style attribute. these are the
		#   highest priority properties. everything copied over to
		#   the stack top, but anything not a real property will end
		#   up not being used.
	        _update_properties($properties[-1], $mytext[$el]);
	        
	        if ($properties[-1]->{'display'} eq 'block') {
		    $need_line = 1; 
		    $start_y = $next_y;
		    $add_x = $add_y = 0;
	            # block display with a non-zero top margin and/or bottom
		    # margin... set skip to larger of the two.
		    # when text is ready to be output, figure both any new
		    # top margin (for that text) and compare to the existing
		    # bottom margin (in points) saved at the end of the previous
		    # text.
		    $topm = $properties[-1]->{'margin-top'};
		    # now that need_line etc. has been set due to block display,
		    # change stack top into 'inline'
		    $properties[-1]->{'display'} = 'inline';
	        }
		# handle specific kinds of tags' special processing
	        if ($tag eq 'p') {
                    # para=1 we're at top of column (no extra margin)
		    # per $para (or default), drop down a line?, indent?
		    # if CSS changed to display=inline for some reason, what to do?
		    # no y change if at top of column, but still indent
		    $add_x = $properties[-1]->{'text-indent'}; # indent by para indent amount
		    if ($para) {
		        # at top of column, so suppress extra space
		        $add_y = 0; # no extra top margin if at column top
		        $para = 0; # for rest of column, extra top margin
		    } else {
		        $add_y = $properties[-1]->{'margin-top'}; # extra top margin
		    }
	            # p with cont=>1 is continuation of paragraph in new column 
	            # no indent and no top margin... just start a new line
	            if (defined $mytext[$el]->{'cont'} && $mytext[$el]->{'cont'}) {
                        $add_x = $add_y = 0;
                    }
	        }
	       #if ($tag eq 'i') { } 
	       #if ($tag eq 'em') { }
	       #if ($tag eq 'b') { }
	       #if ($tag eq 'strong') { }
	       #if ($tag eq 'font') { } face already renamed to font-family,
	       #                        size already renamed to font-size, color
	       #if ($tag eq 'span') { } needs style= or <style> to be useful
	        if ($tag eq 'ul') { 
		    $list_depth++;
		}
	        if ($tag eq 'ol') { 
		    # save any existing start and reversed_ol values
		    $properties[-2]->{'_start'} = $start; # current start
		    $properties[-2]->{'_reversed_ol'} = $reversed_ol; # cur flag

	            $start = 1;
	            if (defined $mytext[$el]->{'start'}) {
	                $start = $mytext[$el]->{'start'};
		    }
		    if (defined $mytext[$el]->{'reversed'}) {
			$reversed_ol = 1;
		    } else {
			$reversed_ol = 0;
		    }
                    $list_depth++;
	        }
	        if ($tag eq 'li') {
		    # paragraph, but label depends on parent (list-style-type)
		    # type and value attributes can override parent 
		    # list-style-type and start
		    if (defined $mytext[$el]->{'value'}) {
		        $start =  $mytext[$el]->{'value'}; # used only for ol
		    }
		    # for time-being, treat position of marker as 'outside' TBD
		    $list_marker = _marker($properties[-1]->{'list-style-type'},
			$list_depth, $start, 
			$properties[-1]->{'_marker-before'}, 
			$properties[-1]->{'_marker-after'});
		    if (substr($list_marker, 0, 1) eq '.') {
			# it's a bullet character
		    } else {
			# fully formatted ordered list item
			if ($reversed_ol) {
		            $start--;
			} else {
		            $start++;
			}
		    }
		    # sl: use normal marker width, marker is blank. position
		    #     is always outside (ignore inside if given)
		    # dl: variable length marker width, minimum size given,
		    #     which is where dd left margin is
	        }
	       #if ($tag eq 'img') { } TBD, hspace and vspace already margins,
	       #                            width, height
	       #if ($tag eq 'a') { } 
	       #if ($tag eq 'pre') { } TBD
	       #if ($tag eq 'code') { } TBD font-family sans-serif + 
	       #                        constant width 75% font-size
	       #if ($tag eq 'blockquote') { } 
                if ($tag eq 'li') {
		    # indent each list level by same amount
	            $properties[-1]->{'_left'} += $marker_width;
                }
               # treat headings as paragraphs
	       #if ($tag eq 'h1') { }  align
	       #if ($tag eq 'h2') { }
	       #if ($tag eq 'h3') { }
	       #if ($tag eq 'h4') { }
	       #if ($tag eq 'h5') { }
	       #if ($tag eq 'h6') { }
	        if ($tag eq 'hr') { 
		    my $fs = $current_prop->{'font-size'};
		    # actually draw a horizontal line
		    $start_y = $next_y;
		    my $oldcolor = $grfx->strokecolor();
		    $grfx->strokecolor($properties[-1]->{'color'});
		    my $oldlinewidth = $grfx->linewidth();
		    my $thickness = $properties[-1]->{'height'} || 1;
		    $grfx->linewidth($thickness);
		    my $y = $start_y - 
		        _size2pt($properties[-1]->{'margin-top'}, $fs) -
		       $thickness/2;
                    ($start_x,$y, $width) = _get_baseline($y, @outline);
                    # need to increase start_x by any left margin
		    $start_x += $properties[-1]->{'_left'};
		    $width -= $properties[-1]->{'_left'} + $properties[-1]->{'_right'};
		    # if there is a requested width, use the smaller of the two
		    # TBD future, width as % of possible baseline, 
		    #     center or right aligned, explicit units (pt default)
		    if ($properties[-1]->{'width'} > 0 &&
			$properties[-1]->{'width'} < $width) {
			$width = $properties[-1]->{'width'};
		    }
                    $endx = $start_x + $width;

		    $grfx->move($start_x, $y);
		    $grfx->hline($endx);
		    $grfx->stroke();
		    $y -= $thickness/2 + 
		        _size2pt($properties[-1]->{'margin-bottom'}, $fs);
		    $next_y = $y;

		    # restore changed values
		    $grfx->linewidth($oldlinewidth);
		    $grfx->strokecolor($oldcolor);
		} 
	       #if ($tag eq 'br') { } TBD force new line
	       #if ($tag eq 'sup') { } TBD
	       #if ($tag eq 'sub') { } TBD
	       #if ($tag eq 'del') { } 
	       #if ($tag eq 'ins') { }
	       #if ($tag eq 's') { } 
	       #if ($tag eq 'strike') { } 
	       #if ($tag eq 'u') { } 
	        
	       #if ($tag eq 'blockquote') { } 
    
	       # tags maybe some time in the future TBD
	       #if ($tag eq 'address') { } inline formatting
	       #if ($tag eq 'article') { } discrete section
	       #if ($tag eq 'aside') { } discrete section 
	       #if ($tag eq 'base') { } 
	       #if ($tag eq 'basefont') { } 
	       #if ($tag eq 'big') { }  font-size 125%
	       # already taken care of head, body
	       #if ($tag eq 'canvas') { } 
	       #if ($tag eq 'caption') { } 
	       #if ($tag eq 'center') { }  margin-left/right auto
	       #if ($tag eq 'cite') { } quotes, face?
	       #if ($tag eq 'dl') { }  similar to ul/li
	       #if ($tag eq 'dt') { } 
	       #if ($tag eq 'dd') { } 
	       #if ($tag eq 'div') { }  # requires width, height, left, etc.
	       #if ($tag eq 'figure') { }
	       #if ($tag eq 'figcap') { }
	       #if ($tag eq 'footer') { } discrete section
	       #if ($tag eq 'header') { } discrete section
	       #if ($tag eq 'kbd') { }  font-family sans-serif + constant width
	       #                        75% font-size
	       #if ($tag eq 'mark') { }
	       #if ($tag eq 'nav') { } discrete section
	       #if ($tag eq 'nobr') { } treat all spaces within as NBSPs?
	       #if ($tag eq 'q') { }  ldquo/rdquo quotes around
	       #if ($tag eq 'samp') { } font-family sans-serif + constant width
	       #                        75% font-size
	       #if ($tag eq 'section') { } discrete section
	       #if ($tag eq 'small') { } font-size 75%
	       #if ($tag eq 'summary') { } discrete section
	        if ($tag eq 'style') {
		    # sometimes some stray empty style tags seem to come 
		    # through...  can be ignored
	        }

	        if (defined $mytext[$el]->{'empty_element'}) {
	            # empty/void tag, no end tag, pop property stack
		    # as this tag's actions have already been taken
		    pop @properties;
		    splice(@mytext, $el, 1);
		    $el--; # end of loop will advance $el
		    # no text as child of this tag, whatever it does, it has
		    # to be completely handled in this section
	        }

		# end of handling starting tags <tag>

	    } else {
		# take care of 'end' tags. some end tags need some special 
		# processing if they do something that isn't just a 
		# property change. current_prop should be up to date.
		$tag = substr($tag, 1); # discard /

		if ($tag eq 'ol' || $tag eq 'ul') { $list_depth--; }
		# note that current_prop should be all up to date by the
		# time you hit the end tag
		if ($tag eq 'ol') {
		    # restore any saved start and reversed_ol values
		    $start = $properties[-2]->{'_start'}; # current start
		    $reversed_ol = $properties[-2]->{'_reversed_ol'}; # cur flag
                }

		# ready to pick larger of top and bottom margins (block display)
		$botm = $current_prop->{'margin-bottom'};
		# block display element end (including paragraphs)
	        # start next material on new line
	        if ($current_prop->{'display'} eq 'block') {
		    $need_line = 1; 
		    $start_y = $next_y;
		    $add_x = $add_y = 0;
		    # now that need_line, etc. are set, make inline
		    $current_prop->{'display'} = 'inline';
	        }

		# last step is to pop the properties stack and remove this
		# element, its start tag, and everything in-between. adjust 
		# $el and loop again.
		for (my $first = $el-1; $first>1; $first--) {
		    # looking for a tag matching $tag
		    if ($mytext[$first]->{'text'} eq '' &&
			$mytext[$first]->{'tag'} eq $tag) {
			# found it at $first
			my $len = $el - $first + 1;
			splice(@mytext, $first, $len);
			$el -= $len; # end of loop will advance $el
			pop @properties;
			last;
		    }
                }
		if (@mytext == 2) { last; } # have used up all input text!
		# only default values and style element are left
		next; # next mytext element s/b one after batch just removed
               
		# end of handling end tags </tag>
	    }

	    # end of tag processing

	} else {
            # ===================================== text to output
	    # we should be at a new text entry ("phrase")
	    # we have text to output on the page, using properties at the
	    # properties stack top. compare against current properties to
	    # see if need to make any calls (font, color, etc.) to make.

	    # after tags processed, and property list (properties[-1]) updated,
	    # typically at start of a text string (phrase) we will call PDF
	    # updates such as fillcolor, get_font, etc. and at the same time
	    # update current_prop to match.

	    # what properties have changed and need PDF calls to update?
	    $call_get_font = 0;
	    if ($properties[-1]->{'font-family'} ne $current_prop->{'font-family'}) {
		 $call_get_font = 1;
		 # a font label known to FontManager
		 $current_prop->{'font-family'} = $properties[-1]->{'font-family'};
            }
	    if ($properties[-1]->{'font-style'} ne $current_prop->{'font-style'}) {
		 $call_get_font = 1;
		 # normal or italic
		 $current_prop->{'font-style'} = $properties[-1]->{'font-style'};
            }
	    if ($properties[-1]->{'font-weight'} ne $current_prop->{'font-weight'}) {
		 $call_get_font = 1;
		 # normal or bold
		 $current_prop->{'font-weight'} = $properties[-1]->{'font-weight'};
            }
	    # font size
	    # don't want to trigger font call unless numeric value changed
	    # current_prop's s/b in points, newval will be in points. if
	    # properties (latest request) is a relative size (e.g., %),
	    # what it is relative to is NOT the last font size used
	    # (current_prop), but carried-along current font size.
	    my $newval = _fs2pt($properties[-1]->{'font-size'}, 
	                        $properties[-1]->{'_fs'});
	    $properties[-1]->{'_fs'} = $newval;  # remember it!
	    # newval is the latest requested size (in points), while
	    # current_prop is last one used for output (in points)
	    if ($newval != $current_prop->{'font-size'}) {
	        $call_get_font = 1;
		$current_prop->{'font-size'} = $newval;
	    }
	    # any size as a percentage of font-size will use the current fs
	    my $fs = $current_prop->{'font-size'};

	    # uncommon to only change font size without also changing something
	    # else, so make font selection call at the same time, besides,
	    # there is very little involved in just returning current font.
	    if ($call_get_font) {
                $text->font($pdf->get_font(
		    'face' => $current_prop->{'font-family'}, 
		    'italic' => ($current_prop->{'font-style'} eq 'normal')? 0: 1, 
		    'bold' => ($current_prop->{'font-weight'} eq 'normal')? 0: 1, 
		                          ), $fs); 
	    }
	    # font-size should be set in current_prop for use by margins, etc.

	    # don't know if color will be used for text or for graphics draw,
	    # so set both
	    if ($properties[-1]->{'color'} ne $current_prop->{'color'}) {
		$current_prop->{'color'} = $properties[-1]->{'color'};
		$text->fillcolor($current_prop->{'color'});
		$text->strokecolor($current_prop->{'color'}); 
		if (defined $grfx && ref($grfx) =~ m/^PDF::Builder::Content/) {
		    $grfx->fillcolor($current_prop->{'color'});
		    $grfx->strokecolor($current_prop->{'color'});
                }
            }

	    # these properties don't get a PDF::Builder call
	    # update text-indent, etc. of current_prop, even if we don't
	    # call a Builder routine to set them in PDF, so we can always use
	    # current_prop instead of switching between the two. current_prop
	    # property lengths should always be in pts (no labeled dimensions).
	    $current_prop->{'text-indent'} = _size2pt($properties[-1]->{'text-indent'}, $fs);
	    $current_prop->{'text-decoration'} = $properties[-1]->{'text-decoration'};
	    $current_prop->{'margin-top'} = _size2pt($properties[-1]->{'margin-top'}, $fs);
	    # the incremental right margin, and the running total
	    $current_prop->{'margin-right'} = _size2pt($properties[-1]->{'margin-right'}, $fs);
	    $properties[-1]->{'_right'} += $current_prop->{'margin-right'};
	    $current_prop->{'margin-bottom'} = _size2pt($properties[-1]->{'margin-bottom'}, $fs);
	    # the incremental left margin, and the running total
	    $current_prop->{'margin-left'} = _size2pt($properties[-1]->{'margin-left'}, $fs);
	    $properties[-1]->{'_left'} += $current_prop->{'margin-left'};
	    # text-height is expected to be a multiplier to font-size, so
	    # % or pts value would have to be converted back to ratio TBD
	    $current_prop->{'text-height'} = $properties[-1]->{'text-height'};
	    $current_prop->{'display'} = $properties[-1]->{'display'};
	    $current_prop->{'list-style-type'} = $properties[-1]->{'list-style-type'};
	    $current_prop->{'list-style-position'} = $properties[-1]->{'list-style-position'};
	    $current_prop->{'_href'} = $properties[-1]->{'_href'};
	    # current_prop should now be up to date with properties[-1], and
	    # any Builder calls have been made

	    # calculate this block's top margin, in points.
	    # if botm (bottom margin of previous block) != 0pt, get larger
	    # of the two and move start of block down by that amount.
	    $topm = $current_prop->{'margin-top'};
            my $vmargin = $botm;
	    if ($botm < $topm) { $vmargin = $topm; }
	    $start_y -= $vmargin; # could be too low for a new line!
	    # will set botm to new margin-bottom after this block is done

	    # we're ready to roll, and output the actual text itself
	    #
	    # fill line from element $el at current x,y until will exceed endx
	    # then get next baseline
	    # if this phrase doesn't finish out the line, will start next
	    # mytext element at the x,y it left off. otherwise, unused portion
	    # of phrase (remainder) becomes the next element to process.
	    $phrase = $mytext[$el]->{'text'}; # there should always be a text
	    # $list_marker was set in li tag processing
	    # if $list_depth > 0, use $marker_width additional left margin
	    #   calculate $marker_width if 0 from current font and size 
	    #   _marker('decimal', 1, 888, $prop top _marker-before/after)
	    #   note that ol is bold, ul is Symbol (replace macros .disc, etc.).
	    #   content of li is with new left margin. first line ($list_marker
	    #   ne '') text_right of $list_marker at left margin of li text.
	    #   then set $list_marker to '' to cancel out until next li.
	    $remainder = '';

	    # for now, all whitespace convert to single blanks 
	    # TBD blank preserve for <code> or <pre> (CSS white-space)
	    $phrase =~ s/\s+/ /g;

	    # a phrase may have multiple words. see if entire thing fits, and if
	    # not, start trimming off right end (split into a new element)
    
            while ($phrase ne '') {
	        # one of four things to handle:
	        # 1. entire phrase fits at x -- just write it out
	        # 2. none of phrase fits at x (all went into remainder) --
	        #    go to next line to check and write (not all may fit)
	        # 3. phrase split into (shortened) phrase (that fits) and a
	        #    remainder -- write out phrase, remainder to next line to
	        #    check and write (not all may fit)
		# 4. phrase consists of just one word, AND it's too long to
		#    fit on the full line. it must be split somewhere to fit 
		#    the line.

		my $full_line = 0;
	        # this is to force start of a new line at start_y?
		# phrase still has content, and there may be remainder.
		# don't forget to set the new start_y when need_line=1
	        if ($need_line) {
	            # first, set font (current, or something specified)
		    if ($para) { # at top of column, font undefined
	                $text->font($pdf->get_font('face'=>'current'), $fs);
		    }

	            # extents above and below the baseline (so far)?
	            ($asc, $desc, $desc_leading) = 
	                _get_fv_extents($pdf, $font_size, 
				        $properties[-1]->{'text-height'});
	            $next_y = $start_y - $add_y - $asc + $desc_leading;
	            # did we go too low? will return -1 (start_x) and 
		    #   remainder of input
	            # don't include leading when seeing if line dips too low
	            if ($start_y - $add_y - $asc + $desc < $min_y) { last; }
	            # start_y and next_y are vertical extent of this line 
		    #   (so far)
	            # y is the y value of the baseline (so far)
	            $y = $start_y - $add_y - $asc;

	            # how tall is the line? need to set baseline. add_y is
		    #   any paragraph top margin to drop further. note that this
		    #   is just the starting point -- the line could get taller
                    ($start_x,$y, $width) = _get_baseline($y, @outline);
                    # need to increase start_x, or list too far left
		    $start_x += $properties[-1]->{'_left'};
		    $width -= $properties[-1]->{'_left'} + $properties[-1]->{'_right'};
                    $endx = $start_x + $width;
		    $x = $start_x;
	            # at this point, we have established the next baseline 
		    #   (x,y start and width/end x). fill this line.
		    $x += $add_x; $add_x = 0; # indent
		    $add_y = 0; # para top margin extra
		    $need_line = 0;
		    $full_line = 1;

                    # stuff to remember if need to shift line down due to 
		    #   vertical extents increase
		    @line_extents = ();
		    push @line_extents, $start_x; # current baseline's start
		    push @line_extents, $x; # current baseline 
		    # note that $x advances with each write
		    push @line_extents, $y;
		    push @line_extents, $width;
		    push @line_extents, $endx;
		    push @line_extents, $next_y;
		    push @line_extents, $asc; # current vertical extents
		    push @line_extents, $desc;
		    push @line_extents, $desc_leading;
		    # text and graphics contexts and
	            # where the current line starts in the streams
		    push @line_extents, $text;
		    push @line_extents, length($text->{' stream'});
		    push @line_extents, $grfx;
		    if (defined $grfx && ref($grfx) =~ m/^PDF::Builder::Content/) {
		        push @line_extents, length($grfx->{' stream'});
		    } else {
			push @line_extents, 0;
		    }
		    push @line_extents, $start_y;
		    push @line_extents, $min_y;
		    push @line_extents, \@outline;
		    push @line_extents, $properties[-1]->{'_left'};
		    push @line_extents, $properties[-1]->{'_right'};

		    # if starting a line, make sure no leading whitespace
		    # TBD if pre, don't remove whitespace
		    $phrase =~ s/^\s+//;
	        }
    	
		# if this is a <li>, there may be non-empty $list_marker to add
		if ($list_marker ne '') {
		    # we have a <li> list marker to add (bold for <ol>, Symbol
		    # font for <ul>, blank for <sl>)
		    # without this increase of _left, lists don't nest

		    # output the marker. x,y is the upper left baseline of
		    #   the <li> text, so text_right() the marker
		    if ($list_marker =~ m/^\./) {
			# it's a symbol for <ul>. 50% size, +y by 33% size
			# add doubled space at end (font size 50%).
			# TBD url image and other character symbols (possibly
			#     in other than Zapf Dingbats). 
			if      ($list_marker eq '.disc') {
			    $list_marker = chr(108).'  ';
			} elsif ($list_marker eq '.circle') {
			    $list_marker = chr(109).'  ';
			} elsif ($list_marker eq '.square') {
			    $list_marker = chr(110).'  ';
			} elsif ($list_marker eq '.box') {
			    $list_marker = chr(111).'  '; # non-standard
			}
                        $text->font($pdf->get_font(
		            'face' => 'ZapfDingbats',
		            'italic' => 0, 'bold' => 0,
		                                  ), 0.5*$fs); 
			$text->translate($x,$y+0.15*$fs);
			$text->text_right($list_marker);
		    } elsif ($list_marker eq '' || $list_marker eq ' ') {
			# simple list, no marker
		    } else {
			# it's a count for <ol>. use bold. TBD CSS for weight
                        $text->font($pdf->get_font(
		            'face' => $current_prop->{'font-family'},
		            'italic' => 0, 'bold' => 1,
		                                  ), $fs); 
			$text->translate($x,$y);
			$text->text_right($list_marker);
		    }

		    # clear the marker so must be redefined for next <li>
		    $list_marker = '';
		    # restore font to requested one
                    $text->font($pdf->get_font(
		        'face' => $current_prop->{'font-family'}, 
		        'italic' => ($current_prop->{'font-style'} eq 'normal')? 0: 1, 
		        'bold' => ($current_prop->{'font-weight'} eq 'normal')? 0: 1, 
		                              ), $fs); 
		}

		# have a phrase to attempt to add to output, and an
		#   x,y to start it at (tentative if start of line)
	        my $w = $text->advancewidth($phrase);

	        if ($x + $w <= $endx) {
		    my $rc;
	            # no worry, the entire phrase fits (case 1.)
	            $text->translate($x,$y);
		    # y (and possibly x) might change if extents change
		    my $w = $text->advancewidth($phrase);
		    if ($current_prop->{'text-decoration'} ne 'none') {
			# output any requested line strokes, after baseline
			#   positioned and before baseline adjusted
			# supported: underline, line-through, overline
			# may be a combination separated by spaces
			# inherit current color (strokecolor) setting
			my $font = $pdf->get_font('face'=>'current');
			my $strokethickness = $font->underlinethickness() || 1;
			$strokethickness *= $fs/1000;
			my $stroke_ydist = $font->underlineposition() || 1;

			# don't stroke through any trailing whitespace
			my $trail = 0; # width of WS
			if ($phrase =~ m/(\s+)$/) {
			    $trail = $text->advancewidth($1);
			}

			$stroke_ydist *= $fs/1000;
			$text->add('q');
			$text->add('ET'); # go into graphics mode
			$text->add("$strokethickness w");
			# baseline is x,y to x+w,y, ydist is < 0
			if ($current_prop->{'text-decoration'} =~ m#underline#) { 
			    # use ydist as-is
			    $text->add("$x ".($y+$stroke_ydist)." m");
			    $text->add(($x+$w-$trail)." ".($y+$stroke_ydist)." l");
			}
			if ($current_prop->{'text-decoration'} =~ m#line-through#) { 
			    # use new ydist at .3fs
			    $stroke_ydist = 0.3*$fs;
			    $text->add("$x ".($y+$stroke_ydist)." m");
			    $text->add(($x+$w-$trail)." ".($y+$stroke_ydist)." l");
			}
			if ($current_prop->{'text-decoration'} =~ m#overline#) {
			    # use new ydist at 0.65fs
			    $stroke_ydist = 0.70*$fs;
			    $text->add("$x ".($y+$stroke_ydist)." m");
			    $text->add(($x+$w-$trail)." ".($y+$stroke_ydist)." l");
			}
			$text->add('S');
			$text->add('BT'); # back into text mode
			$text->add('Q');
		    }
		    # before writing a new phrase with possibly increased
		    # extents, see if new baseline needed
	            # extents above and below the baseline (so far)?
	            my ($n_asc, $n_desc, $n_desc_leading) = 
	                _get_fv_extents($pdf, $current_prop->{'font-size'}, 
				        $properties[-1]->{'text-height'});
		    $line_extents[1] = $x;  # current position
		    ($rc, @line_extents) = 
		        _revise_baseline(@line_extents, $n_asc, $n_desc, $n_desc_leading, $w);
		    ($start_x, $x, $y, $width, $endx, $next_y, 
			$asc, $desc, $desc_leading)
		        = @line_extents; # only parts which might have changed
		    # if rc == 0, line successfully moved down page
		    # if rc == 1, existing line moved down, but need to check if
		    #             still room for $phrase
		    # if rc == 2, current written line doesn't fit narrower line
		    # if rc == 3, revised line won't fit in column! (vertically)
		    # TBD need to check $rc once column width can vary
	            $text->text($phrase);

                    if ($current_prop->{'_href'} ne '') {
			# this text is a link, so need to make an annot. link
			# $x,$y is baseline left, $w is width
			# $asc, $desc are font ascenders/descenders
                        # some extra margin to make it easier to select
                        my $fs = 0.2*$current_prop->{'font-size'};
                        my $rect = [ $x-$fs, $y-$desc-3*$fs, 
				     $x+$w+$fs, $y+$asc+$fs ];
			# TBD what if link wraps around? make two or more?
			my $annotation = $page->annotation();
			my $href = $current_prop->{'_href'};
			# TBD: href=pdf:docpath.pdf#p.x.y.z jump to another PDF
			if ($href =~ m/^#/) {
			    # href starts with # so it's a jump within this doc
			    my ($pageno, $xpos, $ypos, $zoom);
			    if      ($href =~ m/^#(\d+)$/) {
				# #p format (whole page)
				$pageno = $1;
				$xpos = $ypos = $zoom = undef;
			    } elsif ($href =~ m/^#(\d+)-(\d+)-(\d+)$/) {
				# #p-x-y format (no zoom, at a specific spot)
				$pageno = $1;
				$xpos = $2;
				$ypos = $3; 
				$zoom = undef;
			    } elsif ($href =~ m/^#(\d+)-(\d+)-(\d+)-(.+)$/) {
				# #p-x-y-z format (zoom, at a specific spot)
				$pageno = $1; # integer > 0
				$xpos = $2; # number >= 0
				$ypos = $3; # number >= 0
				$zoom = $4; # number >= 0
				if ($zoom <= 0) {
				    carp "Invalid zoom value $zoom. Using 1";
				    $zoom = 1;
				}
		            } else {
			        # bad format
				carp "Invalid link format '$href'. Using page 1";
				$pageno = 1;
				$xpos = $ypos = $zoom = undef;
			    }
			    if ($pageno < 1) { 
				carp "Invalid page number $pageno. Using page 1";
				$pageno = 1; 
			    }
			    if (defined $xpos && $xpos < 0) { 
				carp "Invalid page x coordinate $xpos. Using x=100";
				$xpos = 100; 
			    }
			    if (defined $ypos && $ypos < 0) { 
				carp "Invalid page y coordinate $ypos. Using y=300";
				$ypos = 300; 
			    }

			    my $tgt_page = $pdf->open_page($pageno);
			    if (!defined $tgt_page) {
				carp "Invalid page number $pageno. Using page 1";
				$pageno = 1;
				$tgt_page = $pdf->open_page($pageno);
			    }
			    if (!defined $xpos) {
				# page only
			        $annotation->link($tgt_page,
			            'rect'=>$rect, 'border'=>[0,0,0]);
			    } else {
				# page at a location and zoom factor
			        $annotation->link($tgt_page,
			            'rect'=>$rect, 'border'=>[0,0,0],
			            'xyz'=>[ $xpos,$ypos, $zoom ]);
			    }
			} else {
			    # webpage (usually HTML) link
			    $annotation->uri($href,
			        'rect'=>$rect, 'border'=>[0,0,0]);
		        }
		    }
	            $x += $w;
		    $full_line = 0;
		    $need_line = 0;
		    # change current property display to inline
		    $current_prop->{'display'} = 'inline';

	            # next element in mytext (try to fit on same line)
		    $phrase = $remainder; # may be empty
		    $remainder = '';
		    # since will start a new line, trim leading w/s
		    $phrase =~ s/^\s+//;  # might now be empty
		    if ($phrase ne '') {
			# phrase used up, but remainder for next line
			$need_line = 1;
			$start_y = $next_y;
		    }
		    next; # done with phrase loop if phrase empty

	        } else {
		    # existing line plus phrase is too long
	            # entire phrase does NOT fit (case 2 or 3). start splitting 
		    # up phrase, beginning with stripping space(s) off end

                    if ($phrase =~ s/(\s+)$//) {
		        # remove whitespace at end (line will end somewhere
		        # within phrase, anyway)
		        $remainder = $1.$remainder;
		    } else {
	                # Is line too short to fit even the first word at the
		        # beginning of the line? force split in word somewhere 
			# so that it fits.
	                my $word = $phrase;
	                $word =~ s/^\s+//; # probably not necessary, but doesn't hurt
	                $word =~ s/\s+$//;
	                if ($full_line && index($word, ' ') == -1) {
	                    my ($wordLeft, $wordRight);
                            # is a single word at the beginning of the line, 
			    # and didn't fit
                            require PDF::Builder::Content::Hyphenate_basic;
                            ($wordLeft,$wordRight) = PDF::Builder::Content::Hyphenate_basic::splitWord($text, $word, $w);
			    if ($wordLeft eq '') {
				# failed to split. try desperation move of
				# splitting at Non Splitting SPace!
                                ($wordLeft,$wordRight) = PDF::Builder::Content::Hyphenate_basic::splitWord($text, $word, $w, 'spRB'=>1);
				if ($wordLeft eq '') {
	                            # super-desperation move... split to fit 
				    # space! eventually with proper hyphenation
				    # this probably will never be needed.
                                    ($wordLeft,$wordRight) = PDF::Builder::Content::Hyphenate_basic::splitWord($text, $word, $endx-$x, 'spFS'=>1);
				}
			    }
			    $phrase = $wordLeft; 
			    $remainder = "$wordRight $remainder";
                            next; # re-try shortened phrase
	                }
    
		        # phrase should end with non-whitespace if here. 
			# try moving last word to remainder
                        if ($phrase =~ s/(\S+)$//) {
		            # remove word at end
		            $remainder = $1.$remainder;
		        }
		    }
		    # at least part of text will end up on another line.
	            # find current <p> and add cont=>1 to it to mark 
		    # continuation in case we end up at end of column
	            for (my $ptag=$el-1; $ptag>1; $ptag--) {
		        if ($mytext[$ptag]->{'text'} ne '') { next; }
		        if ($mytext[$ptag]->{'tag'} ne 'p') { next; }
		        $mytext[$ptag]->{'cont'} = 1;
		        last;
	            }
    
		    if ($phrase eq '' && $remainder ne '') {
			# entire phrase goes to next line
			$need_line = 1;
			$start_y = $next_y;
			$add_x = $add_y = 0;
			$phrase = $remainder;
			$remainder = '';
		    }
		    next;
	            
		} # phrase did not fit (else)
	        # end of entire phrase does NOT fit

            } # end of while phrase has content loop
	    # remainder should be '' at this point, phrase may have content
	    # either ran out of phrase, or ran out of column

	    if ($phrase eq '') {
		# ran out of input text phrase, so process more elements
		# but first, remove this text from mytext array so won't be
		#   accidentally repeated
		splice(@mytext, $el, 1);
		$el--;
		next;
	    }
	    # could get here if exited loop due to running out of column,
	    # in which case, phrase has to be stuffed back into mytext
	    $mytext[$el]->{'text'} = $phrase;
            last;
	    
	} 
	# end of processing this element in mytext, UNLESS it was text (phrase)
	# and we ran out of column space!

	if ($phrase ne '') {
	    # we left early, with incomplete text, because we ran out of
	    # column space. can't process any more elements -- done with column.
	    # mytext[el] already updated with remaining text
	    last; # exit mytext loop
	} else {
	    # more elements to go
	    next;
	}

    } # for $el loop through mytext array over multiple lines

    # if get to here, is it because we ran out of mytext (normal loop exit), or 
    #   because we ran out of space in the column (early exit, in middle of a
    #   text element)?
    #
    # for whatever reason we're exiting, remove first array element (default
    # CSS entries). it is always re-created on entry to column(). leave next 
    # element (consolidated <style> tags, if any).
    shift @mytext;

    if ($#mytext == 0) {
	# [0] = consolidated styles (default styles was just removed)
	# we ran out of input. return next start_y and empty list ref
	
	# first, handle restore = 0, 1, or 2
	if      ($restore == 0) {
	    # carry out pending font and color changes
	    # what properties have changed and need PDF calls to update?
	    my $call_get_font = 0;
	    if ($properties[-1]->{'font-family'} ne $current_prop->{'font-family'}) {
		 $call_get_font = 1;
		 # a font label known to FontManager
		 $current_prop->{'font-family'} = $properties[-1]->{'font-family'};
            }
	    if ($properties[-1]->{'font-style'} ne $current_prop->{'font-style'}) {
		 $call_get_font = 1;
		 # normal or italic
		 $current_prop->{'font-style'} = $properties[-1]->{'font-style'};
            }
	    if ($properties[-1]->{'font-weight'} ne $current_prop->{'font-weight'}) {
		 $call_get_font = 1;
		 # normal or bold
		 $current_prop->{'font-weight'} = $properties[-1]->{'font-weight'};
            }
	    # font size
	    # don't want to trigger font call unless numeric value changed
	    # current_prop's s/b in points, newval will be in points. if
	    # properties (latest request) is a relative size (e.g., %),
	    # what it is relative to is NOT the last font size used
	    # (current_prop), but carried-along current font size.
	    my $newval = _fs2pt($properties[-1]->{'font-size'}, 
	                        $properties[-1]->{'_fs'});
	    $properties[-1]->{'_fs'} = $newval;  # remember it!
	    # newval is the latest requested size (in points), while
	    # current_prop is last one used for output (in points)
	    if ($newval != $current_prop->{'font-size'}) {
	        $call_get_font = 1;
		$current_prop->{'font-size'} = $newval;
	    }
	    # any size as a percentage of font-size will use the current fs
	    my $fs = $current_prop->{'font-size'};

	    if ($call_get_font) {
                $text->font($pdf->get_font(
		    'face' => $current_prop->{'font-family'}, 
		    'italic' => ($current_prop->{'font-style'} eq 'normal')? 0: 1, 
		    'bold' => ($current_prop->{'font-weight'} eq 'normal')? 0: 1, 
		                          ), $fs); 
	    }
	    # font-size should be set in current_prop for use by margins, etc.

	    # don't know if color will be used for text or for graphics draw,
	    # so set both
	    if ($properties[-1]->{'color'} ne $current_prop->{'color'}) {
		$current_prop->{'color'} = $properties[-1]->{'color'};
		$text->fillcolor($current_prop->{'color'});
		$text->strokecolor($current_prop->{'color'}); 
		if (defined $grfx && ref($grfx) =~ m/^PDF::Builder::Content/ ) {
		    $grfx->fillcolor($current_prop->{'color'});
		    $grfx->strokecolor($current_prop->{'color'});
                }
            }
	} elsif ($restore == 1) {
	    # do nothing, leave the font state/colors as-is
	} else { # 2
	    # restore to entry with @entry_state
	    return (2, $next_y-$botm, []);
	}

	return (0, $next_y-$botm, []);
    } else {
	# we ran out of vertical space in the column. return -1 and 
	# remainder of mytext list (next_y would be inapplicable)
	
	# first, handle restore = 0, 1, or 2
	if ($restore == 0 || $restore == 1) {
	    # do nothing, leave the font state/colors as-is
	} else { # 2
	    # restore to entry with @entry_state
	    return (3, -1, \@mytext);
	}

	return (1, -1, \@mytext);
    }

} # end of _output_text()

# initialize current property settings to values that will cause updates (PDF
# calls) when the first real properties are determined, and thereafter whenever
# these properties change
sub _init_current_prop {

    my $cur_prop = {};
    
    # NOTE that all lengths must be in points (unitless), ratios are
    # pure numbers, named things are strings.
    $cur_prop->{'font-size'} = -1;
    $cur_prop->{'text-height'} = 0;
    $cur_prop->{'text-indent'} = 0;
    $cur_prop->{'color'} = 'black'; # PDF default
    $cur_prop->{'font-family'} = 'yoMama';  # force a change
    $cur_prop->{'font-weight'} = 'abnormal';
    $cur_prop->{'font-style'} = 'abnormal';
   #$cur_prop->{'font-variant'} = 'abnormal';
    $cur_prop->{'margin-top'} = '0'; 
    $cur_prop->{'margin-right'} = '0'; 
    $cur_prop->{'margin-bottom'} = '0'; 
    $cur_prop->{'margin-left'} = '0'; 
   #$cur_prop->{'text-align'} = 'left';
   #$cur_prop->{'text-transform'} = 'none';
   #$cur_prop->{'border-style'} = 'none';
   #$cur_prop->{'border-width'} = '1pt'; 
   #$cur_prop->{'border-color'} = 'inherit'; 
    $cur_prop->{'text-decoration'} = 'none';
    $cur_prop->{'display'} = 'block';
    $cur_prop->{'list-style-type'} = '.u';
    $cur_prop->{'list-style-position'} = 'outside';
    $cur_prop->{'_marker-before'} = ''; 
    $cur_prop->{'_marker-after'} = '.'; 
    $cur_prop->{'_href'} = '';
    
    return $cur_prop;
} # end of _init_current_prop()

# update a properties hash for a specific selector (all, if not given)
# in all but a few cases, a higher level selector overrides a lower level by
#   simply replacing the old content, but in some, property values are
#   combined
sub _update_properties {
    my ($target, $source, $selector) = @_;

    my $tag = '';
    if (defined $selector) {
        if ($selector =~ m#^tag:(.+)$#) {
	    $tag = $1;
	    $selector = undef;
	}
    }

    if (defined $selector) {
        if (defined $source->{$selector}) {
	    foreach (keys %{$source->{$selector}}) {
		# $selector e.g., 'u' for underline
		# $_ is property name, e.g., 'text-decoration'
		# special treatment for text-decoration
		if ($_ eq 'text-decoration') {
		    # 'none' is overwritten, but subsequent values appended
		    if (defined $target->{$_} && $target->{$_} ne 'none') {
			$target->{$_} .= " $source->{$selector}->{$_}";
		    } else {
                        $target->{$_} = $source->{$selector}->{$_};
		    }
		} else {
                    $target->{$_} = $source->{$selector}->{$_};
		}
            }
	}
    } else { # selector not defined (use all)
	foreach my $tag_sel (keys %$source) { # top-level selectors
	    if ($tag_sel eq 'text' || $tag_sel eq 'tag') { next; }
	    if ($tag_sel eq 'cont') { next; } # paragraph continuation flag
	    if ($tag_sel eq 'body') { next; } # do body selector last
	    if (ref($source->{$tag_sel}) ne 'HASH') { 
	        # e.g., <a href="..."> the href element is a string, not a 
		# hashref (ref != HASH), so we put it in directly
		$target->{$tag_sel} = $source->{$tag_sel};
            } else {
	        foreach (keys %{$source->{$tag_sel}}) {
                    $target->{$_} = $source->{$tag_sel}->{$_};
                }
            }
	}
	# do body selector last, after others
	if (defined $source->{'body'}) {
	    foreach (keys %{$source->{'body'}}) {
                $target->{$_} = $source->{'body'}->{$_};
            }
        }
    }

    return;
} # end of _update_properties()

# according to Text::Layout#10, HarfBuzz::Shaper *may* now have per-glyph 
# extents. should check some day when HS is supported (but not mandatory)
sub _get_fv_extents {
    my ($pdf, $font_size, $leading) = @_;

    $leading = 1.0 if $leading <= 0; # actually, a bad value
    $leading++ if $leading < 1.0;    # might have been given as fractional

    my $font = $pdf->get_font('face' => 'current');   # font object realized
    # now it's loaded, if it wasn't already
    my $ascender  = $font->ascender()/1000*$font_size; # positive
    my $descender = $font->descender()/1000*$font_size; # negative

    # ascender is positive, descender is negative (above/below baseline)
    return ($ascender, $descender, $descender-($leading-1.0)*$font_size);
} # end of _get_fv_extents()

# returns a list (array) of x,y coordinates outlining the column defined
# by various options entries. currently only 'rect' is used, to define a
# rectangular outline.
# $grfx is graphics context, non-dummy if 'outline' option given (draw outline)
#
# TBD: what to do if any line too short to use? 

sub _get_column_outline {
    my ($grfx, $draw_outline, %opts) = @_;

    my @outline = ();
    # currently only 'rect' supported. TBD: path
    if (!defined $opts{'rect'}) {
	croak "column: no outline of column area defined";
    }

    # treat coordinates as absolute, unless 'relative' option given
    my $off_x = 0;
    my $off_y = 0;
    my $scale_x = 1;
    my $scale_y = 1;
    if (defined $opts{'relative'}) {
        my @relative = @{ $opts{'relative'} };
        croak "column: invalid number of elements in 'relative' list" 
            if (@relative < 2 || @relative > 4);

        $off_x = $relative[0];
        $off_y = $relative[1];
	# @relative == 2 use default 1 1 scale factors
        if (@relative == 3) { # same scale for x and y
            $scale_x = $scale_y = $relative[2];
        }
        if (@relative == 4) { # different scales for x and y
            $scale_x = $relative[2];
            $scale_y = $relative[3];
        }
    }

    my @rect = @{$opts{'rect'}};  # if using 'rect' option
    push @outline, [$rect[0], $rect[1]]; # UL corner = x,y
          # TBD: check x,y reasonable, w,h reasonable
    push @outline, [$rect[0]+$rect[2], $rect[1]]; # UR corner + width
    push @outline, [$rect[0]+$rect[2], $rect[1]-$rect[3]]; # LR corner - height
    push @outline, [$rect[0], $rect[1]-$rect[3]]; # LL corner - width
    push @outline, [$rect[0], $rect[1]]; # back to UL corner

    # TBD: 'path' option

    # treat coordinates as absolute or relative
    for (my $i = 0; $i < scalar @outline; $i++) {
	$outline[$i][0] = $outline[$i][0]*$scale_x + $off_x;
	$outline[$i][1] = $outline[$i][1]*$scale_y + $off_y;
    }

    # requested to draw outline (color other than 'none')?
    if ($draw_outline ne 'none' && defined $grfx && ref($grfx) =~ m/^PDF::Builder::Content/) {
	$grfx->strokecolor($draw_outline);
	$grfx->linewidth(0.5);
	# only rect currently supported
	my @flat = ();
        for (my $i = 0; $i < scalar @outline; $i++) {
	    push @flat, $outline[$i][0];
	    push @flat, $outline[$i][1];
	}
	$grfx->poly(@flat);
	$grfx->stroke();
    }

    return @outline;
} # end of _get_column_outline()

sub _get_col_extents {
    my (@outline) = @_;
    my ($minx, $miny, $maxx, $maxy);

    # for rect, all pairs are x,y. once introduce splines/arcs, need more
    for (my $i = 0; $i < scalar @outline; $i++) {
	if ($i == 0) {
	    $minx = $maxx = $outline[$i][0];
	    $miny = $maxy = $outline[$i][1];
	} else {
	    $minx = min($minx, $outline[$i][0]);
	    $miny = min($miny, $outline[$i][1]);
	    $maxx = max($maxx, $outline[$i][0]);
	    $maxy = max($maxy, $outline[$i][1]);
	}
    }

    return ($minx, $miny, $maxx, $maxy);
} # end of _get_col_extents()

# get the next baseline from column outline @outline
# the first argument is the y value of the baseline
# we've already checked that there is room in this column, so y is good
# returns on-page x,y, and width of baseline
# currently expect outline to be UL UR LR LL UL coordinates. 
# TBD: arbitrary shape with line at start_y clipped by outline (if multiple
# lines result, pick longest or first one)
sub _get_baseline {
    my ($start_y, @outline) = @_;

    my ($x,$y, $width);
    $x = $outline[0][0];
    $y = $start_y;
    $width = $outline[1][0] - $x;

    # note that this is the baseline, so it is possible that some
    # descenders may exceed the limit, in a non-rectangular outline!

    return ($x,$y, $width);
} # end of _get_baseline()

# returns array of hashes with prepared text. input could be
#  'pre' markup: must be an array (list) of hashes, returned unchanged.
#  'none' markup: empty lines separate paragraphs, array of texts permitted,
#     paragraphs may not span array elements.
#   'md1' markup: empty lines separate paragraphs, array of texts permitted,
#     paragraphs may span array elements, content is converted to HTML
#     per Text::Markdown, one array element at a time.
#   'html' markup: single text string OR array of texts permitted (consolidated
#     into one text), containing HTML markup. 
#
# each element is a hash containing the text and all attributes (HTML or MD
# has been processed).

sub _break_text {
    my ($text, $markup, %opts) = @_;

    my @array = ();

    if      ($markup eq 'pre') {
	# should already be in final format (such as continuing a column)
	return @$text;

    } elsif ($markup eq 'none') {
	# split up on blank lines into paragraphs and wrap with p and /p tags
        if       (ref($text) eq '') {
	    # is a single string (scalar)
            @array = _none_hash($text, %opts);

        } elsif (ref($text) eq 'ARRAY') {
	    # array ref, elements should be text
            for (my $i = 0; $i < scalar(@$text); $i++) {
                @array = (@array, _none_hash($text->[$i], %opts));
	    }
	}

        # dummy style element at array element [0]
        my $style;
        $style->{'tag'} = 'style';
        $style->{'text'} = '';
        unshift @array, $style;

    } elsif ($markup eq 'md1') {
	# process into HTML, then feed to HTML processing to make hash
	# note that blank-separated lines already turned into paragraphs
        if       (ref($text) eq '') {
	    # is a single string (scalar)
            @array = _md1_hash($text, %opts);

        } elsif (ref($text) eq 'ARRAY') {
	    # array ref, elements should be text
            @array = _md1_hash(join("\n", @$text), %opts);
	}

    } else { # should be 'html'
        if       (ref($text) eq '') {
	    # is a single string (scalar)
            @array = _html_hash($text, %opts);
	    
        } elsif (ref($text) eq 'ARRAY') {
	    # array ref, elements should be text
	    # consolidate into one string. 
            @array = _html_hash(join("\n", @$text), %opts);
	}
    }

    return @array;
} # end of _break_text()

# convert unformatted string to array of hashes, splitting up on blank lines.
# return with only markup as paragraphs
# note that you can NOT span a paragraph across array elements
sub _none_hash {
    my ($text, %opts) = @_;

    my @array = ();
    my $in_para = 0;
    my $line = '';
    chomp($text); # don't want empty last element due to trailing \n
    foreach (split /\n/, $text) {
	# should be no \n's, but adjacent non-empty lines need to be joined
	if ($_ =~ /^\s*$/) {
	    # empty/blank line. end paragraph if one in progress
	    if ($in_para) {
	        push @array, {'tag' => '', 'text' => $line};
		push @array, {'text' => "", 'tag' => '/p'};
		$in_para = 0;
		$line = '';
	    }
	    # not in a paragraph, just ignore this entry

	} else {
	    # content in this line. start paragraph if necessary
	    if ($in_para) {
		# accumulate content into line
		$line .= " $_";
	    } else {
		# start paragraph, content starts with this text
	        push @array, {'text' => "", 'tag' => 'p'};
		$in_para = 1;
		$line = $_;
	    }
	}

    } # end of loop through line(s) in paragraph
   
    # out of input.
    # if still within a paragraph, need to properly close it
    if ($in_para) {
	push @array, {'tag' => '', 'text' => $line};
	push @array, {'text' => "", 'tag' => '/p'};
	$in_para = 0;
	$line = '';
    }
	
    return @array;
} # end of _none_hash()

# convert md1 string to html, returning array of hashes
sub _md1_hash {
    my ($text, %opts) = @_;

    my @array;
    my ($html, $rc);
    $rc = eval {
        require Text::Markdown; # want to use 'markdown'
	1;
    };
    if (!defined $rc) { $rc = 0; }  # not available

    if ($rc) {
	# MD converter appears to be installed, so use it
	$html = Text::Markdown::markdown($text);
    } else {
	# leave as MD, will cause a chain of problems
	warn "Text::Markdown not installed, can't process Markdown";
	$html = $text;
    }

    # dummy (or real) style element will be inserted at array element [0]
    #   by _html_hash()

    # blank-line separated paragraphs already wrapped in <p> </p>
    @array = _html_hash($html, %opts);

    return @array;
} # end of _md1_hash()

# convert html string to array of hashes. this is for both 'html' markup and
# the final step of 'md1' markup.
# returns array (list) of tags and text, and as a side effect, element [0] is
# consolidated <style> tags (may be empty hash)
sub _html_hash {
    my ($text, %opts) = @_;

    my $style = {};  # <style> hashref to return
    my @array;       # array of body tags and text to return
    my ($rc);

    # process 'substitute' stuff here. %opts needs to be passed in!
    if (defined $opts{'substitute'}) {
	# array of substitutions to make 
	foreach my $macro_list (@{$opts{'substitute'}}) {
	    # 4 element array: macro name (including any delimiters, such as ||)
	    #                  HTML code to insert before the macro
	    #                  anything to replace the macro name (could be the
	    #                      macro name itself if you want it unchanged)
	    #                  HTML code to insert after the macro
	    # $text is updated, perhaps multiple times
	    # $macro_list is anonymous array [ macro, before, rep, after ]
	    my $macro = $macro_list->[0];
	    my $sub = $macro_list->[1].$macro_list->[2].$macro_list->[3];
            $text =~ s#$macro#$sub#g;
	}
    }
    # does call include a style initialization (opt in column() call)?
    if (defined $opts{'style'}) {
	# $style should be empty at this point
        $style = _process_style_tag($style, $opts{'style'});
    }

    $rc = eval {
	require HTML::TreeBuilder;
	1;
    };
    if (!defined $rc) { $rc = 0; }  # not available

    if ($rc) {
	# HTML converter appears to be installed, so use it
	my $tree = HTML::TreeBuilder->new();
	$tree->ignore_unknown(0);  # don't discard non-HTML recognized tags
	$tree->no_space_compacting(1);  # preserve spaces
	$tree->warn(1);  # warn if syntax error found
	$tree->p_strict(1);  # auto-close paragraph on new block element
	$tree->implicit_body_p_tag(1);  # loose text gets wrapped in <p>
	$tree->parse_content($text);
	
	# see if there is a <head>, and if so, if any <style> tags within it
	my $head = $tree->{'_head'}; # a hash
	if (defined $head and defined $head->{'_content'}) {
	    my @headList = @{ $head->{'_content'} }; # array of strings and tags
	    @array = _walkTree(0, @headList);
	    # pull out one or more style tags and build $styles hash
            for (my $el = 0; $el < @array; $el++) {
		my $style_text = $array[$el]->{'text'};
		if ($style_text ne '') {
		    # possible style content. style tag immediately before?
		    if (defined $array[$el-1]->{'tag'} &&
			        $array[$el-1]->{'tag'} eq 'style') {
			$style = _process_style_tag($style, $style_text);
		    }
		}
	    }
	} # $style is either empty hash or has style content
	
	# there should always be a body of some sort
	my $body = $tree->{'_body'}; # a hash
	my @bodyList = @{ $body->{'_content'} }; # array of strings and tags
	@array = _walkTree(0, @bodyList);
	# pull out one or more style tags and add to $styles hash
        for (my $el = 0; $el < @array; $el++) {
	    my $style_text = $array[$el]->{'text'};
	    if ($style_text ne '') {
		# possible style content. style tag immediately before?
		if (defined $array[$el-1]->{'tag'} &&
			    $array[$el-1]->{'tag'} eq 'style') {
		    $style = _process_style_tag($style, $style_text);
		    # remove <style> from body (array list)
		    splice(@array, $el-1, 3);
		}
	    }
	} # $style is either empty hash or has style content
    } else {
	# leave as original HTML, will cause a chain of problems
	warn "HTML::TreeBuilder not installed, can't process HTML";
	push @array, {'tag' => '', 'text' => $text};
    }

    # always first element tag=style containing the hash, even if it's empty
    $style->{'tag'} = 'style';
    $style->{'text'} = '';
    unshift @array, $style;
     
    return @array;
} # end of _html_hash()

# given the text between <style> and </style>, and an existing $style
# hashref, update $style and return it
sub _process_style_tag {
    my ($style, $text) = @_;

    # expect sets of selector { property: value; ... }
    # break up into selector => { property => value, ... }
    # replace or add to existing $style
    # note that a selector may be a tagName, a .className, or an #idName

    $text =~ s/\n/ /sg;  # replace end-of-lines with spaces
    while ($text ne '') {
	my $selector;

	if ($text =~ s/^\s+//) { # remove leading whitespace
	    if ($text eq '') { last; }
	}
	if ($text =~ s/([^\s]+)//) { # extract selector
	    $selector = $1;
        }
	if ($text =~ s/^\s*{//) { # remove whitespace up through {
	    if ($text eq '') { last; }
	}
	# one or more property-name: value; sets (; might be missing on last)
	# go into %prop_val. we don't expect to see any } within a property
	# value string.
	if ($text =~ s/([^}]+)//) {
	    $style->{$selector} = _process_style_string({}, $1);
	}
	if ($text =~ s/^}\s*//) { # remove closing } and whitespace
	    if ($text eq '') { last; }
	}

    }

    return $style;
} # end of _process_style_tag()

# decompose a style string into property-value pairs. used for both <style>
# tags and style= attributes.
sub _process_style_string {
    my ($style, $text) = @_;

    # split up at ;'s. don't expect to see any ; within value strings
    my @sets = split /;/, $text;
    # split up at :'s. don't expect to see any : within value strings
    foreach (@sets) {
	my ($property_name, $value) = split /:/, $_;
	if (!defined $property_name || !defined $value) { last; }
	# trim off leading and trailing whitespace from both
	$property_name =~ s/^\s+//;
	$property_name =~ s/\s+$//;
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;
	# trim off any single or double quotes around value string
	if ($value =~ s/^['"]//) {
	    $value =~ s/['"]$//;
	}

	$style->{$property_name} = $value;
    }

    return $style;
} # end of _process_style_string()

# given a list of tags and content and attributes, return a list of hashes.
# new array element at start, at each tag, and each _content.
sub _walkTree {
    my ($depth, @bodyList) = @_;
    my ($tag, $element, $no_content);

    my $bLSize = scalar(@bodyList);
    # $depth not really used here, but might come in handy at some point
    my @array = ();

    for (my $elIdx=0; $elIdx<$bLSize; $elIdx++) {
        $element = $bodyList[$elIdx];
	# an element may be a simple text string, but most are hashes that
	# contain a _tag and _content array and any tag attributes. _tag and
	# any attributes go into an entry with text='', while any _content
	# goes into one entry with text='string' and usually no attributes. 
	# if the _tag takes an end tag , it gets its own dummy entry.
	
        if ($element =~ m/^HTML::Element=HASH/) {
            # $element should be anonymous hash
            $tag = $element->{'_tag'};
            push @array, {'tag' => $tag, 'text' => ''};

	    # look for attributes for tag, also see if no child content
	    $no_content = 0;  # has content (children) until proven otherwise
	    my @tag_attr = keys %$element;
	    # VOID elements (br, hr, img, area, base, col, embed, input,
	    # link, meta, source, track, wbr) should NOT have /> to mark
	    # as "self-closing", but it's harmless and much HTML code will
	    # have them marked as "self-closing" even though it really
	    # isn't! So be prepared to handle such dummy attributes, as
	    # per RT 143038.
	    if ($tag eq 'br' || $tag eq 'hr' ||
	        $tag eq 'img' || $tag eq 'area' || $tag eq 'base' ||
	        $tag eq 'col' || $tag eq 'embed' || $tag eq 'input' ||
	        $tag eq 'link' || $tag eq 'meta' || $tag eq 'source' ||
	        $tag eq 'track' || $tag eq 'wbr' || 
		$tag eq 'defaults' || $tag eq 'style') { 
		# self-closing or VOID with unnecessary /, there is no
		# child data/elements for this tag. and, we can ignore
		# this 'attribute' of /.
		# defaults and style are specially treated as a VOID tags
		$no_content = 1; 
	    }
	    foreach my $key (@tag_attr) {
		# has an (unnecessary) self-closing / ?
	        if ($element->{$key} eq '/') { next; }
	        
		# 'key' is more of an attribute within a tag (element)
	        if ($key =~ m/^_/) { next; } # built-in attribute
		# this tag has one or more attributes to add to it
                # add tag attribute (e.g., src= for <img>) to hash
		$array[-1]->{$key} = $element->{$key};
	    }

	    if (!$no_content && defined $element->{'_content'}) {
	        my @content = @{ $element->{'_content'} };
		# content array elements are either text segments or
		# tag subelements
	        foreach (@content) {
	            if ($_ =~ m/^HTML::Element=HASH/) {
		        # HASH child of this _content
		        # recursively handle a tag within _content
		        @array = (@array, _walkTree($depth+1, $_));
		    } else {
                        # _content text, shouldn't be any attributes
		        push @array, {'tag' => '', 'text' => $_};
		    }
	        }
	    } else {
		# no content for this tag
	    }
	    # at end of a tag ... if has content, output end tag
	    if (!$no_content) {
		push @array, {'tag' => "/$tag", 'text' => ''};
	    }

	    $no_content = 0;

       } else {
            # SCALAR (string) element
            push @array, {'tag' => '', 'text' => $element};
       }
   } # loop through _content at this level

   return @array;
} # end of _walkTree()

# convert a font-size (length) into points
# TBD another parm to indicate how to treat 'no unit' case?
sub _fs2pt {
    my ($font_size, $cur_fs) = @_;
    # requested font size (may be % relative to current font size)
    # current font size (pts)

    my $number = 0;
    my $unit = '';
    # split into number and unit
    if      ($font_size =~ m/^(\d+\.?\d*)(.*)$/) {
	$number = $1; # nnn.nn, nnn., or nnn format
	$unit = $2;   # may be empty
    } elsif ($font_size =~ m/^(\.\d+)(.*)$/) {
	$number = $1; # .nnn format
	$unit = $2;   # may be empty
    } else {
	carp "Unable to find number in '$font_size', _fs2pt returning 0";
	return 0;
    }

    if ($unit eq '') {
        # if is already a pure number, just return it
	return $number;
    } elsif ($unit eq 'pt') {
        # if the unit is 'pt', strip off the unit and return the number
        return $number;
    } elsif ($unit eq '%') {
        # if the unit is '%', strip off, /100, multiply by current font-size
	return $number/100 * $cur_fs;
   #} elsif ($unit eq    ) {
        # TBD more units in the future; for now, return an error
    } else {
	carp "Unknown unit '$unit' in '$font_size', _fs2pt assumes 'pt'";
	return $number;
    }

    return 0; # should not get to here
} # end of _fs2pt()

# convert a size (length) into points
# TBD another parm to indicate how to treat 'no unit' case?
sub _size2pt {
    my ($length, $font_size) = @_;
    # length is requested size, possibly with a unit
    # font_size is current_prop font-size (pts), 
    #    in case relative to font size (such as %)

    my $number = 0;
    my $unit = '';
    # split into number and unit
    if      ($length =~ m/^(\d+\.?\d*)(.*)$/) {
	$number = $1; # nnn.nn, nnn., or nnn format
	$unit = $2;   # may be empty
    } elsif ($length =~ m/^(\.\d+)(.*)$/) {
	$number = $1; # .nnn format
	$unit = $2;   # may be empty
    } else {
	carp "Unable to find number in '$length', _size2pt returning 0";
	return 0;
    }

    # font_size should be in points (bare number)
    if ($unit eq '') {
        # if is already a pure number, just return it
	return $number;
    } elsif ($unit eq 'pt') {
        # if the unit is 'pt', strip off the unit and return the number
        return $number;
    } elsif ($unit eq '%') {
        # if the unit is '%', strip off, /100, multiply by current font-size
	return $number/100 * $font_size;
   #} elsif ($unit eq    ) {
        # TBD more units in the future; for now, return an error
    } else {
	carp "Unknown unit '$unit' in '$length', _size2pt assumes 'pt'";
	return $number;
    }

    return 0; # should not get to here
} # end of _size2pt()

# create ordered or unordered list item marker
# for ordered, returns $prefix.formatted_value.$suffix.blank
# for unordered, returns string .disc, .circle, .square, or .box
#   (.box is nonstandard marker)
#
# TBD check that 'none' works properly (as <sl>?)
# TBD for ol, there are many other formats: cjk-decimal, decimal-leading-zero,
#      lower-greek, upper-greek?, lower-latin = lower-alpha, upper-latin =
#      upper-alpha, arabic-indic, -moz-arabic-indic, armenian, [-moz-]bengali, 
#      cambodian (khmer), [-moz-]cjk-earthly-branch, [-moz-]cjk-heavenly-stem, 
#      cjk-ideographic, [-moz-]devanagari, ethiopi-numeric, georgian,
#      [-moz-]gujarati, [-moz-]gurmukhi, hebrew, hiragana, hiragana-iroha, 
#      japanese-formal, japanese-informal, [-moz-]kannada, katakana, 
#      katakana-iroha, korean-hangul-formal, korean-hanja-formal, 
#      korean-hanja-informal, [-moz-]lao, lower-armenian, upper-armenian, 
#      [-moz-]malayalam, mongolian, [-moz-]myanmar, [-moz-]oriya, 
#      [-moz-]persian, simp-chinese-formal, simp-chinese-informal, [-moz-]tamil,
#      [-moz-]telugu, [-moz-]thai, tibetan, trad-chinese-formal, 
#      trad-chinese-informal, disclosure-open, disclosure-closed
# TBD for ol, some browser-specific formats: -moz-ethiopic-halehame,
#      -moz-ethiopic-halehame-am, [-moz-]ethiopic-halehame-ti-et, [-moz-]hangul,
#      [-moz-]hangul-consonant, [-moz-]urdu
# TBD for ul, ability to select images and possibly other characters
sub _marker {
    my ($type, $depth, $value, $prefix, $suffix) = @_; 
                                     # type = list-style-type, 
                                     # depth = 1, 2,... nesting level,
				     # (following ordered list only):
				     #   value = counter (start)
				     #   prefix = text before formatted value
				     #    default ''
				     #   suffix = text after formatted value
				     #    default '.'
    if (!defined $suffix) { $suffix = '.'; }
    if (!defined $prefix) { $prefix = ''; }

    my $output = '';
    if      ($type eq 'decimal') {
	$output = "$prefix$value$suffix ";
    } elsif ($type eq 'upper-roman' || $type eq 'lower-roman') {
	while ($value >= 1000) { $output .= 'M';  $value -= 1000; }
	if ($value >= 900)     { $output .= 'CM'; $value -= 900;  }
	if ($value >= 500)     { $output .= 'D';  $value -= 500;  }
	if ($value >= 400)     { $output .= 'CD'; $value -= 500;  }
	while ($value >= 100)  { $output .= 'C';  $value -= 100;  }
	if ($value >= 90)      { $output .= 'XC'; $value -= 90;   }
	if ($value >= 50)      { $output .= 'L';  $value -= 50;   }
	if ($value >= 40)      { $output .= 'XL'; $value -= 40;   }
	while ($value >= 10)   { $output .= 'X';  $value -= 10;   }
	if ($value == 9)       { $output .= 'IX'; $value -= 9;    }
	if ($value >= 5)       { $output .= 'V';  $value -= 5;    }
	if ($value == 4)       { $output .= 'IV'; $value -= 4;    }
	while ($value >= 1)    { $output .= 'I';  $value -= 1;    }
        if ($type eq 'lower-roman') { $output = lc($output); }
	$output = "$prefix$output$suffix ";
    } elsif ($type eq 'upper-alpha' || $type eq 'lower-alpha') {
	my $n;
	while ($value) {
	    $n = ($value - 1)%26; # least significant letter digit 0..25
	    $output = chr(ord('A') + $n) . $output;
	    $value -= ($n+1);
	    $value /= 26;
	}
        if ($type eq 'lower-alpha') { $output = lc($output); }
	$output = "$prefix$output$suffix ";
    } elsif ($type eq 'disc') {
	$output = '.disc';
    } elsif ($type eq 'circle') {
	$output = '.circle';
    } elsif ($type eq 'square') {
	$output = '.square';
    } elsif ($type eq 'box') {  # non-standard
	$output = '.box';
    } elsif ($type eq 'none') {
	$output = '.none';
    } elsif ($type eq '.u') { # default for unordered list at this depth
	if      ($depth == 1) {
	    $output = '.disc';
	} elsif ($depth == 2) {
	    $output = '.circle';
	} elsif ($depth >= 3) {
	    $output = '.square';
        }
    } elsif ($type eq '.o') { # default for ordered list at this depth
	$output = "$prefix$value$suffix "; # decimal
    } else {
	# unknown. use disc
	$output =  '.disc';
    }

    return $output;
} # end of _marker()

# stuff to remember if need to shift line down due to extent increase
# @line_extents array:
#   $start_x # fixed start of current baseline
#   $x # current baseline offset to write at
#        note that $x changes with each write 
#   $y
#   $width
#   $endx
#   $next_y # where next line will start (may move down)
#   $asc # current vertical extents
#   $desc
#   $desc_leading
#   $text # text context (won't change)
#   length($text->{' stream'}) # where the current line starts in the stream
#                              # (won't change)
#   $grfx # graphis content, might be undef (won't change)
#   length($grfx->{' stream'}) # where the current line starts in the stream
#                              # (won't change)
#   $start_y # very top of this line (won't change)
#   $min_y # lowest allowable inked value (won't change)
#   $outline # array ref to outline (won't change)
#   $left_margin to shorten line (won't change)
#   $right_margin to shorten line (won't change)
# we do the asc/desc externally, as how to get them depends on whether it's
#   a font change, an image or equation, or some other kind of inline object
# $asc = new ascender (does it exceed the old one?)
# $desc = new descender (does it exceed the old one?)
# $desc_leading = new descender with leading (does it exceed the old one?)
# $text_w = width of text ($phrase) to be written
# returns $rc = 0: all OK, line fits with no change to available space
#               1: OK, but available space reduced, so need to recheck
#               2: problem -- existing line (already written) won't fit in
#                             shorter line, much less space for new text
#               3: problem -- line now runs off bottom of column
#         @line_extents, with some entries revised
sub _revise_baseline {
    my ($o_start_x, $o_x, $o_y, $o_width, $o_endx, $o_next_y, $o_asc, $o_desc,
	$o_desc_leading, $text, $line_start_offset, 
	$grfx, $line_start_offsetg, $start_y, $min_y,
	$outline, $margin_left, $margin_right, 
	$asc, $desc, $desc_leading, $text_w) = @_;
    
    my $rc = 0; # everything OK so far
    # items which may change (remembering initial/old values)
    my $start_x = $o_start_x; # line's original starting x
    my $x = $o_x; # current x position
    my $y = $o_y;
    my $width = $o_width;
    my $endx = $o_endx;
    my $next_y = $o_next_y;
    # may change, but supplied separately
    # $asc = $o_asc;
    # $desc = $o_desc;
    # $desc_leading = $o_desc_leading;

    my $need_revise = 0;
    # determine whether we need to revise baseline due to extent increases
    if ($asc > $o_asc) {
	$need_revise = 1;
    } else {
	$asc = $o_asc;
    }
    if ($desc < $o_desc) { # desc and desc_leading are negative values
	$need_revise = 1;
    } else {
	$desc = $o_desc;
    }
    if ($desc_leading < $o_desc_leading) {
	$need_revise = 1;
    } else {
	$desc_leading = $o_desc_leading;
    }

    if ($need_revise) {
	# in middle of line, add_x and add_y are 0
	# start_y is unchanged, but asc, desc may have increased
	$next_y = $start_y - $asc + $desc_leading;
	# did we go too low? will return -1 (start_x) and 
	#   remainder of input
	# don't include leading when seeing if line dips too low
	if ($start_y - $asc + $desc < $min_y) {
	    $rc = 3; # ran out of column (vertically) = we overflow column
	             # off bottom if we go ahead and write any of new text
	    # TBD instead just end line here (early), 
	    #     go to next column for taller text we want to print
	    #     however, could then end up with a very short line!
        } else {
	    # start_y and next_y are vertical extent of this line (revised)
	    # y is the y value of the baseline (so far). lower it a bit.
	    $y -= $asc - $o_asc;
	    # start_x is baseline start (so far), x is current write position

	    # how tall is the line? need to set baseline.
            ($start_x,$y, $width) = _get_baseline($y, @$outline);
            $start_x += $margin_left;
	    $width -= $margin_left + $margin_right;
            $endx = $start_x + $width;
	    $x += $start_x - $o_start_x;

	    # we don't know the nature of the new material attempting to add,
	    #   so can't resolve insufficient space issues here
	    if      ($x > $endx) {
	        # if current (already written) line can't fit (due to much 
		#     shorter line), rc = 2
                $rc = 2;
	    } elsif ($x + $text_w > $endx) {
	        # if new text will overflow line, rc = 1
		$rc = 1;
	    } else { # should have room to write new text
		$rc = 0;
	    
		# revise (move in x,y) any existing text in this line (Tm cmd)
                my $i = $line_start_offset;
		my $delta_x = $start_x - $o_start_x;
		my $delta_y = $y - $o_y;
                while(1) {
                   $i = index($text->{' stream'}, ' Tm', $i+3);
                   if ($i == -1) { last; }
		   # $i is the position of a Tm command in the stream. the two
		   # words before it are x and y position to write at.
		   # $j is $i back up by two spaces
		   my $j = rindex($text->{' stream'}, ' ', $i-1);
		   $j = rindex($text->{' stream'}, ' ', $j-1) + 1;
		   # $j points to first char of x, $i to one after last y char
		   my $str1 = substr($text->{' stream'}, 0, $j);
		   my $str2 = substr($text->{' stream'}, $i);
		   my $old_string = substr($text->{' stream'}, $j, $i-$j);
		   $old_string =~ m/^([^ ]+) ([^ ]+)$/;
		   my $old_x = $1;
		   my $old_y = $2;
		   $old_x += $delta_x;
		   $old_y += $delta_y;
                   $text->{' stream'} = $str1."$old_x $old_y".$str2;
                   # no need to change line_start_offset, but $i has to be 
		   # adjusted to account for possible change in resulting 
		   # position of Tm
		   $i += length("$old_x old_$y") - ($i - $j);
                } 

		# AFTER the Tm statement may come one or more strokes for
		# underline, strike-through, and/or overline
                $i = $line_start_offset;
		# $delta_x, $delta_y same as before
		while (1) {
                   $i = index($text->{' stream'}, ' l S', $i+4);
                   if ($i == -1) { last; }
		   # $i is the position of a lS command in the stream. the five
		   # words before it are x and y positions to write at.
		   # (x y m x' y l S is full command to modify)
		   # $j is $i back up by five spaces
		   my $j = rindex($text->{' stream'}, ' ', $i-1);
		   $j = rindex($text->{' stream'}, ' ', $j-1);
		   $j = rindex($text->{' stream'}, ' ', $j-1);
		   $j = rindex($text->{' stream'}, ' ', $j-1);
		   $j = rindex($text->{' stream'}, ' ', $j-1);
		   # $j points to first char of x, $i to one after last y char
		   my $str1 = substr($text->{' stream'}, 0, $j);
		   my $str2 = substr($text->{' stream'}, $i);
		   my $old_string = substr($text->{' stream'}, $j, $i-$j);
		   $old_string =~ m/^ ([^ ]+) ([^ ]+) m ([^ ]+) ([^ ]+)$/;
		   my $old_x1 = $1;
		   my $old_y1 = $2;
		   my $old_x2 = $3;
		   my $old_y2 = $4;
		   $old_x1 += $delta_x;
		   $old_y1 += $delta_y;
		   $old_x2 += $delta_x;
		   $old_y2 += $delta_y;
                   $text->{' stream'} = $str1." $old_x1 $old_y1 m $old_x2 $old_y2".$str2;
                   # no need to change line_start_offset, but $i has to be 
		   # adjusted to account for possible change in resulting 
		   # position of lS
		   $i += length(" $old_x1 $old_y1 m $old_x2 $old_y2") - ($i - $j);
                } 
	    }
        }
    }

    return ($rc, $start_x, $x, $y, $width, $endx, $next_y, 
	    $asc, $desc, $desc_leading, 
            $text, $line_start_offset, $grfx, $line_start_offsetg,
	    $start_y, $min_y, $outline,
            $margin_left, $margin_right);
} # end of _revise_baseline()

# just something to pause during debugging
sub _pause {
    print STDERR "====> Press Enter key to continue...";
    my $input = <>;
    return;
}

1;
