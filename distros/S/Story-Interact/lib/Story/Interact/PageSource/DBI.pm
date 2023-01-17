use 5.010001;
use strict;
use warnings;

package Story::Interact::PageSource::DBI;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001004';

use Moo;
use Types::Common -types;
use Types::Path::Tiny -types;
use namespace::clean;

with 'Story::Interact::PageSource';

has 'dbh' => (
	is        => 'ro',
	isa       => Object,
	required  => 1,
);

has 'sth' => (
	is        => 'ro',
	isa       => Object,
	builder   => 1,
);

sub _build_sth {
	my ( $self ) = @_;
	return $self->dbh->prepare('SELECT content FROM page WHERE id=?');
}


sub get_source_code {
	my ( $self, $page_id ) = @_;
	my $sth = $self->sth;
	$sth->execute( $page_id );
	if ( my ( $content ) = $sth->fetchrow_array ) {
		return $content;
	}
	return;
}

1;
