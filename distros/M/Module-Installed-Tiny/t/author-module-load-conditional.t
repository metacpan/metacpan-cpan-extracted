#!perl

# this is a temporary location. testing Module::Load::Conditional with packed
# scripts.

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;
BEGIN {
    plan skip_all => "this test is only for author"
        unless $ENV{AUTHOR_TESTING};
}

use File::Temp qw(tempfile);
use IPC::System::Options qw(readpipe);
use Module::Load::Conditional;
use Test::Needs 'App::depak';

my ($tempfh, $tempname) = tempfile();

subtest normal => sub {
    my $output = readpipe(
        $^X, "-I", "$Bin/lib", "$Bin/bin/test-module-load-conditional.pl");
    like($output, qr/^loadable1.*^loadable2.*^UNLOADABLE3/ms)
        or diag explain $output;
};

subtest fatpack => sub {
    require App::depak;

    my $res = App::depak::depak(
        pack_method => "fatpack",
        include_module => ["Local::Foo", "Local::Bar"],
        input_file => "$Bin/bin/test-module-load-conditional.pl",
        output_file => $tempname,
        overwrite => 1,
        trace_method => "fatpacker",
    );
    die "Can't create packed script (fatpack): $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    my $output = `$^X $tempname`;
    like($output, qr/^loadable1.*^loadable2.*^UNLOADABLE3/ms);
};

subtest datapack => sub {
    require App::depak;

    my $res = App::depak::depak(
        pack_method => "datapack",
        include_module => ["Local::Foo", "Local::Bar"],
        input_file => "$Bin/bin/test-module-load-conditional.pl",
        output_file => $tempname,
        overwrite => 1,
        trace_method => "fatpacker",
    );
    die "Can't create packed script (datapack): $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    my $output = `$^X $tempname`;
    like($output, qr/^loadable1.*^loadable2.*^UNLOADABLE3/ms);
};

done_testing;
