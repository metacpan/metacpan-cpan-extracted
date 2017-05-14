package Project::Euler::Problem::Base;

use Modern::Perl;
use Moose::Role;

use Project::Euler::Lib::Types  qw/ ProblemLink  ProblemName  PosInt  MyDateTime /;

use Carp;
use Readonly;

Readonly::Scalar my $BASE_URL => q{http://projecteuler.net/index.php?section=problems&id=};


=head1 NAME

Project::Euler::Problem::Base - Abstract class that the problems will extend from

=head1 VERSION

Version v0.2.2

=cut

use version 0.77; our $VERSION = qv("v0.2.2");


=head1 SYNOPSIS

    use Moose;
    with Project::Euler::Problem::Base;

=head1 DESCRIPTION

To ensure that each problem class performs a minimum set of functions, this
class will define the basic subroutines and variables that every object must
implement.


=head1 VARIABLES

These are the base variables that every module should have.  Because each
extending module will be changing these values, we will force them to create
functions which will set the attributes.  We also declare the init_arg as undef
so nobody creating an instance of the problem can over-write the values.

    problem_number ( PosInt      )  # Problem number on projecteuler.net
    problem_name   ( ProblemName )  # Short name given by the module author
    problem_date   ( MyDateTime  )  # Date posted on projecteuler.net
    problem_desc   ( str         )  # Description posted on projecteuler.net
    problem_link   ( ProblemLink )  # URL to the problem's homepage

    default_input  ( str         )  # Default input posted on projecteuler.net
    default_answer ( str         )  # Default answer to the default input

    has_input      ( boolean     )  # Some problems may not have use for input
    use_defaults   ( boolean     )  # Use the default inputs

    custom_input   ( str         )  # User provided input to the problem
    custom_answer  ( str         )  # User provided answer to the problem

    solve_status   ( boolean     )  # True means it was valid
    solve_answer   ( str         )  # Last answer provided

=cut

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
);

has 'solved_answer'  => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    writer     => '_set_solved_answer',
    required   => 0,
);

has 'solved_wanted'  => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    writer     => '_set_solved_wanted',
    required   => 0,
);




=head1 ABSTRACT FUNCTIONS

These two functions must also be overridden by the extending class

=head2 _check_input

Ensure the input provided by the user is compliant

=head2 _solve_problem

This the main function which will return the status/answer for a problem

=cut

requires '_check_input';
requires '_solve_problem';


=head1 PROVIDED FUNCTIONS

=head2 solve

This function will point to the internal function that actually solves the
problem..  Depending on the object attributes that are set, it uses either the
default or provided inputs (if they are required) and returns the answer as a
string in scalar context, or an array containing the status, calculated answer,
and expected answer.

    my $problem_1  = Project::Euler::Problem::P001->new();
    my $def_answer = $problem_1->solve;

    $problem_1->custom_input  => (42);
    $problem_1->custom_answer => (42);
    $problem_1->use_defaults  => (1);

    my $custom_answer = $problem_1->solve;

    my ($status, $answer, $expected) = $problem_1->solve;

=cut

sub solve {
    my ($self, $cust_input) = @_;
    my $answer;

    #  If no input was given as an arg, try to get it from the current object.
    #  This may still return an undef but that's alright
    $cust_input //= $self->custom_input;

    #  If there problem takes input, determine the appropriate course of action
    if ( $self->has_input ) {
        #  The user wants to use the defaults so don't pass anything
        if ( $self->use_defaults ) {
            $answer = $self->_solve_problem;
        }
        #  Pass the user input to the subroutine (if it's defined!)
        elsif (defined $cust_input) {
            $answer = $self->_solve_problem( $cust_input );
        }
        #  The user tried to use a cutsom input string to
        #  solve the problem but hasn't defined it yet!
        else {
            croak q{You tried to use custom inputs to solve the problem, but it has not been set yet}
        }
    }

    #  There are no paramaters to pass!
    else {
        $answer = $self->_solve_problem;
    }


    # Determine what the expected answer should be, depending on whether the
    # defaults were used or not.
    my $wanted = $self->use_defaults  ?  $self->default_answer  :  $self->custom_answer;

    #  Determine if the given answer was correct.
    #  Use a blank string rather than undef for the given and expected answer
    $answer //= q{};  $wanted //= q{};

    #  See if the answer was correct
    my $status  =  $answer eq $wanted;

    #  Save the answer, wanted, and status
    $self->_set_solved_answer($answer);
    $self->_set_solved_wanted($wanted);
    $self->_set_solved_status($status);

    #  Return either the status, answer, and wanted or, if the user just
    #  expects a scalar, the found answer
    return  wantarray  ?  ($status, $answer, $wanted)  :  $answer;
}



=head2 status

This function simply returns a nice, readable status message that tells you the
outcome of the last run of the module.

    my $problem_1  = Project::Euler::Problem::P001->new();
    $problem_1->solve;
    my $message = $problem_1->last_run_message;

=cut

sub status {
    my ($self) = @_;

    #  Extract the status and solved and expected answer
    my ($answer, $wanted, $status) =
        @{$self}{qw/ solved_answer  solved_wanted  solved_status /};

    #  If the status isn't even defined then the problem wasn't even run
    if (!defined $status) {
        return q{It appears that the problem has yet to be solved once.};
    }

    #  Otherwise print a message if it failed or not
    else {
        return sprintf(q{The last run was%s succesfull!  The answer expected was '%s' %s the answer returned was '%s'},
            $status ? q{} : ' not', $wanted, $status ? 'and' : 'but', $answer
        );
    }
}



=head1 AUTHOR

Adam Lesperance, C<< <lespea at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-project-euler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Project-Euler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Project::Euler::Base


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Adam Lesperance.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

no Moose::Role;
1; # End of Project::Euler::Problem::Base
