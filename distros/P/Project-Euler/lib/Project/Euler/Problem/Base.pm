use strict;
use warnings;
package Project::Euler::Problem::Base;
BEGIN {
  $Project::Euler::Problem::Base::VERSION = '0.20';
}

use Modern::Perl;
use namespace::autoclean;

use Moose::Role;
use Project::Euler::Lib::Types  qw/ ProblemLink  ProblemName  PosInt  MyDateTime /;

use Carp;
use Readonly;

Readonly::Scalar my $BASE_URL => q{http://projecteuler.net/index.php?section=problems&id=};


#ABSTRACT: Abstract class that the problems will extend from



has 'problem_number' => (
    is         => 'ro',
    isa        => PosInt,
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_problem_number';



has 'problem_name' => (
    is         => 'ro',
    isa        => ProblemName,
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_problem_name';



has 'problem_date' => (
    is         => 'ro',
    isa        => MyDateTime,
    coerce     => 1,
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_problem_date';



has 'problem_desc' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_problem_desc';



has 'problem_link_base' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy       => 1,
    init_arg   => undef,
    default    => $BASE_URL,
);



has 'problem_link' => (
    is         => 'ro',
    isa        => ProblemLink,
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
sub _build_problem_link {
    my ($self) = @_;
    return $BASE_URL . $self->problem_number;
}



has 'default_input' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_default_input';



has 'default_answer' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_default_answer';



has 'has_input' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 1,
    init_arg => undef,
);



has 'use_defaults' => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);




has 'help_message' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
    init_arg   => undef,
);
requires '_build_help_message';



has 'custom_input'  => (
    is         => 'rw',
    isa        => 'Str',
    required   => 0,
    trigger    => \&_check_input_stub,
);
sub _check_input_stub {
    $_[0]->_check_input(@_);
}



has 'custom_answer'  => (
    is         => 'rw',
    isa        => 'Str',
    required   => 0,
);




has 'solved_status'  => (
    is         => 'ro',
    isa        => 'Maybe[Bool]',
    writer     => '_set_solved_status',
    required   => 0,
    init_arg   => undef,
);



has 'solved_answer'  => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    writer     => '_set_solved_answer',
    required   => 0,
    init_arg   => undef,
);



has 'solved_wanted'  => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    writer     => '_set_solved_wanted',
    required   => 0,
    init_arg   => undef,
);




has 'more_info' => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    writer     => '_set_more_info',
    lazy       => 1,
    default    => q{},
    init_arg   => undef,
);





requires '_check_input';
requires '_solve_problem';




sub solve {
    my ($self, $cust_input, $cust_answer) = @_;
    my $answer;

    #  If the user provided some input, then we'll won't use the defaults
    my $defaults  =  defined $cust_input  ?  0  :  $self->use_defaults;

    #  If no input was given as an arg, try to get it from the current object.
    #  This may still return an undef but that's alright
    $cust_input  //= $self->custom_input;
    $cust_answer //= $self->custom_answer;


    #  If the problem takes input, determine the appropriate course of action
    if ( $self->has_input ) {
        #  The user wants to use the defaults so don't pass anything
        if ( $defaults ) {
            $answer = $self->_solve_problem;
        }
        #  Pass the user input to the subroutine (if it's defined!)
        elsif (defined $cust_input) {
            $answer = $self->_solve_problem( $cust_input );
        }
        #  The user tried to use a cutsom input string to
        #  solve the problem but hasn't defined it yet!
        else {
            confess q{You tried to use custom inputs to solve the problem, but it has not been set yet}
        }
    }

    #  There are no paramaters to pass!
    else {
        $answer = $self->_solve_problem;
    }


    # Determine what the expected answer should be, depending on whether the
    # defaults were used or not.
    my $wanted = $defaults  ?  $self->default_answer  :  $cust_answer;

    #  Determine if the given answer was correct.
    #  Use a blank string rather than undef for the given and expected answer
    $answer //= q{};  $wanted //= q{};

    #  See if the answer was correct
    my $status  =  $answer eq $wanted;

    #  Save the answer, wanted, and status
    $self->_set_solved_answer($answer);
    $self->_set_solved_wanted($wanted);
    $self->_set_solved_status($status);


    #  Return either the status, answer, and wanted or if the user just
    #  expects a scalar, the found answer
    return  wantarray  ?  ($status, $answer, $wanted)  :  $answer;
}




