#!perl -T
use warnings;
use strict;

### Test warnings
use Test::Config::System;

eval "use Test::Warn qw//";
if ($@) {
    plan skip_all => 'Test::Warn not installed';
    exit;
} else {
    plan tests => 10;
}

### The following required if these tests are to be optional:
### Can't load the module at runtime with an eval and have the prototypes
### work properly.

{
sub warning_is   (&$;$) { Test::Warn::warning_is   (@_) };
sub warning_like (&$;$) { Test::Warn::warnings_like(@_) };
}

### check_file_contents

warning_is { check_file_contents() } {carped => 'Filename required' }, "check_file_contents (no args)";
warning_is { check_file_contents('aoeu') } {carped => 'qr// style regex required'}, "check_file_contents (no regexp)";

### check_package

warning_is { check_package() } {carped => 'Package name required'}, "check_package (no args)";
warning_is { check_package(';touch /tmp/asdf') } {carped =>
    'Invalid package name.  If this is an error and the package is indeed valid, *please* file a bug.'},
    "check_package (shell bad package name)";
warning_like { check_package('perl', undef, 0, 'invalid_package_manager') }
             { carped => qr/Package manager .* is not supported/},
             "check_package (invalid pkg manager)";

### check_any_package

warning_is { check_any_package("foo") } {carped => 'Require a list of package names'}, "check_any_package (non-listref)";

## This was almost a bug that slipped through a commit
warning_like { check_any_package(['perl'], 'perl', 0, 'invalid_package_manager') }
             { carped => qr/Package manager .* is not supported/},
             "check_any_package (invalid pkg manager)";

### check_link

warning_is { check_link() } {carped => 'Filename required'}, "check_link (no args)";

### check_file

warning_is { check_file() } {carped => 'Filename required'}, "check_file (no args)";

### check_dir

warning_is { check_dir() } {carped => 'Directory name required'}, "check_dir (no args)";
