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

my $account_entry = {
       name => 'DC Comics',
       description => 'DC Comics is special...',
       website => 'http://dccomics.neverland',
       annual_revenue => '12345',
       phone_office => '1123123124',
};

my $accountid = $s->create_account($account_entry);
ok($accountid, "Account created with accountid $accountid");


my $opportunity_entry = {
       name => 'My incredible opportunity',
       description => 'This is the former DC Comics is special...',
       amount => '12345',
       sales_stage => 'Prospecting',
       date_closed => '2011-12-31',
       account_id => $accountid,
};

my $query = 'opportunities.name = "My incredible opportunity"';
ok(!defined($s->get_unique_opportunity_id($query)), "Found no id for query $query");

my $opportunityid = $s->create_opportunity($opportunity_entry);
ok($opportunityid, "Opportunity created with opportunityid $opportunityid");

ok($s->get_opportunity($opportunityid), "Got entry for opportunityid $opportunityid");
is($s->get_opportunity_attribute($opportunityid, 'amount'), '12345', "amount attribute for $opportunityid is 12345");

# search for amount
my $opportunities = $s->get_opportunities($query);
is($#$opportunities, 0, "Got 1 opportunity");
my $opportunityidssearch = $s->get_opportunity_ids($query);
is($$opportunityidssearch[0], $opportunityid, "Found $opportunityid with search $query");
my $opportunityidsearch = $s->get_unique_opportunity_id($query);
is($opportunityidsearch, $opportunityid, "Found unique $opportunityid with search $query");

#$s->log->level($Log::Log4perl::DEBUG);

is($s->update_opportunity($opportunityid, { amount => '67890' } ), 1, "Update of opportunityid $opportunityid of the amount");
$opportunityidsearch = $s->get_unique_opportunity_id("opportunities.amount = '67890'");
is($opportunityidsearch, $opportunityid, "Found unique $opportunityid with search $query");

# Create a second opportunity
my $opportunityid2 = $s->create_opportunity($opportunity_entry);
ok($opportunityid2, "2nd opportunity created with opportunityid $opportunityid2");


ok(!defined(eval { $s->get_unique_opportunity_id($query); 1 }), "An error or more than one opportunityid found for query $query: $@");

my $ids = $s->get_module_link_ids("Accounts", "opportunities", $accountid);
my %linked_opportunities = map { $_ => 1 } (@$ids);

ok($linked_opportunities{$opportunityid}, "Opportunity id $opportunityid is linked to account $accountid");
ok($linked_opportunities{$opportunityid2}, "Opportunity id $opportunityid2 is linked to account $accountid");

is($s->delete_opportunity_by_id($opportunityid), 1, "Deleting opportunityid $opportunityid");
is($s->delete_opportunity_by_id($opportunityid2), 1, "Deleting opportunityid $opportunityid");

is($s->delete_account_by_id($accountid), 1, "Deleting accountid $accountid");
done_testing();
