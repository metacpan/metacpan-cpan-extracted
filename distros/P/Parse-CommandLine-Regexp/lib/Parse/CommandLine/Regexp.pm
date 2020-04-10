package Parse::CommandLine::Regexp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-09'; # DATE
our $DIST = 'Parse-CommandLine-Regexp'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_command_line);

sub _remove_backslash {
    my $s = shift;
    $s =~ s/\\(.)/$1/g;
    $s;
}

sub parse_command_line {
    my $line = shift;

    my @words;
    my $after_ws;
    $line =~ s!(                                                         # 1) everything
                  (")((?: \\\\|\\"|[^"])*)(?:"|\z)(\s*)               |  #  2) open "  3) content  4) space after
                  (')((?: \\\\|\\'|[^'])*)(?:'|\z)(\s*)               |  #  5) open '  6) content  7) space after
                  ((?: \\\\|\\"|\\'|\\\s|[^"'\s])+)(\s*)              |  #  8) unquoted word  9) space after
                  \s+
              )!
                  if ($2) {
                      if ($after_ws) {
                          push @words, _remove_backslash($3);
                      } else {
                          push @words, '' unless @words;
                          $words[$#words] .= _remove_backslash($3);
                      }
                      $after_ws = $4;
                  } elsif ($5) {
                      if ($after_ws) {
                          push @words, _remove_backslash($6);
                      } else {
                          push @words, '' unless @words;
                          $words[$#words] .= _remove_backslash($6);
                      }
                      $after_ws = $7;
                  } elsif (defined $8) {
                      if ($after_ws) {
                          push @words, _remove_backslash($8);
                      } else {
                          push @words, '' unless @words;
                          $words[$#words] .= _remove_backslash($8);
                      }
                      $after_ws = $9;
                  }
    !egx;

    @words;
}

1;
# ABSTRACT: Parsing string like command line

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::CommandLine::Regexp - Parsing string like command line

=head1 VERSION

This document describes version 0.002 of Parse::CommandLine::Regexp (from Perl distribution Parse-CommandLine-Regexp), released on 2020-04-09.

=head1 DESCRIPTION

This module is an alternative to L<Parse::CommandLine>, using regexp instead of
per-character parsing technique employed by Parse::CommandLine, and which might
offer better performance in Perl (see benchmarks in
L<Bencher::Scenario::CmdLineParsingModules>).

L</"parse_command_line">, the main routine, basically split a string into
"words", with whitespaces as delimiters while also taking into account quoting
using C<"> (double-quote character) and C<'> (single-quote character) as well as
escaping using C<\> (backslash character). This splitting is similar to, albeit
simpler than, what a shell like bash does to its command-line string.

=head1 FUNCTIONS

=head2 parse_command_line

Usage:

 my @words = parse_command_line($str);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-CommandLine-Regexp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-CommandLine-Regexp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-CommandLine-Regexp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Parse::CommandLine>

L<Text::ParseWords>'s C<shellwords()>. This module also allows you to specify
which quoting characters to use.

C<parse_cmdline> in L<Complete::Bash>, which uses similar technique as this
module, but also takes into account non-whitespace word-breaking character such
as C<|>.

L<Text::CSV> and friends.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
