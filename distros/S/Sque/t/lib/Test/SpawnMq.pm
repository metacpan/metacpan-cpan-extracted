package Test::SpawnMq;
use strict;
use warnings;
# Only have this for build deps, so we have mq.pl
use POE::Component::MessageQueue;
use POSIX ":sys_wait_h";
use Capture::Tiny qw( capture );

use base qw( Exporter );

our @EXPORT = qw( mq );

sub mq {
    my $port = 11011 + ( $$ % 127 );
    return ( spawn( $port ), "127.0.0.1:$port" );
}

sub spawn {
    my ( $port ) = @_;
    my $data_dir = ".perl_mq";

    if (my $pid = fork) {
        sleep 3;
        return sub {
            kill(15, $pid);
            my $try = 0;
            while ($try++ < 10) {
                my $ok = waitpid($pid, WNOHANG);
                $try = -1, last if $ok > 0;
                sleep 1;
            }
            system "rm -rf $data_dir";
        };
    } elsif (defined $pid) {
        system "rm -rf $data_dir";
        Capture::Tiny::capture {
            exec "mq.pl --port $port --data-dir $data_dir";
        }
    }

    die "Could not fork(): $!";
}

1;

