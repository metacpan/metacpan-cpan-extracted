package Test::BDD::Cucumber::StepMatcher;
$Test::BDD::Cucumber::StepMatcher::VERSION = '0.59';
=head1 NAME

Test::BDD::Cucumber::StepMatcher - Run through Feature and Harness objects

=head1 VERSION

version 0.59

=head1 DESCRIPTION


=cut

use Moo;

=head2 steps

=head2 add_steps

The attributes C<steps> is a hashref of arrayrefs, storing steps by their Verb.
C<add_steps()> takes step definitions of the item list form:

 (
  [ Given => qr//, sub {} ],
 ),

and populates C<steps> with them.

=cut

has 'steps' => ( is => 'rw', isa => HashRef, default => sub { {} } );

sub add_steps {
    my ( $self, @steps ) = @_;

    # Map the steps to be lower case...
    for (@steps) {
        my ( $verb, $match, $code ) = @$_;
        $verb = lc $verb;

        if ( $verb =~ /^(before|after)$/ ) {
            $code  = $match;
            $match = qr//;
        } else {
            unless ( ref($match) ) {
                $match =~ s/:\s*$//;
                $match = quotemeta($match);
                $match = qr/^$match:?/i;
            }
        }

        if ( $verb eq 'transform' or $verb eq 'after' ) {

            # Most recently defined Transform takes precedence
            # and After blocks need to be run in reverse order
            unshift( @{ $self->{'steps'}->{$verb} }, [ $match, $code ] );
        } else {
            push( @{ $self->{'steps'}->{$verb} }, [ $match, $code ] );
        }

    }
}

=head2 find_and_dispatch

Accepts a L<Test::BDD::Cucumber::StepContext> object, and searches through
the steps that have been added to the executor object, executing against the
first matching one.

You can also pass in a boolean 'short-circuit' flag if the Scenario's remaining
steps should be skipped, and a boolean flag to denote if it's a redispatched
step.

=cut

sub find {
    my ( $self, $context, $short_circuit, $redispatch ) = @_;

    # Try and find a matching step
    my @steps = grep { $context->text =~ $_->[0] }
    @{ $self->{'steps'}->{ $context->verb } || [] },
      @{ $self->{'steps'}->{'step'} || [] };

    return \@steps;
}



1;
