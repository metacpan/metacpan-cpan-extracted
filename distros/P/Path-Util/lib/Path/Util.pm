package Path::Util;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-05'; # DATE
our $DIST = 'Path-Util'; # DIST
our $VERSION = '0.000002'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       basename
);

sub basename {
    require File::Spec;

    my ($path, @suffixes) = @_;

    # TODO: we haven't canonicalize foo/bar/ -> foo/bar so basename(foo/bar/) ->
    # ''.

    my (undef, undef, $file) = File::Spec->splitpath($path);
    for my $s (@suffixes) {
        my $re = ref($s) eq 'Regexp' ? qr/$s$/ : qr/\Q$s\E$/;
        last if $file =~ s/$re//;
    }
    $file;
}

1;
# ABSTRACT: Path functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Util - Path functions

=head1 VERSION

This document describes version 0.000002 of Path::Util (from Perl distribution Path-Util), released on 2021-07-05.

=head1 SYNOPSIS

 use Path::Util qw(
     basename
 );

 # basename
 $filename = basename("/home/ujang/foo.txt"); # => "foo.txt"
 $dirname  = basename("../etc/mysql/"); # => "foo.txt"

=head1 DESCRIPTION

B<VERY EARLY RELEASE, ONLY A TINY BIT HAS BEEN IMPLEMENTED.>

Following Perl's "easy things should be easy" motto, the goal of this module is
to make many path-related tasks as simple as calling a single function. The
functions in this module are usually wrappers for functions of other modules or
methods of other classes. You can think of this module as the "List::Util for
path" or "a non-OO Path::Tiny".

=head1 FUNCTIONS

=head2 basename

Usage:

 my $file = basename($path);

Examples:

This function returns the file portion or last directory portion of a path. It
uses File::Spec's C<splitpath> and grabs the last returned element, optionally
does something extra (see below).

Given a list of suffixes as strings or regular expressions, any that matches at
the end of the file portion or last directory portion will be removed before the
result is returned.

Similar to Path::Tiny's C<basename>.

See also: L<File::Basename>.

Available since v0.000001.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Path-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Path-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Path-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Path::Tiny>

L<File::Spec>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
