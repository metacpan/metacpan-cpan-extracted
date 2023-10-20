#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    use lib './lib';
    use vars qw( $DEBUG );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

eval "use CBOR::Free 0.32;";
plan( skip_all => "CBOR::Free 0.32 required for testing serialisation with CBOR::Free" ) if( $@ );

# CBOR::Free only supports non blessed references
my $hash = { name => 'Momo Taro', location => 'Okayama', type => 'legend' };
my $array = [qw( Jack John Paul Peter )];
my $serialised = CBOR::Free::encode( $hash );
my $hash2 = CBOR::Free::decode( $serialised );
is_deeply( $hash2 => $hash, 'deserialised hash match original' );

$serialised = CBOR::Free::encode( $array );
my $array2 = CBOR::Free::decode( $serialised );
is_deeply( $array2 => $array, 'deserialised array match original' );

done_testing();

__END__

