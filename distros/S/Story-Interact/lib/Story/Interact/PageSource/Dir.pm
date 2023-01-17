use 5.010001;
use strict;
use warnings;

package Story::Interact::PageSource::Dir;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001004';

use Moo;
use Types::Common -types;
use Types::Path::Tiny -types;
use namespace::clean;

with 'Story::Interact::PageSource';

has 'dir' => (
	is        => 'ro',
	isa       => Dir,
	coerce    => 1,
	required  => 1,
);

sub get_source_code {
	my ( $self, $page_id ) = @_;
	my $file = $self->dir->child( join q[.], $page_id, 'page.pl' );
	return unless $file->exists;
	return $file->slurp_utf8;
}

1;
