package String::Indent;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-25'; # DATE
our $DIST = 'String-Indent'; # DIST
our $VERSION = '0.040'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(
                       indent
               );

sub indent {
    my ($indent, $str, $opts) = @_;
    $opts //= {};

    my $ibl   = $opts->{indent_blank_lines} // 1;
    my $fli   = $opts->{first_line_indent} // $indent;
    my $sli   = $opts->{subsequent_lines_indent} // $indent;
    my $flopi = $opts->{first_line_of_para_indent} // $sli // $indent;
    #say "D:ibl=<$ibl>, fli=<$fli>, flopi=<$flopi>, sli=<$sli>";

    my $i = 0;
    my $prev_blank;
    $str =~ s/^([^\r\n]?)/$i++; my $blank = !$1; my $start_para = $i==1 || $prev_blank; $prev_blank = $blank; !$ibl && $blank ? "$1" : $i==1 ? "$fli$1" : $start_para ? "$flopi$1" : "$sli$1"/egm;
    $str;
}

1;
# ABSTRACT: String indenting routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Indent - String indenting routines

=head1 VERSION

This document describes version 0.040 of String::Indent (from Perl distribution String-Indent), released on 2024-01-25.

=head1 FUNCTIONS

=head2 indent($indent, $str, \%opts) => STR

Indent every line in $str with $indent. Example:

 indent('  ', "one\ntwo\nthree") # "  one\n  two\n  three"

%opts is optional. Known options:

=over 4

=item * indent_blank_lines => bool (default: 1)

If set to false, does not indent blank lines (i.e., lines containing only zero
or more whitespaces).

=item * first_line_indent => str

If set, then the first line will be set to this instead of the normal indent.

=item * first_line_of_para_indent => str

If set, then the first line of each paragraph will be set to this instead of the
normal indent.

=item * subsequent_lines_indent => str

If set, then all lines but the first line will be set to this instead of the
normal indent.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Indent>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Indent>.

=head1 SEE ALSO

L<Indent::String>, L<String::Nudge>, L<Text::Indent>

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

This software is copyright (c) 2024, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Indent>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
