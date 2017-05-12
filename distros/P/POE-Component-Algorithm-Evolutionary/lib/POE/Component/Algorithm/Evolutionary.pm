package POE::Component::Algorithm::Evolutionary;

use lib qw( ../../../../../Algorithm-Evolutionary/lib ../../../../../../Algorithm-Evolutionary/lib ../Algorithm-Evolutionary/lib ); #For development and perl syntax mode

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.2.1');

use POE;
use Algorithm::Evolutionary;


sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  my ($method) = ($AUTOLOAD =~ /::(\w+)$/);
  return if !$self->{'session'}; # Before creation or after destruction
  my $heap = $self->{'session'}->get_heap();
  if ( $method =~ /^set_(\w+)/ ) {
      my $instanceVar = $1;
      if (defined ($heap->{$instanceVar})) {
	  $heap->{$instanceVar} = shift;
      }
  } else {    
      my $instanceVar = lcfirst($method);
      if (defined ($heap->{$instanceVar})) {
	  return $heap->{$instanceVar};
      }    
  
  }
}


# Module implementation here
sub new {
  my $class = shift;
  my %args = @_;

  my $options = {};
  for my $option ( qw( Fitness Creator Single_Step Terminator Alias ) ) {
      $options->{lc($option)} = $args{$option} || croak "$option required";
  }

  for my $option ( qw( Replacer After_Step ) ) {
      $options->{lc($option)} = $args{$option};
  }
  
  my $self = { alias => $options->{'alias' }};
  bless $self, $class;

  my $session = POE::Session->create(inline_states => { _start => \&start,
							generation => \&generation,
							after_step => \&after_step,
							finish => \&finishing},
				     args  => [$options->{'alias'}, $self, $options]
				    );
  $self->{'session'} = $session;
  return $self;
}

sub _start_base {
    my ($kernel, $heap, $alias, $self, $options )=
	    @_[KERNEL, HEAP, ARG0, ARG1, ARG2 ];
    $kernel->alias_set($alias);
    for my $option ( keys %$options ) {
	$heap->{$option} = $options->{$option};
    }
    $heap->{'self'} = $self;
    my @pop;
    $options->{'creator'}->apply( \@pop );
    map( $_->evaluate($options->{'fitness'}), @pop );
    $heap->{'population'} = \@pop;
    
}

# Create stuff and get ready to go
sub start {
    _start_base( @_ );
    $_[KERNEL]->yield('generation');
}


sub new_population {
    my ($kernel, $heap, $new_population ) = @_[KERNEL, HEAP, ARG0];
    if ( $heap->{'replacer'} ) {
	$heap->{'replacer'}->apply($heap->{'population'}, $new_population ); 
    } else {
	splice( @{$heap->{'population'}}, -@{$new_population} ); 
	push @{$heap->{'population'}}, @{$new_population} ; 
    }
    $kernel->yield('generation');
}

sub after_step {
    my ($kernel, $heap, $arg ) = @_[KERNEL, HEAP, ARG0];
    if ( $heap->{'after_step'} ){
	if ( ref $heap->{'after_step'} eq 'CODE' ) {
	    $heap->{'after_step'}->( $heap->{'population'}, $arg );
	} else {
	    $heap->{'after_step'}->apply( $heap->{'population'}, $arg );
	}
    }
    $kernel->yield('generation');
}

#Evolve population
sub generation {
  my ($kernel, $heap ) = @_[KERNEL, HEAP];
  $heap->{'single_step'}->apply( $heap->{'population'} );
  if ( ! $heap->{'terminator'}->apply( $heap->{'population'} ) ) {
    $kernel->yield( 'finish' );
  } else {
    $kernel->yield( 'after_step' );
  }

}

#Finish here
sub finishing {
  my ($kernel, $heap ) = @_[KERNEL, HEAP];
  print "Best is:\n\t ",$heap->{'population'}->[0]->asString()," Fitness: ",
    $heap->{'population'}->[0]->Fitness(),"\n";
}

"Don't look further" ; # Magic true value required at end of module
__END__

=head1 NAME

POE::Component::Algorithm::Evolutionary - Run evolutionary algorithms in a preemptive multitasking way.


=head1 VERSION

This document describes POE::Component::Algorithm::Evolutionary version 0.0.3


=head1 SYNOPSIS

  use POE::Component::Algorithm::Evolutionary;

  use Algorithm::Evolutionary qw( Individual::BitString Op::Creator 
				  Op::CanonicalGA Op::Bitflip 
				  Op::Crossover Op::GenerationalTerm
				  Fitness::Royal_Road);

  my $bits = shift || 64;
  my $block_size = shift || 4;
  my $pop_size = shift || 256; #Population size
  my $numGens = shift || 200; #Max number of generations
  my $selection_rate = shift || 0.2;

  #Initial population
  my $creator = new Algorithm::Evolutionary::Op::Creator( $pop_size, 'BitString', { length => $bits });

  # Variation operators
  my $m = Algorithm::Evolutionary::Op::Bitflip->new( 1 );
  my $c = Algorithm::Evolutionary::Op::Crossover->new(2, 4);

  # Fitness function: create it and evaluate
  my $rr = new  Algorithm::Evolutionary::Fitness::Royal_Road( $block_size );

  my $generation = Algorithm::Evolutionary::Op::CanonicalGA->new( $rr , $selection_rate , [$m, $c] ) ;
  my $gterm = new Algorithm::Evolutionary::Op::GenerationalTerm 10;

  POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
						Creator => $creator,
						Single_Step => $generation,
						Terminator => $gterm,
						Alias => 'Canonical' );


  $poe_kernel->run();


=head1 DESCRIPTION

Not a lot here: it creates a component that uses POE to run an
evolutionary algorithm 

=head1 INTERFACE 

=head2 AUTOLOAD

Automatically defines accesors for instance variables. For instance,
    $session->Fitness() would return the fitness object, of
    $self->Population() return the population hashref.

=cut

=head2 new

POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
					      Creator => $creator,
					      Single_Step => $generation,
					      Terminator => $gterm,
					      Alias => 'Canonical',
                                              After_Step => $after_step_code);

It's called with all components needed to run an evolutionary
algorithm; to keep everything flexible they are created in
advance. See the C<scripts/> directory for an example.

=head2 new_population

Called with a hashref to the new population to incorporate

=head2 start

Called internally for initializing population

=head2 generation

This is run once for each generation, until end condition is met

=head2 after_step

Run always after each generation, with hooks so that you can add your
    own code. The first argument for the subroutine will be a
    population hash, and the second the argument that the event
    receives. 


=head2 finishing

Called when everything is over. Prints winner

=head1 CONFIGURATION AND ENVIRONMENT

POE::Component::Algorithm::Evolutionary requires no configuration files or environment variables.


=head1 DEPENDENCIES

Main dependence is L<Algorithm::Evolutionary>; however, it's not
included by default, since you must pick and choose the modules you
are going to actually use.


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-poe-component-algorithm-evolutionary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>

=begin html 

Boilerplate taken from <a
href='http://perl.com/pub/a/2004/07/22/poe.html?page=2'>article in
perl.com</a> 

=end html


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

  CVS Info: $Date: 2009/02/13 09:22:57 $ 
  $Header: /cvsroot/opeal/POE-Component-Algorithm-Evolutionary/lib/POE/Component/Algorithm/Evolutionary.pm,v 1.9 2009/02/13 09:22:57 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.9 $ ' 

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
