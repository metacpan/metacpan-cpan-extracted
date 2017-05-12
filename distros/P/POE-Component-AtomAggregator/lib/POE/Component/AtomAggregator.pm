package POE::Component::AtomAggregator;

use warnings;
use strict;

use POE qw(
    Component::Client::HTTP
    Wheel::ReadWrite
    Driver::SysRW
);
use Symbol qw( gensym );
use HTTP::Request;
use Carp qw(croak);

=head1 NAME

POE::Component::AtomAggregator - Watch Muliple Atom Feeds for New Headlines

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use POE qw( Component::AtomAggregator );

    my @feeds = (
        {   url   => "http://xantus.vox.com/library/posts/atom.xml",
            name  => "xantus",
            delay => 600,
        },
        {   url   => "http://www.vox.com/explore/posts/atom.xml",
            name  => "vox",
            delay => 60,
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
        $heap->{atomagg} = POE::Component::AtomAggregator->new(
            alias    => 'atomagg',
            debug    => 1,
            callback => $session->postback('handle_feed'),
            tmpdir   => '/tmp',        # optional caching 
        );
        $kernel->post( 'atomagg', 'add_feed', $_ ) for @feeds;
    }

    sub handle_feed {
        my ( $kernel, $feed ) = ( $_[KERNEL], $_[ARG1]->[0] );
        for my $entry ( $feed->late_breaking_news ) {
        
            # this is where this module differs from RSSAggregator!
            
            # do stuff with the XML::Atom::Entry object
            print $entry->title . "\n";
        }
    }

=head1 CONSTRUCTORS

=head2 POE::Component::AtomAggregator->new( %hash );

Create a new instace of PoCo::AtomAggregator.

=over 4

=item * alias

POE alias to use for your instance of PoCo::AtomAggregator.

=item * debug

Boolean value to turn on verbose output.

=item * tmpdir

The tmpdir argument is used as the directory to cache Atom 
between fetches (and instances).

=item * http_alias

Optional.  Alias of an existing PoCo::Client::HTTP.

=item * follow_redirects

Optional.  Only if you don't have an exiting PoCo::Client::HTTP.
Argument is passed to PoCoCl::HTTP to tell it the follow redirect
level.  (Defaults to 2)

=back

=cut

sub new {
    my $class = shift;
    croak __PACKAGE__ . "->new() params must be a hash" if @_ % 2;
    my %params = @_;

    croak __PACKAGE__
        . "->new() feeds param has been deprecated, use add_feed"
        if $params{feeds};

    my $self = bless \%params, $class;
    $self->_init();

    return $self;
}

sub _start {
    my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $self->{alias} = 'atomagg' unless $self->{alias};
    $kernel->alias_set( $self->{alias} );
}

sub _stop {}

sub _init {
    my ($self) = @_;

    unless ($self->{http_alias}) {
	$self->{http_alias} = 'ua';
	$self->{follow_redirects} ||= 2;
        POE::Component::Client::HTTP->spawn(
            Alias           => $self->{http_alias},
            Timeout         => 60,
            FollowRedirects => $self->{follow_redirects},
            Agent           => 'Mozilla/5.0 (PoCo Atom Aggregator)',
        );
    }

    my $session = POE::Session->create(
	object_states => [
	    $self => [qw(
    		_start
    		add_feed
            remove_feed
            pause_feed
            resume_feed 
	    	_fetch
            _response
    		shutdown
	    	_stop

            _read_file
            _file_read_input
            _file_read_flush
            _file_read_error

            _write_file
            _file_write_flush
            _file_write_error
	    )],
	],
    );

    $self->{sid} = $session->ID();

    undef;
}

sub _create_feed_object {
    my ( $self, $feed_hash ) = @_;

    warn "[$feed_hash->{name}] Creating Feed object\n"
        if $self->{debug};

    if ( exists $self->{tmpdir} && -d $self->{tmpdir} ) {
        $feed_hash->{tmpdir} = $self->{tmpdir};
        # effing windows?
        $feed_hash->{tmpdir} .= "/"
            unless ( $feed_hash->{tmpdir} =~ m!/$! );
    }

    $feed_hash->{debug} = $self->{debug} 
        if $self->{debug};
    
    $feed_hash->{ignore_first} = $self->{ignore_first} 
        if $self->{ignore_first};

    $feed_hash->{_parent_sid} = $self->{sid};

    if ( my $atomfeed = POE::Component::AtomAggregator::Feed->new( $feed_hash ) ) {
        $self->{feed_objs}{ $atomfeed->name } = $atomfeed;
    } else {
        warn "[$feed_hash->{name}] !! Error attempting to " 
            . "create Feed object\n";
    }
    return $feed_hash;
}

=head1 METHODS

=head2 $atomagg->feed_list

Returns the current feeds as an array or array_ref.

=cut

sub feed_list {
    my ($self) = @_;
    my @feeds = map { $self->{feed_objs}{$_} } keys %{ $self->{feed_objs} };
    return wantarray ? @feeds : \@feeds;
}

=head2 $atomagg->feeds

Returns a hash ref of feeds with the key being the feeds name.

=cut

sub feeds {
    my ($self) = @_;
    return $self->{feed_objs};
}

=head2 $atomagg->feed( $feed_name )

Accessor to access a the XML::Atom::Feed object via a feed's name.

=cut

sub feed {
    my ( $self, $name ) = @_;
    return exists $self->{feed_objs}{$name}
        ? $self->{feed_objs}{$name}
        : undef;
}

=head2 $atomagg->add_feed( $hash_ref )

The hash reference you pass in to add_feed is passed to
XML::Atom::Feed->new($hash_ref). ( see L<XML::Atom::Feed> )

=cut

sub add_feed {
    my ( $self, $kernel, $feed_hash ) = @_[ OBJECT, KERNEL, ARG0 ];
    if ( exists $self->{feed_objs}{ $feed_hash->{name} } ) {
        warn "[$feed_hash->{name}] !! Add Failed: Feed name already exists\n";
        return;
    }
    warn "[$feed_hash->{name}] Added\n" if $self->{debug};
    $self->_create_feed_object($feed_hash);
    
    if ( $self->{tmpdir} ) {
        my $file = $feed_hash->{tmpdir}.$feed_hash->{name}.".atom";
        if ( -e $file ) {
            # wheel read write
            $poe_kernel->yield( _read_file => $feed_hash => sub {
                my $f = shift;
                delete $feed_hash->{pending_open};
                if ( $f->{in} ) {
                    $feed_hash->parse( $f->{in}, 1 );
                }
                $kernel->yield( '_fetch', $feed_hash->{name} );
            } );
            return;
        }
    }
    # Test to remove it after 10 seconds
    $kernel->yield( '_fetch', $feed_hash->{name} );
}

=head2 $atomagg->remove_feed( $feed_name )

Pass in the name of the feed you want to remove.

=cut

sub remove_feed {
    my ( $self, $kernel, $name ) = @_[ OBJECT, KERNEL, ARG0 ];
    unless ( exists $self->{feed_objs}{$name} ) {
        warn "[$name] remove_feed: Remove Failed: Unknown feed\n"; 
        return;
    }
    $kernel->call( $self->{alias}, 'pause_feed', $name );
    delete $self->{feed_objs}{$name};
    warn "[$name] remove_feed: Removed Atom Feed\n" if $self->{debug};
}

=head2 $atomagg->pause_feed( $feed_name )

Pass in the name of the feed you want to pause.

=cut

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
        warn "[$name] pause_feed: Paused Atom Feed\n" if $self->{debug};
    }
    else {
        warn "[$name] pause_feed: Failed to Pause Atom Feed\n"
            if $self->{debug};
    }
}

