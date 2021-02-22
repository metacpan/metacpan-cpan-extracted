package Mojo::IRC::UA;
use Mojo::Base 'Mojo::IRC';

use Data::Dumper ();
use IRC::Utils   ();
use Mojo::Util   ();
use constant DEBUG => $ENV{MOJO_IRC_DEBUG} || 0;

Mojo::Util::deprecated 'Mojo::IRC::UA is deprecated and should no longer be used';

has op_timeout => 10;

has _parse_namreply_map => sub {
  my $self   = shift;
  my @prefix = split /[\(\)]/, $self->server_settings->{prefix} || '(@+)ov';
  my $i      = 0;
  my %map    = map { (substr($prefix[2], $i++, 1), $_) } split //, $prefix[1];
  my $re     = "^([$prefix[2]])";

  warn "[$self->{debug_key}] : parse_namreply_map=@{[Data::Dumper->new([[$re, \%map]])->Indent(0)->Terse(1)->Dump]}\n"
    if DEBUG == 2;

  return [qr{$re}, \%map];
};

sub channels {
  my ($self, $cb) = @_;
  my %channels;

  return $self->_write_and_wait(
    Parse::IRC::parse_irc("LIST"),
    {
      rpl_listend => {},     # :hybrid8.debian.local 323 superman :End of /LIST
      rpl_list    => sub {
        my ($self, $msg) = @_;
        my $topic = $msg->{params}[3] // '';
        $topic =~ s!^\[\+[a-z]+\]\s?!!;    # remove mode from topic, such as [+nt]
        $channels{$msg->{params}[1]} = {n_users => $msg->{params}[2], topic => $topic};
      },
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      my $n = 0;

      return $self->$cb($err || $msg->{params}[1] || $event, {}) if $event =~ /^err_/;
      return $self->$cb('', \%channels);
    },
  );
}

sub channel_topic {
  my $cb = pop;
  my ($self, $channel, $topic) = @_;
  my $res = length($topic // '') ? {} : undef;

  if (!$channel) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot get/set topic without channel name.', {}) });
    return $self;
  }
  if ($channel =~ /\s/) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot get/set topic on channel with spaces in name.', {}) });
    return $self;
  }

  return $self->_write_and_wait(
    $res ? Parse::IRC::parse_irc("TOPIC $channel :$topic") : Parse::IRC::parse_irc("TOPIC $channel"),
    {
      err_chanoprivsneeded => {1 => $channel},
      err_nochanmodes      => {1 => $channel},
      err_notonchannel     => {1 => $channel},
      rpl_notopic          => {1 => $channel},
      rpl_topic            => {1 => $channel},    # :hybrid8.debian.local 332 superman #convos :get cool topic
      topic                => {0 => $channel},    # set
    },
    sub {
      my ($self, $event, $err, $msg) = @_;

      if ($event eq 'rpl_notopic') {
        $res->{topic} = '';
      }
      elsif ($event eq 'rpl_topic') {
        $res->{topic} = $msg->{params}[2] // '';
      }
      elsif ($event eq 'topic') {
        $err = '';
      }
      else {
        $err ||= $msg->{params}[2] || $event;
      }

      return $self->$cb($err, $res) if $res;
      return $self->$cb($err);
    }
  );
}

sub channel_users {
  my ($self, $channel, $cb) = @_;
  my $users = {};

  if (!$channel) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot get users without channel name.', {}) });
    return $self;
  }

  return $self->_write_and_wait(
    Parse::IRC::parse_irc("NAMES $channel"),
    {
      err_toomanymatches => {1 => $channel},
      err_nosuchserver   => {},
      rpl_endofnames     => {1 => $channel},
      rpl_namreply       => sub {
        my ($self, $msg) = @_;
        $self->_parse_namreply($msg, $users) if lc $msg->{params}[2] eq lc $channel;
      },
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      $self->$cb($event =~ /^err_/ ? $err || $msg->{params}[2] || $event : '', $users);
    }
  );
}

