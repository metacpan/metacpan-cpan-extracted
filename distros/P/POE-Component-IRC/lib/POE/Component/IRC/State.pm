package POE::Component::IRC::State;
BEGIN {
  $POE::Component::IRC::State::AUTHORITY = 'cpan:HINRIK';
}
$POE::Component::IRC::State::VERSION = '6.88';
use strict;
use warnings FATAL => 'all';
use IRC::Utils qw(uc_irc parse_mode_line normalize_mask);
use POE;
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE);
use base qw(POE::Component::IRC);

# Event handlers for tracking the STATE. $self->{STATE} is used as our
# namespace. uc_irc() is used to create unique keys.

# RPL_WELCOME
# Make sure we have a clean STATE when we first join the network and if we
# inadvertently get disconnected.
sub S_001 {
    my $self = shift;
    $self->SUPER::S_001(@_);
    shift @_;

    delete $self->{STATE};
    delete $self->{NETSPLIT};
    $self->{STATE}{usermode} = '';
    $self->yield(mode => $self->nick_name());
    return PCI_EAT_NONE;
}

sub S_disconnected {
    my $self = shift;
    $self->SUPER::S_disconnected(@_);
    shift @_;

    my $nickinfo = $self->nick_info($self->nick_name());
    $nickinfo = {} if !defined $nickinfo;
    my $channels = $self->channels();
    push @{ $_[-1] }, $nickinfo, $channels;
    return PCI_EAT_NONE;
}

sub S_error {
    my $self = shift;
    $self->SUPER::S_error(@_);
    shift @_;

    my $nickinfo = $self->nick_info($self->nick_name());
    $nickinfo = {} if !defined $nickinfo;
    my $channels = $self->channels();
    push @{ $_[-1] }, $nickinfo, $channels;
    return PCI_EAT_NONE;
}

sub S_socketerr {
    my ($self, undef) = splice @_, 0, 2;
    my $nickinfo = $self->nick_info($self->nick_name());
    $nickinfo = {} if !defined $nickinfo;
    my $channels = $self->channels();
    push @{ $_[-1] }, $nickinfo, $channels;
    return PCI_EAT_NONE;
}

sub S_join {
    my ($self, undef) = splice @_, 0, 2;
    my ($nick, $user, $host) = split /[!@]/, ${ $_[0] };
    my $map   = $self->isupport('CASEMAPPING');
    my $chan  = ${ $_[1] };
    my $uchan = uc_irc($chan, $map);
    my $unick = uc_irc($nick, $map);

    if ($unick eq uc_irc($self->nick_name(), $map)) {
        delete $self->{STATE}{Chans}{ $uchan };
        $self->{CHANNEL_SYNCH}{ $uchan } = {
            MODE  => 0,
            WHO   => 0,
            BAN   => 0,
            _time => time(),
        };
        $self->{STATE}{Chans}{ $uchan } = {
            Name => $chan,
            Mode => ''
        };

        # fake a WHO sync if we're only interested in people's user@host
        # and the server provides those in the NAMES reply
        if (exists $self->{whojoiners} && !$self->{whojoiners}
            && $self->isupport('UHNAMES')) {
            $self->_channel_sync($chan, 'WHO');
        }
        else {
            $self->yield(who => $chan);
        }
        $self->yield(mode => $chan);
        $self->yield(mode => $chan => 'b');
    }
    else {
      SWITCH: {
        my $netsplit = "$unick!$user\@$host";
        if ( exists $self->{NETSPLIT}{Users}{ $netsplit } ) {
            # restore state from NETSPLIT if it hasn't expired.
            my $nuser = delete $self->{NETSPLIT}{Users}{ $netsplit };
            if ( ( time - $nuser->{stamp} ) < ( 60 * 60 ) ) {
              $self->{STATE}{Nicks}{ $unick } = $nuser->{meta};
              $self->send_event_next(irc_nick_sync => $nick, $chan);
              last SWITCH;
            }
        }
        if ( (!exists $self->{whojoiners} || $self->{whojoiners})
            && !exists $self->{STATE}{Nicks}{ $unick }{Real}) {
                $self->yield(who => $nick);
                push @{ $self->{NICK_SYNCH}{ $unick } }, $chan;
        }
        else {
            # Fake 'irc_nick_sync'
            $self->send_event_next(irc_nick_sync => $nick, $chan);
        }
      }
    }

    $self->{STATE}{Nicks}{ $unick }{Nick} = $nick;
    $self->{STATE}{Nicks}{ $unick }{User} = $user;
    $self->{STATE}{Nicks}{ $unick }{Host} = $host;
    $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan } = '';
    $self->{STATE}{Chans}{ $uchan }{Nicks}{ $unick } = '';

    return PCI_EAT_NONE;
}

sub S_chan_sync {
    my ($self, undef) = splice @_, 0, 2;
    my $chan = ${ $_[0] };

    if ($self->{awaypoll}) {
        $poe_kernel->state(_away_sync => $self);
        $poe_kernel->delay_add(_away_sync => $self->{awaypoll} => $chan);
    }

    return PCI_EAT_NONE;
}

sub S_part {
    my ($self, undef) = splice @_, 0, 2;
    my $map   = $self->isupport('CASEMAPPING');
    my $nick  = uc_irc((split /!/, ${ $_[0] } )[0], $map);
    my $uchan = uc_irc(${ $_[1] }, $map);

    if ($nick eq uc_irc($self->nick_name(), $map)) {
        delete $self->{STATE}{Nicks}{ $nick }{CHANS}{ $uchan };
        delete $self->{STATE}{Chans}{ $uchan }{Nicks}{ $nick };

        for my $member ( keys %{ $self->{STATE}{Chans}{ $uchan }{Nicks} } ) {
            delete $self->{STATE}{Nicks}{ $member }{CHANS}{ $uchan };
            if ( keys %{ $self->{STATE}{Nicks}{ $member }{CHANS} } <= 0 ) {
                delete $self->{STATE}{Nicks}{ $member };
            }
        }

        delete $self->{STATE}{Chans}{ $uchan };
    }
    else {
        delete $self->{STATE}{Nicks}{ $nick }{CHANS}{ $uchan };
        delete $self->{STATE}{Chans}{ $uchan }{Nicks}{ $nick };
        if ( !keys %{ $self->{STATE}{Nicks}{ $nick }{CHANS} } ) {
            delete $self->{STATE}{Nicks}{ $nick };
        }
    }

    return PCI_EAT_NONE;
}

