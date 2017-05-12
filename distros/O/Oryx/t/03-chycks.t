use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use Orx::Chyck (auto_deploy => 1);
use Orx::Skirt (auto_deploy => 1);

#####################################################################
### SET UP

ok($storage->ping);
my $id;
my $chyck;
my $skirt;

$chyck = Orx::Chyck->create({
    namefirst => 'Jane'
});
$skirt = Orx::Skirt->create({
    short => '0'
});
$chyck->skirt($skirt);
$chyck->update;
$chyck->commit;

my @honeys = Orx::Chyck->search({ 
    EXISTS => \"( SELECT id FROM skirt WHERE short > 0 AND skirt.id = chyck.skirt )"
});

warn "found ".join(',',map { $_->id } @honeys)." honeys";
