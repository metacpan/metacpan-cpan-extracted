#
# vim: set syntax=perl
use warnings;
use strict;

use Test::More tests => 7;

BEGIN {
    use_ok 'POE';
    use_ok 'IO::AIO';
    use_ok 'POE::Component::AIO';
}

PoCo::AIO::Test->new();

$poe_kernel->run();


package PoCo::AIO::Test;

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
    my $file = $ENV{PWD}.'/Makefile.PL';
    Test::More::pass("started, opening $file");
    
    aio_open( $file, O_RDONLY, 0, $poco_aio->callback( 'open_done', $file ) );
}

sub open_done {
    my ( $self, $session, $file, $fh ) = @_[ OBJECT, SESSION, ARG0, ARG1 ];
    my $id = $session->ID();
    
    unless ( defined $fh ) {
        Test::More::fail("aio open failed on $file: $!");
        return;
    }
    
    Test::More::pass("opened $file, going to read");

    $self->{buffer} = '';
    
    aio_read( $fh, 0, 1024, $self->{buffer}, 0, $poco_aio->postback( [ $id, 'read_done' ] ) );
}

sub read_done {
    my ( $self, $bytes ) = @_[ OBJECT, ARG0 ];

    unless( $bytes > 0 ) {
        Test::More::fail("aio read failed: $!");
        return;
    }

    # XXX compare bytes with buffer len?
    
    Test::More::pass("read file: $bytes bytes");
}

sub _stop {
    Test::More::pass('done!');
    $poco_aio->shutdown();
}

1;
