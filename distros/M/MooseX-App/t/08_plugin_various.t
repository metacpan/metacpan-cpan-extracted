# -*- perl -*-

# t/08_plugin_various.t - Test various plugin

use strict;
use Test::Most tests => 2+1;
use Test::NoWarnings;

use lib 't/testlib';

use Test03;

subtest 'Bash completion' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(bash_completion)]);
    my $test01 = Test03->new_with_command;

    isa_ok($test01,'MooseX::App::Message::Envelope');
    my $bash_completion = $test01->stringify;
    like($bash_completion,qr/_test03_macc_somecommand\(\)\s\{/,'some_command present');
    like($bash_completion,qr/--global_option/,'global_option present');
    like($bash_completion,qr/--roleattr/,'roleattr present');
    unlike($bash_completion,qr/bash_completion/,'bash_completion is not included');
};

subtest 'Version' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(version)]);
    my $test02 = Test03->new_with_command;
    isa_ok($test02,'MooseX::App::Message::Envelope');
    my $version = $test02->stringify;
    like($version,qr/\s*test03\s+version\s+22\.02/s,'Check for app version');
    like($version,qr/\s*MooseX::App\sversion\s\d+\.\d+/s,'Check for MooseX::App version');
    like($version,qr/This library is free software/s,'License included');
};
