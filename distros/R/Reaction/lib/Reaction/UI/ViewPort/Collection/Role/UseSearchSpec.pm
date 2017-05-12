package Reaction::UI::ViewPort::Collection::Role::UseSearchSpec;

use Reaction::Role;
use aliased 'Reaction::InterfaceModel::Search::Spec' => 'SearchSpecRole';
use Scalar::Util qw(weaken);
use Method::Signatures::Simple;
use signatures;
use namespace::clean -except => 'meta';

has 'search_spec' => (isa => SearchSpecRole, is => 'ro', required => 1);

has '_search_spec_cb' => (is => 'ro', lazy_build => 1);

method _build__search_spec_cb () {
  my $object = $self;
  weaken($object);
  my $cb = sub { $object->clear_current_collection };
}

method _filter_collection_using_search_spec($coll) {
  $self->search_spec->filter_collection($coll);
}

method _register_self_with_search_spec () {
  my $cb = $self->_search_spec_cb;
  $self->search_spec->register_dependent($self, $cb);
}

around _build_current_collection => sub ($orig, $self, @rest) {
  my $coll = $self->$orig(@rest);
  return $self->_filter_collection_using_search_spec($coll);
};

1;

