package Sort::Sub::defhash_props;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-10'; # DATE
our $DIST = 'Sort-SubBundle-DefHash'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return {
        v => 1,
        summary => 'Sort DefHash properties and attributes',
        description => <<'MARKDOWN',

Known (standard) properties and attributes are put first, in order of mention in the spec.
Then unknown properties/attributes are sorted asciibetically.

MARKDOWN
    };
}

sub gen_sorter {
    require Sort::BySpec;

    my ($is_reverse, $is_ci) = @_;

    Sort::BySpec::cmp_by_spec(
        spec => [
            'v',

            'defhash_v',

            'name',
            qr/\Aname\./,

            'caption',
            qr/\Acaption\./,

            # not in spec, but very common
            'summary',
            qr/\Asummary\./,

            'description',
            qr/\Adescription\./,

            'tags',

            'default_lang',

            'x',
            qr/\Ax\./ => sub { $_[0] cmp $_[1] },

            qr// => sub { $_[0] cmp $_[1] },
        ],
        reverse => $is_reverse,
    );
}

1;
# ABSTRACT: Sort DefHash properties and attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::Sub::defhash_props - Sort DefHash properties and attributes

=head1 VERSION

This document describes version 0.001 of Sort::Sub::defhash_props (from Perl distribution Sort-SubBundle-DefHash), released on 2024-01-10.

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 SYNOPSIS

Generate sorter (accessed as variable) via L<Sort::Sub> import:

 use Sort::Sub '$defhash_props'; # use '$defhash_props<i>' for case-insensitive sorting, '$defhash_props<r>' for reverse sorting
 my @sorted = sort $defhash_props ('item', ...);

Generate sorter (accessed as subroutine):

 use Sort::Sub 'defhash_props<ir>';
 my @sorted = sort {defhash_props} ('item', ...);

Generate directly without Sort::Sub:

 use Sort::Sub::defhash_props;
 my $sorter = Sort::Sub::defhash_props::gen_sorter(
     ci => 1,      # default 0, set 1 to sort case-insensitively
     reverse => 1, # default 0, set 1 to sort in reverse order
 );
 my @sorted = sort $sorter ('item', ...);

Use in shell/CLI with L<sortsub> (from L<App::sortsub>):

 % some-cmd | sortsub defhash_props
 % some-cmd | sortsub defhash_props --ignore-case -r

=head1 DESCRIPTION

This module can generate sort subroutine. It is meant to be used via L<Sort::Sub>, although you can also use it directly via C<gen_sorter()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-SubBundle-DefHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-SubBundle-DefHash>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-SubBundle-DefHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
