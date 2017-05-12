# $Id: KeyboardInt.pm,v 1.6 2003/12/03 15:35:21 autarch Exp $

package Net::SSH::Perl::Auth::KeyboardInt;

use strict;
use warnings;

use Net::SSH::Perl::Util qw( _prompt );
use Net::SSH::Perl::Constants qw(
    SSH2_MSG_USERAUTH_REQUEST
    SSH2_MSG_USERAUTH_FAILURE
    SSH2_MSG_USERAUTH_INFO_REQUEST
    SSH2_MSG_USERAUTH_INFO_RESPONSE );

use Carp qw( croak );

use Net::SSH::Perl::Auth;
use base qw( Net::SSH::Perl::Auth );

use Scalar::Util qw(weaken);

sub new {
    my $class = shift;
    my $ssh = shift;
    my $auth = bless { ssh => $ssh }, $class;
    weaken $auth->{ssh};
    $auth->enabled( $ssh->config->get('auth_kbd_interactive') &&
                    $ssh->config->get('interactive') );
    $auth;
}

sub enabled {
    my $auth = shift;
    $auth->{enabled} = shift if @_;
    $auth->{enabled};
}

sub authenticate {
    my $auth = shift;
    my $ssh = $auth->{ssh};
    my($packet);

    $packet = $ssh->packet_start(SSH2_MSG_USERAUTH_REQUEST);
    $packet->put_str($ssh->config->get('user'));
    $packet->put_str("ssh-connection");
    $packet->put_str("keyboard-interactive");
    $packet->put_str("");   ## language
    $packet->put_str("");   ## devices
    $packet->send;

    $auth->mgr->register_handler(SSH2_MSG_USERAUTH_INFO_REQUEST, sub {
        my $amgr = shift;
        my($packet) = @_;
        my $name = $packet->get_str;
        my $instructions = $packet->get_str;
        $packet->get_str;    ## language

        print $name, "\n" if $name;
        print $instructions, "\n" if $instructions;

        my $prompts = $packet->get_int32;
        my $pres = $ssh->packet_start(SSH2_MSG_USERAUTH_INFO_RESPONSE);
        $pres->put_int32($prompts);
        for (1..$prompts) {
            my $res = _prompt($packet->get_str, undef, $packet->get_int8);
            $pres->put_str($res);
        }
        $pres->send;
    });

    return 1;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Auth::KeyboardInt - Keyboard-interactive auth plugin

=head1 SYNOPSIS

    use Net::SSH::Perl::Auth;
    my $auth = Net::SSH::Perl::Auth->new('KeyboardInt', $ssh);
    $auth->authenticate;

=head1 DESCRIPTION

I<Net::SSH::Perl::Auth::KeyboardInt> performs keyboard-interactive
authentication with a remote sshd server. This plugin is only
usable when using the SSH2 protocol, and you generally never
need to use it manually; the client and server will perform
authentication negotiation in order to log in the user, a step
which happens automatically.

When you create a new authentication object, you give it a
I<Net::SSH::Perl::SSH2> object I<$ssh>, which should contain an
open connection to an ssh daemon, as well as the data that the
authentication module needs to proceed.

The I<authenticate> method will enter into a dialog with the
server. For keyboard-interactive authentication, this entails
sending a request to authenticate the user using this form
of authentication, then waiting for any number of prompts for
authentication. These prompts are then presented to the user,
who enters his/her responses; the responses are then sent
back to the server, which either allows or denies the user's
credentials.

The fact that this authentication method requires responses to
interactive prompts requires that you only use this method
in an interactive SSH connection.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
