package String::Wildcard::Bash;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.03'; # VERSION

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       $RE_WILDCARD_BASH
                       contains_wildcard
                       convert_wildcard_to_sql
               );

# note: order is important here, brace encloses the other
our $RE_WILDCARD_BASH =
    qr(
          # non-escaped brace expression, with at least one comma
          (?P<brace>
              (?<!\\)(?:\\\\)*\{
              (?:           \\\\ | \\\{ | \\\} | [^\\\{\}] )*
              (?:, (?:  \\\\ | \\\{ | \\\} | [^\\\{\}] )* )+
              (?<!\\)(?:\\\\)*\}
          )
      |
          # non-escaped brace expression, to catch * or ? or [...] inside so
          # they don't go to below pattern, because bash doesn't consider them
          # wildcards, e.g. '/{et?,us*}' expands to '/etc /usr', but '/{et?}'
          # doesn't expand at all to /etc.
          (?P<braceno>
              (?<!\\)(?:\\\\)*\{
              (?:           \\\\ | \\\{ | \\\} | [^\\\{\}] )*
              (?<!\\)(?:\\\\)*\}
          )
      |
          (?P<class>
              # non-empty, non-escaped character class
              (?<!\\)(?:\\\\)*\[
              (?:  \\\\ | \\\[ | \\\] | [^\\\[\]] )+
              (?<!\\)(?:\\\\)*\]
          )
      |
          (?P<joker>
              # non-escaped * and ?
              (?<!\\)(?:\\\\)*[*?]
          )
      |
          (?P<sql_wc>
              # non-escaped % and ?
              (?<!\\)(?:\\\\)*[%_]
          )
      )ox;

sub contains_wildcard {
    my $str = shift;

    while ($str =~ /$RE_WILDCARD_BASH/go) {
        my %m = %+;
        return 1 if $m{brace} || $m{class} || $m{joker};
    }
    0;
}

sub convert_wildcard_to_sql {
    my $str = shift;

    $str =~ s/$RE_WILDCARD_BASH/
        if ($+{joker}) {
            if ($+{joker} eq '*') {
                "%";
            } else {
                "_";
            }
        } elsif ($+{sql_wc}) {
            "\\$+{sql_wc}";
        } else {
            $&;
        }
    /eg;

    $str;
}

1;
# ABSTRACT: Bash wildcard string routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Wildcard::Bash - Bash wildcard string routines

=head1 VERSION

This document describes version 0.03 of String::Wildcard::Bash (from Perl distribution String-Wildcard-Bash), released on 2015-09-10.

=head1 SYNOPSIS

    use String::Wildcard::Bash qw(
        $RE_WILDCARD_BASH
        contains_wildcard
        convert_wildcard_to_sql
    );

    say 1 if contains_wildcard(""));      # -> 0
    say 1 if contains_wildcard("ab*"));   # -> 1
    say 1 if contains_wildcard("ab\\*")); # -> 0

    say convert_wildcard_to_sql("foo*");  # -> "foo%"

=head1 DESCRIPTION

=for Pod::Coverage ^(qqquote)$

=head1 FUNCTIONS

=head2 contains_wildcard($str) => bool

Return true if C<$str> contains wildcard pattern. Wildcard patterns include C<*>
(meaning zero or more characters), C<?> (exactly one character), C<[...]>
(character class), C<{...,}> (brace expansion). Can handle escaped/backslash
(e.g. C<foo\*> does not contain wildcard, it's C<foo> followed by a literal
asterisk C<*>).

Aside from wildcard, bash does other types of expansions/substitutions too, but
these are not considered wildcard. These include tilde expansion (e.g. C<~>
becomes C</home/alice>), parameter and variable expansion (e.g. C<$0> and
C<$HOME>), arithmetic expression (e.g. C<$[1+2]>), history (C<!>), and so on.

Although this module has 'Bash' in its name, this set of wildcards should be
applicable to other Unix shells. Haven't checked completely though.

=head2 convert_wildcard_to_sql($str) => str

Convert bash wildcard to SQL. This includes:

=over

=item * converting unescaped C<*> to C<%>

=item * converting unescaped C<?> to C<_>

=item * escaping unescaped <%>

=item * escaping unescaped C<_>

=back

Unsupported constructs currently will be passed as-is.

=head1 SEE ALSO

L<Regexp::Wildcards> to convert a string with wildcard pattern to equivalent
regexp pattern. Can handle Unix wildcards as well as SQL and DOS/Win32. As of
this writing (v1.05), it does not handle character class (C<[...]>) and
interprets brace expansion differently than bash.

Other C<String::Wildcard::*> modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Wildcard-Bash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Wildcard-Bash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Wildcard-Bash>

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
