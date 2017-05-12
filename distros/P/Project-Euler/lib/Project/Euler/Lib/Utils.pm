use warnings;
use strict;
package Project::Euler::Lib::Utils;
BEGIN {
  $Project::Euler::Lib::Utils::VERSION = '0.20';
}

use Modern::Perl;
use Carp;

use List::MoreUtils qw/ any  all /;

#  Export our functions with tags
use Exporter::Easy (
    TAGS => [
        fibs => [qw/ fib_generator  n_fibs /],
        list => [qw/ multiple_check /],
        all  => [qw/ :fibs /],
    ],
    #OK => [qw( some other stuff )],
);


#  Initial array of fib #s
my @fibs = (1, 1);


#ABSTRACT: Collection of helper utilities for project euler problems





sub fib_generator {
    my ($a, $b) = 0..1;
    return sub {
        #  Swap the 2 numbers
        ($a, $b) = ($b, $a+$b);

        #  And return the newly generated first one
        $a;
    }
}




sub n_fibs {
    my ($num) = @_;

    #  Turn $num into a string signifying undef to prepare for the error message.
    $num //= 'UNDEFINED';

    #  If a number > 0 was not passed, then confess with an error
    confess "You must provide an integer > 0 to n_fibs.  You provided: '$num'"
        unless  $num =~ /\A\d+\z/  and  $num > 0;

    #  If we've already calculated the fib the user wants, then simply return
    #  that value now

    if  (scalar @fibs >= $num) {
        #  User is using 1-base not 0-base
        $num--;

        #  If the user wants an array, then take a slice, otherwise just grab that element.
        return  wantarray  ?  @fibs[0..$num]  :  $fibs[$num];
    }

    #  If not, then we'll take a different course of action depending on whether
    #  the user wants an array or not.  I don't just fill out the cache because
    #  if the user wanted a huge value, then that would be impractical.  I could
    #  do some logic around the # requested but I'm going to postpone that for
    #  now until I have an all-around bettter caching solution.
    elsif  (wantarray) {
        #  Calculate how many values we already have
        $num -= @fibs;

        #  Increase the size of the array until it's the size we want.
        push @fibs, $fibs[-2] + $fibs[-1]  while  $num--;

        return @fibs;
    }

    #  Otherwise we'll just start with the last 2 known fibs and go from there
    #  till we get to the # we want.
    else {
        #  User is using 1-base not 0-base
        $num--;

        #  Calculate the fibs until we find the one we want.
        my ($a, $b) = @fibs[-2, -1];
        ($a, $b) = ($b, $a+$b)  while  $num--;

        return $a;
    }
}




sub multiple_check {
    my ($num, $ranges, $all) = @_;
    #  Turn $num into a string signifying undef to prepare for the error message.
    $num //= 'UNDEFINED';

    #  If a number > 0 was not passed as the num range, then confess with an error
    confess "You must provide an integer > 0 to filter_ranges for the first arg.  You provided: '$num'"
        unless  $num !~ /\D/  and  $num > 0;

    confess "You must provide an array ref of integers as the second arg to filter_ranges!"
        unless   defined $ranges            #  Makes sure ranges is defined
            and  ref $ranges eq 'ARRAY'     #  Makes sure ranges is an array_ref
            and  ((grep  {     !$_          #  Ensure none of the values are either undef or 0
                           or  $_ =~ /\D/   #    or ontains something that isn't a digit
                        }
                        @$ranges)  ==  0);


    #  We only want need to check the values that are > than the number to
    #  check, since a number can not be divisible by another number that is
    #  greater than itself.
    my @ranges = grep {$_ <= $num} @$ranges;

    #  If the user wanted to check all of the numbers, then return "false" if
    #  any number got filtered out
    return 0  if  ($all  and  scalar @ranges != scalar @$ranges);

    #  If there are no (remaining) numbers to filter on, then we'll return
    #  failure
    return 0  unless  scalar @ranges;


    #  If the user wants the values that matched (and isn't filtering on all of
    #  them) then we need to keep track of which ones matched so we have to use
    #  a slower native-perl version
    if  (wantarray  and  !$all) {
        my @return_range;
        for  my $mult  (@ranges) {
            push @return_range, $mult  if  $num % $mult == 0;
        }
        return @return_range;
    }


    #  Otherwise we can use List::MoreUtils's fast XS utils to do the checking
    #  for us
    my $status  =  $all  ?  all {($num % $_) == 0} @ranges
                         :  any {($num % $_) == 0} @ranges
                         ;


    #  Take the appropriate action depending on the context we're in
    if  (wantarray) {
        return  $status  ?  @ranges  :  ();
    }
    else {
        return  $status  ?  1  :  0;
    }
}



1; # End of String::Palindrome

__END__
=pod

=head1 NAME

Project::Euler::Lib::Utils - Collection of helper utilities for project euler problems

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Project::Euler::Lib::Utils qw/ :all /;

=head1 EXPORTS

=head2 :fibs

=over 4

=item *

fib_generator

=item *

n_fibs

=back

=head2 :list

=over 4

=item *

filter_ranges

=back

=head2 :all

=over 4

=item *

:fibs

=item *

:list

=back

=head1 FUNCTIONS

=head2 fib_generator

This returns a clojure that returns the next successive fib number with each call

=head3 Example

    my $fib = fib_generator;

    #  Manually create the first 4 fibs
    my @fibs;
    push @fibs, $fib->()  for  1..4;

=head2 n_fibs

The returns either the first 'n' fibs or the nth fib if called in scalar
context.  If only the nth fib is used, then no memory is used to store the
previous fibs and it should run very fast.  For now this does some very
primitive caching but will have to be improved in the future.

This also does not currently use Math::BigInt so if a large # is requested it
may not be 100% accurate.  This will be fixed once I decide upon a caching
solution.

=head3 Parameters

=over 4

=item 1

Fib number (or list up to a number) that you would like returned.

=back

=head3 Example

    #  Get the first 4 fib numbers
    my @fibs = n_fibs( 4 );

    #  Just get the last one
    my $fourth_fib = n_fibs( 4 );

    $fibs[-1] == $fourth_fib;

=head2 multiple_check

Check to see if a number is evenly divisible by one or all of a range of numbers.

=head3 Parameters

=over 4

=item 1

Number to check divisibility on             (I<must be greater than 0>)

=item 2

Range of numbers to check for divisibility  (I<all must be grater than 0>)

=item 3

Boolean to check all range numbers          (B<optional>)

=back

=head3 Example

    my $is_divisible     = multiple_check(15, [2, 3, 5], 0);
    my $is_divisible2    = multiple_check(15, [2, 3, 5]);
    my $is_not_divisible = multiple_check(10, [3, 6, 7]);

    my $is_all_divisible     = multiple_check(30, [2, 3, 5], 1);
    my $is_not_all_divisible = multiple_check(15, [2, 3, 5], 1);

    my @div_by = multiple_check(15, [2, 3, 5]);
    @div_by ~~ (3, 5) == 1;


    my $num = 3;
    my $is_prime = !multiple_check($num, [2..sqrt($num)]);

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

