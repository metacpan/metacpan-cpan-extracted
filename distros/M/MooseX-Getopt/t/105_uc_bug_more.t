use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Moose ();
use Moose::Meta::Class;
use Module::Runtime 'use_module';

foreach my $role (qw/
    MooseX::Getopt
    MooseX::Getopt::GLD
    MooseX::Getopt::Basic
/) {
    use_module($role);

    my $meta = Moose::Meta::Class->create_anon_class(
        superclasses => ['Moose::Object'],
    );
    $meta->add_attribute('debug', traits => ['Getopt'], isa => 'Bool',
        cmd_aliases => ['d'], is => 'ro');
    $role->meta->apply($meta);

    ok($meta->name->new_with_options({ argv => ['-d'] })->debug,
        "debug was set for argv -d on $role");
    {
        local @ARGV = ('-d');
        ok($meta->name->new_with_options()->debug,
            "debug was set for ARGV on $role");
    }

    ok($meta->name->new_with_options({ argv => ['--debug'] })->debug,
        "debug was set for argv --debug on $role");

    ok($meta->name->new_with_options({ argv => ['--debug'] })->debug,
        "debug was set for argv --debug on $role");
}

done_testing;
