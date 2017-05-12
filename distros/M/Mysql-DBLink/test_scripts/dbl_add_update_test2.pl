#!/usr/bin/perl

use Data::Dumper;
use DBI;
use Mysql::DBLink;


my $util = new my_util;

my $db = $util->db_open;

my $table = 'test2';

my $dblinker = new Mysql::DBLink($db);

my %rec = (
    lastname => 'smith',
    firstname => 'jack',
    address => '12549 happy place',
    city => 'Surprise',
    state => 'AZ',
    zip => '99999',
    phone => '333-333-3333'
);
 
    
my $args = {
    'table' => $table,
    'action' => 'add',
    'values' => \%rec
};

my $new_id = $dblinker->updateAdd($args);

print "Adding the following record to $table\n";
$util->display_rec($db,$new_id,$table);

%rec = (
    lastname => 'smith',
    firstname => 'jack',
    address => '12549 happy place',
    city => 'Surprise',
    state => 'AZ',
    zip => '99999',
    phone => '444-444-444'
);


my $update_args = {
    'table' => $table,
    'action' => 'update',
    'values' => \%rec,
    'id_field' => 'id',
    'update_id' => $new_id
};

$dblinker->updateAdd($update_args);

print "Updating the phone number in following record in $table\n";

$util->display_rec($db,$new_id,$table);

exit(0);




package my_util;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless({ }, $class);
    return $self;
}


sub display_rec{
    my ($self,$db, $new_id,$table) = @_;
    my $sql = qq! select * from $table where id = $new_id!;
    my $db_action = $db->prepare($sql);
    $db_action->execute;
    my $db_rec = $db_action->fetchrow_hashref;
    print Dumper($db_rec);
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

