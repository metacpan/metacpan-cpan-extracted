package Screensaver::Any;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter::Rinci qw(import);
use File::Which qw(which);
use IPC::System::Options 'system', 'readpipe', -log=>1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-04-17'; # DATE
our $DIST = 'Screensaver-Any'; # DIST
our $VERSION = '0.008'; # VERSION

my $known_screensavers = [qw/kde gnome cinnamon xscreensaver/];
my $sch_screensaver = ['str', in=>$known_screensavers];
our %arg_screensaver = (
    screensaver => {
        summary => 'Explicitly set screensaver program to use',
        schema => $sch_screensaver,
        description => <<'MARKDOWN',

The default, when left undef, is to detect what screensaver is running,

MARKDOWN
    },
);

sub _find_qdbus {
    require File::Which;

    my @paths;
    if (my $path = File::Which::which("qdbus")) {
        log_trace "qdbus found in PATH: $path";
        push @paths, $path;
    } else {
        for my $dir ("/usr/lib/qt6/bin", "/usr/lib/qt5/bin") {
            if ((-d $dir) && (-x "$dir/qdbus")) {
                log_trace "qdbus found in $dir";
                push @paths, "$dir/qdbus";
            }
        }
    }

    @paths;
}

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Common interface to screensaver/screenlocker functions',
    description => <<'MARKDOWN',

This module provides common functions related to screensaver.

Supported screensavers: KDE Plasma's kscreenlocker (`kde`), GNOME screensaver
(`gnome`), Cinnamon screensaver (`cinnamon`), and `xscreensaver`. Support for
more screensavers, e.g. Windows is more than welcome.

MARKDOWN
};

$SPEC{'detect_screensaver'} = {
    v => 1.1,
    summary => 'Detect which screensaver program is currently running',
    description => <<'MARKDOWN',

Will return a string containing name of screensaver program, e.g. `kde`,
`gnome`, `cinnamon`, `xscreensaver`. Will return undef if no known screensaver
is detected.

MARKDOWN
    result_naked => 1,
    result => {
        schema => $sch_screensaver,
    },
};
sub detect_screensaver {
    my %args = @_;

    require Proc::Find;
    no warnings 'once';
    local $Proc::Find::CACHE = 1;

  XSCREENSAVER:
    {
        log_trace "Checking whether xscreensaver process exists ...";
        unless (Proc::Find::proc_exists(name => "xscreensaver")) {
            log_trace "xscreensaver process doesn't exist";
            last;
        }
        log_trace "xscreensaver process exists";
        log_trace "Concluding screensaver is xscreensaver";
        return "xscreensaver";
    }

  KDE:
    {
        log_trace "Checking qdbus program ...";
        my @paths = _find_qdbus();

        unless (@paths) {
            log_trace "qdbus doesn't exist";
            last;
        }
        log_trace "qdbus exists at $paths[0]";
        system({capture_stdout=>\my $dummy_out, capture_stderr=>\my $dummy_err},
               $paths[0], "org.kde.screensaver");
        if ($?) {
            log_trace "Couldn't check org.kde.screensaver dbus service";
            last;
        }
        log_trace "org.kde.screensaver dbus service exists";
        log_trace "Concluding screensaver is kde";
        return "kde";
    }

  GNOME:
    {
        log_trace "Checking whether gnome-screensaver process exists ...";
        unless (Proc::Find::proc_exists(name => "gnome-screensaver")) {
            log_trace "gnome-screensaver process doesn't exist";
            last;
        }
        log_trace "gnome-screensaver process exists";
        log_trace "Concluding screensaver is gnome (<= 3.6)";
        return "gnome"; # <= 3.6
    }

  CINNAMON:
    {
        log_trace "Checking whether cinnamon-screensaver process exists ...";
        unless (Proc::Find::proc_exists(name => "cinnamon-screensaver")) {
            log_trace "cinnamon-screensaver process doesn't exist";
            last;
        }
        log_trace "cinnamon-screensaver process exists";
        log_trace "Concluding screensaver is cinnamon";
        return "cinnamon";
    }

    undef;
}

