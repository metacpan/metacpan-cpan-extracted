package Path::Naive;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.040'; # VERSION

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       split_path
                       normalize_path
                       is_abs_path
                       is_rel_path
                       concat_path
                       concat_path_n
                       abs_path
               );

sub split_path {
    die "Please specify path" unless defined($_[0]) && length($_[0]);
    grep {length} split qr!/+!, $_[0];
}

sub normalize_path {
    my @d0 = split_path $_[0];
    my $abs = $_[0] =~ m!\A/!;
    my @d;
    while (@d0) {
        my $d = shift @d0;
        next if $d eq '.' && (@d || @d0 || $abs);
        do { pop @d; next } if $d eq '..' &&
            (@d>1 && $d[-1] ne '..' ||
                 @d==1 && $d[-1] ne '..' && $d[-1] ne '.' && @d0 ||
                     $abs);
        push @d, $d;
    }
    if (wantarray) {
        @d;
    } else {
        ($abs ? "/" : "") . join("/", @d);
    }
}

sub is_abs_path {
    die "Please specify path" unless defined($_[0]) && length($_[0]);
    $_[0] =~ m!\A/! ? 1:0;
}

sub is_rel_path {
    die "Please specify path" unless defined($_[0]) && length($_[0]);
    $_[0] =~ m!\A/! ? 0:1;
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

sub concat_path_n {
    normalize_path(concat_path(@_));
}

sub abs_path {
    die "Please specify path" unless defined($_[0]) && length($_[0]);
    die "Please specify base" unless defined($_[1]) && length($_[1]);
    die "base must be absolute" unless is_abs_path($_[1]);
    concat_path_n($_[1], $_[0]);
}

1;
# ABSTRACT: Yet another abstract, Unix-like path manipulation routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Naive - Yet another abstract, Unix-like path manipulation routines

=head1 VERSION

This document describes version 0.040 of Path::Naive (from Perl distribution Path-Naive), released on 2020-02-05.

=head1 SYNOPSIS

 use Path::Naive qw(
     split_path concat_path normalize_path abs_path
     is_abs_path is_rel_path);

 # split path to directories
 @dirs = split_path("");              # dies, empty path
 @dirs = split_path("/");             # -> ()
 @dirs = split_path("a");             # -> ("a")
 @dirs = split_path("/a");            # -> ("a")
 @dirs = split_path("/a/");           # -> ("a")
 @dirs = split_path("../a");          # -> ("..", "a")
 @dirs = split_path("./a");           # -> (".", "a")
 @dirs = split_path("../../a");       # -> ("..", "..", "a")
 @dirs = split_path(".././../a");     # -> ("..", ".", "..", "a")
 @dirs = split_path("a/b/c/..");      # -> ("a", "b", "c", "..")

 # normalize path (collapse . & .., remove double & trailing / except on "/")
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

 # in list context, normalize_path returns list, this is useful to save you from
 # having to split the normalized path yourself.
 @p = normalize_path("a/b/./");        # -> ("a", "b")

 # check whether path is absolute (starts from root)
 say is_abs_path("/");                # -> 1
 say is_abs_path("/a");               # -> 1
 say is_abs_path("/..");              # -> 1
 say is_abs_path(".");                # -> 0
 say is_abs_path("./b");              # -> 0
 say is_abs_path("b/c/");             # -> 0

 # this is basically just !is_abs_path($path)
 say is_rel_path("/");                # -> 0
 say is_rel_path("a/b");              # -> 1

 # concatenate two paths
 say concat_path("a", "b");           # -> "a/b"
 say concat_path("a/", "b");          # -> "a/b"
 say concat_path("a", "b/");          # -> "a/b/"
 say concat_path("a", "../b/");       # -> "a/../b/"
 say concat_path("a/b", ".././c");    # -> "a/b/.././c"
 say concat_path("../", ".././c/");   # -> "../.././c/"
 say concat_path("a/b/c", "/d/e");    # -> "/d/e" (path2 is absolute)

 # this is just concat_path + normalize_path the result. note that it can return
 # path string (in scalar context) or path elements (in list context).
 $p = concat_path_n("a", "b");         # -> "a/b"
 $p = concat_path_n("a/", "b");        # -> "a/b"
 $p = concat_path_n("a", "b/");        # -> "a/b"
 $p = concat_path_n("a", "../b/");     # -> "b"
 $p = concat_path_n("a/b", ".././c");  # -> "a/c"
 $p = concat_path_n("../", ".././c/"); # -> "../../c"
 @p = concat_path_n("../", ".././c/"); # -> ("..", "..", "c")

 # abs_path($path, $base) is equal to concat_path_n($base, $path). $base must be
 # absolute. note that it can return path string (in scalar context) or path
 # elements (in list context).
 $p = abs_path("a", "b");              # dies, $base is not absolute
 $p = abs_path("a", "/b");             # -> "/b/a"
 $p = abs_path(".", "/b");             # -> "/b"
 $p = abs_path("a/c/..", "/b/");       # -> "/b/a"
 $p = abs_path("/a", "/b/c");          # -> "/a"
 @p = abs_path("a/c/..", "/b/");       # -> ("b", "a")

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

=head2 split_path($path) => list

=head2 normalize_path($path) => str | list

=head2 is_abs_path($path) => bool

=head2 is_rel_path($path) => bool

=head2 concat_path($path1, $path2, ...) => str

=head2 concat_path_n($path1, $path2, ...) => str | list

=head2 abs_path($path) => str | list

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Path-Naive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Path-Naive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Path-Naive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Path::Abstract> a similar module. The difference is, it does not interpret
C<.> and C<..>.

L<File::Spec::Unix> a similar module, with some differences in parsing behavior.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
