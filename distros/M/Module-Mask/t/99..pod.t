BEGIN {
    our @modules = qw(
        Module::Mask
    );
}

use Module::Util qw( find_installed );

use Test::More tests => our @modules * 2;

SKIP: {
    eval {
        require Test::Pod;
        import Test::Pod;
    };

    skip "Test::Pod not installed", scalar @modules if $@;

    for my $module (@modules) {
        my $file = find_installed($module, 'lib');
        
        pod_file_ok($file, "$module pod ok");
    }
}

SKIP: {
    eval {
        require Test::Pod::Coverage;
        import Test::Pod::Coverage;
    };

    skip "Test::Pod::Coverage not installed", scalar @modules if $@;

    for my $module (@modules) {
        pod_coverage_ok(
            $module,
            { also_private => [ qr(^[[:upper:][:digit:]_]+$|INC$) ] },
            "$module pod coverage ok"
        );
    }
}

__END__

vim: ft=perl