sub _get_or_set_screensaver_timeout {
    my %args = @_;

    my $which = $args{_which};
    my $mins = $args{_mins};
    my $screensaver = $args{screensaver} // detect_screensaver();
    return [412, "Can't detect any known screensaver running"]
        unless $screensaver;

    if ($screensaver eq 'gnome') {
        if ($which eq 'set') {
            my $secs = $mins*60;
            system "gsettings", "set", "org.gnome.desktop.session",
                "idle-delay", $secs;
            return [500, "gsettings set failed: $!"] if $?;
        }
        my $res = `gsettings get org.gnome.desktop.session idle-delay`;
        return [500, "gsettings get failed: $!"] if $?;
        $res =~ /^uint32\s+(\d+)$/
            or return [500, "Can't parse gsettings get output"];
        my $val = $1;
        return [200, "OK", ($which eq 'set' ? undef : $val), {
            'func.timeout' => $val,
            'func.screensaver'=>'gnome',
        }];
    }

    if ($screensaver eq 'cinnamon') {
        return [501, "Getting/setting timeout not yet supported on cinnamon"];
    }

    require File::Slurper;

    if ($screensaver eq 'xscreensaver') {
        my $path = "$ENV{HOME}/.xscreensaver";
        my $ct = File::Slurper::read_text($path);
        if ($which eq 'set') {
            my $hours = int($mins/60);
            $mins -= $hours*60;

            $ct =~ s/^(timeout:\s*)(\S+)/
                sprintf("%s%d:%02d:%02d",$1,$hours,$mins,0)/em
                    or return [500, "Can't subtitute timeout setting in $path"];
            File::Slurper::write_text($path, $ct);
            system "killall", "-HUP", "xscreensaver";
            $? == 0 or return [500, "Can't kill -HUP xscreensaver"];
        }
        $ct =~ /^timeout:\s*(\d+):(\d+):(\d+)\s*$/m
            or return [500, "Can't get timeout setting in $path"];
        my $val = ($1*3600+$2*60+$3);
        return [200, "OK", ($which eq 'set' ? undef : $val), {
            'func.timeout' => $val,
            'func.screensaver' => 'xscreensaver',
        }];
    }

    if ($screensaver eq 'kde') {
        my $path;

        {
            $path = "$ENV{HOME}/.kde/share/config/kscreensaverrc";
            log_trace "Checking $path ...";
            unless (-f $path) {
                log_trace "$path doesn't exist";
                last;
            }
            log_trace "$path exists";
            my $ct = File::Slurper::read_text($path);
            if ($which eq 'set') {
                my $secs = $mins*60;
                $ct =~ s/^(Timeout\s*=\s*)(\S+)/${1}$secs/m
                    or return [500, "Can't subtitute Timeout setting in $path"];
                File::Slurper::write_text($path, $ct);
            }
            $ct =~ /^Timeout\s*=\s*(\d+)\s*$/m
                or return [500, "Can't get Timeout setting in $path"];
            my $val = $1;
            return [200, "OK", ($which eq 'set' ? undef : $val), {
                'func.timeout' => $val,
                'func.screensaver'=>'kde-plasma',
            }];
        }

        {
            $path = "$ENV{HOME}/.config/kscreenlockerrc";
            log_trace "Checking $path ...";
            unless (-f $path) {
                log_trace "$path doesn't exist";
                last;
            }
            log_trace "$path exists";
            my $ct = File::Slurper::read_text($path);
            if ($which eq 'set') {
                if ($ct =~ /^Timeout/m) {
                    log_trace "Replacing Timeout setting in $path ...";
                    $ct =~ s/^(Timeout\s*=\s*)(\S+)/${1}$mins/m
                        or return [500, "Can't subtitute Timeout setting in $path"];
                } else {
                    log_trace "Adding Timeout setting in $path ...";
                    $ct .= "\n[Daemon]\nTimeout=$mins\n";
                }
                File::Slurper::write_text($path, $ct);
            }
            my $val;
            if ($ct =~ /^Timeout\s*=\s*(\d+)\s*$/m) {
                $val = $1*60;
                log_trace "Got Timeout setting from $path";
            } else {
                $val = 5*60;
                log_trace "Assuming default of 5 minutes in $path";
            }
            return [200, "OK", ($which eq 'set' ? undef : $val), {
                'func.timeout' => $val,
                'func.screensaver'=>'kde-plasma',
            }];
        }
    }

    [412, "Cannot get/set screensaver timeout (screensaver=$screensaver)"];
}

$SPEC{get_screensaver_timeout} = {
    v => 1.1,
    summary => 'Get screensaver idle timeout, in number of seconds',
    args => {
        %arg_screensaver,
    },
    result => {
        summary => 'Timeout value, in seconds',
        schema  => 'float*',
    },
};
sub get_screensaver_timeout {
    _get_or_set_screensaver_timeout(@_, _which => 'get');
}

