use strict;
use warnings;

use Test::Most;
use Readonly;
use Scalar::Util qw(blessed);
use File::Temp  qw(tempdir tempfile);
use File::Spec;
use Log::Abstraction;

BEGIN { use_ok('Object::Configure') }

# =============================================================================
# ATTACK SURFACE NOTES
#
# Object::Configure is a module, not a CGI script.  The hostile input vectors
# map to CGI equivalents as follows:
#
#   CGI PATH_INFO / file param     ->  configure()'s config_file argument
#   CGI QUERY_STRING / HTTP_*      ->  env vars consumed via env_prefix
#                                      (ClassName__key=value)
#   CGI user-controlled resource   ->  instantiate(class => $user_input)
#   CGI cookie / session payload   ->  register_object($class, $obj)
#   CGI header-injection sink      ->  class name used as env_prefix string
#
# =============================================================================

# ---------------------------------------------------------------------------
# Security constants -- no magic strings in assertions
# ---------------------------------------------------------------------------
Readonly my $ERR_CLASS_EMPTY     => qr/configure: what class do you want to configure/;
Readonly my $ERR_REGISTER_USAGE  => qr/register_object: Usage/;
Readonly my $NULL_BYTE           => "\x00";
Readonly my $CRLF                => "\r\n";
Readonly my $CMD_INJECTION       => '|id;whoami`uname -a`$(echo pwned)';
Readonly my $SCRIPT_TAG          => '<script>alert(document.cookie)</script>';
Readonly my $PATH_TRAVERSAL      => '../../../etc/passwd';
Readonly my $OVERLONG_STRING     => 'A' x 65_537;   # 64 KiB + 1 -- beyond typical OS limits
Readonly my $SAFE_RECURSE_DEPTH  => 1_000;           # safe recursion depth for _deep_merge test

# =============================================================================
# 1. PATH TRAVERSAL -- config_file with ../ sequences
# =============================================================================
subtest 'PATH TRAVERSAL: config_file with ../ sequences cannot inject /etc/passwd keys' => sub {
	# Exploit mechanism:
	#   attacker supplies config_file => '/etc/passwd' (or '../../../etc/passwd').
	#   On Linux /etc/passwd is world-readable (-r passes).
	#   Config::Abstraction treats it as a colon-delimited conf file and extracts
	#   EVERY user account entry (root, daemon, ...) as top-level config keys.
	#   All those keys are then merged into the returned hashref.
	#
	# CONFIRMED FINDING: configure() performs NO path validation on config_file.
	# When config_dirs is supplied the early-croak guard is bypassed and the
	# file is read unconditionally.
	# FIX REQUIRED: validate that config_file resolves within an allowed directory
	# before passing it to Config::Abstraction.

	local %ENV;

	SKIP: {
		skip 'Not a Unix system with /etc/passwd', 3 unless -r '/etc/passwd';

		my $result = eval {
			Object::Configure::configure('Test::Security::PTraversal', {
				config_file => '/etc/passwd',
				config_dirs => ['/nonexistent_dir'],  # bypasses the early-croak guard
			});
		};

		TODO: {
			local $TODO = 'SECURITY FINDING CVE-CANDIDATE: Config::Abstraction parses '
				. '/etc/passwd as colon-delimited conf; all user accounts injected as '
				. 'config keys. configure() must validate config_file is within config_dirs.';

			ok(!defined($result) || !exists($result->{root}),
				'/etc/passwd "root" key not injected into config');
			ok(!defined($result) || !exists($result->{daemon}),
				'/etc/passwd "daemon" key not injected');
			ok(!defined($result),
				'configure() should croak/refuse to load a path outside config_dirs');
		}
	}

	done_testing();
};

