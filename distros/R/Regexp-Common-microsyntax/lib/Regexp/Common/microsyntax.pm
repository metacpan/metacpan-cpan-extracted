package Regexp::Common::microsyntax;

use strict;
use warnings;
use utf8;
use Regexp::Common qw(pattern);

our $VERSION = '0.02';

# -------------------------------------------------------------------------
# Helper sets and regexes

my %REGEXEN = ();

my $AT_SIGNS = '@＠';
my $HASH_SIGNS = '#＃';
my $EXCLAMATION_SIGNS = '!';

my $UNICODE_SPACES = join '|', map { pack 'U*', $_ }
  0x0009 .. 0x000D, # White_Space # Cc   [5] <control-0009>..<control-000D>
  0x0020,           # White_Space # Zs       SPACE
  0x0085,           # White_Space # Cc       <control-0085>
  0x00A0,           # White_Space # Zs       NO-BREAK SPACE
  0x1680,           # White_Space # Zs       OGHAM SPACE MARK
  0x180E,           # White_Space # Zs       MONGOLIAN VOWEL SEPARATOR
  0x2000 .. 0x200A, # White_Space # Zs  [11] EN QUAD..HAIR SPACE
  0x2028,           # White_Space # Zl       LINE SEPARATOR
  0x2029,           # White_Space # Zp       PARAGRAPH SEPARATOR
  0x202F,           # White_Space # Zs       NARROW NO-BREAK SPACE
  0x205F,           # White_Space # Zs       MEDIUM MATHEMATICAL SPACE
  0x3000,           # White_Space # Zs       IDEOGRAPHIC SPACE
  ;
$REGEXEN{spaces} = qr/$UNICODE_SPACES/o;

# Latin accented characters
# Excludes 0xd7 from the range (the multiplication sign, confusable with "x").
# Also excludes 0xf7, the division sign
my $LATIN_ACCENTS = join '', map { pack 'U*', $_ }
  0xc0 .. 0xd6,
  0xd8 .. 0xf6,
  0xf8 .. 0xff,
  ;

my $NON_LATIN_HASHTAG_CHARS = join '', map { pack 'U*', $_ }
  # Cyrillic (Russian, Ukrainian, etc.)
  0x0400 .. 0x04ff,     # Cyrillic
  0x0500 .. 0x0527,     # Cyrillic Supplement
  # Hangul (Korean)
  0x1100 .. 0x11ff,     # Hangul Jamo
  0x3130 .. 0x3185,     # Hangul Compatibility Jamo
  0xA960 .. 0xA97F,     # Hangul Jamo Extended-A
  0xAC00 .. 0xD7AF,     # Hangul Syllables
  0xD7B0 .. 0xD7FF      # Hangul Jamo Extended-B
  ;

my $CJ_HASHTAG_CHARS = join '', map { pack 'U*', $_ }
  0x30A1 .. 0x30FA,     # Katakana (full-width)
  0xFF66 .. 0xFF9D,     # Katakana (half-width)
  0xFF10 .. 0xFF19,     # Latin (full-width)
  0xFF21 .. 0xFF3A,     # Latin (full-width)
  0xFF41 .. 0xFF5A,     # Latin (full-width)
  0x3041 .. 0x3096,     # Hiragana
  0x3400 .. 0x4DBF,     # Kanji (CJK Extension A)
  0x4E00 .. 0x9FFF,     # Kanji (Unified)
  0x20000 .. 0x2A6DF,   # Kanji (CJK Extension B)
  0x2A700 .. 0x2B73F,   # Kanji (CJK Extension C)
  0x2B740 .. 0x2B81F,   # Kanji (CJK Extension D)
  0x2F800 .. 0x2FA1F,   # Kanji (CJK supplement)
  ;

my $HASHTAG_BOUNDARY1    = qr/(?:\A|(?<=$REGEXEN{spaces}|「|」|。|\.|!))/;
my $HASHTAG_BOUNDARY2    = qr/(?:\z|$REGEXEN{spaces}|「|」|。|\.|!)/;
my $HASHTAG_ALPHA        = "[a-zA-Z_$LATIN_ACCENTS$NON_LATIN_HASHTAG_CHARS$CJ_HASHTAG_CHARS]";
my $HASHTAG_ALPHANUMERIC = "[a-zA-Z0-9_$LATIN_ACCENTS$NON_LATIN_HASHTAG_CHARS$CJ_HASHTAG_CHARS]";

my $SLASHTAGS = qr/(?:by|cc|for|tip|thx|hat tip|ht|via)/i;

# -------------------------------------------------------------------------
# Pattern definitions

# user
#           "(/[a-zA-Z][a-zA-Z0-9_-]{0,24})?)" .
pattern
  name   => [ qw(microsyntax user) ],
  create => # @user must be at beginning of string, or not after a word char
            "(?:^|(?<![a-zA-Z0-9_]))" .
            # open main capture
            "(" .
            # at sigil (keep)
            "(?k:[$AT_SIGNS])" .
            # username (keep)
            "(?k:[a-zA-Z0-9_]{1,20})" .
            # close main capture
            ")" .
            # @user must be at end of string, or not followed by a word char or at
            "(?=\$|[^a-zA-Z0-9_$AT_SIGNS$LATIN_ACCENTS])",
  ;

