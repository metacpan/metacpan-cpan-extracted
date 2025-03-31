##----------------------------------------------------------------------------
## String Fuzzy - ~/lib/String/Fuzzy.pm
## Version v0.1.1
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/03/29
## Modified 2025/03/31
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package String::Fuzzy;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Exporter );
    use vars qw( @EXPORT_OK $VERSION );
    require overload;
    use Encode qw( encode_utf8 decode_utf8 is_utf8 );
    use List::Util qw( min max );
    use Scalar::Util qw( looks_like_number );
    use Text::Levenshtein::XS qw( distance );
    use Unicode::Normalize qw( NFD );
    our @EXPORT_OK = qw(
        extract_best
        extract_all
        fuzzy_substring_ratio
        partial_ratio
        ratio
        token_set_ratio
        token_sort_ratio
    );
    our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub extract_all
{
    my( $query, $choices, %opts ) = @_;
    my $scorer = $opts{scorer} || \&ratio;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Handle undef query or choices
    return( [] ) if( !defined( $query ) || !defined( $choices ) || ref( $choices ) ne 'ARRAY' );

    return [
        sort { $b->[1] <=> $a->[1] }  # Sort by score descending
        map {
            my $score = $scorer->( $query, $_, normalize => $normalize );
            [$_, $score]
        } @$choices
    ];
}

sub extract_best
{
    my( $query, $choices, %opts ) = @_;
    my $scorer = $opts{scorer} || \&ratio;
    my $limit = $opts{limit} || 1;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Handle undef query or choices
    return( undef ) if( !defined( $query ) || !defined( $choices ) || ref( $choices ) ne 'ARRAY' );

    my @results = map {
        my $score = $scorer->( $query, $choices->[$_], normalize => $normalize );
        [$choices->[$_], $score, $_]  # Include index
    } 0 .. $#$choices;

    @results = sort { $b->[1] <=> $a->[1] } @results;

    return( $limit == 1 ? $results[0] : [@results[0 .. $limit - 1]] );
}

sub fuzzy_substring_ratio
{
    my( $needle, $haystack, %opts ) = @_;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Validate references, allow stringifiable objects
    if( ref( $needle ) && !overload::Method( $needle, '""' ) )
    {
        die( "Needle must be a scalar or stringifiable object, not a reference" );
    }
    elsif( ref( $haystack ) && !overload::Method( $haystack, '""' ) )
    {
        die( "Haystack must be a scalar or stringifiable object, not a reference" );
    }

    my $str_needle = $normalize ? _normalize( defined( $needle ) ? "$needle" : $needle ) : ( defined( $needle ) ? "$needle" : $needle );
    my $str_haystack = $normalize ? _normalize( defined( $haystack ) ? "$haystack" : $haystack ) : ( defined( $haystack ) ? "$haystack" : $haystack );

    my $nlen = length( $str_needle );
    my $hlen = length( $str_haystack );
    return(0) if( $nlen == 0 || $hlen == 0 );

    my $max_score = 0;

    for my $window ( $nlen - 2 .. $nlen + 2 )
    {
        next if( $window < 3 || $window > $hlen );
        for my $i ( 0 .. $hlen - $window )
        {
            my $chunk = substr( $str_haystack, $i, $window );
            my $score = ratio( $str_needle, $chunk, normalize => 0 );  # Already normalized if needed
            $max_score = $score if( $score > $max_score );
        }
    }

    return( $max_score );
}

