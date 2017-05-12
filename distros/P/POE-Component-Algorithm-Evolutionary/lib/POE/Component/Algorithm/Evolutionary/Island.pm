package POE::Component::Algorithm::Evolutionary::Island;

use lib qw( ../../../../../Algorithm-Evolutionary/lib ../Algorithm-Evolutionary/lib ); #For development and perl syntax mode

use warnings;
use strict;
use Carp;

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/g; 

use POE;
use base 'POE::Component::Algorithm::Evolutionary';

# Module implementation here
sub new {
  my $class = shift;
  my %arg = @_;
  my $self = $class->SUPER::new( %arg );
  $self->{'peers'} = delete $arg{'Peers'} || croak "Need a list of peers";
  return $self;
}

sub start {
    my $self = shift;
    _start_base( @_ );
    $_[HEAP]->{'peers'} = $self->{'peers'};
    $_[KERNEL]->yield('generation');
}


"Don't look further" ; # Magic true value required at end of module
__END__

=head1 NAME

POE::Component::Algorithm::Evolutionary::Island - Base class for evolutionary "islands" that interchange information with each other


=head1 SYNOPSIS

  use POE::Component::Algorithm::Evolutionary::Island;

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

  my @peers = qw( peer_1 peer_2 peer_3 ); # Different way of specifying peers, depending on implementation
  POE::Component::Algorithm::Evolutionary::Island::TypeXXX->new( Fitness => $rr,
    Creator => $creator,
    Single_Step => $generation,
    Terminator => $gterm,
    Alias => 'Canonical',
    Peers => \@peers );

  $poe_kernel->run();


=head1 DESCRIPTION

Not a lot here: it creates a component that uses POE to run an
evolutionary algorithm 

=head1 INTERFACE 

=head2 new

POE::Component::Algorithm::Evolutionary->new( Fitness => $rr,
					      Creator => $creator,
					      Single_Step => $generation,
					      Terminator => $gterm,
					      Alias => 'Canonical',
                                              Peers => \@peers);

Basically like PoCoAE, but with peers

=head2 start

Not a big deal; mainly for initializing the population via calling ancestor

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
  $Header: /cvsroot/opeal/POE-Component-Algorithm-Evolutionary/lib/POE/Component/Algorithm/Evolutionary/Island.pm,v 1.3 2009/02/21 12:39:19 jmerelo Exp $ 
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
