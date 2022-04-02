use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Exception qw/dies lives/;
use Test2::Plugin::NoWarnings;
use Net::Google::Drive::Simple::V3;

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok( $gd, '_validate_param_type' );

my $method = 'test_file';

like(
    dies(
        sub {
            $gd->_validate_param_type(
                $method, {},
                { 'unknown_param' => 'value' },
            );
        }
    ),
    qr/^\Q[test_file] Parameter name 'unknown_param' does not exist\E/xms,
    'Parameter must exist',
);

like(
    dies(
        sub {
            $gd->_validate_param_type(
                $method, { 'foo' => [ 'string', 1 ] },
                {},
            );
        }
    ),
    qr/^\Q[test_file] Parameter 'foo' is required\E/xms,
    'Required parameter must be available',
);

is(
    lives(
        sub {
            $gd->_validate_param_type(
                $method, { 'foo' => [ 'string', 0 ] },
                {},
            );
        }
    ),
    1,
    'Optional parameter does not need to be available',
);

like(
    dies(
        sub {
            $gd->_validate_param_type(
                $method,
                { 'foo' => [ 'nonexistenttype', 1 ] },
                { 'foo' => 'bar' },
            );
        }
    ),
    qr/^\Q[test_file] Parameter type 'nonexistenttype' does not exist\E/xms,
    'Required parameter must be available',
);

subtest(
    'Failing parameter types' => sub {
        my %types = (
            'string'  => [ undef,    '' ],
            'integer' => [ 'string', undef,  123.51 ],
            'long'    => [ 'string', undef,  123.51 ],
            'boolean' => [ undef,    1123,   14.123, 'string' ],
            'object'  => [ [],       \'foo', undef,  123, 123.5, 'string' ],
            'bytes'   => [ undef,    '', ],
        );

        foreach my $type ( sort keys %types ) {
            foreach my $value ( @{ $types{$type} } ) {
                like(
                    dies(
                        sub {
                            $gd->_validate_param_type(
                                $method,
                                { 'foo' => [ $type, 1 ] },
                                { 'foo' => $value },
                            );
                        }
                    ),
                    qr/^\Q[test_file] Parameter type 'foo' does not validate as '$type'\E/xms,
                    "Testing type '$type' with value '" . ( $value || '(undef)' ) . "'",
                );
            }
        }

    }
);

subtest(
    'Successful parameter types' => sub {
        my %types = (
            'string'  => [ 'foo', '12354' ],
            'integer' => [123],
            'long'    => [123],
            'boolean' => [ 0, 1 ],
            'object'  => [ {} ],
            'bytes'   => ['foo'],
        );

        foreach my $type ( sort keys %types ) {
            foreach my $value ( @{ $types{$type} } ) {
                is(
                    lives(
                        sub {
                            $gd->_validate_param_type(
                                $method,
                                { 'foo' => [ $type, 1 ] },
                                { 'foo' => $value },
                            );
                        }
                    ),
                    1,
                    "Testing type '$type' with value '" . ( $value || '(undef)' ) . "'",
                );
            }
        }

    }
);

done_testing();