# hashtag
pattern
  name   => [ qw(microsyntax hashtag) ],
  create => # hashtag boundary condition
            $HASHTAG_BOUNDARY1 . 
            # open main capture
            "(" .
            # hash sigil (keep)
            "(?k:[$HASH_SIGNS])" .
            # hashtag (keep)
            "(?k:$HASHTAG_ALPHANUMERIC*$HASHTAG_ALPHA$HASHTAG_ALPHANUMERIC*)" .
            # close main capture
            ")" .
            # hashtag boundary condition (zero-width)
            "(?=$HASHTAG_BOUNDARY2)",
  ;

# grouptag
pattern
  name   => [ qw(microsyntax grouptag) ],
  create => # hashtag boundary condition
            $HASHTAG_BOUNDARY1 .
            # open main capture
            "(" .
            # exclamation sigil (keep)
            "(?k:[$EXCLAMATION_SIGNS])" .
            # grouptag (keep)
            # TODO: check what chars status.net allows in grouptags
            "(?k:$HASHTAG_ALPHANUMERIC*$HASHTAG_ALPHA$HASHTAG_ALPHANUMERIC*)" .
#           "(?k:[a-z0-9]+)" .
            # close main capture
            ")" .
            # hashtag boundary condition (zero-width)
            "(?=$HASHTAG_BOUNDARY2)",
  ;

# slashtag
pattern
  name   => [ qw(microsyntax slashtag) ],
  create => # slashtag must be at beginning of string, or not after a word char
#           "(?:^|(?<![a-zA-Z0-9_]))" .
            # open main capture
            "(" .
            # slashtag (keep)
            "(?k:/?$SLASHTAGS)$REGEXEN{spaces}" .
            # @user (keep)
            "(?k:[$AT_SIGNS][a-zA-Z0-9_]{1,20}" .
            "(?:$REGEXEN{spaces}+[$AT_SIGNS][a-zA-Z0-9_]{1,20})*)" .
            # close main capture
            ")" .
            # @user must be at end of string, or not followed by a word char or at
            "(?=\$|[^a-zA-Z0-9_$AT_SIGNS$LATIN_ACCENTS])",
  ;

1;

__END__

=head1 NAME

Regexp::Common::microsyntax - a collection of regular expressions for use with microblogging-style text (tweets, dents, microposts, etc.)

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    use Regexp::Common qw(microsyntax);

    # Available patterns: user, hashtag, grouptag, slashtag

    # Get all users/hashtags/groups/slashtags mentioned in $post
    @users     = $post =~ m/$RE{microsyntax}{user}/og;
    @hashtags  = $post =~ m/$RE{microsyntax}{hashtag}/og;
    @groups    = $post =~ m/$RE{microsyntax}{grouptag}/og;
    @slashtags = $post =~ m/$RE{microsyntax}{slashtag}/og;

    # Capture/extract individual elements (see Regexp::Common '-keep')
    my @usernames;
    while ($post =~ m/$RE{microsyntax}{user}{-keep => 1 }/go) {
      push @usernames, $3;
    }

    # Substitute/markup individual elements
    $post =~ s|$RE{microsyntax}{user}|<span class="user">$1</span>|go;


=head1 DESCRIPTION

Please consult the manual of Regexp::Common for a general description of
the works of this interface.

Do not use this module directly, but load it via Regexp::Common.

This module provides regular expressions for matching microblogging-style
text (tweets, dents, microposts, etc.). It is based on the ruby
B<twitter-text> Regex class, with extensions to support features that
Twitter doesn't support (like status.net !group tags, microsyntax.org
slashtags, etc.).

=head2 $RE{microsyntax}{user}

Returns a pattern that matches @username handles. For this pattern and
the next three, using '-keep' (see L<Regexp::Common>) allows access to
the following individual components:

=over 4

=item $1  captures the entire match

=item $2  captures the sigil used ('@' for usernames, '#' or '' for hashtags, etc.)

=item $3  captures the text after the sigil i.e. the bare username, hashtag, etc.

=back

=head2 $RE{microsyntax}{hashtag}

Returns a pattern that matches #hashtags, with support for unicode hashtags.
Note that all number hashtags are specifically excluded.

=head2 $RE{microsyntax}{grouptag}

Returns a pattern that matches identica/status.net !group tags.

=head2 $RE{microsyntax}{slashtag}

Returns a pattern that matches slashtags, as defined and documented at
http://microsyntax.org/. These normally occur at the end of a post, with
the first (but typically not the others) introduced by a slash e.g.

  Sample post /via @person1 by @person2 cc @person3 @person4

The following slashtags are recognised:

=over 4

=item by

=item cc, for, and tip

=item thx

=item hat tip, ht, and via

=back

For this pattern, using '-keep' allows access to the following individual
components:

=over 4

=item $1  captures the entire match

=item $2  captures the verbatim slashtag (e.g. '/via', 'cc', 'by')

=item $3  captures the (potentially multiple) @user handles with this slashtag

=back

=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-regexp-common-microsyntax at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-Common-microsyntax>.

=head1 ACKNOWLEDGEMENTS

The Ruby C<twitter-text-rb> library, L<http://github.com/mzsanford/twitter-text-rb/>.

=head1 SEE ALSO

L<Regexp::Common>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gavin Carr <gavin@openfusion.com.au>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
