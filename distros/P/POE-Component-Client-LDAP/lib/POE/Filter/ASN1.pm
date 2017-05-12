package POE::Filter::ASN1;

# Copyright 2004 Jonathan Steinert (hachi@cpan.org)
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

use 5.006;
use strict;
use warnings;
use Convert::ASN1 qw(asn_decode_tag asn_decode_length);

our $VERSION = '0.01';

sub new {
  my $class = shift;

  my $self = bless {
    buffer => '',
  }, (ref $class || $class);

  return $self;
}

sub get {
  my $self = shift;
  my $blocks = shift;

  $self->{buffer} .= join( '', @$blocks );

  my $return_blocks = [];
  
  while (1) {
    my ($tb, $tag) = asn_decode_tag( $self->{buffer} ) or last;
    my ($lb, $len) = asn_decode_length( substr( $self->{buffer},$tb,8 ) ) or last;
    my $length = $tb + $lb + $len;
    
    if ($length <= length $self->{buffer}) {
      push @$return_blocks, substr( $self->{buffer},0,$length );
      substr( $self->{buffer}, 0, $length ) = '';
    }
    else {
      last;
    }
  }
  return $return_blocks;
}


sub put {
  die( "Unimplemented call to put()\n" );
}

1;
