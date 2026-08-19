#!/usr/bin/env perl

# Penetration tests for Params::Get::get_params in a CGI deployment context.
#
# Threat model: get_params is deployed at the boundary of a CGI/mod_perl
# handler where @_ is populated from attacker-controlled HTTP request data --
# QUERY_STRING, POST body, cookies, HTTP headers parsed by CGI.pm or equivalent.
# Every subtest establishes the full CGI environment via local %ENV to document
# the attack surface and to detect any future regression where the module begins
# reading environment variables.
#
# Security contract being verified:
#   1. MUST NOT execute any input as code (no eval, system, exec, backtick).
#   2. Hostile values MUST pass through to the returned hashref unchanged.
#   3. Global variables ($@, $!, $_) MUST NOT be clobbered.
#   4. Tainted inputs MUST remain tainted in the returned hashref (no stripping).
#   5. Hostile key names MUST be treated as opaque strings.
#   6. The duplicate-key LIMITATION (last wins) is a real attack vector:
#      a hostile duplicate overwrites a previously sanitised value.
#   7. get_params MUST NOT read from STDIN even in a POST CGI context.

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::Most;
use Test::Needs;
use Test::Memory::Cycle;
use Readonly;
use Scalar::Util qw(tainted);

use Params::Get qw(get_params);
use TestHelper qw($USAGE_RE $DEFAULT_CROAK_RE);

# =========================================================================
# Hostile payload constants -- named so tests are self-documenting and the
# attack vector is explicit in the constant name.
# =========================================================================

# Command injection: shell metacharacters that spawn a subprocess if the string
# is ever passed to system(), exec(), or backticks.
Readonly::Scalar my $CMD_PIPE      => '| cat /etc/passwd';
Readonly::Scalar my $CMD_SEMICOLON => '; rm -rf /tmp/pentest; echo injected';
Readonly::Scalar my $CMD_SUBSHELL  => '$(id)';
Readonly::Scalar my $CMD_BACKTICK  => '`id`';

# Path traversal: escape a document root or restricted directory.
Readonly::Scalar my $PATH_DOTDOT   => '../../../etc/passwd';
Readonly::Scalar my $PATH_NULL     => "/etc/passwd\x00.jpg";
Readonly::Scalar my $PATH_ABS      => '/etc/shadow';

# XSS: HTML/JS payloads that execute in a browser when reflected unencoded.
Readonly::Scalar my $XSS_SCRIPT    => '<script>alert(document.cookie)</script>';
Readonly::Scalar my $XSS_ATTR      => '" onmouseover="alert(1)" data-x="';
Readonly::Scalar my $XSS_SRCDOC    => '<iframe srcdoc="&lt;script&gt;alert(1)&lt;/script&gt;">';

# CRLF injection: HTTP response splitting or arbitrary header injection.
Readonly::Scalar my $CRLF_HEADER   => "X-Injected: pwned\r\nContent-Type: text/html";
Readonly::Scalar my $CRLF_COOKIE   => "session=legit\r\nSet-Cookie: admin=1; Path=/";

# SQL injection: flows downstream to a DB query if not parameterised.
Readonly::Scalar my $SQL_UNION     => "' UNION SELECT password FROM users--";
Readonly::Scalar my $SQL_DROP      => "'; DROP TABLE users;--";

# Oversized input limits.
Readonly::Scalar my $LARGE_VAL_LEN  => 1_048_576;    # 1 MiB
Readonly::Scalar my $LARGE_KEY_LEN  => 65_536;        # 64 KiB
Readonly::Scalar my $LARGE_PAIR_CNT => 1_000;

# =========================================================================
# SECTION 1: Command injection
#
# Exploit: if get_params ever passed an argument to system(), exec(), or
# eval(), a shell metacharacter payload would spawn a subprocess or execute
# arbitrary Perl.  get_params has none of those operations.  These tests
# verify that the values are returned UNCHANGED -- they are never executed
# or transformed.
# =========================================================================

