package Plack::Middleware::DBGp;

=head1 NAME

Plack::Middleware::DBGp - interactive debugging for Plack applications

=head1 SYNOPSIS

    # should be the first/one of the first modules to be loaded
    use Plack::Middleware::DBGp (
        remote_host => "localhost:9000",
    );
    use Plack::Builder;

    builder {
        enable "DBGp";
        $app;
    };

=head1 DESCRIPTION

Add interactive debugging support via the
L<DBGp protocol|http://xdebug.org/docs-dbgp.php> to L<Plack> applications.

When debugging, the debugger running inside the application
establishes a connection to an external DBGp client (typically a GUI
program) that allows to inspect the program state from the outside.

C<Plack::Middleware::DBGp> has been tested with
This implementation has been tested with L<pugdebug|http://pugdebug.com>,
L<Sublime Text Xdebug plugin|https://github.com/martomo/SublimeTextXdebug>
and L<Vim VDebug plugin|https://github.com/joonty/vdebug>.

=head1 LOADING

The Perl debugger needs to be enabled early during compilation,
therefore this middleware needs to be loaded explicitly near the top
of the main F<.psgi> file of the application. All files loaded before
the debugger won't be debuggable (unless L<Enbugger> is present and
enabled).

Supported parameters

=over 4

=item remote_host

    use Plack::Middleware::DBGp (
        remote_host => "host:port",
    );

Hostname/port the debugger should connect to.

=item user, client_dir, client_socket

    use Plack::Middleware::DBGp (
        user            => 'Unix login',
        client_dir      => '/path/to/dir',
        client_socket   => '/path/to/dir/and_socket',
    );

Unix-domain socket the debugger should connect to. The directory must
be present, must be owned by the specified user and the group under
which the web server is running, and it must not be
world-readable/writable.

The C<user> and C<client_dir> parameters are optional, and used for
extra sanity checks.

=item autostart

    use Plack::Middleware::DBGp (
        autostart   => [0|1],
    );

Whether the debugger should try connect to the debugger client on
every request; see also L</HTTP INTERFACE>.

=item ide_key

    use Plack::Middleware::DBGp (
        ide_key     => "DBGp ide key",
    );

The IDE key, as defined by the DBGp protocol. Only used when
C<autostart> is in effect.

=item cookie_expiration

    use Plack::Middleware::DBGp (
        cookie_expiration   => <seconds>,
    );

C<XDEBUG_SESSION> cookie expiration time, in seconds. See L</HTTP INTERFACE>.

=item debug_startup

    use Plack::Middleware::DBGp (
        debug_startup   => [0|1],
    );

Whether the debugger should try to connect to the debugger client as
soon as it is loaded, during application startup.

=item log_path

    use Plack::Middleware::DBGp (
        log_path    => '/path/to/debugger.log',
    );

When set, will write debugging information from the debugger to the
sepcified path.

=item enbugger

    use Plack::Middleware::DBGp (
        enbugger    => [0|1],
    );

Use L<Enbugger>. At the moment it only enables debugging all files,
even the ones loaded before C<Plack::Middleware::DBGp>.

=item debug_client_path

    use Plack::Middleware::DBGp (
        debug_client_path   => '/path/to/dbgp-enabled/debugger',
    );

Use a L<Devel::Debug::DBGp> installed outside the default module
search path.

=back

=head1 HTTP INTERFACE

When C<autostart> is disabled, C<Plack::Middleware::DBGp> emulates the
L<Xdebug browser
session|http://xdebug.org/docs/remote#browser_session> interface.

The C<XDEBUG_SESSION_START=idekey> GET/POST parameter starts a
debugging session and sets the C<XDEBUG_SESSION> cookie.

When the C<XDEBUG_SESSION> cookie is set, the debugger tries to
connect to the debugger client passing the sepcified IDE key.

The C<XDEBUG_SESSION_STOP> GET/POST parameter clears the
C<XDEBUG_SESSION> cookie.

=cut

use strict;
use warnings;

our $VERSION = '0.13';

use constant {
    DEBUG_SINGLE_STEP_ON        =>  0x20,
    DEBUG_USE_SUB_ADDRESS       =>  0x40,
    DEBUG_REPORT_GOTO           =>  0x80,
    DEBUG_ALL                   => 0x7ff,
};

use constant {
    DEBUG_OFF                   => 0x0,
    DEBUG_DEFAULT_FLAGS         => # 0x73f
        DEBUG_ALL & ~(DEBUG_USE_SUB_ADDRESS|DEBUG_REPORT_GOTO),
    DEBUG_PREPARE_FLAGS         => # 0x73c
        DEBUG_ALL & ~(DEBUG_USE_SUB_ADDRESS|DEBUG_REPORT_GOTO|DEBUG_SINGLE_STEP_ON),
};

our @ISA;

my ($autostart, $idekey, $cookie_expiration);

# Unable to connect to Unix socket: /var/run/dbgp/uwsgi (No such file or directory)
# Running program outside the debugger...
sub _trap_connection_warnings {
    return if $_[0] =~ /^Unable to connect to Unix socket: /;
    return if $_[0] =~ /^Unable to connect to remote host: /;
    return if $_[0] =~ /^Running program outside the debugger/;

    print STDERR $_[0];
}

