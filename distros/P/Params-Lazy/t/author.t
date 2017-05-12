#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        plan( skip_all => "Author tests not required for installation" );
    }
}

subtest manifest => sub {
    my $min_tcm = 0.9;
    eval "use Test::CheckManifest $min_tcm";
    plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

    ok_manifest();
};

subtest pod => sub {
    # Ensure a recent version of Test::Pod
    my $min_tp = 1.22;
    eval "use Test::Pod $min_tp";
    plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

    all_pod_files_ok();
};

subtest pod_coverage => sub {
    # Ensure a recent version of Test::Pod::Coverage
    my $min_tpc = 1.08;
    eval "use Test::Pod::Coverage $min_tpc";
    plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
        if $@;

    # Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
    # but older versions don't recognize some common documentation styles
    my $min_pc = 0.18;
    eval "use Pod::Coverage $min_pc";
    plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
        if $@;

    all_pod_coverage_ok();
};

subtest boilerplate => sub {
    plan tests => 3;

    sub not_in_file_ok {
        my ($filename, %regex) = @_;
        open( my $fh, '<', $filename )
            or die "couldn't open $filename for reading: $!";

        my %violated;

        while (my $line = <$fh>) {
            while (my ($desc, $regex) = each %regex) {
                if ($line =~ $regex) {
                    push @{$violated{$desc}||=[]}, $.;
                }
            }
        }

        if (%violated) {
            fail("$filename contains boilerplate text");
            diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
        } else {
            pass("$filename contains no boilerplate text");
        }
    }

    sub module_boilerplate_ok {
        my ($module) = @_;
        not_in_file_ok($module =>
            'the great new $MODULENAME'   => qr/ - The great new /,
            'boilerplate description'     => qr/Quick summary of what the module/,
            'stub function definition'    => qr/function[12]/,
        );
    }

    not_in_file_ok(README =>
      "The README is used..."       => qr/The README is used/,
      "'version information here'"  => qr/to provide version information/,
    );

    not_in_file_ok(Changes =>
      "placeholder date/time"       => qr(Date/time)
    );

    module_boilerplate_ok('lib/Params/Lazy.pm');
};

done_testing;
