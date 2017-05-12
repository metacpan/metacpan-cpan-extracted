#!/usr/bin/perl

use strict;

use lib '.';

use POE qw/Wheel::FollowTail Filter::Stream Filter::Stream/;
use Term::Visual;
use Fcntl qw/:seek/;
use File::Basename;
use Math::BigInt;

local *D;
if (Term::Visual::DEBUG) {
    *D = *Term::Visual::ERRS;
}

use Getopt::Long;

our %System_Logs = (
    messages         => "/var/log/messages",
    #syslog          => "/var/log/syslog",
    x               => "/var/log/XFree86.0.log",
    #user            => "/var/log/user.log",
    #daemon          => "/var/log/daemon.log",
    #debug           => "/var/log/debug.log",
    auth            => "/var/log/auth.log",
    ftp              => "/var/log/ftp.log",
    kernel           => "/var/log/kernel.log",
    httpd            => "/var/log/httpd-access.log",
    mail             => "/var/log/maillog",
    security         => "/var/log/security",
    user             => "/var/log/userlog",
    #emerge          => "/var/log/emerge.log",
    #mysql           => "/var/log/mysql/mysql.err",
    #mysql_access    => "/var/log/mysql/mysql.log",
    #apache          => "/var/log/apache/error_log",
    #apache_access   => "/var/log/apache/access_log",
    #myth            => "/var/log/mythbackend.log",
);

our %Bindings = (
    Up   => 'history',
    Down => 'history',
    "Alt-P" => 'change_window',
    map {; "Alt-$_", 'change_window' } 0 .. 9, qw(
        q w e r t y u i o p
        a s d f g h j k l
        z x c v b n m
    )
);

our %Commands = (
    exit    => 'tail_quit',
    quit    => 'tail_quit',
    q       => 'tail_quit',
    close   => 'tail_close',
    cl      => 'tail_close',
    c       => 'tail_close',
    window  => 'tail_win',
    win     => 'tail_win',
    wi      => 'tail_win',
    w       => 'tail_win',
);

our %Pallet = (
    warn_bullet => 'bold yellow',
    err_bullet  => 'bold red',
    out_bullet  => 'bold green',
    access      => 'bright red on blue',
    current     => 'bright yellow on blue',
);

$SIG{__DIE__} = sub {
    if (Term::Visual::DEBUG) {
        print Term::Visual::ERRS "Died: @_\n";
    }
};

sub handler_start {
# -----------------------------------------------------------------------------
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

    my $win_cmd = premutate("window");
    my $exit_cmd = premutate("exit");
    my $close_cmd = premutate("close");
    $heap->{vt} = Term::Visual->new(
        Alias        => "vterm",
        History_Size => 300,
        Common_Input => 1,
        Tab_Complete => sub {
            my $left = shift;
            my @ret;
            if ($left =~ /$win_cmd\z/) {
                @ret = ("window ");
            }
            elsif ($left =~ /$win_cmd (.*)/) {
                my $match = $1;
                for (values %{$heap->{clients}}) {
                    next unless $_->{log}{system};
                    if ($_->{log}{name} =~ /\A\Q$match/i) {
                        push @ret, "$_->{log}{name} ";
                    }
                }
                for (values %{$heap->{clients}}) {
                    next if $_->{log}{system};
                    if ($_->{log}{name} =~ /\A\Q$match/i) {
                        push @ret, "$_->{log}{name} ";
                    }
                }
            }
            if ($left =~ /$exit_cmd\z/) {
                push @ret, "exit ";
            }
            if ($left =~ /$close_cmd\z/) {
                push @ret, "close ";
            }
            my %uniq;
            return sort grep { !$uniq{$_}++ } @ret;
        }
    );
    $heap->{vt}->set_palette(%Pallet);

    # setup some easy to use output handlers
    my $out = sub {
        $heap->{vt}->print($heap->{vt}->current_window,
            "\0($_[0]_bullet)***\0(ncolor) " . $_[1] .
            " \0($_[0]_bullet)***\0(ncolor)\n");
    };
    $heap->{err} = sub {
        my $msg = join '', @_;
        if (!$heap->{vt}) {
            print STDERR $msg;
            return;
        }
        $out->('err', $msg);
    };
    $heap->{warn} = sub {
        my $msg = join '', @_;
        if (!$heap->{vt}) {
            print STDERR $msg;
            return;
        }
        $out->('warn', $msg);
    };
    $heap->{out} = sub {
        my $msg = join '', @_;
        if (!$heap->{vt}) {
            print $msg;
            return;
        }
        $out->('out', $msg);
    };
    for (sort keys %System_Logs) {
        next unless -e $System_Logs{$_};
        my $name = basename $System_Logs{$_};
        push @{$heap->{logs}}, {
            user     => 'None',
            domain   => 'None',
            name     => $_,
            system   => 1,
            path     => $System_Logs{$_},
            multilog => $name eq 'current',
        };
    }

    $heap->{vt}->bind(%Bindings);
    $kernel->post(vterm => send_me_input => 'client_out');
    $kernel->yield('tail_start', shift @{$heap->{logs}});
}

