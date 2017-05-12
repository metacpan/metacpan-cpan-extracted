use 5.012;
use warnings;
use Test::More;
use Panda::Config::Perl;
use FindBin qw($Bin);

plan skip_all => 'BSD::Resource required to test for leaks' unless eval { require BSD::Resource; 1};
plan skip_all => 'set WITH_LEAKS=1 to enable leaks test' unless $ENV{WITH_LEAKS};

my $measure = 200;
my $leak = 0;
my $i = 0;

while (++$i < 4000) {
    my $cfg = Panda::Config::Perl->process($Bin.'/configs/includes.conf',{hello => 'world'});
    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 400;	
}

$leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 100;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);
done_testing();
