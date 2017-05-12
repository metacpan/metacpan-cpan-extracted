package PERLANCAR::Parse::Arithmetic::NoHash;

our $DATE = '2016-06-18'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

my ($match_top,
    $match_add, $match_op_add,
    $match_mult, $match_op_mult,
    $match_pow,
);

use Exporter qw(import);
our @EXPORT_OK = qw(parse_arithmetic);

sub parse_arithmetic {
    state $RE =
        qr{
              (?&TOP)
              (?{
                  $match_top = $^R;
              })

              (?(DEFINE)

                  (?<TOP>
                      ^\s* (?&EXPR) \s*$
                  )

                  (?<EXPR>
                      (?&MULT_EXPR)
                      (?{
                          $match_add = $^R
                      })
                      (?: \s* ([+-])
                          (?{
                              $match_op_add = $^N;
                          })
                          \s* (?&MULT_EXPR)
                          (?{
                              $match_add = $match_op_add eq '+' ? $match_add + $^R : $match_add - $^R;
                          })
                          )*
                  )

                  (?<MULT_EXPR>
                      (?&POW_EXPR)
                      (?{
                          $match_mult = $^R;
                      })
                      (?: \s* ([*/])
                          (?{
                              $match_op_mult = $^N;
                          }) \s*
                          (?&POW_EXPR)
                          (?{
                              $match_mult = $match_op_mult eq '*' ? $match_mult * $^R : $match_mult / $^R;
                          })
                          )*
                  )

                  (?<POW_EXPR>
                      (?&TERM)
                      (?{
                          $match_pow = [$^R];
                      })
                      (?: \s* \*\* \s* (?&TERM)
                          (?{
                              unshift @$match_pow, $^R;
                          })
                      )*
                      (?{
                          # because ** is right-to-left, we collect first then
                          # apply from right to left
                          my $res = $match_pow->[0];
                          for (1..$#{$match_pow}) {
                              $res = $match_pow->[$_] ** $res;
                          }
                          $res;
                      })
                  )

                  (?<TERM>
                      \( \s* (?&EXPR)
                      (?{
                          $^R;
                      })
                      \s* \)
                  |   (?&LITERAL)
                      (?{
                          $^R;
                      })
                  )

                  (?<LITERAL>
                      (-?(?:\d+|\d*\.\d+))
                      (?{
                          $^N;
                      })
                  )
              )
      }x;
    $_[0] =~ $RE or return undef;
    $match_top;
}

1;
# ABSTRACT: Parse arithmetic expmatchsion

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Parse::Arithmetic::NoHash - Parse arithmetic expmatchsion

=head1 VERSION

This document describes version 0.004 of PERLANCAR::Parse::Arithmetic::NoHash (from Perl distribution PERLANCAR-Parse-Arithmetic), released on 2016-06-18.

=head1 SYNOPSIS

 use PERLANCAR::Parse::Arithmetic::NoHash qw(parse_arithmetic);
 say parse_arithmetic('1 + 2 * 3'); # => 7

=head1 DESCRIPTION

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
