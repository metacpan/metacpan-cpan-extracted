#!perl -T
use strict;
use warnings;
use Test::More;
use File::Spec;
use Data::Dumper;
use DateTime;
use Log::Log4perl;
use Log::Log4perl::Level;

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

my $mail = 'superman@justiceleague.org';
my $contact_entry = {
       email1 => $mail,
       salutation => 'Mr',
       first_name => 'Clark',
       last_name => 'Kent123',
       title => 'SuperHero',
       department => 'Metropolis dep',
       phone_work => '+1123123124',
};

ok(!defined($s->get_unique_contact_id_from_mail($mail)), "Found no id for mail $mail");

my $contactid = $s->create_contact($contact_entry);
ok($contactid, "Contact created with contactid $contactid");
my $contact_entries_from_mail = $s->get_contacts_from_mail($mail);
is(ref($contact_entries_from_mail), 'ARRAY', "Got contact entries from mail $mail");
is($#$contact_entries_from_mail, 0, "Got at least 1 contact entry from mail $mail");
my $contact_entries_from_mail_id = $s->get_contact_ids_from_mail($mail);
my $result;
for my $i (@$contact_entries_from_mail_id) {
    $result = 1
	if ($i eq $contactid);
}
ok($result, "Found contactid $contactid");
is($s->get_unique_contact_id_from_mail($mail), $contactid, "Found unique id for contactid $contactid and mail $mail");
ok($s->get_contact($contactid), "Got entry for contactid $contactid");
is($s->get_contact_attribute($contactid, 'salutation'), 'Mr', "Salutation attribute for $contactid is Mr");

# search for website
my $query = 'contacts.last_name = "Kent123"';
my $contacts = $s->get_contacts($query);
is($#$contacts, 0, "Got 1 contact");
my $contactidssearch = $s->get_contact_ids($query);
is($$contactidssearch[0], $contactid, "Found $contactid with search $query");
my $contactidsearch = $s->get_unique_contact_id($query);
is($contactidsearch, $contactid, "Found unique $contactid with search $query");

#$s->log->level($Log::Log4perl::DEBUG);

is($s->update_contact($contactid, { title => 'Super Hero' } ), 1, "Update of contactid $contactid of the title");
$contactidsearch = $s->get_unique_contact_id("contacts.title = 'Super Hero'");
is($contactidsearch, $contactid, "Found unique $contactid with search $query");


# Create a second contact
my $contactid2 = $s->create_contact($contact_entry);
ok($contactid2, "2nd contact created with contactid $contactid2");
$contact_entries_from_mail = $s->get_contacts_from_mail($mail);
is(ref($contact_entries_from_mail), 'ARRAY', "Got contact entries from mail $mail");
is($#$contact_entries_from_mail, 1, "Got 2 contact entries from mail $mail");
$contact_entries_from_mail_id = $s->get_contact_ids_from_mail($mail);
for my $i (@$contact_entries_from_mail_id) {
    $result = 1
	if ($i eq $contactid2);
}
ok($result, "Found contactid $contactid");


ok(!defined(eval {  $s->get_unique_contact_id_from_mail($mail); 1}), "An error or more than one contactid found for mail $mail: $@");

is($s->delete_contact_by_id($contactid), 1, "Deleting contactid $contactid");
is($s->delete_contact_by_id($contactid2), 1, "Deleting contactid $contactid");

done_testing();
