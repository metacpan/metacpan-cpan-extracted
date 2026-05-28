#!/usr/bin/env perl
# Tests for the top-level convenience entry points exposed on the
# ``SignalWire`` package — RestClient, register_skill,
# add_skill_directory, list_skills_with_params. These mirror Python's
# package-level ``signalwire/__init__.py`` factory + skill registry
# helpers.
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('SignalWire');
use_ok('SignalWire::REST::RestClient');
use_ok('SignalWire::Skills::SkillRegistry');

# ============================================================
# RestClient factory
# ============================================================

subtest 'SignalWire::RestClient builds client from kwargs' => sub {
    my $client = SignalWire::RestClient(
        project => 'p-123',
        token   => 't-456',
        host    => 'demo.signalwire.com',
    );
    isa_ok($client, 'SignalWire::REST::RestClient');
    ok(defined $client->fabric, 'fabric namespace wired');
    ok(defined $client->calling, 'calling namespace wired');
    ok(defined $client->compat, 'compat namespace wired');
};

subtest 'SignalWire::RestClient builds client from positional args' => sub {
    my $client = SignalWire::RestClient('proj', 'tok', 'pos.signalwire.com');
    isa_ok($client, 'SignalWire::REST::RestClient');
};

subtest 'SignalWire::RestClient dies on missing credentials' => sub {
    local %ENV = %ENV;
    delete $ENV{SIGNALWIRE_PROJECT_ID};
    delete $ENV{SIGNALWIRE_API_TOKEN};
    delete $ENV{SIGNALWIRE_SPACE};
    eval { SignalWire::RestClient() };
    ok($@, 'died as expected');
};

# ============================================================
# add_skill_directory
# ============================================================

subtest 'SignalWire::add_skill_directory records the path' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    SignalWire::add_skill_directory($tmp);
    my $reg = SignalWire::_singleton_registry();
    my $paths = $reg->_external_paths;
    ok(grep({ $_ eq $tmp } @$paths), 'tmp dir recorded on singleton registry');
};

subtest 'SignalWire::add_skill_directory dies on missing directory' => sub {
    eval { SignalWire::add_skill_directory('/no/such/path/zzz_perl_top_level') };
    like($@, qr/does not exist/, 'died with descriptive message');
};

# ============================================================
# register_skill
# ============================================================

{
    package TopLevelDummySkill;
    sub skill_name { 'top_level_dummy_skill_perl' }
    sub new { bless {}, shift }
}

subtest 'SignalWire::register_skill registers a class' => sub {
    SignalWire::register_skill('TopLevelDummySkill');
    my $skills = SignalWire::Skills::SkillRegistry->list_skills;
    ok(grep({ $_ eq 'top_level_dummy_skill_perl' } @$skills),
       'skill is in the registry list');
};

# ============================================================
# list_skills_with_params
# ============================================================

subtest 'SignalWire::list_skills_with_params returns schema hash' => sub {
    my $schema = SignalWire::list_skills_with_params();
    is(ref($schema), 'HASH', 'returns a hashref');
    ok(scalar(keys %$schema) > 0, 'schema is non-empty');
    for my $name (sort keys %$schema) {
        is(ref($schema->{$name}), 'HASH', "$name entry is a hash");
        is($schema->{$name}{name}, $name, "$name entry has correct name");
    }
};

done_testing();