subtest 'command injection: pipe metacharacter passes through as literal' => sub {
	test_needs 'Test::Returns';
	Test::Returns->import();

	local %ENV = (%ENV,
		QUERY_STRING   => 'cmd=' . $CMD_PIPE,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, cmd => $CMD_PIPE);

	is($result->{cmd}, $CMD_PIPE, 'pipe payload returned as exact literal string');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'cycle-free');

	diag explain $result if $ENV{TEST_VERBOSE};
};

subtest 'command injection: semicolon chain passes through as literal' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'input=' . $CMD_SEMICOLON,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params('input', $CMD_SEMICOLON);

	is($result->{input}, $CMD_SEMICOLON,
		'semicolon chain stored verbatim under scalar $default key');
};

subtest 'command injection: $() subshell syntax passes through as literal' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'q=' . $CMD_SUBSHELL,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, q => $CMD_SUBSHELL);

	is($result->{q}, $CMD_SUBSHELL, '$() payload not expanded; stored as literal');
};

subtest 'command injection: backtick syntax in value passes through as literal' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'val=' . $CMD_BACKTICK,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, val => $CMD_BACKTICK);

	is($result->{val}, $CMD_BACKTICK, 'backtick syntax stored verbatim, never executed');
};

subtest 'command injection: hostile $default key name is never executed' => sub {
	# If get_params used $default in system() or eval(), a hostile key name
	# would spawn a subprocess.  It is used only as a hash key.
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result = get_params($CMD_PIPE, 'safe_value');

	is($result->{$CMD_PIPE}, 'safe_value',
		'hostile $default used only as opaque hash key, not executed');
};

# =========================================================================
# SECTION 2: Path traversal
#
# Exploit: a traversal payload in a file-path parameter causes the application
# to open files outside the intended directory.  get_params performs no file
# operations; it MUST return traversal strings as-is, not resolve or normalise
# them.  Silently resolving paths would be as dangerous as executing them --
# the calling code must receive the raw hostile string to reject it.
# =========================================================================

subtest 'path traversal: ../ sequence passes through unchanged' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'file=' . $PATH_DOTDOT,
		PATH_INFO      => '/' . $PATH_DOTDOT,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, file => $PATH_DOTDOT);

	is($result->{file}, $PATH_DOTDOT, 'traversal path stored unchanged (not resolved)');
};

subtest 'path traversal: null-byte injection byte is preserved in value' => sub {
	# Exploit: C-level file functions treat the first null byte as the string
	# terminator, so "/etc/passwd\x00.jpg" silently opens "/etc/passwd".
	# Perl hash values are null-safe; verify the null byte is not stripped.
	local %ENV = (%ENV,
		QUERY_STRING   => 'file=' . $PATH_NULL,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, file => $PATH_NULL);

	is(length($result->{file}), length($PATH_NULL),
		'null byte preserved: value length unchanged');
	is($result->{file}, $PATH_NULL, 'null-byte path stored with byte intact');
};

subtest 'path traversal: absolute path as $default key name stored opaquely' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'template=' . $PATH_ABS,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params('template', $PATH_ABS);

	is($result->{template}, $PATH_ABS,
		'absolute path stored verbatim under scalar $default');
};

# =========================================================================
# SECTION 3: Cross-site scripting (XSS)
#
# Exploit: an HTML/JS payload reflected in an HTTP response without encoding
# executes in the victim's browser.  get_params MUST NOT encode output -- it
# returns values verbatim so the caller's encoding layer acts on the raw string.
# Encoding here would be a false-safety anti-pattern (the caller could double-
# encode or miss other entry points).  These tests verify that get_params
# neither executes NOR encodes the payload.
# =========================================================================

