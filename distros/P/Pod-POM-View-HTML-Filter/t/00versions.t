use Test::More tests => 1;
use strict;
use warnings;

diag "Printing versions of relevant modules";

# compute the list of prerequisites
use Pod::POM::View::HTML::Filter;
my %modules;
$modules{$_}++
    for map { @{ $_->{requires} || [] } }
    values %Pod::POM::View::HTML::Filter::builtin;

for my $module ( keys %modules ) {
    eval "require $module;";
    diag $@ ? "$module not installed"
            : "$module " . UNIVERSAL::VERSION($module);
}

ok(1, "Dummy test" );
