package Pangloss::Search::Results::Pager;

use POSIX qw( ceil );

use base      qw( Pangloss::Object );
use accessors qw( order page page_size results );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

our $DEFAULT_PAGE      = 1;
our $DEFAULT_PAGE_SIZE = 10;
our %ORDER_METHOD =
  (
   # order_by => Pager method containing collection
   concept  => 'concepts',
   language => 'languages'
  );
our %RESULTS_METHOD =
  (
   # order_by => PG::Search::Results method
   concept  => 'by_concept',
   language => 'by_language'
  );

sub init {
    shift->page( $DEFAULT_PAGE )
         ->page_size( $DEFAULT_PAGE_SIZE )
	 ->order( [] );
}

sub concepts {
    my $self = shift;
    return $self->results->concepts;
}

sub languages {
    my $self = shift;
    return $self->results->languages;
}

sub page_concepts {
    my $self = shift;
    my $results = $self->get_current_results_page || return;
    return $results->concepts;
}

sub page_languages {
    my $self = shift;
    my $results = $self->get_current_results_page || return;
    return $results->languages;
}

sub pages {
    my $self = shift;
    return ceil( $self->results->size / $self->page_size );
}

sub pages_list {
    my $self = shift;
    my @pages = (1 .. $self->pages);
    return wantarray ? @pages : \@pages;
}

sub prev_page {
    my $self = shift;
    return $self->page > 1 ? $self->page - 1 : undef;
}

sub next_page {
    my $self = shift;
    return $self->page < $self->pages ? $self->page + 1 : undef;
}

sub size {
    my $self = shift;
    my $results = $self->get_current_results_page;
    return $results ? $results->size : 0;
}

sub total_size {
    my $self = shift;
    return $self->results->size;
}

sub start_number {
    my $self = shift;
    return ($self->page - 1) * $self->page_size + 1;
}

sub end_number {
    my $self = shift;
    return ($self->page - 1) * $self->page_size + $self->size;
}

sub is_empty {
    my $self = shift;
    my $results = $self->get_current_results_page;
    return $results ? $results->is_empty : 1;
}

sub not_empty {
    my $self = shift;
    my $results = $self->get_current_results_page;
    return $results ? $results->not_empty : 0;
}

sub order_by {
    my $self = shift;

    foreach my $order (@_) {
	unless ($self->can_order_by( $order )) {
	    $self->emit( "don't know how to order by $order!" );
	    next;
	}
	push @{ $self->order }, $order;
    }

    return $self;
}

sub list {
    my $self    = shift;
    my $results = $self->get_current_results_page || return wantarray ? () : [];
    return $results->list;
}

# list_by( order1_val, order2_val ... )
# get results on current page by given order (see order())
# see also _build_caches()
# TODO: think of a better name for this.
sub list_by {
    my $self = shift;

    $self->emit( "WARNING: list_by needs parameters!\n" ) unless (@_);

    my %order = map { $_ => shift } @{ $self->order };

    $self->emit( "WARNING: list_by parameters exceed number of orders!\n" ) if (@_);

    # the cache has already been ordered, so walk to the specified entry:
    my $cache = $self->_get_ordered_cache;
    for my $key ( @{ $self->order } ) {
	$cache = $cache->{$key}->{$order{$key}} || return wantarray ? () : [];
    }

    my $results = $cache->{page}->{$self->page} || return wantarray ? () : [];

    return $results->list;
}

sub can_order_by {
    my $self = shift;
    return exists $ORDER_METHOD{shift()};
}

sub get_order_method {
    my $self = shift;
    return $ORDER_METHOD{shift()};
}

sub get_results_method {
    my $self  = shift;
    return $RESULTS_METHOD{shift()};
}

sub get_current_results_page {
    my $self = shift;
    return $self->_get_page_cache->{$self->page};
}

sub _get_page_cache {
    my $self = shift;
    $self->_build_caches unless ( $self->{_page_cache} );
    return $self->{_page_cache};
}

sub _get_ordered_cache {
    my $self = shift;
    $self->_build_caches unless ( $self->{_ordered_cache} );
    return $self->{_ordered_cache};
}

# builds 2 caches of ordered results, ala:
#
#   $self->{_page_cache} =
#     {
#      $page_no => $results,
#     };
#
#   $self->{_ordered_cache} =
#     {
#      concept => {
#        $concept => {
#          language => {
#            $language => {
#             page => { $page => $results }
#            }
#          }
#        }
#      }
#     };
#
sub _build_caches {
    my $self = shift;

    $self->{_page_cache}    = {};
    $self->{_ordered_cache} = {};
    $self->{_num_results}   = 0;
    $self->{_current_page}  = 1;

    $self->_build_ordered_caches(
				 $self->{_ordered_cache},
				 $self->results,
				 @{ $self->order }
				);
}

# _build_ordered_caches( \%ordered_cache, $results, @order )
sub _build_ordered_caches {
    my $self    = shift;
    my $cache   = shift;
    my $results = shift;
    my $order   = shift;

    return $self->_last_order( $cache, $results ) unless ($order);

    my $order_by_method = $self->get_results_method( $order );

    foreach my $item ( $self->get_order_items( $order ) ) {
	# use key over object for use in list_by()
	my $key = Pangloss::Collection->get_values_key( $item );
	my $new_results = $results->$order_by_method( $item );
	if ( $new_results->not_empty ) {
	    $self->_build_ordered_caches( $cache->{$order}->{$key} = {},
					  $new_results,
					  @_ );
	}
    }

    return $self;
}

sub _last_order {
    my $self    = shift;
    my $cache   = shift;
    my $results = shift;

    # keep track of what page we're on
    my $size      = $results->size;
    my $page_size = $self->page_size;
    my $counter   = $self->{_num_results};
    my $page      = $self->{_current_page};

    # add each term 1 by one, in order, flipping page as needed:
    foreach my $term ($results->sorted_list) {
	$self->emit( "$counter : ". $term->key );

	$self->{_page_cache}->{$page} =
	  Pangloss::Search::Results->new->parent($self->results)
	    unless $self->{_page_cache}->{$page};
	$self->{_page_cache}->{$page}->add( $term );

	$cache->{page}->{$page} =
	  Pangloss::Search::Results->new->parent($self->results)
	    unless $cache->{page}->{$page};
	$cache->{page}->{$page}->add( $term );

	$counter++;
	$page++	if ($counter % $page_size == 0);
    }

    $self->{_num_results}  = $counter;
    $self->{_current_page} = $page;

    return $self;
}

sub get_order_items {
    my $self  = shift;
    my $order = shift;
    my $order_method = $self->get_order_method( $order );
    return ( $self->$order_method->sorted_list );
}

sub get_order_results {
    my $self  = shift;
    my $order = shift;
    my $item  = shift;
    my $results = shift || $self->results;
    my $order_by_method = $self->get_results_method( $order );
    return $results->$order_by_method( $item );
}


1;

__END__

# TODO: re-implement with iterators?
