package Regexp::Pattern::Filename::Backup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-01'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Backup'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Backup ();

our %RE;

my $re = join '|', map {quotemeta} sort keys %Filename::Backup::SUFFIXES;
$re = qr((?:$re)\z)i;

$RE{filename_backup} = {
    summary => 'Backup filename',
    pat => $re,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'gz', matches=>0, summary=>'Not an extension'},
        {str=>'foo~', matches=>1},
        {str=>'foo bar.BAK', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.old is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.txt', matches=>0},
    ],
};

1;
# ABSTRACT: Backup filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Backup - Backup filename

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Filename::Backup (from Perl distribution Regexp-Pattern-Filename-Backup), released on 2020-04-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Backup::filename_backup");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Backup>.

=head1 PATTERNS

=over

=item * filename_backup

Backup filename.

Examples:

No extension.

 "foo" =~ re("Filename::Backup::filename_backup");  # doesn't match

Not an extension.

 "gz" =~ re("Filename::Backup::filename_backup");  # doesn't match

 "foo~" =~ re("Filename::Backup::filename_backup");  # matches

Case insensitive.

 "foo bar.BAK" =~ re("Filename::Backup::filename_backup");  # matches

Regex is anchored.

 "foo.old is the file" =~ re("Filename::Backup::filename_backup");  # doesn't match

 "foo.txt" =~ re("Filename::Backup::filename_backup");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Backup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Backup>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Backup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<Filename::Backup>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
