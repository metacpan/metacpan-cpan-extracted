use strict;
use warnings;
package Project::Euler::Problem::P004;
BEGIN {
  $Project::Euler::Problem::P004::VERSION = '0.20';
}

use Carp;
use Modern::Perl;
use Moose;

use String::Palindrome qw/ is_palindrome /;

with 'Project::Euler::Problem::Base';
use Project::Euler::Lib::Types  qw/ PosInt /;


#ABSTRACT: Solutions for problem 004 - Largest palindrome from prods



sub _build_problem_number {
    #  Must be an int > 0
    return 4;
}



sub _build_problem_name {
    return q{Largest palindrome from prods};
}



sub _build_problem_date {
    return q{16 November 2001};
}



sub _build_problem_desc {
    return <<'__END_DESC';

A palindromic number reads the same both ways. The largest palindrome made from
the product of two 2-digit numbers is 9009 = 91 & 99. Find the largest
palindrome made from the product of two 3-digit numbers.

__END_DESC
}



sub _build_default_input {
    return 3;
}



sub _build_default_answer {
    return 906609;
}


#has '+has_input' => (default => 0);



sub _build_help_message {

    return <<'__END_HELP';

There is little to no customization for this problem, simply tell it what you
want the number of digits to be

__END_HELP

}




sub _check_input {
    my ( $self, $input, ) = @_;

    if ($input !~ /\D/ or $input < 1) {
        croak sprintf(q{Your input, '%s', must be all digits and >= 1}, $input);
    }
}




sub _solve_problem {
    my ($self, $length) = @_;

    $length //= $self->default_input;

    my $max  = 0;
    my @nums;

    #  Calculate the numbers to iterate from
    my $high = (10 ** $length) - 1;
    my $low  =  10 ** ($length - 1);

    OUTER:
    #  Now start a loop, starting from the top
    for  (my $i = $high;  $i >= $low;  $i--) {
        #  If the current number squared is less than the max, then no greater
        #  number will ever be calculated so exit the loop
        last OUTER  if  ($i ** 2) < $max;

        #  Otherwise loop through all of the sub-digits, looking for a new max
        for  (my $j = $i;  $j >= $low;  $j--) {
            my $prod = $i * $j;
            #  If a new max is found, then store it and numbers that made it
            if ($prod > $max  and  is_palindrome($prod)) {
                $max = $prod;
                @nums = ($i, $j);
            }
        }
    }

    #  Store the numbers used to generate the max in more info
    $self->_set_more_info(sprintf('The numbers were %d and %d', $nums[0], $nums[1]));
    return $max;
}


__PACKAGE__->meta->make_immutable;
1; # End of Project::Euler::Problem::P004

__END__
=pod

=head1 NAME

Project::Euler::Problem::P004 - Solutions for problem 004 - Largest palindrome from prods

=head1 VERSION

version 0.20

=head1 HOMEPAGE

L<< http://projecteuler.net/index.php?section=problems&id=4 >>

=head1 SYNOPSIS

    use Project::Euler::Problem::P004;
    my $p4 = Project::Euler::Problem::P004->new;

    my $default_answer = $p4->solve;

=head1 DESCRIPTION

This module is used to solve problem #004

Given the length of ints to iterate through, we will find the largest product
that produces a palindrome.

=head1 SETUP

=head2 Problem Number

    004

=head2 Problem Name

    Largest palindrome from prods

=head2 Problem Date

    16 November 2001

=head2 Problem Desc

A palindromic number reads the same both ways. The largest palindrome made from
the product of two 2-digit numbers is 9009 = 91 & 99.  Find the largest
palindrome made from the product of two 3-digit numbers.

=head2 Default Input

The number of digits the numbers should have

=head2 Default Answer

    906609

=head2 Has Input?

    Yes

=head2 Help Message

There is little to no customization for this problem, simply tell it what you
want the number of digits to be

=head1 INTERNAL FUNCTIONS

=head2 Validate Input

The restrictions on custom_input

    A positive integer

=head2 Solving the problem

First we will calculate the int that we will be using to loop on.  Then we will
iterate backwards from that number to the smallest int the same number of digits
(ie 999 down to 100).  The inner loop will always start with the current outer
loop so no duplicate products are tested.

If we ever iterate the outer loop down and that number squared is less than the
max number found, then we will stop since it is impossible for any larger
number to ever be generated.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

