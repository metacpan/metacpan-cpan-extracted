package POE::Component::Server::IRC::Plugin::OperServ;
BEGIN {
  $POE::Component::Server::IRC::Plugin::OperServ::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::Server::IRC::Plugin::OperServ::VERSION = '1.52';
}

use strict;
use warnings;
use POE::Component::Server::IRC::Plugin qw(:ALL);

sub new {
    my ($package, %args) = @_;
    return bless \%args, $package;
}

sub PCSI_register {
    my ($self, $ircd) = splice @_, 0, 2;

    $ircd->plugin_register($self, 'SERVER', qw(daemon_privmsg daemon_join));
    $ircd->yield(
        'add_spoofed_nick',
        {
            nick    => 'OperServ',
            umode   => 'Doi',
            ircname => 'The OperServ bot',
        },
    );
    return 1;
}

sub PCSI_unregister {
    return 1;
}

sub IRCD_daemon_privmsg {
    my ($self, $ircd) = splice @_, 0, 2;
    my $nick = (split /!/, ${ $_[0] })[0];

    return PCSI_EAT_NONE if !$ircd->state_user_is_operator($nick);
    my $request = ${ $_[2] };

    SWITCH: {
        if (my ($chan) = $request =~ /^clear\s+(#.+)\s*$/i) {
            last SWITCH if !$ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_sjoin', 'OperServ', $chan);
            last SWITCH;
        }
        if (my ($chan) = $request =~ /^join\s+(#.+)\s*$/i) {
            last SWITCH if !$ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_join', 'OperServ', $chan);
            last SWITCH;
        }
        if (my ($chan) = $request =~ /^part\s+(#.+)\s*$/i) {
            last SWITCH unless $ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_part', 'OperServ', $chan);
            last SWITCH;
        }
        if (my ($chan, $mode) = $request =~ /^mode\s+(#.+)\s+(.+)\s*$/i) {
            last SWITCH if !$ircd->state_chan_exists($chan);
            $ircd->yield('daemon_cmd_mode', 'OperServ', $chan, $mode);
            last SWITCH;
        }
        if (my ($chan, $target) = $request =~ /^op\s+(#.+)\s+(.+)\s*$/i) {
            last SWITCH unless $ircd->state_chan_exists($chan);
            $ircd->daemon_server_mode($chan, '+o', $target);
        }
    }

    return PCSI_EAT_NONE;
}

sub IRCD_daemon_join {
    my ($self, $ircd) = splice @_, 0, 2;
    my $nick = (split /!/, ${ $_[0] })[0];
    if (!$ircd->state_user_is_operator($nick) || $nick eq 'OperServ') {
        return PCSI_EAT_NONE;
    }
    my $channel = ${ $_[1] };
    return PCSI_EAT_NONE if $ircd->state_is_chan_op($nick, $channel);
    $ircd->daemon_server_mode($channel, '+o', $nick);
    return PCSI_EAT_NONE;
}

1;

=encoding utf8

=head1 NAME

POE::Component::Server::IRC::Plugin::OperServ - An OperServ plugin for POE::Component::Server::IRC

=head1 SYNOPSIS

 use POE::Component::Server::IRC::Plugin::OperServ;

 $ircd->plugin_add(
     'OperServ',
     POE::Component::Server::IRC::Plugin::OperServ->new(),
 );

=head1 DESCRIPTION

POE::Component::Server::IRC::Plugin::OperServ is a
L<POE::Component::Server::IRC|POE::Component::Server::IRC> plugin which
provides simple operator services.

This plugin provides a server user called OperServ. OperServ accepts
PRIVMSG commands from operators.

 /msg OperServ <command> <parameters>

=head1 METHODS

=head2 C<new>

Returns a plugin object suitable for feeding to
L<POE::Component::Server::IRC|POE::Component::Server::IRC>'s C<plugin_add>
method.

=head1 COMMANDS

The following commands are accepted:

=head2 clear CHANNEL

The OperServ will remove all channel modes on the indicated channel,
including all users' +ov flags. The timestamp of the channel will be reset
and the OperServ will join that channel with +o.

=head2 join CHANNEL

The OperServ will simply join the channel you specify with +o.

=head2 part CHANNEL

The OperServ will part (leave) the channel specified.

=head2 mode CHANNEL MODE

The OperServ will set the channel mode you tell it to. You can also remove
the channel mode by prefixing the mode with a '-' (minus) sign.

=head2 op CHANNEL USER

The OperServ will give +o to any user on a channel you specify. OperServ
does not need to be in that channel (as this is mostly a server hack).

Whenever the OperServ joins a channel (which you specify with the join
command) it will automatically gain +o.

=head1 AUTHOR

Chris 'BinGOs' Williams

=head1 LICENSE

Copyright C<(c)> Chris Williams

This module may be used, modified, and distributed under the same terms as
Perl itself. Please see the license that came with your Perl distribution
for details.

=head1 SEE ALSO

L<POE::Component::Server::IRC|POE::Component::Server::IRC>

=cut
