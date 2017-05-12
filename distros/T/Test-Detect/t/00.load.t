use Test::More tests => 6;

BEGIN {
    use_ok('Test::Detect');
}

diag("Testing Test::Detect $Test::Detect::VERSION");

Test::Detect->import();
ok( defined &detect_testing, 'exports detect_testing() by import()' );

my $rv;

{
    local %ENV = ();
    local %INC = ();
    $rv = detect_testing();
}
ok( !$rv, 'detect_testing() RV false when conditions are not met' );

$rv = undef;
{
    local %ENV = ( 'TAP_VERSION' => 42 );
    local %INC = ();
    $rv = detect_testing();
}
ok( $rv, 'detect_testing() RV true when %ENV has TAP_VERSION' );

$rv = undef;
{
    local %ENV = ();
    local %INC = ( 'Test/More.pm' => 1 );
    $rv = detect_testing();
}
ok( $rv, 'detect_testing() RV true when %INC has Test/More.pm' );

$rv = undef;
{
    local %ENV = ();
    local %INC = ( 'Test/Builder.pm' => 1 );
    $rv = detect_testing();
}
ok( $rv, 'detect_testing() RV true when %INC has Test/Builder.pm' );
