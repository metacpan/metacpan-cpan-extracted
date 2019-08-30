package String::Wildcard::Bash;

our $DATE = '2019-08-30'; # DATE
our $VERSION = '0.043'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       $RE_WILDCARD_BASH
                       contains_wildcard
                       convert_wildcard_to_sql
                       convert_wildcard_to_re
               );

our $re_bash_brace_element =
    qr(
          (?:(?:\\\\ | \\, | \\\{ | \\\} | [^\\\{,\}])*)
  )x;

# note: order is important here, brace encloses the other
our $RE_WILDCARD_BASH =
    qr(
          # non-escaped brace expression, with at least one comma
          (?P<bash_brace>
              (?<!\\)(?P<slashes_before_bash_brace>\\\\)*\{
              (?P<bash_brace_content>
                  $re_bash_brace_element(?:, $re_bash_brace_element )+
              )
              (?<!\\)(?:\\\\)*\}
          )
      |
          # non-escaped brace expression, to catch * or ? or [...] inside so
          # they don't go to below pattern, because bash doesn't consider them
          # wildcards, e.g. '/{et?,us*}' expands to '/etc /usr', but '/{et?}'
          # doesn't expand at all to /etc.
          (?P<literal_brace_single_element>
              (?<!\\)(?:\\\\)*\{
              $re_bash_brace_element
              (?<!\\)(?:\\\\)*\}
          )
      |
          (?P<bash_class>
              # non-empty, non-escaped character class
              (?<!\\)(?:\\\\)*\[
              (?:  \\\\ | \\\[ | \\\] | [^\\\[\]] )+
              (?<!\\)(?:\\\\)*\]
          )
      |
          (?P<bash_joker>
              # non-escaped * and ?
              (?<!\\)(?:\\\\)*(?:\*\*?|\?)
          )
      |
          (?P<sql_joker>
              # non-escaped % and ?
              (?<!\\)(?:\\\\)*[%_]
          )
      |
          (?P<literal>
              [^\\\[\]\{\}*?%_]+
          |
              .+?
          )
      )ox;

sub contains_wildcard {
    my $str = shift;

    while ($str =~ /$RE_WILDCARD_BASH/go) {
        my %m = %+;
        return 1 if $m{bash_brace} || $m{bash_class} || $m{bash_joker};
    }
    0;
}

sub convert_wildcard_to_sql {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $str = shift;

    my @res;
    my $p;
    while ($str =~ /$RE_WILDCARD_BASH/g) {
        my %m = %+;
        if (defined($p = $m{bash_brace_content})) {
            die "Cannot convert brace pattern '$p' to SQL";
        } elsif ($p = $m{bash_joker}) {
            if ($m{bash_joker} eq '*' || $m{bash_joker} eq '**') {
                push @res, "%";
            } else {
                push @res, "_";
            }
        } elsif ($p = $m{sql_joker}) {
            push @res, "\\$p";
        } elsif (defined($p = $m{literal_brace_single_element})) {
            die "Currently cannot convert brace literal '$p' to SQL";
        } elsif (defined($p = $m{bash_class})) {
            die "Currently cannot convert class pattern '$p' to SQL";
        } elsif (defined($p = $m{literal})) {
            push @res, $p;
        }
    }

    join "", @res;
}

sub convert_wildcard_to_re {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $str = shift;

    my $opt_brace   = $opts->{brace} // 1;
    my $opt_dotglob = $opts->{dotglob} // 0;

    my @res;
    my $p;
    while ($str =~ /$RE_WILDCARD_BASH/g) {
        my %m = %+;
        if (defined($p = $m{bash_brace_content})) {
            push @res, quotemeta($m{slashes_before_bash_brace}) if
                $m{slashes_before_bash_brace};
            if ($opt_brace) {
                my @elems;
                while ($p =~ /($re_bash_brace_element)(,|\z)/g) {
                    push @elems, $1;
                    last unless $2;
                }
                #use DD; dd \@elems;
                push @res, "(?:", join("|", map {
                    convert_wildcard_to_re({
                        bash_brace => 0,
                        dotglob    => $opt_dotglob || @res,
                    }, $_)} @elems), ")";
            } else {
                push @res, quotemeta($m{bash_brace});
            }

        } elsif (defined($p = $m{bash_joker})) {
            if ($p eq '?') {
                push @res, '.';
            } elsif ($p eq '*') {
                push @res, $opt_dotglob || @res ? '.*' : '[^.].*';
            } elsif ($p eq '**') {
                push @res, '.*';
            }

        } elsif (defined($p = $m{literal_brace_single_element})) {
            push @res, quotemeta($p);
        } elsif (defined($p = $m{bash_class})) {
            # XXX no need to escape some characters?
            push @res, $p;
        } elsif (defined($p = $m{sql_joker})) {
            push @res, quotemeta($p);
        } elsif (defined($p = $m{literal})) {
            push @res, quotemeta($p);
        }
    }

    join "", @res;
}

