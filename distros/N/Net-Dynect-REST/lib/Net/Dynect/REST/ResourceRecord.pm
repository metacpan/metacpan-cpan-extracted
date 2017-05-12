package Net::Dynect::REST::ResourceRecord;
# $Id: ResourceRecord.pm 172 2010-09-27 06:26:59Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Carp;
use Net::Dynect::REST::RData;
our $VERSION = do { my @r = (q$Revision: 172 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME 

Net::Dynect::REST::ResourceRecord - An abstract DNS resource record object

=head1 SYNOPSIS

  use Net::Dynect::REST:ARecord;
  my $record = Net::Dynect::REST:ARecord->new(connection => $dynect);
  $record->get('example.com', 'www.example.com');
  $ttl = $record->ttl;

=head1 METHODS

=head2 Creating

=over 4

=item Net::Dynect::REST:ARecord->new()

This constructor takes arguments of the connection object (Net::Dynect::REST), and optionally a zone and arecord FQDN to fetch.


=cut

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;
    $self->{connection} = $args{connection} if defined $args{connection};
    # If we have a record_id, then we should load this.
    if (   defined( $args{fqdn} )
        && defined( $args{zone} )
        && defined( $args{record_id} ) )
    {
        $self->get(
            zone      => $args{zone},
            fqdn      => $args{fqdn},
            record_id => $args{record_id}
        ) && return $self;
        return;
    }
    $self->zone( $args{zone} )   if ( defined $args{zone} );
    $self->fqdn( $args{fqdn} )   if ( defined $args{fqdn} );
    $self->rdata( $args{rdata} ) if ( defined $args{rdata} );
    $self->ttl( $args{ttl} )     if ( defined $args{ttl} );
    return $self;
}

=back
=item  Net::Dynect::REST:ARecord-find(connection => $dynect, zone => $zone, fqdn => $fqdn);

This will return an array of objects that match the Name and Zone. Each A Record may have multiple entries in the zone.

=cut

sub find {
    my $proto = shift;
    my %args  = @_;
    if (
        not( defined( $args{connection} )
            && ref( $args{connection} ) eq "Net::Dynect::REST" )
      )
    {
        carp "Need a connection (Net::Dynect::REST)";
        return;
    }
    if ( not( defined $args{zone} ) ) {
        carp "Need a zone to look in";
        return;
    }
    if ( not defined $args{fqdn} ) {
        carp "Need a fully qualified domain name (FQDN) to look for";
        return;
    }
    my $request = Net::Dynect::REST::Request->new(
        operation => 'read',
        service   => sprintf( "%s/%s/%s", __PACKAGE__->_service_base_uri, $args{zone}, $args{fqdn} )
    );
    if ( not $request ) {
        carp "Request not valid: $request";
        return;
    }

    my $response = $args{connection}->execute($request);
    # Not keeping track fo this response as we're not an object!

    if ( not $response ) {
        carp "Response not valid: $response";
        return;
    }

    if ( $response->status !~ /^success$/i ) {
        carp $response->status;
        return;
    }

    if ( ref( $response->data ) ne "ARRAY" ) {
        # Didn't get a list of records back, probably becuase it doesn't exist!
        return;
    }

    my @records;
    foreach ( @{ $response->data } ) {
        if ( $_->value =~ m!/REST/([^\/]+)/([^\/]+)/([^\/]+)/(\d+)$! ) {
	    eval "require Net::Dynect::REST::$1";
            push @records,
              "Net::Dynect::REST::$1"->new(
                connection => $args{connection},
                fqdn       => $3,
                zone       => $2,
                record_id  => $4
              );
        }
        else {
            carp "Could not understand " . $_->data;
            return;
        }
    }
    return @records;
}

=head2 Operations

=over 4

=item $record->get( $zone, $fqdn [, $redord_id] ) 

This will attempt to load the data from Dynect for the given fully qualified domain name, in the given zone.

=cut

sub get {
    my $self = shift;
    my %args = @_;

    if ( not( defined( $args{zone} ) || $self->zone ) ) {
        carp "Zone needs to be set";
        return;
    }

    if ( not( defined( $args{fqdn} ) || $self->fqdn ) ) {
        carp "FQDN needs to be set";
        return;
    }

    my $request = Net::Dynect::REST::Request->new(
        operation => 'read',
        service   => sprintf(
            "%s/%s/%s/%s",
	    $self->_service_base_uri,
            $args{zone}      || $self->zone,
            $args{fqdn}      || $self->fqdn,
            $args{record_id} || $self->record_id
        )
    );

    if ( not $request ) {
        carp "Invalid request: $request";
        return;
    }

    my $response = $self->{connection}->execute($request);
    $self->last_response($response);

    if ( not $response ) {
        carp "Invalid response: $response";
        return;
    }

    if ( $response->status !~ /^success$/i ) {
        carp $response->status;
        return;
    }

    $self->fqdn( $response->data->fqdn );
    $self->record_id( $response->data->record_id );
    $self->zone( $response->data->zone );
    $self->rdata(
        Net::Dynect::REST::RData->new( data => $response->data->rdata ) );
    $self->record_type( $response->data->record_type );
    $self->ttl( $response->data->ttl );
    return 1;
}

=item $arecord->save();

This will create a new ARecord resource. 
 You need to already populate the B<zone>, B<fqdn>, and B<rdata> attributes with the correct data. The B<rdata> should be a Net::Dynect::REST::RData object, with the B<address> field set to one IPv4 address, such as:

  Net::Dynect::REST::RData->new(data => {address => '1.2.3.4'});

=cut

sub save {
    my $self = shift;
    my %args = @_;

    if ( not defined $self->{connection} ) {
        carp "Don't have a connection";
        return;
    }
    elsif ( not defined $self->fqdn ) {
        carp "Don't have an FQDN for this record";
        return;
    }
    elsif ( not defined $self->rdata ) {
        carp "Need an rdata structure with the address";
        return;
    }

    my $request = Net::Dynect::REST::Request->new(
        operation => 'create',
        service   => $self->_service_base_uri ."/" . $self->zone . "/" . $self->fqdn,
        params    => { rdata => $self->rdata->rdata, ttl => $args{ttl} || 0 }
    );

    my $response = $self->{connection}->execute($request);
    $self->last_response($response);
    if ( $response->status !~ /^success$/i ) {
        carp "Response failed: $response";
        return;
    }
    #print $response . "\n";
    return 1;
}

sub delete {
    my $self = shift;
    return unless defined $self->{connection};
    return unless defined $self->zone;
    return unless defined $self->fqdn && $self->record_id;
    my $request = Net::Dynect::REST::Request->new(
        operation => 'delete',
        service   => __PACKAGE__->_service_base_uri . '/' . $self->zone . '/' . $self->fqdn . '/' . $self->record_id
    );
    my $response = $self->{connection}->execute($request);
    $self->last_response($response);
    if ( $response->status =~ /^success$/i ) {
        $self->{fqdn}         = undef;
        $self->{record_id}    = undef;
        $self                 = undef;
        return 1;
    }
    else {
        printf "%s\n", $response->msgs->[0]->info if defined $response->msgs;
	return 0;
    }
}

=back

=head2 Attributes

=over 4

=item fqdn

This is the Fully Qaulified Domain Name of the A Record.

=cut

sub fqdn {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( defined $self->{fqdn} && $self->{fqdn} ne $new ) {
            carp
"Cannot change name from what it has been set to. Create a new instance for a new record, and delete the old one.";
            return;
        }
        elsif ( $new !~ /^\S+/ ) {
            carp "FQDN names must not have spaces in them: '$new'";
            return;
        }
        $self->{fqdn} = $new;
    }
    return $self->{fqdn};
}

