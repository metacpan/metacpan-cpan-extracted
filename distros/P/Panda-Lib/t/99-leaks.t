use 5.012;
use warnings;
use Panda::Lib;
use Test::More;
use Data::Dumper qw/Dumper/;

plan skip_all => 'set WITH_LEAKS=1 to enable leaks test' unless $ENV{WITH_LEAKS};
plan skip_all => 'BSD::Resource required to test for leaks' unless eval { require BSD::Resource; 1};

my $measure = 200;
my $leak = 0;

my @a = 1..1000;
undef @a;

my $str = "0123456789" x 100;
my $str2 = "sadfjksfhkdshfjkdsf";

$Data::Dumper::Terse = 1;
my $h1 = Dumper({a => 1, b => 2, c => [1,2,3], d => {a => 1, b => 2, c => {a => 1, b => 2}, d => [12,13,14]}});
my $h2 = {a => 1, b => 2, c => [1,2,3], d => {a => 1, b => 2, c => {a => 1, b => 2}, d => undef}};

my $s1 = {"max_qid" => 11,"clover" => {"fillup_multiplier" => "1.3","finish_date" => 12345676}};
my $s2 = {"clover" => {"finish_date" => 12345676,"fillup_multiplier" => "1.3"},"max_qid" => 11};
my $s3 = {"clover" => {"finish_date" => 12345676,"fillup_multiplier" => 1.3},"max_qid" => 11};

for (my $i = 0; $i < 100000; $i++) {
    my $ret = Panda::Lib::string_hash($str);
    $ret = Panda::Lib::string_hash32($str);
    $ret = Panda::Lib::crypt_xor($str, $str2);
    $ret = Panda::Lib::timeout(sub { my $a = 10 }, 1);

    my $h1c = eval($h1); 
    Panda::Lib::hash_merge($h1c, $h2, MERGE_DELETE_UNDEF);
    $h1c = eval($h1);
    Panda::Lib::hash_merge($h1c, $h2, MERGE_COPY);
    Panda::Lib::hash_merge(undef, $h2);
    Panda::Lib::hash_merge($h1c, undef);
    Panda::Lib::hash_merge($h1c, undef, MERGE_COPY);
    Panda::Lib::hash_merge(undef, undef);
    
    Panda::Lib::hash_cmp($s1, $s2);
    Panda::Lib::hash_cmp($s1, $s3);

    my @to_test = (1, 0.3, "abvcdsfds", \1, \"dsfddsf", [1,2,3], {a => 1, b => 2}, \[1,2,3], \{a => 1}, \\\10);
    my $cycled = {a => 1, b => 2};
    $cycled->{c} = $cycled;
    Panda::Lib::clone($_) for @to_test;
    Panda::Lib::fclone($_) for @to_test;
    my $copy = Panda::Lib::fclone($cycled);
    delete $cycled->{c};
    delete $copy->{c};
    
    if ($i > 10000) {
        state $once1 = eval { Panda::Lib::test_mempool_tls(); }; # can absent if without TEST_FULL
    }

    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 20000;
}

$leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 100;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);

done_testing();
