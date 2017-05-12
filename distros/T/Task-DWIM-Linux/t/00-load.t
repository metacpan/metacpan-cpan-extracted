#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Task::DWIM::Linux;
use Perl::Version;

my %modules = Task::DWIM::Linux::get_modules();
plan tests => 1 + 3 * scalar keys %modules;

ok(1, 'loaded Task::DWIM::Linux');

my %SKIP = (
    'Readonly::XS' => 'Readonly::XS is not stand alone module.',
    # use did not work well

    'Devel::NYTProf' => 'No need to profile ourselves',

    'strictures'   => 'Invalid version format (version required) at strictures.pm line 21.'
    # strictures::VERSION(** Incomplete caller override detected in &Hook::LexWrap::__ANON__[Hook/LexWrap.pm:21]; @DB::args were not set **) called at t/00-load.t line 30
    # The use statement was OK, but checking the VERSION blew it up

);

foreach my $name (keys %modules) {

    # Check if the module can be loaded
    SKIP: {
        skip $SKIP{$name}, 1 if $SKIP{$name};
        no warnings 'redefine';
        eval "use $name ()";
        is $@, '', $name;
    }

    # Check if the version number at least the one we asked for
    SKIP: {
        skip $SKIP{$name}, 1 if $SKIP{$name};
        if ($name->VERSION =~ /v/ or split(/\./, $name->VERSION) > 2) {
            cmp_ok( Perl::Version->new($name->VERSION), '>=', Perl::Version->new($modules{$name}), "Version of $name");
        } else {
            cmp_ok( $name->VERSION, '>=', $modules{$name}, "Version of $name");
        }
    }

    # Check if the version number is exactly the one we asked for
    SKIP: {
        skip $SKIP{$name}, 1 if $SKIP{$name};
        skip "Need ENV variable VERSION to check exact version ", 1 if not $ENV{VERSION};
        is $name->VERSION, $modules{$name}, "Version of $name";
    }
}
