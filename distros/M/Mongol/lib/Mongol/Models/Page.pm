package Mongol::Models::Page;

use Moose;

extends 'Mongol::Model';

has 'items' => (
	is => 'ro',
	isa => 'ArrayRef[Mongol::Model]',
	default => sub { [] },
);

has 'total' => (
	is => 'ro',
	isa => 'Int',
	default => 0,
);

has 'start' => (
	is => 'ro',
	isa => 'Int',
	default => 0,
);

has 'rows' => (
	is => 'ro',
	isa => 'Int',
	default => 0,
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Mongol::Models::Page - Result object for pagination

=head1 SYNOPSIS

	use POSIX qw( ceil );

	my $page = Models::Person->paginate( { age => { '$gt' => 25 } }, 0, 10 );

	my $total_pages = ceil( $page->total() / $page->rows() );
	my $current_page = ( $page->start() / $page->rows() ) + 1;

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 items

	my $array_ref = $page->items();

=head2 start

	my $start = $page->start();

=head2 rows

	my $rows = $page->rows();

=head1 SEE ALSO

=over 4

=item *

L<Mongol::Model>

=back

=cut
