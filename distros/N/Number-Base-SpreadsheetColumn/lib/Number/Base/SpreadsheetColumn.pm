package Number::Base::SpreadsheetColumn;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       from_scbase
                       to_scbase
               );

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-02'; # DATE
our $DIST = 'Number-Base-SpreadsheetColumn'; # DIST
our $VERSION = '0.001'; # VERSION

sub from_scbase {
    my $str = uc shift;

    die "Please only use letters A-Z" if $str =~ /[^A-Z]/;

    my $res = 0;
    for my $char (split //, $str) {
        $res = $res * 26 + (ord($char) - ord('A') + 1);
    }
    $res-1;
}

sub to_scbase {
    my $num = shift;

    die "Currently can't handle fraction or negative number!"
        if $num < 0 || $num != int($num);
    $num = int($num);

    my $res = "";
    while ($num >= 0) {
        my $remainder = $num % 26;
        my $letter = chr($remainder + ord('A'));
        #say "D:num=<$num>, remainder=<$remainder>, letter=<$letter>";
        $res = $letter . $res;
        $num = int($num / 26) - 1;
        #say "D:num=<$num>";
    }
    $res;
}

1;

# ABSTRACT: Convert spreadsheet column name (e.g. "A", "Z", "AA") to number (e.g. 0, 25, 26) and vice versa

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Base::SpreadsheetColumn - Convert spreadsheet column name (e.g. "A", "Z", "AA") to number (e.g. 0, 25, 26) and vice versa

=head1 VERSION

This document describes version 0.001 of Number::Base::SpreadsheetColumn (from Perl distribution Number-Base-SpreadsheetColumn), released on 2026-02-02.

=head1 SYNOPSIS

 use Number::Base::SpreadsheetColumn qw(from_scbase to_scbase);

 say from_scbase("A");  # => 0
 say from_scbase("Z");  # => 25
 say from_scbase("AA"); # => 26
 say from_scbase("AZ"); # => 51
 say from_scbase("BA"); # => 52

 say to_scbase(0);  # => "A"
 say to_scbase(25); # => "Z"
 say to_scbase(26); # => "AA"
 say to_scbase(51); # => "AZ"
 say to_scbase(52); # => "BA"

=head1 DESCRIPTION

Spreadsheet column is basically 26-base number with 1-based index.

=head1 FUNCTIONS

=head2 from_scbase

=head2 to_scbase

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Base-SpreadsheetColumn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Base-SpreadsheetColumn>.

=head1 SEE ALSO

L<Number::AnyBase>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Base-SpreadsheetColumn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
