#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::MockModule;
use feature 'say';
use FindBin;
use lib "$FindBin::Bin/../lib";

# ---------------------------------------------------------
# Override exit BEFORE loading NVMPL::Core
# ---------------------------------------------------------
BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::exit = sub { 
        my $code = shift;
        die "EXIT: $code" if defined $code && $code != 0;
        return;
    };
}

# ---------------------------------------------------------
# Now load the module
# ---------------------------------------------------------
use NVMPL::Core;

# ---------------------------------------------------------
# Mock dependencies
# ---------------------------------------------------------

my $installer = Test::MockModule->new('NVMPL::Installer');
my $switcher = Test::MockModule->new('NVMPL::Switcher');
my $remote = Test::MockModule->new('NVMPL::Remote');
my $uninstaller = Test::MockModule->new('NVMPL::Uninstaller');  # Add uninstaller mock

my %called;

$installer->mock('install_version', sub { 
    $called{install} = 1; 
    return 1;
});

$switcher->mock('use_version', sub { 
    $called{use} = 1; 
    return 1;
});

$switcher->mock('list_installed', sub { 
    $called{ls} = 1; 
    return ["v18.0.0", "v20.0.0"];
});

$switcher->mock('show_current', sub { 
    $called{current} = 1; 
    return "v20.0.0";
});

$remote->mock('list_remote_versions', sub { 
    $called{ls_remote} = 1; 
    return ["v21.0.0", "v22.0.0"];
});

# Mock the uninstaller to track calls and avoid actual file operations
$uninstaller->mock('uninstall_version', sub { 
    $called{uninstall} = 1; 
    say "[nvm-pl] Uninstalling Node.js version: $_[0] (mock)";
    return 1;
});

# We're running 9 tests based on the output
plan tests => 10;

# ---------------------------------------------------------
# 1. Test missing command
# ---------------------------------------------------------
eval {
    NVMPL::Core::dispatch();
};
like($@, qr/EXIT: 1/, 'missing command calls exit 1');

# ---------------------------------------------------------
# 2. Test unknown command  
# ---------------------------------------------------------
eval {
    NVMPL::Core::dispatch('unknowncmd');
};
like($@, qr/EXIT: 1/, 'unknown command calls exit 1');

# ---------------------------------------------------------
# 3. Test known commands - these should NOT call exit
# ---------------------------------------------------------
%called = ();

eval { 
    NVMPL::Core::dispatch('install', '22.0.0');
    1;
} or do {
    fail("install command called exit: $@");
};
ok($called{install}, 'install command routed correctly');

eval { 
    NVMPL::Core::dispatch('use', '20');
    1;
} or do {
    fail("use command called exit: $@");
};
ok($called{use}, 'use command routed correctly');

eval { 
    NVMPL::Core::dispatch('ls');
    1;
} or do {
    fail("ls command called exit: $@");
};
ok($called{ls}, 'ls command routed correctly');

eval { 
    NVMPL::Core::dispatch('ls-remote');
    1;
} or do {
    fail("ls-remote command called exit: $@");
};
ok($called{ls_remote}, 'ls-remote command routed correctly');

eval { 
    NVMPL::Core::dispatch('current');
    1;
} or do {
    fail("current command called exit: $@");
};
ok($called{current}, 'current command routed correctly');

# ---------------------------------------------------------
# 4. Test commands that print to STDOUT
# ---------------------------------------------------------
{
    local *STDOUT;
    my $output = '';
    open STDOUT, '>', \$output or die "Can't capture STDOUT: $!";
    
    eval { 
        NVMPL::Core::dispatch('cache', 'clean');
        1;
    } or do {
        fail("cache command called exit: $@");
    };
    
    like($output, qr/Cache command: clean/, 'cache subcommand prints message');
}

{
    local *STDOUT;
    my $output = '';
    open STDOUT, '>', \$output or die "Can't capture STDOUT: $!";
    
    eval { 
        NVMPL::Core::dispatch('uninstall', '20.0.0');
        1;
    } or do {
        fail("uninstall command called exit: $@");
    };
    
    # Updated to match the actual mock output
    like($output, qr/Uninstalling Node\.js version.*\(mock\)/, 'uninstall command prints message');
    ok($called{uninstall}, 'uninstall command routed correctly');
}