package Reaction::InterfaceModel::Reflector::SearchSpec;

use Moose::Exporter;
use Carp qw(confess);
use Reaction::Types::Core qw(SimpleStr NonEmptySimpleStr);
#use aliased 'T365::BrokerInterface::SearchSpec';
use aliased 'Moose::Meta::TypeConstraint::Enum';

sub reflect_attributes_from_target {
  my ($caller, $foreign) = @_;
  confess 'Class name to reflect search specification is required as first argument to reflect_attributes_from_target'
    unless $foreign;
#  $foreign ||= SearchSpec;
  my $meta = Class::MOP::Class->initialize($caller);
  my %info;
  foreach my $attr (
    grep { $_->name !~ /^_/ }
      $foreign->meta->get_all_attributes
  ) {
#warn "Doing ".$attr->name;
    my %args;
    { my @copy = qw(required is isa);
      @args{@copy} = @{$attr}{@copy};
    }
    if ($args{isa} eq NonEmptySimpleStr) {
#warn "here ".$attr->name." ".join(', ', %args);
      if ($args{required}) {
        confess "I really have no idea how we got here";
      } else {
        $args{isa} = SimpleStr;
        $args{required} = 1;
        push(@{$info{empty}||=[]}, $attr->name);
      }
    } else {
      push(@{$info{normal}||=[]}, $attr->name);
#warn "here instead ".$attr->name;
    }
    my $tc;
    if (($tc = $args{type_constraint}) && ($tc->isa(Enum))) {
      $args{valid_values} = $tc->values;
    }
    $args{predicate} = "has_".$attr->name;
    $meta->add_attribute($attr->name => \%args);
  }
  \%info;
}

Moose::Exporter->setup_import_methods(
  with_caller => [ 'reflect_attributes_from_target' ]
);

1;

