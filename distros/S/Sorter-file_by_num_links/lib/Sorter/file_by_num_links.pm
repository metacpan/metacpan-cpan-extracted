package Sorter::file_by_num_links;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-10'; # DATE
our $DIST = 'Sorter-file_by_num_links'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return +{
        v => 1,
        summary => 'Sort files by number of (hard) links',
        args => {
            follow_symlink => {schema=>'bool*', default=>1},
            reverse => {schema => 'bool*'},
            #ci => {schema => 'bool*'},
        },
    };
}

sub gen_sorter {
    my %args = @_;

    my $follow_symlink = $args{follow_symlink} // 1;
    my $reverse = $args{reverse};

    sub {
        my @items = @_;
        my @num_links = map { my @st = $follow_symlink ? stat($_) : lstat($_); $st[3] } @items;

        map { $items[$_] } sort {
            $reverse ? $num_links[$b] <=> $num_links[$a] : $num_links[$a] <=> $num_links[$b]
        } 0 .. $#items;
    };
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sorter::file_by_num_links

=head1 VERSION

This document describes version 0.001 of Sorter::file_by_num_links (from Perl distribution Sorter-file_by_num_links), released on 2024-11-10.

=head1 SYNOPSIS

 use Sorter::file_by_num_links;

 my $sorter = Sorter::file_by_num_links::gen_sorter();
 my @sorted = $sorter->("foo", "bar", "baz");

Reverse:

 $sorter = Sorter::file_by_num_links::gen_sorter(reverse=>1);
 @sorted = $sorter->("foo", "bar", "baz");

=head1 DESCRIPTION

This sorter assumes items are filenames and sort them by number of (hard) links.

=for Pod::Coverage ^(meta|gen_sorter)$

=head1 SORTER ARGUMENTS

=head2 follow_symlink

Bool, default true. If set to false, will use C<lstat()> function instead of the
default C<stat()>.

=head2 reverse

Bool.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sorter-file_by_num_links>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sorter-file_by_num_links>.

=head1 SEE ALSO

L<Comparer::file_num_links>

L<SortKey::Num::file_num_links>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sorter-file_by_num_links>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
