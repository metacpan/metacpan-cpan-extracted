#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib ../lib);
use POE qw(Component::IRC  Component::IRC::Plugin::WWW::GetPageTitle);

my $irc = POE::Component::IRC->spawn(
    nick        => 'TitleBot222',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'TitleBot222',
    plugin_debug => 1,
    debug       => 1,
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 ) ],
    ],
);

$poe_kernel->run;


sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'get_page_title' =>
            POE::Component::IRC::Plugin::WWW::GetPageTitle->new(
                find_uris => 1,
                addressed => 0,
                trigger   => qr/^/,
            ),
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}


