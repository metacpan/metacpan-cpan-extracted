package Project::Euler::Lib::MultipleCheck;

use Modern::Perl;
use Moose;
use MooseX::Method::Signatures;

use List::MoreUtils qw/ any  all /;

use Project::Euler::Lib::Types qw/ PosInt  PosIntArray /;


=head1 NAME

Project::Euler::Lib::MultipleCheck - Determine if an integer is divisible by an array of numbers

=head1 VERSION

Version v0.1.1

=cut

use version 0.77; our $VERSION = qv("v0.1.1");


=head1 SYNOPSIS

Module that is used to determine if a number is a multiple of any (or
optionally all) numbers in an array

    use Project::Euler::Lib::MultipleCheck;
    my $multi_check = Project::Euler::Lib::MultipleCheck->new(
        multi_nums => [2, 3, 5],
        check_all  => 0,  # Default
    );

    $is_divisible = $multi_check->check(15);


=head1 DESCRIPTION

It is often useful to determine if a number is divisible by a set of numbers.
A basic example is to determine if an integer is even by testing it against the
array C<< [2] >>.  A boolean is also used to determining if the number should
be divisible by all of the integers in the array or if any will suffice.

The array of integers is always sorted to maximize efficiency (lower numbers
have a better chance of matching over higher ones)


=head1 VARIABLES

The numbers to test against

    multi_nums ( ArrayRef[PosInts] )

The check number must be divisible by all numbers in the array

    check_all  ( Bool )

=cut

has 'multi_nums' => (
    is          => 'rw',
    isa         => PosIntArray,
    lazy_build  => 1,
    required    => 1,
);

has 'check_all' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);



=head1 FUNCTIONS

=head2 check

Function that returns a Boolean if the given number passes the checks

    my $check = Project::Euler::Lib::MultipleCheck->new(
        multi_nums => [3, 5],
        check_all  => 0,
    );

    OK      $multi_check->check(9);
    NOT OK  $multi_check->check(11);


    $multi_check->check_all(1);

    OK      $multi_check->check(15);
    NOT OK  $multi_check->check(10);


    DIES    $multi_check->multi_nums([0, 1]);  # Multi_nums must all be positive
    DIES    $multi_check->multi_nums(2, 9);    # Multi nums must be an array ref

    DIES    $multi_check->check('two');        # Can't check a string!

=cut


method check (PosInt $num) {
    my $multi_nums = $self->multi_nums;
    return  $self->check_all  ?  all {($num % $_) == 0} @$multi_nums
                              :  any {($num % $_) == 0} @$multi_nums
}




=head1 AUTHOR

Adam Lesperance, C<< <lespea at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Project::Euler::Lib::MultipleCheck


=head1 COPYRIGHT & LICENSE

Copyright 2009 Adam Lesperance.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no Moose;
1; # End of Project::Euler::Lib::MultipleCheck
