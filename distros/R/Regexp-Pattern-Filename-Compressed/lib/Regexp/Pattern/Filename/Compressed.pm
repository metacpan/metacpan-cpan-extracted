package Regexp::Pattern::Filename::Compressed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-01'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Compressed'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Compressed ();

our %RE;

my $re = join '|', map {quotemeta} sort keys %Filename::Compressed::SUFFIXES;
$re = qr((?:$re)\z)i;

$RE{filename_compressed} = {
    summary => 'Compressed data filename',
    pat => $re,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'gz', matches=>0, summary=>'Not an extension'},
        {str=>'foo.gz', matches=>1},
        {str=>'foo bar.TAR.BZ2', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.xz is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.mp3', matches=>0},
    ],
};

1;
# ABSTRACT: Compressed data filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Compressed - Compressed data filename

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Filename::Compressed (from Perl distribution Regexp-Pattern-Filename-Compressed), released on 2020-04-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Compressed::filename_compressed");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Compressed>.

=head1 PATTERNS

=over

=item * filename_compressed

Compressed data filename.

Examples:

No extension.

 "foo" =~ re("Filename::Compressed::filename_compressed");  # doesn't match

Not an extension.

 "gz" =~ re("Filename::Compressed::filename_compressed");  # doesn't match

 "foo.gz" =~ re("Filename::Compressed::filename_compressed");  # matches

Case insensitive.

 "foo bar.TAR.BZ2" =~ re("Filename::Compressed::filename_compressed");  # matches

Regex is anchored.

 "foo.xz is the file" =~ re("Filename::Compressed::filename_compressed");  # doesn't match

 "foo.mp3" =~ re("Filename::Compressed::filename_compressed");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Compressed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Compressed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Compressed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<Filename::Compressed>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