sub status {
    my ($self) = @_;
    my $out;

    #  Extract the status and solved and expected answer
    my ($answer, $wanted, $status) =
        @{$self}{qw/ solved_answer  solved_wanted  solved_status /};

    #  If the status isn't even defined then the problem wasn't ever run
    if (!defined $status) {
        $out = q{It appears that the problem has yet to be solved once.};
    }

    #  Otherwise print a message if it failed or not
    else {
        $out = sprintf(q{The last run was%s successful!  The answer expected was '%s' %s the answer returned was '%s'},
            $status ? q{} : ' not', $wanted, $status ? 'and' : 'but', $answer
        );
    }

    if ($self->has_more_info) {
        $out .= sprintf(qq{\n%s}, $self->more_info);
    }


    return $out;
}



1; # End of Project::Euler::Problem::Base

__END__
=pod

=head1 NAME

Project::Euler::Problem::Base - Abstract class that the problems will extend from

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    package Project::Euler::Problem::P999;
    use Moose;
    with 'Project::Euler::Problem::Base';

=head1 DESCRIPTION

To ensure that each problem class performs a minimum set of functions, this
class will define the basic subroutines and variables that every object must
implement.

=head1 ATTRIBUTES

=head2 problem_number

Problem number on the problem's website

=over 4

=item Isa

PosInt

=item Requires

_build_problem_number

=back

=head2 problem_name

Short name for the problem designated by the module author

=over 4

=item Isa

ProblemName

=item Requires

_build_problem_name

=back

=head2 problem_date

Date the problem was posted on the website

=over 4

=item Isa

MyDateTime

=item Requires

_build_problem_date

=back

=head2 problem_desc

Description posted on the problem's website

=over 4

=item Isa

Str

=item Requires

_build_problem_desc

=back

=head2 problem_link_base

The base URL for the problems on L<< http://projecteuler.net >>

=over 4

=item Isa

Str

=item Default

http://projecteuler.net/index.php?section=problems&id=

=back

=head2 problem_link

URL to the problem's homepage

=over 4

=item Isa

ProblemLink

=item Is

$self->problem_link_base . $self->problem_number

=back

=head2 default_input

Default input posted on the problem's website

=over 4

=item Isa

Str

=item Requires

_build_default_input

=back

=head2 default_answer

Answer for the default input

=over 4

=item Isa

Str

=item Requires

_build_default_answer

=back

=head2 has_input

Indicates if the problem takes any input from the user

=over 4

=item Isa

Bool

=back

=head2 use_defaults

Whether the problem should use the default input/answer strings

=over 4

=item Isa

Bool

=back

=head2 help_message

A message to assist the user in using the specific problem

=over 4

=item Isa

Str

=item Requires

_build_help_message

=back

=head2 custom_input

The user-provided input to the problem

=over 4

=item Isa

Str

=back

=head2 custom_answer

The user-provided answer to the problem

=over 4

=item Isa

Str

=back

=head2 solved_status

Flag to indicate if the last run was successful

=over 4

=item Isa

Maybe[Bool

=back

=head2 solved_answer

The solved answer from the previous run

=over 4

=item Isa

Maybe[Str]

=back

=head2 solved_wanted

The wanted answer from the previous run

=over 4

=item Isa

Maybe[Str]

=back

=head2 more_info

Any additional information the last run provided

=over 4

=item Isa

Maybe[Str]

=back

=head1 ABSTRACT FUNCTIONS

These two functions must be overridden by the extending class

=head2 _check_input

Ensure the input provided by the user is compliant

=head2 _solve_problem

This is the main function which will return the status/answer for a problem

=head1 PROVIDED FUNCTIONS

=head2 solve

This function will point to the internal function that actually solves the
problem.  Depending on the object attributes that are set, it uses either the
default or provided inputs (if they are required).  It returns the answer as a
string in scalar context, or an array containing the status, calculated answer,
and expected answer.  If values are passed to the function, then they are taken
as the custom_input and custom_answer respectively.  This also turns off
use_defaults temporarily.

=head3 Example

    my $problem_1  = Project::Euler::Problem::P001->new();
    my $p1_def_answer = $problem_1->solve;

    $problem_1->custom_input  => (42);
    $problem_1->custom_answer => (24);
    $problem_1->use_defaults  => (0);

    my $p1_custom_answer = $problem_1->solve;

    my ($p1_status, $p1_answer, $p1_expected) = $problem_1->solve;


    #  OR  #


    my $problem_2 = Project::Euler::Problem::P002->new();
    my $p2_def_answer = $problem_2->solve;

    #  Providing input automatically stops using the defaults
    my $p2_custom_answer = $problem_2->solve( 1, 4 );  # Provide custom input & answer

    my ($p2_status, $p2_answer, $p2_expected) = $problem_2->solve;

=head2 status

This function simply returns a nice, readable status message that tells you the
outcome of the last run of the module.

=head3 Example

    my $problem_1  = Project::Euler::Problem::P001->new();
    $problem_1->solve;
    my $message = $problem_1->last_run_message;

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

