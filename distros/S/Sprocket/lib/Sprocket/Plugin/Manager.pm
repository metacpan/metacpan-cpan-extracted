package Sprocket::Plugin::Manager;

use Sprocket qw( Plugin );
use base 'Sprocket::Plugin';

use POE::Filter::Line;
use Data::Dumper;

BEGIN {
    eval "use Devel::Gladiator";
    # You can get it here:
    # http://code.sixapart.com/svn/Devel-Gladiator/trunk/
    if ( $@ ) {
        eval 'sub HAS_GLADIATOR() { 0 }';
    } else {
        eval 'sub HAS_GLADIATOR() { 1 }';
    }
};

use strict;
use warnings;

sub new {
    my $class = shift;
    $class->SUPER::new(
        name => 'Manager',
        @_
    );
}

# ---------------------------------------------------------
# server

sub local_connected {
    my ( $self, $server, $con, $socket ) = @_;
    
    $self->take_connection( $con );

    # POE::Filter::Stackable object:
    $con->filter->push( POE::Filter::Line->new() );
    
    $con->filter->shift(); # POE::Filter::Stream
    
    $con->send( "Sprocket Manager" );
    $con->call( cmd_help => [] );
}

sub local_receive {
    my ( $self, $server, $con, $data ) = @_;
    
    #$self->_log( v => 4, msg => "manager:".Data::Dumper->Dump([ $data ]));
    my ( $cmd, @args ) = split( /\s+/, $data );
    
    if ( $self->can( "cmd_$cmd" ) ) {
        $con->call( "cmd_$cmd" => \@args );
        $con->send( "command finished." );
    } else {
        $con->send( "unknown command.  Need 'help'?" );
    }
    
    return 1;
}

sub cmd_help {
    my ( $self, $server, $con, $args ) = @_;
    
    $con->send( "commands: dump [val], list_conn, con_dump [cid], find_leaks, find_refs, quit" );
    if ( $args->[0] ) {
        $con->send( "no detailed info for  $args->[0]" );
    }
}

sub cmd_dump {
    my ( $self, $server, $con, $args ) = @_;
    
    $con->send( eval "Data::Dumper->Dump([$args->[0]])" );
}

sub cmd_x {
    my ( $self, $server, $con, $args ) = @_;
    
    if ( $args->[0] =~ m/^0x(\S+)/i ) {
        my $c = $server->get_connection( $1 );
        my $res = eval "$args->[1]";
        $con->send( $res );
        $con->send( $@ ) if ( $@ );
    } else {
        my $res = eval "$args->[0]";
        $con->send( $res );
        $con->send( $@ ) if ( $@ );
    }
}

sub cmd_list_conn {
    my ( $self, $server, $con, $args ) = @_;
    
    foreach my $p ( @{ $sprocket->get_components } ) {
        next unless ( $p );
        foreach my $c ( values %{$p->{heaps}} ) {
            $con->send( $p->name." - $c - ".$c->peer_addr );
        }
    }
}

sub cmd_con_dump {
    my ( $self, $server, $con, $args ) = @_;
    
    return $con->send( "con_dump <id>" )
        unless ( @$args );
    
    $con->send('looking for '.$args->[0]);
    LOOP: foreach my $p ( @{ $sprocket->get_components } ) {
        next unless ( $p );
        foreach my $c ( values %{$p->{heaps}} ) {
            next unless ( lc( $c->ID ) eq $args->[0] );
            $con->send( $p->name." - $c - ".Data::Dumper->Dump([ $c ]) );
            last LOOP;
        }
    }
}

sub cmd_find_leaks {
    my ( $self, $server, $con, $args ) = @_;
    
    return $con->send( "Devel::Gladiator not installed: http://code.sixapart.com/svn/Devel-Gladiator/trunk/" )
        unless ( HAS_GLADIATOR );

    my $array = Devel::Gladiator::walk_arena();
    for my $i ( 0 .. $#{$array} ) {
        next unless ( ref($array->[$i]) =~ m/^Sprocket\:\:Connection/ );
        my $found = undef;
        foreach my $c ( @{ $sprocket->get_components } ) {
            next unless ( $c );
            $found = $c
                if ( exists( $c->{heaps}->{$array->[$i]->ID} ) );
        }
        if ($found) {
            #$con->send( "cometd connection: ".$array->[$i]->ID." with plugin ".$array->[$i]->plugin()." found in ".$found->name );
        } else {
            $con->send( "cometd connection: ".$array->[$i]->ID." with plugin ".$array->[$i]->plugin()." not found --- leaked!" );
        }
    }
}

sub cmd_find_refs {
    my ( $self, $server, $con, $args ) = @_;

    return $con->send( "Devel::Gladiator not installed http://code.sixapart.com/svn/Devel-Gladiator/trunk/" )
        unless ( HAS_GLADIATOR );

    my $array = Devel::Gladiator::walk_arena();
    for my $i ( 0 .. $#{$array} ) {
        if ( ref($array->[$i]) =~ m/^Sprocket/ && ref($array->[$i]) !~ m/^Sprocket::Session/ ) {
            $con->send( "obj: $array->[$i] ".( $array->[$i]->can( "name" ) ? $array->[$i]->name : '' ));
        }
    }
}

sub cmd_quit {
    my ( $self, $server, $con, $args ) = @_;
    
    $con->send( "goodbye." );
    $con->close();
}
    
1;
