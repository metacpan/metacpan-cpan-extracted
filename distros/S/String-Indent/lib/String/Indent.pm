package String::Indent;

our $DATE = '2015-03-06'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       indent
               );

sub indent {
    my ($indent, $str, $opts) = @_;
    $opts //= {};

    my $ibl = $opts->{indent_blank_lines} // 1;
    my $fli = $opts->{first_line_indent} // $indent;
    my $sli = $opts->{subsequent_lines_indent} // $indent;
    #say "D:ibl=<$ibl>, fli=<$fli>, sli=<$sli>";

    my $i = 0;
    $str =~ s/^([^\r\n]?)/$i++; !$ibl && !$1 ? "$1" : $i==1 ? "$fli$1" : "$sli$1"/egm;
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

This document describes version 0.03 of String::Indent (from Perl distribution String-Indent), released on 2015-03-06.

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

=item * subsequent_lines_indent => str

If set, then all lines but the first line will be set to this instead of the
normal indent.

=back

=head1 SEE ALSO

L<Indent::String>, L<String::Nudge>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Indent>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Indent>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Indent>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
