package Simulation::Sensitivity;
use strict;
use warnings;
# ABSTRACT: A general-purpose sensitivity analysis tool for user-supplied calculations and parameters
our $VERSION = '0.12'; # VERSION

# Required modules
use Carp;
use Params::Validate ':all';

# ISA
use base qw( Class::Accessor::Fast );

#--------------------------------------------------------------------------#
# main pod documentation #####
#--------------------------------------------------------------------------#


#--------------------------------------------------------------------------#
# new()
#--------------------------------------------------------------------------#


{
    my $param_spec = {
        calculation => { type => CODEREF },
        parameters  => { type => HASHREF },
        delta       => { type => SCALAR }
    };

    __PACKAGE__->mk_accessors( keys %$param_spec );

    sub new {
        my $class  = shift;
        my %params = validate( @_, $param_spec );
        my $self   = bless( {%params}, $class );
        return $self;
    }

}


#--------------------------------------------------------------------------#
# base()
#--------------------------------------------------------------------------#


sub base {
    my ($self) = @_;
    return $self->calculation->( { %{ $self->parameters } } );
}

#--------------------------------------------------------------------------#
# run()
#--------------------------------------------------------------------------#


sub run {
    my ($self) = @_;
    my $results;

    for my $key ( keys %{ $self->parameters } ) {
        $results->{$key} = {};
        for my $mult ( 1, -1 ) {
            my $p = { %{ $self->parameters } };
            $p->{$key} = ( 1 + $mult * $self->delta ) * $self->parameters->{$key};
            $results->{$key}->{ $self->_case($mult) } =
              $self->calculation->($p);
        }
    }
    return $results;
}

#--------------------------------------------------------------------------#
# _case ($mult, $result, $base)
#
# private helper function to turn a +/-1 into a case label using the delta
#--------------------------------------------------------------------------#

sub _case {
    my ( $self, $mult ) = @_;
    return ( ( $mult == 1 ) ? "+" : "-" ) . ( $self->delta * 100 ) . "%";
}

#--------------------------------------------------------------------------#
# text_report()
#--------------------------------------------------------------------------#


sub text_report {
    my ( $self, $results ) = @_;
    my $base = $self->base;
    croak "Simulation base case is zero/undefined.  Cannot generate report."
      unless $base;
    my $report =
      sprintf( "%12s %9s %9s\n", "Parameter", $self->_case(1), $self->_case(-1) );
    $report .= sprintf( "-" x 36 . "\n" );
    for my $param ( sort keys %$results ) {
        my $cases = $results->{$param};
        $report .= sprintf(
            "%12s %+9.2f%% %+9.2f%%\n",
            $param,
            ( $cases->{ $self->_case(1) } / $base - 1 ) * 100,
            ( $cases->{ $self->_case(-1) } / $base - 1 ) * 100,
        );
    }
    return $report;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Simulation::Sensitivity - A general-purpose sensitivity analysis tool for user-supplied calculations and parameters

=head1 VERSION

version 0.12

=head1 SYNOPSIS

 use Simulation::Sensitivity;
 $sim = Simulation::Sensitiviy->new(
    calculation => sub { my $p = shift; return $p->{alpha} + $p->{beta} }
    parameters  => { alpha => 1.1, beta => 0.2 },
    delta       => 0.1 );
 $result = $sim->run;
 print $sim->text_report($result);

=head1 DESCRIPTION

Simulation::Sensitivity is a general-purpose sensitivity analysis tool.
Given a user-written calculating function, a "base-case" of parameters,
and a requested input sensitivity delta, this module will carry out a
sensitivity analysis, capturing the output of the calculating function
while varying each parameter positively and negatively by the specified 
delta.  The module also produces a simple text report showing the
percentage impact of each parameter upon the output.

The user-written calculating function must follow a standard form, but 
may make any type of computations so long as the form is satisfied.  It
must take a single argument -- a hash reference of parameters for use 
in the calculation.  It must return a single, numerical result.

=head1 CONSTRUCTORS

=head2 C<new> 

 my $sim = Simulation::Sensitivity->new(
    calculation => sub { my $p = shift; return $p->{alpha} + $p->{beta} }
    parameters  => { alpha => 1.1, beta => 0.2 },
    delta       => 0.1 );

C<new> takes as its argument a hash with three required parameters. 
C<calculation> must be a reference to a subroutine and is used for 
calculation.  It must adhere to the usage guidelines above for such 
functions.  C<parameters> must be a reference to a hash that represents
the initial starting parameters for the calculation.  C<delta> is a
percentage that each parameter will be perturbed by during the analysis.  
Percentages should be expressed as a decimal (0.1 to indicate 10%).  

As a constructor, C<new> returns a Simulation::Sensitivity object.

=head1 PROPERTIES

=head2 C<calculation>, C<parameters>, C<delta>

 $sim->calculation()->({alpha=1.0, beta=1.0});
 %p = %{$sim->parameters()};
 $new_delta = $sim->delta(.15);

The parameter values in a Simulation::Sensitivity object may be 
retrieved or modified using get/set accessors.  With no argument, the 
accessor returns the value of the parameter.  With an argument, the
accessor sets the value to the new value and returns the new value.

=head1 METHODS

=head2 C<base>

 $base_case = base();

This method returns the base-case result for the parameter values provided
in the constructor.

=head2 C<run>

 $results = run();

This method returns a hash reference containing the results of the
sensitivity analysis.  The keys of the hash are the same as the keys of the
parameters array.  The values of the hash are themselves a hash reference
with each key representing a particular case in string form (e.g. "+10%" or
"-10%") and the value equal to the result from the calculation.  A simple
example would be:

 {
     alpha => {
         "+25%" => 5.25,
         "-25%" => 4.75
     },
     beta => {
         "+25%" => 6,
         "-25%" => 4
     }
 }

=head2 C<text_report>

 $report = text_report( $results );

This method generates a text string containing a simple, multi-line report.
The only parameter is a hash reference containing a set of results produced
with C<run>.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Simulation-Sensitivity/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Simulation-Sensitivity>

  git clone https://github.com/dagolden/Simulation-Sensitivity.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
