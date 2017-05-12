package Mongol::Roles::Pagination;

use Moose::Role;

use Mongol::Models::Page;

use constant {
	PAGINATION_DEFAULT_START => 0,
	PAGINATION_DEFAULT_ROWS => 10,
};

requires 'count';
requires 'find';

sub paginate {
	my ( $class, $query, $start, $rows, $options ) = @_;

	$options ||=  {};
	$options->{skip} = $start || PAGINATION_DEFAULT_START;
	$options->{limit} = $rows || PAGINATION_DEFAULT_ROWS;

	my $total = $class->count( $query );
	my @items = $class->find( $query, $options )
		->all();

	my $page = Mongol::Models::Page->new(
		{
			items => \@items,
			total => $total,
			start => $options->{skip},
			rows => $options->{limit},
		}
	);

	return $page;
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Mongol::Roles::Pagination - Pagination for Mongol models

=head1 SYNOPSIS

	use POSIX qw( ceil );
	use Data::Dumper;

	my $page = Models::Person->paginate( { age => { '$gt' => 25 } }, 0, 10 );

	my $total_pages = ceil( $page->total() / $page->rows() );
	my $current_page = ( $page->start() / $page->rows() ) + 1;

	printf( "%s", Dumper( $page->serialize() ) );

=head1 DESCRIPTION

=head1 METHODS

=head2 paginate

	my $page = Models::Person->paginate( { first_name => 'John' }, 0, 10, {} );

=head1 SEE ALSO

=over 4

=item *

L<Mongol::Models::Page>

=back

=cut
