use strictures 2;

use if !(-e 'META.yml'), "Test::InDistDir";
use Test::More;

BEGIN {

    package MainRole;
    use Muuse::Role;
    use Test::More;
    ro "roletest";
    ok( MainRole->can( $_ ), "role can do $_" ) for qw( ro lazy rwp rw );
}

use Muuse;

ro "test";
ok( main->can( $_ ), "class can do $_" ) for qw( ro lazy rwp rw );
with "MainRole";

run();
done_testing;
exit;

sub run {
    my $s = main->new( test => 3, roletest => 3 );
    is eval { $s->test( 2 ); 1 }, undef, "test is indeed ro";
    is $s->test, 3, "reading test works";
    is eval { $s->roletest( 2 ); 1 }, undef, "roletest is indeed ro";
    is $s->roletest, 3, "reading roletest works";
    return;
}
