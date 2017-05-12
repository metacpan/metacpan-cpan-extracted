#!/usr/bin/env perl -w
use strict;
use warnings;
use Carp       qw( croak   );
use Test::More qw( no_plan );
use Data::Dumper;

use Sys::Info::Driver::Linux::OS::Distribution;

ok( my $distro  = Sys::Info::Driver::Linux::OS::Distribution->new, 'Got the object' );
ok( my $name    = $distro->name,    'Got a name'    );
ok( my $version = $distro->version, 'Got a version' );

diag Dumper {
    distro  => $distro,
    name    => $name,
    version => $version,
};

dump_if_exists( '/etc/lsb-release' );

sub dump_if_exists {
    my $file = shift;
    return if ! -e $file;
    diag('DEBUG');
    diag("[DUMPING] $file");
    diag( slurp( $file ) );
    return;
}

sub slurp {
    my $file = shift || croak 'File parameter is missing';
    require IO::File;
    my $FH = IO::File->new;
    $FH->open( $file, '<' ) or croak "Can't open FH ($file) for reading: $!";
    my $rv = do { local $/; <$FH> };
    $FH->close;
    return $rv;
}

1;
