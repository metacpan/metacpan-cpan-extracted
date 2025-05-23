package SortKey::Num::similarity;

use 5.010001;
use strict;
use warnings;

use Text::Levenshtein::XS;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-15'; # DATE
our $DIST = 'SortKey-Num-similarity'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            string => {schema=>'str*', req=>1},
            ci => {schema => 'bool*'},
        },
    };
}

sub gen_keygen {
    my %args = @_;

    my $reverse = $args{reverse};
    my $string = $args{string};
    my $lc_string = lc $string;
    my $ci = $args{ci};

    sub {
        my $arg = @_ ? shift : $_;
        $ci ? Text::Levenshtein::XS::distance($lc_string, lc($arg)) : Text::Levenshtein::XS::distance($string, $arg);
    };
}

1;
# ABSTRACT: Similarity to a reference string as sort key

__END__

=pod

=encoding UTF-8

=head1 NAME

SortKey::Num::similarity - Similarity to a reference string as sort key

=head1 VERSION

This document describes version 0.002 of SortKey::Num::similarity (from Perl distribution SortKey-Num-similarity), released on 2024-05-15.

=head1 SYNOPSIS

Use with L<Sort::Key>:

 use Sort::Key qw(nkeysort);
 use SortKey::Num::similarity;

 my $keygen = SortKey::Num::similarity::gen_keygen(string => 'foo');
 my @sorted = &nkeysort($keygen, "food", "foolish", "foo", "bar");
 # => ("foo","food","bar","foolish")

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|gen_keygen)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortKey-Num-similarity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortKey-Num-similarity>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortKey-Num-similarity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
