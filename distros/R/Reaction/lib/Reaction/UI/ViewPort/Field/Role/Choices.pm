package Reaction::UI::ViewPort::Field::Role::Choices;

use Reaction::Role;
use URI;
use Scalar::Util 'blessed';

use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/ArrayRef Str/;

has valid_values  => (isa => ArrayRef, is => 'ro', lazy_build => 1);
has value_choices => (isa => ArrayRef, is => 'ro', lazy_build => 1);
has value_map_method => (
  isa => Str, is => 'ro', required => 1, default => sub { 'display_name' },
);
sub str_to_ident {
  my ($self, $str) = @_;
  my $u = URI->new('','http');
  $u->query($str);
  return ($u->query_keywords ? ($u->query_keywords)[0] : { $u->query_form });
};
sub obj_to_str {
  my ($self, $obj) = @_;
  return $obj unless ref($obj);
  confess "${obj} not an object" unless blessed($obj);
  my $ident = $obj->ident_condition; #XXX DBIC ism that needs to go away
  my $u = URI->new('', 'http');
  $u->query_form(%$ident);
  return $u->query;
};
sub obj_to_name {
  my ($self, $obj) = @_;
  return $obj unless ref($obj);
  confess "${obj} not an object" unless blessed($obj);
  my $meth = $self->value_map_method;
  return $obj->$meth;
};
sub _build_valid_values {
  my $self = shift;
  return [ $self->attribute->all_valid_values($self->model) ];
};
sub _build_value_choices {
  my $self  = shift;
  my @pairs = map{{value => $self->obj_to_str($_), name => $self->obj_to_name($_)}}
    @{ $self->valid_values };
  return [ sort { $a->{name} cmp $b->{name} } @pairs ];
};



1;
