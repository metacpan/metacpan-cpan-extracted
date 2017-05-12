use Modern::Perl;
use Net::Discident;
use Test::More      tests => 4;


my $ident = Net::Discident->new();

# DATA - a known hex fingerprint, and a known long fingerprint
my $long_kiss_goodnight_fingerprint = '3DF28C7A-3EB4-41F2-7CD8-27B691EF984D';
my $buck_rogers_s1_d1 = q(:/VIDEO_TS/VIDEO_TS.BUP:16384:/VIDEO_TS/VIDEO_TS.IFO:16384:/VIDEO_TS/VIDEO_TS.VOB:321536:/VIDEO_TS/VTS_01_0.BUP:126976:/VIDEO_TS/VTS_01_0.IFO:126976:/VIDEO_TS/VTS_01_0.VOB:1404928:/VIDEO_TS/VTS_01_1.VOB:1073608704:/VIDEO_TS/VTS_01_2.VOB:1073412096:/VIDEO_TS/VTS_01_3.VOB:1073539072:/VIDEO_TS/VTS_01_4.VOB:1073440768:/VIDEO_TS/VTS_01_5.VOB:1073489920:/VIDEO_TS/VTS_01_6.VOB:1073731584:/VIDEO_TS/VTS_01_7.VOB:1030516736:/VIDEO_TS/VTS_02_0.BUP:18432:/VIDEO_TS/VTS_02_0.IFO:18432:/VIDEO_TS/VTS_02_0.VOB:10240:/VIDEO_TS/VTS_02_1.VOB:20172800:/VIDEO_TS/VTS_03_0.BUP:18432:/VIDEO_TS/VTS_03_0.IFO:18432:/VIDEO_TS/VTS_03_0.VOB:10240:/VIDEO_TS/VTS_03_1.VOB:17948672);



# test that we can get data using just the long fingerprint
my $fingerprint = $ident->fingerprint( '/dev/null', $buck_rogers_s1_d1 );
is( $fingerprint, 'D62AD3CB-2739-07E2-A378-A1ED0714AED0' );

my $fingerprint_data = $ident->query();
is_deeply( 
    $fingerprint_data,
    {
        discs => {
            'D62AD3CB-2739-07E2-A378-A1ED0714AED0' => {
                confirmed => 'false',
                tag       => '1A',
            },
        },
        title => 'Buck Rogers - Season 1 - Disc 1'
    },
);

# test that we can get to a GTIN when available
$ident->ident( $long_kiss_goodnight_fingerprint );
$fingerprint_data = $ident->query();
is_deeply( 
    $fingerprint_data,
    {
        discs => {
            '3DF28C7A-3EB4-41F2-7CD8-27B691EF984D' => {
                confirmed => 'true',
                tag       => '1A'
            }
        },
        gtin  => '00794043444623',
        title => 'Long Kiss Goodnight'
    },
);

my $gtin = $fingerprint_data->{'gtin'};
my $gtin_data = $ident->query( $gtin );
is_deeply( 
    $gtin_data,
    {
        discs          => {
            '3DF28C7A-3EB4-41F2-7CD8-27B691EF984D' => {
                confirmed => 'true',
                tag       => "1A"
            }
        },
        genre          => 'Action/Adventure',
        gtin           => '00794043444623',
        productionYear => 1996,
        studio         => 'New Line',
        title          => 'Long Kiss Goodnight'
    }
    
);