$SPEC{set_screensaver_timeout} = {
    v => 1.1,
    summary => 'Set screensaver idle timeout',
    description => <<'MARKDOWN',

* xscreensaver

  To set timeout for xscreensaver, the program finds this line in
  `~/.xscreensaver`:

      timeout:    0:05:00

  modifies the line, save the file, and HUP the xscreensaver process.

* gnome

  To set timeout for gnome screensaver, the program executes this command:

      gsettings set org.gnome.desktop.session idle-delay 300

* cinnamon

  Not yet supported.

* KDE

  To set timeout for the KDE screen locker, the program looks for this line in
  `~/.kde/share/config/kscreensaverrc`:

      Timeout=300

  modifies the line, save the file.

MARKDOWN
    args => {
        %arg_screensaver,
        timeout => {
            summary => 'Value',
            schema => ['duration*'],
            pos => 0,
            completion => sub {
                require Complete::Bash::History;
                my %args = @_;
                Complete::Bash::History::complete_cmdline_from_hist();
            },
        },
    },
    result => {
        summary => 'Timeout value, in seconds',
        schema  => 'float*',
    },
    examples => [
        {
            summary => 'Set timeout to 3 minutes',
            src => '[[prog]] 3min',
            src_plang => 'bash', # because direct function call doesn't grok '3min', coercing is done by perisga-argv
            'x.doc.show_result' => 0,
            test => 0,
        },
        {
            summary => 'Set timeout to 5 minutes',
            argv => [300],
            'x.doc.show_result' => 0,
            test => 0,
        },
    ],
};
sub set_screensaver_timeout {
    my %args = @_;

    my $to = delete $args{timeout} or return get_screensaver_timeout();
    my $mins = int($to/60); $mins = 1 if $mins < 1;

    _get_or_set_screensaver_timeout(%args, _which=>'set', _mins=>$mins);
}

$SPEC{enable_screensaver} = {
    v => 1.1,
    summary => 'Enable screensaver that has been previously disabled',
    args => {
        %arg_screensaver,
    },
};
sub enable_screensaver {
    my %args = @_;
    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'gnome') {
        system "gsettings", "set", "org.gnome.desktop.lockdown", "disable-lock-screen", "false";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    [501, "Not yet implemented except for gnome"];
}

$SPEC{disable_screensaver} = {
    v => 1.1,
    summary => 'Disable screensaver so screen will not go blank or lock after being idle',
    args => {
        %arg_screensaver,
    },
};
sub disable_screensaver {
    my %args = @_;
    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'gnome') {
        system "gsettings", "set", "org.gnome.desktop.lockdown", "disable-lock-screen", "true";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    [501, "Not yet implemented except for gnome"];
}

$SPEC{screensaver_is_enabled} = {
    v => 1.1,
    summary => 'Check whether screensaver is enabled',
    args => {
        %arg_screensaver,
    },
};
sub screensaver_is_enabled {
    my %args = @_;
    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'gnome') {
        my $read = readpipe "gsettings", "get", "org.gnome.desktop.lockdown", "disable-lock-screen";
        if ($?) { return [500, "Failed"] } else { return [200, "OK", $read =~ /false/ ? 1 : $read =~ /true/ ? 0 : undef] }
    }

    [501, "Not yet implemented except for gnome"];
}