subtest 'XSS: <script> payload preserved verbatim (no entity encoding)' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'q=' . $XSS_SCRIPT,
		HTTP_REFERER   => $XSS_SCRIPT,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, q => $XSS_SCRIPT);

	is($result->{q}, $XSS_SCRIPT,
		'XSS payload returned byte-for-byte (no HTML entity encoding applied)');
};

subtest 'XSS: attribute-injection payload preserved verbatim' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'name=' . $XSS_ATTR,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params('name', $XSS_ATTR);

	is($result->{name}, $XSS_ATTR,
		'attribute-injection payload stored unchanged under scalar $default');
};

subtest 'XSS: payload used as hash key does not corrupt retrieval' => sub {
	# An attacker controlling key names could inject XSS into any diagnostic
	# output that iterates over hash keys without encoding.  Verify the key
	# is stored and retrievable as-is -- the caller must encode when rendering.
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result = get_params(undef, $XSS_SCRIPT => 'marker_value');

	is($result->{$XSS_SCRIPT}, 'marker_value',
		'XSS string as hash key stored and retrievable unchanged');
};

# =========================================================================
# SECTION 4: CRLF / header injection
#
# Exploit: CRLF (\r\n) in a value used to set a redirect Location or
# Set-Cookie header splits the HTTP response, allowing injection of arbitrary
# headers.  get_params does not write headers; it MUST store the CRLF sequence
# as inert string content so the caller's header-setting code can detect and
# reject it.  Stripping CRLFs silently would mask the attack.
# =========================================================================

subtest 'CRLF injection: header-split payload preserved as literal string' => sub {
	local %ENV = (%ENV,
		QUERY_STRING      => 'redirect=' . $CRLF_HEADER,
		HTTP_USER_AGENT   => $CRLF_HEADER,
		REQUEST_METHOD    => 'GET',
	);

	my $result = get_params(undef, redirect => $CRLF_HEADER);

	is($result->{redirect}, $CRLF_HEADER,
		'CRLF header-inject payload stored as plain string (no stripping)');
	ok(index($result->{redirect}, "\r\n") >= 0,
		'CRLF bytes present in stored value -- not silently stripped');
};

subtest 'CRLF injection: Set-Cookie split payload preserved' => sub {
	local %ENV = (%ENV,
		HTTP_COOKIE    => $CRLF_COOKIE,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params('cookie', $CRLF_COOKIE);

	is($result->{cookie}, $CRLF_COOKIE,
		'CRLF cookie-split payload stored unchanged under scalar $default');
};

# =========================================================================
# SECTION 5: SQL injection (passthrough integrity)
#
# Exploit: an SQL injection payload in a value flows to a database query.
# get_params does not access the database.  Verify the payload passes through
# UNCHANGED so the caller's parameterised-query / escaping layer receives the
# original hostile string.  Any transformation by get_params would be a
# false-safety anti-pattern that could break the downstream sanitiser.
# =========================================================================

subtest 'SQL injection: UNION payload preserved verbatim' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'username=' . $SQL_UNION,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params(undef, username => $SQL_UNION);

	is($result->{username}, $SQL_UNION,
		'SQL UNION payload returned unchanged for caller to sanitise');
};

subtest 'SQL injection: DROP payload preserved verbatim' => sub {
	local %ENV = (%ENV,
		QUERY_STRING   => 'id=' . $SQL_DROP,
		REQUEST_METHOD => 'GET',
	);

	my $result = get_params('id', $SQL_DROP);

	is($result->{id}, $SQL_DROP,
		'SQL DROP payload stored unchanged under scalar $default');
};

# =========================================================================
# SECTION 6: POST context / STDIN isolation
#
# Exploit: if get_params read from STDIN in a POST CGI context, an attacker
# could supply hostile values via the request body that bypass the caller's
# argument-level sanitisation.  get_params MUST ignore STDIN -- its only
# input is @_.  A mocked STDIN with hostile content MUST have no effect on
# the returned hashref.
# =========================================================================

