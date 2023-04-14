use 5.010001;
use strict;
use warnings;

package Story::Interact::Analyze;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001010';

use Story::Interact::State;

use Moo;
use Storable qw( dclone );
use Types::Common -types;
use namespace::clean;

has 'page_source' => (
	is        => 'ro',
	isa       => Object,
	required  => 1,
);

has 'data' => (
	is        => 'lazy',
	init_arg  => undef,
	builder   => 1,
);

sub _build_data {
	my ( $self ) = @_;
	
	my @page_ids = $self->page_source->all_page_ids;
	my %data;
	
	# Allow the `main` page to define NPCs, etc, first.
	my $state = Story::Interact::State->new;
	$self->page_source->get_page( $state, 'main' );
	
	for my $page_id ( @page_ids ) {
		$data{$page_id}{exists} = 1;
		
		my $page_source = $self->page_source->get_source_code( $page_id ) or next;
		my @naive_links;
		while ( $page_source =~ /^ \s* next_page \s* \(? \s* (\S+) \s* [,=] /mxg ) {
			push @naive_links, $1;
		}
		@naive_links = map { /\A\w+\z/ ? $1 : scalar( eval $_ ) } @naive_links;
		
		my $naive_todo = 0;
		if ( $page_source =~ /^ \s* todo \b /mx ) {
			$naive_todo = 1;
		}
		
		my ( @explicit_links, $explicit_todo );
		my $cloned_state = dclone( $state );
		if ( my $page = eval { $self->page_source->get_page( $cloned_state, $page_id ) } ) {
			@explicit_links = map $_->[0], @{ $page->next_pages };
			$explicit_todo  = 0+!! $page->todo;
			$data{$page_id}{abstract} = $page->abstract;
			$data{$page_id}{location} = $page->location;
		}
		else {
			$data{$page_id}{error} = 1;
		}
		
		my @all_links = do {
			my %tmp;
			$tmp{$_}++ for @explicit_links;
			$tmp{$_}++ for @naive_links;
			keys %tmp;
		};
		
		$data{$page_id}{todo} = $explicit_todo // $naive_todo;
		$data{$page_id}{outgoing} = \@all_links;
		$data{$page_id}{incoming} //= [];
		for my $link_id ( @all_links ) {
			$data{$link_id} //= { exists => 0 };
			$data{$link_id}{incoming} //= [];
			push @{ $data{$link_id}{incoming} }, $page_id;
		}
	}
	
	\%data;
}

sub _quote {
	my ( $str ) = @_;
	$str =~ s/"/""/g;
	qq{"$str"};
}

sub to_tabbed {
	my ( $self ) = @_;
	my $data = $self->data;
	my $out = '';
	
	$out .= join(
		"\t",
		'Page Id',
		'Not Found',
		'Errors',
		'Todo',
		'Abstract',
		'Location',
		'Outgoing Links',
		'Incoming Links',
	) . "\n";
	
	for my $page_id ( sort keys %$data ) {
		my $d = $data->{$page_id};
		$out .= join(
			"\t",
			$page_id,
			$d->{exists} ? '' : 'not found',
			$d->{error}  ? 'error' : '',
			$d->{todo}   ? 'todo' : '',
			_quote( $d->{abstract} // '?' ),
			_quote( $d->{location} // '?' ),
			join( q{;}, sort @{ $d->{outgoing} || [] } ),
			join( q{;}, sort @{ $d->{incoming} || [] } ),
		) . "\n";
	}
	
	return $out;
}

1;

