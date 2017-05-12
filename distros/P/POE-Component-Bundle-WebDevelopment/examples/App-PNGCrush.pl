#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib  ../lib};

die "Usage: perl crush.pl <fileS_to_crush>\n"
    unless @ARGV;

use POE qw(Component::App::PNGCrush);

my $poco = POE::Component::App::PNGCrush->spawn(debug=>1);

POE::Session->create(
    package_states => [ main => [qw(_start crushed)] ],
);

$poe_kernel->run;

sub _start {
    $poco->run( {
            in      => [ @ARGV ],
            options => [
                qw( -d OUT_DIR -brute 1 ),
                remove  => [ qw( gAMA cHRM sRGB iCCP ) ],
            ],
            event   => 'crushed',
        }
    );
}

sub crushed {
    my $in_ref = $_[ARG0];

    my $proc_ref = $in_ref->{out};
    for ( keys %$proc_ref ) {
        if ( exists $proc_ref->{$_}{error} ) {
            print "Got error on file $_ : $proc_ref->{$_}{error}\n";
        }
        else {
            printf "Stats for file %s\n\tSize reduction: %.2f%%\n\t"
                    . "IDAT reduction: %.2f%%\n",
                    $_, @{ $proc_ref->{$_} }{ qw(size idat) };
        }
    }

    $poco->shutdown;
}