sub S_quit {
    my ($self, undef) = splice @_, 0, 2;
    my $map   = $self->isupport('CASEMAPPING');
    my $nick  = (split /!/, ${ $_[0] })[0];
    my $msg   = ${ $_[1] };
    my $unick = uc_irc($nick, $map);
    my $netsplit = 0;

    push @{ $_[-1] }, [ $self->nick_channels( $nick ) ];

    # Check if it is a netsplit
    $netsplit = 1 if _is_netsplit( $msg );

    if ($unick ne uc_irc($self->nick_name(), $map)) {
        for my $uchan ( keys %{ $self->{STATE}{Nicks}{ $unick }{CHANS} } ) {
            delete $self->{STATE}{Chans}{ $uchan }{Nicks}{ $unick };
            # No don't stash the channel state.
            #$self->{NETSPLIT}{Chans}{ $uchan }{NICKS}{ $unick } = $chanstate
            #  if $netsplit;
        }

        my $nickstate = delete $self->{STATE}{Nicks}{ $unick };
        if ( $netsplit ) {
          delete $nickstate->{CHANS};
          $self->{NETSPLIT}{Users}{ "$unick!" . join '@', @{$nickstate}{qw(User Host)} } =
             { meta => $nickstate, stamp => time };
        }
    }

    return PCI_EAT_NONE;
}

sub _is_netsplit {
  my $msg = shift || return;
  return 1 if $msg =~ /^\s*\S+\.[a-z]{2,} \S+\.[a-z]{2,}$/i;
  return 0;
}

sub S_kick {
    my ($self, undef) = splice @_, 0, 2;
    my $chan  = ${ $_[1] };
    my $nick  = ${ $_[2] };
    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);
    my $uchan = uc_irc($chan, $map);

    push @{ $_[-1] }, $self->nick_long_form( $nick );

    if ( $unick eq uc_irc($self->nick_name(), $map)) {
        delete $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan };
        delete $self->{STATE}{Chans}{ $uchan }{Nicks}{ $unick };

        for my $member ( keys %{ $self->{STATE}{Chans}{ $uchan }{Nicks} } ) {
            delete $self->{STATE}{Nicks}{ $member }{CHANS}{ $uchan };
            if ( keys %{ $self->{STATE}{Nicks}{ $member }{CHANS} } <= 0 ) {
                delete $self->{STATE}{Nicks}{ $member };
            }
        }

        delete $self->{STATE}{Chans}{ $uchan };
    }
    else {
        delete $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan };
        delete $self->{STATE}{Chans}{ $uchan }{Nicks}{ $unick };
        if ( keys %{ $self->{STATE}{Nicks}{ $unick }{CHANS} } <= 0 ) {
            delete $self->{STATE}{Nicks}{ $unick };
        }
    }

    return PCI_EAT_NONE;
}

sub S_nick {
    my $self = shift;
    $self->SUPER::S_nick(@_);
    shift @_;

    my $nick  = (split /!/, ${ $_[0] })[0];
    my $new   = ${ $_[1] };
    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);
    my $unew  = uc_irc($new, $map);

    push @{ $_[-1] }, [ $self->nick_channels( $nick ) ];

    if ($unick eq $unew) {
        # Case Change
        $self->{STATE}{Nicks}{ $unick }{Nick} = $new;
    }
    else {
        my $user = delete $self->{STATE}{Nicks}{ $unick };
        $user->{Nick} = $new;

        for my $channel ( keys %{ $user->{CHANS} } ) {
           $self->{STATE}{Chans}{ $channel }{Nicks}{ $unew } = $user->{CHANS}{ $channel };
           delete $self->{STATE}{Chans}{ $channel }{Nicks}{ $unick };
        }

        $self->{STATE}{Nicks}{ $unew } = $user;
    }

    return PCI_EAT_NONE;
}

sub S_chan_mode {
    my ($self, undef) = splice @_, 0, 2;
    pop @_;
    my $who  = ${ $_[0] };
    my $chan = ${ $_[1] };
    my $mode = ${ $_[2] };
    my $arg  = defined $_[3] ? ${ $_[3] } : '';
    my $map  = $self->isupport('CASEMAPPING');
    my $me   = uc_irc($self->nick_name(), $map);

    return PCI_EAT_NONE if $mode !~ /\+[qoah]/ || $me ne uc_irc($arg, $map);

    my $excepts = $self->isupport('EXCEPTS');
    my $invex = $self->isupport('INVEX');
    $self->yield(mode => $chan, $excepts ) if $excepts;
    $self->yield(mode => $chan, $invex ) if $invex;

    return PCI_EAT_NONE;
}

# RPL_UMODEIS
sub S_221 {
    my ($self, undef) = splice @_, 0, 2;
    my $mode = ${ $_[1] };
    $mode =~ s/^\+//;
    $self->{STATE}->{usermode} = $mode;
    return PCI_EAT_NONE;
}

# RPL_CHANNEL_URL
sub S_328 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan, $url) = @{ ${ $_[2] } };
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return PCI_EAT_NONE if !$self->_channel_exists($chan);
    $self->{STATE}{Chans}{ $uchan }{Url} = $url;
    return PCI_EAT_NONE;
}

# RPL_UNAWAY
sub S_305 {
    my ($self, undef) = splice @_, 0, 2;
    $self->{STATE}->{away} = 0;
    return PCI_EAT_NONE;
}

# RPL_NOWAWAY
sub S_306 {
    my ($self, undef) = splice @_, 0, 2;
    $self->{STATE}->{away} = 1;
    return PCI_EAT_NONE;
}