subtest 'POST context: get_params does not read hostile data from mocked STDIN' => sub {
	my $post_body = "cmd=$CMD_SEMICOLON&xss=$XSS_SCRIPT";
	open(my $mock_stdin, '<', \$post_body)
		or die "Cannot create in-memory STDIN mock: $!";

	local *STDIN = $mock_stdin;
	local %ENV = (%ENV,
		REQUEST_METHOD => 'POST',
		CONTENT_TYPE   => 'application/x-www-form-urlencoded',
		CONTENT_LENGTH => length($post_body),
	);

	# Explicit safe args -- NOT derived from the mocked STDIN body.
	my $result = get_params(undef, cmd => 'safe_cmd', xss => 'safe_xss');

	is($result->{cmd}, 'safe_cmd',
		'result comes from @_ arguments, not from mocked STDIN');
	is($result->{xss}, 'safe_xss',
		'XSS payload in STDIN body has no effect on returned hashref');

	close($mock_stdin);
};

# =========================================================================
# SECTION 7: Duplicate key injection
#
# Exploit: an attacker sends the same parameter name twice in a query string
# (e.g. role=user&role=admin).  When CGI.pm takes the last value and the
# caller passes the resulting flat list to get_params, the last occurrence
# silently wins.  This is a documented LIMITATION but constitutes a real
# attack vector: a hostile duplicate key overwrites a previously sanitised
# value.  The tests DOCUMENT and VERIFY this behaviour so callers know to
# use Params::Validate::Strict to detect duplicates before calling get_params.
# =========================================================================

subtest 'duplicate key: last value wins -- hostile value overwrites sanitised value' => sub {
	# Attack scenario: CGI query string "role=user&role=admin".
	# Sanitiser validates first occurrence (role=user); attacker's second
	# occurrence (role=admin) arrives later in the flat list and wins.
	local %ENV = (%ENV,
		QUERY_STRING   => 'role=user&role=admin',
		REQUEST_METHOD => 'GET',
	);

	# Perl silently drops duplicate hash keys; last occurrence wins.
	my $result = get_params(undef, role => 'user', role => 'admin');

	is($result->{role}, 'admin',
		'SECURITY NOTE: last duplicate key wins -- hostile value overwrote safe value');
};

subtest 'duplicate key: XSS payload as second occurrence wins over clean value' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result = get_params(undef, msg => 'Hello', msg => $XSS_SCRIPT);

	is($result->{msg}, $XSS_SCRIPT,
		'SECURITY NOTE: XSS payload in duplicate key wins; sanitise BEFORE calling get_params');
};

# =========================================================================
# SECTION 8: Hostile $default values
#
# Exploit: if the caller derives $default from attacker-controlled input,
# the hostile string becomes a hash key in the returned hashref.  Any code
# that iterates or prints the returned hash could reflect the hostile key.
# Additionally, a non-scalar $default (e.g. CODE ref, HASH ref) must be
# rejected immediately by the guard to prevent use as an indirect callback
# or improper dispatch.
# =========================================================================

subtest 'hostile $default: CRLF string becomes opaque hash key (no header split)' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result = get_params($CRLF_HEADER, 'value');

	ok(exists $result->{$CRLF_HEADER},
		'CRLF $default used as opaque hash key -- not written to headers');
	is($result->{$CRLF_HEADER}, 'value', 'value stored correctly under CRLF key');
};

subtest 'hostile $default: XSS string as key stored opaquely' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result = get_params($XSS_SCRIPT, 'safe_value');

	is($result->{$XSS_SCRIPT}, 'safe_value',
		'XSS string as $default key is opaque; value retrievable unchanged');
};

subtest 'hostile $default: CODE ref rejected immediately -- cannot be used as callback' => sub {
	# Exploit: a CODE ref as $default could be misused as an indirect callback
	# if get_params ever invoked it.  The type guard must croak before inspecting args.
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	throws_ok(
		sub { get_params(sub { system('/bin/sh') }, 'anything') },
		$DEFAULT_CROAK_RE,
		'CODE ref as $default rejected immediately with correct error',
	);
};

