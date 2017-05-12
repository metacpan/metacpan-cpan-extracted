use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);

use POE qw(Component::IRC  Component::IRC::Plugin::Magic8Ball);

my $irc = POE::Component::IRC->spawn(
    nick        => 'Magic8BallBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Magic8BallBot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 irc_magic_8_ball) ],
    ],
);

$poe_kernel->run;

sub irc_magic_8_ball {
    use Data::Dumper;
    print Dumper $_[ARG0];
}

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'Magic8Ball' =>
            POE::Component::IRC::Plugin::Magic8Ball->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

