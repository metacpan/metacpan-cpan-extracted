#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use FakeSSHD;
use Net::LibSSH;

# Old firmware offers only algorithms libssh no longer proposes by default:
# diffie-hellman SHA-1 key exchange, ssh-rsa host keys, CBC ciphers. The
# options kex, hostkeys, ciphers_c_s, ciphers_s_c, hmac_c_s and hmac_s_c let
# a caller opt in to them explicitly; left alone, nothing changes.
#
# Each case starts a fake server (t/lib/fake-sshd.c) that offers exactly one
# legacy algorithm, then connects twice: without the option, which must fail
# with libssh's "no match" and must not croak, and with it, which must work.
# The fake server is built from the same libssh the module links, so a libssh
# built without an algorithm makes the server refuse to start, and this file
# fails instead of silently testing less.
#
# The "+", "-" and "^" prefixes belong to libssh, not to this module, and
# libssh only knows them from 0.11.0 on. The cases that use them ask the
# linked libssh whether it accepts a prefixed list and are skipped, with that
# reason, where it does not; every other case runs unchanged.

my $probe = FakeSSHD->start;
plan skip_all => 'no C compiler: cannot build t/lib/fake-sshd.c' unless $probe;
undef $probe;

# Does the linked libssh take a "+", "-" or "^" prefix on an algorithm list?
# Older ones read the sign as part of an algorithm name and refuse the list
# ("no allowed algorithm for method"). Asked once, of libssh itself.
my $PREFIX_SUPPORT;
sub libssh_knows_prefixes {
    return $PREFIX_SUPPORT if defined $PREFIX_SUPPORT;
    my $ssh = Net::LibSSH->new;
    return $PREFIX_SUPPORT = eval {
        $ssh->option(kex => '+diffie-hellman-group14-sha1');
        1;
    } ? 1 : 0;
}

sub session_for {
    my ($srv, %opt) = @_;
    my $ssh = Net::LibSSH->new;
    $ssh->option(host       => $srv->host);
    $ssh->option(port       => $srv->port);
    $ssh->option(user       => 'switch');
    $ssh->option(knownhosts => $srv->known_hosts);
    $ssh->option(timeout    => 10);
    $ssh->option($_ => $opt{$_}) for sort keys %opt;
    return $ssh;
}

