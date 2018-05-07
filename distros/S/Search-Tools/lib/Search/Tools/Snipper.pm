package Search::Tools::Snipper;
use Moo;
extends 'Search::Tools::Object';
with 'Search::Tools::ArgNormalizer';
use Carp;
use Data::Dump qw( dump );
use Search::Tools::XML;
use Search::Tools::UTF8;
use Search::Tools::Tokenizer;
use Search::Tools::HeatMap;

use namespace::autoclean;

our $VERSION = '1.007';

# extra space here so pmvers works against $VERSION
our $ellip          = ' ... ';
our $DefaultSnipper = 'offset';

#
#   TODO allow for returning an array ref of
#   extracts instead of joining them all with $ellip
#

my @attrs = qw(
    as_sentences
    collapse_whitespace
    context
    count
    escape
    force
    ignore_length
    max_chars
    occur
    query
    show
    snipper
    strip_markup
    treat_phrases_as_singles
    type
    type_used
    use_pp
    word_len
);

my %Defaults = (
    type                     => $DefaultSnipper,
    occur                    => 5,
    max_chars                => 300,
    context                  => 8,
    word_len                 => 4,                 # TODO still used?
    show                     => 1,
    collapse_whitespace      => 1,
    escape                   => 0,
    force                    => 0,
    as_sentences             => 0,
    ignore_length            => 0,
    treat_phrases_as_singles => 1,
    strip_markup             => 0,
);

for my $attr (@attrs) {
    my $def = $Defaults{$attr} || undef;
    if ( defined $def ) {
        has( $attr => ( is => 'rw', default => sub {$def} ) );
    }
    else {
        has( $attr => ( is => 'rw' ) );
    }
}

sub BUILD {
    my $self = shift;

    #dump $self;

    $self->{_tokenizer} = Search::Tools::Tokenizer->new(
        re    => $self->query->qp->term_re,
        debug => $self->debug,
    );

    my $wc = $self->query->qp->word_characters;

    # regexp for splitting into terms in _re()
    $self->{_wc_regexp} = qr/[^$wc]+/io;

    $self->{_qre}
        = $self->query->terms_as_regex( $self->treat_phrases_as_singles );

    $self->count(0);

    return $self;
}

# I tried Text::Context but that was too slow.
# Here are several different models.
# I have found that _loop() is faster for single-word queries,
# while _re() seems to be the best compromise between speed and accuracy.
# New in version 0.24 is _token() which is mostly XS and should be best.

sub _pick_snipper {
    my ( $self, $text ) = @_;
    my $snipper_name = $self->type || $DefaultSnipper;
    if ( $self->query->qp->stemmer ) {
        $snipper_name = 'token';
    }
    my $method_name = '_' . $snipper_name;
    $self->type_used($snipper_name);
    my $func = sub { shift->$method_name(@_) };
    return $func;
}

# 2 passes, excluding ' ' in the first one,
# is 60% faster than a single pass including ' '.
# likely because there are far fewer matches
# in either of the 2 than the 1.
sub _normalize_whitespace {
    $_[0] =~ s,[\n\r\t\xa0]+,\ ,go;
    $_[0] =~ s,\ +, ,go;    # \ \ + was 16x slower on bigfile!!
}

sub snip {
    my $self = shift;
    my $text = shift;
    if ( !defined $text ) {
        croak "text required to snip";
    }

    # normalize encoding, esp for regular expressions.
    $text = to_utf8($text);

    # don't snip if we're less than the threshold
    if ( length($text) < $self->max_chars && !$self->ignore_length ) {
        if ( $self->show ) {
            if ( $self->strip_markup ) {
                return Search::Tools::XML->no_html($text);
            }
            return $text;
        }
        return '';
    }

    if ( $self->strip_markup ) {
        $text = Search::Tools::XML->no_html($text);
    }

    if ( $self->collapse_whitespace ) {
        _normalize_whitespace($text);
    }

    # we calculate the snipper each time since caller
    # may set type() or snipper() between calls to snip().
    my $func = $self->snipper || $self->_pick_snipper($text);

    my $s = $func->( $self, $text );

    $self->debug and warn "snipped: '$s'\n";

    # sanity check
    if ( length($s) > ( $self->max_chars * 4 ) && !$self->ignore_length ) {
        $s = $self->_dumb($s);
        $self->debug and warn "too long. dumb snip: '$s'\n";
    }
    elsif ( !length($s) && !$self->ignore_length ) {
        $s = $self->_dumb($text);
        $self->debug and warn "too short. dumb snip: '$s'\n";
    }

    # escape entities before collapsing whitespace.
    $s = $self->_escape($s);

    if ( $self->collapse_whitespace ) {
        _normalize_whitespace($s);
    }

    return $s;

}