# this code needs refactoring
## no critic (Subroutines::ProhibitExcessComplexity ControlStructures::ProhibitCascadingIfElse)
sub S_mode {
    my ($self, undef) = splice @_, 0, 2;
    my $map   = $self->isupport('CASEMAPPING');
    my $who   = ${ $_[0] };
    my $chan  = ${ $_[1] };
    my $uchan = uc_irc($chan, $map);
    pop @_;
    my @modes = map { ${ $_ } } @_[2 .. $#_];

    # CHANMODES is [$list_mode, $always_arg, $arg_when_set, $no_arg]
    # A $list_mode always has an argument
    my $prefix = $self->isupport('PREFIX') || { o => '@', v => '+' };
    my $statmodes = join '', keys %{ $prefix };
    my $chanmodes = $self->isupport('CHANMODES') || [ qw(beI k l imnpstaqr) ];
    my $alwaysarg = join '', $statmodes,  @{ $chanmodes }[0 .. 1];

    # Do nothing if it is UMODE
    if ($uchan ne uc_irc($self->nick_name(), $map)) {
        my $parsed_mode = parse_mode_line( $prefix, $chanmodes, @modes );
        for my $mode (@{ $parsed_mode->{modes} }) {
            my $orig_arg;
            if (length $chanmodes->[2] && length $alwaysarg && $mode =~ /^(.[$alwaysarg]|\+[$chanmodes->[2]])/) {
                $orig_arg = shift @{ $parsed_mode->{args} };
            }

            my $flag;
            my $arg = $orig_arg;

            if (length $statmodes && (($flag) = $mode =~ /\+([$statmodes])/)) {
                $arg = uc_irc($arg, $map);
                if (!$self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan } || $self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan } !~ /$flag/) {
                    $self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan } .= $flag;
                    $self->{STATE}{Chans}{ $uchan }{Nicks}{ $arg } = $self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan };
                }
            }
            elsif (length $statmodes && (($flag) = $mode =~ /-([$statmodes])/)) {
                $arg = uc_irc($arg, $map);
                if ($self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan } =~ /$flag/) {
                    $self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan } =~ s/$flag//;
                    $self->{STATE}{Chans}{ $uchan }{Nicks}{ $arg } = $self->{STATE}{Nicks}{ $arg }{CHANS}{ $uchan };
                }
            }
            elsif (length $chanmodes->[0] && (($flag) = $mode =~ /\+([$chanmodes->[0]])/)) {
                $self->{STATE}{Chans}{ $uchan }{Lists}{ $flag }{ $arg } = {
                    SetBy => $who,
                    SetAt => time(),
                };
            }
            elsif (length $chanmodes->[0] && (($flag) = $mode =~ /-([$chanmodes->[0]])/)) {
                delete $self->{STATE}{Chans}{ $uchan }{Lists}{ $flag }{ $arg };
            }

            # All unhandled modes with arguments
            elsif (length $chanmodes->[3] && (($flag) = $mode =~ /\+([^$chanmodes->[3]])/)) {
                $self->{STATE}{Chans}{ $uchan }{Mode} .= $flag if $self->{STATE}{Chans}{ $uchan }{Mode} !~ /$flag/;
                $self->{STATE}{Chans}{ $uchan }{ModeArgs}{ $flag } = $arg;
            }
            elsif (length $chanmodes->[3] && (($flag) = $mode =~ /-([^$chanmodes->[3]])/)) {
                $self->{STATE}{Chans}{ $uchan }{Mode} =~ s/$flag//;
                delete $self->{STATE}{Chans}{ $uchan }{ModeArgs}{ $flag };
            }

            # Anything else doesn't have arguments so just adjust {Mode} as necessary.
            elsif (($flag) = $mode =~ /^\+(.)/ ) {
                $self->{STATE}{Chans}{ $uchan }{Mode} .= $flag if $self->{STATE}{Chans}{ $uchan }{Mode} !~ /$flag/;
            }
            elsif (($flag) = $mode =~ /^-(.)/ ) {
                $self->{STATE}{Chans}{ $uchan }{Mode} =~ s/$flag//;
            }
            $self->send_event_next(irc_chan_mode => $who, $chan, $mode, (defined $orig_arg ? $orig_arg : ()));
        }

        # Lets make the channel mode nice
        if ( $self->{STATE}{Chans}{ $uchan }{Mode} ) {
            $self->{STATE}{Chans}{ $uchan }{Mode} = join('', sort {uc $a cmp uc $b} ( split( //, $self->{STATE}{Chans}{ $uchan }{Mode} ) ) );
        }
    }
    else {
        my $parsed_mode = parse_mode_line( @modes );
        for my $mode (@{ $parsed_mode->{modes} }) {
            my $flag;
            if ( ($flag) = $mode =~ /^\+(.)/ ) {
                $self->{STATE}{usermode} .= $flag if $self->{STATE}{usermode} !~ /$flag/;
            }
            elsif ( ($flag) = $mode =~ /^-(.)/ ) {
                $self->{STATE}{usermode} =~ s/$flag//;
            }
            $self->send_event_next(irc_user_mode => $who, $chan, $mode );
        }
    }

    return PCI_EAT_NONE;
}

sub S_topic {
    my ($self, undef) = splice @_, 0, 2;
    my $who   = ${ $_[0] };
    my $chan  = ${ $_[1] };
    my $topic = ${ $_[2] };
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    push @{ $_[-1] }, $self->{STATE}{Chans}{$uchan}{Topic};

    $self->{STATE}{Chans}{ $uchan }{Topic} = {
        Value => $topic,
        SetBy => $who,
        SetAt => time(),
    };

    return PCI_EAT_NONE;
}

# RPL_NAMES
sub S_353 {
    my ($self, undef) = splice @_, 0, 2;
    my @data   = @{ ${ $_[2] } };
    shift @data if $data[0] =~ /^[@=*]$/;
    my $chan   = shift @data;
    my @nicks  = split /\s+/, shift @data;
    my $map    = $self->isupport('CASEMAPPING');
    my $uchan  = uc_irc($chan, $map);
    my $prefix = $self->isupport('PREFIX') || { o => '@', v => '+' };
    my $search = join '|', map { quotemeta } values %$prefix;
    $search    = qr/(?:$search)/;

    for my $nick (@nicks) {
        my $status;
        if ( ($status) = $nick =~ /^($search+)/ ) {
           $nick =~ s/^($search+)//;
        }

        my ($user, $host);
        if ($self->isupport('UHNAMES')) {
            ($nick, $user, $host) = split /[!@]/, $nick;
        }

        my $unick    = uc_irc($nick, $map);
        $status      = '' if !defined $status;
        my $whatever = '';
        my $existing = $self->{STATE}{Nicks}{$unick}{CHANS}{$uchan} || '';

        for my $mode (keys %$prefix) {
            if ($status =~ /\Q$prefix->{$mode}/ && $existing !~ /\Q$prefix->{$mode}/) {
                $whatever .= $mode;
            }
        }

        $existing .= $whatever if !length $existing || $existing !~ /$whatever/;
        $self->{STATE}{Nicks}{$unick}{CHANS}{$uchan} = $existing;
        $self->{STATE}{Chans}{$uchan}{Nicks}{$unick} = $existing;
        $self->{STATE}{Nicks}{$unick}{Nick} = $nick;
        if ($self->isupport('UHNAMES')) {
            $self->{STATE}{Nicks}{$unick}{User} = $user;
            $self->{STATE}{Nicks}{$unick}{Host} = $host;
        }
    }
    return PCI_EAT_NONE;
}

# RPL_WHOREPLY
sub S_352 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan, $user, $host, $server, $nick, $status, $rest) = @{ ${ $_[2] } };
    my ($hops, $real) = split /\x20/, $rest, 2;
    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);
    my $uchan = uc_irc($chan, $map);

    $self->{STATE}{Nicks}{ $unick }{Nick} = $nick;
    $self->{STATE}{Nicks}{ $unick }{User} = $user;
    $self->{STATE}{Nicks}{ $unick }{Host} = $host;

    if ( !exists $self->{whojoiners} || $self->{whojoiners} ) {
        $self->{STATE}{Nicks}{ $unick }{Hops} = $hops;
        $self->{STATE}{Nicks}{ $unick }{Real} = $real;
        $self->{STATE}{Nicks}{ $unick }{Server} = $server;
        $self->{STATE}{Nicks}{ $unick }{IRCop} = 1 if $status =~ /\*/;
    }

    if ( exists $self->{STATE}{Chans}{ $uchan } ) {
        my $whatever = '';
        my $existing = $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan } || '';
        my $prefix = $self->isupport('PREFIX') || { o => '@', v => '+' };

        for my $mode ( keys %{ $prefix } ) {
            if ($status =~ /\Q$prefix->{$mode}/ && $existing !~ /\Q$prefix->{$mode}/ ) {
                $whatever .= $mode;
            }
        }

        $existing .= $whatever if !$existing || $existing !~ /$whatever/;
        $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan } = $existing;
        $self->{STATE}{Chans}{ $uchan }{Nicks}{ $unick } = $existing;
        $self->{STATE}{Chans}{ $uchan }{Name} = $chan;

        if ($self->{STATE}{Chans}{ $uchan }{AWAY_SYNCH} && $unick ne uc_irc($self->nick_name(), $map)) {
            if ( $status =~ /G/ && !$self->{STATE}{Nicks}{ $unick }{Away} ) {
                $self->send_event_next(irc_user_away => $nick, [ $self->nick_channels( $nick ) ] );
            }
            elsif ($status =~ /H/ && $self->{STATE}{Nicks}{ $unick }{Away} ) {
                $self->send_event_next(irc_user_back => $nick, [ $self->nick_channels( $nick ) ] );
            }
        }

        if ($self->{awaypoll}) {
            $self->{STATE}{Nicks}{ $unick }{Away} = $status =~ /G/ ? 1 : 0;
        }
    }

    return PCI_EAT_NONE;
}

