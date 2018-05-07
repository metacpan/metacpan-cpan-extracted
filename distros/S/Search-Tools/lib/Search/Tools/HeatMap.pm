package Search::Tools::HeatMap;
use Moo;
use Carp;
use Data::Dump qw( dump );
extends 'Search::Tools::Object';

use namespace::autoclean;

our $VERSION = '1.007';

# debugging only
my $OPEN  = '[';
my $CLOSE = ']';
eval { require Term::ANSIColor; };
if ( !$@ ) {
    $OPEN .= Term::ANSIColor::color('bold red');
    $CLOSE = Term::ANSIColor::color('reset') . $CLOSE;
}

my @attrs = qw( window_size
    tokens
    spans
    as_sentences
    _treat_phrases_as_singles
    _qre
    _query
    _stemmer
);

for my $attr (@attrs) {
    has $attr => ( is => 'rw' );
}

=head1 NAME

Search::Tools::HeatMap - locate the best matches in a snippet extract

=head1 SYNOPSIS

 use Search::Tools::Tokenizer;
 use Search::Tools::HeatMap;
     
 my $tokens = $self->tokenizer->tokenize( $my_string, qr/^(interesting)$/ );
 my $heatmap = Search::Tools::HeatMap->new(
     tokens         => $tokens,
     window_size    => 20,  # default
     as_sentences   => 0,   # default
 );

 if ( $heatmap->has_spans ) {
 
     my $tokens_arr = $tokens->as_array;

     # stringify positions
     my @snips;
     for my $span ( @{ $heatmap->spans } ) {
         push( @snips, $span->{str} );
     }
     my $occur_index = $self->occur - 1;
     if ( $#snips > $occur_index ) {
         @snips = @snips[ 0 .. $occur_index ];
     }
     printf("%s\n", join( ' ... ', @snips ));
     
 }

=head1 DESCRIPTION

Search::Tools::HeatMap implements a simple algorithm for locating
the densest clusters of unique, hot terms in a TokenList.

HeatMap is used internally by Snipper but documented here in case
someone wants to abuse and/or improve it.

=head1 METHODS

=head2 new( tokens => I<TokenList> )

Create a new HeatMap. The I<TokenList> object may be either a
Search::Tools::TokenList or Search::Tools::TokenListPP object.

=head2 BUILD

Builds the HeatMap object. Called internally by new().

=cut

sub BUILD {
    my $self = shift;
    $self->_build;
    return $self;
}

=head2 window_size

The max width of a span. Defaults to 20 tokens, including the
matches.

Set this in new(). Access it later if you need to, but the spans
will have already been created by new().

=head2 as_sentences

Try to match clusters at sentence boundaries. Default is false.

Set this in new().

=head2 spans

Returns an array ref of matching clusters. Each span in the array
is a hash ref with the following keys:

=over

=item cluster

=item pos

=item heat

=item str

=item str_w_pos

This item is available only if debug() is true.

=item unique

=back

=cut

# TODO this is mostly integer math and might be much
# faster if rewritten in XS once the algorithm is "final".
sub _build {
    my $self         = shift;
    my $tokens       = $self->tokens or croak "tokens required";
    my $window       = $self->window_size || 20;
    my $as_sentences = $self->as_sentences || 0;
    return $as_sentences
        ? $self->_as_sentences( $tokens, $window )
        : $self->_no_sentences( $tokens, $window );
}

