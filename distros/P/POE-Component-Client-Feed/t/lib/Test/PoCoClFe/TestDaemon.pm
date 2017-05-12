package Test::PoCoClFe::TestDaemon;
use MooseX::POE;
use POE::Component::Client::Feed;
use POE::Component::Server::HTTP;
use File::Spec::Functions;
use Slurp;

event 'feed_received' => sub {
	my ( $self, @args ) = @_[ OBJECT, ARG0..$#_ ];
	my $http_request = $args[0];
	my $xml_feed = $args[1];
	my $tag = $args[2];
	my $cnt = 0;
	for my $entry ($xml_feed->entries) {
		$cnt++;
	}
	::isa_ok($http_request, "HTTP::Request", "First arg is HTTP::Request on receive");
	if ($tag eq 'atom') {
		::isa_ok($xml_feed, "XML::Feed::Format::Atom", "Second arg is XML::Feed::Format::Atom on receive");
		$self->atom_cnt_inc($cnt);
		$self->client->yield('request','http://localhost:'.$self->port.'/rss','feed_received','rss');
	} elsif ($tag eq 'rss') {
		::isa_ok($xml_feed, "XML::Feed::Format::RSS", "Second arg is XML::Feed::Format::RSS on receive");
		$self->rss_cnt_inc($cnt);
		POE::Kernel->stop;
	}
};

has data_path => ( is => 'ro', required => 1 );
has port => ( is => 'ro', required => 1 );

has atom_cnt => ( traits  => ['Counter'], isa => 'Int', is => 'rw', default => sub { 0 }, handles => { atom_cnt_inc => 'inc' } );
has rss_cnt => ( traits  => ['Counter'], isa => 'Int', is => 'rw', default => sub { 0 }, handles => { rss_cnt_inc => 'inc' } );

has server => ( is => 'rw', );
has client => ( is => 'rw', );

sub START {
	my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];
	$self->server(POE::Component::Server::HTTP->new(
		Port => $self->port,
		ContentHandler => {
			'/atom' => sub { 
				my ($request, $response) = @_;
				$response->code(RC_OK);
				my $content = slurp( catfile( $self->data_path, "atom.xml" ) );
				$response->content( $content );
				$response->content_type('application/xhtml+xml');
				return RC_OK;
			},
			'/rss' => sub { 
				my ($request, $response) = @_;
				$response->code(RC_OK);
				my $content = slurp( catfile( $self->data_path, "rss.xml" ) );
				$response->content( $content );
				$response->content_type('application/xhtml+xml');
				return RC_OK;
			},
		},
		Headers => { Server => 'FeedServer' },
	));
	$self->client(POE::Component::Client::Feed->new());
	::isa_ok($self->client, "POE::Component::Client::Feed", "Getting POE::Component::Client::Feed object on new");
	$self->client->yield('request','http://localhost:'.$self->port.'/atom','feed_received','atom');
}

1;