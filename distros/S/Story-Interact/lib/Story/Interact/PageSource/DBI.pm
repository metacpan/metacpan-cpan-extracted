use 5.010001;
use strict;
use warnings;

package Story::Interact::PageSource::DBI;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001011';

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
	is        => 'lazy',
	isa       => Object,
	builder   => sub { my $s = shift; $s->dbh->prepare( $s->sql ) },
);

has 'sql' => (
	is        => 'lazy',
	isa       => Str,
	builder   => sub { 'SELECT content FROM page WHERE id=?' }
);

sub _build_sth {
	
	return ;
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

sub all_page_ids {
	my ( $self ) = @_;
	map $_->[0], @{ $self->dbh->selectall_arrayref('SELECT id FROM page') };
}

1;
