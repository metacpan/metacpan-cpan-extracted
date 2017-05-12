package POE::Component::Client::Feed;
BEGIN {
  $POE::Component::Client::Feed::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $POE::Component::Client::Feed::VERSION = '0.901';
}
# ABSTRACT: Event based feed client

use MooseX::POE;

use POE qw(
	Component::Client::HTTP
);

use HTTP::Request;
use XML::Feed;

our $VERSION ||= '0.0development';

has logger => (
	isa => 'Object',
	is => 'rw',
	predicate => 'has_logger',
);

has http_agent => (
	is => 'ro',
	isa => 'Str',
	default => sub { __PACKAGE__.'/'.$VERSION },
	required => 1,
);

has alias => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	default => sub { 'feed' },
);

has http_alias => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	lazy => 1,
	default => sub {
		my ( $self ) = @_;
		$self->http_client;
		return $self->_http_alias;
	},
);

has _http_alias => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;
		return $self->alias.'_http';
	},
);

has http_timeout => (
	is => 'ro',
	isa => 'Int',
	required => 1,
	default => sub { 30 },
);

has http_keepalive => (
	isa => 'POE::Component::Client::Keepalive',
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->logger->info($self->logger_prefix.'Startup POE::Component::Client::Keepalive') if $self->has_logger;
		POE::Component::Client::Keepalive->new(
			keep_alive    => 20, # seconds to keep connections alive
			max_open      => 100, # max concurrent connections - total
			max_per_host  => 100, # max concurrent connections - per host
			timeout       => 10, # max time (seconds) to establish a new connection
		)
	},
);

has http_followredirects => (
	is => 'ro',
	isa => 'Int',
	required => 1,
	default => sub { 5 },
);

has http_client => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;
		$self->logger->info($self->logger_prefix.'Startup POE::Component::Client::HTTP') if $self->has_logger;
		POE::Component::Client::HTTP->spawn(
			Agent     => $self->http_agent,
			Alias     => $self->_http_alias,
			Timeout   => $self->http_timeout,
			ConnectionManager => $self->http_keepalive,
			FollowRedirects => $self->http_followredirects,
		);
	},
);

sub START {
	my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
	$kernel->alias_set($self->alias);
}

event 'request' => sub {
	my ( $self, $sender, $feed, $response_event, $tag ) = @_[ OBJECT, SENDER, ARG0..$#_ ];
	$self->logger->debug($self->logger_prefix.'Request of feed '.$feed.' requested') if $self->has_logger;
	$response_event = 'feed_received' if !$response_event;
	my $request;
	if (ref $feed) {
		$request = $feed;
	} else {
		$request = HTTP::Request->new(GET => $feed);
	}
	POE::Kernel->post(
		$self->http_alias,
		'request',
		'http_received',
		$request,
		[ $sender, $feed, $response_event, $tag ],
	);
};

event 'http_received' => sub {
	my ( $self, @args ) = @_[ OBJECT, ARG0..$#_ ];
	$self->logger->debug($self->logger_prefix.'HTTP Received') if $self->has_logger;
	my $request_packet = $args[0];
	my $response_packet = $args[1];
	my $request_object  = $request_packet->[0];
	my $response_object = $response_packet->[0];
	my ( $sender, $feed, $response_event, $tag ) = @{$request_packet->[1]};
	$self->logger->debug($self->logger_prefix.'Received from '.$feed) if $self->has_logger;
	my $content = $response_object->content;
	my $xml_feed;
	eval {
		$xml_feed = XML::Feed->parse(\$content);
		$xml_feed = XML::Feed->errstr if !$xml_feed;
	};
	$xml_feed = $@ if $@;
	# i dont understand that really... need a case (Getty)
	# if (ref $response_event) {
		# $response_event->postback->($xml_feed);
	# } else {
		$self->logger->debug($self->logger_prefix.'Post result') if $self->has_logger;
		POE::Kernel->post( $sender, $response_event, $request_object, $xml_feed, $tag );
	# }
};

sub logger_prefix {
	my $self = shift;
	__PACKAGE__.' ('.$self->get_session_id.') ';
}

1;



=pod

=head1 NAME

POE::Component::Client::Feed - Event based feed client

=head1 VERSION

version 0.901

=head1 SYNOPSIS

  package MyServer;
  use MooseX::POE;
  use POE::Component::Client::Feed;

  has feed_client => (
    is => 'ro',
    default => sub {
      POE::Component::Client::Feed->new();
    }
  );

  event feed_received => sub {
    my ( $self, @args ) = @_[ OBJECT, ARG0..$#_ ];
    my $http_request = $args[0];
    my $xml_feed = $args[1];
    my $tag = $args[2];
  };

  sub START {
    my ( $self ) = @_;
	$self->feed_client->yield('request','http://news.perlfoundation.org/atom.xml','feed_received','tag');
  }

=head1 DESCRIPTION

This POE Component gives you like L<POE::Component::Client::HTTP> an event based way of fetching from a feed. It is not made
for making consume a feed and only get events on new headlines, for this you can use L<POE::Component::FeedAggregator> which is
based on this module, or L<POE::Component::RSSAggregator>.

=head1 SEE ALSO

=over 4

=item *

L<POE::Component::FeedAggregator>

=item *

L<POE::Component::Client::HTTP>

=item *

L<XML::Feed>

=item *

L<MooseX::POE>

=item *

L<POE::Component::RSSAggregator>

=back

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

