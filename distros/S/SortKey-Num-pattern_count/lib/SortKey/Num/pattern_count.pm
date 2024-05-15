package SortKey::Num::pattern_count;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-15'; # DATE
our $DIST = 'SortKey-Num-pattern_count'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            pattern => {
                schema => 're_from_str*',
                req => 1,
            },
            string => {
                schema => ['str*', min_len=>1],
                req => 1,
            },
        },
        args_rels => {
            'req_one' => [qw/regexp/],
        },
    };
}

sub gen_keygen {
    my %args = @_;

    my $re = $args{pattern} ? $args{pattern} : qr/\Q$args{string}\E/;

    sub {
        my $str = @_ ? shift : $_;
        my $count = 0;
        $count++ while $str =~ /$re/g;
        $count;
    };
}

1;
# ABSTRACT: Number of occurrences of string/regexp pattern as sort key

__END__

=pod

=encoding UTF-8

=head1 NAME

SortKey::Num::pattern_count - Number of occurrences of string/regexp pattern as sort key

=head1 VERSION

This document describes version 0.002 of SortKey::Num::pattern_count (from Perl distribution SortKey-Num-pattern_count), released on 2024-05-15.

=head1 SYNOPSIS

 use Sort::Key qw(nkeysort);
 use SortKey::Num::pattern_count;

 my $by_pattern_count = SortKey::Num::length::gen_keygen(string => 'fo');
 my @sorted = &nkeysort($by_pattern_count, "fofood", "foolish", "fofofo");
 # => ("foolish", "fofood", "fofofo")

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|gen_keygen)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortKey-Num-pattern_count>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortKey-Num-pattern_count>.

=head1 SEE ALSO

Old incarnation: L<Sort::Sub::by_count>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortKey-Num-pattern_count>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
