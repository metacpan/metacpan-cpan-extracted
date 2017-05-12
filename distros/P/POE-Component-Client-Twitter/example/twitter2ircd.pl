#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use Data::Dumper;
use Getopt::Long;
use POE qw(Component::Client::Twitter Component::Server::IRC Component::TSTP);
use YAML;

GetOptions('-c=s' => \my $conf, '--quiet' => \my $quiet);
$conf or die "Usage: twitter2ircd.pl -c=config.yaml\n";

my $config = YAML::LoadFile($conf) or die $!;

if ($quiet) {
    close STDIN;
    close STDOUT;
    close STDERR;
    exit if fork;
} else {
    # for Ctrl-Z
    POE::Component::TSTP->create();
}

my $ircd = POE::Component::Server::IRC->spawn(
    alias  => 'ircd',
    config => {
        servername => $config->{irc}->{servername},
        nicklen    => 15,
        network    => 'SimpleNET'
    },
);

my $twitter = POE::Component::Client::Twitter->spawn(%{ $config->{twitter} });

POE::Session->create(
    inline_states => {
        _start   => \&_start,
        ircd_daemon_nick => \&ircd_nick,
        ircd_daemon_join => \&ircd_join,
        ircd_daemon_part => \&ircd_part,
        ircd_daemon_quit => \&ircd_quit,
#        ircd_daemon_privmsg => \&ircd_privmsg,
        ircd_daemon_public  => \&ircd_public,

        'twitter.update_success' => \&twitter_update_success,
        'twitter.friend_timeline_success' => \&twitter_friend_timeline_success,
        'twitter.response_error' => \&twitter_error,

        bot_join => \&bot_join,
        delay_friend_timeline => \&delay_friend_timeline,
    },
    options => { trace => 0 },
    heap => { ircd => $ircd, twitter => $twitter, config => $config },
);

$poe_kernel->run();
exit 0;

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $conf = $heap->{config}->{irc};

    # register ircd to receive events
    $heap->{ircd}->yield( 'register' );
    $heap->{twitter}->yield('register');
    $heap->{ircd}->add_auth(
        mask => $conf->{mask},
        password => $conf->{password}
    );
    $heap->{ircd}->add_listener( port => $conf->{serverport} || 6667 );

    # add super user
    $heap->{ircd}->yield(add_spoofed_nick => { nick => $conf->{botname} });
    $heap->{ircd}->yield(daemon_cmd_join => $conf->{botname}, $conf->{channel});
    $kernel->delay('delay_friend_timeline', 5);

    $heap->{nicknames} = {};
    $heap->{joined}    = 0;
    $heap->{stack}     = [];

    undef;
}

sub delay_friend_timeline {
    my($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{twitter}->yield('friend_timeline');
}

sub bot_join {
    my($kernel, $heap, $nick, $ch) = @_[KERNEL, HEAP, ARG0, ARG1];

    return if $heap->{nicknames}->{$nick};
    $heap->{ircd}->yield(add_spoofed_nick => { nick => $nick });
    $heap->{ircd}->yield(daemon_cmd_join => $nick, $ch);
    $heap->{nicknames}->{$nick} = 1;
}

sub ircd_nick {
    my($kernel, $heap, $nick, $host) = @_[KERNEL, HEAP, ARG0, ARG5];
    my $conf = $heap->{config}->{irc};

    return if $nick eq $conf->{botname};
    return if $heap->{nick_change} || '';
    if (($host || '') eq $conf->{servername}) {
        $heap->{ircd}->_daemon_cmd_join($nick, $conf->{channel});
        $heap->{nick_change} = 1;
        $heap->{ircd}->_daemon_cmd_nick($nick, $conf->{nickname});
        delete $heap->{nick_change};
    }

    $heap->{nick} = $nick;
}

sub ircd_join {
    my($kernel, $heap, $user, $ch) = @_[KERNEL,HEAP,ARG0,ARG1];
    my $conf = $heap->{config}->{irc};

    return unless my($nick) = $user =~ /^([^!]+)!/;
    return if $heap->{nicknames}->{$nick};
    return if $nick eq $conf->{botname};
    if ($ch eq $conf->{channel}) {
        $heap->{joined} = 1;
        $heap->{twitter}->yield(update => 'twitter2irc.pl join');

        for my $data (@{ $heap->{stack} }) {
            $heap->{ircd}->yield(daemon_cmd_privmsg => $data->{name}, $conf->{channel}, $data->{text});
        }
        $heap->{stack} = [];
        return;
    }
    $heap->{ircd}->_daemon_cmd_part($nick, $ch);
}

sub ircd_part {
    my($kernel, $heap, $user, $ch) = @_[KERNEL,HEAP,ARG0,ARG1];
    my $conf = $heap->{config}->{irc};

    return unless my($nick) = $user =~ /^([^!]+)!/;
    return if $heap->{nicknames}->{$nick};
    return if $nick eq $conf->{botname};

    if ($ch eq $conf->{channel}) {
        $heap->{joined} = 0;
        $heap->{twitter}->yield(update => 'twitter2irc.pl part');
    }
}

sub ircd_quit {
    my($kernel, $heap, $user) = @_[KERNEL,HEAP,ARG0];
    my $conf = $heap->{config}->{irc};

    return unless my($nick) = $user =~ /^([^!]+)!/;
    return if $heap->{nicknames}->{$nick};
    return if $nick eq $conf->{botname};
    $heap->{joined} = 0;
    $heap->{twitter}->yield(update => 'twitter2irc.pl quit');
}

sub ircd_public {
    my($kernel, $heap, $user, $channel, $text) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    my $conf = $heap->{config}->{irc};

    my $nick = ( $user =~ m/^(.*)!/)[0];
    $heap->{twitter}->yield(update => $text);
}


sub twitter_update_success {
    my($kernel, $heap, $ret) = @_[KERNEL, HEAP, ARG0];
    my $conf = $heap->{config}->{irc};
    $heap->{ircd}->yield(daemon_cmd_notice => $conf->{botname}, $conf->{channel}, $ret->{text});
}

sub twitter_friend_timeline_success {
    my($kernel, $heap, $ret) = @_[KERNEL, HEAP, ARG0];
    my $conf = $heap->{config}->{irc};

    $ret = [] unless $ret;
    for my $line (reverse @{ $ret }) {
        my $name = $line->{user}->{screen_name};
        my $text = $line->{text};

        unless ($heap->{nicknames}->{$name}) {
            $heap->{ircd}->yield(add_spoofed_nick => { nick => $name });
            $heap->{ircd}->yield(daemon_cmd_join => $name, $conf->{channel});
            $heap->{nicknames}->{$name} = 1;
        }

        next if $heap->{config}->{twitter}->{screenname} eq $name;
        if ($heap->{joined}) {
            $heap->{ircd}->yield(daemon_cmd_privmsg => $name, $conf->{channel}, $text);
        } else {
            push @{ $heap->{stack} }, { name => $name, text => $text }
        }
    }
    $kernel->delay('delay_friend_timeline', $heap->{config}->{twitter}->{retry});
}

sub twitter_error {
    my($kernel, $heap, $res) = @_[KERNEL, HEAP, ARG0];
    my $conf = $heap->{config}->{irc};
    $heap->{ircd}->yield(daemon_cmd_notice => $conf->{botname}, $conf->{channel}, 'Twitter error');
}

__END__

config.yaml example

irc:
  servername: twitter.irc
  serverport: 6667
  botname: twitter
  nickname: chatname
  password: password
  mask: '*@*'
  channel: '#twitter'
twitter:
  screenname: twittername
  username: twitter id
  password: twitter password
  retry: 300