subtest 'hostile $default: HASH ref rejected immediately' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	throws_ok(
		sub { get_params({}, 'anything') },
		$DEFAULT_CROAK_RE,
		'HASH ref as $default rejected immediately with correct error',
	);
};

# =========================================================================
# SECTION 9: Resource exhaustion
#
# Exploit: an attacker sends an enormous argument list or very large string
# to cause memory allocation spikes or process stalls (algorithmic DoS).
# get_params MUST handle large inputs in time and memory proportional to
# the input size (O(n)) -- no quadratic expansion or unbounded allocation.
# =========================================================================

subtest 'resource exhaustion: 1 MiB string value passes through without expansion' => sub {
	my $large_val = 'A' x $LARGE_VAL_LEN;

	local %ENV = (%ENV,
		CONTENT_LENGTH => $LARGE_VAL_LEN,
		REQUEST_METHOD => 'POST',
	);

	my $result;
	lives_ok(
		sub { $result = get_params(undef, bigval => $large_val) },
		'1 MiB value accepted without error',
	);

	is(length($result->{bigval}), $LARGE_VAL_LEN,
		'1 MiB value stored without truncation or expansion');
	memory_cycle_ok($result, 'large value: no reference cycle');
};

subtest 'resource exhaustion: 64 KiB key name handled without error' => sub {
	my $long_key = 'K' x $LARGE_KEY_LEN;

	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result;
	lives_ok(
		sub { $result = get_params(undef, $long_key => 'v') },
		'64 KiB key accepted without error',
	);

	is(length((keys %{$result})[0]), $LARGE_KEY_LEN, '64 KiB key stored at correct length');
	is($result->{$long_key}, 'v', 'value accessible via long key');
};

subtest 'resource exhaustion: 1000 key-value pairs normalised without error' => sub {
	test_needs 'Test::Returns';
	Test::Returns->import();

	my @pairs = map { ("key_$_" => "val_$_") } 1 .. $LARGE_PAIR_CNT;

	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	my $result;
	lives_ok(
		sub { $result = get_params(undef, @pairs) },
		"$LARGE_PAIR_CNT pairs normalised without error",
	);

	is(scalar keys %{$result}, $LARGE_PAIR_CNT, "all $LARGE_PAIR_CNT keys present");
	is($result->{key_1},                       'val_1',                       'first pair correct');
	is($result->{"key_$LARGE_PAIR_CNT"}, "val_$LARGE_PAIR_CNT", 'last pair correct');
	returns_ok($result, { type => 'hashref' }, 'return type: hashref');
	memory_cycle_ok($result, 'large result: no reference cycle');
};

# =========================================================================
# SECTION 10: Global state integrity under hostile inputs
#
# Exploit: a library function that clobbers $@, $!, or $_ can silently mask
# upstream error state, causing a caller to proceed despite a prior failure
# (confused-deputy / error-swallowing).  get_params MUST leave all global
# variables unchanged regardless of the payload.
# =========================================================================

subtest 'global state: $@ preserved across hostile named-pair call' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	eval { die "upstream error\n" };
	my $saved_at = $@;

	get_params(undef, cmd => $CMD_PIPE, xss => $XSS_SCRIPT, path => $PATH_DOTDOT);

	is($@, $saved_at, '$@ not clobbered by get_params with hostile named-pair args');
};

subtest 'global state: $! preserved across hostile call' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	# Trigger ENOENT so $! holds a known non-zero errno value.
	stat('/this_path_cannot_exist_pentest_probe_' . $$);
	my $saved_errno = $! + 0;

	get_params(undef, path => $PATH_DOTDOT, cmd => $CMD_SUBSHELL);

	is($! + 0, $saved_errno, '$! (errno) not clobbered by get_params with hostile values');
};