1;
# ABSTRACT: Bash wildcard string routines

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Wildcard::Bash - Bash wildcard string routines

=head1 VERSION

This document describes version 0.043 of String::Wildcard::Bash (from Perl distribution String-Wildcard-Bash), released on 2019-08-30.

=head1 SYNOPSIS

    use String::Wildcard::Bash qw(
        $RE_WILDCARD_BASH
        contains_wildcard
        convert_wildcard_to_sql
        convert_wildcard_to_re
    );

    say 1 if contains_wildcard(""));      # -> 0
    say 1 if contains_wildcard("ab*"));   # -> 1
    say 1 if contains_wildcard("ab\\*")); # -> 0

    say convert_wildcard_to_sql("foo*");  # -> "foo%"

    say convert_wildcard_to_re("foo*");   # -> "foo.*"

=head1 DESCRIPTION

=for Pod::Coverage ^(qqquote)$

=head1 VARIABLES

=head2 $RE_WILDCARD_BASH

=head1 FUNCTIONS

=head2 contains_wildcard

Usage:

 $bool = contains_wildcard($wildcard_str)

Return true if C<$str> contains wildcard pattern. Wildcard patterns include
I<joker> such as C<*> (meaning zero or more of any characters) and C<?> (exactly
one of any character), I<character class> C<[...]>, and I<brace> C<{...,}>
(brace expansion). A pattern can be escaped using a bacslash so it becomes
literal, e.g. C<foo\*> does not contain wildcard because it's C<foo> followed by
a literal asterisk C<*>.

Aside from the abovementioned wildcard patterns, bash does other types of
expansions/substitutions too, but these are not considered wildcard. These
include tilde expansion (e.g. C<~> becomes C</home/alice>), parameter and
variable expansion (e.g. C<$0> and C<$HOME>), arithmetic expression (e.g.
C<$[1+2]>), or history (C<!>).

Although this module has 'Bash' in its name, this set of wildcards should be
applicable to other Unix shells. Haven't checked completely though.

For more specific needs, e.g. you want to check if a string just contains joker
and not other types of wildcard patterns, use L</"$RE_WILDCARD_BASH"> directly.

=head2 convert_wildcard_to_sql

Usage:

 $sql_str = convert_wildcard_to_sql($wildcard_str);

Convert bash wildcard to SQL pattern. This includes:

=over

=item * converting unescaped C<*> to C<%>

=item * converting unescaped C<?> to C<_>

=item * escaping unescaped C<%>

=item * escaping unescaped C<_>

=back

Unsupported constructs will cause the function to die.

=head2 convert_wildcard_to_re

Usage:

 $re_str = convert_wildcard_to_re([ \%opts, ] $wildcard_str);

Convert bash wildcard to regular expression string.

Known options:

=over

=item * brace

Bool. Default is true. Whether to expand braces or not. If set to false, will
simply treat brace as literals.

Examples:

 convert_wildcard_to_re(            "{a,b}"); # => "(?:a|b)"
 convert_wildcard_to_re({brace=>0}, "{a,b}"); # => "\\{a\\,b\\}"

=item * dotglob

Bool. Default is false. Whether joker C<*> (asterisk) will match a dot file. The
default behavior follows bash; that is, dot file must be matched explicitly with
C<.*>.

This setting is similar to shell behavior (shopt) setting C<dotglob>.

Examples:

 convert_wildcard_to_re({}          , '*a*'); # => "[^.].*a.*"
 convert_wildcard_to_re({dotglob=>1}, '*a*'); # => ".*a.*"

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/String-Wildcard-Bash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-String-Wildcard-Bash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Wildcard-Bash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Wildcards> can also convert a string with wildcard pattern to
equivalent regexp pattern, like L</convert_wildcard_to_re>. Can handle Unix
wildcards as well as SQL and DOS/Win32. As of this writing (v1.05), it does not
handle character class (C<[...]>) and interprets brace expansion differently
than bash. String::Wildcard::Bash's C<convert_wildcard_to_re> follows bash
behavior more closely and also provides more options.

Other C<String::Wildcard::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
