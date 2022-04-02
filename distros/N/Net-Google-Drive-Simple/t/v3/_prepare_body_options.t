use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Net::Google::Drive::Simple::V3;

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok( $gd, '_prepare_body_options' );

my $body_params = [qw< foo bar baz quux >];

my $options = {
    'foo'  => 'fooval',
    'bar'  => '',
    'baz'  => 0,
    'quux' => undef,

    'qfoo'  => 'qfooval',
    'qbar'  => '',
    'qbaz'  => 0,
    'qquux' => undef,
};

is(
    $gd->_prepare_body_options( $options, $body_params ),
    {
        'foo'  => 'fooval',
        'bar'  => '',
        'baz'  => 0,
        'quux' => undef,
    },
    'Corretly extracted body parameters',
);

is(
    $options,
    {
        'qfoo'  => 'qfooval',
        'qbar'  => '',
        'qbaz'  => 0,
        'qquux' => undef,
    },
    'Correctly cleaned up options',
);

done_testing();