sub _token {
    my $self = shift;
    my $qre  = $self->{_qre};
    $self->debug and warn "\$qre: $qre";

    my $method = ( $self->{use_pp} ) ? 'tokenize_pp' : 'tokenize';

    # must split phrases into OR'd regex or else no heat is generated.
    my $qre_ORd = $qre;
    $qre_ORd =~ s/(\\ )+/\|/g;
    my $heat_seeker = qr/^$qre_ORd$/;

    # if stemmer is on, we must stem each token to look for a match
    if ( $self->query->qp->stemmer ) {
        my $stemmer = $self->query->qp->stemmer;
        my $qp      = $self->query->qp;
        my $re      = $heat_seeker;
        $heat_seeker = sub {
            my ($token) = @_;
            my $st = $stemmer->( $qp, $token->str );
            return $st =~ m/$re/;
        };
    }
    my $tokens = $self->{_tokenizer}->$method( $_[0], $heat_seeker );

    #$self->debug and $tokens->dump;

    return $self->_dumb( $_[0] ) unless scalar @{ $tokens->get_heat };

    my $heatmap = Search::Tools::HeatMap->new(
        tokens                    => $tokens,
        window_size               => $self->{context},
        as_sentences              => $self->{as_sentences},
        debug                     => $self->debug,
        _query                    => $self->query,
        _qre                      => $qre,
        _treat_phrases_as_singles => $self->{treat_phrases_as_singles},
        _stemmer                  => $self->query->qp->stemmer,
    );

    # reduce noise in debug
    delete $heatmap->{_query};

    $self->debug and warn "heatmap: " . dump $heatmap;

    my $tokens_arr = $tokens->as_array;

    #warn "snips: " . dump $heatmap->spans;
    if ( $heatmap->has_spans ) {

        # stringify positions
        my @snips;
        for my $span ( @{ $heatmap->spans } ) {

            $self->debug and warn '>>>' . $span->{str_w_pos} . '<<<';
            push( @snips, $span->{str} );
        }
        my $occur_index = $self->occur - 1;
        if ( $#snips > $occur_index ) {
            @snips = @snips[ 0 .. $occur_index ];
        }
        my $snip                   = join( $ellip, @snips );
        my $snips_start_with_query = $_[0] =~ m/^\Q$snip\E/;
        my $snips_end_with_query   = $_[0] =~ m/\Q$snip\E$/;
        if ( $self->{as_sentences} ) {
            $snips_start_with_query = 1;
            $snips_end_with_query   = $snip =~ m/[\.\?\!]\s*$/;
        }

        # if we are pulling out something less than the entire
        # text, insert ellipses...
        if ( $_[0] ne $snip ) {
            $self->debug and warn "extract is smaller than snip";
            my $extract = join( '',
                ( $snips_start_with_query ? '' : $ellip ),
                $snip, ( $snips_end_with_query ? '' : $ellip ) );
            return $extract;
        }
        else {
            return $snip;
        }
    }
    else {

        #warn "no spans. using dumb snip";
        return $self->_dumb( $_[0] );
    }

}

sub _get_offsets {
    my $self = shift;
    return $self->{_tokenizer}->get_offsets( @_, $self->{_qre} );
}

sub _offset {
    my $self    = shift;
    my $txt     = shift;
    my $offsets = $self->_get_offsets($txt);
    my $snips   = $self->_get_offset_snips( $txt, $offsets );
    return $self->_token( join( '', @$snips ) );
}

