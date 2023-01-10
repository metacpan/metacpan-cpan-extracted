use strict;
use warnings;
use Test::More;
use Sodium::FFI ();

# check the access functions
my $ver_string = Sodium::FFI::sodium_version_string();
my $ver_major = Sodium::FFI::sodium_library_version_major();
my $ver_minor = Sodium::FFI::sodium_library_version_minor();
ok($ver_string, "version string: $ver_string");
ok($ver_major, "version major: $ver_major");
ok($ver_minor, "version minor: $ver_minor");

# now check the constants
$ver_string = Sodium::FFI->SODIUM_VERSION_STRING;
$ver_major = Sodium::FFI->SODIUM_LIBRARY_VERSION_MAJOR;
$ver_minor = Sodium::FFI->SODIUM_LIBRARY_VERSION_MINOR;
ok($ver_string, "constant version string: $ver_string");
ok($ver_major, "constant version major: $ver_major");
ok($ver_minor, "constant version minor: $ver_minor");

# check the minimal function
my $error;
my $min;
{
    local $@;
    $error = $@ || 'Error' unless eval {
        $min = Sodium::FFI::sodium_library_minimal();
        1;
    };
}
if ($error) {
    ok("sodium_library_minimal is not defined in this version.");
}
else {
    ok($min == 0 || $min == 1, "sodium_library_minimal: $min");
}

done_testing;
