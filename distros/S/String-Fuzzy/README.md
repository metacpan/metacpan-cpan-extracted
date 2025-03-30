# NAME

String::Fuzzy - Python-style fuzzy string matching (fuzzywuzzy port)

# SYNOPSIS

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

# VERSION

    v0.1.0

# DESCRIPTION

This module provides fuzzy string matching similar to Python's [fuzzywuzzy](https://github.com/seatgeek/fuzzywuzzy) [library](https://pypi.org/project/fuzzywuzzy/),
faithfully replicating its core functionality and behavior in a Perl context. It
supports multiple strategies for comparing strings with typos, extra words, or
inconsistent formatting. By default, strings are normalized (lowercased, diacritics
removed, punctuation stripped), but this can be disabled with the `normalize` option.

# FUNCTIONS

All functions accept an optional `normalize` parameter (default: 1) to toggle
string normalization.

## ratio($a, $b, %opts)

Computes Levenshtein similarity between two strings, returning a score from 0 to 100.
Returns a float for precision.

## partial\_ratio($a, $b, %opts)

Slides the shorter string over the longer one to find the best fixed-length match.

Returns 100 if the shorter string is fully contained in the longer one.

## fuzzy\_substring\_ratio($needle, $haystack, %opts)

Searches for the best fuzzy match of `$needle` in `$haystack` across variable-length
windows. Useful for OCR noise or embedded typos.

## token\_sort\_ratio($a, $b, %opts)

Ignores word order by sorting tokens before comparison.

## token\_set\_ratio($a, $b, %opts)

Focuses on common word tokens, ignoring duplicates and order.

## extract\_best($query, \\@choices, %opts)

Returns the best match as `[$string, $score, $index]`. Accepts `scorer` (default: `\&ratio`)
and `limit` (default: 1) for top-N results.

## extract\_all($query, \\@choices, %opts)

Returns all matches as `[[string, score], ...]`, sorted by score descending.

Accepts `scorer` (default: `\&ratio`).

# AUTHOR

Albert (ChatGPT) from OpenAI, with enhancements by Grok 3 from xAI.

Supported by Jacques Deguest <`jack@deguest.jp`>.

# SEE ALSO

[Text::Approx](https://metacpan.org/pod/Text%3A%3AApprox), [Text::Levenshtein::XS](https://metacpan.org/pod/Text%3A%3ALevenshtein%3A%3AXS), [Text::Fuzzy](https://metacpan.org/pod/Text%3A%3AFuzzy),
[String::Approx](https://metacpan.org/pod/String%3A%3AApprox), [Text::Levenshtein::Damerau](https://metacpan.org/pod/Text%3A%3ALevenshtein%3A%3ADamerau)

# LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
