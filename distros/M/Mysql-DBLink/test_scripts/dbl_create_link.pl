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
    'action' => 'create',
    'verbose' => 1,
};

print "Current test tables in database test\n";
$util->display_tables($db);
print "Linking tables test1 and test2\n";

$dblinker->bldLinker($args);
$args->{'action'} = 'get_name';
my $name = $dblinker->bldLinker($args);

print "name of link table: $name\n";

exit(0);


package my_util;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless({ }, $class);
    return $self;
}


sub display_tables{
    my ($self,$db) = @_;
    my @tables = $db->tables();
    print "\nState of database test\n";
    for my $t (@tables){
        my ($t1,$t2) = split /\./,$t;
        $t2 =~ s/`//g;
        next if ($t2 =~ /_lnk$/);
        print "found table $t\n" if ($t2 =~ /test/ig);
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