sub import {
    my ($class, %args) = @_;

    die "Specify either 'remote_host' or 'client_socket'"
        unless $args{remote_host} || $args{client_socket};

    $args{debug_client_path} //= do {
        require Devel::Debug::DBGp;

        Devel::Debug::DBGp->debugger_path;
    };

    $autostart = $args{autostart} // 1;
    $idekey = $args{ide_key};
    $cookie_expiration = $args{cookie_expiration} // 3600;

    my %options = (
          Xdebug         => 1,
          KeepRunning    => 1,
          ConnectAtStart => ($args{debug_startup} ? 1 : 0),
        ( LogFile        => $args{log_path} ) x !!$args{log_path},
    );

    if (!$args{remote_host}) {
        my $error;
        my ($user, $dbgp_client_dir) = @args{qw(user client_dir)};
        my $group = getgrnam($)) || (split / /, $))[0];

        if (!$user || !$dbgp_client_dir) {
            # pass through and hope for the best
        } elsif (-d $dbgp_client_dir) {
            my ($mode, $uid, $gid) = (stat($dbgp_client_dir))[2, 4, 5];
            my $user_id = getpwnam($user) || die "Can't retrieve the UID for $user";

            $error = sprintf "invalid UID %d, should be %d", $uid, $user_id
                unless $uid == $user_id;
            $error = sprintf "invalid GID %d, should be %d", $gid, $)
                unless $gid == $);
            $error = sprintf "invalid permissions bits %04o, should be 0770", $mode & 0777
                unless ($mode & 0777) == 0770;
        } else {
            $error = "directory not found";
        }

        if ($error) {
            print STDERR <<"EOT";
There was the following issue with the DBGp client directory '$dbgp_client_dir': $error

You can fix it by running:
\$ sudo sh -c 'rm -rf $dbgp_client_dir &&
      mkdir $dbgp_client_dir &&
      chmod 2770 $dbgp_client_dir &&
      chown $user:$group $dbgp_client_dir'
EOT
            exit 1;
        }

        $options{RemotePath} = $args{client_socket};
    } else {
        $options{RemotePort} = $args{remote_host};
    }

    $ENV{PERLDB_OPTS} =
        join " ", map +(sprintf "%s=%s", $_, $options{$_}),
                      sort keys %options;

    if ($args{enbugger}) {
        require Enbugger;

        Enbugger->VERSION(2.014);
        Enbugger->load_source;
    }

    my $inc_path = $args{debug_client_path};
    unshift @INC, ref $inc_path ? @$inc_path : $inc_path;
    {
        local $SIG{__WARN__} = \&_trap_connection_warnings;
        require 'perl5db.pl';
    }

    $^P = DEBUG_PREPARE_FLAGS;

    require Plack::Middleware;
    require Plack::Request;
    require Plack::Response;
    require Plack::Util;

    @ISA = qw(Plack::Middleware);
}

sub reopen_dbgp_connection {
    local $SIG{__WARN__} = \&_trap_connection_warnings;
    DB::connectOrReconnect();
    DB::enable() if DB::isConnected();
}

sub close_dbgp_connection {
    DB::answerLastContinuationCommand('stopped');
    DB::disconnect();
    DB::disable();
    # this works around uWSGI bug fixed by
    # https://github.com/unbit/uwsgi/commit/c6f61719106908b82ba2714fd9d2836fb1c27f22
    $^P = DEBUG_OFF;
}

sub call {
    my($self, $env) = @_;

    my ($stop_session, $start_session, $debug_idekey);
    if ($autostart) {
        $ENV{DBGP_IDEKEY} = $idekey if defined $idekey;

        reopen_dbgp_connection();
    } else {
        my $req = Plack::Request->new($env);
        my $params = $req->parameters;
        my $cookies = $req->cookies;
        my $debug;

        if (exists $params->{XDEBUG_SESSION_STOP}) {
            $stop_session = 1;
        } elsif (exists $params->{XDEBUG_SESSION_START}) {
            $debug_idekey = $params->{XDEBUG_SESSION_START};
            $debug = $start_session = 1;
        } elsif (exists $cookies->{XDEBUG_SESSION}) {
            $debug_idekey = $cookies->{XDEBUG_SESSION};
            $debug = 1;
        }

        if ($debug) {
            $ENV{DBGP_IDEKEY} = $debug_idekey;
            reopen_dbgp_connection();
        }
    }

    my $res = $self->app->($env);

    if ($start_session || $stop_session) {
        $res = Plack::Response->new(@$res);

        if ($start_session) {
            $res->cookies->{XDEBUG_SESSION} = {
                value   => $debug_idekey,
                expires => time + $cookie_expiration,
            };
        } elsif ($stop_session) {
            $res->cookies->{XDEBUG_SESSION} = {
                value   => undef,
                expires => time - 24 * 60 * 60,
            };
        }

        $res = $res->finalize;
    }

    Plack::Util::response_cb($res, sub {
        return sub {
            # use $_[0] to try to avoid a copy
            if (!defined $_[0] && DB::isConnected()) {
                close_dbgp_connection();
            }

            return $_[0];
        };
    });
}

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2015-2016 Mattia Barbon. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