sub handler_tail_start {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $log) = @_[KERNEL, HEAP, ARG0];
    my $title;
    if ($log->{system}) {
        $title = "System Log: $log->{path}";
    }
    else {
        $title = "$log->{user} $log->{domain} $log->{path}"
    }
    my $win = $heap->{vt}->create_window(
        Window_Name  => $log->{name},
        Buffer_Size  => 9000,
        Title        => $title,
        Status       => {
            0 => {
                format => "%s",
                fields => [ 'time' ],
            }
        }
    );
    my $wheel = POE::Wheel::FollowTail->new(
        Filename     => $log->{path},
        Filter       => POE::Filter::Line->new,
        PollInterval => 1,
        InputEvent   => 'tail_out',
        ResetEvent   => 'tail_truncated',
        ErrorEvent   => 'tail_error',
        SeekBack     => find_frame($log->{path}, 20)
    );
    $heap->{windows}{$win} = $wheel->ID;
    $heap->{clients}{$wheel->ID} = {
        id     => $wheel->ID,
        wheel  => $wheel,
        window => $win,
        log    => $log
    };
    my $next_log = shift @{$heap->{logs}};
    if ($next_log) {
        $kernel->yield('tail_start', $next_log);
    }
    else {
        $kernel->delay_set(update_status => 1);
        for my $cl (values %{$heap->{clients}}) {
            my $i = 0;
            $heap->{vt}->set_status_format($cl->{window},
                1 => {
                    format => join(" ", map { "[%s]" } keys %{$heap->{clients}}),
                    fields => [
                        map { $heap->{clients}{$_}{log}{name} }
                        sort { $heap->{clients}{$a}{log}{name} cmp $heap->{clients}{$b}{log}{name} }
                        keys %{$heap->{clients}}
                    ],
                }
            );
            my %stuff = map {; $_->{log}{name} => $_->{log}{name} } values %{$heap->{clients}};
            $heap->{vt}->set_status_field($cl->{window}, %stuff);
        }
        $heap->{status_ready} = 1;
        change_window($heap, 0);
    }
}

sub handler_client_out {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $output, $thing) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $win = $heap->{vt}->current_window;
    if ($thing and ($thing eq 'interrupt' or $thing eq 'quit')) {
        $kernel->yield('tail_quit');
    }
    elsif ($output =~ m{\A(\w+)(?:\s+(.+))?}i and exists $Commands{$1}) {
        $kernel->yield($Commands{$1}, $win, $2);
    }
    else {
        $heap->{warn}->("I don't know what you want!");
    }
}

sub handler_tail_quit {
# -----------------------------------------------------------------------------
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{out}->("GoodBye");
    delete $heap->{clients};
    $kernel->post(vterm => 'shutdown');
    $kernel->alarm_remove_all;
    delete $heap->{vt};
}

sub handler_tail_win {
# -----------------------------------------------------------------------------
    my ($heap, $win, $id) = @_[HEAP, ARG0, ARG1];
    $id =~ s/\A\s*//;
    $id =~ s/\s*\z//;
    # try very hard to find what window they want to switch to
    if ($id =~ /\D/) {
        for (values %{$heap->{clients}}) {
            if (lc($_->{log}{name}) eq lc($id)) {
                $id = $_->{window};
                last;
            }
        }
    }
    unless ($heap->{vt}->validate_window($id)) {
        $heap->{warn}->("$id is not a valid window");
        return;
    }
    my $cp = $id;
    if ($id !~ /\A\d+\z/) {
        $id = $heap->{vt}->get_window_id($id);
    }
    if (!defined $id) {
        $heap->{warn}->("$cp is not a valid window");
    }
    else {
        change_window($heap, $id);
    }
}

sub change_window {
# -----------------------------------------------------------------------------
    my ($heap, $id) = @_;
    my $cw = $heap->{vt}->current_window;
    my $wheel_id = $heap->{windows}{$cw};
    my $cl = $heap->{clients}{$wheel_id};
    if ($cl) {
        print D "normal for $cl->{window}\n";
        $heap->{vt}->set_status_field($cl->{window},
            $cl->{log}{name} => $cl->{log}{name}
        );
    }
    $heap->{vt}->change_window($id);
    $wheel_id = $heap->{windows}{$id};
    $cl = $heap->{clients}{$wheel_id};
    if ($cl) {
        print D "current for $cl->{window}\n";
        $heap->{vt}->set_status_field($cl->{window},
            $cl->{log}{name} => "\0(current)$cl->{log}{name}\0(st_frames)"
        );
    }
}

sub handler_tail_close {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $win) = @_[KERNEL, HEAP, ARG0];

    my $wheel_id = delete $heap->{windows}{$win};
    delete $heap->{clients}{$wheel_id};

    if (keys %{$heap->{clients}}) {
        $heap->{vt}->delete_window($win);
    }
    else {
        $kernel->yield('tail_quit');
    }
}

sub handler_stop {
# -----------------------------------------------------------------------------
    my $heap = $_[HEAP];
    $heap->{out}->("GoodBye!\n");
}