# RPL_ENDOFWHO
sub S_315 {
    my ($self, undef) = splice @_, 0, 2;
    my $what  = ${ $_[2] }->[0];
    my $map   = $self->isupport('CASEMAPPING');
    my $uwhat = uc_irc($what, $map);

    if ( exists $self->{STATE}{Chans}{ $uwhat } ) {
        my $chan = $what; my $uchan = $uwhat;
        if ( $self->_channel_sync($chan, 'WHO') ) {
            my $rec = delete $self->{CHANNEL_SYNCH}{ $uchan };
            $self->send_event_next(irc_chan_sync => $chan, time() - $rec->{_time} );
        }
        elsif ( $self->{STATE}{Chans}{ $uchan }{AWAY_SYNCH} ) {
            $self->{STATE}{Chans}{ $uchan }{AWAY_SYNCH} = 0;
            $poe_kernel->delay_add(_away_sync => $self->{awaypoll} => $chan );
            $self->send_event_next(irc_away_sync_end => $chan );
        }
    }
    else {
        my $nick = $what; my $unick = $uwhat;
        my $chan = shift @{ $self->{NICK_SYNCH}{ $unick } };
        delete $self->{NICK_SYNCH}{ $unick } if !@{ $self->{NICK_SYNCH}{ $unick } };
        $self->send_event_next(irc_nick_sync => $nick, $chan );
    }

    return PCI_EAT_NONE;
}

# RPL_CREATIONTIME
sub S_329 {
    my ($self, undef) = splice @_, 0, 2;
    my $map   = $self->isupport('CASEMAPPING');
    my $chan  = ${ $_[2] }->[0];
    my $time  = ${ $_[2] }->[1];
    my $uchan = uc_irc($chan, $map);

    $self->{STATE}->{Chans}{ $uchan }{CreationTime} = $time;
    return PCI_EAT_NONE;
}

# RPL_BANLIST
sub S_367 {
    my ($self, undef) = splice @_, 0, 2;
    my @args  = @{ ${ $_[2] } };
    my $chan  = shift @args;
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my ($mask, $who, $when) = @args;

    $self->{STATE}{Chans}{ $uchan }{Lists}{b}{ $mask } = {
        SetBy => $who,
        SetAt => $when,
    };
    return PCI_EAT_NONE;
}

# RPL_ENDOFBANLIST
sub S_368 {
    my ($self, undef) = splice @_, 0, 2;
    my @args  = @{ ${ $_[2] } };
    my $chan  = shift @args;
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    if ($self->_channel_sync($chan, 'BAN')) {
        my $rec = delete $self->{CHANNEL_SYNCH}{ $uchan };
        $self->send_event_next(irc_chan_sync => $chan, time() - $rec->{_time} );
    }

    return PCI_EAT_NONE;
}

# RPL_INVITELIST
sub S_346 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan, $mask, $who, $when) = @{ ${ $_[2] } };
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my $invex = $self->isupport('INVEX');

    $self->{STATE}{Chans}{ $uchan }{Lists}{ $invex }{ $mask } = {
        SetBy => $who,
        SetAt => $when
    };

    return PCI_EAT_NONE;
}

# RPL_ENDOFINVITELIST
sub S_347 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan) = @{ ${ $_[2] } };
    my $map    = $self->isupport('CASEMAPPING');
    my $uchan  = uc_irc($chan, $map);

    $self->send_event_next(irc_chan_sync_invex => $chan);
    return PCI_EAT_NONE;
}

# RPL_EXCEPTLIST
sub S_348 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan, $mask, $who, $when) = @{ ${ $_[2] } };
    my $map     = $self->isupport('CASEMAPPING');
    my $uchan   = uc_irc($chan, $map);
    my $excepts = $self->isupport('EXCEPTS');

    $self->{STATE}{Chans}{ $uchan }{Lists}{ $excepts }{ $mask } = {
        SetBy => $who,
        SetAt => $when,
    };
    return PCI_EAT_NONE;
}

# RPL_ENDOFEXCEPTLIST
sub S_349 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan) = @{ ${ $_[2] } };
    my $map    = $self->isupport('CASEMAPPING');
    my $uchan  = uc_irc($chan, $map);

    $self->send_event_next(irc_chan_sync_excepts => $chan);
    return PCI_EAT_NONE;
}

