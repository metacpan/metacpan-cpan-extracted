package PDF::Builder::Content::Hyphenate_basic;

use base 'PDF::Builder::Content::Text';

use strict;
use warnings;

our $VERSION = '3.016'; # VERSION
my $LAST_UPDATE = '3.014'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Content::Hyphenate_basic - Simple hyphenation capability

=head1 SYNOPSIS

These are internal routines that are somewhat experimental, and may (or may
not) be extended in the future. They are called from various Content routines
that take long strings of text and split them into fixed-length lines.

Words are split to fill the line most completely, without regard to widows and
orphans, long runs of hyphens at the right edge, "rivers" of space flowing
through a paragraph, and other problems. Also, only simple splitting is done
(not actually I<words>), on a simple, language-independent basis. No dictionary 
or rules-based splitting is currently done.

This functionality may well be replaced by "hooks" to call language-specific
word-splitting rules, as well as worrying about the appearance of the results
(such as Knuth-Plass).

=cut

# Main entry. Returns array of left portion of word (and -) to stick on end of
# sentence (may be empty) and remaining (right) portion of word to go on next
# line (usually not empty).
sub splitWord {
    my ($self, $word, $width, %opts) = @_;

    my ($leftWord, $rightWord, @splitLoc, @chars, $i, $j, $len, $ptLen);

    # various settings, some of which may be language-specific
    my $minBegin = 2;  # minimum 2 characters before split
    my $minEnd   = 2;  # minimum 2 characters to next line
   #my $hyphen = '-';
    my $hyphen = "\xAD";  # add a hyphen at split, unless splitting at -
                       # or other dash character
    # NOTE: PDF-1.7 14.8.2.2.3 suggests using a soft hyphen (\AD) when splitting
    #       a word at the end of the line, so that when text is extracted for
    #       a screen reader, etc., the closed-up word can have the "visible"
    #       hyphen removed. PDF readers should render as -.
    my @suppressHyphen = ( # ASCII/Latin-1/UTF-8 ordinals to NOT add - after
       #  -   en-dash em-dash /
	  45, 8211,   8212,   47,
                         );
    my $splitHardH = defined($opts{'-spHH'})? $opts{'-spHH'}: 1;  # 1=OK to split on hard (explicit) hyphen U+002D
    my $otherPunc = defined($opts{'-spOP'})? $opts{'-spOP'}: 1;  # 1=OK to split after most punctuation
    my $digitRun = defined($opts{'-spDR'})? $opts{'-spDR'}: 1;  # 1=OK to split after run of digit(s)
    my $letterRun = defined($opts{'-spLR'})? $opts{'-spLR'}: 1;  # 1=OK to split after run of ASCII letter(s)
    my $camelCase = defined($opts{'-spCC'})? $opts{'-spCC'}: 1;  # 1=OK to split camelCase on ASCII lc-to-UC transition

    # note that we are ignoring U+2010 "hyphen" and U+2011 "non-splitting 
    # hyphen". The first is probably rare enough to not be worth the bother,
    # and the second won't be split at anyway.

    $leftWord = '';  # default return values
    $rightWord = $word;

    @splitLoc = ();  # no known OK splits yet

    # highest priority for splits: hard and soft hyphens
    # remove SHYs, remember any break points
    ($word, @splitLoc) = _removeSHY($word);
    # remember any break points due to hard coded hyphens
    @chars = split //, $word;
    for ($i=0; $i<scalar(@chars); $i++) {
	if ($chars[$i] eq '-' && $splitHardH) { push @splitLoc, $i; }
	# note that unlike SHY, - is not removed
    }

    # If nothing in @splitLoc, proceed to find other splits. If @splitLoc
    # has at least one entry, could make it the top priority and split there,
    # and not look at other possible splits. Or, keep adding to @splitLoc 
    # (equal priority for all possible splits). Mix and match is OK
    # (grouping criteria, as hard and soft hyphens were done together).

   #if (!@splitLoc) {
        if ($otherPunc) {
            # look for other punctuation to split after.
	    # don't split on ' or " or other quotes (<, <<, etc.)
	    # !%&)]*+/,.:;<>?^_~ and curly right brace ASCII OK for now
	    # en-dash, em-dash should ideally be split after, whether they are
	    # free floating or embedded between words.
	    my @ASCII_punct = ( '!', '.', '?', ',', '%', '&', ':', ';',
		                '<', '>', ')', ']', chr(125), '_', '~', 
		                '^', '+', '*', '/',   );
	    #                   en-dash em-dash
	    my @UTF8_punct =  ( 8211,   8212,   );
	    # remember not to split if next char is - 
	    # (defer split to after hard hyphen - [if allowed]).
            for ($i=0; $i<scalar(@chars)-1; $i++) {
	        foreach (@ASCII_punct) {
	            if ($chars[$i] eq $_ && $chars[$i+1] ne '-') { 
			push @splitLoc, $i; 
			last;
	            }
	        }
	        foreach (@UTF8_punct) {
	            if (ord($chars[$i]) == $_ && $chars[$i+1] ne '-') { 
			push @splitLoc, $i;
		       	last;
	       	    }
	        }
            }
        }
   #}

    # group digit runs and camelCase together at same priority
   #if (!@splitLoc) {
        if ($digitRun) {
            # look for a run of digits to split after.
	    # that is, any digit NOT followed by another digit.
	    # remember not to split if next char is - 
	    # (defer split to after hard hyphen - [if allowed]).
            for ($i=0; $i<scalar(@chars)-1; $i++) {
	        if ($chars[$i] ge '0' && $chars[$i] le '9' &&
		    !($chars[$i+1] ge '0' && $chars[$i+1] le '9' ||
		      $chars[$i+1] eq '-')) {
		    push @splitLoc, $i;
	        }
	    }
        }

        if ($letterRun) {
            # look for a run of letters (ASCII) to split after.
	    # that is, any letter NOT followed by another letter.
	    # remember not to split if next char is - 
	    # (defer split to after hard hyphen - [if allowed]).
            for ($i=0; $i<scalar(@chars)-1; $i++) {
	        if (($chars[$i] ge 'a' && $chars[$i] le 'z' ||
	             $chars[$i] ge 'A' && $chars[$i] le 'Z' )  &&
		    !($chars[$i+1] ge 'a' && $chars[$i+1] le 'z' ||
		      $chars[$i+1] ge 'A' && $chars[$i+1] le 'Z' ||
	              $chars[$i+1] eq '-')  ) {
		    push @splitLoc, $i;
	        }
	    }
        }

        if ($camelCase) {
            # look for camelCase to split on lowercase to
    	    # uppercase transitions. just ASCII letters for now.
	    # Note that this will split names like McIlroy -> Mc-Ilroy
	    # and MacDonald -> Mac-Donald.
            for ($i=0; $i<scalar(@chars)-1; $i++) {
	        if ($chars[$i] ge 'a' && $chars[$i] le 'z' &&
		    $chars[$i+1] ge 'A' && $chars[$i+1] le 'Z') {
		    push @splitLoc, $i;
	        }
	    }
        }
   #}

   #if (!@splitLoc) {
        # look for real English word split locations
	# TBD
   #}

    # sort final @splitLoc, remove any split points violating "min" settings
    # set $leftWord and $rightWord if find successful split
    if (@splitLoc) {
        @splitLoc = sort { $a <=> $b } @splitLoc;
	# unnecessary to have unique values
        $len = length($word);
	$j = -1;
        for ($i=0; $i<scalar(@splitLoc); $i++) {
            if ($splitLoc[$i] >= $minBegin-1) { last; }
	    $j = $i;	
        }
	if ($j >= 0) { splice(@splitLoc, 0, $j+1); } # remove j+1 els
	$j = -1;
        for ($i=$#splitLoc; $i>=0; $i--) {
            if ($splitLoc[$i] < $len-$minEnd) { last; }
	    $j = $i;	
        }
	if ($j >= 0) { splice(@splitLoc, $j); } # remove els >= j-th

        # scan R to L through @splitLoc to try splitting there
	# TBD estimate starting position in @splitLoc by dividing $width by
	# 1em to get approximate split location; pick highest @splitLoc
	# element that does not exceed it, and move right (probably) or left
	# to get proper split point.
	while (@splitLoc) {
	    $j = pop @splitLoc;  # proposed split rightmost on list
	    my $trial = substr($word, 0, $j+1);
	    # this is the left fragment at the end of the line. make sure
	    # there is room for the space before it, the hyphen (if added), 
	    # and any letter doubling (e.g., in German)

	    # does the left fragment already end in -, etc.?
	    # if it does, don't add a $hyphen. 
	    my $h = $hyphen;
	    $i = ord(substr($trial, -1, 1)); # last character in left fragment
	    foreach (@suppressHyphen) {
		if ($i == $_) { $h = ''; last; }
	    }
	    # $width should already count the trailing space in the existing
	    # line, or full width if empty
	    $len = $self->advancewidth("$trial$h");
	    if ($len > $width) { next; }

	    # any letter doubling needed?
	    $leftWord = $trial.$h;
	    $rightWord = substr($word, $j+1); 
	    last;
	}
	# if fell through because no fragment was short enough, $leftWord and
	# $rightWord were never reassigned, and effect is to leave the entire
	# word for the next line.
    }
    # if 0 elements in @splitLoc, $leftWord and $rightWord already defaulted

    return ($leftWord, $rightWord);
}

# remove soft hyphens (SHYs) from a word. assume is always #173 (good for
# Latin-1, CP-1252, UTF-8; might not work for some encodings)  TBD might want
# to pass in current encoding, or what SHY value is.
# return list of break points where SHYs were removed
sub _removeSHY {
    my ($word) = @_;

    my @SHYs = ();
    my $i = 0;

    my @chars = split //, $word;
    my $out = '';
    foreach (@chars) {
        if (ord($_) == 173) {
	    # it's a SHY, so remove from word, add to list
	    push @SHYs, ($i - 1);
	    next;
	}
	$out .= $_;
	$i++;
    }
    return ($out, @SHYs);
}

1;
