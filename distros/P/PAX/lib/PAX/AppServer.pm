package PAX::AppServer;

our $VERSION = '0.031';

use strict;
use warnings;
use IO::Socket::UNIX;
use JSON::PP qw(decode_json);
use POSIX qw(setsid);
use PAX::AppImage;

sub new {
    my ($class, %args) = @_;
    return bless {
        image => $args{image} // die('image required'),
    }, $class;
}

sub start {
    my ($self, %args) = @_;
    return $self->_daemonize if $args{daemonize};
    return $self->_serve;
}

sub run_client {
    my ($class, %args) = @_;
    my $image = $args{image} // die 'image required';
    my $argv = $args{argv} // [];
    my $socket = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $image->{socket_path},
    );
    if (!$socket) {
        return _direct_exec($image, $argv);
    }
    my $request = JSON::PP->new->ascii(1)->canonical(1)->encode({
        argv => $argv,
        cwd => $args{cwd} // _cwd(),
    });
    print {$socket} "$request\n";
    my $exit = 0;
    while (defined(my $line = <$socket>)) {
        if ($line =~ /^__PAX_EXIT__:(\d+)/) {
            $exit = $1 + 0;
            last;
        }
        print $line;
    }
    close $socket;
    return $exit;
}

sub stop {
    my ($class, %args) = @_;
    my $image = $args{image} // die 'image required';
    my $socket = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Peer => $image->{socket_path},
    ) or return 1;
    print {$socket} "{\"control\":\"stop\"}\n";
    close $socket;
    return 0;
}

sub _serve {
    my ($self) = @_;
    my $image = $self->{image};
    _prepare_runtime($image);
    my $preload = _preload_modules($image);
    unlink $image->{socket_path} if -e $image->{socket_path};
    my $server = IO::Socket::UNIX->new(
        Type => SOCK_STREAM,
        Local => $image->{socket_path},
        Listen => 20,
    ) or die "cannot listen on $image->{socket_path}: $!";
    chmod 0600, $image->{socket_path};
    local $SIG{TERM} = sub { unlink $image->{socket_path}; exit 0 };
    local $SIG{INT} = sub { unlink $image->{socket_path}; exit 0 };

    while (my $client = $server->accept) {
        my $line = <$client>;
        if (!defined $line) {
            close $client;
            next;
        }
        my $request = eval { decode_json($line) } // {};
        if (($request->{control} // '') eq 'stop') {
            print {$client} "__PAX_EXIT__:0\n";
            close $client;
            last;
        }
        _run_request($image, $client, $request);
        close $client;
    }
    close $server;
    unlink $image->{socket_path};
    return 0;
}

sub _daemonize {
    my ($self) = @_;
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    return 0 if $pid;
    setsid();
    open STDIN, '<', '/dev/null';
    open STDOUT, '>', "$self->{image}{app_dir}/server.log";
    open STDERR, '>&', \*STDOUT;
    $self->_serve;
    exit 0;
}

sub _run_request {
    my ($image, $client, $request) = @_;
    my $pid = fork();
    if (!defined $pid) {
        print {$client} "fork failed: $!\n__PAX_EXIT__:111\n";
        return;
    }
    if ($pid == 0) {
        open STDOUT, '>&', $client;
        open STDERR, '>&', $client;
        my $cwd = $request->{cwd} // '.';
        chdir $cwd if -d $cwd;
        local @ARGV = @{ $request->{argv} // [] };
        local $0 = $image->{entrypoint};
        $ENV{PAX_APP_IMAGE} = $image->{name};
        my $ok = do $image->{entrypoint};
        if (!$ok) {
            print STDERR defined $@ && length $@ ? $@ : "failed to run $image->{entrypoint}: $!\n";
            exit 111;
        }
        exit 0;
    }
    waitpid($pid, 0);
    my $exit = $? >> 8;
    print {$client} "__PAX_EXIT__:$exit\n";
}

sub _prepare_runtime {
    my ($image) = @_;
    my @libs = @{ $image->{lib_dirs} // [] };
    unshift @INC, grep { -d $_ && !_in_inc($_) } @libs;
    if (@libs) {
        require Config;
        my $sep = $Config::Config{path_sep} || ':';
        my @existing = grep { defined && length } split /\Q$sep\E/, ($ENV{PERL5LIB} // '');
        $ENV{PERL5LIB} = join $sep, @libs, @existing;
    }
}

sub _preload_modules {
    my ($image) = @_;
    my @loaded;
    for my $module (@{ $image->{preload_modules} // [] }) {
        next if $module !~ /\A[A-Za-z_][A-Za-z0-9_:]*\z/;
        my $ok = eval "require $module; 1";
        push @loaded, $module if $ok;
    }
    return \@loaded;
}

sub _direct_exec {
    my ($image, $argv) = @_;
    _prepare_runtime($image);
    my $pid = fork();
    die "fork failed: $!" if !defined $pid;
    if ($pid == 0) {
        my @cmd = ($^X, $image->{entrypoint}, @$argv);
        no warnings 'exec';
        exec { $cmd[0] } @cmd;
        print STDERR "exec failed: $!\n";
        exit 111;
    }
    waitpid($pid, 0);
    return $? >> 8;
}

sub _in_inc {
    my ($path) = @_;
    for my $inc (@INC) {
        return 1 if $inc eq $path;
    }
    return 0;
}

sub _cwd {
    require Cwd;
    return Cwd::getcwd();
}

1;

=pod

=head1 NAME

PAX::AppServer - fork server and request bridge for packaged app images

=head1 SYNOPSIS

  use PAX::AppServer;

  my $obj = PAX::AppServer->new(...);
  my $result = $obj->start(...);

=head1 DESCRIPTION

Runs the prefork application image server that accepts launcher requests, prepares the Perl runtime, and falls back to direct execution when the socket path is unavailable.

=head1 METHODS

=head2 new, start, run_client, stop

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the fork server and request bridge for packaged app images logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs fork server and request bridge for packaged app images. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects fork server and request bridge for packaged app images, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover fork server and request bridge for packaged app images.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::AppServer -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
