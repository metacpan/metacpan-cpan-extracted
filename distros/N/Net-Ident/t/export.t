# Tests for Net::Ident export hooks: the :fh, :apache, and :debug tags,
# and the export_fail dispatch mechanism that drives them.
#
# These test the rarely-exercised Exporter extension that makes
# "use Net::Ident ':fh'" add methods to other packages.

use 5.010;
use strict;
use warnings;
use Test::More;

# We need to test import effects in isolated ways, so we load the module
# first without any tags, then test the mechanics directly.
use Net::Ident;

# === %EXPORT_HOOKS and @EXPORT_FAIL setup ===

subtest 'EXPORT_HOOKS registered correctly' => sub {
    ok(exists $Net::Ident::EXPORT_HOOKS{fh},     'fh hook registered');
    ok(exists $Net::Ident::EXPORT_HOOKS{apache},  'apache hook registered');
    ok(exists $Net::Ident::EXPORT_HOOKS{debug},   'debug hook registered');
    is(ref $Net::Ident::EXPORT_HOOKS{fh},     'CODE', 'fh hook is a coderef');
    is(ref $Net::Ident::EXPORT_HOOKS{apache},  'CODE', 'apache hook is a coderef');
    is(ref $Net::Ident::EXPORT_HOOKS{debug},   'CODE', 'debug hook is a coderef');
};

subtest 'EXPORT_FAIL contains hook pseudo-functions' => sub {
    my %fail = map { $_ => 1 } @Net::Ident::EXPORT_FAIL;
    ok($fail{_export_hook_fh},     '_export_hook_fh in EXPORT_FAIL');
    ok($fail{_export_hook_apache}, '_export_hook_apache in EXPORT_FAIL');
    ok($fail{_export_hook_debug},  '_export_hook_debug in EXPORT_FAIL');
};

subtest 'EXPORT_TAGS contain hook pseudo-functions' => sub {
    is_deeply($Net::Ident::EXPORT_TAGS{fh},     ['_export_hook_fh'],     ':fh tag');
    is_deeply($Net::Ident::EXPORT_TAGS{apache},  ['_export_hook_apache'], ':apache tag');
    is_deeply($Net::Ident::EXPORT_TAGS{debug},   ['_export_hook_debug'],  ':debug tag');
};

subtest 'EXPORT_OK contains hook pseudo-functions and real exports' => sub {
    my %ok = map { $_ => 1 } @Net::Ident::EXPORT_OK;
    ok($ok{_export_hook_fh},     '_export_hook_fh in EXPORT_OK');
    ok($ok{_export_hook_apache}, '_export_hook_apache in EXPORT_OK');
    ok($ok{_export_hook_debug},  '_export_hook_debug in EXPORT_OK');
    ok($ok{ident_lookup},        'ident_lookup in EXPORT_OK');
    ok($ok{lookup},              'lookup in EXPORT_OK');
    ok($ok{lookupFromInAddr},    'lookupFromInAddr in EXPORT_OK');
};


# === export_fail dispatch ===

subtest 'export_fail dispatches known hooks' => sub {
    # Save and restore DEBUG to avoid side effects
    my $orig_debug = $Net::Ident::DEBUG;

    # Calling export_fail with a known hook pseudo-function should
    # invoke the hook and return an empty list (success)
    my @remaining = Net::Ident->export_fail('_export_hook_debug');
    is(scalar @remaining, 0, 'known hook consumed by export_fail');
    is($Net::Ident::DEBUG, $orig_debug + 1, 'debug hook incremented $DEBUG');

    $Net::Ident::DEBUG = $orig_debug;
};

subtest 'export_fail passes unknown symbols upstream' => sub {
    # Unknown symbols should be passed to SUPER::export_fail.
    # Exporter::export_fail returns them as-is (still failed).
    my @remaining = Net::Ident->export_fail('_no_such_export_xyz');
    is_deeply(\@remaining, ['_no_such_export_xyz'],
        'unknown symbol passes through to SUPER');
};

