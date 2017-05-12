use 5.010000;
use warnings;
use strict;
use Test::More;
use FindBin               qw( $RealBin );
use File::Spec::Functions qw( catfile );


BEGIN {
    if ( $^O eq 'MSWin32' ) {
        plan skip_all => "MSWin32: Expect not available.";
    }
    #if ( ! $ENV{TESTS_USING_EXPECT_OK} ) {
    #    plan skip_all => "Environment variable 'TESTS_USING_EXPECT_OK' not enabled.";
    #}
}


eval "use Expect";
if ( $@ ) {
    plan skip_all => "Expect required for $0.";
}


eval "use Term::ReadKey";
if ( $@ ) {
    plan skip_all => $@;
}


use Term::Choose::Constants qw( :linux );


my $script = catfile $RealBin, 'get_key_linux.pl';

eval {
    my $exp = Expect->new();
    $exp->raw_pty( 1 );
    $exp->slave->set_winsize( 24, 80, undef, undef );
    -r $script or die "$script is NOT readable $!";
    $exp->spawn( $script ) or die "Spawn '$script' NOT ok $!";
    1;
}
or plan skip_all => $@;


for my $char ( qw( h j k l q ), ' ', "\t" ) {
    my $exp = Expect->new();
    $exp->raw_pty( 1 );
    $exp->slave->set_winsize( 24, 80, undef, undef );
    $exp->spawn( $script );
    $exp->send( $char );
    my $expected = '<' . ord( $char ) . '>';
    my $ret = $exp->expect( 3, [ qr/...+/ ]  );
    ok( $ret, 'matched something' );
    my $result = $exp->match() // '';
    ok( $result eq $expected, "expected: '$expected', got: '$result'" );
    $exp->soft_close();
}


for my $char ( "\cA", "\cB", "\cC", "\cD", "\cE", "\cF", "\cH", "\cI", "\c@" ) {
    my $exp = Expect->new();
    $exp->raw_pty( 1 );
    $exp->slave->set_winsize( 24, 80, undef, undef );
    $exp->spawn( $script );
    $exp->send( $char );
    my $expected = '<' . ord( $char ) . '>';
    my $ret = $exp->expect( 3, [ qr/...+/ ] );
    ok( $ret, 'matched something' );
    my $result = $exp->match() // '';
    ok( $result eq $expected, "expected: '$expected', got: '$result'" );
    $exp->soft_close();
}


my $array = [
    [ [ "\e[A", "\eOA" ],   VK_UP ],
    [ [ "\e[B", "\eOB" ],   VK_DOWN ],
    [ [ "\e[C", "\eOC" ],   VK_RIGHT ],
    [ [ "\e[D", "\eOD" ],   VK_LEFT ],
    [ [ "\e[F", "\eOF" ],   VK_END ],
    [ [ "\e[H", "\eOH" ],   VK_HOME ],
    [ [ "\e[Z", "\eOZ" ],   KEY_BTAB ],
    [ [ "\e[5~" ],          VK_PAGE_UP ],
    [ [ "\e[6~" ],          VK_PAGE_DOWN ],
];

for my $elem ( @$array ) {
    for my $seq ( @{$elem->[0]} ) {
        my $exp = Expect->new();
        $exp->raw_pty( 1 );
        $exp->slave->set_winsize( 24, 80, undef, undef );
        $exp->spawn( $script );
        $exp->send( $seq );
        my $expected = '<' . $elem->[1] . '>';
        my $ret = $exp->expect( 3, [ qr/...+/ ] );
        ok( $ret, 'matched something' );
        my $result = $exp->match() // '';
        ok( $result eq $expected, "expected: '$expected', got: '$result'" );
        $exp->soft_close();
    }
}

done_testing();
