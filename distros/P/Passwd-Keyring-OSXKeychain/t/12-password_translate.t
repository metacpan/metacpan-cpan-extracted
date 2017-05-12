#!perl
use strict;
use utf8;
use Test::Most;
use List::Util 1.29 qw/pairs/;
use Encode qw/encode_utf8/;

# use Test::More skip_all => "Not yet ready (and not yet used, #1 in progress)";

# binmode(STDOUT, 'utf8');

BEGIN { use_ok('Passwd::Keyring::OSXKeychain::PasswordTranslate', qw(read_security_encoded_passwd)); }

my @PLAINTEXT_SAMPLES = (
    'alabela', '1997', 'Koszmarny Karolek', 'fefe', 'alternatywa', '',
   );

foreach my $plain_password (@PLAINTEXT_SAMPLES) {
    is( read_security_encoded_passwd($plain_password), $plain_password, "plain: $plain_password");
}

my @ESCAPED_SAMPLES = (
    "€uro" => 'ffffffe2ffffff82ffffffac75726f0a3231333469396b6f70',
    "∑sum" => 'ffffffe2ffffff88ffffff9173756d0a3231333469396b6f70',
    # This sample seems broken
    # "x123x" => '6b6f706f707070006b6f70006f7000700070',
    "ü∑bér" => "c3bce2ffffff88ffffff9162ffffffc3ffffffa9720a3231333469396b6f70006f7000700070",
    "¥€N" => "ffffffc2ffffffa5ffffffe2ffffff82ffffffac4e",
    "abccccccccdddddeeefffffffggggghhhhhïìjjklllmñ" => "6162636363636363636364646464646565656666666666666667676767676868686868ffffffc3ffffffafffffffc3ffffffac6a6a6b6c6c6c6dffffffc3ffffffb1",
);

foreach my $pair (pairs @ESCAPED_SAMPLES) {
    my ($utf, $escaped) = @$pair;
    # print STDERR read_security_encoded_passwd($escaped), "\n";
    is( read_security_encoded_passwd($escaped), $utf, "escaped form: $escaped");
}

# Sample from #1 (security_format_test.sh)
my @VARIOUS_SAMPLES = (
    #11
    "simple" => "simple",
    #12
    "other" => "other",
    #13
    "1919" => "1919",
    #14
    "Kosmaty Krokodyl" => "Kosmaty Krokodyl",
    #15
    "" => "",
    #16
    "ffffff" => "ffffff",
    #17
    "ffffff00" => "ffffff00",
    #18
    "abffffff10" => "abffffff10",

    # 51
    "€uro" => "ffffffe2ffffff82ffffffac75726f",
    # 52
    "∑sum" => "ffffffe2ffffff88ffffff9173756d",
    # 53
    "x123x" => "x123x",
    # 54
    "ü∑bér" => "ffffffc3ffffffbcffffffe2ffffff88ffffff9162ffffffc3ffffffa972",
    # 55
    "¥€N" => "ffffffc2ffffffa5ffffffe2ffffff82ffffffac4e",
    # 56
    "abccccccccdddddeeefffffffggggghhhhhïìjjklllmñ" => "6162636363636363636364646464646565656666666666666667676767676868686868ffffffc3ffffffafffffffc3ffffffac6a6a6b6c6c6c6dffffffc3ffffffb1",
    # 57
    "Zażółć gęślą jaźń" => "5a61ffffffc5ffffffbcffffffc3ffffffb3ffffffc5ffffff82ffffffc4ffffff872067ffffffc4ffffff99ffffffc5ffffff9b6cffffffc4ffffff85206a61ffffffc5ffffffbaffffffc5ffffff84",
    # 58
    "Pójdź kińże w głąb flaszy" => "50ffffffc3ffffffb36a64ffffffc5ffffffba206b69ffffffc5ffffff84ffffffc5ffffffbc6520772067ffffffc5ffffff82ffffffc4ffffff856220666c61737a79",
    # 59
    "Здравствуй" => "ffffffd0ffffff97ffffffd0ffffffb4ffffffd1ffffff80ffffffd0ffffffb0ffffffd0ffffffb2ffffffd1ffffff81ffffffd1ffffff82ffffffd0ffffffb2ffffffd1ffffff83ffffffd0ffffffb9",

    # Additional passwords by Maroš Kollár (comment from #1, 2015-02-15)
    'othér' => '6f7468ffffffc3ffffffa972',
    'other' => '6f7468657200',
    'othér' => '6f7468ffffffc3ffffffa97200',
    'othersomethingreallylongbutwithoutanyspecialcharacters' => '6f74686572736f6d657468696e677265616c6c796c6f6e67627574776974686f7574616e797370656369616c636861726163746572730000',
    'other' => '6f746865720000',
    'öthé®' => 'ffffffc3ffffffb67468ffffffc3ffffffa9ffffffc2ffffffae0000',
    'other' => '6f7468657200ffffffc2ffffffae0000',

   );

foreach my $pair (pairs @ESCAPED_SAMPLES) {
    my ($utf, $escaped) = @$pair;
    # print STDERR read_security_encoded_passwd($escaped), "\n";
    is( read_security_encoded_passwd($escaped), $utf, "escaped form: $escaped");
}

done_testing;