subtest 'export_fail handles mix of known and unknown' => sub {
    my $orig_debug = $Net::Ident::DEBUG;

    my @remaining = Net::Ident->export_fail(
        '_export_hook_debug',
        '_no_such_export_abc',
    );
    is(scalar @remaining, 1, 'one symbol remains after dispatch');
    is($remaining[0], '_no_such_export_abc', 'unknown symbol returned');
    is($Net::Ident::DEBUG, $orig_debug + 1, 'debug hook still fired');

    $Net::Ident::DEBUG = $orig_debug;
};


# === :fh tag — _add_fh_method ===

subtest ':fh adds ident_lookup to the right package' => sub {
    # Determine which package should receive the method
    my $expected_pkg = grep(/^IO::/, @FileHandle::ISA)
        ? "IO::Handle" : "FileHandle";

    # Call the hook directly
    Net::Ident::_add_fh_method();

    # Check the method exists
    my $method = $expected_pkg->can('ident_lookup');
    ok($method, "ident_lookup method added to $expected_pkg");
    is($method, \&Net::Ident::lookup,
        "method is a reference to Net::Ident::lookup");
};

subtest ':fh makes FileHandle objects respond to ident_lookup' => sub {
    # A FileHandle object should now have the ident_lookup method
    # (via inheritance from IO::Handle or directly)
    ok(FileHandle->can('ident_lookup'),
        'FileHandle->can("ident_lookup") after :fh hook');
};


# === :apache tag — _add_apache_method ===

subtest ':apache adds ident_lookup to Apache::Connection' => sub {
    # Call the hook directly
    Net::Ident::_add_apache_method();

    # Check the method exists
    ok(Apache::Connection->can('ident_lookup'),
        'Apache::Connection has ident_lookup method');

    # Verify it's a coderef (the apache method is a closure, not
    # a direct alias to lookup)
    my $method = Apache::Connection->can('ident_lookup');
    is(ref $method, 'CODE', 'method is a coderef');
};


# === :debug tag — _set_debug ===

subtest ':debug increments DEBUG level' => sub {
    my $orig = $Net::Ident::DEBUG;

    # Redirect STDDBG to avoid noise
    my $output = '';
    {
        local *Net::Ident::STDDBG;
        open(Net::Ident::STDDBG, '>', \$output) or die "open: $!";
        Net::Ident::_set_debug();
    }

    is($Net::Ident::DEBUG, $orig + 1, 'DEBUG incremented by 1');
    like($output, qr/Debugging turned to level/, 'debug message printed');

    $Net::Ident::DEBUG = $orig;
};

subtest ':debug stacks — multiple calls increase level' => sub {
    my $orig = $Net::Ident::DEBUG;

    {
        local *Net::Ident::STDDBG;
        open(Net::Ident::STDDBG, '>', \my $devnull) or die "open: $!";
        Net::Ident::_set_debug();
        Net::Ident::_set_debug();
        Net::Ident::_set_debug();
    }

    is($Net::Ident::DEBUG, $orig + 3, 'three calls increment DEBUG by 3');

    $Net::Ident::DEBUG = $orig;
};


# === Full import simulation ===

subtest 'use Net::Ident with :fh tag via import' => sub {
    # Simulate what "use Net::Ident ':fh'" does
    # The import mechanism goes through Exporter, which calls export_fail
    # for symbols in @EXPORT_FAIL. We test the whole chain here.

    # Create a fresh test package to verify the import doesn't pollute
    {
        package TestImportFH;
        Net::Ident->import(':fh');
    }

    # The :fh tag should have caused _add_fh_method to run
    ok(FileHandle->can('ident_lookup'),
        'FileHandle has ident_lookup after import(:fh)');
};

subtest 'ident_lookup can be imported as a function' => sub {
    {
        package TestImportFunc;
        Net::Ident->import('ident_lookup');
    }

    ok(TestImportFunc->can('ident_lookup'),
        'ident_lookup imported as function into test package');
};

subtest 'lookup can be imported as a function' => sub {
    {
        package TestImportLookup;
        Net::Ident->import('lookup');
    }

    ok(TestImportLookup->can('lookup'),
        'lookup imported as function into test package');
};

subtest 'lookupFromInAddr can be imported as a function' => sub {
    {
        package TestImportLFIA;
        Net::Ident->import('lookupFromInAddr');
    }

    ok(TestImportLFIA->can('lookupFromInAddr'),
        'lookupFromInAddr imported as function into test package');
};


done_testing;
