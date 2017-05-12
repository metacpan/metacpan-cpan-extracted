use Test::More;
use Test::Deep;
use POE::Filter::MessagePack;

my $filter = POE::Filter::MessagePack->new( canonical => 1 );

my %tdata = ( "\x82\xc4\x01\x61\x01\xc4\x01\x62\x02" => { a => 1, b => 2 }, );

isa_ok( $filter, 'POE::Filter::MessagePack' );

for my $packed ( keys %tdata ) {
    my $repacked = $filter->put( [ $tdata{$packed} ] );
    is( $repacked->[0], $packed );

    $filter->get_one_start( [$packed] );

    my $obj_array = $filter->get_one;

    is_deeply( $obj_array, [ $tdata{$packed} ] );
}

done_testing;
