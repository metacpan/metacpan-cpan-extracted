package String::PodQuote;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-17'; # DATE
our $DIST = 'String-PodQuote'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(pod_escape pod_quote);

our %transforms = (
    ( map { ("$_<" => "${_}E<lt>") } 'A'..'Z' ),
    ">"  => "E<gt>",
    " "  => "E<32>",
    "\t" => "E<9>",
    "="  => "E<61>",
    "/"  => "E<sol>",
    "|"  => "E<verbar>",
);

sub pod_escape {
    my $text = shift;

    $text =~ s{ ( [A-Z]< | [>/|] | ^[ \t=] ) }{$transforms{$1}}gmx;
    $text;
}

*pod_quote = \&pod_escape;

1;

# ABSTRACT: Escape/quote special characters that might be interpreted by a POD parser

__END__

=pod

=encoding UTF-8

=head1 NAME

String::PodQuote - Escape/quote special characters that might be interpreted by a POD parser

=head1 VERSION

This document describes version 0.003 of String::PodQuote (from Perl distribution String-PodQuote), released on 2019-12-17.

=head1 SYNOPSIS

 use String::PodQuote qw(pod_escape);

Putting a text as-is in an ordinary paragraph:

 print "=pod\n\n", pod_escape("First paragraph containing C<=>.\n\n   Second indented paragraph.\n\n"), "=cut\n\n";

will output:

 =pod

 First paragraph containing CE<lt>=E<gt>.

 E<32>  Second indented paragraph.

Putting text inside a POD link:

 print "L<", pod_escape("Some description containing <, >, |, /"), "|Some::Module>";

will output:

 L<Some description containing <, E<gt>, E<verbar>, E<sol>|Some::Module>

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 pod_escape

Usage:

 $escaped = pod_escape($text);

Quote special characters that might be interpreted by a POD parser.

The following characters are escaped:

 Character                                    Escaped into
 ---------                                    ------------
 < (only when preceded by a capital letter)   E<lt>
 >                                            E<gt>
 |                                            E<verbar>
 /                                            E<sol>
 (Space) (only at beginning of string/line)   E<32>
 (Tab) (only at beginning of string/line)     E<9>
 = (only at beginning of string/line)         E<61>

=head2 pod_quote

Alias for L<pod_escape>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-PodQuote>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-PodQuote>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-PodQuote>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perlpod>

Tangentially related modules: L<HTML::Entities>, L<URI::Escape>,
L<String::ShellQuote>, L<String::Escape>, L<String::PerlQuote>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
