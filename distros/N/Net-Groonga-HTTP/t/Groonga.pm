package t::Groonga;
use strict;
use warnings;
use utf8;

use Test::More;
use Test::TCP;
use File::Which;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);
use Net::Groonga::HTTP;

sub start {
    my $class = shift;
    plan skip_all => "Missing groonga" unless which('groonga');

    my $tmpdir = tempdir(CLEANUP => 0);
    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            exec 'groonga', '-s', '--protocol' => 'http', '--port', $port, '--bind-address' => '127.0.0.1', '-n', "$tmpdir/test.db";
            die $!;
        }
    );
    bless {
        tmpdir => $tmpdir,
        server => $server,
    }, $class;
}

sub client {
    my $self = shift;
    my $port = $self->port;
    return Net::Groonga::HTTP->new(
        end_point => "http://127.0.0.1:$port/d/"
    );
}

sub port { $_[0]->{server}->port }

sub DESTROY {
    my $self = shift;
    rmtree($self->{tmpdir});
}

1;