$SPEC{activate_screensaver} = {
    v => 1.1,
    summary => 'Activate screensaver immediately and lock screen',
    args => {
        %arg_screensaver,
    },
};
sub activate_screensaver {
    my %args = @_;
    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'kde') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        system $paths[0], "org.kde.screensaver", "/ScreenSaver", "Lock";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    if ($screensaver eq 'gnome') {
        system "gnome-screensaver-command", "-l";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    if ($screensaver eq 'cinnamon') {
        system "cinnamon-screensaver-command", "-l";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    if ($screensaver eq 'xscreensaver') {
        system "xscreensaver-command", "-activate";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    [412, "Unknown screensaver '$screensaver'"];
}

$SPEC{deactivate_screensaver} = {
    v => 1.1,
    summary => 'Deactivate screensaver and unblank the screen',
    description => <<'MARKDOWN',

If screen is not being blank (screensaver is not activated) then nothing
happens. If screen is being blanked (screensaver is activated) then unblank the
screen.

Often the screen is also locked when being blanked. On some screensavers, like
xscreensaver, deactivating won't unlock the screen and user will need to unlock
the screen herself first. Some other screensavers, like GNOME/cinnamon, will
happily unlock the screen automatically.

MARKDOWN
    args => {
        %arg_screensaver,
    },
};
sub deactivate_screensaver {
    my %args = @_;
    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'kde') {
        return [501, "Deactivating screensaver is not supported on kde"];
    }

    if ($screensaver eq 'gnome') {
        system "gnome-screensaver-command", "-d";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    if ($screensaver eq 'cinnamon') {
        system "cinnamon-screensaver-command", "-d";
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    if ($screensaver eq 'xscreensaver') {
        system({capture_stdout=>\my $dummy_stdout},
               "xscreensaver-command", "-deactivate");
        if ($?) { return [500, "Failed"] } else { return [200, "OK"] }
    }

    [412, "Unknown screensaver '$screensaver'"];
}

$SPEC{screensaver_is_active} = {
    v => 1.1,
    summary => 'Check if screensaver is being activated',
    args => {
        %arg_screensaver,
    },
};
sub screensaver_is_active {
    my %args = @_;

    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'kde') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        my $res = `$paths[0] org.kde.screensaver /ScreenSaver GetActive`;
        if ($res =~ /true/) {
            return [200, "OK", 1];
        } elsif ($res =~ /false/) {
            return [200, "OK", 0];
        } else {
            return [500, "Can't check, GetActive gave unknown response '$res'"];
        }
    }

    if ($screensaver eq 'gnome') {
        my $res = `gnome-screensaver-command -q`;
        if ($res =~ /is active/) {
            return [200, "OK", 1];
        } elsif ($res =~ /is inactive/) {
            return [200, "OK", 0];
        } else {
            return [500, "Can't check, -q gave unknown response '$res'"];
        }
    }

    if ($screensaver eq 'cinnamon') {
        my $res = `cinnamon-screensaver-command -q`;
        if ($res =~ /is active/) {
            return [200, "OK", 1];
        } elsif ($res =~ /is inactive/) {
            return [200, "OK", 0];
        } else {
            return [500, "Can't check, -q gave unknown response '$res'"];
        }
    }

    if ($screensaver eq 'xscreensaver') {
        return [501, "This function is not supported by xscreensaver"];
    }

    [412, "Unknown screensaver '$screensaver'"];
}

$SPEC{prevent_screensaver_activated} = {
    v => 1.1,
    summary => 'Prevent screensaver from being activated by resetting idle timer',
    description => <<'MARKDOWN',

You can use this function to prevent screensaver from being activated, if it is
not yet being activated. This is usually done by resetting the idle counter.
With KDE, this is called "simulating user activity". With xscreensaver, one can
use the -deactivate on the CLI.

This function will need to be run periodically and often enough (more often than
the idle timeout period) to actually keep the screensaver from ever being
activated.

If screensaver is already activated, then nothing happens.

MARKDOWN
};
sub prevent_screensaver_activated {
    my %args = @_;

    my $screensaver = $args{screensaver} // detect_screensaver();

    if ($screensaver eq 'kde') {
        my @paths = _find_qdbus();
        die "Can't find qdbus" unless @paths;
        system $paths[0], "org.kde.screensaver", "/ScreenSaver", "SimulateUserActivity";
        return $? ? [500, "Failed"] : [200];
    }

    if ($screensaver eq 'gnome') {
        return [501, "Preventing screensaver from being activated not yet supported on gnome"];
    }

    if ($screensaver eq 'cinnamon') {
        return [501, "Preventing screensaver from being activated not yet supported on cinnamon"];
    }

    if ($screensaver eq 'xscreensaver') {
        system({capture_stdout => \my $dummy_stdout},
               "xscreensaver-command", "-deactivate");
        return $? ? [500, "Failed"] : [200];
    }

    [412, "Unknown screensaver '$screensaver'"];
}

# XXX get_screensaver_active_time (in KDE, we can use GetActiveTime, in xscreensaver -time, in gnome/cinnamon -t)
# XXX get_screensaver_idle_time (in KDE, we can use GetSessionIdleTime, in xscreensaver -time, in gnome/cinnamon -t)

1;
# ABSTRACT: Common interface to screensaver/screenlocker functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Screensaver::Any - Common interface to screensaver/screenlocker functions

=head1 VERSION

This document describes version 0.008 of Screensaver::Any (from Perl distribution Screensaver-Any), released on 2025-04-17.

=head1 DESCRIPTION


This module provides common functions related to screensaver.

Supported screensavers: KDE Plasma's kscreenlocker (C<kde>), GNOME screensaver
(C<gnome>), Cinnamon screensaver (C<cinnamon>), and C<xscreensaver>. Support for
more screensavers, e.g. Windows is more than welcome.

=head1 NOTES

In GNOME 3.8 and later, C<gnome-screensaver> command has been removed (one of
the reasons is consideration of the eventual move to Wayland). Locking/unlocking
screen can be done if you install C<gnome-screensaver> separately, or use other
screensaver like C<xscreensaver>, or use C<gdm> (in which case you can use a
command like C<< dbus-send --type=method_call --dest=org.gnome.ScreenSaver
/org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock >>).

=head1 FUNCTIONS


=head2 activate_screensaver

Usage:

 activate_screensaver(%args) -> [$status_code, $reason, $payload, \%result_meta]

Activate screensaver immediately and lock screen.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 deactivate_screensaver

Usage:

 deactivate_screensaver(%args) -> [$status_code, $reason, $payload, \%result_meta]

Deactivate screensaver and unblank the screen.

If screen is not being blank (screensaver is not activated) then nothing
happens. If screen is being blanked (screensaver is activated) then unblank the
screen.

Often the screen is also locked when being blanked. On some screensavers, like
xscreensaver, deactivating won't unlock the screen and user will need to unlock
the screen herself first. Some other screensavers, like GNOME/cinnamon, will
happily unlock the screen automatically.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 detect_screensaver

Usage:

 detect_screensaver() -> str

Detect which screensaver program is currently running.

Will return a string containing name of screensaver program, e.g. C<kde>,
C<gnome>, C<cinnamon>, C<xscreensaver>. Will return undef if no known screensaver
is detected.

This function is not exported by default, but exportable.

No arguments.

Return value:  (str)



=head2 disable_screensaver

Usage:

 disable_screensaver(%args) -> [$status_code, $reason, $payload, \%result_meta]

Disable screensaver so screen will not go blank or lock after being idle.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 enable_screensaver

Usage:

 enable_screensaver(%args) -> [$status_code, $reason, $payload, \%result_meta]

Enable screensaver that has been previously disabled.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_screensaver_timeout

Usage:

 get_screensaver_timeout(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get screensaver idle timeout, in number of seconds.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value: Timeout value, in seconds (float)



=head2 prevent_screensaver_activated

Usage:

 prevent_screensaver_activated() -> [$status_code, $reason, $payload, \%result_meta]

Prevent screensaver from being activated by resetting idle timer.

You can use this function to prevent screensaver from being activated, if it is
not yet being activated. This is usually done by resetting the idle counter.
With KDE, this is called "simulating user activity". With xscreensaver, one can
use the -deactivate on the CLI.

This function will need to be run periodically and often enough (more often than
the idle timeout period) to actually keep the screensaver from ever being
activated.

If screensaver is already activated, then nothing happens.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 screensaver_is_active

Usage:

 screensaver_is_active(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check if screensaver is being activated.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 screensaver_is_enabled

Usage:

 screensaver_is_enabled(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether screensaver is enabled.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 set_screensaver_timeout

Usage:

 set_screensaver_timeout(%args) -> [$status_code, $reason, $payload, \%result_meta]

Set screensaver idle timeout.

Examples:

=over

=item * Set timeout to 5 minutes:

 set_screensaver_timeout(timeout => 300);

=back

=over

=item * xscreensaver

To set timeout for xscreensaver, the program finds this line in
C<~/.xscreensaver>:

  timeout:    0:05:00

modifies the line, save the file, and HUP the xscreensaver process.

=item * gnome

To set timeout for gnome screensaver, the program executes this command:

  gsettings set org.gnome.desktop.session idle-delay 300

=item * cinnamon

Not yet supported.

=item * KDE

To set timeout for the KDE screen locker, the program looks for this line in
C<~/.kde/share/config/kscreensaverrc>:

  Timeout=300

modifies the line, save the file.

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<screensaver> => I<str>

Explicitly set screensaver program to use.

The default, when left undef, is to detect what screensaver is running,

=item * B<timeout> => I<duration>

Value.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value: Timeout value, in seconds (float)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Screensaver-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Screensaver-Any>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Screensaver-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