# RPL_CHANNELMODEIS
sub S_324 {
    my ($self, undef) = splice @_, 0, 2;
    my @args  = @{ ${ $_[2] } };
    my $chan  = shift @args;
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my $modes = $self->isupport('CHANMODES') || [ qw(beI k l imnpstaqr) ];
    my $prefix = $self->isupport('PREFIX') || { o => '@', v => '+' };

    my $parsed_mode = parse_mode_line($prefix, $modes, @args);
    for my $mode (@{ $parsed_mode->{modes} }) {
        $mode =~ s/\+//;
        my $arg = '';
        if ($mode =~ /[^$modes->[3]]/) {
            # doesn't match a mode with no args
            $arg = shift @{ $parsed_mode->{args} };
        }

        if ( $self->{STATE}{Chans}{ $uchan }{Mode} ) {
            $self->{STATE}{Chans}{ $uchan }{Mode} .= $mode if $self->{STATE}{Chans}{ $uchan }{Mode} !~ /$mode/;
        }
        else {
            $self->{STATE}{Chans}{ $uchan }{Mode} = $mode;
        }

        $self->{STATE}{Chans}{ $uchan }{ModeArgs}{ $mode } = $arg if defined ( $arg );
    }

    if ( $self->{STATE}{Chans}{ $uchan }{Mode} ) {
        $self->{STATE}{Chans}{ $uchan }{Mode} = join('', sort {uc $a cmp uc $b} split //, $self->{STATE}{Chans}{ $uchan }{Mode} );
    }

    if ( $self->_channel_sync($chan, 'MODE') ) {
        my $rec = delete $self->{CHANNEL_SYNCH}{ $uchan };
        $self->send_event_next(irc_chan_sync => $chan, time() - $rec->{_time} );
    }

    return PCI_EAT_NONE;
}

# RPL_TOPIC
sub S_332 {
    my ($self, undef) = splice @_, 0, 2;
    my $chan  = ${ $_[2] }->[0];
    my $topic = ${ $_[2] }->[1];
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    $self->{STATE}{Chans}{ $uchan }{Topic}{Value} = $topic;
    return PCI_EAT_NONE;
}

# RPL_TOPICWHOTIME
sub S_333 {
    my ($self, undef) = splice @_, 0, 2;
    my ($chan, $who, $when) = @{ ${ $_[2] } };
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    $self->{STATE}{Chans}{ $uchan }{Topic}{SetBy} = $who;
    $self->{STATE}{Chans}{ $uchan }{Topic}{SetAt} = $when;

    return PCI_EAT_NONE;
}

# Methods for STATE query
# Internal methods begin with '_'
#

sub umode {
    my ($self) = @_;
    return $self->{STATE}{usermode};
}

sub is_user_mode_set {
    my ($self, $mode) = @_;

    if (!defined $mode) {
        warn 'User mode is undefined';
        return;
    }

    $mode = (split //, $mode)[0] || return;
    $mode =~ s/[^A-Za-z]//g;
    return if !$mode;

    return 1 if $self->{STATE}{usermode} =~ /$mode/;
    return;
}

sub _away_sync {
    my ($self, $chan) = @_[OBJECT, ARG0];
    my $map = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    $self->{STATE}{Chans}{ $uchan }{AWAY_SYNCH} = 1;
    $self->yield(who => $chan);
    $self->send_event(irc_away_sync_start => $chan);

    return;
}

sub _channel_sync {
    my ($self, $chan, $sync) = @_;
    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return if !$self->_channel_exists($chan) || !defined $self->{CHANNEL_SYNCH}{ $uchan };
    $self->{CHANNEL_SYNCH}{ $uchan }{ $sync } = 1 if $sync;

    for my $item ( qw(BAN MODE WHO) ) {
        return if !$self->{CHANNEL_SYNCH}{ $uchan }{ $item };
    }

    return 1;
}

sub _nick_exists {
    my ($self, $nick) = @_;
    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);

    return 1 if exists $self->{STATE}{Nicks}{ $unick };
    return;
}

sub _channel_exists {
    my ($self, $chan) = @_;
    my $map = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return 1 if exists $self->{STATE}{Chans}{ $uchan };
    return;
}

sub _nick_has_channel_mode {
    my ($self, $chan, $nick, $flag) = @_;
    my $map = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my $unick = uc_irc($nick, $map);
    $flag = (split //, $flag)[0];

    return if !$self->is_channel_member($uchan, $unick);
    return 1 if $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan } =~ /$flag/;
    return;
}

# Returns all the channels that the bot is on with an indication of
# whether it has operator, halfop or voice.
sub channels {
    my ($self) = @_;
    my $map    = $self->isupport('CASEMAPPING');
    my $unick  = uc_irc($self->nick_name(), $map);

    my %result;
    if (defined $unick && $self->_nick_exists($unick)) {
        for my $uchan ( keys %{ $self->{STATE}{Nicks}{ $unick }{CHANS} } ) {
            $result{ $self->{STATE}{Chans}{ $uchan }{Name} } = $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan };
        }
    }

    return \%result;
}

sub nicks {
    my ($self) = @_;
    return map { $self->{STATE}{Nicks}{$_}{Nick} } keys %{ $self->{STATE}{Nicks} };
}

sub nick_info {
    my ($self, $nick) = @_;

    if (!defined $nick) {
        warn 'Nickname is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);

    return if !$self->_nick_exists($nick);

    my $user = $self->{STATE}{Nicks}{ $unick };
    my %result = %{ $user };

    # maybe we haven't synced this user's info yet
    if (defined $result{User} && defined $result{Host}) {
        $result{Userhost} = "$result{User}\@$result{Host}";
    }
    delete $result{'CHANS'};

    return \%result;
}

sub nick_long_form {
    my ($self, $nick) = @_;

    if (!defined $nick) {
        warn 'Nickname is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);

    return if !$self->_nick_exists($nick);

    my $user = $self->{STATE}{Nicks}{ $unick };
    return unless exists $user->{User} && exists $user->{Host};
    return "$user->{Nick}!$user->{User}\@$user->{Host}";
}

sub nick_channels {
    my ($self, $nick) = @_;

    if (!defined $nick) {
        warn 'Nickname is undefined';
        return;
    }
    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);

    return if !$self->_nick_exists($nick);
    return map { $self->{STATE}{Chans}{$_}{Name} } keys %{ $self->{STATE}{Nicks}{ $unick }{CHANS} };
}

sub channel_list {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return if !$self->_channel_exists($chan);
    return map { $self->{STATE}{Nicks}{$_}{Nick} } keys %{ $self->{STATE}{Chans}{ $uchan }{Nicks} };
}

sub is_away {
    my ($self, $nick) = @_;

    if (!defined $nick) {
        warn 'Nickname is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);

    if ($unick eq uc_irc($self->nick_name())) {
        # more accurate
        return 1 if $self->{STATE}{away};
        return;
    }

    return if !$self->_nick_exists($nick);
    return 1 if $self->{STATE}{Nicks}{ $unick }{Away};
    return;
}

sub is_operator {
    my ($self, $nick) = @_;

    if (!defined $nick) {
        warn 'Nickname is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $unick = uc_irc($nick, $map);

    return if !$self->_nick_exists($nick);

    return 1 if $self->{STATE}{Nicks}{ $unick }{IRCop};
    return;
}

sub is_channel_mode_set {
    my ($self, $chan, $mode) = @_;

    if (!defined $chan || !defined $mode) {
        warn 'Channel or mode is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    $mode = (split //, $mode)[0];

    return if !$self->_channel_exists($chan) || !$mode;
    $mode =~ s/[^A-Za-z]//g;

    if (defined $self->{STATE}{Chans}{ $uchan }{Mode}
        && $self->{STATE}{Chans}{ $uchan }{Mode} =~ /$mode/) {
        return 1;
    }

    return;
}

sub is_channel_synced {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    return $self->_channel_sync($chan);
}

sub channel_creation_time {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return if !$self->_channel_exists($chan);
    return if !exists $self->{STATE}{Chans}{ $uchan }{CreationTime};

    return $self->{STATE}{Chans}{ $uchan }{CreationTime};
}

sub channel_limit {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return if !$self->_channel_exists($chan);

    if ( $self->is_channel_mode_set($chan, 'l')
        && defined $self->{STATE}{Chans}{ $uchan }{ModeArgs}{l} ) {
        return $self->{STATE}{Chans}{ $uchan }{ModeArgs}{l};
    }

    return;
}

sub channel_key {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    return if !$self->_channel_exists($chan);

    if ( $self->is_channel_mode_set($chan, 'k')
        && defined $self->{STATE}{Chans}{ $uchan }{ModeArgs}{k} ) {
        return $self->{STATE}{Chans}{ $uchan }{ModeArgs}{k};
    }

    return;
}

sub channel_modes {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    return if !$self->_channel_exists($chan);

    my %modes;
    if ( defined $self->{STATE}{Chans}{ $uchan }{Mode} ) {
        %modes = map { ($_ => '') } split(//, $self->{STATE}{Chans}{ $uchan }{Mode});
    }
    if ( defined $self->{STATE}{Chans}{ $uchan }->{ModeArgs} ) {
        my %args = %{ $self->{STATE}{Chans}{ $uchan }{ModeArgs} };
        @modes{keys %args} = values %args;
    }

    return \%modes;
}

sub is_channel_member {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nickname is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my $unick = uc_irc($nick, $map);

    return if !$self->_channel_exists($chan) || !$self->_nick_exists($nick);
    return 1 if defined $self->{STATE}{Chans}{ $uchan }{Nicks}{ $unick };
    return;
}

sub is_channel_operator {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nickname is undefined';
        return;
    }

    return 1 if $self->_nick_has_channel_mode($chan, $nick, 'o');
    return;
}

sub has_channel_voice {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nickname is undefined';
        return;
    }

    return 1 if $self->_nick_has_channel_mode($chan, $nick, 'v');
    return;
}

sub is_channel_halfop {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nickname is undefined';
        return;
    }

    return 1 if $self->_nick_has_channel_mode($chan, $nick, 'h');
    return;
}

sub is_channel_owner {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nickname is undefined';
        return;
    }

    return 1 if $self->_nick_has_channel_mode($chan, $nick, 'q');
    return;
}

sub is_channel_admin {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nickname is undefined';
        return;
    }

    return 1 if $self->_nick_has_channel_mode($chan, $nick, 'a');
    return;
}

