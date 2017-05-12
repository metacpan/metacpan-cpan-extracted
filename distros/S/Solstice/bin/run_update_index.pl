#!/usr/bin/perl

use strict;
use warnings;
use 5.006_000;

use Solstice::ImplementationManager;
use Solstice::Database;
use Solstice::Configure;

my $db = Solstice::Database->new();
my $db_name = Solstice::Configure->new()->getDBName();

$db->readQuery("SELECT * from $db_name.Status WHERE flag = 'solstice_index_updating'");
exit if $db->rowCount();
$db->writeQuery("INSERT INTO $db_name.Status (flag) VALUES ('solstice_index_updating')");


eval {

my $manager = Solstice::ImplementationManager->new();
$manager->createList({
    method => 'updateIndex',
});

};

warn "Update Index run failed: $@\n" if $@;

$db->writeQuery("DELETE FROM $db_name.Status WHERE flag = 'solstice_index_updating'");

exit;
