#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../lib");
use Test::More tests => 2;

package Dashboard;
use Moose;
has state => (is => 'rw');
sub door_opened { shift->state('open') }
sub door_closed { shift->state('closed') }

package Car;
use Moose;
with 'MooseX::Role::Listenable' => {event => 'door_opened'};
with 'MooseX::Role::Listenable' => {event => 'door_closed'};
sub open_door  { shift->door_opened }
sub close_door { shift->door_closed }

package main;
use strict;
use warnings;

my $car = Car->new;
my $dash = Dashboard->new;

$car->add_door_opened_listener($dash);
$car->add_door_closed_listener($dash);

$car->open_door;
is $dash->state, open => 'open';

$car->close_door;
is $dash->state, closed => 'closed';
