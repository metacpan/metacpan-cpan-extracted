package POE::Filter::JSONMaybeXS;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A POE filter using JSON::MaybeXS
$POE::Filter::JSONMaybeXS::VERSION = '0.002';
use Carp;
use JSON::MaybeXS;

use strict;
use warnings;

use base qw( POE::Filter );

sub BUFFER () { 0 }
sub OBJ    () { 1 }

sub new {
  my $class = shift;
  croak "$class requires an even number of parameters" if @_ % 2;
  my %opts = @_;
  bless( [
    [],                         # BUFFER
    JSON::MaybeXS->new( %opts ) # OBJ
  ], ref $class || $class );
}

sub get {
  my ($self, $lines) = @_;
  my $ret = [];

  foreach my $json (@$lines) {
    if ( my $data = eval { ($self->[ OBJ ]->decode( $json )) } ) {
      push( @$ret, $data );
    } else {
      warn "Couldn't convert json: $@";
    }
  }
  return $ret;
}

sub get_one_start {
  my ($self, $lines) = @_;
  $lines = [ $lines ] unless ( ref( $lines ) );
  push( @{ $self->[ BUFFER ] }, @{ $lines } );
}

sub get_one {
  my $self = shift;
  my $ret = [];

  if ( my $line = shift ( @{ $self->[ BUFFER ] } ) ) {
    if ( my $data = eval { ($self->[ OBJ ]->decode( $line )) } ) {
      push( @$ret, $data );
    } else {
      warn "Couldn't convert json: $@";
    }
  }

  return $ret;
}

sub put {
  my ($self, $objects) = @_;
  my $ret = [];

  foreach my $obj (@$objects) {
    if ( my $json = eval { $self->[ OBJ ]->encode( $obj ) } ) {
      push( @$ret, $json );
    } else {
      warn "Couldn't convert object to json\n";
    }
  }
  
  return $ret;
}

1;

__END__

=pod

=head1 NAME

POE::Filter::JSONMaybeXS - A POE filter using JSON::MaybeXS

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use POE::Filter::JSONMaybeXS;

  my $filter = POE::Filter::JSONMaybeXS->new(
    allow_nonref => 1,  # see the JSON::MaybeXS new options
  );
  my $obj = { foo => 1, bar => 2 };
  my $json_array = $filter->put( [ $obj ] );
  my $obj_array = $filter->get( $json_array );

  use POE qw(
    Filter::Stackable
    Filter::Line
    Filter::JSONMaybeXS
  );

  my $filter = POE::Filter::Stackable->new();
  $filter->push(
    POE::Filter::Line->new(),
    POE::Filter::JSONMaybeXS->new(),
  );

=head1 DESCRIPTION

More documentation to come...

More tests to come...

Based on L<POE::Filter::JSON>

Best used together with L<POE::Filter::Line>

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
