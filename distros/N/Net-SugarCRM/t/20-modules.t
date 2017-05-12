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
my $modules=$s->get_available_modules;
ok($modules, "Modules are returned");
my %module_names = map { $_->{module_key} => $_->{module_label} } @{$modules->{modules}};
#diag(Dumper(\%module_names));
for my $i ('Accounts', 'Leads', 'Contacts', 'Opportunities') {
    ok(exists($module_names{$i}), "Check for module $i");
    my $fields = $s->get_module_fields($i);
    ok($s->get_module_fields($i), "Check for module fields of module $i are returned");
    for my $f ('id', 'description', 'date_entered', 'created_by_name') {
	ok(exists($fields->{module_fields}->{$f}), "Checking $f field for module $i");
    }
}

done_testing();
