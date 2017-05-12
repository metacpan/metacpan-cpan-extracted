package POE::Component::IRC::Plugin::MegaHAL;
BEGIN {
  $POE::Component::IRC::Plugin::MegaHAL::AUTHORITY = 'cpan:HINRIK';
}
{
  $POE::Component::IRC::Plugin::MegaHAL::VERSION = '0.46';
}

use strict;
use warnings FATAL => 'all';
use Carp;
use Encode qw(decode_utf8 encode_utf8 is_utf8);
use IRC::Utils qw(lc_irc matches_mask_array decode_irc strip_color strip_formatting);
use List::Util qw(first);
use POE;
use POE::Component::AI::MegaHAL;
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE);

sub new {
    my ($package, %args) = @_;
    my $self = bless \%args, $package;

    if (ref $self->{MegaHAL} eq 'POE::Component::AI::MegaHAL') {
        $self->{keep_alive} = 1;
    }
    else {
        $self->{MegaHAL} = POE::Component::AI::MegaHAL->spawn(
            ($self->{MegaHAL_args} ? %{ $self->{MegaHAL_args} } : () ),
        );
    }

    $self->{Method} = 'notice' if !defined $self->{Method} || $self->{Method} !~ /privmsg|notice/;
    $self->{abusers} = { };
    $self->{Abuse_interval} = 60 if !defined $self->{Abuse_interval};

    return $self;
}

sub PCI_register {
    my ($self, $irc) = @_;

    if (!$irc->isa('POE::Component::IRC::State')) {
        die __PACKAGE__ . " requires PoCo::IRC::State or a subclass thereof\n";
    }

    $self->{irc} = $irc;
    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                _sig_DIE
                _save
                _megahal_reply
                _megahal_greeting
                _megahal_saved
                _greet_handler
                _msg_handler
            )],
        ],
    );

    $irc->plugin_register($self, 'SERVER', qw(isupport ctcp_action join public));
    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;

    $irc->yield(part => $self->{Own_channel}) if $self->{Own_channel};
    delete $self->{irc};
    $poe_kernel->post($self->{session_id}, '_save');

    return 1;
}

sub _save {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    $kernel->post(
        $self->{MegaHAL}->session_id(),
        '_cleanup',
        { event => '_megahal_saved' },
    );
    return;
}

sub _start {
    my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];
    $kernel->sig(DIE => '_sig_DIE');
    $self->{session_id} = $session->ID();
    $kernel->refcount_increment($self->{session_id}, __PACKAGE__);
    return;
}

sub _sig_DIE {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};
    warn "Error: Event $ex->{event} in $ex->{dest_session} raised exception:\n";
    warn "  $ex->{error_str}\n";
    $kernel->sig_handled();
    return;
}

sub _megahal_reply {
    my ($self, $info) = @_[OBJECT, ARG0];
    my $reply = $self->_normalize_megahal($info->{reply});
    $reply = encode_utf8($reply);

    if ($reply =~ s/^\x01 //) {
        $self->{irc}->yield('ctcp', $info->{_target}, "ACTION $reply");
    }
    else {
        $self->{irc}->yield($self->{Method}, $info->{_target}, $reply);
    }
    return;
}

sub _megahal_greeting {
    my ($self, $info) = @_[OBJECT, ARG0];
    my $reply = $self->_normalize_megahal($info->{reply});
    $reply = encode_utf8($reply);

    if ($reply =~ s/^\x01 //) {
        $self->{irc}->yield('ctcp', $info->{_target}, "ACTION $reply");
    }
    else {
        $reply = "$info->{_nick}: $reply";
        $self->{irc}->yield($self->{Method}, $info->{_target}, $reply);
    }
    return;
}

sub _megahal_saved {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    if (!$self->{keep_alive}) {
        $poe_kernel->post($self->{MegaHAL}->session_id(), 'shutdown');
    }
    delete $self->{MegaHAL};
    $poe_kernel->refcount_decrement($self->{session_id}, __PACKAGE__);
    return;
}

sub _ignoring_channel {
    my ($self, $chan) = @_;

    return if $self->{Own_channel} && $self->_is_own_channel($chan);

    if ($self->{Channels}) {
        return 1 if !first {
            my $c = $chan;
            $c = decode_irc($c) if is_utf8($_);
            $_ eq $c
        } @{ $self->{Channels} };
    }
    return;
}

sub _ignoring_user {
    my ($self, $user) = @_;

    if ($self->{Ignore_masks}) {
        my $mapping = $self->{irc}->isupport('CASEMAPPING');
        return 1 if keys %{ matches_mask_array($self->{Ignore_masks}, [$user], $mapping) };
    }

    return;
}