sub partial_ratio
{
    my( $s1, $s2, %opts ) = @_;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Validate references, allow stringifiable objects
    if( ref( $s1 ) && !overload::Method( $s1, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The first string is invalid." );
    }
    elsif( ref( $s2 ) && !overload::Method( $s2, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The second string is invalid." );
    }

    my $str1 = $normalize ? _normalize( defined( $s1 ) ? "$s1" : $s1 ) : ( defined( $s1 ) ? "$s1" : $s1 );
    my $str2 = $normalize ? _normalize( defined( $s2 ) ? "$s2" : $s2 ) : ( defined( $s2 ) ? "$s2" : $s2 );

    ( $str1, $str2 ) = ( $str2, $str1 ) if( length( $str1 ) > length( $str2 ) );
    return(0) if( length( $str1 ) == 0 );

    my $max_score = 0;
    my $s1_len = length( $str1 );
    my $s2_len = length( $str2 );

    # Check for full containment first
    if( index( $str2, $str1 ) != -1 )
    {
        return(100);
    }

    # Slide window of s1's length over s2, ensuring typo tolerance
    for my $i ( 0 .. $s2_len - $s1_len )
    {
        my $substr = substr( $str2, $i, $s1_len );
        my $score = ratio( $str1, $substr, normalize => $normalize );  # Use caller's normalize setting
        $max_score = max( $max_score, $score );  # Explicitly use max()
    }

    return( $max_score );
}

sub ratio
{
    my( $s1, $s2, %opts ) = @_;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Validate references, allow stringifiable objects
    if( ref( $s1 ) && !overload::Method( $s1, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The first string is invalid." );
    }
    elsif( ref( $s2 ) && !overload::Method( $s2, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The second string is invalid." );
    }

    my $str1 = $normalize ? _normalize( defined( $s1 ) ? "$s1" : $s1 ) : ( defined( $s1 ) ? "$s1" : $s1 );
    my $str2 = $normalize ? _normalize( defined( $s2 ) ? "$s2" : $s2 ) : ( defined( $s2 ) ? "$s2" : $s2 );

    return(100) if( $str1 eq $str2 );
    return(0) if( !length( $str1 // '' ) || !length( $str2 // '' ) );

    my $distance = distance( $str1, $str2 );
    my $length = $normalize
        ? max( length( $str1 ), length( $str2 ) )
        : max( length( is_utf8( $str1 ) ? encode_utf8( $str1 ) : $str1 ), length( is_utf8( $str2 ) ? encode_utf8( $str2 ) : $str2 ) );

    return( ( 1 - $distance / $length ) * 100 );  # Keep as float
}

sub token_set_ratio
{
    my( $s1, $s2, %opts ) = @_;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Validate references, allow stringifiable objects
    if( ref( $s1 ) && !overload::Method( $s1, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The first string is invalid." );
    }
    elsif( ref( $s2 ) && !overload::Method( $s2, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The second string is invalid." );
    }

    my $str1 = $normalize ? _normalize( defined( $s1 ) ? "$s1" : $s1 ) : ( defined( $s1 ) ? "$s1" : $s1 );
    my $str2 = $normalize ? _normalize( defined( $s2 ) ? "$s2" : $s2 ) : ( defined( $s2 ) ? "$s2" : $s2 );

    my @tokens1 = split( /\s+/, $str1 );
    my @tokens2 = split( /\s+/, $str2 );

    my %count;
    $count{ $_ }++ for( @tokens1, @tokens2 );
    my @intersection = grep { $count{$_} > 1 } keys( %count );
    my @left  = grep { !$count{ $_ } || $count{ $_ } == 1 } @tokens1;
    my @right = grep { !$count{ $_ } || $count{ $_ } == 1 } @tokens2;

    my $sorted_common  = join( ' ', sort( @intersection ) );
    my $combined_left  = join( ' ', sort( @intersection, @left ) );
    my $combined_right = join( ' ', sort( @intersection, @right ) );

    return max(
        ratio( $sorted_common, $combined_left, normalize => 0 ),
        ratio( $sorted_common, $combined_right, normalize => 0 ),
        ratio( $combined_left, $combined_right, normalize => 0 )
    );
}

sub token_sort_ratio
{
    my( $s1, $s2, %opts ) = @_;
    my $normalize = exists( $opts{normalize} ) ? $opts{normalize} : 1;

    # Validate references, allow stringifiable objects
    if( ref( $s1 ) && !overload::Method( $s1, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The first string is invalid." );
    }
    elsif( ref( $s2 ) && !overload::Method( $s2, '""' ) )
    {
        die( "Both input strings must be scalars or stringifiable objects, not references. The second string is invalid." );
    }

    my $str1 = $normalize ? _normalize( defined( $s1 ) ? "$s1" : $s1 ) : ( defined( $s1 ) ? "$s1" : $s1 );
    my $str2 = $normalize ? _normalize( defined( $s2 ) ? "$s2" : $s2 ) : ( defined( $s2 ) ? "$s2" : $s2 );

    my $sorted1 = join( ' ', sort( split( /\s+/, $str1 ) ) );
    my $sorted2 = join( ' ', sort( split( /\s+/, $str2 ) ) );
    return( ratio( $sorted1, $sorted2, normalize => 0 ) );
}

sub _normalize
{
    my( $str ) = @_;
    return( '' ) unless( defined( $str ) );
    $str = lc( $str );
    $str = NFD( $str );
    $str =~ s/\pM+//g;              # Remove diacritics
    $str =~ s/[^\p{L}\p{Nd}\s]//g;  # Remove punctuation/symbols
    $str =~ s/\s+/ /g;              # Normalize whitespace
    $str =~ s/^\s+|\s+$//g;         # Trim
    return( $str );
}

1;
# NOTE: POD
__END__

=pod

=head1 NAME

String::Fuzzy - Python-style fuzzy string matching (fuzzywuzzy port)

=head1 SYNOPSIS

    use String::Fuzzy qw( fuzzy_substring_ratio extract_best ratio );

    # Basic ratio with normalization (default)
    my $score = ratio( "Hello", "hello" );  # 100 (normalized)

    # Disable normalization for case-sensitive matching
    my $raw_score = ratio( "Hello", "hello", normalize => 0 );  # ~80

    # Find best match with index
    my $best = extract_best( "cat", [ "cat", "category", "dog" ], scorer => \&partial_ratio );
    print "Best: $best->[0], Score: $best->[1], Index: $best->[2]\n";

    # Get all matches sorted by score
    my $all = extract_all( "cat", [ "cat", "category", "dog" ] );
    for ( @$all ) { print "Match: $_->[0], Score: $_->[1]\n"; }

    # Practical example: Find the best vendor match with a typo
    my @vendors = qw( SendGrid Mailgun SparkPost Postmark );
    my $input = "SpakPost Invoice";
    my $best_score = 0;
    my $best_vendor;
    for my $vendor ( @vendors ) {
        my $score = fuzzy_substring_ratio( $vendor, $input );
        if( $score > $best_score ) {
            $best_score = $score;
            $best_vendor = $vendor;
        }
    }
    if( $best_score >= 85 ) {
        print "Matched '$best_vendor' with score $best_score\n";  # SparkPost, 88.89
    }

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This module provides fuzzy string matching similar to Python's L<fuzzywuzzy|https://github.com/seatgeek/fuzzywuzzy> L<library|https://pypi.org/project/fuzzywuzzy/>,
faithfully replicating its core functionality and behavior in a Perl context. It
supports multiple strategies for comparing strings with typos, extra words, or
inconsistent formatting. By default, strings are normalized (lowercased, diacritics
removed, punctuation stripped), but this can be disabled with the C<normalize> option.

=head1 FUNCTIONS

All functions accept an optional C<normalize> parameter (default: 1) to toggle
string normalization.

=head2 ratio($a, $b, %opts)

Computes Levenshtein similarity between two strings, returning a score from 0 to 100.
Returns a float for precision.

=head2 partial_ratio($a, $b, %opts)

Slides the shorter string over the longer one to find the best fixed-length match.

Returns 100 if the shorter string is fully contained in the longer one.

=head2 fuzzy_substring_ratio($needle, $haystack, %opts)

Searches for the best fuzzy match of C<$needle> in C<$haystack> across variable-length
windows. Useful for OCR noise or embedded typos.

=head2 token_sort_ratio($a, $b, %opts)

Ignores word order by sorting tokens before comparison.

=head2 token_set_ratio($a, $b, %opts)

Focuses on common word tokens, ignoring duplicates and order.

=head2 extract_best($query, \@choices, %opts)

Returns the best match as C<[$string, $score, $index]>. Accepts C<scorer> (default: C<\&ratio>)
and C<limit> (default: 1) for top-N results.

=head2 extract_all($query, \@choices, %opts)

Returns all matches as C<[[string, score], ...]>, sorted by score descending.

Accepts C<scorer> (default: C<\&ratio>).

=head1 AUTHOR

Albert (ChatGPT) from OpenAI, with enhancements by Grok 3 from xAI.

Supported by Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>.

=head1 SEE ALSO

L<Text::Approx>, L<Text::Levenshtein::XS>, L<Text::Fuzzy>,
L<String::Approx>, L<Text::Levenshtein::Damerau>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
