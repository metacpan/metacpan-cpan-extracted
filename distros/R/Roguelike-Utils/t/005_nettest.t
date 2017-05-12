# -*- perl -*-

# t/005_nettest.t - test network game 

use strict;

use Test::More;

eval('require IO::Socket::INET');

if( $@ ) {
      plan skip_all => 'IO::Socket::INET not available';
}
else {
      plan tests => 3;
}

use_ok( 'Games::Roguelike::World::Daemon' ); 

my $stdout = new IO::File;

open($stdout, ($^O =~ /win32/) ? ">NUL" : ">/dev/null");

my $world = myWorld->new(stdout=>$stdout, noinit=>1);

if (!$world->{main_sock}) {
		BAIL_OUT("Can't complete network test, socket won't listen");
}

isa_ok ($world, 'Games::Roguelike::World::Daemon');

$world->area(new Games::Roguelike::Area(name=>'1'));

$world->area->load(map=>'
#######
#.....#
#######
');

my $sock = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $world->{main_sock}->sockport, Proto => 'tcp');
if (!$sock) {
	$sock = IO::Socket::INET->new(PeerAddr => 'localhost', PeerPort => $world->{main_sock}->sockport, Proto => 'tcp');
	if (!$sock) {
		BAIL_OUT("Can't complete network test, socket won't connect");
	}
}
$sock->autoflush(1);
$sock->write(chr(255));

my $now = time();
$world->proc();
isa_ok($world->{vp}, 'Games::Roguelike::Mob');
$sock->write(chr(255));
$world->proc();

# good to clean up so harness doesn't panic
close ($sock);
undef $world;

package myWorld;
use base 'Games::Roguelike::World::Daemon';
sub newconn {                                           
        my $self = shift;
        my $char = Games::Roguelike::Mob->new($self->area(1),
                sym=>'@',
                color=>'',
                pov=>7
        );
        $self->{vp} = $char;                             
        $self->{state} = 'MOVE';                         
}

sub readinput {
        my $self = shift;
	$self->{state} = 'QUIT';
}

sub setfocuscolor {
	# leave color alone, just to make the output easier
}
