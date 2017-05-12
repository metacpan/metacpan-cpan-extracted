#!perl

# testing with packed scripts

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use File::Temp qw(tempfile);
use Test::More 0.98;
use Test::Needs 'App::depak';

my ($tempfh, $tempname) = tempfile();

subtest fatpack => sub {
    require App::depak;

    my $res = App::depak::depak(
        pack_method => "fatpack",
        include_module => ["Local::Foo", "Local::Bar"],
        input_file => "$Bin/bin/test-module-installed.pl",
        output_file => $tempname,
        overwrite => 1,
        trace_method => "fatpacker",
    );
    die "Can't create packed script (fatpack): $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    my $output = `$^X $tempname`;
    like($output, qr/^installed1.*^installed2.*NOT-INSTALLED3/ms);
};

subtest datapack => sub {
    require App::depak;

    my $res = App::depak::depak(
        pack_method => "datapack",
        include_module => ["Local::Foo", "Local::Bar"],
        input_file => "$Bin/bin/test-module-source.pl",
        output_file => $tempname,
        overwrite => 1,
        trace_method => "fatpacker",
    );
    die "Can't create packed script (datapack): $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    my $output = `$^X $tempname`;
    like($output, qr/package Local::Foo.*package Local::Bar/s);
};

done_testing;
