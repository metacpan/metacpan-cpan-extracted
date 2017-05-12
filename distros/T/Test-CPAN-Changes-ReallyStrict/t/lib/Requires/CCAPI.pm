use strict;
use warnings;

package Requires::CCAPI;

# ABSTRACT: Check API for various ranges and skip otherwise

# AUTHORITY

sub import {
  my ( $self, $todo, $params ) = @_;
  my $max  = '0.5';    # Future
  my @skip = (
    [ '0.400001', '0.400002' ]    # Nefarious over pad
  );
  $params = {} unless defined $params;
  $max  = $params->{max}       if exists $params->{max};
  @skip = @{ $params->{skip} } if exists $params->{skip};
  return if $ENV{AUTHOR_TESTING};
  require CPAN::Changes;

  if ( eval { CPAN::Changes->VERSION($max); 1 } ) {
    ${$todo} = "CPAN::Changes >= $max is too new for this test";
    return;
  }
  for my $pair (@skip) {
    next unless eval { CPAN::Changes->VERSION( $pair->[0] ); 1 };
    next if eval { CPAN::Changes->VERSION( $pair->[1] ); 1 };
    ${$todo} = "CPAN::Changes versions between $pair->[0] and $pair->[1] are known to break this test";
    return;
  }
}

1;

