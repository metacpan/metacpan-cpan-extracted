#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(lib ../lib);
use POE qw(Component::WWW::DoingItWrongCom::RandImage);

my $Total_pics_to_get = shift || 1;
my $Pics_gotten = 0;

POE::Component::WWW::DoingItWrongCom::RandImage->spawn( alias => 'wrong' );

POE::Session->create(
    package_states => [
        main => [ qw( _start  got_pic ) ],
    ],
);

$poe_kernel->run;

sub _start {
    $_[KERNEL]->post( wrong => fetch => {
            event => 'got_pic',
            _num => $_,
        },
    )
        for 1 .. $Total_pics_to_get;
}

sub got_pic {
    my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];

    if ( $input->{error} ) {
        print "ERROR: $input->{error}\n";
    }
    else {
        print "[$input->{_num}] You are doing it wrong: $input->{out}\n";
    }

    if ( ++$Pics_gotten >= $Total_pics_to_get ) {
         $kernel->post( wrong => 'shutdown' );
    }
}

__END__

