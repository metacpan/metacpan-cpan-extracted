package t::SCGIUtils;
use strict;
use warnings;
use File::Temp ();
use FindBin;
use Test::More;
use IO::Socket;
use File::Spec;
use Test::TCP qw/test_tcp empty_port/;
use parent qw/Exporter/;

our @EXPORT = qw/ test_lighty_external test_scgi_standalone /;

# test for SCGI External Server
sub test_lighty_external (&@) {
    my ($callback, $lighty_port, $scgi_port) = @_;

    $lighty_port ||= empty_port();
    $scgi_port   ||= empty_port($lighty_port);

    my $lighttpd_bin = $ENV{LIGHTTPD_BIN} || `which lighttpd`;
    chomp $lighttpd_bin;

    plan skip_all => 'Please set LIGHTTPD_BIN to the path to lighttpd'
        unless $lighttpd_bin && -x $lighttpd_bin;

    my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

    test_tcp(
        client => sub {
            $callback->($lighty_port, $scgi_port);
            warn `cat $tmpdir/error.log` if $ENV{DEBUG};
        },
        server => sub {
            my $conffname = File::Spec->catfile($tmpdir, "lighty.conf");
            _write_file($conffname => _render_conf($tmpdir, $lighty_port, $scgi_port));

            my $pid = open my $lighttpd, "$lighttpd_bin -D -f $conffname 2>&1 |" 
                or die "Unable to spawn lighttpd: $!";
            $SIG{TERM} = sub {
                kill 'INT', $pid;
                close $lighttpd;
                exit;
            };
            sleep 60; # waiting tests.
            die "server timeout";
        },
        port => $lighty_port,
    );
}

sub _write_file {
    my ($fname, $src) = @_;
    open my $fh, '>', $fname or die $!;
    print {$fh} $src or die $!;
    close $fh;
}

sub _render_conf {
    my ($tmpdir, $port, $scgiport) = @_;
    <<"END";
# basic lighttpd config file for testing scgi(external server)+Plack
server.modules += ("mod_scgi")

server.document-root = "$tmpdir"

server.bind = "127.0.0.1"
server.port = $port

scgi.server = (
    "" => ((
            "check-local"     => "disable",
            "host"            => "127.0.0.1",
            "port"            => $scgiport,
            "idle-timeout"    => 20,
    ))
)
END
}

1;
