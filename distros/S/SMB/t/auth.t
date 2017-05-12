#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 27;

use lib '../lib', 'lib';

use_ok('SMB::Auth');

my $username = 'hacker';
my $password = '3A$y';

my $server_auth = SMB::Auth->new;
my $client_auth = SMB::Auth->new;

$server_auth->user_passwords({ $username => $password });
my ($name, $buffer);

$name = "Negotiate Response 1";
$buffer = $server_auth->generate_spnego;
ok($buffer, "generate buffer for $name");
ok($client_auth->process_spnego($buffer), "process buffer from $name");
is($server_auth->ntlmssp_supported, 1, "sanity on server after $name");
is($client_auth->ntlmssp_supported, 1, "sanity on client after $name");

$name = "Negotiate Response 2";
$buffer = $server_auth->generate_spnego(is_initial => 1);
ok($buffer, "generate buffer for $name");
ok($client_auth->process_spnego($buffer, is_initial => 1), "process buffer from $name");
is($server_auth->ntlmssp_supported, 1, "sanity on server after $name");
is($client_auth->ntlmssp_supported, 1, "sanity on client after $name");

$name = "SessionSetup Request 1";
$buffer = $client_auth->generate_spnego(host => 'client');
ok($buffer, "generate buffer for $name");
ok($server_auth->process_spnego($buffer), "process buffer from $name");
is($client_auth->client_host, 'client', "sanity on client after $name");
is($server_auth->client_host, 'client', "sanity on server after $name");

$name = "SessionSetup Response 1";
$buffer = $server_auth->generate_spnego(host => 'server');
ok($buffer, "generate buffer for $name");
ok($client_auth->process_spnego($buffer), "process buffer from $name");
is($server_auth->server_host, 'server', "sanity on server after $name");
is($client_auth->server_host, 'server', "sanity on client after $name");

$name = "SessionSetup Request 2";
$buffer = $client_auth->generate_spnego(username => $username, password => $password, domain => 'galaxy');
ok($buffer, "generate buffer for $name");
ok($server_auth->process_spnego($buffer), "process buffer from $name");
ok($client_auth->client_challenge, "sanity on client after $name");
ok($server_auth->client_challenge, "sanity on server after $name");

$name = "SessionSetup Response 2";
$buffer = $server_auth->generate_spnego();
ok($buffer, "generate buffer for $name");
ok($client_auth->process_spnego($buffer), "process buffer from $name");
is($server_auth->auth_completed, 1, "sanity on server after $name");
is($client_auth->auth_completed, 1, "sanity on client after $name");

my $lm_hash   = "\xae\xbd\x4d\xe3\x84\xc7\xec\x43\xaa\xd3\xb4\x35\xb5\x14\x04\xee";
my $ntlm_hash = "\x7a\x21\x99\x0f\xcd\x3d\x75\x99\x41\xe4\x5c\x49\x0f\x14\x3d\x5f";

is(SMB::Auth::create_lm_hash  ("12345"), $lm_hash,   'create_lm_hash');
is(SMB::Auth::create_ntlm_hash("12345"), $ntlm_hash, 'create_ntlm_hash');

