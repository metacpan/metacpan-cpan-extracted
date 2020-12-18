#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

if (! $ENV{RELEASE_TESTING}) {
    plan skip_all => "Developer only tests";
}

use Module::Installed qw(module_installed);

my $m = 'Mock::Sub';
# require/import with cb
{
    is eval {my $mock = Mock::Sub->new; 1; }, undef, "Callback module not loaded ok";
    module_installed($m, \&cb);
    is eval {my $mock = Mock::Sub->new; 1; }, 1, "Callback works ok";
}

if (module_installed('Carp')) {
    is eval { confess("test"); 1 }, undef, "require/import fails if module isn't loaded ok";
    like $@, qr/confess/, "...and error is that module isn't loaded ok";

    require Carp;
    Carp->import('confess');
    is eval { confess("test2"); 1 }, undef, "require/import ok";
    like $@, qr/test2/, "...and error is from the required module ok";

}

sub cb {
    my ($module, $module_file, $installed) = @_;

    if ($installed) {
        require $module_file;
        $module->import;
    }
}

done_testing;

