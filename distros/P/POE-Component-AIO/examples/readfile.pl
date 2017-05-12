#!/usr/bin/perl

use POE;

use strict;
use warnings;

Foo->new();

$poe_kernel->run();



package Foo;

use POE qw( Component::AIO );
use Fcntl;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = bless( {}, $class );

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                _stop

                open_done
                read_done
            )]
        ]
    );
  
    return $self;
}

sub _start {
    my $file = '/etc/passwd';
    print "started\n";
    aio_open( $file, O_RDONLY, 0, $poco_aio->callback( 'open_done', $file ) );
}

sub open_done {
    my ( $self, $session, $file, $fh ) = @_[ OBJECT, SESSION, ARG0, ARG1 ];
    
    unless ( defined $fh ) {
        die "aio open failed on $file: $!";
    }
    
    print "opened $file\n";


    my $buffer = '';
    aio_read( $fh, 0, 1024, $buffer, 0, $poco_aio->postback( 'read_done', \$buffer ) );
}

sub read_done {
    my ( $self, $buffer, $bytes ) = @_[ OBJECT, ARG0, ARG1 ];

    unless( $bytes > 0 ) {
        die "aio read failed: $!";
    }

    print "read done, buffer:\n$$buffer\n";
}

sub _stop {
    $poco_aio->shutdown();
}
