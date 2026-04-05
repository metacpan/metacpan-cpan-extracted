package String::FillCharTemplate;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-01-20'; # DATE
our $DIST = 'String-FillCharTemplate'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       fill_char_template
               );

sub fill_char_template {
    my ($template, $str) = @_;

    my $len = length($str);
    my $i = 0;
    $template =~ s/#/$i >= $len ? " " : substr($str, $i++, 1)/eg;
    $template;
}

1;
# ABSTRACT: Fill placeholders in a template with characters from a string

__END__

=pod

=encoding UTF-8

=head1 NAME

String::FillCharTemplate - Fill placeholders in a template with characters from a string

=head1 VERSION

This document describes version 0.001 of String::FillCharTemplate (from Perl distribution String-FillCharTemplate), released on 2026-01-20.

=head1 SYNOPSIS

 use String::FillCharTemplate qw/fill_char_template/;

 my $res;
 $res = fill_char_template("###-###-###", "1234567890"); # => "123-456-789"
 $res = fill_char_template("###-###-###", "aaabbbc"); # => "aaa-bbb-c  "

=head1 FUNCTIONS

=head2 fill_char_template

Usage:

 my $result = fill_char_template($template, $str);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-FillCharTemplate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-FillCharTemplate>.

=head1 SEE ALSO

=head2 perl format

L<perlform>.

Perl format has a "fill mode" to let you fill multiple fields from a single
scalar. It is more flexible but also has additional syntax. Example:

 format STDOUT =
 ^<<-^<<-^<<
 $s, $s, $s
 .

 $s = "1234567890";
 write;

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-FillCharTemplate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