=item zone

the is the DNS zone the record lives in.

=cut

sub zone {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( defined $self->{zone} ) {
            carp
"Cannot change name from what it has been set to. Create a new instance for a new record, and delete the old one.";
            return;
        }
        elsif ( $new !~ /^\S+/ ) {
            carp "Zone names must not have spaces in them: '$new'";
            return;
        }
        $self->{zone} = $new;
    }
    return $self->{zone};
}

=item rdata

This is the address record data

=cut 

sub rdata {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{rdata} = $new;
    }
    return $self->{rdata};
}

=item record_type

This is the record type.

=cut

sub record_type {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{record_type} = $new;
    }
    return $self->{record_type};
}

=item record_id

This is unique to each record. 

=cut

sub record_id {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^\d*$/ ) {
            carp "Invalid record id: $new";
            return;
        }
        $self->{record_id} = $new;
    }
    return $self->{record_id};
}

=item ttl

This is the time to live for the reord. Use 0 to inherit the zone default.

=cut

sub ttl {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( $new !~ /^\d+$/ ) {
            carp "New TTL should be numeric";
            return;
        }
        $self->{ttl} = $new;
    }
    return $self->{ttl};
}

sub _service_base_uri {
    return "ARecord";
}

=item last_response

This is the Net::Dynect::REST::Response object that was returned most recently 
returned. Fromt his you can see stuff like when the request was submitted, and 
how long it took to get a response.

=cut

sub last_response {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{last_response} = $new;
    }
    return $self->{last_response};
}

sub _as_string {
    my $self = shift;
    my @texts;
    push @texts, sprintf "FQDN '%s'", $self->fqdn if defined $self->fqdn;
    push @texts, sprintf "Record Type '%s'", $self->record_type
      if defined $self->record_type;
    push @texts, sprintf "Record ID '%s'", $self->record_id
      if defined $self->record_id;
    push @texts, sprintf "TTL '%s'",   $self->ttl   if defined $self->ttl;
    push @texts, sprintf "Zone '%s'",  $self->zone  if defined $self->zone;
    push @texts, sprintf "RData '%s'", $self->rdata if defined $self->rdata;
    return join( ', ', @texts );
}

1;

=back

=head1 AUTHOR

James Bromberger, james@rcpt.to

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::info>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