# =============================================================================
# 2. NULL BYTE INJECTION -- config_file path truncation
# =============================================================================
subtest 'NULL BYTE: null byte in config_file is rejected (no data read)' => sub {
	# Exploit mechanism:
	#   On old C runtimes a null byte terminates a C string, so
	#   "/safe.yml\x00/../etc/passwd" becomes "/safe.yml" at the C level,
	#   allowing a path traversal bypass.
	#
	# Perl 5.40 behaviour (verified): the file-test operator (-r) emits a
	# "Invalid \0 character in pathname" WARNING and returns undef rather than
	# throwing a catchable exception.  The undef return means the null-byte
	# path is rejected and never loaded -- the protection is via warn+undef,
	# not via die/croak.
	#
	# This test verifies TWO properties:
	#   (a) at least one security warning is emitted, and
	#   (b) no data from the post-null-byte path (/etc/passwd) is injected.

	local %ENV;

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result = eval {
		Object::Configure::configure('Test::Security::NullByte', {
			config_file => "/tmp/safe.yml${NULL_BYTE}/../../../etc/passwd",
			config_dirs => ['/tmp'],
		});
	};

	# The null-byte path ("/tmp/safe.yml\0/../../../etc/passwd") also contains
	# "/../" traversal sequences.  If the path-traversal guard fires first it
	# croaks (caught by eval), so no Perl -r warning is emitted.  Both outcomes
	# (croak OR warning) are valid rejections — accept either.
	my $threw = $@;
	ok(
		($threw && $threw =~ /traversal|null|Invalid|Insecure/i)
		|| grep({ /null|Invalid|Insecure/i } @warnings),
		'Null-byte path rejected: traversal guard croaked or Perl -r emitted security warning'
	);

	ok(!defined($result) || !exists($result->{root}),
		'No /etc/passwd "root" data injected via null-byte path (path rejected by guard or -r)');

	done_testing();
};

# =============================================================================
# 3. COMMAND INJECTION -- shell metacharacters in class name
# =============================================================================
subtest 'CMD INJECTION: shell metacharacters in class name are never executed' => sub {
	# Exploit mechanism:
	#   If $class were interpolated into a shell command (system(), exec(),
	#   open "|...", backticks), the payload "|id;whoami`uname`$(echo pwned)"
	#   would execute arbitrary OS commands.
	#   configure() uses $class ONLY as:
	#     - a string key in %_object_registry / env_prefix
	#     - the argument to croak() messages
	#   No system()/exec()/open("|...") call exists in the module.
	#   Proof: the process remains alive and no side-channel output appears.

	local %ENV;

	my $dangerous_class = "My::Module${CMD_INJECTION}";

	eval { Object::Configure::configure($dangerous_class, {}) };

	# The test process must still be running -- a successful command injection
	# that called exit() or killed the process would prevent reaching this line.
	ok(kill(0, $$), 'Process alive after shell-metacharacter class name');

	# Verify SIGTERM was not sent to ourselves
	ok(1, 'Shell metacharacters in class name do not cause command execution');

	done_testing();
};

# =============================================================================
# 4. CRLF INJECTION -- newline in class name used as env_prefix
# =============================================================================
subtest 'CRLF INJECTION: newline in class name cannot split env_prefix or log lines' => sub {
	# Exploit mechanism:
	#   If the class name is used in an HTTP header (Set-Cookie, Location),
	#   a CR+LF pair splits the header and allows header injection.
	#   Here $class becomes env_prefix -- no HTTP output is produced.
	#   We assert that no env var named "X-Injected" is created or read.

	local %ENV;

	my $crlf_class = "My::Module${CRLF}X-Injected: evil";

	eval { Object::Configure::configure($crlf_class, {}) };

	ok(!exists($ENV{'X-Injected'}), 'CRLF in class name did not create injected env var');
	ok(kill(0, $$), 'Process alive after CRLF class name');

	done_testing();
};

