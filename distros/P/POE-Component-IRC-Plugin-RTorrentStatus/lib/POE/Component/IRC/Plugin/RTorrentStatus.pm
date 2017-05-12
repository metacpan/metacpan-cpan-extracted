package POE::Component::IRC::Plugin::RTorrentStatus;
BEGIN {
  $POE::Component::IRC::Plugin::RTorrentStatus::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::RTorrentStatus::VERSION = '0.17';
}

use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use DateTime;
use DateTime::Format::Human::Duration;
use File::Glob ':glob';
use File::Spec::Functions 'rel2abs';
use Format::Human::Bytes;
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE);
use POE::Component::IRC::Common qw(NORMAL DARK_GREEN DARK_BLUE ORANGE TEAL BROWN PURPLE MAGENTA);
use POE::Component::IRC::Plugin::FollowTail;

sub new {
    my ($package, %args) = @_;
    my $self = bless \%args, $package;

    if (!defined $self->{Torrent_log}) {
        croak __PACKAGE__ . ": No torrent log file defined";
    }

    if (ref $self->{Channels} ne 'ARRAY' || !$self->{Channels}) {
        croak __PACKAGE__ . ': No channels defined';
    }

    $self->{Torrent_log} = rel2abs(bsd_glob($self->{Torrent_log}));
    if (!-e $self->{Torrent_log}) {
        open my $foo, '>', $self->{Torrent_log}
            or die "Can't create $self->{Torrent_log}: $!\n";
        close $foo;
    }

    # defaults
    $self->{Method} = 'notice' if !defined $self->{Method};
    $self->{Color} = 1 if !defined $self->{Color};

    return $self;
}

sub PCI_register {
    my ($self, $irc) = @_;

    $irc->plugin_add(TorrentTail => POE::Component::IRC::Plugin::FollowTail->new(
        filename => $self->{Torrent_log},
    ));

    $irc->plugin_register($self, 'SERVER', qw(tail_input));
    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;
    return 1;
}

sub S_tail_input {
    my ($self, $irc) = splice @_, 0, 2;
    my $filename = ${ $_[0] };
    my $input    = ${ $_[1] };
    return if $filename ne $self->{Torrent_log};

    my ($date, $action, @args) = split /\t/, $input;
    my $method = "_${action}_torrent";
    my $msg = $self->$method(@args);

    if (defined $msg) {
        for my $chan (@{ $self->{Channels} }) {
            $irc->yield($self->{Method}, $chan, $msg);
        }
    }

    return PCI_EAT_NONE;
}

sub _inserted_new_torrent {
    my ($self, $name, $user, $bytes) = @_;

    my $size = _fmt_bytes($bytes);
    my $msg = $self->{Color}
        ? DARK_BLUE.'Enqueued: '.ORANGE.$name.NORMAL." ($size, by $user)"
        : "Enqueued: $name ($size, by $user)";

    return $msg;
}

sub _hash_queued_torrent {
    my ($self, $name, $enqueued, $finished, $bytes) = @_;

    my $duration = _duration($enqueued, $finished);
    my $secs = $finished - $enqueued;
    $secs = 1 if $secs == 0; # avoid division by zero

    my $bps = $bytes / $secs;
    my $size = _fmt_bytes($bps);
    my $rate = "$size/s";

    return $self->{Color}
        ? DARK_GREEN.'Finished: '.ORANGE.$name.NORMAL." in $duration ($rate); Checking hash..."
        : "Finished: $name in $duration ($rate). Checking hash...";
}

sub _finished_torrent {
    my ($self, $name, $hash_started, $hash_done, $rars) = @_;

    my $duration = _duration($hash_started, $hash_done);

    my $msg = $self->{Color}
        ? PURPLE.'Hashed: '.ORANGE.$name.NORMAL." in $duration"
        : "Hashed: $name in $duration";

    if ($rars > 0) {
        my $archives = $rars > 1 ? 'archives' : 'archive';
        $msg .= "; $rars $archives to unrar...";
    }

    return $msg;
}

sub _unrar_torrent {
    my ($self, $name, $start, $finish, $rars, $file) = @_;

    my $duration = _duration($start, $finish);
    my $archives = $rars > 1 ? 'archives' : 'archive';
    my $info = defined $file ? $file : "$rars $archives";

    my $msg = $self->{Color}
        ? MAGENTA.'Unrared: '.ORANGE.$name.NORMAL." in $duration ($info)"
        : "Unrared: $name in $duration ($info)";

    return $msg;
}

