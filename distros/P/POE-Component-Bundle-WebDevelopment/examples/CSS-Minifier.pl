#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{lib  ../lib};
use POE qw/Component::CSS::Minifier/;

die "Usage: $0 [URL or filename of CSS file to minify]\n"
    unless @ARGV;

my $In_File = shift;
my $Out_File = 'out_' . time() . '.css';

my $poco = POE::Component::CSS::Minifier->spawn(
    ua_args => { agent => 'Firefox' },
);

POE::Session->create( package_states => [ main => [qw(_start results)] ], );

$poe_kernel->run;

sub _start {
    $poco->minify({
            event => 'results',
            outfile => $Out_File,
            (
                $In_File =~ m{^https?://}
                ? ( uri     => $In_File, )
                : ( infile  => $In_File, )
            ),
    });
}

sub results {
    if ( defined $_[ARG0]->{error} ) {
        print "Error: $_[ARG0]->{error}\n";
    }
    else {
        print "Minified CSS saved in file $_[ARG0]->{outfile}\n";

    $poco->shutdown;
}