package Pipeworks::Stage::FetchURL;

use Mojo::Base qw( Pipeworks::Stage );
use Mojo::UserAgent;

has gets => sub { {
	url	=> ['','Mojo::URL'],
} };

has sets => sub { {
	res	=> 'Mojo::Message::Response',
} };

sub process
{
	my ( $self, $message ) = @_;
	my $url = $self->get( url => $message );

	my $ua = Mojo::UserAgent->new();
	my $tx = $ua->get( $url );
	my $res = $tx->success();

	unless ( $res ) {
		my ( $reason, $code ) = $tx->error();

		die( "[$code] $reason" );
	}

	$self->set( res => $message => $res );
}

1;

