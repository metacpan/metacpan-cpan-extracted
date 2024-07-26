package Path::Naive;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Path-Naive'; # DIST
our $VERSION = '0.044'; # VERSION

our @EXPORT_OK = qw(
    abs_path
    concat_and_normalize_path
    concat_path
    normalize_and_split_path
    normalize_path
    is_abs_path
    is_rel_path
    rel_path
    split_path
);

sub abs_path {
    my ($path, $base) = @_;

    die "Please specify path (first arg)"  unless defined $path && length $path;
    die "Please specify base (second arg)" unless defined $base && length $base;
    die "base must be absolute" unless is_abs_path($base);
    concat_and_normalize_path($base, $path);
}

sub is_abs_path {
    my $path = shift;
    die "Please specify path" unless defined $path && length $path;
    $path =~ m!\A/! ? 1:0;
}

sub is_rel_path {
    my $path = shift;
    die "Please specify path" unless defined $path && length $path;
    $path =~ m!\A/! ? 0:1;
}

sub concat_path {
    die "Please specify at least two paths" unless @_ > 1;
    my $i = 0;
    my $res = $_[0];
    for (@_) {
        die "Please specify path (#$i)" unless defined && length;
        next unless $i++;
        if (m!\A/!) {
            $res = $_;
        } else {
            $res .= ($res =~ m!/\z! ? "" : "/") . $_;
        }
    }
    $res;
}

sub concat_and_normalize_path {
    normalize_path(concat_path(@_));
}

my $_split;
sub _normalize_path {
    my $path = shift;
    my @elems0 = split_path($path);
    my $is_abs = $path =~ m!\A/!;
    my @elems;
    while (@elems0) {
        my $elem = shift @elems0;
        next if $elem eq '.' && (@elems || @elems0 || $is_abs);
        do { pop @elems; next } if $elem eq '..' &&
            (@elems>1 && $elems[-1] ne '..' ||
                 @elems==1 && $elems[-1] ne '..' && $elems[-1] ne '.' && @elems0 ||
                     $is_abs);
        push @elems, $elem;
    }
    return @elems if $_split;
    ($is_abs ? "/" : "") . join("/", @elems);
}

sub normalize_path {
    $_split = 0;
    goto &_normalize_path;
}

sub normalize_and_split_path {
    $_split = 1;
    goto &_normalize_path;
}

