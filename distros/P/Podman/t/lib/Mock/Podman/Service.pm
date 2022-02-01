package Mock::Podman::Service;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious';
use Mojo::Server::Daemon;
use Mojo::IOLoop;
use Mojo::Util ();
use Mojo::URL;

has Pid    => sub { return; };
has Listen => sub {
    return sprintf "http+unix://%s/podman.sock",
      $ENV{XDG_RUNTIME_DIR} ? $ENV{XDG_RUNTIME_DIR} : '/tmp';
};

$ENV{MOJO_LOG_LEVEL} ||= $ENV{HARNESS_IS_VERBOSE} ? 'trace' : 'fatal';

sub startup {
    my $Self = shift;

    $Self->hook(
        after_build_tx => sub {
            my $Transaction = shift;

            return $Transaction->res->headers->header(
                'Content-Type' => 'Application/JSON' );
        }
    );

    $Self->secrets('dedf9c3d-93ca-42ca-9ee7-82bc1d625c61');
    $Self->routes->any('/*route')->to('Routes#Any');
    $Self->renderer->classes( ['Mock::Podman::Service::Routes'] );

    return;
}

sub Start {
    my ( $Self, $Listen ) = @_;

    $Listen = $Self->Listen;
    $Listen = Mojo::URL->new($Listen);
    if ( $Listen->scheme eq 'http+unix' ) {
        $Listen = Mojo::URL->new(
            $Listen->scheme . '://' . Mojo::Util::url_escape( $Listen->path ) );
    }

    my $Daemon = Mojo::Server::Daemon->new(
        app    => $Self,
        listen => [ $Listen->to_string ],
        silent => $ENV{MOJO_LOG_LEVEL} ne 'fatal' ? 1 : 0,
    );

    my $Pid = fork;
    if ( !$Pid ) {
        $Daemon->start;
        Mojo::IOLoop->start if !Mojo::IOLoop->is_running;

        return;
    }

    $Self->Pid($Pid);

    return;
}

sub Stop {
    my $Self = shift;

    kill 'KILL', $Self->Pid if $Self->Pid;
    waitpid $Self->Pid, 0;

    return;
}

1;