sub _get_offset_snips {
    my $self    = shift;
    my $txt     = shift;
    my $offsets = shift;

    # grab $size chars on either side of each offset
    # and tokenize each.
    # $size should be nice and wide to minimize the substr() calls.
    my $size = $self->max_chars * 10;

    #warn "window size $size";

    my @buf;
    my $len = length($txt);
    if ( $size > $len ) {

        #warn "window bigger than document";
        return [$txt];
    }

    my ( $seen_start, $seen_end );
    my $last_ending = 0;
    for my $pos (@$offsets) {

        my $tmp;

        my $start = $pos - int( $size / 2 );
        my $end   = $pos + int( $size / 2 );

        # avoid overlaps
        if ( $last_ending && $start < $last_ending ) {
            $start = $last_ending + 1;
            $end   = $start + $size;
        }

        #warn "$start .. $pos .. $end";

        if ( $pos > $end or $pos < $start ) {
            next;
        }

        $last_ending = $end;

        #warn "$start .. $end";

        # if $pos is close to the front of $txt
        if ( $start <= 0 ) {
            next if $seen_start++;

            #warn "start";
            $tmp = substr( $txt, 0, $size );
        }

        # if $pos is somewhere near the end
        elsif ( $end > $len ) {
            next if $seen_end++;

            #warn "end";
            $tmp = substr( $txt, ( $len - $size ) );
        }

        # default is somewhere in the ripe middle.
        else {

            #warn "middle";
            $tmp = substr( $txt, $start, $size );
        }

        push @buf, $tmp;
    }

    return \@buf;
}

sub _loop {
    my $self   = shift;
    my $txt    = shift;
    my $regexp = $self->{_qre};

    #carp "loop snip: $txt";

    $self->debug and carp "loop snip regexp: $regexp";

    my $debug = $self->debug || 0;

    # no matches
    return $self->_dumb($txt) unless $txt =~ m/$regexp/;

    #carp "loop snip: $txt";

    my $context = $self->context - 1;
    my $occur = $self->occur || 1;
    my @snips;

    my $notwc = $self->{_wc_regexp};

    my @words       = split( /($notwc)/, $txt );
    my $count       = -1;
    my $start_again = $count;
    my $total       = 0;
    my $first_match = 0;

WORD: for my $w (@words) {

        if ( $debug > 1 ) {
            warn ">>\n" if $count % 2;
            warn "word: '$w'\n";
        }

        $count++;
        next WORD if $count < $start_again;

        # the next WORD lets us skip past the last frag we excerpted

        my $last = $count - 1;
        my $next = $count + 1;

        #warn '-' x 30 . "\n";
        if ( $w =~ m/^$regexp$/ ) {

            if ( $debug > 1 ) {
                warn "w: '$w' match: '$1'\n";
            }

            $first_match = $count;

            my $before = $last - $context;
            $before = 0 if $before < 0;
            my $after = $next + $context;
            $after = $#words if $after > $#words;

            if ( $debug > 1 ) {
                warn "$before .. $last, $count, $next .. $after\n";
            }

            my @before = @words[ $before .. $last ];
            my @after  = @words[ $next .. $after ];

            my $this_snip_matches = grep {m/^$regexp$/i} ( @before, @after );
            if ($this_snip_matches) {
                $after += $this_snip_matches;
                @after = @words[ $next .. $after ];
            }
            $total += $this_snip_matches;
            $total++;    # for current $w

            my $t = join( '', @before, $w, @after );

            $t .= $ellip unless $count == $#words;

            if ( $debug > 1 ) {
                warn "t: $t\n";
                warn "this_snip_matches: $this_snip_matches\n";
                warn "total: $total\n";
            }

            push( @snips, [ $t, $this_snip_matches + 1 ] );    # +1 for $w
            $start_again = $after;
        }

    }

    # sort by match density.
    # consistent with HeatMap and lets us find
    # the *best* match, including phrases.
    @snips = map { $_->[0] } sort { $b->[1] <=> $a->[1] } @snips;

    if ( $debug > 1 ) {
        carp "snips: " . scalar @snips;
        carp "words: $count\n";
        carp "grandtotal: $total\n";
        carp "occur: $occur\n";
        carp '-' x 50 . "\n";

    }

    $self->count( scalar(@snips) + $self->count );
    my $last_snip = $occur - 1;
    if ( $last_snip > $#snips ) {
        $last_snip = $#snips;
    }

    #warn dump \@snips;
    my $snippet = join( '', @snips[ 0 .. $last_snip ] );
    $self->debug and warn "before no_start_partial: '$snippet'\n";

    #_no_start_partial($snippet);
    $snippet = $ellip . $snippet if $first_match;

    return $snippet;
}

