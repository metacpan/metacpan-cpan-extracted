package Reaction::UI::WidgetClass::_OVER;

use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];


has 'collection' => (is => 'ro', required => 1);
sub BUILD {
  my ($self, $args) = @_;
  my $coll = $args->{collection};
  unless (ref $coll eq 'ARRAY' || (blessed($coll) && $coll->can('next'))) {
    confess _OVER."->new collection arg ${coll} is neither"
                 ." arrayref nor implements next()";
  }
};
sub each {
  my ($self, $do) = @_;
  my $coll = $self->collection;
  if (ref $coll eq 'ARRAY') {
    foreach my $el (@$coll) {
      $do->($el);
    }
  } else {
    $coll->reset if $coll->can('reset');
    while (my $el = $coll->next) {
      $do->($el);
    }
  }
};
__PACKAGE__->meta->make_immutable;


1;