subtest 'global state: $_ preserved across hostile call' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');
	local $_ = 'original_pentest_sentinel';

	get_params(undef, xss => $XSS_SCRIPT, crlf => $CRLF_HEADER);

	is($_, 'original_pentest_sentinel', '$_ not clobbered by get_params');
};

subtest 'global state: croak on hostile $default sets $@ to useful error message' => sub {
	local %ENV = (%ENV, REQUEST_METHOD => 'GET');

	# A CODE ref $default is the earliest possible croak path.
	# Verify croak sets $@ (rather than swallowing it) so the caller can
	# inspect the error in a wrapping eval.
	eval { get_params(sub {}, 'arg') };

	ok(length($@), 'croak on hostile $default sets $@ with error message');
	like($@, $DEFAULT_CROAK_RE, 'croak message matches expected pattern');
};

# =========================================================================
# SECTION 11: Taint mode propagation
#
# Exploit: a library that STRIPS taint from attacker-controlled values gives
# a false security guarantee -- downstream code relying on taint propagation
# to detect hostile data silently proceeds with untainted hostile input.
# get_params MUST preserve taintedness: tainted in => tainted out.
#
# These tests require Perl's taint mode (-T).  Run with:
#   HARNESS_PERL_SWITCHES=-T prove -l t/cgi_security.t
#
# Under taint mode, all %ENV values are tainted, giving us a reliable source
# of tainted strings without any external dependency.
# =========================================================================

subtest 'taint propagation: tainted value remains tainted in returned hashref' => sub {
	unless (${^TAINT}) {
		plan skip_all =>
			'Requires taint mode: HARNESS_PERL_SWITCHES=-T prove -l t/cgi_security.t';
	}

	# Under -T, data from %ENV is tainted.
	local $ENV{_PENTEST_TAINT_VAL} = $CMD_PIPE;
	my $tainted_val = $ENV{_PENTEST_TAINT_VAL};

	ok(tainted($tainted_val), 'precondition: env-derived value is tainted under -T');

	my $result = get_params(undef, hostile => $tainted_val);

	ok(tainted($result->{hostile}),
		'tainted input value remains tainted in returned hashref (taint not stripped)');
	is($result->{hostile}, $CMD_PIPE, 'tainted value content preserved exactly');
};

subtest 'taint propagation: tainted key stored and retrievable under -T' => sub {
	unless (${^TAINT}) {
		plan skip_all =>
			'Requires taint mode: HARNESS_PERL_SWITCHES=-T prove -l t/cgi_security.t';
	}

	local $ENV{_PENTEST_TAINT_KEY} = 'attack_key';
	my $tainted_key = $ENV{_PENTEST_TAINT_KEY};

	ok(tainted($tainted_key), 'precondition: key is tainted');

	my $result = get_params(undef, $tainted_key => 'safe_value');

	ok(exists $result->{attack_key}, 'tainted key accepted and stored in hashref');
	is($result->{attack_key}, 'safe_value', 'value accessible via tainted key');
};

subtest 'taint propagation: tainted $default used as hash key under -T' => sub {
	unless (${^TAINT}) {
		plan skip_all =>
			'Requires taint mode: HARNESS_PERL_SWITCHES=-T prove -l t/cgi_security.t';
	}

	local $ENV{_PENTEST_TAINT_DEFAULT} = 'tainted_default_key';
	my $tainted_default = $ENV{_PENTEST_TAINT_DEFAULT};

	ok(tainted($tainted_default), 'precondition: $default value is tainted');

	my $result = get_params($tainted_default, 'safe_value');

	ok(exists $result->{tainted_default_key},
		'tainted $default accepted and used as opaque hash key');
	is($result->{tainted_default_key}, 'safe_value',
		'value stored correctly under tainted $default key');
};

done_testing();