sub _re {

   # get first N matches for each q, then take one of each till we have $occur

    my $self  = shift;
    my $text  = shift;
    my @q     = @{ $self->query->terms };
    my $occur = $self->occur;
    my $Nchar = $self->context * $self->word_len;
    my $total = 0;
    my $notwc = $self->{_wc_regexp};

    # get minimum number of snips necessary to meet $occur
    my $snip_per_q = int( $occur / scalar(@q) );
    $snip_per_q ||= 1;

    my ( %snips, @snips, %ranges, $snip_starts_with_query );
    $snip_starts_with_query = 0;

Q: for my $q (@q) {
        $snips{$q} = { t => [], offset => [] };

        $self->debug and warn "$q : $snip_starts_with_query";

        # try simple regexp first, then more complex if we don't match
        next Q
            if $self->_re_match( \$text, $self->query->regex_for($q)->plain,
            \$total, $snips{$q}, \%ranges, $Nchar, $snip_per_q,
            \$snip_starts_with_query );

        $self->debug and warn "failed match on plain regexp";

        pos $text = 0;    # do we really need to reset this?

        unless (
            $self->_re_match(
                \$text,      $self->query->regex_for($q)->html,
                \$total,     $snips{$q},
                \%ranges,    $Nchar,
                $snip_per_q, \$snip_starts_with_query
            )
            )
        {
            $self->debug and warn "failed match on html regexp";
        }

    }

    return $self->_dumb($text) unless $total;

    # get all snips into one array in order they appeared in $text
    # should be a max of $snip_per_q in any one $q snip array
    # so we should have at least $occur in total,
    # which we'll splice() if need be.

    my %offsets;
    for my $q ( keys %snips ) {
        my @s = @{ $snips{$q}->{t} };
        my @o = @{ $snips{$q}->{offset} };

        my $i = 0;
        for (@s) {
            $offsets{$_} = $o[$i];
        }
    }
    @snips = sort { $offsets{$a} <=> $offsets{$b} } keys %offsets;

    # max = $occur
    @snips = splice @snips, 0, $occur;

    $self->debug and warn dump( \@snips );

    my $snip = join( $ellip, @snips );
    _no_start_partial($snip) unless $snip_starts_with_query;
    $snip = $ellip . $snip unless $text =~ m/^\Q$snips[0]/i;
    $snip .= $ellip unless $text =~ m/\Q$snips[-1]$/i;

    $self->count( scalar(@snips) + $self->count );

    return $snip;

}

