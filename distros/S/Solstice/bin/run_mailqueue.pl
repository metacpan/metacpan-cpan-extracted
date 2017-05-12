#!/usr/bin/perl

use strict;
use warnings;
use 5.006_000;

use Solstice::Mailer;
use Solstice::ImplementationManager;
use Solstice::Configure;

my $db = Solstice::Database->new();
my $db_name = Solstice::Configure->new()->getDBName();

$db->readQuery("SELECT * from $db_name.Status WHERE flag = 'mail_queue_running'");
exit if $db->rowCount();
$db->writeQuery("INSERT INTO $db_name.Status (flag) VALUES ('mail_queue_running')");

eval {

my $manager = Solstice::ImplementationManager->new();
$manager->createList({
        method  => 'queueMail',
    });

my $mailer = Solstice::Mailer->new();
$mailer->runQueue();

};

warn "MailQueue run failed: $@\n" if $@;

$db->writeQuery("DELETE FROM $db_name.Status WHERE flag = 'mail_queue_running'");

exit;
