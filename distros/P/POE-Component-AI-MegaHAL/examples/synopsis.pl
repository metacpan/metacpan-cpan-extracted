    use strict;
    use POE qw(Component::AI::MegaHAL);

    $|=1;

    my $poco = POE::Component::AI::MegaHAL->spawn( autosave => 1, debug => 0,
                                                   path => '.', options => { trace => 0 } );

    POE::Session->create(
        package_states => [
                'main' => [ qw(_start _got_reply) ],
        ],
    );

    $poe_kernel->run();
    exit 0;

    sub _start {
        $_[KERNEL]->post( $poco->session_id() => do_reply => { text => 'What is a MegaHAL ?', event => '_got_reply' } );
        undef;
    }

    sub _got_reply {
        print STDOUT $_[ARG0]->{reply} . "\n";
        $_[KERNEL]->post( $poco->session_id() => 'shutdown' );
        undef;
    }