sub _re_match {

    # the .{0,$Nchar} regexp slows things WAY down. so just match,
    # then use pos() to get chars before and after.

    # if escape = 0 and if prefix or suffix contains a < or >,
    # try to include entire tagset.

    my ( $self, $text, $re, $total, $snips, $ranges, $Nchar, $max_snips,
        $snip_starts_with_query )
        = @_;

    my $t_len = length $$text;

    my $cnt = 0;

    if ( $self->debug ) {
        warn "re_match regexp: >$re<\n";
        warn "max_snips: $max_snips\n";
    }

RE: while ( $$text =~ m/$re/g ) {

        my $pos          = pos $$text;
        my $before_match = $1;
        my $match        = $2;
        my $after_match  = $3;
        $cnt++;
        my $len  = length $match;
        my $blen = length $before_match;
        if ( $self->debug ) {
            warn "re: '$re'\n";
            warn "\$1 = '$before_match' = ", ord($before_match), "\n";
            warn "\$2 = '$match'\n";
            warn "\$3 = '$after_match' = ", ord($after_match), "\n";
            warn "pos = $pos\n";
            warn "len = $len\n";
            warn "blen= $blen\n";
        }

        if ( $self->debug && exists $ranges->{$pos} ) {
            warn "already found $pos\n";
        }

        next RE if exists $ranges->{$pos};

        my $start_match = $pos - $len - ( $blen || 1 );
        $start_match = 0 if $start_match < 0;

        $$snip_starts_with_query = 1 if $start_match == 0;

        # sanity
        $self->debug
            and warn "match should be [$start_match $len]: '",
            substr( $$text, $start_match, $len ), "'\n";

        my $prefix_start
            = $start_match < $Nchar
            ? 0
            : $start_match - $Nchar;

        my $prefix_len = $start_match - $prefix_start;

        #$prefix_len++; $prefix_len++;

        my $suffix_start = $pos - length($after_match);
        my $suffix_len   = $Nchar;
        my $end          = $suffix_start + $suffix_len;

        # if $end extends beyond, that's ok, substr compensates

        $ranges->{$_}++ for ( $prefix_start .. $end );
        my $prefix = substr( $$text, $prefix_start, $prefix_len );
        my $suffix = substr( $$text, $suffix_start, $suffix_len );

        if ( $self->debug ) {
            warn "prefix_start = $prefix_start\n";
            warn "prefix_len = $prefix_len\n";
            warn "start_match = $start_match\n";
            warn "len = $len\n";
            warn "pos = $pos\n";
            warn "char = $Nchar\n";
            warn "suffix_start = $suffix_start\n";
            warn "suffix_len = $suffix_len\n";
            warn "end = $end\n";
            warn "prefix: '$prefix'\n";
            warn "match:  '$match'\n";
            warn "suffix: '$suffix'\n";
        }

        # try and get whole words if we split one up
        # _no_*_partial does this more rudely

        # might be faster to do m/(\S)*$prefix/i
        # but we couldn't guarantee position accuracy
        # e.g. if $prefix matched more than once in $$text,
        # we might pull the wrong \S*

        unless ( $prefix =~ m/^\s/
            or substr( $$text, $prefix_start - 1, 1 ) =~ m/(\s)/ )
        {
            while ( --$prefix_start >= 0
                and substr( $$text, $prefix_start, 1 ) =~ m/(\S)/ )
            {
                my $onemorechar = $1;

                #warn "adding $onemorechar to prefix\n";
                $prefix = $onemorechar . $prefix;

                #last if $prefix_start <= 0 or $onemorechar !~ /\S/;
            }
        }

        # do same for suffix

        # We get error here under -w
        # about substr outside of string -- is $end undefined sometimes??

        unless ( $suffix =~ m/\s$/ or substr( $$text, $end, 1 ) =~ m/(\s)/ ) {
            while ( $end <= $t_len
                and substr( $$text, $end++, 1 ) =~ m/(\S)/ )
            {

                my $onemore = $1;

                #warn "adding $onemore to suffix\n";
                #warn "before '$suffix'\n";
                $suffix .= $onemore;

                #warn "after  '$suffix'\n";
            }
        }

        # will likely fail to include one half of tagset if other is complete
        unless ( $self->escape ) {
            my $sanity = 0;
            my @l      = ( $prefix =~ /(<)/g );
            my @r      = ( $prefix =~ /(>)/g );
            while ( scalar @l != scalar @r ) {

                @l = ( $prefix =~ /(<)/g );
                @r = ( $prefix =~ /(>)/g );
                last
                    if scalar @l
                    == scalar @r;    # don't take any more than we need to

                my $onemorechar = substr( $$text, $prefix_start--, 1 );

                #warn "tagfix: adding $onemorechar to prefix\n";
                $prefix = $onemorechar . $prefix;
                last if $prefix_start <= 0;
                last if $sanity++ > 100;

            }

            $sanity = 0;
            while ( $suffix =~ /<(\w+)/ && $suffix !~ /<\/$1>/ ) {

                my $onemorechar = substr( $$text, $end, 1 );

                #warn "tagfix: adding $onemorechar to suffix\n";
                $suffix .= $onemorechar;
                last if ++$end > $t_len;
                last if $sanity++ > 100;

            }
        }

        #		warn "prefix: '$prefix'\n";
        #		warn "match:  '$match'\n";
        #		warn "suffix: '$suffix'\n";

        my $context = join( '', $prefix, $match, $suffix );

        #warn "context is '$context'\n";

        push( @{ $snips->{t} },      $context );
        push( @{ $snips->{offset} }, $prefix_start );

        $$total++;

        #		warn '-' x 40, "\n";

        last if $cnt >= $max_snips;
    }

    return $cnt;
}

sub _dumb {

    # just grap the first X chars and return

    my $self = shift;
    return '' unless $self->show;

    my $txt = shift;
    my $max = $self->max_chars;
    $self->type_used('dumb');

    my $show = substr( $txt, 0, $max );
    _no_end_partial($show);
    $show .= $ellip;

    $self->count( 1 + $self->count );

    return $show;

}

sub _no_start_partial {
    $_[0] =~ s/^\S+\s+//gs;
}

sub _no_end_partial {
    $_[0] =~ s/\s+\S+$//gs;
}

sub _escape {
    if ( $_[0]->escape ) {
        return Search::Tools::XML->escape( $_[1] );
    }
    else {
        return $_[1];
    }
}

1;
__END__

=pod

=head1 NAME

Search::Tools::Snipper - extract terms in context

