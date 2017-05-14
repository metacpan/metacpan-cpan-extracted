package Sprites;

#/*
 #* KAsteroids - Copyright (c) Martin R. Jones 1997
 #*
 #* Part of the KDE project
 #*/


use constant {
    ID_ROCK_LARGE          => 1024,
    ID_ROCK_MEDIUM         => 1025,
    ID_ROCK_SMALL          => 1026,
    ID_MISSILE             => 1030,
    ID_BIT                 => 1040,
    ID_EXHAUST             => 1041,
    ID_ENERGY_POWERUP      => 1310,
    ID_TELEPORT_POWERUP    => 1311,
    ID_BRAKE_POWERUP       => 1312,
    ID_SHIELD_POWERUP      => 1313,
    ID_SHOOT_POWERUP       => 1314,
    ID_SHIP                => 1350,
    ID_SHIELD              => 1351,
    MAX_SHIELD_AGE         => 350,
    MAX_POWERUP_AGE        => 500,
    MAX_MISSILE_AGE        => 40,
};

1;

package KMissile;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use AnimatedPixmapItem;
use QtCore4::isa qw(AnimatedPixmapItem);

sub NEW
{
    my ( $class, $s, $c ) = @_;
    $class->SUPER::NEW($s, $c);
    this->{myAge} = 0;
}

sub type() { return Sprites::ID_MISSILE; }

sub growOlder() { this->{myAge}++; }
sub expired() { return this->{myAge} > Sprites::MAX_MISSILE_AGE; }

1;

package KBit;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use AnimatedPixmapItem;
use QtCore4::isa qw(AnimatedPixmapItem);

sub NEW
{
    my ( $class, $s, $c ) = @_;
    $class->SUPER::NEW($s, $c);
	this->{death} = 7;
}

sub type() {  return Sprites::ID_BIT; }

sub setDeath($) { my ( $d )= @_; this->{death} = $d; }
sub growOlder() { this->{death}--; }
sub expired() { return this->{death} <= 0; }

1;

package KExhaust;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use AnimatedPixmapItem;
use QtCore4::isa qw(AnimatedPixmapItem);

sub NEW
{
    my ( $class, $s, $c ) = @_;
    $class->SUPER::NEW($s, $c);
	this->{death} = 1;
}

sub type() {  return Sprites::ID_EXHAUST; }

sub setDeath($) { my ($d) = @_; this->{death} = $d; }
sub growOlder() { this->{death}--; }
sub expired() { return this->{death} <= 0; }

1;

package KPowerup;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use AnimatedPixmapItem;
use QtCore4::isa qw(AnimatedPixmapItem);

sub NEW
{
    my ( $class, $s, $c, $t ) = @_;
    $class->SUPER::NEW($s, $c);
    this->{myAge} = 0;
    this->{_type} = $t;
}

sub type() { return this->{_type}; }

sub growOlder() { this->{myAge}++; }
sub expired() { return this->{myAge} > Sprites::MAX_POWERUP_AGE; }

1;

package KRock;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use AnimatedPixmapItem;
use QtCore4::isa qw(AnimatedPixmapItem);

sub NEW
{
    my ( $class, $s, $c, $t, $sk, $st ) = @_;
    $class->SUPER::NEW($s, $c);
    this->{_type} = $t;
    this->{skip} = $sk;
    this->{cskip} = $sk;
    this->{step} = $st;
}

sub nextFrame
{
    if (this->{cskip}-- <= 0) {
        setFrame( (frame()+this->{step}+frameCount()) % frameCount() );
        this->{cskip} = abs(this->{skip});
    }
}

sub type() { return this->{_type}; }

1;

package KShield;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use AnimatedPixmapItem;
use QtCore4::isa qw(AnimatedPixmapItem);

sub NEW
{
    my ( $class, $s, $c ) = @_;
    $class->SUPER::NEW($s, $c);
}

sub type() { return Sprites::ID_SHIELD; }

1;
