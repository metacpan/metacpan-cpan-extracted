use Test::More;

BEGIN {
    use_ok( 'Sque' );
}

{
    ok ( my $r = Sque->new(), 'Build default object' );
    test_namespace( $r => 'sque' );
}
{
    ok ( my $r = Sque->new( namespace => 'perl' ), 'Build default object' );
    test_namespace( $r => 'perl' );
}

sub test_namespace {
    my ( $r, $namespace ) = @_;
    is ( $r->namespace, $namespace, "Default namespace is $namespace" );
    is ( $r->key( 'test' ), "/queue/$namespace/test",
            'Key generator use namespace' );
}

done_testing;
