package String::SimpleEscape;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-28'; # DATE
our $DIST = 'String-SimpleEscape'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(simple_escape_string simple_unescape_string);

my %escape = (
    "\012" => "\\n",
    "\t"   => "\\t",
    "\\"   => "\\\\",
    "\""   => "\\\"",
);

my %unescape = (
    "\\n"  => "\012",
    "\\t"  => "\t",
    "\\\\" => "\\",
    "\\\"" => "\"",
);

sub simple_escape_string {
    my $str = shift;
    $str =~ s/([\012\011\\"])/$escape{$1}/g;
    $str;
}
sub simple_unescape_string {
    my $str = shift;
    $str =~ s/(\\n|\\t|\\\\|\\")/$unescape{$1}/g;
    $str;
}

1;
# ABSTRACT: Simple string escaping & unescaping

__END__

=pod

=encoding UTF-8

=head1 NAME

String::SimpleEscape - Simple string escaping & unescaping

=head1 VERSION

This document describes version 0.001 of String::SimpleEscape (from Perl distribution String-SimpleEscape), released on 2020-05-28.

=head1 DESCRIPTION

A very simple backslash escaping/unescaping utility, with only four escapes
known: C<\n> (for \012), C<\t> (for tab), C<\\> (for backslash), C<\"> (for
doublequotes).

=head1 FUNCTIONS

=head2 simple_escape_string

=head2 simple_unescape_string

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-SimpleEscape>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-SimpleEscape>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-SimpleEscape>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::Escape>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
