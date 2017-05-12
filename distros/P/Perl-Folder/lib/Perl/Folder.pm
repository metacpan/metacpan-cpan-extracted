## Fold and Unfold Blocks in Perl Code
#
# Using regexps to look for values in Perl code is problematic. This module
# makes it much more reliable.
#
# Say you are looking for a line like this one:
#
#     our $VERSION = '0.10';
#
# Matching that line is easy. But that line might be in a heredoc, the `DATA`
# section, a POD block or a comment. Also if you try to strip out all heredocs
# you don't know if they are really part of a POD block of `DATA` section, and
# vice versa.
#
# This module correctly finds these four types of blocks and folds them up,
# replacing their content with the SHA1 digest of their content.
#
# Copyright (c) 2007. Ingy döt Net. All rights reserved.
#
# Licensed under the same terms as Perl itself.

package Perl::Folder;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.10';

## Synopsis:
#   use Perl::Folder;
#   my $folded = Perl::Folder->fold_blocks($perl);
#   my $unfolded = Perl::Folder->unfold_blocks($folded);

# A map of digests to code blocks
my $digest_map = {};

# Regexp fragments for matching heredoc, pod section, comment block and
# data section.
my $re_here = qr/
(?:                     # Heredoc starting line
    ^                   # Start of some line
    ((?-s:.*?))         # $2 - text before heredoc marker
    <<(?!=)             # heredoc marker
    [\t\x20]*           # whitespace between marker and quote
    ((?>['"]?))         # $3 - possible left quote
    ([\w\-\.]*)         # $4 - heredoc terminator
    (\3                 # $5 - possible right quote
     (?-s:.*\n))        #      and rest of the line
    (.*?\n)             # $6 - Heredoc content
    (?<!\n[0-9a-fA-F]{40}\n)  # Not another digest
    (\4\n)              # $7 - Heredoc terminating line
)
/xsm;

my $re_pod = qr/
(?:
    (?-s:^=(?!cut\b)\w+.*\n)        # Pod starter line
    .*?                             # Pod lines
    (?:(?-s:^=cut\b.*\n)|\z)        # Pod terminator
)
/xsm;

my $re_comment = qr/
(?:
    (?m-s:^[^\S\n]*\#.*\n)+           # one or more comment lines
)
/xsm;

my $re_data = qr/
(?:
    ^(?:__END__|__DATA__)\n   # DATA starter line
    .*                              # Rest of lines
)
/xsm;

# Fold each heredoc, pod section, comment block and data section, each
# into a single line containing a digest of the original content.
#
# This makes further dividing of Perl code less troublesome.
sub fold_blocks {
    my ($class, $source) = @_;

    $$source =~ s/(~{3,})/$1~/g;
    $$source =~ s/(^'{3,})/$1'/gm;
    $$source =~ s/(^`{3,})/$1`/gm;
    $$source =~ s/(^={3,})/$1=/gm;

    while (1) {
        no warnings;
        $$source =~ s/
            (
                $re_pod |
                $re_comment |
                $re_here |
                $re_data
            )
        /
            my $result = $1;
            $result =~ m{\A($re_data)}    ? $class->fold_data()    :
            $result =~ m{\A($re_pod)}     ? $class->fold_pod()     :
            $result =~ m{\A($re_comment)} ? $class->fold_comment() :
            $result =~ m{\A($re_here)}    ? $class->fold_here()    :
                die "'$result' didn't match '$re_comment'";
        /ex or last;
    }

    $$source =~ s/(?<!~)~~~(?!~)/<</g;
    $$source =~ s/^'''(?!') /__DATA__\n/gm;
    $$source =~ s/^```(?!`)/#/gm;
    $$source =~ s/^===(?!=)/=/gm;

    $$source =~ s/^(={3,})=/$1/gm;
    $$source =~ s/^('{3,})'/$1/gm;
    $$source =~ s/^(`{3,})`/$1/gm;
    $$source =~ s/(~{3,})~/$1/g;

    return $source;
}

sub unfold_blocks {
    my ($class, $source) = @_;

    $$source =~ s/
        (
            ^__DATA__\n[0-9a-fA-F]{40}\n
        |
            ^=pod\s[0-9a-fA-F]{40}\n=cut\n
        |
            ^\#\s[0-9a-fA-F]{40}\n
        )
    /
        my $match = $1;
        $match =~ s!.*?([0-9a-fA-F]{40}).*!$1!s or die;
        $digest_map->{$match}
    /xmeg;

    return $source;
}

sub unfold_comment_blocks {
    my ($class, $source) = @_;

    $$source =~ s/
        (?:
            ^\#\s([0-9a-fA-F]{40})\n
        )
    /
        $digest_map->{$1}
    /xmeg;

    return $source;
}

# Fold a heredoc's content but don't fold other heredocs from the
# same line.
sub fold_here {
    my $class = shift;
    my $result = "$2~~~$3$4$5";
    my $preface = '';
    my $text = $6;
    my $stop = $7;
    while (1) {
        if ($text =~ s!^(([0-9a-fA-F]{40})\n.*\n)!!) {
            if (defined $digest_map->{$2}) {
                $preface .= $1;
                next;
            }
            else {
                $text = $1 . $text;
                last;
            }
        }
        last;
    }
    my $digest = $class->fold($text);
    $result = "$result$preface$digest\n$stop";
    $result;
}

sub fold_pod {
    my $class = shift;
    my $text = $1;
    my $digest = $class->fold($text);
    return qq{===pod $digest\n===cut\n};
}

sub fold_comment {
    my $class = shift;
    my $text = $1;
    my $digest = $class->fold($text);
    return qq{``` $digest\n};
}

sub fold_data {
    my $class = shift;
    my $text = $1;
    my $digest = $class->fold($text);
    return qq{''' $digest\n};
}

# Fold a piece of code into a unique string.
sub fold {
    require Digest::SHA1;
    my ($class, $text) = @_;
    my $digest = Digest::SHA1::sha1_hex($text);
    $digest_map->{$digest} = $text;
    return $digest;
}

# Expand folded code into original content.
sub unfold {
    my ($class, $digest) = @_;
    return $digest_map->{$digest};
}

1;

=for perldoc
This POD generated by Perldoc-0.21.
DO NOT EDIT. Your changes will be lost.

=head1 NAME

Perl::Folder - Fold and Unfold Blocks in Perl Code

=head1 SYNOPSIS

    use Perl::Folder;
    my $folded = Perl::Folder->fold_blocks($perl);
    my $unfolded = Perl::Folder->unfold_blocks($folded);

=head1 DESCRIPTION

Using regexps to look for values in Perl code is problematic. This module
makes it much more reliable.

Say you are looking for a line like this one:

    our $VERSION = '0.10';

Matching that line is easy. But that line might be in a heredoc, the C<DATA>
section, a POD block or a comment. Also if you try to strip out all heredocs
you don't know if they are really part of a POD block of C<DATA> section, and
vice versa.

This module correctly finds these four types of blocks and folds them up,
replacing their content with the SHA1 digest of their content.

=head1 AUTHOR

Ingy döt Net

=head1 COPYRIGHT

Copyright (c) 2007. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
