package String::Wildcard::SQL;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-09'; # DATE
our $DIST = 'String-Wildcard-SQL'; # DIST
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       $RE_WILDCARD_SQL
                       contains_wildcard
               );

our $RE_WILDCARD_SQL =
    qr/
      #    (?:
      #        # non-empty, non-escaped character class
      #        (?<!\\)(?:\\\\)*\[
      #        (?:  \\\\ | \\\[ | \\\] | [^\\\[\]] )+
      #        (?<!\\)(?:\\\\)*\]
      #    )
      #|
          (?:
              # non-escaped % and _
              (?P<sql_joker>
                  (?<!\\)(?:\\\\)*[_%]
              )
          |
              (?P<literal>
                  .+?
              )
          )
      /ox;

sub contains_wildcard {
    my $str = shift;

    while ($str =~ /$RE_WILDCARD_SQL/go) {
        my %m = %+;
        return 1 if $m{sql_joker};
    }
    0;
}

1;
# ABSTRACT: SQL wildcard string routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Wildcard::SQL - SQL wildcard string routines

=head1 VERSION

This document describes version 0.030 of String::Wildcard::SQL (from Perl distribution String-Wildcard-SQL), released on 2020-02-09.

=head1 SYNOPSIS

    use String::Wildcard::SQL qw(contains_wildcard);

    say 1 if contains_wildcard(""));      # -> 0
    say 1 if contains_wildcard("ab%"));   # -> 1
    say 1 if contains_wildcard("ab\\%")); # -> 0

=head1 DESCRIPTION

=head1 VARIABLES

=head2 $RE_WILDCARD_SQL

=head1 FUNCTIONS

=head2 contains_wildcard($str[, $variant]) => bool

Return true if C<$str> contains wildcard pattern. Wildcard patterns include C<%>
(meaning zero or more characters) and C<_> (exactly one character).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Wildcard-SQL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Wildcard-SQL>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Wildcard-SQL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Wildcards> to convert a string with wildcard pattern to equivalent
regexp pattern. Can handle Unix wildcards as well as SQL and DOS/Win32.

Other C<String::Wildcard::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
