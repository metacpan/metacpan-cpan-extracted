#!perl -T
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

my ($volume,$directories,$file) = File::Spec->splitpath($0);
push @INC, $directories;
my $defaults = File::Spec->catfile('lib', 'defaults.pl');
require $defaults;
use_ok('Net::SugarCRM');

my $s;
{
    no warnings 'once';
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
}
is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');

my $mail = 'batman@justiceleague.org';
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

ok(!defined($s->get_unique_lead_id_from_mail($mail)), "Found no id for mail $mail");

my $leadid = $s->create_lead($lead_entry);
ok($leadid, "Lead created with leadid $leadid");
my $lead_entries_from_mail = $s->get_leads_from_mail($mail);
is(ref($lead_entries_from_mail), 'ARRAY', "Got lead entries from mail $mail");
is($#$lead_entries_from_mail, 0, "Got at least 1 lead entry from mail $mail");
my $lead_entries_from_mail_id = $s->get_lead_ids_from_mail($mail);
my $result;
for my $i (@$lead_entries_from_mail_id) {
    $result = 1
	if ($i eq $leadid);
}
ok($result, "Found leadid $leadid");
is($s->get_unique_lead_id_from_mail($mail), $leadid, "Found unique id for leadid $leadid and mail $mail");

ok($s->get_lead($leadid), "Got entry for leadid $leadid");
is($s->get_lead_attribute($leadid, 'salutation'), 'Mr', "Salutation attribute for $leadid is Mr");

# search for website
my $query = 'website = "http://justiceleagueofamerica.org"';
my $leads = $s->get_leads($query);
is($#$leads, 0, "Got 1 lead");
my $leadidssearch = $s->get_lead_ids($query);
is($$leadidssearch[0], $leadid, "Found $leadid with search $query");
my $leadidsearch = $s->get_unique_lead_id($query);
is($leadidsearch, $leadid, "Found unique $leadid with search $query");

is($s->update_lead($leadid, { website => 'http://justiceleague.org' } ), 1, "Update of leadid $leadid of the website");
$leadidsearch = $s->get_unique_lead_id("website = 'http://justiceleague.org'");
is($leadidsearch, $leadid, "Found unique $leadid with search $query");


# Create a second lead
my $leadid2 = $s->create_lead($lead_entry);
ok($leadid2, "2nd lead created with leadid $leadid2");
$lead_entries_from_mail = $s->get_leads_from_mail($mail);
is(ref($lead_entries_from_mail), 'ARRAY', "Got lead entries from mail $mail");
is($#$lead_entries_from_mail, 1, "Got 2 lead entries from mail $mail");
$lead_entries_from_mail_id = $s->get_lead_ids_from_mail($mail);
for my $i (@$lead_entries_from_mail_id) {
    $result = 1
	if ($i eq $leadid2);
}
ok($result, "Found leadid $leadid");


ok(!defined(eval {  $s->get_unique_lead_id_from_mail($mail); 1}), "An error or more than one leadid found for mail $mail: $@");

is($s->delete_lead_by_id($leadid), 1, "Deleting leadid $leadid");
is($s->delete_lead_by_id($leadid2), 1, "Deleting leadid $leadid");

done_testing();
