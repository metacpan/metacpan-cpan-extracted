package RPC::JSON;

use warnings;
use strict;

use RPC::JSON::Shell;

use Carp;
use JSON;
use LWP::UserAgent;

use URI;
use URI::Heuristic qw(uf_uri);

use vars qw|$VERSION @EXPORT $DEBUG $META $AUTOLOAD|;

$VERSION = '0.15';

@RPC::JSON = qw|Exporter|;

@EXPORT = qw|
    shell
    test
|;

our $REQUEST_COUNT = 1;

=head1 NAME

RPC::JSON - JSON-RPC Client Library

=head1 SYNOPSIS

    use RPC::JSON;

    my $jsonrpc = RPC::JSON->new(
        "http://www.simplymapped.com/services/geocode/json.smd" );

    # Imports a geocode(['address']) method:
    $jsonrpc->geocode('1600 Pennsylvania Ave');

Dumping this function returns whatever data was returned from the server.
In this case:

    $VAR1 = [
        {
            'administrativearea' => 'DC',
            'country' => 'US',
            'longitude' => '-77.037691',
            'subadministrativearea' => 'District of Columbia',
            'locality' => 'Washington',
            'latitude' => '38.898758',
            'thoroughfare' => '1600 Pennsylvania Ave NW',
            'postalcode' => '20004',
            'address' => '1600 Pennsylvania Ave NW, Washington, DC 20004, USA'
         }
    ];

=head1 DESCRIPTION

RPC::JSON aims to be a full-featured JSON-RPC client library that enables a
client to connect to any JSON-RPC service and dispatch remote method calls.

=head1 METHODS

=over

=cut

=item shell

Instantiate a JSON-RPC shell

=cut

sub shell {
    my ( $self ) = @_;
    RPC::JSON::Shell::shell();
}

my @options = qw|
    smd timeout keepalive env_proxy agent conn_cache max_size dont_connect
|;

=item new(<smd source>)

Return a new RPC::JSON object for a given SMD source

=cut

sub new {
    my ( $class, @opts ) = @_;
    my $self = {
        utf8 => 0,
    };

    unless ( @opts ) {
        carp __PACKAGE__ . " requires at least the SMD URI";
        return 0;
    }

    #  ->new({ smd => $SMDURI, timeout => $TIMEOUT });
    if ( ref $opts[0] eq 'HASH' and @opts == 1 ) {
        foreach my $key ( @options ) {
            if ( exists $opts[0]->{$key} ) {
                $self->{$key} = $opts[0]->{$key};
            }
        }
    }
    #  ->new( smd => $SMDURI, timeout => $TIMEOUT );
    elsif ( @opts % 2 == 0 ) {
        my %p = @opts;
        my $i = 0;
        foreach my $key ( @options ) {
            if ( $opts[$i] eq $key ) {
                $self->{$key} = $opts[$i + 1];
                $i += 2;
            }
            last unless $opts[$i];
        }
        unless ( keys %$self ) {
            $self->{smd}     = $opts[0];
            $self->{timeout} = $opts[1];
        }
    }
    # Called like:
    #  ->new( $SMDURI, $TIMEOUT );
    elsif ( @opts < 2 ) {
        $self->{smd}     = $opts[0];
        $self->{timeout} = $opts[1];
    }
    bless $self, $class;

    # Verify the SMD is valid
    if ( $self->{smd} ) {
        my $smd = $self->{smd};
        delete $self->{smd};
        $self->set_smd($smd);
    }

    unless ( $self->{smd} ) {
        carp "No valid SMD source, please check the SMD URI.";
        return 0;
    }
    # Default timeout of 180 seconds
    $self->{timeout} ||= 180;

    unless ( $self->{dont_connect} ) {
        # If we fail to connect, it will alert the user but we shouldn't cancel
        # the object (or maybe we should if it is a 40* error?)
        $self->connect;
    }
    return $self;
}

=item set_smd

Sets the current SMD file, via URI

=cut

sub set_smd {
    my ( $self, $smd ) = @_;
    my $uri;
    eval {
        if ( $smd =~ /^\w+:/ ) {
            $uri = new URI($smd);
        } else {
            $uri = uf_uri($smd);
        }
    };
    if ( $@ or not $uri ) {
        carp $@;
        return 0;
    }
    $self->{smd} = $uri;
}

=item connect ?SMD?

Connects to the specified SMD file, or whichever was configured with.  This
will initialize the JSON-RPC service.

=cut

