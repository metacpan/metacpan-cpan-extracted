package POE::Component::Algorithm::Evolutionary::Island::POEtic;

use lib qw( ../../../../../../Algorithm-Evolutionary/lib ../Algorithm-Evolutionary/lib ); #For development and perl syntax mode

use warnings;
use strict;
use Carp;

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/g; 

use POE;
use base 'POE::Component::Algorithm::Evolutionary::Island';

# Module implementation here
sub new {
  my $class = shift;
  my %arg = @_;
  $arg{'After_Step'} = \&after_step;
  my $self = $class->SUPER::new( %arg );
  return $self;
}

sub after_step {
    my ($kernel, $heap, $arg ) = @_[KERNEL, HEAP, ARG0];
    for my $node ( @{$heap->{'peers'}} ) { #Sessions by name
	$kernel->post($node, 'new_population', [$heap->{'population'}->[0]] );
    }
}


"No man is an island" ; # Magic true value required at end of module
__END__

=head1 NAME

POE::Component::Algorithm::Evolutionary::Island::POEtic - Island that
uses L<POE> mechanisms for interchanging information, and act only as
POE sessions 


=head1 SYNOPSIS

  use POE::Component::Algorithm::Evolutionary::Island::POEtic;

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

  my @nodes = qw( node_1 node_2 );
  my %sessions;
  for my $n ( @nodes ){
    my @nodes_here = grep( $_ ne $n, @nodes );
    $sessions{$n} = POE::Component::Algorithm::Evolutionary::Island::POEtic->new( Fitness => $rr,
										Creator => $creator,
										Single_Step => $generation,
										Terminator => $gterm,
										Alias => $n,
										Peers => \@nodes_here );
  }

  $poe_kernel->run();


=head1 DESCRIPTION

Using C<post>, this type of island moves individuals from one island
to another

=head1 INTERFACE 

=head2 new

POE::Component::Algorithm::Evolutionary::Island::POEtic->new( Fitness => $rr,
					      Creator => $creator,
					      Single_Step => $generation,
					      Terminator => $gterm,
					      Alias => 'this_peer',
                                              Peers => \@peers);

Basically like PoCoAE, but with peers

=head2 after_step

Not to be called from outside, is the one that does the actual
interchange between islands.


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

  CVS Info: $Date: 2009/02/21 12:39:19 $ 
  $Header: /cvsroot/opeal/POE-Component-Algorithm-Evolutionary/lib/POE/Component/Algorithm/Evolutionary/Island/POEtic.pm,v 1.2 2009/02/21 12:39:19 jmerelo Exp $ 
  $Author: jmerelo $ 

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