sub join_channel {
  my ($self, $command, $cb) = @_;
  my ($channel) = split /\s/, $command, 2;
  my $info = {topic => '', topic_by => '', users => {}};

  # err_needmoreparams and will not allow special "JOIN 0"

  if (!$channel) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot join without channel name.') });
    return $self;
  }

  return $self->_write_and_wait(
    Parse::IRC::parse_irc("JOIN $command"),
    {
      err_badchanmask     => {1 => $channel},
      err_badchannelkey   => {1 => $channel},
      err_bannedfromchan  => {1 => $channel},    # :hybrid8.debian.local 474 superman #convos :Cannot join channel (+b)
      err_channelisfull   => {1 => $channel},
      err_inviteonlychan  => {1 => $channel},
      err_nosuchchannel   => {1 => $channel},    # :hybrid8.debian.local 403 nick #convos :No such channel
      err_toomanychannels => {1 => $channel},
      err_toomanytargets  => {1 => $channel},
      err_unavailresource => {1 => $channel},
      479                 => {1 => $channel},    # Illegal channel name
      rpl_endofnames      => {1 => $channel},    # :hybrid8.debian.local 366 superman #convos :End of /NAMES list.
      err_linkchannel     => sub {
        my ($self, $msg) = @_;
        return unless lc $msg->{params}[1] eq lc $channel;
        for my $item (values %{$msg->{look_for}}) {
          $item->{1} = $msg->{params}[2] if ref $item eq 'HASH' and $item->{1} and $item->{1} eq $channel;
        }
        $channel = $msg->{params}[2];
      },
      rpl_namreply => sub {
        my ($self, $msg) = @_;
        $self->_parse_namreply($msg, $info->{users}) if lc $msg->{params}[2] eq lc $channel;
      },
      rpl_topic => sub {
        my ($self, $msg) = @_;
        $info->{topic} = $msg->{params}[2] if lc $msg->{params}[1] eq lc $channel;
      },
      rpl_topicwhotime => sub {
        my ($self, $msg) = @_;
        $info->{topic_by} = $msg->{params}[2] if lc $msg->{params}[1] eq lc $channel;
      },
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      $info->{name} = $channel;
      $self->$cb($event =~ /^(?:err_|479)/ ? $err || $msg->{params}[2] || $event : '', $info);
    }
  );
}

sub kick {
  my ($self, $command, $cb) = @_;
  my ($target, $user) = $command =~ /(\S+)\s+(.*)/;
  my $res = {reason => ''};

  $target //= '';
  $user   //= '';
  $self->_write_and_wait(
    Parse::IRC::parse_irc("KICK $command"),
    {
      err_needmoreparams   => {},
      err_nosuchchannel    => {1 => $target},
      err_nosuchnick       => {1 => $user},
      err_badchanmask      => {1 => $target},
      err_chanoprivsneeded => {1 => $target},
      err_usernotinchannel => {1 => $user},
      err_notonchannel     => {1 => $target},
      kick => {0 => $target, 1 => $user},
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      my ($nick) = IRC::Utils::parse_user($msg->{prefix});
      $msg->{params}[2] //= '';
      $res->{reason} = lc $msg->{params}[2] eq lc $nick ? '' : $msg->{params}[2];
      $self->$cb($event =~ /^err_/ ? $err || $msg->{params}[2] || $event : '', $res);
    }
  );
}

sub mode {
  my $cb = pop;
  my ($self, $mode) = @_;
  return $self->_mode_for_channel($1, $2, $cb) if $mode and $mode =~ /(\S+)\s+(.+)/;
  return $self->_mode_for_user($mode, $cb);    # get or set
}

