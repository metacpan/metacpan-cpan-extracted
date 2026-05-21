package QDTest;
use strict;
use warnings;
use Exporter 'import';
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Copy ();
use IO::Socket::INET;
use Cwd qw(abs_path);
use POSIX ":sys_wait_h";

our @EXPORT_OK = qw(
    repo_root
    pick_port
    setup_abs_fixtures
    setup_perm_dirs
    start_daemon
    stop_daemon
);

# Locate the repo root from this file's path
sub repo_root {
    my $here = abs_path(__FILE__);
    $here =~ s{/t/lib/QDTest\.pm$}{};
    return $here;
}

sub pick_port {
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "pick_port: $!";
    my $port = $sock->sockport;
    $sock->close;
    return $port;
}

sub _copy_tree {
    my ( $src, $dst ) = @_;
    my $src_mode = ( stat $src )[2] & 07777;
    make_path($dst);
    chmod $src_mode, $dst or die "chmod $dst: $!";
    opendir my $dh, $src or die "opendir $src: $!";
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' or $entry eq '..';
        my ( $s, $d ) = ( "$src/$entry", "$dst/$entry" );
        if ( -d $s ) { _copy_tree( $s, $d ); }
        else {
            File::Copy::copy( $s, $d ) or die "copy $s -> $d: $!";
            my $file_mode = ( stat $s )[2] & 07777;
            chmod $file_mode, $d or die "chmod $d: $!";
        }
    }
    closedir $dh;
}

# Copy t/fixtures into a temp dir, rewriting users/assign paths to absolute.
# Returns the absolute path to the new fixtures root.
sub setup_abs_fixtures {
    my $root = repo_root();
    my $tmp  = tempdir( CLEANUP => 1 );
    _copy_tree( "$root/t/fixtures", "$tmp/fixtures" );

    my $assign = "$tmp/fixtures/users/assign";
    open my $in, '<', $assign or die "open $assign: $!";
    my @lines = <$in>;
    close $in;
    for (@lines) {
        s{t/fixtures/domains/}{$tmp/fixtures/domains/}g;
    }
    open my $out, '>', $assign or die "open > $assign: $!";
    print {$out} @lines;
    close $out;

    return "$tmp/fixtures";
}

# Create homedirs with non-default modes for 0x21/0x22/0x11 testing.
sub setup_perm_dirs {
    my ($base) = @_;
    make_path("$base/domains/$_") for qw(perms775 permssticky noread);
    chmod 0775,  "$base/domains/perms775";
    chmod 01755, "$base/domains/permssticky";
    chmod 0000,  "$base/domains/noread";
}

# Fork a qmail-deliverabled child against the given absolute fixtures dir.
# Retries on port conflict. Returns (pid, port).
sub start_daemon {
    my (%opts)    = @_;
    my $qmail_dir = $opts{qmail_dir} or die "qmail_dir required";
    my $pidfile   = $opts{pidfile};                                 # optional
    my $root      = repo_root();

    for my $attempt ( 1 .. 5 ) {
        my $port = pick_port();
        my $pid  = fork;
        die "fork: $!" if not defined $pid;

        if ( $pid == 0 ) {
            @ARGV = ( '--foreground', '--listen', "127.0.0.1:$port" );
            push @ARGV, '--pidfile', $pidfile if $pidfile;
            $Qmail::Deliverable::qmail_dir = $qmail_dir;
            Qmail::Deliverable::reread_config();
            $opts{pre_hook}->() if $opts{pre_hook};
            do "$root/bin/qmail-deliverabled";
            warn "daemon exited: $@" if $@;
            exit 1;
        }

        for ( 1 .. 50 ) {
            my $waited = waitpid $pid, WNOHANG;
            last if $waited == $pid;    # child died early
            my $s = IO::Socket::INET->new(
                PeerAddr => "127.0.0.1:$port",
                Timeout  => 1,
            );
            if ($s) { $s->close; return ( $pid, $port ); }
            select undef, undef, undef, 0.1;
        }

        kill 9, $pid;
        waitpid $pid, 0;
    }
    die "could not start daemon after 5 attempts";
}

sub stop_daemon {
    my ($pid) = @_;
    return unless $pid;
    local $?;    # don't leak the child's signal status to our own exit
    kill 15, $pid;
    my $deadline = time + 5;
    while ( time < $deadline ) {
        my $r = waitpid $pid, WNOHANG;
        return if $r == $pid;
        select undef, undef, undef, 0.05;
    }
    kill 9, $pid;
    waitpid $pid, 0;
}

1;