sub rel_path {
    my ($path, $base) = @_;

    die "Please specify path (first arg)"  unless defined $path && length $path;
    die "Please specify base (second arg)" unless defined $base && length $base;
    die "path must be absolute" unless is_abs_path($path);
    die "base must be absolute" unless is_abs_path($base);
    my @elems_path = normalize_and_split_path($path);
    my @elems_base = normalize_and_split_path($base);

    my $num_common_elems = 0;
    for (0..$#elems_base) {
        last unless @elems_path > $num_common_elems;
        last unless
            $elems_path[$num_common_elems] eq $elems_base[$num_common_elems];
        $num_common_elems++;
    }
    my @elems;
    push @elems, ".." for ($num_common_elems .. $#elems_base);
    push @elems, @elems_path[$num_common_elems .. $#elems_path];
    @elems = (".") unless @elems;
    join("/", @elems);
}

sub split_path {
    my $path = shift;
    die "Please specify path" unless defined $path && length $path;
    grep {length} split qr!/+!, $path;
}

1;
# ABSTRACT: Yet another abstract, Unix-like path manipulation routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Naive - Yet another abstract, Unix-like path manipulation routines

=head1 VERSION

This document describes version 0.044 of Path::Naive (from Perl distribution Path-Naive), released on 2024-07-17.

=head1 SYNOPSIS

 use Path::Naive qw(
     abs_path
     concat_and_normalize_path
     concat_path
     is_abs_path
     is_rel_path
     normalize_and_split_path
     normalize_path
     rel_path
     split_path
);

 # split path to its elements.
 @dirs = split_path("");              # dies, empty path
 @dirs = split_path("/");             # -> ()
 @dirs = split_path("a");             # -> ("a")
 @dirs = split_path("/a");            # -> ("a")
 @dirs = split_path("/a/");           # -> ("a")
 @dirs = split_path("/a/b/c");        # -> ("a", "b", "c")
 @dirs = split_path("/a//b////c//");  # -> ("a", "b", "c")
 @dirs = split_path("../a");          # -> ("..", "a")
 @dirs = split_path("./a");           # -> (".", "a")
 @dirs = split_path("../../a");       # -> ("..", "..", "a")
 @dirs = split_path(".././../a");     # -> ("..", ".", "..", "a")
 @dirs = split_path("a/b/c/..");      # -> ("a", "b", "c", "..")

 # normalize path (collapse . & .., remove double & trailing / except on "/").
 $p = normalize_path("");              # dies, empty path
 $p = normalize_path("/");             # -> "/"
 $p = normalize_path("..");            # -> ".."
 $p = normalize_path("./");            # -> "."
 $p = normalize_path("//");            # -> "/"
 $p = normalize_path("a/b/.");         # -> "a/b"
 $p = normalize_path("a/b/./");        # -> "a/b"
 $p = normalize_path("a/b/..");        # -> "a"
 $p = normalize_path("a/b/../");       # -> "a"
 $p = normalize_path("/a/./../b");     # -> "/b"
 $p = normalize_path("/a/../../b");    # -> "/b" (.. after hitting root is ok)

 # check whether path is absolute (starts from root).
 say is_abs_path("/");                # -> 1
 say is_abs_path("/a");               # -> 1
 say is_abs_path("/..");              # -> 1
 say is_abs_path(".");                # -> 0
 say is_abs_path("./b");              # -> 0
 say is_abs_path("b/c/");             # -> 0

 # this is basically just !is_abs_path($path).
 say is_rel_path("/");                # -> 0
 say is_rel_path("a/b");              # -> 1

 # concatenate two paths.
 say concat_path("a", "b");           # -> "a/b"
 say concat_path("a/", "b");          # -> "a/b"
 say concat_path("a", "b/");          # -> "a/b/"
 say concat_path("a", "../b/");       # -> "a/../b/"
 say concat_path("a/b", ".././c");    # -> "a/b/.././c"
 say concat_path("../", ".././c/");   # -> "../.././c/"
 say concat_path("a/b/c", "/d/e");    # -> "/d/e" (path2 is absolute)

 # this is just concat_path + normalize_path the result. note that it can return
 # path string (in scalar context) or path elements (in list context).
 $p = concat_and_normalize_path("a", "b");         # -> "a/b"
 $p = concat_and_normalize_path("a/", "b");        # -> "a/b"
 $p = concat_and_normalize_path("a", "b/");        # -> "a/b"
 $p = concat_and_normalize_path("a", "../b/");     # -> "b"
 $p = concat_and_normalize_path("a/b", ".././c");  # -> "a/c"
 $p = concat_and_normalize_path("../", ".././c/"); # -> "../../c"

 # abs_path($path, $base) is equal to concat_path_n($base, $path). $base must be
 # absolute.
 $p = abs_path("a", "b");              # dies, $base is not absolute
 $p = abs_path("a", "/b");             # -> "/b/a"
 $p = abs_path(".", "/b");             # -> "/b"
 $p = abs_path("a/c/..", "/b/");       # -> "/b/a"
 $p = abs_path("/a", "/b/c");          # -> "/a"

 # rel_path($path, $base) makes $path relative. the opposite of abs_path().
 $p = rel_path("a", "/b");             # dies, $path is not absolute
 $p = rel_path("/a", "b");             # dies, $base is not absolute
 $p = rel_path("/a", "/b");            # -> "../a"
 $p = rel_path("/b/c/e", "/b/d/f");    # -> "../../c/e"

=head1 DESCRIPTION

This is yet another set of routines to manipulate abstract Unix-like paths.
B<Abstract> means not tied to actual filesystem. B<Unix-like> means single-root
tree, with forward slash C</> as separator, and C<.> and C<..> to mean current-
and parent directory. B<Naive> means not having the concept of symlinks, so
paths need not be traversed on a per-directory basis (see L<File::Spec::Unix>
where it mentions the word "naive").

These routines can be useful if you have a tree data and want to let users walk
around it using filesystem-like semantics. Some examples of where these routines
are used: Config::Tree, L<Riap> (L<App::riap>).

=head1 FUNCTIONS

=head2 abs_path($path, $base) => str

=head2 concat_and_normalize_path($path1, $path2, ...) => str

=head2 concat_path($path1, $path2, ...) => str

=head2 is_abs_path($path) => bool

=head2 is_rel_path($path) => bool

=head2 normalize_and_split_path($path) => list

Added in v0.043.

=head2 normalize_path($path) => str

=head2 rel_path($path, $base) => str

Added in v0.043.

=head2 split_path($path) => list

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Path-Naive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Path-Naive>.

=head1 SEE ALSO

L<Path::Abstract> a similar module. The difference is, it does not interpret
C<.> and C<..>.

L<File::Spec::Unix> a similar module, with some differences in parsing behavior.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2024, 2020, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Path-Naive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
