package POE::Component::RSSAggregator;
use warnings;
use strict;
use POE;
use POE::Component::Client::HTTP;
use HTTP::Request;
use XML::RSS::Feed;
use Carp qw(croak);

use constant DEFAULT_TIMEOUT => 60;
use constant REDIRECT_DEPTH  => 2;

our $VERSION = 1.11;

sub new {
    my $class = shift;
    croak __PACKAGE__ . '->new() params must be a hash' if @_ % 2;
    my %params = @_;

    croak __PACKAGE__
        . '->new() feeds param has been deprecated, use add_feed'
        if $params{feeds};

    my $self = bless \%params, $class;
    $self->_init();

    return $self;
}

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $self->{alias} = 'rssagg' unless $self->{alias};
    $kernel->alias_set( $self->{alias} );
    return;
}

sub _stop {}

sub _init {
    my ($self) = @_;

    unless ( $self->{http_alias} ) {
        $self->{http_alias} = 'ua';
        $self->{follow_redirects} ||= REDIRECT_DEPTH;
        POE::Component::Client::HTTP->spawn(
            Alias           => $self->{http_alias},
            Timeout         => DEFAULT_TIMEOUT,
            FollowRedirects => $self->{follow_redirects},
            Agent           => 'Mozilla/5.0 (X11; U; Linux i686; en-US; '
                . 'rv:1.1) Gecko/20020913 Debian/1.1-1',
        );
    }

    POE::Session->create(
        object_states => [
            $self => [ qw(
                _start
                add_feed remove_feed pause_feed resume_feed
                _fetch _response
                shutdown
                _stop
            ) ],
        ],
    );

    return;
}

sub _create_feed_object {
    my ( $self, $feed_hash ) = @_;

    warn "[$feed_hash->{name}] Creating XML::RSS::Feed object\n"
        if $self->{debug};

    $feed_hash->{tmpdir} = $self->{tmpdir}
        if exists $self->{tmpdir} && -d $self->{tmpdir};

    $feed_hash->{debug} = $self->{debug}
        if $self->{debug};

    if ( my $rssfeed = XML::RSS::Feed->new(%$feed_hash) ) {
        $self->{feed_objs}{ $rssfeed->name } = $rssfeed;
    }
    else {
        warn "[$feed_hash->{name}] !! Error attempting to "
            . "create XML::RSS::Feed object\n";
    }

    return;
}

sub feed_list {
    my ($self) = @_;
    my @feeds = map { $self->{feed_objs}{$_} } keys %{ $self->{feed_objs} };
    return wantarray ? @feeds : \@feeds;
}

sub feeds {
    my ($self) = @_;
    return $self->{feed_objs};
}

sub feed {
    my ( $self, $name ) = @_;
    return exists $self->{feed_objs}{$name}
        ? $self->{feed_objs}{$name}
        : undef;
}

sub add_feed {
    my ( $self, $kernel, $feed_hash ) = @_[ OBJECT, KERNEL, ARG0 ];
    if ( exists $self->{feed_objs}{ $feed_hash->{name} } ) {
        warn "[$feed_hash->{name}] !! Add Failed: Feed name already exists\n";
        return;
    }
    warn "[$feed_hash->{name}] Added\n" if $self->{debug};
    $self->_create_feed_object($feed_hash);

    # Test to remove it after 10 seconds
    $kernel->yield( '_fetch', $feed_hash->{name} );
    return;
}

sub remove_feed {
    my ( $self, $kernel, $name ) = @_[ OBJECT, KERNEL, ARG0 ];
    unless ( exists $self->{feed_objs}{$name} ) {
        warn "[$name] remove_feed: Remove Failed: Unknown feed\n";
        return;
    }
    $kernel->call( $self->{alias}, 'pause_feed', $name );
    delete $self->{feed_objs}{$name};
    warn "[$name] remove_feed: Removed RSS Feed\n" if $self->{debug};
    return;
}

sub pause_feed {
    my ( $self, $kernel, $name ) = @_[ OBJECT, KERNEL, ARG0 ];
    unless ( exists $self->{feed_objs}{$name} ) {
        warn "[$name] pause_feed: Pause Failed: Unknown feed\n";
        return;
    }
    unless ( exists $self->{alarm_ids}{$name} ) {
        warn "[$name] pause_feed: Pause Failed: Feed currently on pause\n";
        return;
    }
    if ( $kernel->alarm_remove( $self->{alarm_ids}{$name} ) ) {
        delete $self->{alarm_ids}{$name};
        warn "[$name] pause_feed: Paused RSS Feed\n" if $self->{debug};
    }
    else {
        warn "[$name] pause_feed: Failed to Pause RSS Feed\n"
            if $self->{debug};
    }
    return;
}

sub resume_feed {
    my ( $self, $kernel, $name ) = @_[ OBJECT, KERNEL, ARG0 ];
    unless ( exists $self->{feed_objs}{$name} ) {
        warn "[$name] resume_feed: Resume Failed: Unknown feed\n";
        return;
    }
    if ( exists $self->{alarm_ids}{$name} ) {
        warn "[$name] resume_feed: Resume Failed: Feed currently active\n";
        return;
    }
    warn "[$name] resume_feed: Resumed RSS Feed\n" if $self->{debug};
    $kernel->yield( '_fetch', $name );
    return;
}

sub shutdown {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];
    for my $feed ( $self->feed_list ) {
        $kernel->call( $session, 'remove_feed', $feed->name );
    }
    delete $self->{callback};
    $kernel->alias_remove( $self->{alias} );
    warn "shutdown: shutting down rssaggregator\n" if $self->{debug};
    return;
}

