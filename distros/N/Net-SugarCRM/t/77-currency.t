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

my $currency_entry = {
       name => 'MyEuro',
       symbol => 'ME',
       iso4217 => 'MEUR',
       conversion_rate => '1.23',
};

my $currencyid = $s->create_currency($currency_entry);
ok($currencyid, "currencyid created with id $currencyid");

# search for website
my $query = 'currencies.name = "MyEuro"';
my $currencies = $s->get_currencies($query);
is($#$currencies, 0, "Got 1 currency");
my $currencyidssearch = $s->get_currency_ids($query);
is($$currencyidssearch[0], $currencyid, "Found $currencyid with search $query");
my $currencyidsearch = $s->get_unique_currency_id($query);
is($currencyidsearch, $currencyid, "Found unique $currencyid with search $query");

#$s->log->level($Log::Log4perl::DEBUG);

is($s->update_currency($currencyid, { name => 'MyEuro2' } ), 1, "Update of currencyid $currencyid of the name");
$currencyidsearch = $s->get_unique_currency_id("currencies.name = 'MyEuro2'");
is($currencyidsearch, $currencyid, "Found unique $currencyid with search $query");



is($s->delete_currency_by_id($currencyid), 1, "Deleting contactid $currencyid");

done_testing();
