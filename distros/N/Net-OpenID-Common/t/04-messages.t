#!/usr/bin/perl

use strict;
use Test::More tests => 40;
use Net::OpenID::IndirectMessage;

my $openid2_ns = 'http://specs.openid.net/auth/2.0';
my $sreg_ns = 'http://openid.net/extensions/sreg/1.1';

my %basic_v2_args = (
   'openid.mode' => 'id_res',
   'openid.ns' => $openid2_ns,
   'openid.test' => 'success',
);

my %basic_v1_args = (
   'openid.mode' => 'id_res',
   'openid.test' => 'success',
);

my %sreg_args = (
   'openid.sreg.nickname' => 'Frank',
   'openid.sreg.fullname' => 'Frank the Goat',
);

my $good_v2_args = args({
   %basic_v2_args,
});

my $good_v1_args = args({
   %basic_v1_args,
});

my $sreg_v1_args = args({
   %basic_v1_args,
   %sreg_args,
});

my $sreg_v2_args = args({
   %basic_v2_args,
   %sreg_args,
   'openid.ns.sreg' => $sreg_ns,
});

my $sreg_v1_in_openid_v2 = args ({
   %basic_v2_args,
   %sreg_args,
});

my $nonsense_args = args({
   'kumquats' => 'yes',
   'madprops' => 'no',
   'language' => 'spranglish',
});

my $missing_mode_v2 = args({
   'openid.ns' => 'http://specs.openid.net/auth/2.0',
});

my $unsupported_version_args = args({
   %basic_v2_args,
   'openid.ns' => 'http://example.com/openid/some-future-version',
});

my $empty_args = args({});

my $basic_test = sub {
    my $args = shift;
    my $version = shift;

    is($args->protocol_version, $version, "detected version $version");
    is($args->mode, 'id_res', "v$version mode correct");
    is($args->get('test'), 'success', "v$version test correct");
    is($args->get('missing'), undef, "v$version missing correctly");
    should_die(sub { $args->get('sreg.fullname'); }, "v$version access invalid keyname croaks");
    should_die(sub { $args->get(); }, "v$version missing keyname croaks");

};

# A valid OpenID 2.0 message
$basic_test->($good_v2_args, 2);

# A valid OpenID 1.1 message
$basic_test->($good_v1_args, 1);

# OpenID 1.1 message to consumer when we only support 2.0 or above
is(args(\%basic_v1_args, minimum_version => 2), undef, "2.0-only doesn't understand 1.1");

my $sreg_test = sub {
    my $args = shift;
    my $version = shift;

    ok($args->has_ext($sreg_ns), "v$version has sreg namespace");
    ok($args->get_ext($sreg_ns, 'nickname'), "v$version has sreg nickname");
    is($args->get_ext($sreg_ns, 'nonsense'), undef, "v$version has no sreg nonsense");
    my $sreg = $args->get_ext($sreg_ns);
    is(keys(%$sreg), 2, "v$version two sreg args");
    ok(defined $sreg->{nickname}, "v$version has sreg nickname in hash");
    ok(defined $sreg->{fullname}, "v$version has sreg fullname in hash");
    should_die(sub { $args->get_ext(); }, "v$version missing namespace croaks");
};

# SREG in a valid 2.0 message
$sreg_test->($sreg_v2_args, 2);

# SREG in a valid 1.1 message
$sreg_test->($sreg_v1_args, 1);

my $missing_extension_test = sub {
    my $args = shift;
    my $version = shift;

    is($args->has_ext('nonsense'), 0, "v$version no nonsense extension");
    is($args->get_ext('nonsense', 'nonsense'), undef, "v$version no nonsense extension argument");
    is(keys(%{$args->get_ext('nonsense')}), 0, "v$version nonsense extension empty hash");
};

# A namespace that doesn't exist in a 2.0 message
$missing_extension_test->($good_v2_args, 2);

# A namespace that doesn't exist in a 1.1 message
$missing_extension_test->($good_v1_args, 1);

# V1 SREG in V2 Message
is($sreg_v1_in_openid_v2->has_ext($sreg_ns), 0, "no v1 sreg in v2 message");

# Some args that aren't an OpenID message at all
is($nonsense_args, undef, "nonsense args give undef");
is($missing_mode_v2, undef, "v2 with missing mode gives undef");
is($unsupported_version_args, undef, "unsupported version gives undef");
is($empty_args, undef, "empty hash gives undef");

# Passing in garbage into the constructor
should_die(sub { args("HELLO WORLD!"); }, "passing string into constructor croaks");
should_die(sub { args(); }, "passing nothing into constructor croaks");

sub args {
    return Net::OpenID::IndirectMessage->new(@_);
}

sub should_die {
    my ($coderef, $message) = @_;

    eval {
        $coderef->();
    };
    $@ ? pass($message) : fail($message);
}

1;
