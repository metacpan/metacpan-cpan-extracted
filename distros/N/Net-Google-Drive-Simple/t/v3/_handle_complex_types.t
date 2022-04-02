use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Exception qw/dies lives/;
use Test2::Plugin::NoWarnings;
use Net::Google::Drive::Simple::V3;

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok( $gd, '_handle_complex_types' );

my $method = 'test_file';

my @failing_tests = (
    { 'includePermissionsForView' => 'nonpublished' },
    { 'pageSize'                  => 0 },
    { 'pageSize'                  => 1_001 },
    { 'pageSize'                  => -1 },
    { 'pageSize'                  => 3_000 },
    { 'uploadType'                => 'm' },
    { 'uploadType'                => 'part' },
    { 'uploadType'                => 'nonresumable' },
);

my @success_tests = (
    { 'includePermissionsForView' => 'published' },
    { 'pageSize'                  => 1 },
    { 'pageSize'                  => 1_000 },
    { 'pageSize'                  => 2 },
    { 'pageSize'                  => 999 },
    { 'uploadType'                => 'media' },
    { 'uploadType'                => 'multipart' },
    { 'uploadType'                => 'resumable' },
    { 'other_param'               => 'somevalue' },
);

subtest(
    'Failing complex types' => sub {
        foreach my $test (@failing_tests) {
            my $param = ( keys %{$test} )[0];
            my $message =
                $param eq 'includePermissionsForView' ? 'published'
              : $param eq 'pageSize'                  ? '1 to 1000'
              :                                         'media|multipart|resumable';

            like(
                dies( sub { $gd->_handle_complex_types( $method, $test ) } ),
                qr/^\Q[test_file] Parameter '$param' must be: $message\E/xms,
                "Correct error message when $param => $test->{$param}",
            );
        }
    }
);

subtest(
    'Succeeding complex types' => sub {
        foreach my $test (@success_tests) {
            my $param = ( keys %{$test} )[0];
            is(
                lives( sub { $gd->_handle_complex_types( $method, $test ) } ),
                1,
                "Correct error message when $param => $test->{$param}",
            );
        }
    }
);

done_testing();
