package String::CommonPrefix;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-08-02'; # DATE
our $DIST = 'String-CommonPrefix'; # DIST
our $VERSION = '0.021'; # VERSION

our @EXPORT_OK = qw(
                       common_prefix
                       majority_prefix
               );

sub common_prefix {
    return undef unless @_; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    my $i;
  L1:
    for ($i=0; $i < length($_[0]); $i++) {
        for (@_[1..$#_]) {
            if (length($_) < $i) {
                $i--; last L1;
            } else {
                last L1 if substr($_, $i, 1) ne substr($_[0], $i, 1);
            }
        }
    }
    substr($_[0], 0, $i);
}

sub majority_prefix {
    #my $opts = ref($_[0]) eq 'HASH' ? {%{shift}} : {};
    return undef unless @_; ## no critic: Subroutines::ProhibitExplicitReturnUndef

    my @excluded = map {0} @_;
    my $min_items_for_majority = int(@_/2) + 1;
    my $prefix_len = 0;
    while (1) {
        my @items;
        # take the next character from items that are still eligible
        for my $i (0..$#_) {
            my $char;
            if ($excluded[$i]) {
                $char = undef;
            } elsif (length($_[$i]) < $prefix_len) {
                $excluded[$i]++;
                $char = undef;
            } else {
                $char = substr($_[$i], $prefix_len, 1);
            }
            push @items, $char;
        }
        #use DD; dd \@excluded;
        # determine whether there's still a character that belong to the
        # majority
        my %freqs;
        for (@items) { next unless defined; $freqs{$_}++ }
        last unless keys %freqs;
        #use DD; dd \%freqs;
        my @freqs = sort { $freqs{$b} <=> $freqs{$a} } keys %freqs;
        my $majority_char = $freqs[0];
        last if $freqs{$majority_char} < $min_items_for_majority;
        for (0 .. $#items) { next unless defined $items[$_]; unless ($items[$_] eq $majority_char) { $excluded[$_]++ } }
        $prefix_len++;
        #say "D: prefix_len=$prefix_len";
    }

    my $first_included;
    for (0 .. $#_) { unless ($excluded[$_]) { $first_included = $_; last } }
    return undef unless defined $first_included; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    #say "D: first_included=$first_included";
    substr($_[$first_included], 0, $prefix_len);
}

1;
# ABSTRACT: Find prefix common to all strings

__END__

=pod

=encoding UTF-8

=head1 NAME

String::CommonPrefix - Find prefix common to all strings

=head1 VERSION

This document describes version 0.021 of String::CommonPrefix (from Perl distribution String-CommonPrefix), released on 2025-08-02.

=head1 FUNCTIONS

=head2 common_prefix(@LIST) => STR

Given a list of strings, return common prefix.

=head2 majority_prefix(@LIST) => STR

Given a list of strings, return longest prefix that still belong to > 50% of the
items in the list.

Example:

 majority_prefix("qux", "foo", "foobar"); # => "foo", found in 2 out of 3

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-CommonPrefix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-CommonPrefix>.

=head1 SEE ALSO

L<String::CommonSuffix>

CLI: L<strip-common-prefix> (from L<App::CommonPrefixUtils>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-CommonPrefix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
