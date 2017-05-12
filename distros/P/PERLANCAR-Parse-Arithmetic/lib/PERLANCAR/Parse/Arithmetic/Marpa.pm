package PERLANCAR::Parse::Arithmetic::Marpa;

our $DATE = '2016-06-18'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use MarpaX::Simple qw(gen_parser);

use Exporter qw(import);
our @EXPORT_OK = qw(parse_arithmetic);

sub parse_arithmetic {
    state $parser = gen_parser(
        grammar => <<'_',
:default             ::= action=>::first
lexeme default         = latm=>1
:start               ::= expr

expr                 ::= literal
                       | '(' expr ')'                    action=>paren assoc=>group
                      || expr '**' expr                  action=>pow   assoc=>right
                      || expr '*' expr                   action=>mult
                       | expr '/' expr                   action=>div
                      || expr '+' expr                   action=>add
                       | expr '-' expr                   action=>subtract

literal                ~ digits
                       | sign digits
                       | digits '.' digits
                       | sign digits '.' digits
digits                 ~ [\d]+
sign                   ~ [+-]
:discard               ~ ws
ws                     ~ [\s]+
_
        actions => {
            add => sub {
                my $h = shift;
                $_[0] + $_[2];
            },
            subtract => sub {
                my $h = shift;
                $_[0] - $_[2];
            },
            mult => sub {
                my $h = shift;
                $_[0] * $_[2];
            },
            div => sub {
                my $h = shift;
                $_[0] / $_[2];
            },
            pow => sub {
                my $h = shift;
                $_[0] ** $_[2];
            },
            paren => sub {
                my $h = shift;
                $_[1];
            },
        },
        trace_terminals => $ENV{DEBUG},
        trace_values    => $ENV{DEBUG},
    );

    $parser->($_[0]);
}

1;
# ABSTRACT: Parse arithmetic expression (Marpa version)

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Parse::Arithmetic::Marpa - Parse arithmetic expression (Marpa version)

=head1 VERSION

This document describes version 0.004 of PERLANCAR::Parse::Arithmetic::Marpa (from Perl distribution PERLANCAR-Parse-Arithmetic), released on 2016-06-18.

=head1 SYNOPSIS

 use PERLANCAR::Parse::Arithmetic qw(parse_arithmetic);
 say parse_arithmetic('1 + 2 * 3'); # => 7

=head1 DESCRIPTION

This is a temporary module.

=head1 FUNCTIONS

=head2 parse_arithmetic

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-Parse-Arithmetic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-Parse-Arithmetic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-Parse-Arithmetic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