sub ban_mask {
    my ($self, $chan, $mask) = @_;

    if (!defined $chan || !defined $mask) {
        warn 'Channel or mask is undefined';
        return;
    }

    my $map = $self->isupport('CASEMAPPING');
    $mask = normalize_mask($mask);
    my @result;

    return if !$self->_channel_exists($chan);

    # Convert the mask from IRC to regex.
    $mask = uc_irc($mask, $map);
    $mask = quotemeta $mask;
    $mask =~ s/\\\*/[\x01-\xFF]{0,}/g;
    $mask =~ s/\\\?/[\x01-\xFF]{1,1}/g;

    for my $nick ( $self->channel_list($chan) ) {
        push @result, $nick if uc_irc($self->nick_long_form($nick)) =~ /^$mask$/;
    }

    return @result;
}


sub channel_ban_list {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my %result;

    return if !$self->_channel_exists($chan);

    if ( defined $self->{STATE}{Chans}{ $uchan }{Lists}{b} ) {
        %result = %{ $self->{STATE}{Chans}{ $uchan }{Lists}{b} };
    }

    return \%result;
}

sub channel_except_list {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map     = $self->isupport('CASEMAPPING');
    my $uchan   = uc_irc($chan, $map);
    my $excepts = $self->isupport('EXCEPTS');
    my %result;

    return if !$self->_channel_exists($chan);

    if ( defined $self->{STATE}{Chans}{ $uchan }{Lists}{ $excepts } ) {
        %result = %{ $self->{STATE}{Chans}{ $uchan }{Lists}{ $excepts } };
    }

    return \%result;
}

sub channel_invex_list {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my $invex = $self->isupport('INVEX');
    my %result;

    return if !$self->_channel_exists($chan);

    if ( defined $self->{STATE}{Chans}{ $uchan }{Lists}{ $invex } ) {
        %result = %{ $self->{STATE}{Chans}{ $uchan }{Lists}{ $invex } };
    }

    return \%result;
}

sub channel_topic {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my %result;

    return if !$self->_channel_exists($chan);

    if ( defined $self->{STATE}{Chans}{ $uchan }{Topic} ) {
        %result = %{ $self->{STATE}{Chans}{ $uchan }{Topic} };
    }

    return \%result;
}

sub channel_url {
    my ($self, $chan) = @_;

    if (!defined $chan) {
        warn 'Channel is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);

    return if !$self->_channel_exists($chan);
    return $self->{STATE}{Chans}{ $uchan }{Url};
}

sub nick_channel_modes {
    my ($self, $chan, $nick) = @_;

    if (!defined $chan || !defined $nick) {
        warn 'Channel or nick is undefined';
        return;
    }

    my $map   = $self->isupport('CASEMAPPING');
    my $uchan = uc_irc($chan, $map);
    my $unick = uc_irc($nick, $map);

    return if !$self->is_channel_member($chan, $nick);

    return $self->{STATE}{Nicks}{ $unick }{CHANS}{ $uchan };
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::State - A fully event-driven IRC client module with
nickname and channel tracking

=head1 SYNOPSIS

 # A simple Rot13 'encryption' bot

 use strict;
 use warnings;
 use POE qw(Component::IRC::State);

 my $nickname = 'Flibble' . $$;
 my $ircname = 'Flibble the Sailor Bot';
 my $ircserver = 'irc.blahblahblah.irc';
 my $port = 6667;

 my @channels = ( '#Blah', '#Foo', '#Bar' );

 # We create a new PoCo-IRC object and component.
 my $irc = POE::Component::IRC::State->spawn(
     nick => $nickname,
     server => $ircserver,
     port => $port,
     ircname => $ircname,
 ) or die "Oh noooo! $!";

 POE::Session->create(
     package_states => [
         main => [ qw(_default _start irc_001 irc_public) ],
     ],
     heap => { irc => $irc },
 );

 $poe_kernel->run();

 sub _start {
     my ($kernel, $heap) = @_[KERNEL, HEAP];

     # We get the session ID of the component from the object
     # and register and connect to the specified server.
     my $irc_session = $heap->{irc}->session_id();
     $kernel->post( $irc_session => register => 'all' );
     $kernel->post( $irc_session => connect => { } );
     return;
 }

 sub irc_001 {
     my ($kernel, $sender) = @_[KERNEL, SENDER];

     # Get the component's object at any time by accessing the heap of
     # the SENDER
     my $poco_object = $sender->get_heap();
     print "Connected to ", $poco_object->server_name(), "\n";

     # In any irc_* events SENDER will be the PoCo-IRC session
     $kernel->post( $sender => join => $_ ) for @channels;
     return;
 }

 sub irc_public {
     my ($kernel ,$sender, $who, $where, $what) = @_[KERNEL, SENDER, ARG0 .. ARG2];
     my $nick = ( split /!/, $who )[0];
     my $channel = $where->[0];
     my $poco_object = $sender->get_heap();

     if ( my ($rot13) = $what =~ /^rot13 (.+)/ ) {
         # Only operators can issue a rot13 command to us.
         return if !$poco_object->is_channel_operator( $channel, $nick );

         $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];
         $kernel->post( $sender => privmsg => $channel => "$nick: $rot13" );
     }
     return;
 }

 # We registered for all events, this will produce some debug info.
 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     my @output = ( "$event: " );

     for my $arg ( @$args ) {
         if (ref $arg  eq 'ARRAY') {
             push( @output, '[' . join(', ', @$arg ) . ']' );
         }
         else {
             push ( @output, "'$arg'" );
         }
     }
     print join ' ', @output, "\n";
     return 0;
 }

