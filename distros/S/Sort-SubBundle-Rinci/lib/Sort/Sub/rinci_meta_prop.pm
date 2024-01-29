package Sort::Sub::rinci_meta_prop;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-12'; # DATE
our $DIST = 'Sort-SubBundle-Rinci'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return {
        v => 1,
        summary => 'Sort Rinci metadata properties (and attributes)',
    };
}

sub gen_sorter {
    require Sort::BySpec;

    my ($is_reverse, $is_ci) = @_;

    Sort::BySpec::cmp_by_spec(
        spec => [
            # from defhash
            'v',

            # from defhash
            'defhash_v',

            'entity_v',

            # from defhash
            'default_lang',

            # from defhash
            'name',
            qr/\Aname\./,

            # from defhash
            'caption',
            qr/\Acaption\./,

            # from defhash
            'summary',
            qr/\Asummary\./,

            # from defhash
            'description',
            qr/\Adescription\./,

            # from defhash
            'tags',

            'links',

            'x',
            qr/\Ax\./ => sub { $_[0] cmp $_[1] },

            qr// => sub { $_[0] cmp $_[1] },
        ],
        reverse => $is_reverse,
    );
}

1;
# ABSTRACT: Sort Rinci metadata properties (and attributes)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::rinci_meta_prop - Sort Rinci metadata properties (and attributes)

=head1 VERSION

This document describes version 0.001 of Sort::Sub::rinci_meta_prop (from Perl distribution Sort-SubBundle-Rinci), released on 2024-01-12.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$rinci_meta_prop'; # use '$rinci_meta_prop<i>' for case-insensitive sorting, '$rinci_meta_prop<r>' for reverse sorting
 my @sorted = sort $rinci_meta_prop ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'rinci_meta_prop<ir>';
 my @sorted = sort {rinci_meta_prop} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::rinci_meta_prop;
 my $sorter = Sort::Sub::rinci_meta_prop::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub rinci_meta_prop
 % some-cmd | sortsub rinci_meta_prop --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-SubBundle-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-SubBundle-Rinci>.

=head1 SEE ALSO

L<Sort::Sub>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-Rinci>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
