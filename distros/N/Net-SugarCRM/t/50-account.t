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
my $account_entry = {
       email1 => $mail,
       name => 'DC Comics',
       description => 'DC Comics is special...',
       website => 'http://dccomics.neverland',
       annual_revenue => '12345',
       phone_office => '1123123124',
};

ok(!defined($s->get_unique_account_id_from_mail($mail)), "Found no id for mail $mail");

my $accountid = $s->create_account($account_entry);
ok($accountid, "Account created with accountid $accountid");
my $account_entries_from_mail = $s->get_accounts_from_mail($mail);
is(ref($account_entries_from_mail), 'ARRAY', "Got account entries from mail $mail");
is($#$account_entries_from_mail, 0, "Got at least 1 account entry from mail $mail");
my $account_entries_from_mail_id = $s->get_account_ids_from_mail($mail);
my $result;
for my $i (@$account_entries_from_mail_id) {
    $result = 1
	if ($i eq $accountid);
}
ok($result, "Found accountid $accountid");
is($s->get_unique_account_id_from_mail($mail), $accountid, "Found unique id for accountid $accountid and mail $mail");
ok($s->get_account($accountid), "Got entry for accountid $accountid");
is($s->get_account_attribute($accountid, 'phone_office'), '1123123124', "phone_office attribute for $accountid is +1123123124");

# search for website
my $query = 'accounts.name = "DC Comics"';
my $accounts = $s->get_accounts($query);
is($#$accounts, 0, "Got 1 account");
my $accountidssearch = $s->get_account_ids($query);
is($$accountidssearch[0], $accountid, "Found $accountid with search $query");
my $accountidsearch = $s->get_unique_account_id($query);
is($accountidsearch, $accountid, "Found unique $accountid with search $query");

#$s->log->level($Log::Log4perl::DEBUG);

is($s->update_account($accountid, { annual_revenue => '111111' } ), 1, "Update of accountid $accountid of the title");
$accountidsearch = $s->get_unique_account_id("accounts.annual_revenue = '111111'");
is($accountidsearch, $accountid, "Found unique $accountid with search $query");

# Create a second account
my $accountid2 = $s->create_account($account_entry);
ok($accountid2, "2nd account created with accountid $accountid2");
$account_entries_from_mail = $s->get_accounts_from_mail($mail);
is(ref($account_entries_from_mail), 'ARRAY', "Got account entries from mail $mail");
is($#$account_entries_from_mail, 1, "Got 2 account entries from mail $mail");
$account_entries_from_mail_id = $s->get_account_ids_from_mail($mail);
for my $i (@$account_entries_from_mail_id) {
    $result = 1
	if ($i eq $accountid2);
}
ok($result, "Found accountid $accountid");


ok(!defined(eval {  $s->get_unique_account_id_from_mail($mail); 1}), "An error or more than one accountid found for mail $mail: $@");

is($s->delete_account_by_id($accountid), 1, "Deleting accountid $accountid");
is($s->delete_account_by_id($accountid2), 1, "Deleting accountid $accountid");

done_testing();
