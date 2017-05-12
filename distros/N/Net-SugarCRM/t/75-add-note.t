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

my $note_attrs = {
    name => 'test note',
    description => 'Also a test note descr',
    parent_type => 'Leads',
    parent_id => $leadid,
};

my $noteid = $s->create_note($note_attrs);
ok($s->get_note($noteid), "Got note");
is($s->get_note_attribute($noteid, 'name'), "test note", "Got note");
is($s->delete_note_by_id($noteid), 1, "Deleting noteid $noteid");
is($s->delete_lead_by_id($leadid), 1, "Deleting leadid $leadid");

done_testing();
