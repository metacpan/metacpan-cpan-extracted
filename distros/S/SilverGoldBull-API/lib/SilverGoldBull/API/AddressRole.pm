package SilverGoldBull::API::AddressRole;

use strict;
use warnings;

use Mouse::Role;
use Mouse::Util::TypeConstraints;
use Locale::Country qw(all_country_codes);

enum 'ISO_3166-1' => map { uc($_) } all_country_codes();

has 'country'    => ( is => 'rw', isa => 'ISO_3166-1', required => 1 );
has 'first_name' => ( is => 'rw', isa => 'Str',        required => 1 );
has 'last_name'  => ( is => 'rw', isa => 'Str',        required => 1 );
has 'street'     => ( is => 'rw', isa => 'Str',        required => 1 );
has 'city'       => ( is => 'rw', isa => 'Str',        required => 1 );
has 'company'    => ( is => 'rw', isa => 'Str',        required => 0 );
has 'region'     => ( is => 'rw', isa => 'Str',        required => 0 );
has 'phone'      => ( is => 'rw', isa => 'Str',        required => 0 );
has 'postcode'   => ( is => 'rw', isa => 'Str',        required => 0 );
has 'email'      => ( is => 'rw', isa => 'Str',        required => 0 );

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my $args  = undef;

  if ( @_ == 1 && ref $_[0] ) {
    $args = shift;
  }
  else {
    my %hash = shift;
    $args = \%hash;
  }

  $args->{country} = uc($args->{country});

  return $class->$orig($args);
};

sub to_hashref {
  my ($self) = @_;
  my $hashref = {};
  for my $field (qw(company country first_name last_name street city region phone postcode email)) {
    if (defined $self->{$field}) {
      $hashref->{$field} = $self->{$field};
    }
  }
  
  return $hashref;
}

1;
