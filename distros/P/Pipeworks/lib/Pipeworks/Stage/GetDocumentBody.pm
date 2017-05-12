package Pipeworks::Stage::GetDocumentBody;

use Mojo::Base qw( Pipeworks::Stage );

has gets => sub { {
	res	=> 'Mojo::Message::Response',
} };

has sets => sub { {
	body	=> 'Mojo::DOM',
} };

sub process
{
	my ( $self, $message ) = @_;
	my $res = $self->get( res => $message );

	my $dom = $res->dom;
	my $body = $dom->at( 'body' );

	$self->set( body => $message => $body );
}

1;