sub _unrar_failed_torrent {
    my ($self, $name, $error) = @_;
    $error = '' if !defined $error;

    return $self->{Color}
        ? BROWN.'Unrar failed: '.ORANGE.$name.NORMAL.": $error"
        : "Unrared failed: $name: $error";
}

sub _erased_torrent {
    my ($self, $name, $size_bytes, $down_bytes, $up_bytes, $ratio) = @_;
    my $up = _fmt_bytes($up_bytes);
    $ratio /= 1000 if $ratio != 0;
    $ratio = sprintf '%.2f', $ratio;

    my $msg;
    if ($size_bytes == $down_bytes) {
        $msg = $self->{Color}
            ? TEAL.'Removed: '.ORANGE.$name.NORMAL." (ratio: $ratio, uploaded: $up)"
            : "Removed: $name (ratio: $ratio, uploaded: $up)";
    }
    else {
        my $done = sprintf '%.f%%', $down_bytes / $size_bytes * 100;
        $msg = $self->{Color}
            ? BROWN.'Aborted: '.ORANGE.$name.NORMAL." ($done done, ratio: $ratio, uploaded: $up)"
            : "Aborted: $name ($done done, ratio: $ratio, uploaded: $up)";
    }

    return $msg;
}

sub _duration {
    my ($start, $finish) = @_;

    my $enq_date = DateTime->from_epoch(epoch => $start);
    my $fin_date = DateTime->from_epoch(epoch => $finish);
    my $dur_obj = $fin_date - $enq_date;
    my $span = DateTime::Format::Human::Duration->new();
    return $span->format_duration($dur_obj);
}

sub _fmt_bytes {
    my ($bytes) = @_;
    return '0B' if $bytes == 0;
    return Format::Human::Bytes::base2($_[0]) }

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::RTorrentStatus - A PoCo-IRC plugin which prints RTorrent status messages to IRC

=head1 SYNOPSIS

To quickly get an IRC bot with this plugin up and running, you can use
L<App::Pocoirc|App::Pocoirc>:

 $ pocoirc -s irc.perl.org -j '#bots' -a 'RTorrentStatus{ "Channels": ["#bots"], "Torrent_log": "/tmp/torrentlog" }'

Or use it in your code:

 use POE::Component::IRC::Plugin::RTorrentStatus;

 # post status updates to #foobar
 $irc->plugin_add(Torrent => POE::Component::IRC::Plugin::RTorrentStatus->new(
     Torrent_log => '/tmp/torrentlog',
     Channels    => ['#foobar'],
 ));

=head1 DESCRIPTION

POE::Component::IRC::Plugin::RTorrentStatus is a
L<POE::Component::IRC|POE::Component::IRC> plugin. It reads a log file
generated by the included L<irctor-queue> program and posts messages to
IRC describing the events. See the documentation for L<irctor-queue>
on how to set it up with RTorrent.

 -MyBot:#channel- Enqueued: ubuntu-9.10-desktop-i386.iso (700MB, by hinrik)
 -MyBot:#channel- Aborted: ubuntu-9.10-desktop-i386.iso (10% done, ratio: 0.05, up: 35MB)
 -MyBot:#channel- Enqueued: ubuntu-9.10-desktop-amd64.iso (700MB, by hinrik)
 -MyBot:#channel- Finished: ubuntu-9.10-desktop-amd64.iso in 20 minutes (597kB/s); Checking hash...
 -MyBot:#channel- Hashed: ubuntu-9.10-desktop-amd64.iso in 10 seconds
 -MyBot:#channel- Removed: ubuntu-9.10-desktop-amd64.iso (ratio: 2.00, up: 1400MB)

And if you've got unraring enabled:

 -MyBot:#channel- Enqueued: foobar (100MB, by hinrik)
 -MyBot:#channel- Finished: foobar in 10 minutes (171kB/s); Checking hash...
 -MyBot:#channel- Hashed: foobar in 5 seconds; 1 archive to unrar
 -MyBot:#channel- Unrared: foobar in 5 seconds (1 archive)
 -MyBot:#channel- Removed: foobar (ratio: 2.00, uploaded: 200MB)

=head1 METHODS

=head2 C<new>

Takes the following arguments:

B<'Torrent_log'>, the path to the torrent log file generated by the
L<irctor-queue> program. This argument is required.

B<'Channels'>, an array reference of channels to post messages to. You must
specify at least one channel.

B<'Color'>, whether to print colorful status messages. True by default.

B<'Method'>, how you want messages to be delivered. Valid options are
'notice' (the default) and 'privmsg'.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add> method.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
