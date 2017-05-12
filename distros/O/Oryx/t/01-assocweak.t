# vim:set ft=perl:

use lib 't', 'lib';

use Test::More qw(no_plan);
use YAML;
use Oryx;
use Oryx::Class (auto_deploy => 1);

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use AssocStrong;
use AssocWeak;

#####################################################################
### SET UP

ok($storage->ping);
my $id;
my $owner;

my $weak = AssocWeak->create({
    attrib1 => 'Has weakref to AssocStrong',
});

my $strong = AssocStrong->create({
    attrib1 => 'Has hard ref to AssocWeak',
});

push @{$strong->assoc_strong}, $weak;
$strong->update;

is($weak->assoc_weak, $strong);