=head2 $atomagg->resume_feed( $feed_name )

Pass in the name of the feed you want to resume (that you previously paused).

=cut

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
    warn "[$name] resume_feed: Resumed Atom Feed\n" if $self->{debug};
    $kernel->yield( '_fetch', $name );
}

=head2 $atomagg->shutdown

Shutdown the instance of PoCo::AtomAggregator.

=cut

sub shutdown {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];
    for my $feed ( $self->feed_list ) {
        $kernel->call( $session => 'remove_feed' => $feed->name );
    }
    delete $self->{callback};
    $kernel->alias_remove( $self->{alias} );
    warn "shutdown: shutting down atomaggregator\n" if $self->{debug};
}

sub _fetch {
    my ( $self, $kernel, $feed_name ) = @_[ OBJECT, KERNEL, ARG0 ];
    unless ( exists $self->{feed_objs}{$feed_name} ) {
        warn "[$feed_name] Unknown Feed\n";
        return;
    }

    my $atomfeed = $self->{feed_objs}{$feed_name};
    my $req = HTTP::Request->new( GET => $atomfeed->url );
    warn "[" . $atomfeed->name . "] Attempting to fetch\n" if $self->{debug};
    $kernel->post( $self->{http_alias}, 'request', '_response', $req,
        $atomfeed->name );
    $self->{alarm_ids}{ $atomfeed->name }
        = $kernel->delay_set( '_fetch', $atomfeed->delay, $atomfeed->name );
}

