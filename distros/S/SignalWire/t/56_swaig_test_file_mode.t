#!/usr/bin/env perl
# Tests for `bin/swaig-test --file PATH --list-tools` against the
# non-AgentBase SWMLService examples. Proves the in-process file loader
# walks the runtime tool registry (NO HTTP) and surfaces the tools the
# example script registered.

use strict;
use warnings;
use Test::More;
use File::Spec;

my $perl = $^X;
my $script = File::Spec->catfile('bin', 'swaig-test');
my $standalone = File::Spec->catfile('examples', 'swmlservice_swaig_standalone.pl');
my $sidecar    = File::Spec->catfile('examples', 'swmlservice_ai_sidecar.pl');

plan skip_all => "swaig-test not found at $script" unless -f $script;
plan skip_all => "$standalone not found"           unless -f $standalone;
plan skip_all => "$sidecar not found"              unless -f $sidecar;

sub run_cli {
    my (@args) = @_;
    my $cmd = qq{PERL5LIB="lib:\$PERL5LIB" $perl $script @args 2>&1};
    return scalar `$cmd`;
}

subtest '--help advertises --file' => sub {
    my $out = run_cli('--help');
    like($out, qr/--file/, 'help mentions --file');
};

subtest 'standalone example: --list-tools surfaces lookup_competitor' => sub {
    my $out = run_cli('--file', $standalone, '--list-tools');
    like($out, qr/Found \d+ SWAIG function/, 'reports a tool count');
    like($out, qr/lookup_competitor/, 'lists lookup_competitor');
    like($out, qr/competitor/, 'lists the parameter');
    unlike($out, qr/No SWAIG functions found/, 'not the empty case');
};

subtest 'sidecar example: --list-tools surfaces lookup_competitor' => sub {
    my $out = run_cli('--file', $sidecar, '--list-tools');
    like($out, qr/Found \d+ SWAIG function/, 'reports a tool count');
    like($out, qr/lookup_competitor/, 'lists lookup_competitor');
    unlike($out, qr/No SWAIG functions found/, 'not the empty case');
};

subtest 'standalone example: --exec runs the handler in-process' => sub {
    my $out = run_cli(
        '--file', $standalone,
        '--exec', 'lookup_competitor',
        '--param', 'competitor=ACME',
    );
    like($out, qr/ACME/, 'response mentions ACME');
    like($out, qr/\$99/, 'response mentions $99');
};

subtest '--file requires action and --url is mutually exclusive' => sub {
    my $out = run_cli('--file', $standalone);
    like($out, qr/--dump-swml|--list-tools|--exec/, 'errors when no action provided');

    my $out2 = run_cli('--file', $standalone, '--url', 'http://x/', '--list-tools');
    like($out2, qr/mutually exclusive/i, 'rejects --file + --url combo');
};

subtest 'unknown --file path errors cleanly' => sub {
    my $out = run_cli('--file', '/nonexistent/path.pl', '--list-tools');
    like($out, qr/does not exist|no such/i, 'errors on missing file');
};

done_testing;