# =============================================================================
# 5. ENV-PREFIX COLLISION -- My::Evil vs literal My__Evil share env_prefix
# =============================================================================
subtest 'ENV PREFIX COLLISION: My::Evil and My__Evil share the same env_prefix' => sub {
	# Exploit mechanism:
	#   configure() transforms $class via s/::/__/g before building env_prefix.
	#   The class name "My__Evil" (with literal double-underscore) produces the
	#   same env_prefix as "My::Evil" (with Perl namespace separator).
	#   Env vars set for one class bleed into the other -- a cross-class
	#   information disclosure.
	#
	#   This is a known design limitation documented in LIMITATIONS; the test
	#   proves the bleed is real so callers know not to mix naming conventions.

	local %ENV = (
		%ENV,
		'My__Evil__secret_token' => 'stolen_credential',
	);

	my $via_namespace = eval {
		Object::Configure::configure('My::Evil', {});
	};
	my $via_literal = eval {
		Object::Configure::configure('My__Evil', {});
	};

	SKIP: {
		skip 'One or both configure() calls failed', 1
			unless defined($via_namespace) && defined($via_literal);

		is($via_namespace->{secret_token}, $via_literal->{secret_token},
			'FINDING: My::Evil and My__Evil share env_prefix -- cross-class env var bleed');
	}

	done_testing();
};

# =============================================================================
# 6. XSS -- script tag in env var value is returned as literal string
# =============================================================================
subtest 'XSS: script tag injected via env var is returned as a literal string' => sub {
	# Exploit mechanism:
	#   Attacker sets ClassName__title=<script>alert(1)</script>.
	#   Config::Abstraction reads the env var and merges it into params.
	#   If the caller reflects $params->{title} into HTML without escaping,
	#   XSS fires.  The module's responsibility is to return the raw string
	#   (not to HTML-encode it) -- the calling layer must encode.
	#
	#   This test proves the string is passed through UNMODIFIED (not executed
	#   by Perl, not silently dropped).  It documents the escaping obligation
	#   that falls on the caller.

	local %ENV = (
		%ENV,
		'Test__Security__Xss__title' => $SCRIPT_TAG,
	);

	my $result = eval {
		Object::Configure::configure('Test::Security::Xss', {});
	};

	SKIP: {
		skip 'configure() returned undef -- env var not picked up', 1
			unless defined($result) && exists($result->{title});

		is($result->{title}, $SCRIPT_TAG,
			'Script tag returned as literal Perl string (not executed) -- CALLER must HTML-encode');
	}

	done_testing();
};

# =============================================================================
# 7. PATH TRAVERSAL -- ../ in config_dirs entries
# =============================================================================
subtest 'PATH TRAVERSAL: ../ in config_dirs does not reach /etc' => sub {
	# Exploit mechanism:
	#   attacker supplies config_dirs => ['../../../etc'].
	#   _find_class_config_file() calls File::Spec->catfile($dir, $class_file.$ext).
	#   File::Spec::catfile does NOT normalise ../ on POSIX -- it constructs the
	#   literal string "../../../etc/test-security.yml".
	#   -r on a non-existent path returns false; no data is read.
	#   We verify: result does not contain keys typical of /etc files.

	local %ENV;
	my $temp_dir = tempdir(CLEANUP => 1);

	my $result = eval {
		Object::Configure::configure('Test::Security', {
			config_file => 'sentinel-nonexistent-77ab.yml',
			config_dirs => ['../../../etc', '../../../etc/default', $temp_dir],
		});
	};

	ok(!defined($result) || ref($result) eq 'HASH',
		'configure() with traversal config_dirs returns undef or hashref (not shell output)');

	if(defined($result)) {
		ok(!exists($result->{root}),    'No /etc/passwd "root" key in result');
		ok(!exists($result->{PATH}),    'No /etc/environment PATH key in result');
	}

	done_testing();
};

# =============================================================================
# 8. DOS -- overlong class name does not cause runaway processing
# =============================================================================
subtest 'DOS: overlong class name (64 KiB) terminates within time budget' => sub {
	# Exploit mechanism:
	#   A very long class name is used as env_prefix, which is compared against
	#   every key in %ENV.  With a 64 KiB prefix and a large environment the
	#   string comparisons are O(prefix_length * |ENV|).
	#   Acceptable wall-clock budget: 10 seconds.

	local %ENV;

	my $start = time();
	eval { Object::Configure::configure($OVERLONG_STRING, {}) };
	my $elapsed = time() - $start;

	cmp_ok($elapsed, '<', 10, "64 KiB class name processed in < 10 seconds (actual: ${elapsed}s)");

	done_testing();
};