# Returns the connect result and the error; the option calls may croak, which
# is reported through $@ by the caller's eval.
sub attempt {
    my ($server_args, %opt) = @_;
    my ($ok, $err);
    # A server that refuses the proposal hangs up at once, and now and then
    # the client reports that hang-up ("Socket error: ...") instead of its own
    # "no match for method" diagnosis. Whether the connection works is not in
    # doubt in that case, only the wording, so ask again for the wording.
    for (1 .. 8) {
        my $srv = FakeSSHD->start(@$server_args);
        my $ssh = session_for($srv, %opt);
        $ok  = $ssh->connect;
        $err = $ssh->error;
        last if $ok || ($err // '') !~ /\ASocket error/;
    }
    return ($ok, $err);
}

my @cases = (
    {
        name   => 'key exchange',
        server => [ '--kex=diffie-hellman-group14-sha1' ],
        opt    => { kex => 'diffie-hellman-group14-sha1' },
        no_match => qr/key exchange|kex algos/,
    },
    {
        name   => 'key exchange, legacy group-exchange',
        server => [ '--kex=diffie-hellman-group-exchange-sha1' ],
        opt    => { kex => 'diffie-hellman-group-exchange-sha1' },
        no_match => qr/kex algos/,
    },
    {
        name   => 'key exchange, appended to the defaults with "+"',
        server => [ '--kex=diffie-hellman-group14-sha1' ],
        opt    => { kex => '+diffie-hellman-group14-sha1' },
        no_match => qr/kex algos/,
        needs_prefix => 1,
    },
    {
        name   => 'host key',
        server => [ '--hostkey-type=rsa', '--hostkeys=ssh-rsa' ],
        opt    => { hostkeys => 'ssh-rsa' },
        no_match => qr/host key algo/,
    },
    {
        name   => 'MACs in both directions',
        server => [ '--ciphers=aes256-ctr', '--hmac=hmac-sha1' ],
        opt    => { hmac_c_s => 'hmac-sha1', hmac_s_c => 'hmac-sha1' },
        no_match => qr/mac algo/,
    },
    {
        name   => 'ciphers in both directions',
        server => [ '--ciphers=aes128-cbc' ],
        opt    => { ciphers_c_s => 'aes128-cbc', ciphers_s_c => 'aes128-cbc' },
        no_match => qr/encryption/,
    },
);

for my $case (@cases) {
    subtest $case->{name} => sub {
        plan skip_all => 'the linked libssh does not know the "+", "-" and "^" prefixes (libssh 0.11.0 and later do)'
            if $case->{needs_prefix} && !libssh_knows_prefixes();
        my ($ok, $err) = eval { attempt($case->{server}) };
        is $@, '', 'connecting with no options does not croak';
        ok !$ok, 'the default proposal does not reach a legacy-only server';
        like $err // '', $case->{no_match}, '... and error() says which method found no match';

        ($ok, $err) = eval { attempt($case->{server}, %{ $case->{opt} }) };
        is $@, '', 'the options are accepted';
        ok $ok, 'connect() succeeds once the legacy algorithm is enabled explicitly'
            or diag $err;
    };
}

# --- each direction is its own option ---

subtest 'ciphers: one direction is not enough' => sub {
    for my $only (qw(ciphers_c_s ciphers_s_c)) {
        my ($ok, $err) = eval { attempt([ '--ciphers=aes128-cbc' ], $only => 'aes128-cbc') };
        is $@, '', $only . ' is accepted';
        ok !$ok, $only . ' alone leaves the other direction without a match';
        like $err // '', qr/\Q@{[ $only eq 'ciphers_c_s' ? 'server->client' : 'client->server' ]}\E/,
            '... and error() names the direction that was left out';
    }
};

subtest 'hmac: each option is applied to its own direction' => sub {
    # The server offers only hmac-sha2-256 (in libssh's defaults) and a
    # non-AEAD cipher, so a MAC really is negotiated. Asking for hmac-sha1 in
    # one direction must fail exactly that direction.
    my @server = ('--ciphers=aes256-ctr', '--hmac=hmac-sha2-256');
    for my $case ([ hmac_c_s => 'client->server' ], [ hmac_s_c => 'server->client' ]) {
        my ($opt, $direction) = @$case;
        my ($ok, $err) = eval { attempt(\@server, $opt => 'hmac-sha1') };
        is $@, '', $opt . ' is accepted';
        ok !$ok, $opt . ' => a MAC the server lacks: no connection';
        like $err // '', qr/mac algo \Q$direction\E/, '... for the ' . $direction . ' direction';
    }

    my ($ok, $err) = eval {
        attempt(\@server, hmac_c_s => 'hmac-sha2-256', hmac_s_c => 'hmac-sha2-256');
    };
    ok $ok, 'both set to the MAC the server offers: connects' or diag $err;
};

# --- the prefix forms, on every algorithm list ---

subtest 'prefixes "+", "-" and "^" on the algorithm lists' => sub {
    plan skip_all => 'the linked libssh does not know the "+", "-" and "^" prefixes (libssh 0.11.0 and later do)'
        unless libssh_knows_prefixes();
    my $ssh = Net::LibSSH->new;
    my %known = (
        kex         => 'diffie-hellman-group14-sha1',
        hostkeys    => 'ssh-ed25519',
        ciphers_c_s => 'aes256-ctr',
        ciphers_s_c => 'aes256-ctr',
        hmac_c_s    => 'hmac-sha2-256',
        hmac_s_c    => 'hmac-sha2-256',
    );
    for my $key (sort keys %known) {
        for my $prefix ('+', '-', '^') {
            eval { $ssh->option($key => $prefix . $known{$key}) };
            is $@, '', $key . ' accepts ' . $prefix . $known{$key};
        }
    }
};

# --- off by default; libssh vets the values ---

subtest 'rejection and defaults' => sub {
    my $srv = FakeSSHD->start;
    my $ssh = session_for($srv);

    for my $key (qw(kex hostkeys ciphers_c_s ciphers_s_c hmac_c_s hmac_s_c)) {
        eval { $ssh->option($key => 'no-such-algorithm') };
        like $@, qr/\ANet::LibSSH::option: /, $key . ' croaks on an algorithm libssh does not know';
    }

    eval { $ssh->option(ciphers => 'aes128-cbc') };
    like $@, qr/unknown option 'ciphers'/, 'there is no combined "ciphers" key: the set stays closed';

    # A rejected value must not have spoiled the session.
    ok $ssh->connect, 'a session whose algorithm options were all rejected connects normally'
        or diag $ssh->error;
};

done_testing;
