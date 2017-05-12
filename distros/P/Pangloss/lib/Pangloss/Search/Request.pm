=head1 NAME

Pangloss::Search::Request - wrapper around a set of search filters

=head1 SYNOPSIS

  use Pangloss::Search;
  use Pangloss::Search::Request;
  my $srequest = new Pangloss::Search::Request;

  $srequest->language( 'foo', $boolean )
           ->toggle_category( $category->key )
           ->keywords( 'foo bar baz' )
           ->document_uri( $uri )
           ->document( $text );

  my $search = new Pangloss::Search;
  $search->add_filters( $srequest->get_filters );
         ->apply;

=cut

package Pangloss::Search::Request;

use URI;
use LWP::Simple qw( get );
use Scalar::Util qw( blessed );

use Pangloss::HTML::Stripper;

use Pangloss::Search::Filter::Keyword;
use Pangloss::Search::Filter::Document;
use Pangloss::Search::Filter::Category;
use Pangloss::Search::Filter::Concept;
use Pangloss::Search::Filter::Language;
use Pangloss::Search::Filter::Proofreader;
use Pangloss::Search::Filter::Translator;
use Pangloss::Search::Filter::Status;
use Pangloss::Search::Filter::DateRange;

use base      qw( Pangloss::Object );
use accessors qw( filters modified document_uri );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.13 $ '))[2];

sub init {
    my $self = shift;
    $self->filters( $self->default_filters );
}

sub default_filters {
    return {
	    keyword     => Pangloss::Search::Filter::Keyword->new,
	    document    => Pangloss::Search::Filter::Document->new,
	    category    => Pangloss::Search::Filter::Category->new,
	    concept     => Pangloss::Search::Filter::Concept->new,
	    language    => Pangloss::Search::Filter::Language->new,
	    proofreader => Pangloss::Search::Filter::Proofreader->new,
	    translator  => Pangloss::Search::Filter::Translator->new,
	    status      => Pangloss::Search::Filter::Status->new,
	    date_range  => Pangloss::Search::Filter::DateRange->new,
	   };
}

#------------------------------------------------------------------------------
# Make filters look like accessors...

sub keyword {
    my $self = shift;
    my $filter = $self->filters->{keyword};
    if (@_) {
	$self->modified(1) and $filter->set( $_[0] ) if ($filter->get ne $_[0]);
	return $self;
    } else {
	return $self->filters->{keyword}->get
    }
}

sub document {
    my $self = shift;
    my $filter = $self->filters->{document};
    if (@_) {
	$self->modified(1) and $filter->set( $_[0] ) if ($filter->get ne $_[0]);
	return $self;
    } else {
	return $self->filters->{document}->get
    }
}

# Create accessors for filters that don't already have one
{
    no strict 'refs';
    foreach my $property (qw( status concept language category
			      date_range translator proofreader )) {
	next if __PACKAGE__->can( $property );
	*{$property} = sub {
	    my $self = shift;
	    my $key  = shift;
	    if (@_) { return $self->set_filter_key( $property, $key, @_ ); }
	    else    { return $self->filters->{$property}->is_set( $key ); }
	};
    }
}


#------------------------------------------------------------------------------
# generic filter methods

sub set_filter_key {
    my $self  = shift;
    my $type  = shift;
    my $thing = shift;
    my $val   = shift;
    my $key   = blessed($thing) ? $thing->key : $thing;
    my $filter = $self->filters->{$type};
    if ($val) {
	if ($filter->not_set( $key )) {
	    $filter->set( $key );
	    $self->modified(1);
	}
    } elsif ($filter->is_set( $key )) {
	$filter->unset( $key );
	$self->modified(1);
    }
    return $self;
}

sub toggle_filter {
    my $self  = shift;
    my $type  = shift;
    my $thing = shift;
    my $key   = blessed($thing) ? $thing->key : $thing;
    $self->modified(1)
         ->filters->{$type}->toggle( $key );
    return $self;
}

