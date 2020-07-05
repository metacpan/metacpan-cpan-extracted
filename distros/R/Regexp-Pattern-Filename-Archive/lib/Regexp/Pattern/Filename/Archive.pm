package Regexp::Pattern::Filename::Archive;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-01'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Archive'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Archive ();
use Filename::Compressed ();

our %RE;

my $re = join('',
              '(?:', join('|', map {quotemeta} sort keys %Filename::Archive::SUFFIXES   ), ')',
              '(?:', join('|', map {quotemeta} sort keys %Filename::Compressed::SUFFIXES), ')*',
          );
$re = qr($re\z)i;

$RE{filename_archive} = {
    summary => 'Archive filename',
    pat => $re,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'zip', matches=>0, summary=>'Not an extension'},
        {str=>'foo.zip', matches=>1},
        {str=>'foo.tar.gz', matches=>1, summary=>'Plus compression'},
        {str=>'foo bar.TBZ', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.ARJ is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.txt', matches=>0},
    ],
};

1;
# ABSTRACT: Archive filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Archive - Archive filename

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Filename::Archive (from Perl distribution Regexp-Pattern-Filename-Archive), released on 2020-04-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Archive::filename_archive");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Archive>.

=head1 PATTERNS

=over

=item * filename_archive

Archive filename.

Examples:

No extension.

 "foo" =~ re("Filename::Archive::filename_archive");  # doesn't match

Not an extension.

 "zip" =~ re("Filename::Archive::filename_archive");  # doesn't match

 "foo.zip" =~ re("Filename::Archive::filename_archive");  # matches

Plus compression.

 "foo.tar.gz" =~ re("Filename::Archive::filename_archive");  # matches

Case insensitive.

 "foo bar.TBZ" =~ re("Filename::Archive::filename_archive");  # matches

Regex is anchored.

 "foo.ARJ is the file" =~ re("Filename::Archive::filename_archive");  # doesn't match

 "foo.txt" =~ re("Filename::Archive::filename_archive");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Archive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Archive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Archive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<Filename::Archive>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