sub _fetch {
    my ( $self, $kernel, $feed_name ) = @_[ OBJECT, KERNEL, ARG0 ];
    unless ( exists $self->{feed_objs}{$feed_name} ) {
        warn "[$feed_name] Unknown Feed\n";
        return;
    }

    my $rssfeed = $self->{feed_objs}{$feed_name};
    my $req = HTTP::Request->new( GET => $rssfeed->url );
    warn '[' . $rssfeed->name . '] Attempting to fetch' . "\n" if $self->{debug};
    $kernel->post( $self->{http_alias}, 'request', '_response', $req,
        $rssfeed->name );
    $self->{alarm_ids}{ $rssfeed->name }
        = $kernel->delay_set( '_fetch', $rssfeed->delay, $rssfeed->name );
    return;
}

sub _response {
    my ( $self, $kernel, $request_packet, $response_packet )
        = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

    my ( $req, $feed_name ) = @$request_packet;

    unless ( exists $self->{feed_objs}{$feed_name} ) {
        warn "[$feed_name] Unknown Feed\n";
        return;
    }

    my $rssfeed = $self->{feed_objs}{$feed_name};
    my $res     = $response_packet->[0];
    if ( $res->is_success ) {
        warn '[' . $rssfeed->name . '] Fetched ' . $rssfeed->url . "\n"
            if $self->{debug};
        $self->{callback}->($rssfeed) if $rssfeed->parse( $res->content );
    }
    else {
        warn '[!!] Failed to fetch ' . $req->uri . "\n";
    }
    return;
}

1;

__END__
=head1 NAME

POE::Component::RSSAggregator - Watch Muliple RSS Feeds for New Headlines

=head1 VERSION

Version 1.11

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use POE;
    use POE::Component::RSSAggregator;

    my @feeds = (
        {   url   => "http://www.jbisbee.com/rdf/",
            name  => "jbisbee",
            delay => 10,
        },
        {   url   => "http://lwn.net/headlines/rss",
            name  => "lwn",
            delay => 300,
        },
    );

    POE::Session->create(
        inline_states => {
            _start      => \&init_session,
            handle_feed => \&handle_feed,
        },
    );

    $poe_kernel->run();

    sub init_session {
        my ( $kernel, $heap, $session ) = @_[ KERNEL, HEAP, SESSION ];
        $heap->{rssagg} = POE::Component::RSSAggregator->new(
            alias    => 'rssagg',
            debug    => 1,
            callback => $session->postback("handle_feed"),
            tmpdir   => '/tmp',        # optional caching 
        );
        $kernel->post( 'rssagg', 'add_feed', $_ ) for @feeds;
    }

    sub handle_feed {
        my ( $kernel, $feed ) = ( $_[KERNEL], $_[ARG1]->[0] );
        for my $headline ( $feed->late_breaking_news ) {

            # do stuff with the XML::RSS::Headline object
            print $headline->headline . "\n";
        }
    }

=head1 CONSTRUCTORS

=head2 POE::Component::RSSAggregator->new( %hash );

Create a new instace of PoCo::RSSAggregator.

=over 4

=item * alias

POE alias to use for your instance of PoCo::RSSAggregator.

=item * debug

Boolean value to turn on verbose output.  (debug is also passed to
XML::RSS::Feed instances to turn on verbose output as well)

=item * tmpdir

The tmpdir argument is passed on to XML::RSS::Feed as the directory to 
cache RSS between fetches (and instances).

=item * http_alias

Optional.  Alias of an existing PoCoCl::HTTP.

=item * follow_redirects

Optional.  Only if you don't have an exiting PoCoCl::HTTP.  Argument 
is passed to PoCoCl::HTTP to tell it the follow redirect level.  
(Defaults to 2)

=back

=head1 METHODS

=head2 $rssagg->feed_list

Returns the current feeds as an array or array_ref.

=head2 $rssagg->feeds

Returns a hash ref of feeds with the key being the feeds name.  
The hash reference you that belongs to the key is passed to
XML::RSS::Feed->new($hash_ref). ( see L<XML::RSS::Feed> )

=head2 $rssagg->feed( $feed_name )

Accessor to access a the XML::RSS::Feed object via a feed's name.

=head2 $rssagg->add_feed( $hash_ref )

The hash reference you pass in to add_feed is passed to
XML::RSS::Feed->new($hash_ref). ( see L<XML::RSS::Feed> )

=head2 $rssagg->remove_feed( $feed_name )

Pass in the name of the feed you want to remove.

=head2 $rssagg->pause_feed( $feed_name )

Pass in the name of the feed you want to pause.

=head2 $rssagg->resume_feed( $feed_name )

Pass in the name of the feed you want to resume (that you previously paused).

=head2 $rssagg->shutdown

Shutdown the instance of PoCo::RSSAggregator.

=head1 AUTHOR

Jeff Bisbee, C<< <jbisbee at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-component-rssaggregator at rt.cpan.org>, or through the web 
interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-RSSAggregator>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::RSSAggregator

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-RSSAggregator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-RSSAggregator>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-RSSAggregator>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-RSSAggregator>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Rocco Caputo, Martijn van Beers, Sean Burke, Prakash Kailasa
and Randal Schwartz for their help, guidance, patience, and bug reports. Guys 
thanks for actually taking time to use the code and give good, honest feedback.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jeff Bisbee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::RSS::Feed>, L<XML::RSS::Headline>, L<XML::RSS::Headline::PerlJobs>, 
L<XML::RSS::Headline::Fark>

