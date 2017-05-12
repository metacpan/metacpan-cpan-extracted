package Reaction::InterfaceModel::Search::Spec;

use Reaction::Role;
use Method::Signatures::Simple;
use JSON;
use Scalar::Util qw(weaken);
use namespace::clean -except => [ qw(meta) ];

has '_search_spec' => (
  is => 'ro', lazy_build => 1, clearer => '_clear_search_spec',
);

has '_dependent_clients' => (
  is => 'ro', default => sub { {} },
);

method register_dependent ($dep, $callback) {
  weaken($self->_dependent_clients->{$dep} = $callback);
}

method unregister_dependent ($dep) {
  delete $self->_dependent_clients->{$dep};
}

after '_clear_search_spec' => method () {
  $_->($self) for grep defined, values %{$self->_dependent_clients};
};

requires '_build__search_spec';

method filter_collection ($coll) {
  return $coll->where(@{$self->_search_spec});
}

method _to_string_fetch ($attr) {
  return () unless $self->${\($attr->get_predicate_method||sub{ 1 })};
  my $value = $self->${\$attr->get_read_method};
  return ($attr->name => $self->_to_string_pack_value($attr->name, $value));
}

requires '_to_string_pack_value';

method to_string () {
  my %val = map { $self->_to_string_fetch($_) }
            grep { $_->name !~ /^_/ } $self->meta->get_all_attributes;
  return to_json(\%val, { canonical => 1 });
}

requires '_from_string_unpack_value';

method from_string ($class: $string, $other) {
  my %raw = %{from_json($string)};
  my %val;
  @val{keys %raw} = map {
    $class->_from_string_unpack_value($_, $raw{$_})
  } keys %raw;
  return $class->new({ %val, %{$other||{}} });
}

1;

