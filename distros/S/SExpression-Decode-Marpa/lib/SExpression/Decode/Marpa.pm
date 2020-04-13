package SExpression::Decode::Marpa;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-10'; # DATE
our $DIST = 'SExpression-Decode-Marpa'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use MarpaX::Simple qw(gen_parser);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(from_sexp);

my $parser = gen_parser(
    grammar => <<'EOF',
:default         ::= action => do_array

:start           ::= value

value            ::= number_int_radix action => do_number_int_radix
                   | number_int_hex action => do_number_int_hex
                   | number_int_oct action => do_number_int_oct
                   | number_int_bin action => do_number_int_bin
                   | number_inf_nan action => do_number_inf_nan
                   | number_int action => do_first
                   | number_float action => do_first
                   | char_unescaped action => do_char_unescaped
                   | char_escaped_1char action => do_char_escaped_1char
                   | char_escaped_ctrl action => do_char_escaped_ctrl
                   | string action => do_first
                   | list action => do_first
                   | vector action => do_first
                   | 't' action => do_true
                   | 'nil' action => do_undef
                   | atom action => do_first

opt_dec_digits     ~ [0-9]*
dec_digits         ~ [0-9]+
hex_digits         ~ [0-9A-Fa-f]+
oct_digits         ~ [0-7]+
bin_digits         ~ [01]+
alphanums          ~ [0-9A-Za-z]+
sign               ~ [+-]
r                  ~ [rR]
x                  ~ [xX]
o                  ~ [oO]
b                  ~ [bB]
e                  ~ [eE]

number_int_radix   ~ '#' dec_digits r sign alphanums
                   | '#' dec_digits r      alphanums

number_int_hex     ~ '#' x sign hex_digits
                   | '#' x      hex_digits

number_int_oct     ~ '#' o sign oct_digits
                   | '#' o      oct_digits

number_int_bin     ~ '#' b sign bin_digits
                   | '#' b      bin_digits

number_int         ~ sign dec_digits
                   |      dec_digits

unsigned_decimal   ~ opt_dec_digits '.' dec_digits
                   | dec_digits '.' opt_dec_digits
decimal            ~ sign unsigned_decimal
                   |      unsigned_decimal
inf                ~ 'INF'
nan                ~ 'NaN'

number_inf_nan     ~ decimal e '+' inf
                   | decimal e '+' nan

exp                ~ e sign dec_digits
                   | e      dec_digits

number_float       ~ decimal
                   | decimal exp

ch1                ~ [^\\\(]
char_unescaped     ~ '?' ch1

ch2                ~ [^\^C]
char_escaped_1char ~ '?\' ch2

alpha              ~ [A-Za-z]
ch3                ~ 'C-'
                   | '^'
char_escaped_ctrl  ~ '?\' ch3 alpha

string           ::= string_lexeme action => do_string
string_lexeme      ~ quote in_string quote
quote              ~ ["]
in_string          ~ in_string_char*
in_string_char     ~ [^"\\]
                   | '\' [\d\D]

atom               ~ [^\\\[\]\(\)\s".#]+

vector           ::= ('[' ']')
                   | ('[') list_elems_dot   (']') action => do_first
                   | ('[') list_elems_nodot (']') action => do_first

list             ::= ('(' ')')
                   | ('(') list_elems_dot   (')') action => do_first
                   | ('(') list_elems_nodot (')') action => do_first

list_elems_nodot ::= value+
list_elems_dot   ::= list_elems_nodot ('.') value action => do_list_elems_dot

whitespace         ~ [\s]+
:discard           ~ whitespace

EOF
    actions => {
        do_array  => sub { shift; [@_] },
        do_join   => sub { shift; join "", @_ },
        do_hash   => sub { shift; +{map {@$_} @{ $_[0] } } },
        do_first  => sub { $_[1] },
        do_second => sub { $_[2] },
        do_number_int_radix => sub {
            require Math::NumberBase;

            my ($base, $num) = $_[1] =~ /\A#([0-9]+)[rR](\w+)/ or die;
            $_[1] =~ s/\A([+-]?)//;
            my $sign = $1 // '';
            ($sign eq '-' ? -1:1) * Math::NumberBase->new($base)->to_decimal(lc $num);
        },
        do_number_int_hex => sub {
            my $str = $_[1];
            $str =~ s/\A#[xX]//;
            $str =~ s/\A([+-]?)//;
            my $sign = $1 // '';
            ($sign eq '-' ? -1:1) * hex($str);
        },
        do_number_int_oct => sub {
            my $str = $_[1];
            $str =~ s/\A#[oO]//;
            $str =~ s/\A([+-]?)//;
            my $sign = $1 // '';
            ($sign eq '-' ? -1:1) * oct($str);
        },
        do_number_int_bin => sub {
            my $str = $_[1];
            $str =~ s/\A#[bB]//;
            $str =~ s/\A([+-]?)//;
            my $sign = $1 // '';
            ($sign eq '-' ? -1:1) * oct("0b$str");
        },
        do_number_inf_nan => sub {
            my $str = $_[1];
            $str =~ s/\A([+-]?)//;
            my $sign = $1 // '';
            $str =~ /NaN/ ? "NaN" : ($sign eq '-' ? -1:1) * "Inf";
        },
        do_char_unescaped => sub {
            substr($_[1], -1, 1);
        },
        do_char_escaped_1char => sub {
            my $char = substr($_[1], -1, 1);
            if    ($char eq 'a') { return chr(7) }
            elsif ($char eq 'b') { return chr(8) }
            elsif ($char eq 't') { return chr(9) }
            elsif ($char eq 'n') { return chr(10) }
            elsif ($char eq 'v') { return chr(11) }
            elsif ($char eq 'f') { return chr(12) }
            elsif ($char eq 'r') { return chr(13) }
            elsif ($char eq 'e') { return chr(27) }
            elsif ($char eq 's') { return chr(32) }
            elsif ($char eq 'd') { return chr(127) }
            else { return $char }
        },
        do_char_escaped_ctrl => sub {
            my $char = lc substr($_[1], -1, 1);
            return chr(ord($char) - 97+1);
        },
        do_string => sub {
            my $str0 = substr($_[1], 1, length($_[1])-2);
            # XXX support \x... and \... octal
            $str0 =~ s{\\(C-|^)([A-Za-z]) | # 1 2 control
                       \\x([0-91-f]{1,2}) | # 3 hex
                       \\([0-7]{1,3})     | # 4 octal
                       \\([^C\^])}          # 5 other single char
                      {
                          if    (defined $1) { chr(ord(lc $2) - 97+1) }
                          elsif (defined $3) { chr(hex $3) }
                          elsif (defined $4) { chr(oct $4) }
                          else    {
                              my $c = $5;
                              if    ($c eq 'a') { return chr(7) }
                              elsif ($c eq 'b') { return chr(8) }
                              elsif ($c eq 't') { return chr(9) }
                              elsif ($c eq 'n') { return chr(10) }
                              elsif ($c eq 'v') { return chr(11) }
                              elsif ($c eq 'f') { return chr(12) }
                              elsif ($c eq 'r') { return chr(13) }
                              elsif ($c eq 'e') { return chr(27) }
                              elsif ($c eq 's') { return chr(32) }
                              elsif ($c eq 'd') { return chr(127) }
                              else { $c }
                          }
                      }egx;
            $str0;
        },
        do_list_elems_dot  => sub { [@{ $_[1] }, $_[2]] },
        do_undef  => sub { undef },
        do_true   => sub { 1 },
        do_empty_string => sub { '' },
    },
);

sub from_sexp {
    $parser->(shift);
}

1;
# ABSTRACT: S-expression parser using Marpa

__END__

=pod

=encoding UTF-8

=head1 NAME

SExpression::Decode::Marpa - S-expression parser using Marpa

=head1 VERSION

This document describes version 0.002 of SExpression::Decode::Marpa (from Perl distribution SExpression-Decode-Marpa), released on 2020-04-10.

=head1 SYNOPSIS

 use SExpression::Decode::Marpa qw(from_sexp);
 my $data = from_sexp(q|((foo . 1) (bar . 2))|); # => [[foo=>1], [bar=>2]]

=head1 DESCRIPTION

B<EARLY RELEASE.>

Todo: wrap special values (e.g. nil, t, keyword symbol :foo, other symbols,
vectors, lists). Convert to alist when appropriate.

=head1 FUNCTIONS

=head2 from_sexp

Usage:

 my $data = from_sexp($str);

Decode S-expresion in C<$str>. Dies on error.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SExpression-Decode-Marpa>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SExpression-Decode-Marpa>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SExpression-Decode-Marpa>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::SExpression>, another S-expression parser based on L<Parse::Yapp>.

L<SExpression::Decode::Regexp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
