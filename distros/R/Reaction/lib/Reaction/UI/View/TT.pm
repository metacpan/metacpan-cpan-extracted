package Reaction::UI::View::TT;

use Reaction::Class;
use aliased 'Reaction::UI::View';
use Template;

use namespace::clean -except => [ qw(meta) ];
extends View;



has '_tt' => (isa => 'Template', is => 'rw', lazy_fail => 1);
sub BUILD {
  my ($self, $args) = @_;
  my $tt_args = $args->{tt}||{};
  $self->_tt(Template->new($tt_args));
};
override 'layout_set_args_for' => sub {
  my ($self) = @_;
  return (super(), tt_object => $self->_tt);
};
sub layout_set_file_extension { 'tt' };
sub serve_static_file {
  my ($self, $c, $args) = @_;
  foreach my $path (@{$self->search_path_for_type('web')}) {
    my $cand = $path->file(@$args);
    if ($cand->stat) {
      $c->serve_static_file($cand);
      return 1;
    }
  }
  return 0;
};

__PACKAGE__->meta->make_immutable;


1;