sub nick {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $nick) = @_;

  unless ($cb) {
    return $self->{nick} ||= $self->_build_nick unless defined $nick;
    $self->{nick} = $nick;
    return $self;
  }

  if ($nick) {
    if ($self->{stream}) {
      $self->_write_and_wait(
        Parse::IRC::parse_irc("NICK $nick"),
        {
          err_erroneusnickname => {0 => $nick},
          err_nickcollision    => {0 => $nick},
          err_nicknameinuse    => {1 => $nick},
          err_restricted       => {},
          err_unavailresource  => {},
          nick                 => {0 => $nick},    # :Superman12923!superman@i.love.debian.org NICK :Supermanx12923
        },
        sub {
          my ($self, $event, $err, $msg) = @_;
          $self->nick($nick) if $event eq 'nick';
          $self->$cb($event =~ /^err_/ ? $err || $msg->{params}[2] || $event : '');
        }
      );
    }
    else {
      $self->nick($nick)->$cb('');
    }
  }
  else {
    $self->$cb('', $self->nick);
  }

  return $self;
}

sub part_channel {
  my ($self, $channel, $cb) = @_;

  # err_needmoreparams
  if (!$channel) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot part without channel name.') });
    return $self;
  }
  if ($channel =~ /\s/) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot part channel with spaces.') });
    return $self;
  }

  return $self->_write_and_wait(
    Parse::IRC::parse_irc("PART $channel"),
    {
      err_nosuchchannel => {1 => $channel},    # :hybrid8.debian.local 403 nick #convos :No such channel
      err_notonchannel  => {1 => $channel},
      479               => {1 => $channel},    # Illegal channel name
      part              => {0 => $channel},
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      $self->$cb($event =~ /^(?:err_|479)/ ? $err || $msg->{params}[2] || $event : '');
    }
  );

}

sub whois {
  my ($self, $target, $cb) = @_;
  my $info = {channels => {}, name => '', nick => $target, server => '', user => ''};

  unless ($target) {
    $self->ioloop->next_tick(sub { $self->$cb('Cannot retrieve whois information without target.', {}) });
    return $self;
  }

  return $self->_write_and_wait(
    Parse::IRC::parse_irc("WHOIS $target"),
    {
      err_nosuchnick   => {1 => $target},    # :hybrid8.debian.local 401 superman batman :No such nick/channel
      err_nosuchserver => {1 => $target},
      rpl_away         => {1 => $target},
      rpl_endofwhois   => {1 => $target},
      rpl_whoischannels => sub {
        my ($self, $msg) = @_;
        return unless lc $msg->{params}[1] eq lc $target;
        for (split /\s+/, $msg->{params}[2] || '') {
          my ($mode, $channel) = /^([+@]?)(.+)$/;
          $info->{channels}{$channel} = {mode => $mode};
        }
      },
      rpl_whoisidle => sub {
        my ($self, $msg) = @_;
        return unless lc $msg->{params}[1] eq lc $target;
        $info->{idle_for} = 0 + $msg->{params}[2];
      },
      rpl_whoisoperator => {},     # TODO
      rpl_whoisserver   => sub {
        my ($self, $msg) = @_;
        return unless lc $msg->{params}[1] eq lc $target;
        $info->{server}      = $msg->{params}[2];
        $info->{server_info} = $msg->{params}[3];
      },
      rpl_whoisuser => sub {
        my ($self, $msg) = @_;
        return unless lc $msg->{params}[1] eq lc $target;
        $info->{nick} = $msg->{params}[1];
        $info->{user} = $msg->{params}[2];
        $info->{host} = $msg->{params}[3];
        $info->{name} = $msg->{params}[5];
      },
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      $self->$cb($event =~ /^err_/ ? $err || $msg->{params}[2] || $event : '', $info);
    }
  );
}

sub _dispatch_message {
  my ($self, $msg) = @_;
  my $listeners = $self->{write_and_wait}{$msg->{event}} || {};

  $self->$_($msg) for values %$listeners;
  $self->SUPER::_dispatch_message($msg);
}