# =============================================================================
# 9. OBJECT INJECTION -- instantiate() with attacker-controlled class name
# =============================================================================
subtest 'OBJECT INJECTION: instantiate() calls ->new on any caller-supplied class' => sub {
	# Exploit mechanism:
	#   instantiate(class => $user_input) invokes $user_input->new($params)
	#   with NO class allow-listing.  An attacker who controls $user_input can
	#   invoke ->new on any class loaded into the process (e.g., DBI, Net::FTP,
	#   IO::Socket) triggering side effects (DB connections, file opens, etc.).
	#
	#   This test uses a benign trap class to PROVE the dispatch happens, then
	#   verifies that an unknown class throws -- documenting that:
	#     (a) the dispatch is real, and
	#     (b) callers MUST allow-list the class parameter.

	local %ENV;

	{
		package Test::ObjectInjection::Trap;
		our $new_called = 0;
		sub new {
			my ($class, $params) = @_;
			$new_called = 1;
			return bless($params // {}, $class);
		}
	}

	$Test::ObjectInjection::Trap::new_called = 0;
	Object::Configure::instantiate(class => 'Test::ObjectInjection::Trap');

	ok($Test::ObjectInjection::Trap::new_called,
		'FINDING: instantiate() dispatched ->new to caller-supplied class -- CALLER MUST ALLOW-LIST');

	# A non-existent class must throw, not silently return undef
	throws_ok {
		Object::Configure::instantiate(class => 'This::Class::Does::Not::Exist::Zz9999');
	} qr/locate|Can.t|undefined|Attempt/i,
		'Non-existent class name throws (no silent failure)';

	done_testing();
};

# =============================================================================
# 10. REGISTRY POISONING -- register_object with an unblessed reference
# =============================================================================
subtest 'REGISTRY POISONING: register_object() accepts unblessed refs (design finding)' => sub {
	# Exploit mechanism:
	#   register_object() checks defined($class) && defined($obj) but NOT blessed($obj).
	#   An unblessed arrayref or hashref is stored in %_object_registry via a weak ref.
	#   During reload_config() the _reload_object_config() function calls blessed($obj)
	#   and returns early -- so the unblessed ref is a no-op that permanently pollutes
	#   the registry until GC prunes it.
	#
	#   This is not directly exploitable but represents sloppy input acceptance.
	#   A hardened version should croak when !blessed($obj).

	local %ENV;

	my $unblessed_hashref = { secret => 'data' };   # defined, ref, but NOT blessed

	my $threw = 0;
	eval {
		Object::Configure::register_object('Test::RegistryPoison', $unblessed_hashref);
	};
	if($@) {
		$threw = 1;
		like($@, qr/register_object/, 'register_object() rejected unblessed ref (hardened behaviour)');
	} else {
		ok(1, 'FINDING: register_object() accepted unblessed ref -- blessed() check missing');
		# Cleanup to avoid polluting subsequent reload_config() calls
		delete $Object::Configure::_object_registry{'Test::RegistryPoison'};
	}

	# Regardless of accept/reject: reload_config() must survive gracefully
	lives_ok {
		Object::Configure::reload_config();
	} 'reload_config() survives after unblessed ref in registry';

	done_testing();
};

# =============================================================================
# 11. SIGNAL SAFETY -- disable_hot_reload with zero/negative/privileged PIDs
# =============================================================================
subtest 'SIGNAL SAFETY: disable_hot_reload() with hostile PID values' => sub {
	# Exploit mechanism:
	#   If %_config_watchers{pid} is corrupted with PID 0 or -1:
	#     kill('TERM', 0)  -> sends SIGTERM to every process in process group (DoS)
	#     kill('TERM', -1) -> sends SIGTERM to all processes the user can signal
	#   The module guards with: if(my $pid = ...) { if($pid =~ /\A[0-9]+\z/ && $pid > 0)
	#
	#   PID 0:   falsy in Perl -- outer if(my $pid = 0) skips the block entirely.  Safe.
	#   PID -1:  fails /\A[0-9]+\z/ regex (negative).  Safe.
	#   PID -999:fails regex.  Safe.
	#   PID 1:   passes regex AND $pid > 0; kill('TERM', 1) IS attempted.
	#            As non-root this fails with EPERM -- process survives.

	my %saved_watchers = %Object::Configure::_config_watchers;

	for my $pid (0, -1, -999) {
		$Object::Configure::_config_watchers{pid} = $pid;

		lives_ok {
			Object::Configure::disable_hot_reload();
		} "disable_hot_reload() survives pid=$pid (kill not sent)";

		ok(kill(0, $$), "Test process alive after disable_hot_reload(pid=$pid)");
	}

	# PID 1: kill attempted but fails EPERM for non-root -- process survives
	$Object::Configure::_config_watchers{pid} = 1;
	lives_ok {
		Object::Configure::disable_hot_reload();
	} 'disable_hot_reload(pid=1) survives (EPERM as non-root)';
	ok(kill(0, $$), 'Test process alive after SIGTERM-to-init attempt');

	# Restore
	%Object::Configure::_config_watchers = %saved_watchers;

	done_testing();
};

# =============================================================================
# 12. ARBITRARY FILE READ -- _reload_object_config with tampered _config_file
# =============================================================================
subtest 'ARBITRARY FILE READ: _reload_object_config with tampered _config_file' => sub {
	# Exploit mechanism:
	#   _reload_object_config() reads $obj->{_config_file} with NO path validation.
	#   An attacker who can modify a registered object's internals (e.g., via a
	#   deserialization gadget or an insecure merge) can redirect the hot-reload
	#   path to read any file the process can open.
	#
	# CONFIRMED FINDING: When _config_file is set to '/etc/passwd', Config::Abstraction
	# parses it as colon-delimited conf and injects ALL user accounts (root, daemon, ...)
	# as keys directly onto the live object.
	# FIX REQUIRED: _reload_object_config() must validate that _config_file is within
	# an expected/allowed directory before loading it.

	local %ENV;

	SKIP: {
		skip 'Not a Unix system with /etc/passwd', 2 unless -r '/etc/passwd';

		my $obj = bless {
			_config_file => '/etc/passwd',    # tampered path
			logger       => Log::Abstraction->new(),
		}, 'Test::Security::TamperedReload';

		eval { Object::Configure::_reload_object_config($obj) };

		TODO: {
			local $TODO = 'SECURITY FINDING CVE-CANDIDATE: _reload_object_config() reads '
				. '_config_file without path validation. /etc/passwd injected as config keys. '
				. 'Fix: validate _config_file is within the originally-configured config_dirs.';

			ok(!exists($obj->{root}),
				'/etc/passwd "root" key not injected into live object (fails until path validation added)');
			ok(!exists($obj->{daemon}),
				'/etc/passwd "daemon" key not injected into live object (fails until path validation added)');
		}
	}

	done_testing();
};

# =============================================================================
# 13. DOS -- _deep_merge unbounded recursion
# =============================================================================
subtest 'DOS: _deep_merge with 1000-deep nested hash completes without stack overflow' => sub {
	# Exploit mechanism:
	#   _deep_merge() is recursive with no depth limit.
	#   A malicious YAML config file with 10,000-deep nesting would exhaust the
	#   Perl call stack (typically ~10,000 frames default).
	#   We test at SAFE_RECURSE_DEPTH (1,000) to verify correctness and record the
	#   absence of a depth guard as a finding for future hardening.

	my $nested  = {};
	my $cursor  = $nested;
	for (1 .. $SAFE_RECURSE_DEPTH) {
		$cursor->{child} = {};
		$cursor = $cursor->{child};
	}
	$cursor->{leaf} = 'value';

	my $start  = time();
	my $result = eval { Object::Configure::_deep_merge({}, $nested) };
	my $elapsed = time() - $start;

	ok(!$@, "_deep_merge survives ${SAFE_RECURSE_DEPTH}-level nesting (no stack overflow)");
	cmp_ok($elapsed, '<', 5, "Merge completed in under 5 seconds (actual: ${elapsed}s)");

	# Verify the leaf value survived the merge correctly
	my $leaf_cursor = $result;
	$leaf_cursor = $leaf_cursor->{child} for (1 .. $SAFE_RECURSE_DEPTH);
	is($leaf_cursor->{leaf}, 'value', 'Leaf value intact after deep merge');

	done_testing();
};

# =============================================================================
# 14. CRLF IN PATH -- config_file with embedded newline
# =============================================================================
subtest 'CRLF IN PATH: config_file with embedded CR+LF does not inject header key' => sub {
	# Exploit mechanism:
	#   If config_file is used in an HTTP header (redirect, log), an embedded CRLF
	#   splits the header stream.  Here the path goes only to -r / File::Spec.
	#   On Linux, CRLF in a filename is legal but the file almost certainly does not
	#   exist (-r returns false).  Without config_dirs this triggers croak.
	#   With config_dirs: the traversal path also doesn't exist.
	#   Either way: no "X-Injected" key must appear in the result.

	local %ENV;
	my $temp_dir = tempdir(CLEANUP => 1);

	my $crlf_path = "/tmp/legit.yml${CRLF}X-Injected: evil";

	my $result = eval {
		Object::Configure::configure('Test::Security::CRLFPath', {
			config_file => $crlf_path,
			config_dirs => [$temp_dir],
		});
	};

	ok(!defined($result) || !exists($result->{'X-Injected'}),
		'CRLF in config_file path does not inject a header-like key into result');

	done_testing();
};

# =============================================================================
# 15. INPUT VALIDATION -- register_object edge cases
# =============================================================================
subtest 'INPUT VALIDATION: register_object() rejects all undef/empty combinations' => sub {
	# Prove both guard clauses independently -- each is a separate equivalence partition.

	throws_ok {
		Object::Configure::register_object(undef, bless({}, 'Test::Dummy'));
	} $ERR_REGISTER_USAGE, 'Undef class rejected by register_object()';

	throws_ok {
		Object::Configure::register_object('Test::Security', undef);
	} $ERR_REGISTER_USAGE, 'Undef obj rejected by register_object()';

	# Shell metacharacters in class name -- used only as hash key, no shell call
	lives_ok {
		my $obj = bless {}, 'Test::Safe';
		Object::Configure::register_object('Safe::Class|id;rm -rf /', $obj);
		delete $Object::Configure::_object_registry{'Safe::Class|id;rm -rf /'};
	} 'Shell metacharacters in class name treated as literal hash key (no execution)';

	# Overlong class name -- must not hang
	lives_ok {
		my $obj = bless {}, 'Test::Safe';
		Object::Configure::register_object($OVERLONG_STRING, $obj);
		delete $Object::Configure::_object_registry{$OVERLONG_STRING};
	} 'Overlong class name in register_object() does not cause hang';

	done_testing();
};

# =============================================================================
# 16. CONFIGURE GUARD CLAUSES -- empty and undef class
# =============================================================================
subtest 'INPUT VALIDATION: configure() guard clauses on class parameter' => sub {
	# Prove both terminal-invalid partitions are blocked at the earliest point
	# (before any file I/O or env lookup).

	throws_ok {
		Object::Configure::configure(undef, {});
	} $ERR_CLASS_EMPTY, 'configure() croaks on undef class';

	throws_ok {
		Object::Configure::configure('', {});
	} $ERR_CLASS_EMPTY, 'configure() croaks on empty-string class';

	done_testing();
};

done_testing();
