package SortKey::Num::file_num_links;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-10'; # DATE
our $DIST = 'SortKey-Num-file_num_links'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            follow_symlink => {schema=>'bool*', default=>1},
        },
    };
}

sub gen_keygen {
    my %args = @_;

    my $follow_symlink = $args{follow_symlink} // 1;

    sub {
        my $arg = @_ ? shift : $_;
        my @st = $follow_symlink ? stat($arg) : lstat($arg);
        @st ? $st[3] : undef;
    }
}

1;
# ABSTRACT: File number of (hard) links as sort key

__END__

=pod

=encoding UTF-8

=head1 NAME

SortKey::Num::file_num_links - File number of (hard) links as sort key

=head1 VERSION

This document describes version 0.001 of SortKey::Num::file_num_links (from Perl distribution SortKey-Num-file_num_links), released on 2024-11-10.

=head1 SYNOPSIS

 use Sort::Key qw(nkeysort);
 use SortKey::Num::file_num_links;

 my $by_num_links = SortKey::Num::file_num_links::gen_keygen;
 my @sorted = &nkeysort($by_num_links, "foo", "bar", "baz"");

=head1 DESCRIPTION

This module provides sort key generator that assumes item is filename and
take the file's number of (hard) links as key.

=for Pod::Coverage ^(meta|gen_keygen)$

=head1 KEYGEN GENERATOR ARGUMENTS

=head2 follow_symlink

Bool, default true. If set to false, will use C<lstat()> function instead of the
default C<stat()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortKey-Num-file_num_links>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortKey-Num-file_num_links>.

=head1 SEE ALSO

L<Sorter::file_by_num_links>

L<Comparer::file_num_links>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortKey-Num-file_num_links>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