sub _mode_for_channel {
  my ($self, $target, $mode, $cb) = @_;
  my $res = {banlist => [], exceptlist => [], invitelist => [], uniqopis => [], mode => $mode, params => ''};

  return $self->_write_and_wait(
    Parse::IRC::parse_irc("MODE $target $mode"),
    {
      err_chanoprivsneeded => {1 => $target},
      err_keyset           => {1 => $target},
      err_needmoreparams   => {1 => $target},
      err_nochanmodes      => {1 => $target},
      err_unknownmode      => {1 => $target},
      err_usernotinchannel => {1 => $target},
      mode                 => {0 => $target},
      rpl_endofbanlist     => {1 => $target},
      rpl_endofexceptlist  => {1 => $target},
      rpl_endofinvitelist  => {1 => $target},
      rpl_channelmodeis => sub { @$res{qw(mode params)} = @{$_[1]->{params}}[1, 2] },
      rpl_banlist    => sub { push @{$res->{banlist}},    $_[1]->{params}[1] },
      rpl_exceptlist => sub { push @{$res->{exceptlist}}, $_[1]->{params}[1] },
      rpl_invitelist => sub { push @{$res->{invitelist}}, $_[1]->{params}[1] },
      rpl_uniqopis   => sub { push @{$res->{uniqopis}},   $_[1]->{params}[1] },
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      $self->$cb($event =~ /^(?:err_)/ ? $err || $msg->{params}[2] || $event : '', $res);
    }
  );
}

sub _mode_for_user {
  my ($self, $mode, $cb) = @_;
  my $nick = $self->nick;

  return $self->_write_and_wait(
    Parse::IRC::parse_irc($mode ? "MODE $nick $mode" : "MODE $nick"),
    {
      err_umodeunknownflag => {},
      err_needmoreparams   => {},
      err_usersdontmatch   => {},
      mode        => {0 => $nick},
      rpl_umodeis => {0 => $nick},
    },
    sub {
      my ($self, $event, $err, $msg) = @_;
      $self->$cb($event =~ /^(?:err_)/ ? $err || $event : '', $msg->{params}[1]);
    }
  );
}

sub _parse_namreply {
  my ($self, $msg, $users) = @_;
  my ($re, $map) = @{$self->_parse_namreply_map};

  for my $nick (sort { lc $a cmp lc $b } split /\s+/, $msg->{params}[3]) {
    $users->{$nick}{mode} = $nick =~ s/$re// ? $map->{$1} || $1 : '';
  }
}

