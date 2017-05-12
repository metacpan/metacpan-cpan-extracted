#!/usr/bin/perl

use Data::Dumper;
use DBI;
use Mysql::DBLink;

my $util = new my_util;

my $db = $util->db_open;

my $table1 = 'test1';
my $table2 = 'test2';

my $dblinker = new Mysql::DBLink($db);

my @t1 = ();
my @t2 = ();

my $sql = qq! select id from $table1 !;
my $db_action = $db->prepare($sql);
$db_action->execute;
while (my $id = $db_action->fetchrow_array){
    push @t1, $id;
}
$db_action->finish;

$sql = qq! select id from $table2 !;
$db_action = $db->prepare($sql);
$db_action->execute;
while (my $id = $db_action->fetchrow_array){
    push @t2, $id;
}
$db_action->finish;


my $args = {
    'from_table' => $table1,
    'to_table' => $table2,
    'action' => 'get_name',
    'verbose' => 1,
};

my $lnk_name = $dblinker->bldLinker($args);

for my $i (0..$#t1){
    for my $i1 (0..$#t2){
        my $lnk_args = {
            'link_table' => $lnk_name,
            'from_id' => $t1[$i],
            'to_id' => $t2[$i1],
            'action' => 'add'
        };
        $dblinker->handleLinker($lnk_args);
    }
}

$util->display_table($db,$lnk_name);

exit(0);


package my_util;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless({ }, $class);
    return $self;
}

sub display_table{
    my ($self,$db,$table) = @_;
    print "\ndisplay of data from $table\n";
    my $sql = qq! select * from $table!;
    my $db_action = $db->prepare($sql);
    $db_action->execute;
    while ( my $db_rec = $db_action->fetchrow_hashref){
        foreach my $k ( keys %{$db_rec}){
            next if ($k eq 'id');
            print "$k: $db_rec->{$k} ";
        }
        print "\n";
    }
}


sub db_open{
    my $db_host = 'localhost';
    my $username = '';
    my $password = '';
    my $db = 'test';
	my $db_port  =  '3306';
	my $data_source = "DBI:mysql:$db:$db_host:$db_port";
    my $DB = DBI->connect("$data_source", "$username", "$password")
   		or die "Error in open of db  - $DBI::errstr";
    return ($DB);
}

1;

