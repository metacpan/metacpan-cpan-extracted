use strict;
use warnings;

use lib qw(../lib  lib);
use POE qw(Component::IRC  Component::IRC::Plugin::FTP::EasyUpload);

die "Usage: perl ftp_bot.pl <host> <login> <password>\n"
    unless @ARGV == 3;

my ( $Host, $Login, $Password ) = @ARGV;

my $irc = POE::Component::IRC->spawn(
    nick        => 'FTPBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'FTP uploading bot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001  irc_public) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'FTPEasyUpload' =>
            POE::Component::IRC::Plugin::FTP::EasyUpload->new(
                host    => $Host,
                login   => $Login,
                pass    => $Password,
                pub_uri => 'http://zoffix.com/',
                debug   => 1,
                unique  => 1,
            )
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $irc->yield( join => '#zofbot' );
}

sub irc_public {
    $irc->yield( privmsg => '#zofbot' =>
        'See <irc_ftp:test.txt:public_html:>'
    );
}