=head1 DESCRIPTION

POE::Component::IRC::State is a sub-class of L<POE::Component::IRC|POE::Component::IRC>
which tracks IRC state entities such as nicks and channels. See the
documentation for L<POE::Component::IRC|POE::Component::IRC> for general usage.
This document covers the extra methods that POE::Component::IRC::State provides.

The component tracks channels and nicks, so that it always has a current
snapshot of what channels it is on and who else is on those channels. The
returned object provides methods to query the collected state.

=head1 CONSTRUCTORS

POE::Component::IRC::State's constructors, and its C<connect> event, all
take the same arguments as L<POE::Component::IRC|POE::Component::IRC> does, as
well as two additional ones:

B<'AwayPoll'>, the interval (in seconds) in which to poll (i.e. C<WHO #channel>)
the away status of channel members. Defaults to 0 (disabled). If enabled, you
will receive C<irc_away_sync_*> / L<C<irc_user_away>|/irc_user_away> /
L<C<irc_user_back>|/irc_user_back> events, and will be able to use the
L<C<is_away>|/is_away> method for users other than yourself. This can cause
a lot of increase in traffic, especially if you are on big channels, so if you
do use this, you probably don't want to set it too low. For reference, X-Chat
uses 300 seconds (5 minutes).

B<'WhoJoiners'>, a boolean indicating whether the component should send a
C<WHO nick> for every person which joins a channel. Defaults to on
(the C<WHO> is sent). If you turn this off, L<C<is_operator>|/is_operator>
will not work and L<C<nick_info>|/nick_info> will only return the keys
B<'Nick'>, B<'User'>, B<'Host'> and B<'Userhost'>.

=head1 METHODS

All of the L<POE::Component::IRC|POE::Component::IRC> methods are supported,
plus the following:

=head2 C<ban_mask>

Expects a channel and a ban mask, as passed to MODE +b-b. Returns a list of
nicks on that channel that match the specified ban mask or an empty list if
the channel doesn't exist in the state or there are no matches.

=head2 C<channel_ban_list>

Expects a channel as a parameter. Returns a hashref containing the banlist
if the channel is in the state, a false value if not. The hashref keys are the
entries on the list, each with the keys B<'SetBy'> and B<'SetAt'>. These keys
will hold the nick!hostmask of the user who set the entry (or just the nick
if it's all the ircd gives us), and the time at which it was set respectively.

=head2 C<channel_creation_time>

Expects a channel as parameter. Returns channel creation time or a false value.

=head2 C<channel_except_list>

Expects a channel as a parameter. Returns a hashref containing the ban
exception list if the channel is in the state, a false value if not. The
hashref keys are the entries on the list, each with the keys B<'SetBy'> and
B<'SetAt'>. These keys will hold the nick!hostmask of the user who set the
entry (or just the nick if it's all the ircd gives us), and the time at which
it was set respectively.

=head2 C<channel_invex_list>

Expects a channel as a parameter. Returns a hashref containing the invite
exception list if the channel is in the state, a false value if not. The
hashref keys are the entries on the list, each with the keys B<'SetBy'> and
B<'SetAt'>. These keys will hold the nick!hostmask of the user who set the
entry (or just the nick if it's all the ircd gives us), and the time at which
it was set respectively.

=head2 C<channel_key>

Expects a channel as parameter. Returns the channel key or a false value.

=head2 C<channel_limit>

Expects a channel as parameter. Returns the channel limit or a false value.

=head2 C<channel_list>

Expects a channel as parameter. Returns a list of all nicks on the specified
channel. If the component happens to not be on that channel an empty list will
be returned.

=head2 C<channel_modes>

Expects a channel as parameter. Returns a hash ref keyed on channel mode, with
the mode argument (if any) as the value. Returns a false value instead if the
channel is not in the state.

=head2 C<channels>

Takes no parameters. Returns a hashref, keyed on channel name and whether the
bot is operator, halfop or
has voice on that channel.

 for my $channel ( keys %{ $irc->channels() } ) {
     $irc->yield( 'privmsg' => $channel => 'm00!' );
 }

=head2 C<channel_topic>

Expects a channel as a parameter. Returns a hashref containing topic
information if the channel is in the state, a false value if not. The hashref
contains the following keys: B<'Value'>, B<'SetBy'>, B<'SetAt'>. These keys
will hold the topic itself, the nick!hostmask of the user who set it (or just
the nick if it's all the ircd gives us), and the time at which it was set
respectively.

If the component happens to not be on the channel, nothing will be returned.

=head2 C<channel_url>

Expects a channel as a parameter. Returns the channel's URL. If the channel
has no URL or the component is not on the channel, nothing will be returned.

=head2 C<has_channel_voice>

Expects a channel and a nickname as parameters. Returns a true value if
the nick has voice on the specified channel. Returns false if the nick does
not have voice on the channel or if the nick/channel does not exist in the state.

=head2 C<is_away>

Expects a nick as parameter. Returns a true value if the specified nick is away.
Returns a false value if the nick is not away or not in the state. This will
only work for your IRC user unless you specified a value for B<'AwayPoll'> in
L<C<spawn>|POE::Component::IRC/spawn>.

=head2 C<is_channel_admin>

Expects a channel and a nickname as parameters. Returns a true value if
the nick is an admin on the specified channel. Returns false if the nick is
not an admin on the channel or if the nick/channel does not exist in the state.

=head2 C<is_channel_halfop>

Expects a channel and a nickname as parameters. Returns a true value if
the nick is a half-operator on the specified channel. Returns false if the nick
is not a half-operator on the channel or if the nick/channel does not exist in
the state.

=head2 C<is_channel_member>

Expects a channel and a nickname as parameters. Returns a true value if
the nick is on the specified channel. Returns false if the nick is not on the
channel or if the nick/channel does not exist in the state.

=head2 C<is_channel_mode_set>

Expects a channel and a single mode flag C<[A-Za-z]>. Returns a true value
if that mode is set on the channel.

=head2 C<is_channel_operator>

Expects a channel and a nickname as parameters. Returns a true value if
the nick is an operator on the specified channel. Returns false if the nick is
not an operator on the channel or if the nick/channel does not exist in the state.

=head2 C<is_channel_owner>

Expects a channel and a nickname as parameters. Returns a true value if
the nick is an owner on the specified channel. Returns false if the nick is
not an owner on the channel or if the nick/channel does not exist in the state.

=head2 C<is_channel_synced>

Expects a channel as a parameter. Returns true if the channel has been synced.
Returns false if it has not been synced or if the channel is not in the state.

=head2 C<is_operator>

Expects a nick as parameter. Returns a true value if the specified nick is
an IRC operator. Returns a false value if the nick is not an IRC operator
or is not in the state.

=head2 C<is_user_mode_set>

Expects single user mode flag C<[A-Za-z]>. Returns a true value if that user
mode is set.

=head2 C<nick_channel_modes>

Expects a channel and a nickname as parameters. Returns the modes of the
specified nick on the specified channel (ie. qaohv). If the nick is not on the
channel in the state, a false value will be returned.

=head2 C<nick_channels>

Expects a nickname. Returns a list of the channels that that nickname and the
component are on. An empty list will be returned if the nickname does not
exist in the state.

=head2 C<nick_info>

Expects a nickname. Returns a hashref containing similar information to that
returned by WHOIS. Returns a false value if the nickname doesn't exist in the
state. The hashref contains the following keys:

B<'Nick'>, B<'User'>, B<'Host'>, B<'Userhost'>, B<'Hops'>, B<'Real'>,
B<'Server'> and, if applicable, B<'IRCop'>.

=head2 C<nick_long_form>

Expects a nickname. Returns the long form of that nickname, ie. C<nick!user@host>
or a false value if the nick is not in the state.

=head2 C<nicks>

Takes no parameters. Returns a list of all the nicks, including itself, that it
knows about. If the component happens to be on no channels then an empty list
is returned.

=head2 C<umode>

Takes no parameters. Returns the current user mode set for the bot.

=head1 OUTPUT EVENTS

=head2 Augmented events

New parameters are added to the following
L<POE::Component::IRC|POE::Component::IRC> events.

=head3 C<irc_quit>

See also L<C<irc_quit>|POE::Component::IRC/irc_quit> in
L<POE::Component::IRC|POE::Component::IRC>.

Additional parameter C<ARG2> contains an arrayref of channel names that are
common to the quitting client and the component.

=head3 C<irc_nick>

See also L<C<irc_nick>|POE::Component::IRC/irc_nick> in
L<POE::Component::IRC|POE::Component::IRC>.

Additional parameter C<ARG2> contains an arrayref of channel names that are
common to the nick hanging client and the component.

=head3 C<irc_kick>

See also L<C<irc_kick>|POE::Component::IRC/irc_kick> in
L<POE::Component::IRC|POE::Component::IRC>.

Additional parameter C<ARG4> contains the full nick!user@host of the kicked
individual.

=head3 C<irc_topic>

See also L<C<irc_kick>|POE::Component::IRC/irc_kick> in
L<POE::Component::IRC|POE::Component::IRC>.

Additional parameter C<ARG3> contains the old topic hashref, like the one
returned by L<C<channel_topic>|/channel_topic>.

=head3 C<irc_disconnected>

=head3 C<irc_error>

=head3 C<irc_socketerr>

These three all have two additional parameters. C<ARG1> is a hash of
information about your IRC user (see L<C<nick_info>|/nick_info>), while
C<ARG2> is a hash of the channels you were on (see
L<C<channels>|/channels>).

=head2 New events

As well as all the usual L<POE::Component::IRC|POE::Component::IRC> C<irc_*>
events, there are the following events you can register for:

=head3 C<irc_away_sync_start>

Sent whenever the component starts to synchronise the away statuses of channel
members. C<ARG0> is the channel name. You will only receive this event if you
specified a value for B<'AwayPoll'> in L<C<spawn>|POE::Component::IRC/spawn>.

=head3 C<irc_away_sync_end>

Sent whenever the component has completed synchronising the away statuses of
channel members. C<ARG0> is the channel name. You will only receive this event if
you specified a value for B<'AwayPoll'> in L<C<spawn>|POE::Component::IRC/spawn>.

=head3 C<irc_chan_mode>

This is almost identical to L<C<irc_mode>|POE::Component::IRC/irc_mode>,
except that it's sent once for each individual mode with it's respective
argument if it has one (ie. the banmask if it's +b or -b). However, this
event is only sent for channel modes.

=head3 C<irc_chan_sync>

Sent whenever the component has completed synchronising a channel that it has
joined. C<ARG0> is the channel name and C<ARG1> is the time in seconds that
the channel took to synchronise.

=head3 C<irc_chan_sync_invex>

Sent whenever the component has completed synchronising a channel's INVEX
(invite list). Usually triggered by the component being opped on a channel.
C<ARG0> is the channel name.

=head3 C<irc_chan_sync_excepts>

Sent whenever the component has completed synchronising a channel's EXCEPTS
(ban exemption list). Usually triggered by the component being opped on a
channel. C<ARG0> is the channel.

=head3 C<irc_nick_sync>

Sent whenever the component has completed synchronising a user who has joined
a channel the component is on. C<ARG0> is the user's nickname and C<ARG1> the
channel they have joined.

=head3 C<irc_user_away>

Sent when an IRC user sets his/her status to away. C<ARG0> is the nickname,
C<ARG1> is an arrayref of channel names that are common to the nickname
and the component. You will only receive this event if you specified a value
for B<'AwayPoll'> in L<C<spawn>|POE::Component::IRC/spawn>.

B<Note:> This above is only for users I<other than yourself>. To know when you
change your own away status, register for the C<irc_305> and C<irc_306> events.

=head3 C<irc_user_back>

Sent when an IRC user unsets his/her away status. C<ARG0> is the nickname,
C<ARG1> is an arrayref of channel names that are common to the nickname and
the component. You will only receive this event if you specified a value for
B<'AwayPoll'> in L<C<spawn>|POE::Component::IRC/spawn>.

B<Note:> This above is only for users I<other than yourself>. To know when you
change your own away status, register for the C<irc_305> and C<irc_306> events.

=head3 C<irc_user_mode>

This is almost identical to L<C<irc_mode>|POE::Component::IRC/irc_mode>,
except it is sent for each individual umode that is being set.

=head1 CAVEATS

The component gathers information by registering for C<irc_quit>, C<irc_nick>,
C<irc_join>, C<irc_part>, C<irc_mode>, C<irc_kick> and various numeric replies.
When the component is asked to join a channel, when it joins it will issue
'WHO #channel', 'MODE #channel', and 'MODE #channel b'. These will solicit
between them the numerics, C<irc_352>, C<irc_324> and C<irc_329>, respectively.
When someone joins a channel the bot is on, it issues a 'WHO nick'. You may
want to ignore these.

Currently, whenever the component sees a topic or channel list change, it will
use C<time> for the SetAt value and the full address of the user who set it
for the SetBy value. When an ircd gives us its record of such changes, it will
use its own time (obviously) and may only give us the nickname of the user,
rather than their full address. Thus, if our C<time> and the ircd's time do
not match, or the ircd uses the nickname only, ugly inconsistencies can develop.
This leaves the B<'SetAt'> and B<'SetBy'> values inaccurate at best, and you
should use them with this in mind (for now, at least).

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

With contributions from Lyndon Miller.

=head1 LICENCE

This module may be used, modified, and distributed under the same
terms as Perl itself. Please see the license that came with your Perl
distribution for details.

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>

L<POE::Component::IRC::Qnet::State|POE::Component::IRC::Qnet::State>

=cut
