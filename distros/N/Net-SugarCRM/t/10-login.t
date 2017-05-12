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
{
    my $s;
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
    is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');
    my $sessionid = $s->login;
    ok($sessionid, 'We got a sessionid back after login');
    is($sessionid, $s->_sessionid, "Check that the sessionid is stored $sessionid");
    is($sessionid, $s->sessionid, "Check that the sessionid is stored $sessionid");
    $s->logout;
    ok(!defined($s->_sessionid), "Check that we have effectively logged out");
}

# Set explicityly PLAIN parameter
{
    my $s;
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass, encryption => 'PLAIN');
    is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');
    my $sessionid = $s->login;
    ok($sessionid, 'We got a sessionid back after login');
    is($sessionid, $s->_sessionid, "Check that the sessionid is stored $sessionid");
    is($sessionid, $s->sessionid, "Check that the sessionid is stored $sessionid");
    $s->logout;
    ok(!defined($s->_sessionid), "Check that we have effectively logged out");
}

# Now try to implicitly log in and out
{
    my $s;
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
    is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');
    my $sessionid = $s->sessionid;
    is($sessionid, $s->_sessionid, "Check that the sessionid is stored $sessionid");
}
# logout a non logged in
{
    my $s;
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> $Test::pass);
    is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');
    $s->logout;
}
# Error in login
{
    my $s;
    $s = Net::SugarCRM->new(url=>$Test::url, restuser=>$Test::login, restpasswd=> "wrong pass");
    is(ref $s, 'Net::SugarCRM', 'Check that we got a Net::SugarCRM package');
    ok(!defined(eval {$s->sessionid; 1 }), "Error in login");
}

done_testing(16);
