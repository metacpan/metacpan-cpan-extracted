package Salvation::AnyNotify::Plugin::Daemon;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use Salvation::DaemonDecl;
use Salvation::Method::Signatures;
use Salvation::DaemonDecl::Backend ();

our $VERSION = 0.02;

method start() {

    $self -> { 'queue' } = [];
}

method enqueue( CodeRef|Str code ) {

    push( @{ $self -> { 'queue' } }, $code );

    return;
}

method run() {

    my $daemon_meta = $self -> daemon_meta();

    Salvation::DaemonDecl::Backend -> add_worker( $daemon_meta, {
        name 'main',
        max_instances 1,
        log {
            warn @_;
        },
        ro,
        main {
            my ( $worker ) = @_;
            my $core = $self -> core();

            while( defined( my $code = shift( @{ $self -> { 'queue' } } ) ) ) {

                eval{ $core -> $code() };

                warn $@ if $@;
            }

            Salvation::DaemonDecl::Backend -> wait_all_workers( $self -> daemon_meta() );
        },
    } );

    Salvation::DaemonDecl::Backend -> daemon_main( $daemon_meta, 'main' );
}

method daemon_meta() {

    return Salvation::DaemonDecl::Backend -> get_meta( ref( $self -> core() ) );
}

1;

__END__
