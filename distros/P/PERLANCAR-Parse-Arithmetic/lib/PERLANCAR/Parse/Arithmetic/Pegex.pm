package PERLANCAR::Parse::Arithmetic::Pegex;

our $DATE = '2016-06-18'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Pegex;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_arithmetic);

my $grammar = <<'...';
# Precedence Climbing grammar:
expr: add-sub
add-sub: mul-div+ % /- ( [ '+-' ])/
mul-div: power+ % /- ([ '*/' ])/
power: token+ % /- '**' /
token: /- '(' -/ expr /- ')'/ | number
number: /- ( '-'? DIGIT+ '.'? DIGIT* )/
...

{
    package
        Calculator;
    use base 'Pegex::Tree';

    sub gotrule {
        my ($self, $list) = @_;
        return $list unless ref $list;

        # Right associative:
        if ($self->rule eq 'power') {
            while (@$list > 1) {
                my ($a, $b) = splice(@$list, -2, 2);
                push @$list, $a ** $b;
            }
        }
        # Left associative:
        else {
            while (@$list > 1) {
                my ($a, $op, $b) = splice(@$list, 0, 3);
                unshift @$list,
                    ($op eq '+') ? ($a + $b) :
                    ($op eq '-') ? ($a - $b) :
                    ($op eq '*') ? ($a * $b) :
                    ($op eq '/') ? ($a / $b) :
                    die;
            }
        }
        return @$list;
    }
}

sub parse_arithmetic {
    pegex($grammar, 'Calculator')->parse($_[0]);
}

1;
# ABSTRACT: Parse arithmetic expression (Pegex version)

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::Parse::Arithmetic::Pegex - Parse arithmetic expression (Pegex version)

=head1 VERSION

This document describes version 0.004 of PERLANCAR::Parse::Arithmetic::Pegex (from Perl distribution PERLANCAR-Parse-Arithmetic), released on 2016-06-18.

=head1 SYNOPSIS

 use PERLANCAR::Parse::Pegex qw(parse_arithmetic);
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