sub _write_and_wait {
  my ($self, $msg, $look_for, $handler) = @_;
  my $cmd = $msg->{raw_line};
  my ($tid, $timeout);

  # This method will send a IRC command to the server and wait for a
  # corresponding IRC event is returned from the server. On such an
  # event, the $handler callback will be called, but only if the event
  # received match the rules set in $look_for.

  Scalar::Util::weaken($self);

  # We want a "master timeout" as well, in case the server never send
  # us any response.
  $tid = $self->ioloop->timer(
    ($timeout = $self->op_timeout),
    sub {
      delete $self->{write_and_wait}{$_}{$cmd} for keys %$look_for;
      $self->$handler(err_timeout => "Response timeout after ${timeout}s.", {});
    }
  );

  # Set up which IRC events to look for
  for my $event (keys %$look_for) {
    $self->{write_and_wait}{$event}{$cmd} = sub {
      my ($self, $res) = @_;
      my $needle = $look_for->{$event};
      $res->{look_for} = $look_for;
      return $self->$needle($res) if ref $needle eq 'CODE';

      for my $k (keys %$needle) {
        my $v = $k =~ /^\d/ ? $res->{params}[$k] : $res->{$k};
        return unless lc $v eq lc $needle->{$k};
      }

      $self->ioloop->remove($tid);
      delete $self->{write_and_wait}{$_}{$cmd} for keys %$look_for;
      $self->$handler($event => '', $res);
    };
  }

  # Write the command to the IRC server and stop looking for events
  # if the write fails.
  $self->write(
    $msg->{raw_line},
    sub {
      my ($self, $err) = @_;
      return unless $err;    # no error
      $self->ioloop->remove($tid);
      delete $self->{write_and_wait}{$_}{$cmd} for keys %$look_for;
      $self->$handler(err_write => $err, {});
    }
  );

  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::IRC::UA - IRC Client with sugar on top (DEPRECATED)

=head1 SYNOPSIS

  use Mojo::IRC::UA;
  my $irc = Mojo::IRC::UA->new;

=head1 DESCRIPTION

L<Mojo::IRC::UA> is a module which extends L<Mojo::IRC> with methods
that can track changes in state on the IRC server.

This module is DEPRECATED and should no longer be used.

=head1 ATTRIBUTES

L<Mojo::IRC::UA> inherits all attributes from L<Mojo::IRC> and implements the
following new ones.

=head2 op_timeout

  $int = $self->op_timeout;
  $self = $self->op_timeout($int);

Max number of seconds to wait for a response from the IRC server.

=head1 EVENTS

L<Mojo::IRC::UA> inherits all events from L<Mojo::IRC> and implements the
following new ones.

=head1 METHODS

L<Mojo::IRC::UA> inherits all methods from L<Mojo::IRC> and implements the
following new ones.

=head2 channels

  $self = $self->channels(sub { my ($self, $err, $channels) = @_; });

Will retrieve available channels on the IRC server. C<$channels> has this
structure on success:

  {
    "#convos" => {n_users => 4, topic => "[+nt] some cool topic"},
  }

NOTE: This might take a long time, if the server has a lot of channels.

=head2 channel_topic

  $self = $self->channel_topic($channel, $topic, sub { my ($self, $err) = @_; });
  $self = $self->channel_topic($channel, sub { my ($self, $err, $res) = @_; });

Used to get or set topic for a channel. C<$res> is a hash with a key "topic" which
holds the current topic.

=head2 channel_users

  $self = $self->channel_users($channel, sub { my ($self, $err, $users) = @_; });

This can retrieve the users in a channel. C<$users> contains this structure:

  {
    jhthorsen => {mode => "o"},
    Superman  => {mode => ""},
  }

This method is EXPERIMENTAL and can change without warning.

=head2 join_channel

  $self = $self->join_channel($channel => sub { my ($self, $err, $info) = @_; });

Used to join an IRC channel. C<$err> will be false (empty string) on a
successful join. C<$info> will contain information about the joined channel:

  {
    name     => "#channel_name",
    topic    => "some cool topic",
    topic_by => "jhthorsen",
    users    => {
      jhthorsen => {mode => "@"},
      Superman  => {mode => ""},
    },
  }

"name" in C<$info> holds the actual channel name that is joined. This will not
be the same as C<$channel> in case of "ERR_LINKCHANNEL" (470) events, where you
are automatically redirected to another channel.

NOTE! This method will fail if the channel is already joined. Unfortunately,
the way it will fail is simply by not calling the callback. This should be
fixed - Just don't know how yet.

=head2 kick

  $self = $self->kick("#channel superman", sub { my ($self, $err, $res) = @_; });

Used to kick a user. C<$res> looks like this:

  {reason => "you don't behave"}

=head2 mode

  $self = $self->mode(sub { my ($self, $err, $mode) = @_; });
  $self = $self->mode("-i", sub { my ($self, $err, $mode) = @_; });
  $self = $self->mode("#channel +k secret", sub { my ($self, $err, $mode) = @_; });

This method is used to get or set a user mode or set a channel mode.

C<$mode> is EXPERIMENTAL, but holds a hash, with "mode" as key.

Note that this method seems to be unstable. Working on a fix:
L<https://github.com/jhthorsen/mojo-irc/issues/28>.

=head2 nick

  $self = $self->nick($nick => sub { my ($self, $err) = @_; });
  $self = $self->nick(sub { my ($self, $err, $nick) = @_; });

Used to set or get the nick for this connection.

Setting the nick will change L</nick> I<after> the nick is actually
changed on the server.

=head2 part_channel

  $self = $self->part_channel($channel => sub { my ($self, $err) = @_; });

Used to part/leave a channel.

=head2 whois

  $self = $self->whois($target, sub { my ($self, $err, $info) = @_; });

Used to retrieve information about a user. C<$info> contains this information
on success:

  {
    channels => {"#convos => {mode => "@"}],
    host     => "example.com",
    idle_for => 17454,
    name     => "Jan Henning Thorsen",
    nick     => "batman",
    server   => "hybrid8.debian.local",
    user     => "jhthorsen",
  },

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