sub _response {
    my ( $self, $kernel, $request_packet, $response_packet )
        = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

    my ( $req, $feed_name ) = @$request_packet;

    unless ( exists $self->{feed_objs}{$feed_name} ) {
        warn "[$feed_name] Unknown Feed\n";
        return;
    }

    my $atomfeed = $self->{feed_objs}{$feed_name};
    my $res = $response_packet->[0];
    if ( $res->is_success ) {
        warn "[" . $atomfeed->name . "] Fetched " . $atomfeed->url . "\n"
            if $self->{debug};
        
        $self->{callback}->($atomfeed) if $atomfeed->parse( $res->content );
    } else {
        warn "[!!] Failed to fetch " . $req->uri . "\n";
    }
}

sub _read_file {
    my ( $self, $kernel, $feed ) = @_[OBJECT, KERNEL, ARG0];
    
    my $filename = $feed->tmpdir.$feed->name.".atom";
    my $fh = gensym();
    open($fh,$filename);

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle => $fh,
        Driver => POE::Driver::SysRW->new(),
        Filter => POE::Filter::Stream->new(),
        InputEvent => '_file_read_input',
        FlushedEvent => '_file_read_flush',
        ErrorEvent => '_file_read_error',
    );
    my $wid = $wheel->ID;
    warn "started wheel id $wid" if ($self->{debug});

    $self->{wheels}->{$wid} = {
        name => $feed->name,
        obj => $wheel,
        file => $filename,
        callback => $_[ARG1]
    };

    undef;
}

sub _file_read_input {
    my ($self, $wid) = @_[OBJECT, ARG1];
    my $f = $self->{wheels}->{$wid};
    warn "[$f->{name}][read] input on wheel $wid : $f->{file}" if ($self->{debug});
    $f->{in} .= $_[ARG0];
}

sub _file_read_flush {
    my ($self, $wid) = @_[OBJECT, ARG0];
    return unless($self->{debug});
    my $f = $self->{wheels}->{$wid};
    warn "[$f->{name}][read] file flushed";
}

sub _file_read_error {
    my ($self, $name, $num, $desc, $wid) = @_[ OBJECT, ARG0 .. ARG3 ];
    my $f = delete $self->{wheels}->{$wid};
    warn "[$f->{name}][read] file $name error $num : $desc on wheel $wid" if ($self->{debug});
    if ($f->{callback}) {
        delete $f->{obj};
        $f->{error} = $num;
        $f->{callback}->( $f );
    }
    undef;
}

