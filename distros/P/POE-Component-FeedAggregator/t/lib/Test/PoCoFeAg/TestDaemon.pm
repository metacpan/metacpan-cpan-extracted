package Test::PoCoFeAg::TestDaemon;
use MooseX::POE;
use POE::Component::FeedAggregator;
use POE::Component::Server::HTTP;
use File::Spec::Functions;
use Slurp;

event new_feed_entry_fetchtest => sub {
	my ( $self, $feed, $entry ) = @_[ OBJECT, ARG0..$#_ ];
	::isa_ok($feed, "POE::Component::FeedAggregator::Feed", "Getting POE::Component::FeedAggregator::Feed object as first arg on new feed entry");
	if ($feed->name eq 'rss') {
		::isa_ok($entry, "XML::Feed::Entry::Format::RSS", "XML::Feed::Entry::Format::RSS object as second arg on new feed entry");
	} elsif ($feed->name eq 'atom') {
		::isa_ok($entry, "XML::Feed::Entry::Format::Atom", "XML::Feed::Entry::Format::Atom object as second arg on new feed entry");
	}
	$self->cnt_inc;
	POE::Kernel->stop if $self->cnt == 42;
};

event new_feed_entry_knowntest => sub {
	my ( $self, $feed, $entry ) = @_[ OBJECT, ARG0..$#_ ];
	::isa_ok($feed, "POE::Component::FeedAggregator::Feed", "Getting POE::Component::FeedAggregator::Feed object as first arg on new feed entry");
	::isa_ok($entry, "XML::Feed::Entry::Format::Atom", "XML::Feed::Entry::Format::Atom object as second arg on new feed entry");
	$self->cnt_inc;
};

event new_feed_entry_counttest => sub {
	my ( $self, $feed, $entry ) = @_[ OBJECT, ARG0..$#_ ];
	::isa_ok($feed, "POE::Component::FeedAggregator::Feed", "Getting POE::Component::FeedAggregator::Feed object as first arg on new feed entry");
	::isa_ok($entry, "XML::Feed::Entry::Format::Atom", "XML::Feed::Entry::Format::Atom object as second arg on new feed entry");
	$self->cnt_inc;
	POE::Kernel->stop if $self->cnt == 21;
};

event new_feed_entry_ignoretest => sub {
	my ( $self, $feed, $entry ) = @_[ OBJECT, ARG0..$#_ ];
	$self->cnt_inc;
};

event stop_that_peepeeness => sub {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
	$kernel->stop;
};

has data_path => ( is => 'ro', required => 1 );
has port => ( is => 'ro', required => 1 );

has cnt => ( traits  => ['Counter'], isa => 'Int', is => 'rw', default => sub { 0 }, handles => { cnt_inc => 'inc' } );

has server => ( is => 'rw', );
has client => ( is => 'rw', );

has test => ( is => 'ro', required => 1 );

sub BUILD {
	my ( $self ) = @_;
	$self->client(POE::Component::FeedAggregator->new());
}

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
	::isa_ok($self->client, "POE::Component::FeedAggregator", "Getting POE::Component::FeedAggregator object on new");
	if ($self->test eq 'fetchtest') {
		$self->client->add_feed({
			url => 'http://localhost:'.$self->port.'/atom',
			name => '01-atom',
			delay => 10,
			entry_event => 'new_feed_entry_'.$self->test,
			ignore_first => 0,
		});
		$self->client->add_feed({
			url => 'http://localhost:'.$self->port.'/rss',
			name => '01-rss',
			delay => 10,
			entry_event => 'new_feed_entry_'.$self->test,
			ignore_first => 0,
		});
	} elsif ($self->test eq 'knowntest') {
		$self->client->add_feed({
			url => 'http://localhost:'.$self->port.'/atom',
			name => '02-atom',
			delay => 2,
			entry_event => 'new_feed_entry_'.$self->test,
			ignore_first => 0,
		});
		$kernel->delay('stop_that_peepeeness', 10);
	} elsif ($self->test eq 'counttest') {
		$self->client->add_feed({
			url => 'http://localhost:'.$self->port.'/atom',
			name => '03-atom',
			delay => 10,
			max_headlines => 10,
			entry_event => 'new_feed_entry_'.$self->test,
			ignore_first => 0,
		});
	} elsif ($self->test eq 'ignoretest') {
		$self->client->add_feed({
			url => 'http://localhost:'.$self->port.'/atom',
			name => '04-atom',
			delay => 2,
			entry_event => 'new_feed_entry_'.$self->test,
		});
		$kernel->delay('stop_that_peepeeness', 10);
	}
}

1;