sub connect {
    my ( $self, $smd ) = @_;
    if ( $smd ) {
        $self->set_smd($smd);
    }
    my %options =
        map  { $_ => $self->{$_} }
        grep { $_ !~ '^smd|dont_connect$' and exists $self->{$_} }
        @options;
    $self->{_ua} = LWP::UserAgent->new( %options );
    if ( $self->{_ua} and $self->{smd} ) {
        my $response = $self->{_ua}->get( $self->{smd} );
        
        if ( $response and $response->is_success ) {
            return $self->load_smd($response);
        }

        carp "Can't load $self->{smd}: " . $response->status_line;
    }
    return 0;
}

=item load_smd

load_smd will process a given SMD file by converting from JSON to a Perl
native structure, and setup the various keys as well as the autoload handles
for calling the methods.

=cut

sub load_smd {
    my ( $self, $res ) = @_;
    my $content = $res->content;
    # Turn this on, because a lot of sources don't properly quote keys
    local $JSON::BareKey  = 1;
    local $JSON::QuotApos = 1;
    my $obj;
    eval { $obj = from_json($content,{ utf8 => $self->is_utf8 }) };
    if ( $@ ) { 
        carp $@;
        return 0;
    }
    if ( $obj ) {
        $self->{_service} = { methods => [] };
        foreach my $req ( qw|serviceURL serviceType objectName SMDVersion| ) {
            if ( $obj->{$req} ) {
                $self->{_service}->{$req} = $obj->{$req};
            } else {
                carp "Invalid SMD format, missing key: $req";
                return 0;
            }
        }
        unless ( $self->{_service}->{serviceURL} =~ /^\w+:/ ) {
            my $serviceURL = sprintf("%s://%s%s",
                $self->{smd}->scheme,
                $self->{smd}->authority,
                $self->{_service}->{serviceURL});
            $self->{_service}->{serviceURL} = $serviceURL;
        }
        $self->{serviceURL} = new URI($self->{_service}->{serviceURL});

        $self->{methods} = {};
        foreach my $method ( @{$obj->{methods}} ) {
            if ( $method->{name} and $method->{parameters}  ) {
                push @{$self->{_service}->{methods}}, $method;
                $self->{methods}->{$method->{name}} = $self->{_service}->{methods}->[-1];
            }
        };
    }
    return 1;
}

=item is_utf8

makes the call to from_json utf8 aware (see perldoc JSON)

    $jsonrpc->is_utf8( 1 );

default state is non utf8

=cut

sub is_utf8 {

	my ( $self,$set_utf8 ) = @_;
	$self->{_utf8} = 1 if ( $set_utf8 );
	return $self->{_utf8} || 0;
}

=item service

Return the object name of the current service connected to, or undef if
not connected.

=cut

sub service {
    my ( $self ) = @_;
    if ( $self->{_service} and $self->{_service}->{objectName} ) {
        return $self->{_service}->{objectName};
    }
    return undef;
}

=item methods

Return a structure of method names for use on the current service, or undef
if not connected.

The structure looks like:
    {
        methodName1 => [ { name => NAME, type => DATATYPE }, ... ]
    }

=cut

sub methods {
    my ( $self ) = @_;
   
    if ( $self->{_service} and $self->{_service}->{methods} ) {
        return {
            map { $_->{name} => $_->{parameters} }
            @{$self->{_service}->{methods}}
        };
    }
    return undef;
}

=item serviceURI

Returns the serviceURI (not the SMD URI, the URI to request RPC calls against),
or undef if not connected. 

=cut

sub serviceURI {
    my ( $self ) = @_;
    if ( $self->{serviceURL} ) {
        return $self->{serviceURL};
    }
    return undef;
}

# TODO: Remove this and create generated methods.  Although when we refresh
# the methods will need to be removed.
sub AUTOLOAD {
    my $self = shift;
    my ( $l ) = $AUTOLOAD;
    $l =~ s/.*:://;
    if ( exists $self->{methods}->{$l} ) {
        my ( @p ) = @_;
        my $packet = {
            id     => $REQUEST_COUNT++,
            method => $l,
            params => [ @p ]
        };
        my $res = $self->{_ua}->post(
            $self->{serviceURL}->as_string,
            Content_Type => 'application/javascript+json',
            Content      => to_json($packet)
        );
        if ( $res->is_success ) {
            my $ret = {};
            eval { $ret = from_json($res->content, { utf8 => $self->is_utf8 }) };
            if ( $@ ) {
                carp "Error parsing server response, but got acceptable status: $@";
            } else {
                my $result = from_json($ret->{result}, { utf8 => $self->is_utf8 });
                return $result if $result;
            }
        } else {
            carp "Error received from server: " . $res->status_line;
        }
    }
    return undef;
}

=back

=head1 AUTHORS

J. Shirley C<< <jshirley@gmail.com> >>

=head1 CONTRIBUTORS

Chris Carline
Lee Johnson

=head1 LICENSE

Copyright 2006-2008 J. Shirley C<< <jshirley@gmail.com> >>

This program is free software;  you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

1;
