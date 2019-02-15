#!/usr/bin/env perl
use strictures 2;

use Time::HiRes qw();

use Storable qw( freeze nfreeze dclone );
use Sereal::Encoder qw( encode_sereal );
use Sereal::Decoder;
use JSON::XS qw( encode_json decode_json );
use YAML::XS qw();
use Data::Dumper qw( Dumper );

my $iters = 100_000;

my $data = {
    user => 1234567,
    agent => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
    ip => '129.394.12.34',
    form => {
        password => 'asddsads',
        user => 'asdads@asdjasidj.com',
        _submit => 1,
    },
    ab_tests => [
        [green_button => 1],
        [blue_background => 0],
        [force_register => 0],
    ],
};

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Purity = 1;

my $oo_sereal_encoder = Sereal::Encoder->new();
my $oo_canonical_sereal_encoder = Sereal::Encoder->new({ canonical => 1 });
my $oo_sereal_decoder = Sereal::Decoder->new();
my $oo_jsonxs = JSON::XS->new();
my $oo_canonical_jsonxs = JSON::XS->new->canonical();

my %tests = (
    Storable_freeze => sub{
        freeze( $data );
    },
    Storable_nfreeze => sub{
        nfreeze( $data );
    },
    Storable_freeze_canonical => sub{
        freeze( $data );
    },
    Storable_nfreeze_canonical => sub{
        nfreeze( $data );
    },
    Storable_dclone => sub{
        dclone( $data );
    },
    Sereal_encode => sub{
        encode_sereal( $data );
    },
    Sereal_encode_oo => sub{
        $oo_sereal_encoder->encode( $data );
    },
    Sereal_encode_oo_canonical => sub{
        $oo_canonical_sereal_encoder->encode( $data );
    },
    Sereal_clone_oo => sub{
        $oo_sereal_decoder->decode( $oo_sereal_encoder->encode( $data ) );
    },
    JSONXS_encode => sub{
        encode_json( $data );
    },
    JSONXS_clone => sub{
        decode_json( encode_json( $data ) );
    },
    JSONXS_encode_oo => sub{
        $oo_jsonxs->encode( $data );
    },
    JSONXS_oo_canonical_encode => sub{
        $oo_canonical_jsonxs->encode( $data );
    },
    JSONXS_clone_oo => sub{
        $oo_jsonxs->decode( $oo_jsonxs->encode( $data ) );
    },
    YAMLXS_encode => sub{
        YAML::XS::Dump( $data );
    },
    YAMLXS_clone => sub{
        YAML::XS::Load( YAML::XS::Dump( $data ) );
    },
    DD_encode => sub{
        Dumper( $data );
    },
    DD_clone => sub{
        eval Dumper( $data );
    },
);

foreach my $test_name (sort keys %tests) {
    my $test_sub = $tests{ $test_name };

    local $Storable::canonical = 1 if $test_name =~ m{canonical};

    $test_sub->();

    my $start = Time::HiRes::time();
    foreach (1..$iters) {
        $test_sub->();
    }
    my $end = Time::HiRes::time();

    my $run_time = $end - $start;
    printf("%s %.02f -> %d/s\n", $test_name, $run_time, $iters/$run_time );
}