# currently _as_sentences() is mostly identical to _no_sentences()
# with slightly fewer gymnastics.
# Since we already know via sentence_starts where our boundaries are,
# we do not have to call $tokens->get_window().
# Who knows how we might improve the sentence algorithm in future,
# so already having it in its own method seems like a win.
sub _as_sentences {
    my ( $self, $tokens, $window ) = @_;
    my $debug = $self->debug || 0;
    my $sentence_length = $window * 2;

    # build heatmap with sentence starts
    my $num_tokens           = $tokens->len;
    my $tokens_arr           = $tokens->as_array;
    my %heatmap              = ();
    my $token_list_heat      = $tokens->get_heat;
    my $heat_sentence_starts = $tokens->get_sentence_starts;

    # this regex is a sanity check for phrases. we replace the \ with a
    # more promiscuous check because the single space is too naive
    # for real text (e.g. st. john's)
    my $qre              = $self->{_qre};
    my @phrases          = @{ $self->{_query}->phrases };
    my $n_terms          = $self->{_query}->num_terms;
    my $query_has_phrase = $qre =~ s/(\\ )+/.+/g;

    if ($debug) {
        warn "heat_sentence_starts: " . dump($heat_sentence_starts);
        warn "token_list_heat: " . dump($token_list_heat);
        warn "n_terms: $n_terms";
        warn "phrases: " . dump( \@phrases );
        warn "query_has_phrase: $query_has_phrase";
    }

    # find the "sentence" that each hot token appears in.
    my @starts_ends;
    my $i                  = 0;
    my %heat_sentence_ends = ();    # cache
    for (@$token_list_heat) {
        my $token     = $tokens->get_token($_);
        my $token_pos = $token->pos;
        my $start     = $heat_sentence_starts->[ $i++ ];
        $heatmap{$token_pos} = $token->is_hot;

        # a little optimization for when we've got
        # multiple hot tokens in the same sentence
        if ( exists $heat_sentence_ends{$start} ) {
            $debug
                and warn "found cached end $heat_sentence_ends{$start} "
                . "for start $start token $token_pos\n";

            push( @starts_ends,
                [ $start, $token_pos, $heat_sentence_ends{$start} ] );
            next;
        }

        # find the outermost limit of where this sentence might end
        my $max_end;

        # is there a "next" start?
        if ( defined $heat_sentence_starts->[$i]
            and $heat_sentence_starts->[$i] != $start )
        {

            # this token is unique in this non-final sentence
            $max_end = $heat_sentence_starts->[$i] - 1;
        }
        else {

            # this is the final sentence
            $max_end = $num_tokens - 1;
        }
        my $end = $start;

        # find the nearest sentence end to the start
        while ( $end < $max_end ) {
            my $tok = $tokens->get_token( $end++ );
            if ( !$tok ) {
                $debug and warn "No token at end=$end";
                last;
            }
            if ( $tok->is_sentence_end ) {
                $end--;    # move back one position
                if ($debug) {
                    warn "tok $_ is_sentence_end end=$end";
                    $tok->dump;
                }
                last;
            }
        }

        # back up if we've exceeded the 0-based tokens array.
        $end = $num_tokens if $end > $num_tokens;

        $debug
            and warn "start=$start max_end=$max_end "
            . "sentence_length=$sentence_length end=$end "
            . "token_pos=$token_pos\n";

        # if we didn't yet set the actual hot token,
        # include everything up to it.
        if ( $end < $token_pos ) {
            $debug
                and warn "resetting end=$token_pos\n";

            $end = $token_pos;
        }
        push( @starts_ends, [ $start, $token_pos, $end ] );

        # cache
        $heat_sentence_ends{$start} = $end;
    }

    $debug and warn "starts_ends: " . dump( \@starts_ends );

    my @spans;
    my %seen_pos;
START_END:
    for my $start_end (@starts_ends) {

        # get full window, ignoring positions we've already seen.
        my $heat = 0;
        my %span;
        my @cluster_tokens;

        my ( $start, $hot_pos, $end ) = @$start_end;
    POS: for my $pos ( $start .. $end ) {
            next POS if $seen_pos{$pos}++;
            $heat += ( exists $heatmap{$pos} ? $heatmap{$pos} : 0 );
            push( @cluster_tokens, $tokens->get_token($pos) );
        }

        # if we had already seen_pos all positions.
        next START_END unless @cluster_tokens;

        # sanity: make sure we still have something hot
        my $has_hot = 0;
        my @cluster_pos;
        my @strings;
    TOK: for (@cluster_tokens) {
            my $pos = $_->pos;
            $has_hot++ if exists $heatmap{$pos};
            push @strings,     $_->str;
            push @cluster_pos, $pos;
        }
        next START_END unless $has_hot;

        # the final string is a sentence end,
        # but we only want the first char in it,
        # and not any whitespace, stray punctuation or other
        # non-word noise.
        $strings[$#strings] =~ s/^([\.\?\!]).*/$1/;

        $span{start_end} = $start_end;
        $span{heat}      = $heat;
        $span{pos}       = \@cluster_pos;
        $span{tokens}    = \@cluster_tokens;
        $span{str}       = join( '', @strings );

        # spans with more *unique* hot tokens in a single span rank higher
        # spans with more *proximate* hot tokens in a single span rank higher
        my %uniq          = ();
        my $i             = 0;
        my $num_proximate = 1;    # one for the single hot token
        for (@cluster_pos) {
            if ( exists $heatmap{$_} ) {
                $uniq{ lc $strings[$i] } += $heatmap{$_};
                if ( $i && exists $heatmap{ $cluster_pos[ $i - 2 ] } ) {
                    $num_proximate++;
                }
            }
            $i++;
        }
        $span{unique}    = scalar keys %uniq;
        $span{proximate} = $num_proximate;

        # no false phrase matches if !_treat_phrases_as_singles
        # stemmer check because regex will likely fail
        # when stemmer is on
        if ( $query_has_phrase
            and !$self->{_treat_phrases_as_singles} )
        {
            if ( !$self->{_stemmer} ) {

                #warn "_treat_phrases_as_singles NOT true";
                if ( $span{str} !~ m/$qre/ ) {
                    $debug
                        and warn
                        "treat_phrases_as_singles=FALSE and '$span{str}' failed to match $qre\n";
                    next START_END;
                }
            }
            else {

                # if stemmer was on, we cannot rely on the regex,
                # but we assume that number of uniq terms must match query

                if (   $n_terms == $query_has_phrase
                    && $n_terms > $span{unique} )
                {

                    $debug
                        and warn
                        "treat_phrases_as_singles=FALSE and '$span{str}' "
                        . "expected $n_terms unique terms, got $span{unique}\n";
                    next START_END;
                }

            }
        }

        # just for debug
        if ($debug) {
            my $i = 0;
            $span{str_w_pos} = join(
                '',
                map {
                          $strings[ $i++ ]
                        . ( exists $heatmap{$_} ? $OPEN : '[' )
                        . $_
                        . ( exists $heatmap{$_} ? $CLOSE : ']' )
                } @cluster_pos
            );
        }

        push @spans, \%span;

    }

    $self->{spans}   = $self->_sort_spans( \@spans );
    $self->{heatmap} = \%heatmap;

    return $self;
}

sub _sort_spans {
    return [

        # sort by unique,
        # then by proximity
        # then by heat
        # then by pos

        sort {
                   $b->{unique} <=> $a->{unique}
                || $b->{proximate} <=> $a->{proximate}
                || $b->{heat} <=> $a->{heat}
                || $a->{pos}->[0] <=> $b->{pos}->[0]
            } @{ $_[1] }

    ];
}

sub _no_sentences {
    my ( $self, $tokens, $window ) = @_;
    my $lhs_window = int( $window / 2 );
    my $debug = $self->debug || 0;

    my $num_tokens      = $tokens->len;
    my $tokens_arr      = $tokens->as_array;
    my %heatmap         = ();
    my $token_list_heat = $tokens->get_heat;

    # this regex is a sanity check for phrases. we replace the \ with a
    # more promiscuous check because the single space is too naive
    # for real text (e.g. st. john's)
    my $qre              = $self->{_qre};
    my @phrases          = @{ $self->{_query}->phrases };
    my $n_terms          = $self->{_query}->num_terms;
    my $query_has_phrase = $qre =~ s/(\\ )+/.+/g;

    if ($debug) {
        warn "token_list_heat: " . dump($token_list_heat);
        warn "n_terms: $n_terms";
        warn "phrases: " . dump( \@phrases );
        warn "query_has_phrase: $query_has_phrase";
    }

    # build heatmap
    for (@$token_list_heat) {
        my $token = $tokens->get_token($_);
        $heatmap{ $token->pos } = $token->is_hot;
    }

    # make clusters

    # $proximity == (1/4 of $window)+1 is somewhat arbitrary,
    # but since we want to err in having too much context,
    # we aim high. Worst case scenario is where there are
    # multiple hot spots in a cluster and each is a full
    # $proximity length apart, which will grow the
    # eventual span far beyond $window size. We rely
    # on max_chars in Snipper to catch that worst case.
    my $proximity = int( $lhs_window / 2 ) + 1;
    my @positions = sort { $a <=> $b } keys %heatmap;
    my @clusters  = ( [] );
    my $i         = 0;
    for my $pos (@positions) {

        # if we have advanced past the first position
        # and the previous position is not "close" to this one,
        # start a new cluster
        if ( $i && ( $pos - $positions[ $i - 1 ] ) > $proximity ) {
            push( @clusters, [$pos] );
        }
        else {
            push( @{ $clusters[-1] }, $pos );
        }
        $i++;
    }

    $debug
        and warn "proximity: $proximity   clusters: " . dump \@clusters;

    # create spans from each cluster, each with a weight.
    # we do the initial sort so that clusters that overlap
    # other clusters via get_window() are weeded out via %seen_pos.
    my @spans;
    my %seen_pos;
CLUSTER:
    for my $cluster (
        sort {
                   scalar(@$b) <=> scalar(@$a)
                || $heatmap{ $b->[0] } <=> $heatmap{ $a->[0] }
                || $a->[0] <=> $b->[0]
        } @clusters
        )
    {

        # get full window, ignoring positions we've already seen.
        my $heat = 0;
        my %span;
        my @cluster_tokens;
    POS: for my $pos (@$cluster) {
            my ( $start, $end ) = $tokens->get_window( $pos, $window );
        POS_TWO: for my $pos2 ( $start .. $end ) {
                next if $seen_pos{$pos2}++;
                $heat += ( exists $heatmap{$pos2} ? $heatmap{$pos2} : 0 );
                push( @cluster_tokens, $tokens->get_token($pos2) );
            }
        }

        # we may have skipped a $seen_pos from the $slice above
        # so make sure we still start/end on a match
        while ( @cluster_tokens && !$cluster_tokens[0]->is_match ) {
            shift @cluster_tokens;
        }
        while ( @cluster_tokens && !$cluster_tokens[-1]->is_match ) {
            pop @cluster_tokens;
        }

        next CLUSTER unless @cluster_tokens;

        # sanity: make sure we still have something hot
        my $has_hot = 0;
        my @cluster_pos;
        my @strings;
        for (@cluster_tokens) {
            my $pos = $_->pos;
            $has_hot++ if exists $heatmap{$pos};
            push @strings,     $_->str;
            push @cluster_pos, $pos;
        }
        next CLUSTER unless $has_hot;

        $span{cluster} = $cluster;
        $span{heat}    = $heat;
        $span{pos}     = \@cluster_pos;
        $span{tokens}  = \@cluster_tokens;
        $span{str}     = join( '', @strings );

        # spans with more *unique* hot tokens in a single span rank higher
        # spans with more *proximate* hot tokens in a single span rank higher
        my %uniq          = ();
        my $i             = 0;
        my $num_proximate = 1;    # one for the single hot token
        for (@cluster_pos) {
            if ( exists $heatmap{$_} ) {
                $uniq{ lc $strings[$i] } += $heatmap{$_};
                if ( $i && exists $heatmap{ $cluster_pos[ $i - 2 ] } ) {
                    $num_proximate++;
                }
            }
            $i++;
        }
        $span{unique}    = scalar keys %uniq;
        $span{proximate} = $num_proximate;

        # no false phrase matches if !_treat_phrases_as_singles
        # stemmer check because regex will likely fail when stemmer is on
        if ( $query_has_phrase
            and !$self->{_treat_phrases_as_singles} )
        {
            if ( !$self->{_stemmer} ) {

                #warn "_treat_phrases_as_singles NOT true";
                if ( $span{str} !~ m/$qre/ ) {
                    $debug
                        and warn
                        "treat_phrases_as_singles=FALSE and '$span{str}' failed to match $qre\n";
                    next CLUSTER;
                }
            }
            else {

                # stemmer used, so check unique term count against n_terms
                if (   $n_terms == $query_has_phrase
                    && $n_terms > $span{unique} )
                {
                    $debug
                        and warn
                        "treat_phrases_as_singles=FALSE and '$span{str}' "
                        . "expected $n_terms but got $span{unique}\n";
                    next CLUSTER;
                }

            }
        }

        # just for debug
        if ($debug) {
            my $i = 0;
            $span{str_w_pos} = join(
                '',
                map {
                          $strings[ $i++ ]
                        . ( exists $heatmap{$_} ? $OPEN : '[' )
                        . $_
                        . ( exists $heatmap{$_} ? $CLOSE : ']' )
                } @cluster_pos
            );
        }

        push @spans, \%span;

    }

    $self->{spans}   = $self->_sort_spans( \@spans );
    $self->{heatmap} = \%heatmap;

    return $self;
}

=head2 has_spans

Returns the number of spans found.

=cut

sub has_spans {
    return scalar @{ $_[0]->{spans} };
}

1;

__END__

=head1 AUTHOR

Peter Karman C<< <karman at cpan dot org> >>

=head1 ACKNOWLEDGEMENTS

The idea of the HeatMap comes from KinoSearch, though the implementation
here is original.

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

KinoSearch
