package Net::Dynect::REST::ZoneChanges;
# $Id: ZoneChanges.pm 177 2010-09-28 00:50:02Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Carp;
use Net::Dynect::REST::RData;
our $VERSION = do { my @r = (q$Revision: 177 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME 

Net::Dynect::REST::Zone - List changes pending for a DNS zone

=cut 

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;
    $self->{connection} = $args{connection} if defined $args{connection};
    $self->get( $args{zone} ) if defined $args{zone};
    return $self;
}

sub get {
    my $self = shift;
    my $zone = shift;
    if ( not defined $zone ) {
        carp "Need a zone to check changes for";
        return;
    }
    if ( not defined $self->{connection} ) {
        carp "Don't have a connection";
        return;
    }
    my $request = Net::Dynect::REST::Request->new(
        operation => 'read',
        service   => "ZoneChanges/$zone"
    );
    my $response = $self->{connection}->execute($request);
    if ( $response->status !~ /^success$/i ) {
        carp "" . $response;
        return;
    }
    $self->zone($zone);
    return 1 unless $response->data;
    foreach ( @{ $response->data } ) {
        push @{ $self->{changes} },
          Net::Dynect::REST::RData->new( data => $_->{data}->{value} );
    }
    return 1;
}

sub delete {
    my $self = shift;
    return unless defined $self->{connection};
    my $request = Net::Dynect::REST::Request->new(
        operation => 'delete',
        service   => 'ZoneChanges/' . $self->zone
    );
    my $response = $self->{connection}->execute($request);
    if ( $response->status =~ /^success$/i ) {
        $self = undef;
        return 1;
    }
    else {
        print $response->msg->[0]->info;
    }
}

sub zone {
    my $self = shift;
    if (@_) {
        my $new = shift;
        if ( defined $self->{zone} ) {
            carp
"Cannot change name from what it has been set to. Create a new instance for a new zone, and delete the old one";
            return;
        }
        elsif ( $new !~ /^\S+/ ) {
            carp "Zone names must not have spaces in them";
            return;
        }
        $self->{zone} = $new;
    }
    return $self->{zone};
}

sub changes {
    my $self = shift;
    if (@_) {
        my $new = shift;
        my $self->{changes} = $new;
    }
    return $self->{changes};
}

sub _as_string {
    my $self = shift;
    my @texts;
    push @texts, sprintf "Zone '%s'", $self->name if defined $self->name;
    push @texts, sprintf "Changes:\n", join( "\n", $self->changes );
    push @texts, sprintf "Serial '%s'", $self->serial if defined $self->serial;
    push @texts, sprintf "Serial Style '%s'", $self->serial_style
      if defined $self->serial_style;
    return join( ', ', @texts );
}

1;


=head1 SYNOPSIS

 use Net::Dynect::REST;
 use Net::Dynect::REST::Zone;
 $dynect = Net::Dynect::REST->new(user_name => 'me', customer_name => 'myco', password => 'secret');
 $zone = Net::Dynect::REST::Zone->new(connection => $dynect, zone => 'example.com');
 print "Zone details: $zone\n";

 $zone->freeze;
 $zone->thaw;
 $zone->publish;
 $zone->delete;

 $new_zone = Net::Dynect::REST::Zone->new(connection => $dynect);
 $zone->name('new.example.com');
 $zone->serial_style('increment');
 $zone->zone_type('Primary');
 $zone->save(rname => 'admin@example.com', ttl => 900);

=head1 REQUIRES

Net::Dynect::REST, Carp

=head1 EXPORTS

Nothing

=head1 Description

A Net::Dynect::REST::Zone is a representation of a DNS Zone in the Dynect REST interface. It permits the user to load zones that already exist, inspect their attributes (eg, serial number), freeze the zone from modification, thaw the zone, publish zone changes live, delete the zone, and create a new zone.

=head1 METHODS

=head2 Creation

=over 4

=item Net::Dynect::REST::Zone->new(connection => $dynect)

Creates and returns a Net::Dynect::REST::Zone object. You should pass this method your connection object, which should have a valid session established, in order to do anything useful.

=back

=head2 Operations

=over 4

=item $zone->get('zone.to.get.com');

This will attempt to get the details of the zone from Dynect.

=item $zone->save(rname => 'admin@example.com', ttl => 900);

This will try to save a new zone (which has already had its name and serial style set via the L</Attributes> below). You must supply the "I<rname>" parameter of the email address for the resposible person, and you may supply a I<ttl> value.


=item $zone->delete();

This will tryt o delete the zone that was previously loaded.

=item $zone->freeze();

This will freeze the zone from any changes.

=item $zone->thaw();

This will unfreeze the zone and permit changes.

=item $zone->publish();

This will commit changes to the zone to the live production environment.

=back

=head2 Attributes

=over 4

=item $zone->name();

This will get (or set) the zone's name, eg: example.com.

=item $zone->serial();

This will get (or set) the zones serial number.

=item $zone->zone_type();

This will get (or set) the zone type, either:

=over 4

=item * Primary

=item * Secondary

=back

=item $zone->serial_style();

This will get or set the serial style for the zone, either 

=over 4

=item * increment

=item * epoch

=item * day

=item * minute

=back

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
