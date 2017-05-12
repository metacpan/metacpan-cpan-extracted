package Misc::Quality;

=head1 NAME

Astro::Quality - Class for handling quality flags for astronomical objects.

=head1 SYNOPSIS

  use Astro::Quality;

  $quality = new Astro::Quality( 'derived' => 1 );

  $derived = $quality->query('derived');

  $quality->set( 'derived' => 0 );

=head1 DESCRIPTION

Class for handling quality flags for astronomical objects. This class
can handle any type of flag used.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

# CVS version $Id: Quality.pm,v 1.2 2005/06/10 00:50:04 aa Exp $
our $VERSION = '0.01';

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  my $quality = ();

  my %args = @_;

  foreach my $key ( keys %args ) {
    $quality->{uc($key)} = $args{$key};
  }

  bless( $quality, $class );
  return $quality;
}

sub query {
  my $self = shift;
  my $flag = uc(shift);

  if( exists( $self->{$flag} ) ) {
    return $self->{$flag};
  } else {
    return undef;
  }
}

sub set {
  my $self = shift;
  my $flag = uc(shift);
  my $value = shift;

  $self->{$flag} = $value;
}

1;