=head1 SYNOPSIS

 use Search::Tools;
 my $query = qw/ quick dog /;
 my $text  = 'the quick brown fox jumped over the lazy dog';

 my $s = Search::Tools->snipper(
     occur       => 3,
     context     => 8,
     word_len    => 5,
     max_chars   => 300,
     query       => $query
 );

 print $s->snip( $text );


=head1 DESCRIPTION

Search::Tools::Snipper extracts terms and their context from a larger
block of text. The larger block may be plain text or HTML/XML.


=head1 METHODS

=head2 new( query => I<query> )

Instantiate a new object. I<query> must be either a scalar string
or a Search::Tools::Query object

Many of the following methods
are also available as key/value pairs to new().

=head2 BUILD

Called internally by new().

=head2 as_sentences B<Experimental feature>

Attempt to extract a snippet that starts at a sentence boundary.

=head2 occur

The number of snippets that should be returned by snip().

Available via new().

=head2 context

The number of context words to include in the snippet.

Available via new().

=head2 max_chars

The maximum number of characters (not bytes! under Perl >= 5.8) to return
in a snippet. B<NOTE:> This is only used to test whether I<test> is worth
snipping at all, or if no terms are found.

See also show() and ignore_length().

Available via new().

=head2 word_len

The estimated average word length used in combination with context(). You can
usually ignore this value.

Available via new().

=head2 show

Boolean flag indicating whether snip() should succeed no matter what, or if it should
give up if no snippets were found. Default is 1 (true).

If no matches are found, the first I<max_chars> of the snippet are returned.

Available via new().

=head2 escape

Boolean flag indicating whether snip() should escape any HTML/XML markup in the resulting
snippet or not. Default is 0 (false).

Available via new().

=head2 strip_markup

Boolean flag indicating whether snip() should attempt to remove any
HTML/XML markup in the original text before snipping is applied. Default 
is 0 (false).

Available via new().

=head2 snipper

The CODE ref used by the snip() method for actually extracting snippets. You can
use your own snipper function if you want (though if you have a better snipper algorithm
than the ones in this module, why not share it?). If you go this route, have a look
at the source code for snip() to see how snipper() is used.

Available via new().

=head2 type

There are different algorithms used internally for snipping text.
They are, in order of speed:

=over

=item dumb

Just grabs the first B<max_chars> characters and returns it,
doing a little clean up to prevent partial words from ending the snippet
and (optionally) escaping the text.

=item loop

Fastest for single-word queries.

=item token

Most accurate, for both single-word and phrase queries, although it relies
on a HeatMap in order to locate phrases.

See also the B<use_pp> feature.

=item offset (default)

Same as C<re> but optimized slightly to look at a substr of text.

=item re

The regular expression algorithm. Will match phrases exactly.

=back

=cut

=head2 type_used

The name of the internal snipper function used. In case you're curious.

=head2 force

Boolean flag indicating whether the snipper() value should always be used,
regardless of the type of query keyword. Default is 0 (false).

Available via new().

=head2 count

The number of snips made by the Snipper object.

=head2 collapse_whitespace

Boolean flag indicating whether multiple whitespace characters
should be collapsed into a single space. A whitespace character
is defined as anything that Perl's C<\s> pattern matches, plus
the nobreak space (C<\xa0>). Default is 1 (true).

Available via new().

=head2 use_pp( I<n> )

Set to a true value to use Tokenizer->tokenize_pp() and TokenListPP
and TokenPP instead of the XS versions of the same. XS is the default
and is much faster, but harder to modify or subclass.

Available via new().

=head2 ignore_length

Boolean flag. If set to false (default) then C<max_chars> is respected.
If set to true, C<max_chars> is ignored.

Available via new().

=head2 treat_phrases_as_singles

Boolean flag. If set to true (default), individual terms within a phrase
are considered a match. If false, only match if individual terms
have a proximity distance of 1.

=head2 snip( I<text> )

Return a snippet of text from I<text> that matches
I<query> plus context() words of context. Matches are case insensitive.

The snippet returned will be in UTF-8 encoding, regardless of the encoding
of I<text>.

=head1 AUTHOR

Peter Karman C<< <karman at cpan dot org> >>

=head1 ACKNOWLEDGEMENTS

Based on the HTML::HiLiter regular expression building code, originally by the same author,
copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com>
for sponsoring the development of this module.

=head1 COPYRIGHT

Copyright 2006 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

SWISH::HiLiter

=cut
