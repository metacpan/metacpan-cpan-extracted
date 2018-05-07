package Search::Tools::TokenListUtils;
use Moo::Role;
use Carp;

our $VERSION = '1.007';

=head1 NAME

Search::Tools::TokenListUtils - mixin methods for TokenList and TokenListPP

=head1 SYNOPSIS

 my $tokens = $tokenizer->tokenize( $string );
 if ( $tokens->str eq $string) {
    print "string is same, before and after tokenize()\n";
 }
 else {
    warn "I'm filing a bug report against Search::Tools right away!\n";
 }
 
 my ($start_pos, $end_pos) = $tokens->get_window( 5, 20 );
 # $start_pos probably == 0
 # $end_pos probably   == 25
 
 my $slice = $tokens->get_window_pos( 5, 20 );
 for my $token (@$slice) {
    print "token = $token\n";
 }

=head1 DESCRIPTION

Search::Tools::TokenListUtils contains pure-Perl methods inhertited
by both Search::Tools::TokenList and Search::Tools::TokenListPP.

=head1 METHODS

=head2 str

Returns a serialized version of the TokenList. If you haven't
altered the TokenList since you got it from tokenize(),
then str() returns a scalar string identical to (but not the same as)
the string you passed to tokenize().

Both Search::Tools::TokenList and TokenListPP are overloaded
to stringify to the str() value.

=cut

sub str {
    my $self   = shift;
    my $joiner = shift(@_);
    if ( !defined $joiner ) {
        $joiner = '';
    }
    return join( $joiner, map {"$_"} @{ $self->as_array } );
}

=head2 get_window( I<pos> [, I<size>, I<as_sentence>] )

Returns array with two values: I<start> and I<end> positions
for the array of length I<size> on either side of I<pos>. 
Like taking a slice of the TokenList.

Note that I<size> is the number of B<tokens> not B<matches>.
So if you're looking for the number of "words", think about
I<size>*2.

Note too that I<size> is the number of B<tokens> on B<one>
side of I<pos>. So the entire window width (length of the returned
slice) is I<size>*2 +/-1. The window is guaranteed to be bounded
by B<matches>.

If I<as_sentence> is true, the window is shifted to try and match
the first token prior to I<pos> that returns true for is_sentence_start().

=cut

sub get_window {
    my $self = shift;
    my $pos  = shift;
    if ( !defined $pos ) {
        croak "pos required";
    }

    my $size        = int(shift) || 20;
    my $as_sentence = shift      || 0;
    my $max_index   = $self->len - 1;

    if ( $pos > $max_index or $pos < 0 ) {
        croak "illegal pos value: no such index in TokenList";
    }

    #warn "window size $size for pos $pos";

    # get the $size tokens on either side of $tok
    my ( $start, $end );

    # is token too close to the top of the stack?
    if ( $pos > $size ) {
        $start = $pos - $size;
    }

    # is token too close to the bottom of the stack?
    if ( $pos < ( $max_index - $size ) ) {
        $end = $pos + $size;
    }
    $start ||= 0;
    $end   ||= $max_index;

    if ($as_sentence) {
        my $sentence_starts = $self->get_sentence_starts;

        # default to what we have.
        my $start_for_pos = $start;
        my $i             = 0;

        #warn "looking for sentence_start for start = $start end = $end\n";
        for (@$sentence_starts) {

            #warn " $_ [$i]\n";
            if ( $_ >= $pos ) {
                $start_for_pos = $sentence_starts->[$i];
                last;
            }
            $i++;
        }

        #warn "found $start_for_pos (start = $start end = $end)\n";
        if ( $start_for_pos != $start ) {
            if ( $start_for_pos < $start ) {
                $end -= ( $start - $start_for_pos );
            }
            else {
                $end += ( $start_for_pos - $start );
            }
            $start = $start_for_pos;
        }

        #warn "now $start_for_pos (start = $start end = $end)\n";
    }
    else {

        # make sure window starts and ends with is_match
        while ( !$self->get_token($start)->is_match ) {
            $start++;
        }
        while ( !$self->get_token($end)->is_match ) {
            $end--;
        }
    }

    #warn "return $start .. $end";
    #warn "$size ~~ " . ( $end - $start );

    return ( $start, $end );
}

=head2 get_window_tokens( I<pos> [, I<size>] )

Like get_window() but returns an array ref of a slice
of the TokenList containing Tokens.

=cut

sub get_window_tokens {
    my $self = shift;
    my ( $start, $end ) = $self->get_window(@_);
    my @slice = ();
    for ( $start .. $end ) {
        push( @slice, $self->get_token($_) );
    }
    return \@slice;
}

=head2 as_sentences([I<stringified>])

Returns a reference to an array of arrays,
where each child array is a "sentence" worth of Token objects.
You can stringify each sentence array like:

 my $sentences = $tokenlist->as_sentences;
 for my $s (@$sentences) {
     printf("sentence: %s\n", join("", map {"$_"} @$s));
 }

If you pass a single true value to as_sentences(),
then the array returned will consist of plain scalar strings
with whitespace normalized.

=cut

sub as_sentences {
    my $self = shift;
    my $stringed = shift || 0;
    my @sents;
    my @s;

    # use array method since we do not know the iterator position
    for my $t ( @{ $self->as_array } ) {
        if ( $t->is_sentence_start ) {

            # if has any, add anonymous copy to master
            if (@s) {
                push @sents, [@s];
            }

            # reset
            @s = ();
        }

        # add
        push @s, $t;
    }
    if (@s) {
        push @sents, [@s];
    }
    if ($stringed) {
        my @stringed;
        for my $s (@sents) {
            my $str = join( "", map {"$_"} @$s );
            $str =~ s/\s\s+/\ /g;
            $str =~ s/\s+$//;
            push @stringed, $str;
        }
        return \@stringed;
    }

    return \@sents;
}

1;

__END__

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

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
