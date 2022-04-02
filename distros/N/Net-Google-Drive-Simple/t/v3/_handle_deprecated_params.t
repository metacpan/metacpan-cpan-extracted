use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Warnings qw< warning no_warnings >;
use Test2::Plugin::NoWarnings;
use Test::MockModule qw< strict >;
use Net::Google::Drive::Simple::V3;
use Log::Log4perl qw< :easy >;

# Ugh... Couldn't find an easy way to trap Log4perl stuff
my $gd_mock = Test::MockModule->new('Net::Google::Drive::Simple::V3');
$gd_mock->redefine( 'WARN' => sub { warn $_[0] } );

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok( $gd, '_handle_deprecated_params' );

my $method = 'test_file';

subtest(
    'Warnings on default deprecations' => sub {
        my @tests = (
            { 'corpus'                => undef },
            { 'includeTeamDriveItems' => undef },
            { 'supportsTeamDrives'    => undef },
            { 'teamDriveId'           => undef },
        );

        foreach my $options (@tests) {
            my $name = ( keys %{$options} )[0];
            like(
                warning(
                    sub {
                        $gd->_handle_deprecated_params(
                            $method, {},
                            $options
                        );
                    }
                ),
                qr/^\Q[test_file] Parameter name '$name' is deprecated, use '\E[a-zA-Z]+\Q' instead\E/xms,
                "Got warning to avoid $name",
            );
        }
    }
);

subtest(
    'Overriding warnings on default deprecations' => sub {
        my @tests = (
            { 'corpus'                => 'c' },
            { 'includeTeamDriveItems' => 'i' },
            { 'supportsTeamDrives'    => 's' },
            { 'teamDriveId'           => 't' },
        );

        foreach my $options (@tests) {
            my $name = ( keys %{$options} )[0];
            my $alt  = $options->{$name};
            like(
                warning(
                    sub {
                        $gd->_handle_deprecated_params(
                            $method,
                            {

                                'deprecated_param_names' => $options
                            },
                            $options
                        );
                    }
                ),
                qr/^\Q[test_file] Parameter name '$name' is deprecated, use '$alt' instead\E/xms,
                "Got warning to avoid $name in favor of $alt (overridden alternative)",
            );
        }
    }
);

subtest(
    'Warnings on non-default deprecations' => sub {
        my @tests = (
            { 'foobar'                    => 'bazquux' },
            { 'corpora'                   => 'newcorp' },
            { 'includeItemsFromAllDrives' => 'newincl' },
            { 'supportsAllDrives'         => 'newsupp' },
            { 'driveId'                   => 'newdrive' },
        );

        foreach my $options (@tests) {
            my $name = ( keys %{$options} )[0];
            my $alt  = $options->{$name};
            like(
                warning(
                    sub {
                        $gd->_handle_deprecated_params(
                            $method,
                            {

                                'deprecated_param_names' => $options
                            },
                            $options
                        );
                    }
                ),
                qr/^\Q[test_file] Parameter name '$name' is deprecated, use '$alt' instead\E/xms,
                "Got warning to avoid $name in favor of $alt (new deprecation)",
            );
        }
    }
);

subtest(
    'Warnings on non-default deprecations' => sub {
        my @tests = (
            { 'corpora'                   => undef },
            { 'includeItemsFromAllDrives' => undef },
            { 'supportsAllDrives'         => undef },
            { 'driveId'                   => undef },
            { 'foobar'                    => undef },
        );

        foreach my $options (@tests) {
            my $name = ( keys %{$options} )[0];

            $gd->_handle_deprecated_params( $method, {}, $options );
            is(
                no_warnings(
                    sub {
                        $gd->_handle_deprecated_params(
                            $method, {},
                            $options
                        );
                    }
                ),
                1,
                "No warning to avoid $name",
            );
        }
    }
);

done_testing();
