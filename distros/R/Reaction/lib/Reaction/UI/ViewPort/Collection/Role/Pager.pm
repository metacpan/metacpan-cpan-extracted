package Reaction::UI::ViewPort::Collection::Role::Pager;

use Reaction::Role;

use aliased 'Reaction::InterfaceModel::Collection';

# XX This needs to be consumed after Ordered
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::Moose qw/Int/;

#has paged_collection => (isa => Collection, is => 'rw', lazy_build => 1);

has pager    => (isa => 'Data::Page', is => 'rw', lazy_build => 1);
has page     => (isa => Int, is => 'rw', lazy_build => 1, trigger_adopt('page'), clearer => 'clear_page');
has per_page => (isa => Int, is => 'rw', lazy_build => 1, trigger_adopt('page'));
has per_page_max => (isa => Int, is => 'rw', lazy_build => 1);
sub _build_page { 1  };
sub _build_per_page { 10 };
sub _build_per_page_max { 100 };
sub _build_pager { shift->current_collection->pager };
sub adopt_page {
  my ($self) = @_;
  #$self->clear_paged_collection;

  $self->clear_pager;
  $self->clear_current_collection;
};

after clear_page => sub {
  my ($self) = @_;
  $self->clear_pager;
  $self->clear_current_collection;
};

around accept_events => sub { ('page','per_page', shift->(@_)); };

#implements build_paged_collection => as {
#  my ($self) = @_;
#  my $collection = $self->current_collection;
#  return $collection->where(undef, {rows => $self->per_page})->page($self->page);
#};

around _build_current_collection => sub {
  my $orig = shift;
  my ($self) = @_;
  my $collection = $orig->(@_);
  return $collection->where(undef, {rows => $self->per_page})->page($self->page);
};

1;

__END__;
