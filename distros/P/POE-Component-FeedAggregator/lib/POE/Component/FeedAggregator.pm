package POE::Component::FeedAggregator;
BEGIN {
  $POE::Component::FeedAggregator::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $POE::Component::FeedAggregator::VERSION = '0.902';
}
# ABSTRACT: Watch multiple feeds (Atom or RSS) for new headlines 

use MooseX::POE;
use POE qw(
	Component::FeedAggregator::Feed
	Component::Client::Feed
);
use Cwd;
use IO::All;

our $VERSION ||= '0.0development';

has logger => (
	isa => 'Object',
	is => 'rw',
	predicate => 'has_logger',
);

has http_agent => (
	is => 'ro',
	isa => 'Str',
	required => 1,
	default => sub { __PACKAGE__.'/'.$VERSION },
);

has feed_client => (
	isa => 'POE::Component::Client::Feed',
	is => 'ro',
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		$self->logger->info($self->logger_prefix.'Starting up POE::Component::Client::Feed') if $self->has_logger;
		if ($self->has_logger) {
			POE::Component::Client::Feed->new({
				http_agent => $self->http_agent,
				logger   => $self->logger,
			});
		} else {
			POE::Component::Client::Feed->new({
				http_agent => $self->http_agent,
			});
		}
	},
);

has tmpdir => (
	isa => 'Str',
	is => 'ro',
	required => 1,
	default => sub { getcwd },
);

event feed_received => sub {
	my ( $self, $kernel, @args ) = @_[ OBJECT, KERNEL, ARG0..$#_ ];
	$self->logger->debug($self->logger_prefix.'Feed received') if $self->has_logger;
	my $http_request = $args[0];
	my $feed = $args[2];
	$self->logger->debug($self->logger_prefix.'Request feed '.$feed->url.' delayed with '.$feed->delay.' seconds') if $self->has_logger;
	$kernel->delay_add( 'request_feed', $feed->delay, $feed );
	my $xml_feed = $args[1];
	return if !(ref $xml_feed);
	my $cache_file = $self->tmpdir.'/'.$feed->name.'.feedcache';
	my @entries;
	my $ignore = 0;
	if (-f $cache_file) {
		@entries = io($cache_file)->slurp;
	} else {
		$ignore = $feed->ignore_first;
	}
	my @new_entries;
	$self->logger->debug($self->logger_prefix.( scalar $xml_feed->entries ).' Entries found') if $self->has_logger;
	for my $entry ($xml_feed->entries) {
		my $link = $entry->link;
		my $title = $entry->title;
		$link =~ s/ //g;
		my $known = 0;
		for (@entries) {
			chomp;
			if ( $_ =~ m/^(.+?) (.+)$/ ) {
				if ( $1 eq $link || $2 eq $title ) {
					$known = 1;
					last; 
				}
			}
		}
		next if $known;
		push @new_entries, $link.' '.$title;
		$kernel->post( $feed->sender, $feed->entry_event, $feed, $entry ) if (!$known and !$ignore);
	}
	$self->logger->debug($self->logger_prefix.( scalar @new_entries ).' new entries') if $self->has_logger;
	push @entries, @new_entries;
	my $count = @entries;
	my @save_entries = splice(@entries, $count - $feed->max_headlines > 0 ? $count - $feed->max_headlines : 0, $feed->max_headlines);
	$self->logger->debug($self->logger_prefix.'Saving cache file '.$cache_file) if $self->has_logger;
	scalar join("\n",@save_entries) > io($cache_file);
};

event request_feed => sub {
	my ( $self, $feed ) = @_[ OBJECT, ARG0..$#_ ];
	$self->logger->debug($self->logger_prefix.'Requesting feed '.$feed->url) if $self->has_logger;
	$self->feed_client->yield('request',$feed->url,'feed_received',$feed);
};

sub add_feed { shift->yield('_add_feed', @_); }

event _add_feed => sub {
	my ( $self, $sender, $feed_args ) = @_[ OBJECT, SENDER, ARG0..$#_ ];
	$feed_args->{sender} = $sender;
	my $feed = POE::Component::FeedAggregator::Feed->new($feed_args);
	$self->logger->debug($self->logger_prefix.'Added feed '.$feed->url) if $self->has_logger;
	$self->yield( request_feed => $feed );
};

sub logger_prefix {
	my $self = shift;
	__PACKAGE__.' ('.$self->get_session_id.') ';
}

1;



=pod

=head1 NAME

POE::Component::FeedAggregator - Watch multiple feeds (Atom or RSS) for new headlines 

=head1 VERSION

version 0.902

=head1 SYNOPSIS

  package MyServer;
  use MooseX::POE;
  use POE::Component::FeedAggregator;

  has feedaggregator => (
    is => 'ro',
    default => sub {
      POE::Component::FeedAggregator->new();
    }
  );

  event new_feed_entry => sub {
    my ( $self, @args ) = @_[ OBJECT, ARG0..$#_ ];
    my $feed = $args[0]; # POE::Component::FeedAggregator::Feed object of the feed
    my $entry = $args[1]; # XML::Feed::Format::* object of the new entry
  };

  sub START {
    my ( $self ) = @_;
    $self->feedaggregator->add_feed({
      url => 'http://news.perlfoundation.org/atom.xml', # required
      name => 'perlfoundation',                         # required
      delay => 1200,                                    # default value
	  entry_event => 'new_feed_entry',                  # default value
    });
  }

=head1 SEE ALSO

=over 4

=item *

L<POE::Component::Client::Feed>

=item *

L<POE::Component::FeedAggregator::Feed>

=item *

L<XML::Feed>

=item *

L<MooseX::POE>

=back

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