sub _write_file {
    my ( $self, $kernel, $feed, $contents ) = @_[OBJECT, KERNEL, ARG0, ARG1];
    
    my $filename = $feed->tmpdir.$feed->name.".atom";
    my $fh = gensym();
    open($fh,">$filename");

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle => $fh,
        Driver => POE::Driver::SysRW->new(),
        Filter => POE::Filter::Stream->new(),
        FlushedEvent => '_file_write_flush',
        ErrorEvent => '_file_write_error',
    );

    $self->{wheels}->{$wheel->ID} = {
        name => $feed->name,
        obj => $wheel,
        file => $filename,
        callback => $_[ARG2],
    };

    $wheel->put( $contents );

    undef;
}

sub _file_write_flush {
    my ( $self, $wid ) = @_[OBJECT, ARG0];
    my $f = delete $self->{wheels}->{$wid};
    warn "[$f->{name}][write] flush on $f->{file}" if ($self->{debug});
    if ($f->{callback}) {
        delete $f->{obj};
        $f->{callback}->( $f );
    }
    undef;
}

sub _file_write_error {
    my ($self, $name, $num, $desc, $wid) = @_[ OBJECT, ARG0 .. ARG3 ];
    my $f = delete $self->{wheels}->{$wid};
    warn "[$f->{name}][write] file $name $num on $f->{file} : $f->{file}" if ($self->{debug});
    if ($f->{callback}) {
        delete $f->{obj};
        $f->{error} = $num;
        $f->{callback}->( $f );
    }
    undef;
}

=head1 AUTHOR

David Davis, aka Xantus, C<< <xantus at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-component-atomaggregator at rt.cpan.org>, or through the web 
interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-AtomAggregator>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::AtomAggregator

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-AtomAggregator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-AtomAggregator>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-AtomAggregator>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-AtomAggregator>

=back

=head1 NOTES

All XML::Atom::Feed objects mentioned in this doc are actually
POE::Component::AtomAggregator::Feed objects that have extra accessors and
methods to add late_breaking_news functionality and non blocking file IO.
You can use the object as if it were a XML::Atom::Feed object.

=head1 ACKNOWLEDGEMENTS

A big thank you to Jeff Bisbee for POE::Component::RSSAggregator

This module entirely based off his work, with changes to use XML::Atom
instead of XML::RSS

Also a big thanks to miyagawa for XML::Atom::Feed.

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Davis, aka Xantus

All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Atom::Feed>, L<XML::Atom::Entry>

=cut

1;

# TODO move this?
package POE::Component::AtomAggregator::Feed;

use XML::Atom::Feed;
use Carp qw( croak );
use POE;

our $AUTOLOAD;

our %accessors = map { $_ => 1 } qw(
    url
    name
    delay
    tmpdir
    ignore_first
);

# autoload that calls methods on XML::Atom::Feed
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    if ($accessors{$name}) {
        return $self->{$name};
    }

    if ($self->{obj} && $self->{obj}->can( $name ) ) {
        no strict 'refs';
        return $self->{obj}->$name(@_);
    }
    

    croak "method not found `$name' in class $type";
}

sub new {
    my $class = shift;
    my $obj = shift;
    $obj->{entries} = [];
    my $self = bless($obj, $class);

    $self;
}

sub late_breaking_news {
    @{shift->{entries}};
}

sub parse {
    my ( $self, $content, $no_write ) = @_;
    
    return 0 if ($self->{pending_open});
   
    # using the last obj $self->{obj} diff the feeds
    my $feed = XML::Atom::Feed->new( \$content );
    
    # TODO better diff detection
    my %entries;
    if ( $self->{obj} ) {
        %entries = map { $_->link->href => 1 } $self->entries;
    }

    my @diff = grep { !exists( $entries{ $_->link->href } ) } $feed->entries;

    if ( $self->ignore_first && !$self->{obj} ) {
        $self->{obj} = $feed;
        return 0;
    }
    
    $self->{obj} = $feed;
    $self->{entries} = \@diff;
    
    unless ($no_write) {
        if ( @diff ) {
            $poe_kernel->post( $self->{_parent_sid} => _write_file => $self => $content => sub {
                my $f = shift;
                warn "[$f->{name}] finished writing $f->{file}" if ($self->{debug});
            } );
        }
    }

    return @diff ? scalar(@diff) : 0;
}

1;

