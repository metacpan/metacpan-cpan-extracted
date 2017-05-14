package Project::Euler::Problem::P001;

use Carp;
use Modern::Perl;
use Moose;

with 'Project::Euler::Problem::Base';
use Project::Euler::Lib::Types  qw/ PosInt  PosIntArray /;
use Project::Euler::Lib::MultipleCheck;

use List::Util qw/ sum /;

my $multiple_check = Project::Euler::Lib::MultipleCheck->new(
    multi_nums => [3, 5],
    check_all  => 0,
);


=head1 NAME

Project::Euler::Problem::P001 - Solutions for problem 001

=head1 VERSION

Version v0.1.2

=cut

use version 0.77; our $VERSION = qv("v0.1.2");

=head1 SYNOPSIS

L<< http://projecteuler.net/index.php?section=problems&id=1 >>

    use Project::Euler::Problem::P001;
    my $p1 = Project::Euler::Problem::P001->new;

    my $default_answer = $p1->solve;

=head1 DESCRIPTION

This module is used to solve problem #001

This simple problem simply needs to find the sum of all the numbers within a
range which are multiples of a set of integers.  The range always starts at 1
and continues B<upto> the provided input I<(1000 by default)>.  The numbers are
filtered using L<< Project::Euler::Lib::MultipleCheck >>.

=head1 Problem Attributes

=head2 Multiple Numbers

An array of positive integers that are used to filter out the number to sum

This array is always kept sorted in order to optimize the solve function

    [3, 5]

=cut

has 'multi_nums' => (
    is       => 'rw',
    isa      => PosIntArray,
    required => 1,
    default  => sub { return [3, 5] },
);
around 'multi_nums' => sub {
    my ($func, $self, $args) = @_;

    if  (ref $args) {
        $self->$func( [sort {$a <=> $b} @$args] );
    }
    else {
        $self->$func();
    }
};

=head1 SETUP

=head2 Problem Number

    001

=cut

sub _build_problem_number {
    #  Must be an int > 0
    return 1;
}


=head2 Problem Name

    Sum filtered list

=cut

sub _build_problem_name {
    #  Must be a string whose length is between 10 and 80
    return q{Sum filtered list};
}


=head2 Problem Date

    2001-10-05

=cut

sub _build_problem_date {
    return q{05 October 2001};
}


=head2 Problem Desc

If we list all the natural numbers below 10 that are multiples of 3 or 5, we
get 3, 5, 6 and 9. The sum of these multiples is 23.

Find the sum of all the multiples of 3 or 5 below 1000.

=cut

sub _build_problem_desc {
    return <<'__END_DESC';
If we list all the natural numbers below 10 that are multiples of 3 or 5, we get 3, 5, 6 and 9. The sum of these multiples is 23.

Find the sum of all the multiples of 3 or 5 below 1000.
__END_DESC
}


=head2 Default Input

The maximum value

    1,000

=cut

sub _build_default_input {
    return 1_000;
}


=head2 Default Answer

    233,168

=cut

sub _build_default_answer {
    return 233_168;
}


=head2 Has Input?

    Yes

=cut

#has '+has_input' => (default => 0);


=head2 Help Message

You can change C<< multi_nums >> to alter the way the program will function.  If you
are providing custom_input, don't forget to specify the wanted_answer if you
know it!

=cut

sub _build_help_message {
    return <<'__END_HELP';
You can change multi_nums to alter the way the program will function.  If you
are providing custom_input, don't forget to specify the wanted_answer if you
know it!
__END_HELP
}



=head1 INTERNAL FUNCTIONS

=head2 Validate Input

The restrictions on custom_input

    A positve integer

=cut

sub _check_input {
      my ( $self, $input, $old_input ) = @_;

      if ($input !~ /\D/ or $input < 1) {
          croak sprintf(q{Your input, '%s', must be all digits and >= 1}, $input);
      }
}



=head2 Solving the problem

Tell the multiple_check object what the current multi_nums is.  Then loop from
the first multi_num to the max_number (- 1) and filter all numbers that retrun
false.  Finally use the List::More util 'sum' to return the sum of the filtered
numbers.  If nothing was found return 0 rather than undef.

=cut

sub _solve_problem {
    my ($self, $max) = @_;

    #  If the user didn't give us a max, then use the default_input
    $max //= $self->default_input;

    #  Decrement the max since it's an 'upto' limit
    $max--;

    #  Tell the checker object the numbers to filter on
    $multiple_check->multi_nums($self->multi_nums);

    #  Sum the filtered numbers.  Since we know the list is sorted, we start at
    #  the first multi_num since anything less than that cannot possible return
    #  true.
    return sum(grep {$multiple_check->check($_)}
               $self->multi_nums->[0] .. $max
           )  //  0;
}


=head1 AUTHOR

Adam Lesperance, C<< <lespea at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Project::Euler::Problem::P001


=head1 ACKNOWLEDGEMENTS

L<< List::Util >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Adam Lesperance.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


#  Cleanup the Moose stuff
no Moose;
__PACKAGE__->meta->make_immutable;
1; # End of Project::Euler::Problem::P001
