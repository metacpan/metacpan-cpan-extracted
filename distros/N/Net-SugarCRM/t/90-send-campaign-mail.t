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

my ($s, $mail, $mail2);
{
    no warnings 'once';
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass,
	dsn => $Test::testdsn, dbuser => $Test::testdbuser, dbpassword => $Test::testdbpass
);
    $mail = $Test::testemail1;
    $mail2 = $Test::testemail2;
}
is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');
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

my $leadid = $s->create_lead($lead_entry);
ok($leadid, "Lead created with leadid $leadid");
my $attrs;
{
    no warnings 'once';
    $attrs = {
	campaign_name => $Test::testcampaign,
	emailmarketing_name => $Test::testemailmarketing, 
	prospectlist_name => $Test::testprospectlist, 
	related_type => 'Leads',
	related_id => $leadid,
	email => $mail,
    };
}

ok($s->send_prospectlist_marketing_email_force($attrs), "Email sent to the outbound queue");
diag("Sleeping 65 seconds");
sleep 65 if ($sleep);
is($s->delete_lead_by_id($leadid), 1, "Deleting leadid $leadid");

done_testing();
