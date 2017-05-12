#!/usr/bin/perl

use Data::Dumper;
use DBI;
use Mysql::DBLink;


my $file = './test_data.csv';

my $util = new my_util;

my $db = $util->db_open;

my $dblinker = new Mysql::DBLink($db);

my %rec = (
    lastname => '',
    firstname => '',
    address => '',
    city => '',
    state => '',
    zip => '',
    phone => '',
);
    
my $args = {
    'table' => '',
    'action' => 'add',
    'values' => \%rec
};


open I,"< $file" or die " could not open $file - $!\n";
while (my $ln = <I>){
    chomp $ln;
    my @a = split /,/,$ln;
    $args->{'table'} = shift @a;
    print "Loading to $args->{'table'}: $ln\n";
    sleep(1);
    $rec{'lastname'} = shift @a;
    $rec{'firstname'} = shift @a;
    $rec{'address'} = shift @a;
    $rec{'city'} = shift @a;
    $rec{'state'} = shift @a;
    $rec{'zip'} = shift @a;
    $rec{'phone'} = shift @a;
    $dblinker->updateAdd($args);
}
close I;

$util->display_table($db);

exit(0);


package my_util;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless({ }, $class);
    return $self;
}


sub display_table{
    my ($self,$db) = @_;
    print "\ndisplay of data from test1\n";
    my $sql = qq! select * from test1!;
    my $db_action = $db->prepare($sql);
    $db_action->execute;
    while ( my $db_rec = $db_action->fetchrow_hashref){
        foreach my $k ( keys %{$db_rec}){
            print "$k: $db_rec->{$k} ";
        }
        print "\n";
    }
    print "\ndisplay of data from test2\n";
    $sql = qq! select * from test2!;
    $db_action = $db->prepare($sql);
    $db_action->execute;
    while ( my $db_rec = $db_action->fetchrow_hashref){
        foreach my $k ( keys %{$db_rec}){
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