sub _ignoring_abuser {
    my ($self, $user, $chan) = @_;

    # abuse protection
    my $key = "$user $chan";
    my $last_time = delete $self->{abusers}->{$key};
    $self->{abusers}->{$key} = time;

    return 1 if $last_time && (time - $last_time < $self->{Abuse_interval});
    return;
}

sub _msg_handler {
    my ($self, $kernel, $type, $user, $chan, $what) = @_[OBJECT, KERNEL, ARG0..$#_];
    my $nick = $self->{irc}->nick_name();

    return if $self->_ignoring_channel($chan);
    return if $self->_ignoring_user($user);
    $what = _normalize_irc($what);

    # should we reply?
    my $event = '_no_reply';
    if ($self->{Own_channel} && $self->_is_own_channel($chan)
        || $type eq 'public' && $what =~ s/^\s*\Q$nick\E[:,;.!?~]?\s//i
        || $self->{Talkative} && $what =~ /\Q$nick/i)
    {
        $event = '_megahal_reply';
    }

    if ($event eq '_megahal_reply' && $self->_ignoring_abuser($user, $chan)) {
        $event = '_no_reply';
    }

    if ($self->{Ignore_regexes}) {
        for my $regex (@{ $self->{Ignore_regexes} }) {
            return if $what =~ $regex;
        }
    }

    $kernel->post($self->{MegaHAL}->session_id() => do_reply => {
        event   => $event,
        text    => $what,
        _target => $chan,
    });

    return;
}

sub _is_own_channel {
    my $self = shift;
    my $chan = lc_irc(shift);
    my $own  = lc_irc($self->{Own_channel});

    $chan = decode_irc($chan) if is_utf8($own);
    return 1 if $chan eq $own;
    return;
}

sub _greet_handler {
    my ($self, $kernel, $user, $chan) = @_[OBJECT, KERNEL, ARG0, ARG1];

    return if $self->_ignoring_user($user, $chan);
    return if !$self->{Own_channel} || !$self->_is_own_channel($chan);

    $kernel->post($self->{MegaHAL}->session_id() => initial_greeting => {
        event   => '_megahal_greeting',
        _target => $chan,
        _nick   => (split /!/, $user)[0],
    });

    return;
}

sub _normalize_megahal {
    my ($self, $line) = @_;

    $line = decode_utf8($line);
    if ($self->{English}) {
        $line =~ s{\bi\b}{I}g;
        $line =~ s{(?<=\w)$}{.};
    }
    return $line;
}

sub _normalize_irc {
    my ($line) = @_;

    $line = decode_irc($line);
    $line = strip_color($line);
    $line = strip_formatting($line);
    return $line;
}

sub brain {
    my ($self) = @_;
    return $self->{MegaHAL};
}

sub transplant {
    my ($self, $brain) = @_;

    if (ref $brain ne 'POE::Component::AI::MegaHAL') {
        croak 'Argument must be a POE::Component::AI::MegaHAL instance';
    }

    my $old_brain = $self->{MegaHAL};
    $poe_kernel->post($self->{MegaHAL}->session_id(), 'shutdown') if !$self->{keep_alive};
    $self->{MegaHAL} = $brain;
    $self->{keep_alive} = 1;
    return $old_brain;
}

sub S_isupport {
    my ($self, $irc) = splice @_, 0, 2;
    $irc->yield(join => $self->{Own_channel}) if $self->{Own_channel};
    return PCI_EAT_NONE;
}

sub S_ctcp_action {
    my ($self, $irc) = splice @_, 0, 2;
    my $user         = ${ $_[0] };
    my $chan         = ${ $_[1] }->[0];
    my $what         = ${ $_[2] };
    my $chantypes    = join('', @{ $irc->isupport('CHANTYPES') || ['#', '&']});

    return PCI_EAT_NONE if $chan !~ /^[$chantypes]/;

    $poe_kernel->post(
        $self->{session_id},
        '_msg_handler',
        'action',
        $user,
        $chan,
        "\x01 $what",
    );

    return PCI_EAT_NONE;
}

sub S_public {
    my ($self, $irc) = splice @_, 0, 2;
    my $user         = ${ $_[0] };
    my $chan         = ${ $_[1] }->[0];
    my $what         = ${ $_[2] };

    $poe_kernel->post($self->{session_id} => _msg_handler => 'public', $user, $chan, $what);
    return PCI_EAT_NONE;
}

sub S_join {
    my ($self, $irc) = splice @_, 0, 2;
    my $user         = ${ $_[0] };
    my $chan         = ${ $_[1] };

    return PCI_EAT_NONE if (split /!/, $user)[0] eq $irc->nick_name();
    $poe_kernel->post($self->{session_id} => _greet_handler => $user, $chan);
    return PCI_EAT_NONE;
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::MegaHAL - A PoCo-IRC plugin which provides access to a MegaHAL conversation simulator.

=head1 SYNOPSIS

To quickly get an IRC bot with this plugin up and running, you can use
L<App::Pocoirc|App::Pocoirc>:

 $ pocoirc -s irc.perl.org -j '#bots' -a MegaHAL

Or use it in your code:

 use POE::Component::IRC::Plugin::MegaHAL;
 
 $irc->plugin_add('MegaHAL', POE::Component::IRC::Plugin::MegaHAL->new(
     Own_channel    => '#bot_chan',
     English        => 1,
     Ignore_regexes => [ qr{^\s*\w+://\S+\s*$} ], # ignore URL-only lines
 ));
 
=head1 DESCRIPTION

POE::Component::IRC::Plugin::MegaHAL is a
L<POE::Component::IRC|POE::Component::IRC> plugin. It provides "intelligence"
through the use of L<POE::Component::AI::MegaHAL|POE::Component::AI::MegaHal>.
It will talk back when addressed by channel members (and possibly in other
situations, see L<C<new>|/"new">). An example:

 --> megahal_bot joins #channel
 <Someone> oh hi there
 <Other> hello there
 <Someone> megahal_bot: hi
 <megahal_bot> oh hi there

It will occasionally send CTCP ACTIONS (/me) too, if the reply in question
happens to be based on an earlier CTCP ACTION from someone.

All NOTICEs are ignored, so if your other bots only issue NOTICEs like
they should, they will be ignored automatically.

Before using, you should read the documentation for
L<POE::Component::AI::MegaHAL|POE::Component::AI::MegaHAL> and by extension,
L<AI::MegaHAL|AI::MegaHAL>, so you have an idea of what to pass as the
B<'MegaHAL_args'> parameter to L<C<new>|/"new">.

This plugin requires the IRC component to be
L<POE::Component::IRC::State|POE::Component::IRC::State> or a subclass thereof.

=head1 METHODS

=head2 C<new>

Takes the following optional arguments:

B<'MegaHAL'>, a reference to an existing
L<POE::Component::AI::MegaHAL|POE::Component::AI::MegaHAL> object you have
lying around. Useful if you want to use it with multiple IRC components.
If this argument is not provided, the plugin will construct its own object.

B<'MegaHAL_args'>, a hash reference containing arguments to pass to the
constructor of a new L<POE::Component::AI::MegaHAL|POE::Component::AI::MegaHAL>
object.

B<'Channels'>, an array reference of channel names. If this is provided, the
bot will only listen/respond in the specified channels, rather than all
channels.

B<'Own_channel'>, a channel where it will reply to all messages, as well as
greet everyone who joins. The plugin will take care of joining the channel.
It will part from it when the plugin is removed from the pipeline. Defaults
to none.

B<'Abuse_interval'>, default is 60 (seconds), which means that user X in
channel Y has to wait that long before addressing the bot in the same channel
if he wants to get a reply. Setting this to 0 effectively turns off abuse
protection.

B<'Talkative'>, when set to a true value, the bot will respond whenever
someone mentions its name (in a PRIVMSG or CTCP ACTION (/me)). If false, it
will only respond when addressed directly with a PRIVMSG. Default is false.

B<'Ignore_masks'>, an array reference of IRC masks (e.g. "purl!*@*") to
ignore.

B<'Ignore_regexes'>, an array reference of regex objects. If a message
matches any of them, it will be ignored. Handy for ignoring messages with
URLs in them.

B<'Method'>, how you want messages to be delivered. Valid options are
'notice' (the default) and 'privmsg'.

B<'English'>, when set to a true value, some English-language corrections
will be applied to the bot's output. Currently it will capitalizes the word
'I' and make sure paragraphs end with '.' where appropriate. Defaults to
false.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s plugin_add() method.

=head2 C<brain>

Takes no arguments. Returns the underlying
L<POE::Component::AI::MegaHAL|POE::Component::AI::MegaHAL> object being used
by the plugin.

=head2 C<transplant>

Replaces the brain with the supplied
L<POE::Component::AI::MegaHAL|POE::Component::AI::MegaHAL> instance. Shuts
down the old brain if it was instantiated by the plugin itself.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 KUDOS

Those go to Chris C<BinGOs> Williams and his friend GumbyBRAIN.

=cut
