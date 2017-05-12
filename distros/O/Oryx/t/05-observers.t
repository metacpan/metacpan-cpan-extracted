use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use AssocClass (auto_deploy => 1);
use Class1 (auto_deploy => 1);

#####################################################################
### SET UP

ok($storage->ping);
my $id;
my $owner;
my $retrieved;


Class1->add_observer(sub {
    my ($item, $action) = @_;
    ok($item eq 'Class1');
    ok($action =~ /^(before)|(after)_/); 
});

Class1->create({attrib1 => 'foo'});


#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->table_drop($dbh, 'assocclass');
$storage->util->table_drop($dbh, 'assocclass_assoc1_class1');
$storage->util->table_drop($dbh, 'class1');
# $storage->util->sequence_drop($dbh, 'assocclass');
# $storage->util->sequence_drop($dbh, 'class1');
$dbh->commit;

