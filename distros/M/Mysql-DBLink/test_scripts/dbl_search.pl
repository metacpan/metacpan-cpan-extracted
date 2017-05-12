#!/usr/bin/perl

use Data::Dumper;
use DBI;
use Mysql::DBLink;

my $util = new my_util;

my $db = $util->db_open;

my $table1 = 'test1';
my $table2 = 'test2';

my $dblinker = new Mysql::DBLink($db);

my $args = {
    'from_table' => $table1,
    'to_table' => $table2,
    'action' => 'get_name',
    'verbose' => 1,
};

my $lnk_name = $dblinker->bldLinker($args);

my $lnk_args = {
    'link_table' => $lnk_name,
    'action' => 'get_lnk_records',
    'from_id' => 1
};

my $return_recs = $dblinker->handleLinker($lnk_args);

print "The following dump represents the records in test2 that were linked to the record in test1 with id =  1\n";
print Dumper($return_recs);


$lnk_args->{'sfield'} = 'firstname';
$lnk_args->{'svalue'} = 'jeff';

$return_recs = $dblinker->handleLinker($lnk_args);

print "The following dump represents the records in test2 that are linked to test1 with a firstname of jeff \n";
print Dumper($return_recs);

$lnk_args->{'sfield'} = '';
$lnk_args->{'svalue'} = '';
$lnk_args->{'from_id'} = 1;
$lnk_args->{'to_id'} = 2;
$lnk_args->{'action'} = 'islinked';

$return_recs = $dblinker->handleLinker($lnk_args);


print "The following dump represents the record 1 in test1 is linked to record 2 in test2 \n";
if ($return_recs){
    print "record 1 in test1 is linked to record 2 in test2\n";
} else {
    print "record 1 in test1 is not linked to record 2 in test2\n";
}


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

