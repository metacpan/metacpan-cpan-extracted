package ComponentUI::UI::ViewPort::Baz::ListView::Member;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use aliased 'Reaction::UI::ViewPort::Field::String::Fragment';

extends 'Reaction::UI::ViewPort::Collection::Grid::Member';

sub _build_layout {
 'collection/grid/member';
}

sub _build_fields_for_name_description {
  my ($self, $attr, $args) = @_;
  $self->_build_simple_field(attribute => $attr, class => Fragment, %$args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

