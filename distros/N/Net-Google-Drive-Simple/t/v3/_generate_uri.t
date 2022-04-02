use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Net::Google::Drive::Simple::V3;

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok( $gd, '_generate_uri' );

my $base = 'http://foobar/baz/';
$gd->{'api_base_url'} = $base;
is( $gd->{'api_base_url'}, $base, 'Set api_base_url correctly' );

is(
    $gd->_generate_uri('files')->as_string(),
    $base . 'files',
    'Add path to generated uri',
);

is(
    $gd->_generate_uri('http://special/files')->as_string(),
    'http://special/files',
    'Handle absolute path in generated uri',
);

is(
    $gd->_generate_uri( 'foo', { 'q' => 'hello' } )->as_string(),
    'http://foobar/baz/foo?q=hello',
    'Handled parameters well',
);

done_testing();
