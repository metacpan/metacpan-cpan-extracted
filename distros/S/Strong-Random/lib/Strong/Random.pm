package Strong::Random;

=head1 NAME

Strong::Random - Strong random generator

=head1 SYNOPSIS

  use Strong::Random;

  my $rand = new Strong::Random;

  # Print random character
  print chr $rand->rand(256) . "\n";

=cut

use 5.022;
use warnings;

use Config;
use Time::HiRes;

our $VERSION = '0.95';

=head1 METHODS

=head2 new()

Strong::Random constructor.

Parameters:
	
	$seed - Seed for next series of random generation by algorythm. 
	        If not specified, will be use CPU-time + PID.

Return:
	
	Strong::Random based class object.

=cut

sub new {
	my $class = shift;
	my $seed  = shift;
	
	my $self = bless {}, $class;
	
	$self->srand($seed ? abs $seed : undef);
	
	return $self;
}



sub _shuffle_seed {
	my $class = shift;
	
	return rand() * ((join '.', reverse Time::HiRes::gettimeofday) . $$);
}

sub _harmonic {
	my $self = shift;
	my $x = $self->{seed};
	
	state $half_freq = 2/7.0;

	my $step = int ($x / $half_freq);
	$x -= $step * $half_freq;

	return ($step % 2 ? -1 : 1)*sqrt (1 - $x*$x);
}

=head2 srand()

Setup new seed.

Parameters:
	
	$seed - Seed for next series of random generation by algorythm. 
	        If not specified, will be use CPU-time + PID.


=cut

sub srand {
	my $self = shift;
	my $seed = shift // $self->_shuffle_seed();
	
	while ($seed >= 100000000) {
		$seed /= 2;
	}
	
	$self->{seed} = $seed;
}

=head2 rand()

Return random number.

Parameters:
	
	$num - If specified, method will return int between [0..$num-1).
		   If not specfied, method return value form [0..1).

=cut

sub rand {
	my $self = shift;
	my $num = shift;
	
	my $r = ($self->_harmonic()+1.0)/2.0+1.5;
	
	$self->{seed} *= $r;
	$self->{seed} /= 2 while ($self->{seed} >= 100000000);
	
	my $s = sprintf("%0.42g", $r);
	$s =~ s/\.//;
	
	$r *= substr($s, -5) || 0;
	$r = substr($r, 0, 22);
	
	$r =~ s/\.//;
	$r = '0.'.$r;
	
	return $num ? int $num * $r : $r;
}

=head1 VERSION

0.95

=head1 AUTHOR

All code writen by Ivan Trunaev.

=head1 LICENSE

Commercial support by Author for Open Source!

Contacts <ivan@trunaev.ru>

=cut

1;
