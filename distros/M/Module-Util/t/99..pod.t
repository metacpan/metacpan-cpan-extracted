use strict;
use warnings;

use File::Spec::Functions qw( catdir );
use Test::More tests => 3;

BEGIN {
    use_ok('Module::Util', qw( find_installed module_fs_path ));
}

SKIP: {
    eval {
        require Test::Pod;
        import Test::Pod;
    };

    skip "Test::Pod not installed", 1 if $@;

    my $file = find_installed('Module::Util', catdir 'lib');
    
    pod_file_ok($file, "Module::Util pod ok");
}

SKIP: {
    eval {
        require Test::Pod::Coverage;
        import Test::Pod::Coverage;
    };

    skip "Test::Pod::Coverage not installed", 1 if $@;

    pod_coverage_ok(
        'Module::Util',
        "Module::Util pod coverage ok"
    );
}

__END__

vim: ft=perl