sub handler_tail_out {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $input, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    return unless exists $heap->{clients}{$wheel_id};
    my $cl = $heap->{clients}{$wheel_id};

    if ($cl->{log}{multilog} and substr($input, 0, 1) == '@') {
        my $len = length $input;
        my $secs = Math::BigInt->new();
        my $nsecs = Math::BigInt->new();
        my $i;
        for ($i = 1; $i < $len; $i++) {
            my $ch = substr($input, $i, 1);
            my $u = ord($ch) - ord('0');
            if ($u >= 10 or $u < 0) {
                $u = ord($ch) - ord('a');
                if ($u >= 6 or $u < 0) {
                    last;
                }
                $u += 10;
            }
            $secs <<= 4;
            $secs += $nsecs >> 28;
            $nsecs &= 0xfffffff;
            $nsecs <<= 4;
            $nsecs += $u;
        }
        my $time = $secs - Math::BigInt->new('4611686018427387914');
        substr($input, 0, $i, scalar(localtime $time));
    }
    if ($heap->{status_ready} and $cl->{window} != $heap->{vt}->current_window) {
        print D "busy for $cl->{window}\n";
        $heap->{vt}->set_status_field($cl->{window}, $cl->{log}{name} => "\0(access)$cl->{log}{name}\0(st_frames)");
    }

    $heap->{vt}->print($cl->{window}, $input);
}

sub handler_tail_error {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $ret, $errno, $errstr) = @_[KERNEL, HEAP, ARG0 .. $#_];
    return if $errno == 0;
    $heap->{err}->("Error[$errno]: $errstr\n");
}

sub handler_tail_truncated {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $wheel_id) = @_[KERNEL, HEAP, ARG0];

    return unless exists $heap->{clients}{$wheel_id};
    my $cl = $heap->{clients}{$wheel_id};

    $heap->{vt}->print(
        $cl->{window},
        "\0(warn_bullet)>>>\0(ncolor) ".
        "File Truncated ".
        "\0(warn_bullet)<<<\0(ncolor)\n"
    );
}

sub handler_change_window {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $key) = @_[KERNEL, HEAP, ARG0];
    my $k = substr $key, -1;
    my $i = 0;
    my %map = (map { $_, $i++ } 1 .. 9, 0, qw(
        q w e r t y u i o p
        a s d f g h j k l
        z x c v b n m
    ));
    if (exists $map{$k} and exists $heap->{windows}{$map{$k}}) {
        change_window($heap, $map{$k});
    }
}

sub handler_history {
# -----------------------------------------------------------------------------
    my ($kernel, $heap, $key, $win) = @_[KERNEL, HEAP, ARG0, ARG2];
    if ($key eq 'KEY_UP') {
        $heap->{vt}->command_history($win, 1);
    }
    else {
        $heap->{vt}->command_history($win, 2);
    }
}

sub handler_update_status {
# -----------------------------------------------------------------------------
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    for (keys %{$heap->{windows}}) {
        $heap->{vt}->set_status_field($_, time => scalar(localtime));
    }
    $kernel->delay_set(update_status => 1);
}

sub find_frame {
# -----------------------------------------------------------------------------
    my ($path, $lines) = @_;
    use bytes;

    my $file_size = -s $path;
    open my $fh, "<", $path
        or die "Could not open $path; Reason: $!";
    seek $fh, 0, SEEK_END;
    my $num_lines = 0;
    my $back = 0;
    while ($num_lines != $lines) {
        if (($back - 1024) * -1 > $file_size) {
            $back = $file_size * -1;
            last;
        }
        seek $fh, $back - 1024, SEEK_END or last;
        $back -= 1024;
        my $bad = <$fh>;
        $back += length $bad;
        $num_lines = 0;
        $num_lines++ while <$fh>;
        if ($num_lines > $lines) {
            seek $fh, $back, SEEK_END;
            while ($num_lines > $lines) {
                $back += length(scalar(<$fh>));
                $num_lines--;
            }
        }
    }
    close $fh;
    return $back * -1;
}

sub premutate {
# -----------------------------------------------------------------------------
    my $str = shift;
    my $re = '\A';
    for (0 .. length $str) {
        $re .= '(?:' . substr $str, $_, 1;
    }
    for (0 .. length $str) {
        $re .= ')?';
    }
    return qr/$re/i;
}


POE::Session->create(
    inline_states => {
        _start         => \&handler_start,
        _stop          => \&handler_stop,
        client_out     => \&handler_client_out,
        tail_out       => \&handler_tail_out,
        tail_start     => \&handler_tail_start,
        tail_error     => \&handler_tail_error,
        tail_quit      => \&handler_tail_quit,
        tail_win       => \&handler_tail_win,
        tail_close     => \&handler_tail_close,
        tail_truncated => \&handler_tail_truncated,
        history        => \&handler_history,
        change_window  => \&handler_change_window,
        update_status  => \&handler_update_status,
    },
    heap => {
        vt      => undef,
        clients => {},
        windows => {},
        logs    => [],
    }
);

$poe_kernel->run;

