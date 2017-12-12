use strictures 1;
package Mojito::Collection::Present;
$Mojito::Collection::Present::VERSION = '0.25';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Mojito::Collection::CRUD;
use List::MoreUtils qw/ first_index /;

has db => (is => 'ro', lazy => 1);

has config => (is => 'ro', lazy => 1);

has 'collection' => (
    is => 'ro',
    isa => HashRef,
    lazy => 1,
    builder => '_build_collection',
);
sub _build_collection {
    my $self = shift;
    die "Must have collection id" if !$self->collection_id;
    return Mojito::Collection::CRUD->new(config => $self->config, db => $self->db)->read($self->collection_id);
}

has 'collection_id' => (
    is => 'ro',
    isa => Value,
    required => 1,
);

has 'page_ids' => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_page_ids',
);
sub _build_page_ids {
    return $_[0]->collection->{'collected_page_ids'};
}

# The focus_page is the slot number of the page being view where the slot number
# comes from the ArrayRef of pages that make up the collection.
# The index page (list of links to all pages of the collection) is, by convention,
# indicated by a -1.
has 'focus_page_id'  => (
    is => 'ro',
);

has 'focus_page_number' => (
    is => 'rw',
    isa => Int,
    builder => '_build_focus_page_number', 
);
sub _build_focus_page_number {
    my $self = shift;
    
    return -1 if !$self->focus_page_id;
    return first_index { $_ eq $self->focus_page_id } @{$self->page_ids};
}

has 'focus_page_route' => (
    is => 'ro',
    builder => '_build_focus_page_route',
);
sub _build_focus_page_route {
    my $self = shift;
    
    my $URI_fragment;
    # Handle index case
    if ($self->focus_page_number == -1) {
        $URI_fragment = 'collection/' . $self->collection->{id};
    }
    else {
        $URI_fragment = 'page/' . $self->page_ids->[$self->focus_page_number];
    }
    return $URI_fragment;
}

has 'index_page_route' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_index_page_route',
);
sub _build_index_page_route {
    return 'collection/' . $_[0]->index_page_id;
}

has 'next_page_route' => (
    is => 'ro',
    builder => '_build_next_page_route',
);
sub _build_next_page_route {
    my $self = shift;
    
    # Are we focused on index => first_page
    # Are we focused on last => index
    # Are we focused on any other page => focus + 1
    my $focus = $self->focus_page_number;
    warn "index page id empty: " if !$self->index_page_id;
    my $collection_route = 'collection/' . $self->index_page_id;
    my $next;
    if ($focus == -1) {
        $next = $collection_route . '/page/' . $self->first_page_id;
    }
    elsif ($focus == $self->last_page_number) {
        $next = $collection_route;
    }
    else {
        $next = $collection_route . '/page/' . $self->page_ids->[($self->focus_page_number + 1)];
    }
    
    return $next;
}

has 'previous_page_route' => (
    is => 'ro',
    builder => '_build_previous_page_route',
);
sub _build_previous_page_route {
    my $self = shift;
    
    # Are we focused on index => last page
    # Are we focused on first => index
    # Are we focused on any other page => focus - 1
    my $focus = $self->focus_page_number;
    my $collection_route = 'collection/' . $self->index_page_id;
    my $previous;
    if ($focus == -1) {
        $previous = $collection_route . '/page/' . $self->last_page_id;
    }
    elsif ($focus == $self->first_page_number) {
        $previous = 'collection/' . $self->index_page_id;
    }
    else {
        $previous = $collection_route . '/page/' . $self->page_ids->[($self->focus_page_number - 1)];
    }
    
    return $previous;
}

has 'first_page_id' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_first_page_id',
);
sub _build_first_page_id {
    $_[0]->page_ids->[0];
}

has 'last_page_id' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_last_page_id',
);
sub _build_last_page_id {
    $_[0]->page_ids->[-1];
}

has 'index_page_id' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_index_page_id',
);
sub _build_index_page_id { $_[0]->collection->{_id}||$_[0]->collection->{id} }

has 'index_page_number' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_index_page_number',
);
sub _build_index_page_number { -1 }

has 'first_page_number' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_first_page_number',
);
sub _build_first_page_number { 0 }


has 'last_page_number' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_last_page_number',
);
sub _build_last_page_number {
    (scalar @{$_[0]->page_ids}) - 1;
}

1
