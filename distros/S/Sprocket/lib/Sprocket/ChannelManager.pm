package Sprocket::ChannelManager;

use strict;
use warnings;

use Sprocket;

our $singleton;

sub CH      () { 0 }

sub new {
    my $class = shift;
    return $singleton if ( $singleton );

    $singleton = bless([
        { }, # CH
    ], ref $class || $class );
}

sub grouplist {
    my ( $self, $plugin, $groups ) = @_; 
    
    # XXX
    #my $id = $plugin->uuid;

    return [ map {
        "/sp".( ( $_ =~ m!^/! ) ? $_ : '/'.$_ )
    } @$groups ];
}

sub subscribe {
    my ( $self, $plugin, $groups ) = @_;

    my $id = $plugin->uuid;
    my $ch = $self->[ CH ];
    foreach ( @$groups ) {
        if ( exists( $ch->{$_} ) ) {
            # they could be duping their subscription if called twice
            push( @{$ch->{$_}}, $id );
        } else {
            $ch->{$_} = [ $id ];
        }
    }
    
    require Data::Dumper;
    warn Data::Dumper->Dump([$ch]);

    return $self->grouplist( $plugin, $groups );
}

sub unsubscribe {
    my ( $self, $plugin, $groups ) = @_;

    my $id = $plugin->uuid;
    my $ch = $self->[ CH ];
    foreach my $g ( @$groups ) {
        next unless ( exists( $ch->{$g} ) );
        @{$ch->{$g}} = grep { $_ ne $id  } @{$ch->{$g}};
    }
    
    require Data::Dumper;
    warn Data::Dumper->Dump([$ch]);

    return $self->grouplist( $plugin, $groups );
}

sub get_plugins {
    my ( $self, $groups ) = @_;
    
    my %uuids;
    foreach ( @$groups ) {
        next unless ( m!/sp(/.*)! );
        if ( my $ids = $self->[ CH ]->{$1} ) {
            foreach ( @$ids ) {
                $uuids{$_}++;
            }
        }
    }

    my $plugins = [];
    foreach ( keys %uuids ) {
        my $p = $sprocket->get_plugin( $_ );
        if ( $p ) {
            push( @$plugins, $p );
        }
    }

    require Data::Dumper;
    warn "deliver to plugins:".Data::Dumper->Dump([$plugins]);
    
    return $plugins;
}

sub deliver {
    my ( $self, $type, $privname, $message ) = @_;

    warn __PACKAGE__."::deliver message: $message $message->{members}";

    unless ( ref( $message->{members} ) eq 'ARRAY' ) {
        warn "members in the message is not an array, skipping: $message->{members}";
        return;
    }

    foreach ( @{ $self->get_plugins( $message->{members} ) } ) {
        warn "handle event in channel manager $_";
        $_->handle_event( spread_message => $_ => $message );
    }

    return;
}

1;