sub is_filter_selected {
    my $self  = shift;
    my $type  = shift;
    my $thing = shift;
    my $key   = blessed($thing) ? $thing->key : $thing;
    return $self->filters->{$type}->is_set( $key );
}


#------------------------------------------------------------------------------
# toggles

sub toggle_category {
    shift->toggle_filter( 'category', shift );
}

sub toggle_concept {
    shift->toggle_filter( 'concept', shift );
}

sub toggle_language {
    shift->toggle_filter( 'language', shift );
}

sub toggle_proofreader {
    shift->toggle_filter( 'proofreader', shift );
}

sub toggle_translator {
    shift->toggle_filter( 'translator', shift );
}

sub toggle_status {
    shift->toggle_filter( 'status', shift );
}

sub toggle_date_range {
    shift->toggle_filter( 'date_range', shift );
}

#------------------------------------------------------------------------------
# is selected tests

sub is_category_selected {
    shift->is_filter_selected( 'category', shift );
}

sub is_concept_selected {
    shift->is_filter_selected( 'concept', shift );
}

sub is_language_selected {
    shift->is_filter_selected( 'language', shift );
}

sub is_proofreader_selected {
    shift->is_filter_selected( 'proofreader', shift );
}

sub is_translator_selected {
    shift->is_filter_selected( 'translator', shift );
}

sub is_status_selected {
    shift->is_filter_selected( 'status', shift );
}

sub is_date_range_selected {
    shift->is_filter_selected( 'date_range', shift );
}


#------------------------------------------------------------------------------

sub get_filters {
    my $self = shift;
    my @filters;

    foreach my $type (keys %{ $self->filters }) {
	my $filter = $self->filters->{$type};
	push @filters, $filter unless ($filter->is_empty);
    }

    $self->modified(0);

    return wantarray ? @filters : \@filters;
}


#------------------------------------------------------------------------------
# Document/URI

sub load_document_from {
    my $self = shift;
    my $uri  = shift;

    unless ($uri) {
	return $self->document( undef )
	            ->document_uri( undef );
    }

    $uri = $self->create_uri_from( $uri )
      unless (blessed $uri and $uri->isa( 'URI' ));

    unless ($self->is_document_loaded_from( $uri )) {
	$self->document_uri( $uri )
	     ->download_document_uri;
    }

    return $self;
}

sub download_document_uri {
    my $self = shift;
    my $uri  = $self->document_uri;

    $self->emit( "downloading $uri..." );
    $uri = URI->new( $uri );

    # TODO: throw error on unable to d/l
    # assume it's HTML
    my $html = LWP::Simple::get( $uri );
    my $text = Pangloss::HTML::Stripper->new->strip( $html );

    # set to a non-empty string for get_filters()
    $text ||= ' ';

    $self->document( $text );
}

sub create_uri_from {
    my $self = shift;
    my $uri  = shift;
    $uri =~ s|\A(?!http)|http://|;
    $uri;
}

sub is_document_loaded_from {
    my $self = shift;
    my $uri  = shift;
    return ( ($self->document_uri eq $uri) && ($self->document) );
}


1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class is a wrapper around the Pangloss::Search::Filters, designed to
preserve the current state of a user's search criteria in such a way that it
can be refined over a number of requests.

=head1 METHODS

TODO: document API methods.

=over 4

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss::Search>,
L<Pangloss::Search::Results>,
L<Pangloss::Search::Filter>,
L<Pangloss::Search::Filter::Category>,
L<Pangloss::Search::Filter::Concept>,
L<Pangloss::Search::Filter::Language>,
L<Pangloss::Search::Filter::Proofreader>,
L<Pangloss::Search::Filter::Translator>,
L<Pangloss::Search::Filter::Status>,
L<Pangloss::Search::Filter::Keyword>,
L<Pangloss::Search::Filter::Document>,
L<Pangloss::Search::Filter::DateRange>,

=cut

