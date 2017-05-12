package Reaction::InterfaceModel::Action::Search::UpdateSpec;

use Reaction::Class;
#use aliased 'BrokerInterface::SearchSpec';
use Method::Signatures::Simple;
use Reaction::InterfaceModel::Reflector::SearchSpec;
use Carp qw( confess );

use namespace::clean -except => 'meta';

extends 'Reaction::InterfaceModel::Action';

method _reflection_info () {
    confess sprintf "Class %s did not override the _reflection_info method", 
        ref($self) || $self;
}

with 'Reaction::InterfaceModel::Search::UpdateSpec';

1;

=head1 NAME

Reaction::InterfaceModel::Action::Search::UpdateSpec - Update search specification

=head1 SYNOPSIS

  package MyApp::InterfaceModel::UpdateSearchSpec;
  use Reaction::Class;
  use Reaction::InterfaceModel::Reflector::SearchSpec;

  use aliased 'MyApp::InterfaceModel::SearchSpec';

  use namespace::autoclean;

  extends 'Reaction::InterfaceModel::Action::Search::UpdateSpec';

  # this will reflect the search spec as update spec in the current
  # class.
  my $info = reflect_attributes_from_target SearchSpec;

  sub _reflection_info { $info }

  1;

=cut
