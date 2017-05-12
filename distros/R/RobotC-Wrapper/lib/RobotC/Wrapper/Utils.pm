package RobotC::Wrapper::Utils;

use strict;
use warnings;
use YAML qw/LoadFile/;
use Carp qw/croak/;

our $VERSION = 1.00;

use parent qw/RobotC::Wrapper/;

sub new {
    my ( $class, %opt ) = @_;

    if (!$opt{config}) {
        croak "you must provide a config/yaml file";
    }

    my $self = $class->SUPER::new;
    $self->{conf} = LoadFile( $opt{config} );

    return bless $self, $class;
}

sub setup {
    my $self = shift;
    $self->auto( $self->{conf}->{auto}->{state} );
    $self->reflect(
        port => $self->{conf}->{reflect}->{port},
        bool => $self->{conf}->{reflect}->{state}
    );
}

sub drive {
    my $self = shift;
    $self->start_void( 'drive' );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{right},
        speed => $self->{conf}->{speed}->{forward}
    );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{left},
        speed => $self->{conf}->{speed}->{forward}
    );
    $self->end;
    return $self;
}

sub turn_left {
    my $self = shift;

    $self->start_void('turn_left');
    $self->motor(
        port  => $self->{conf}->{motor_port}->{right},
        speed => $self->{conf}->{speed}->{reverse}
    );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{left},
        speed => $self->{conf}->{speed}->{forward}
    );
    $self->end;
    return $self;
}

sub halt {
    my $self = shift;
    $self->start_void( 'halt' );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{right},
        speed => $self->{conf}->{speed}->{stopped}
    );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{left},
        speed => $self->{conf}->{speed}->{stopped}
    );
    $self->end;
    return $self;
}

sub turn_right {
    my $self = shift;

    $self->start_void( 'turn_right' );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{right},
        speed => $self->{conf}->{speed}->{forward}
    );
    $self->motor(
        port  => $self->{conf}->{motor_port}->{left},
        speed => $self->{conf}->{speed}->{reverse}
    );
    $self->end;
    return $self;
}

sub set_cont {
    my $self = shift;
    $self->start_void( 'cont' );
    $self->cont(
        port    => $self->{conf}->{motor_port}->{right},
        channel => $self->{conf}->{channel}->{2}
    );
    $self->cont(
        port    => $self->{conf}->{motor_port}->{left},
        channel => $self->{conf}->{channel}->{1}
    );
    $self->end;
    return $self;
}

sub basic_movements {
    my $self = shift;
    $self->setup;
    $self->drive;
    $self->turn_left;
    $self->turn_right;
    $self->halt;
    $self->set_cont;
}

1;
