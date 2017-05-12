package Net::Shoutcast::Admin;
# $Id: Admin.pm 229 2008-02-13 00:10:09Z davidp $

use warnings;
use strict;
use Carp;
use Net::Shoutcast::Admin::Song;
use Net::Shoutcast::Admin::Listener;
use URI::Escape;
use LWP::UserAgent;
use XML::Simple;

use vars qw($VERSION);
$VERSION = '0.02';


=head1 NAME

Net::Shoutcast::Admin - administration of Shoutcast servers


=head1 VERSION

This document describes Net::Shoutcast::Admin version 0.0.2


=head1 SYNOPSIS

    use Net::Shoutcast::Admin;

    my $shoutcast = Net::Shoutcast::Admin->new(
                                    host => 'server hostname',
                                    port => 8000,
                                    admin_password => 'mypassword',
    );
    
    if ($shoutcast->source_connected) {
        printf "%s is currently playing %s by %s",
            $shoutcast->dj_name,
            $shoutcast->currentsong->title,
            $shoutcast->currentsong->artist
        ;
    } else {
        print "No source is currently connected.";
    }
  
  
=head1 DESCRIPTION

A module to interact with Shoutcast servers to retrieve information about
their current status (and perhaps in later versions of the module, to also
control the server in various ways).


=head1 INTERFACE 

=over 4

=item new

$shoutcast = Net::Shoutcast::Admin->new( %params );

Creates a new Net::Shoutcast::Admin object.  Takes a hash of options
as follows:

=over 4

=item B<host>

The hostname of the Shoutcast server you wish to query.

=item port

The port on which Shoutcast is running.  Defaults to 8000 if not specified.

=item B<admin_password>

The admin password for the Shoutcast server.

=item timeout

The number of seconds to wait for a response.  Defaults to 10 seconds if
not specified.

=item agent

The HTTP User-Agent header which will be sent in HTTP requests to the Shoutcast
server.  If not supplied, a suitable default will be used.

=back

=cut

sub new {

    my ($class, %params) = @_;
    
    my $self = bless {}, $class;
        
    $self->{last_update} = 0;
    
    my %acceptable_params = map { $_ => 1 } 
        qw(host port admin_password timeout agent);
    
    # make sure we haven't been given any bogus parameters:
    if (my @bad_params = grep { ! $acceptable_params{$_} } keys %params) {
        carp "Net::Shoutcast::Admin does not recognise param(s) "
            . join ',', @bad_params;
        return;
    }
    
    # 
    $self->{$_} = $params{$_} for keys %acceptable_params;
    
    # set decent defaults for optional params:
    $self->{port}    ||= 8000;
    $self->{timeout} ||= 10;
    # In my initial testing, it seems the Shoutcast server will not respond
    # with the status XML if the User-Agent does not contain "Mozilla"
    # (Why?  That's just lame!)
    $self->{agent}   ||= "Mozilla";
    
    if (my @missing_params = grep { ! $self->{$_} } keys %acceptable_params) {
        carp "Net::Shoutcast::Admin->new() must be supplied with params: "
            . join ',', @missing_params;
        return;
    }
    
    # get an LWP::UserAgent object to make our requests with:
    my $ua = new LWP::UserAgent;
    if ($ua) {
        $ua->agent(   $self->{agent}   );
        $ua->timeout( $self->{timeout} );
        $self->{ua} = $ua;
    } else {
        warn "Failed to create LWP::UserAgent object";
        return;
    }
    
    return $self;

}


# if we haven't fetched the status XML recently, fetch it.  Returns true if
# we either fetched it successfully or it was fresh enough to not need
# re-fetching, or false if we couldn't get it.
sub _update_if_necessary {
    my $self = shift;
    if ($self->{last_update} and (time - $self->{last_update}) < 5) {
            # status was updated not long ago
            return 1;
    }
    
    my ($fetched, $msg) = $self->_fetch_status_xml;
    if (!$fetched) {
        warn "Failed to fetch status from Shoutcast server: $msg";
        return;
    }
    
    # all good.
    return 1;
}


sub _fetch_status_xml {
    my $self = shift;
        
    my ($host, $port) = @$self{qw(host port)};
    my $pass = URI::Escape::uri_escape( $self->{admin_password} );
    
    my $url = "http://$host:$port/admin.cgi?pass=$pass&mode=viewxml";
    
    my $response = $self->{ua}->get($url);
    
    if (!$response->is_success) {
        my $err = "Failed to fetch status XML - " . $response->status_line;
        carp $err;
        return wantarray? (0, $err) : 0;
    }
    
    my $data = XML::Simple::XMLin($response->content, 
        forceArray => [qw(LISTENER SONG)]);
    
    if (!$data) {
        return wantarray? (0, 'Failed to parse XML') : 0;
    }
    
    $self->{data} = $data;
    $self->{last_update} = time;
    
    return wantarray? (1, undef) : 1;
}



=item currentsong

Returns a Net::Shoutcast::Admin::Song object representing the current
song.

=cut

sub currentsong {
    my $self = shift;
    $self->_update_if_necessary or return;
    
    my $song = Net::Shoutcast::Admin::Song->new( 
        title => $self->{data}->{SONGTITLE}
    );   
    return $song;
}


=item song_history

Returns a list of Net::Shoutcast::Admin::Song objects representing
the the last few songs played

=cut

sub song_history {
    my $self = shift;
    my @song_objects;
    $self->_fetch_status_xml;
    
    for my $song (@{ $self->{data}->{SONGHISTORY}->{SONG} }) {
        push @song_objects, Net::Shoutcast::Admin::Song->new(
            title => $song->{TITLE},
            played_at => $song->{PLAYEDAT},
        );
    }
    
    return (@song_objects);
}


=item listeners

In scalar context, returns the number of listeners currently connected.
In list context, returns a list of Net::Shoutcast::Admin::Listener
objects representing each listener.

=cut

sub listeners {
    my $self = shift;
    $self->_fetch_status_xml;
    
    if (!wantarray) {
        # okay, it's nice and simple:
        return $self->{data}->{CURRENTLISTENERS};
    } else {
        # okay, we need to return a list of N:S:A::Listener objects:
        return if !$self->{data}->{CURRENTLISTENERS};
        
        my @listener_objects;
        for my $listener (@{ $self->{data}->{LISTENERS}->{LISTENER} }) {
            push @listener_objects, Net::Shoutcast::Admin::Listener->new(
                host         => $listener->{HOSTNAME},
                connect_time => $listener->{CONNECTTIME},
                underruns    => $listener->{UNDERRUNS} || 5,
                agent        => $listener->{USERAGENT},
            );
        }
            
        return (@listener_objects);
    }
}


=item source_connected

Returns true if the stream is currently up (a source is connected and streaming
audio to the server)

=cut

sub source_connected {
    my $self = shift;
    $self->_fetch_status_xml;   
    return ($self->{data}->{STREAMSTATUS});
}


1; # Magic true value required at end of module
__END__



=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-shoutcast-admin@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Precious  C<< <davidp@preshweb.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, David Precious C<< <davidp@preshweb.co.uk> >>. 
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
