#!perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use Data::Dumper;
use DateTime;
use Log::Log4perl;

if ( not $ENV{TEST_AUTHOR_SUGAR}) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR_SUGAR} to a true value to run. Define it as DEBUG to see the debug messages';
    plan( skip_all => $msg );
}


if(!(Log::Log4perl->initialized()) && $ENV{TEST_AUTHOR_SUGAR} eq 'DEBUG') {
    Log::Log4perl->easy_init($Log::Log4perl::DEBUG);
}

my $sleep = $ENV{NOSLEEP} ? 0 : 1;


my ($volume,$directories,$file) = File::Spec->splitpath($0);
push @INC, $directories;
my $defaults = File::Spec->catfile('lib', 'defaults.pl');
require $defaults;
if ( not defined($Test::testcampaign) || not defined($Test::testemail1) || not defined($Test::testemail2) || not defined($Test::testdsn) || not defined($Test::testdbuser) || not defined($Test::testdbpass)) {
    my $msg = 'Define testcampaign testprospectlist testemailmarketing  testemail1 and testemail2 in t/lib/defaults.pl';
    plan( skip_all => $msg );
}

use_ok('Net::SugarCRM');

my $s;
{
    no warnings 'once';
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
}
is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');

my $mail = $Test::testemail1;
my $lead_entry = {
       email1 => $mail,
       salutation => 'Mr',
       first_name => 'Bruce',
       last_name => 'Wayne',
       title => 'Detective',
       account_name => 'Justice League of America',
       department => 'Gotham city dep',
       phone_work => '+1123123123',
       website => 'http://justiceleagueofamerica.org',
};


my $mail2 = $Test::testemail2;
my $contact_entry = {
       email1 => $mail2,
       salutation => 'Mr',
       first_name => 'Clark',
       last_name => 'Kent123',
       title => 'SuperHero',
       department => 'Metropolis dep',
       phone_work => '+1123123124',
};


my $campaignid = $s->get_campaignid_by_name($Test::testcampaign);
ok($campaignid, "The campaing id for $Test::testcampaign was $campaignid");
my $campaign = $s->get_campaign($campaignid);
is(ref $campaign, 'Net::SugarCRM::Entry',"Got campaing data back");
is($s->get_campaign_attribute($campaignid, 'name'), $Test::testcampaign, "Check for the test campaign name");

my $prospectlistid = $s->get_prospectlistid_by_name($Test::testprospectlist);
ok($prospectlistid, "The prospectlistid was $prospectlistid for $Test::testprospectlist");
is(ref $s->get_prospectlist($prospectlistid), 'Net::SugarCRM::Entry',"Got prospect_list data back");
is($s->get_prospectlist_attribute($prospectlistid, 'name'), $Test::testprospectlist, "Check for the test prospect_list name");

my $emailmarketingid = $s->get_emailmarketingid_by_name($Test::testemailmarketing);
ok($emailmarketingid, "The emailmarketingid was $emailmarketingid for $Test::testemailmarketing");
is(ref $s->get_emailmarketing($emailmarketingid), 'Net::SugarCRM::Entry',"Got prospect_list data back");
is($s->get_emailmarketing_attribute($emailmarketingid, 'name'), $Test::testemailmarketing, "Check for the test email_marketing name");


# Check if database variables are defined and skip
# Set database variables
# Send email
# send second email

$s->dsn($Test::testdsn);
$s->dbuser($Test::testdbuser);
$s->dbpassword($Test::testdbpass);
my $leadid2 = $s->get_unique_lead_id_from_mail($mail);
if (!$leadid2) {
#    diag("Force setting leadid2");
    $leadid2 = '-1';
}
my $attrs = {
    campaign_id => $campaignid,
    target_id => $leadid2,
    target_type => 'Leads',
    list_id => $prospectlistid,
    marketing_id => $emailmarketingid,
    email => $mail,
};
my $ids = $s->get_ids_from_campaignlog($attrs);
ok($ids, "Got ids from campaign log @$ids");
$s->delete_ids_from_campaignlog($ids);

my $contactid2 = $s->get_unique_contact_id_from_mail($mail);
if (!$contactid2) {
#    diag("Force setting contactid2");
    $contactid2 = '1';
}
my $attrs2 = {
    campaign_id => $campaignid,
    target_id => $contactid2,
    target_type => 'Contacts',
    list_id => $prospectlistid,
    marketing_id => $emailmarketingid,
    email => $mail,
};
#    $s->log->level($Log::Log4perl::DEBUG);
my $ids2 = $s->get_ids_from_campaignlog($attrs2);
ok($ids2, "Got ids from campaign log @$ids2");
$s->delete_ids_from_campaignlog($ids2);

my $leadid = $s->create_lead($lead_entry);
ok($leadid, "Lead created with leadid $leadid");
sleep 1;
ok($s->add_lead_id_to_prospect_list($leadid, $prospectlistid), "Added leadid to prospectlist");
sleep 1;


my $emailman_attrs = {
    campaign_id => $campaignid,
    marketing_id => $emailmarketingid,
    list_id => $prospectlistid,
    related_id => $leadid, 
    related_type => 'Leads',
    user_id => 'f2347eb8-b5ed-b324-a316-4e26c9558337',
    modified_user_id => 'f2347eb8-b5ed-b324-a316-4e26c9558337',
};
ok($s->add_to_emailman($emailman_attrs), "Added mails to emailman");

diag("Sleeping for 65 seconds");
$s->log->level($Log::Log4perl::ERROR);
sleep 65 if ($sleep);


# Delete contactid and leadid from the list
#$s->log->level($Log::Log4perl::DEBUG);
ok($s->delete_lead_id_from_prospect_list($leadid, $prospectlistid), "Deleted lead_id $leadid from prospect_list $prospectlistid");
is($s->delete_lead_by_id($leadid), 1, "Deleting leadid $leadid");


done_testing();
