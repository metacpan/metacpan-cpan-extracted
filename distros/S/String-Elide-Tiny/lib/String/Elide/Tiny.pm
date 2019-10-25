package String::Elide::Tiny;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.002'; # VERSION

# be tiny
#use strict 'subs', 'vars';
#use warnings;

sub import {
    my $pkg = shift;
    my $caller = caller;
    for my $sym (@_) {
        if ($sym eq 'elide') { *{"$caller\::$sym"} = \&{$sym} }
        else { die "$sym is not exported!" }
    }
}

sub elide {
    my ($str, $max_len, $opts) = @_;

    $opts ||= {};

    my $str_len = length $str;

    my $marker = defined $opts->{marker} ? $opts->{marker} : "...";
    my $marker_len = length $marker;
    return substr($marker, 0, $max_len) if $max_len < $marker_len;

    return $str if $str_len <= $max_len;

    my $truncate = $opts->{truncate} || 'right';
    if ($truncate eq 'left') {
        return $marker . substr($str, $str_len - $max_len + $marker_len);
    } elsif ($truncate eq 'middle') {
        my $left  = substr($str, 0,
                           ($max_len - $marker_len)/2);
        my $right = substr($str,
                           $str_len - ($max_len - $marker_len - length($left)));
        return $left . $marker . $right;
    } elsif ($truncate eq 'ends') {
        if ($max_len <= 2 * $marker_len) {
            return substr($marker . $marker, 0, $max_len);
        }
        return $marker . substr($str, ($str_len - $max_len)/2 + $marker_len,
                                $max_len - 2*$marker_len) . $marker;
    } else { # right
        return substr($str, 0, $max_len - $marker_len) . $marker;
    }
}

1;
# ABSTRACT: A very simple text truncating function, elide()

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Elide::Tiny - A very simple text truncating function, elide()

=head1 VERSION

This document describes version 0.002 of String::Elide::Tiny (from Perl distribution String-Elide-Tiny), released on 2019-09-11.

=head1 SYNOPSIS

 use String::Elide::Tiny qw(elide);

 # ruler:                                      0----5---10---15---20
 my $text =                                   "this is your brain";
 elide($text, 16);                       # -> "this is your ..."
 elide($text, 14);                       # -> "this is yo ..."

 # marker option:
 elide($text, 14, {marker=>"xxx"});      # -> "this is youxxx"

 # truncate option:
 elide($text, 14, {truncate=>"left"});   # -> "... your brain"
 elide($text, 14, {truncate=>"middle"}); # -> "this ... brain"
 elide($text, 14, {truncate=>"ends"});   # -> "...is your ..."

=head1 DESCRIPTION

This module offers L</elide>() function that is very simple; it's not
word-aware. It has options to choose marker or to select side(s) to truncate.

=head1 FUNCTIONS

=head2 elide

Usage:

 my $truncated = elide($str, $max_len [ , \%opts ])

Elide a string with " ..." if length exceeds C<$max_len>.

Known options:

=over

=item * truncate

String, either C<right>, C<left>, C<middle>, C<ends>.

=item * marker

String. Default: "...".

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Elide-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Elide-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Elide-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Elide> is also quite simple and elides at word boundaries, but it's not
tiny enough.

L<Text::Truncate> is tiny enough, but does not support truncating at the
left/both ends.

L<String::Elide::Parts> can elide at different points of the string.

L<String::Truncate> has similar interface like String::Elide::Parts and has some
options. But it's not tiny: it has a couple of non-core dependencies.

L<String::Elide::Lines> is based on this module but works on a line-basis.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
