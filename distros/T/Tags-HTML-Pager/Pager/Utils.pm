package Tags::HTML::Pager::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use POSIX qw(ceil);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(adjust_actual_page compute_index_values
	pages_num);

our $VERSION = 0.04;

sub adjust_actual_page {
	my ($input_actual_page, $pages) = @_;

	if (! defined $pages) {
		err 'Not defined number of pages.';
	}
	if ($pages !~ m/^\d+$/ms) {
		err 'Number of pages must be a positive number.';
	}

	# No pages.
	if ($pages == 0) {
		return;
	}

	my $actual_page;
	if (! defined $input_actual_page) {
		$actual_page = 1;
	} else {
		$actual_page = $input_actual_page;
	}

	if ($actual_page > $pages) {
		$actual_page = $pages;
	}

	return $actual_page;
}

sub compute_index_values {
	my ($items, $actual_page, $items_on_page) = @_;

	if (! defined $actual_page) {
		return ();
	}

	my ($begin_index, $end_index);
	$begin_index = ($actual_page - 1) * $items_on_page;
	$end_index = ($actual_page * $items_on_page) - 1;
	if ($end_index + 1 > $items) {
		$end_index = $items - 1;
	}

	return ($begin_index, $end_index);
}

sub pages_num {
	my ($items, $items_on_page) = @_;

	my $pages = 0;
	if (defined $items && defined $items_on_page) {
		$pages = ceil($items / $items_on_page);
	}

	return $pages;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Pager::Utils - Pager utilities.

=head1 SYNOPSIS

 use Tags::HTML::Pager::Utils qw(adjust_actual_page compute_index_values pages_num);

 my $actual_page = adjust_actual_page($input_actual_page, $pages);
 my ($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);
 my $pages = pages_num($items, $items_on_page);

=head1 SUBROUTINES

=head2 C<adjust_actual_page>

 my $actual_page = adjust_actual_page($input_actual_page, $pages);

Adjust actual page.

Arguments:

 - C<$input_actual_page> - Input value for actual page. This is value for adjust.
 - C<$pages> - Number of pages.

Returns number.

=head2 C<compute_index_values>

 my ($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);

Compute begin and end index in items list.

Arguments:

 - C<$items> - Number of items.
 - C<$actual_page> - Actual page of items.
 - C<$items_on_page> - Items on page.

Returns array with begin and end index.

=head2 C<pages_num>

 my $pages = pages_num($items, $items_on_page);

Compute number of pages from C<$items> and C<$items_on_page>.
If input arguments are undefined, returns 0.

Returns number.

=head1 ERRORS

 adjust_actual_page():
         Not defined number of pages.
         Number of pages must be a positive number.

=head1 EXAMPLE1

=for comment filename=adjust_actual_page.pl

 use strict;
 use warnings;

 use Tags::HTML::Pager::Utils qw(adjust_actual_page);

 # Input informations.
 my $input_actual_page = 10;
 my $pages = 5;

 # Compute;
 my $actual_page = adjust_actual_page($input_actual_page, $pages);

 # Print out.
 print "Input actual page: $input_actual_page\n";
 print "Number of pages: $pages\n";
 print "Adjusted actual page: $actual_page\n";

 # Output:
 # Input actual page: 10
 # Number of pages: 5
 # Adjusted actual page: 5

=head1 EXAMPLE2

=for comment filename=compute_index_values.pl

 use strict;
 use warnings;

 use Tags::HTML::Pager::Utils qw(compute_index_values);

 # Input informations.
 my $items = 55;
 my $actual_page = 2;
 my $items_on_page = 10;

 # Compute.
 my ($begin_index, $end_index) = compute_index_values($items, $actual_page, $items_on_page);

 # Print out.
 print "Items: $items\n";
 print "Actual page: $actual_page\n";
 print "Items on page: $items_on_page\n";
 print "Begin index: $begin_index\n";
 print "End index: $end_index\n";

 # Output:
 # Items: 55
 # Actual page: 2
 # Items on page: 10
 # Computed begin index: 10
 # Computed end index: 19

=head1 EXAMPLE3

=for comment filename=pages_num.pl

 use strict;
 use warnings;

 use Tags::HTML::Pager::Utils qw(pages_num);

 # Input informations.
 my $items = 123;
 my $items_on_page = 20;

 # Compute.
 my $pages = pages_num($items, $items_on_page);

 # Print out.
 print "Items count: $items\n";
 print "Items on page: $items_on_page\n";
 print "Number of pages: $pages\n";

 # Output:
 # Items count: 123
 # Items on page: 20
 # Number of pages: 7 

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<POSIX>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Pager>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
