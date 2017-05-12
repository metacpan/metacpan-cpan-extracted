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
    $meta->add_attribute('BigD', traits => ['Getopt'], isa => 'Bool',
        cmd_aliases => ['D'], is => 'ro');
    $meta->add_attribute('SmallD', traits => ['Getopt'], isa => 'Bool',
        cmd_aliases => ['d'], is => 'ro');
    $role->meta->apply($meta);

    {
        my $obj = $meta->name->new_with_options(
                { argv => ["-d"], no_ignore_case => 1}
            );

        ok((! $obj->BigD), "BigD was not set for argv -d on $role");
        ok($obj->SmallD, "SmallD was set for argv -d on $role");

    }
    ok($meta->name->new_with_options({ argv => ['-d'], no_ignore_case => 1})
            ->SmallD,
        "SmallD was set for argv -d on $role");
    {
        local @ARGV = ('-d');
        ok($meta->name->new_with_options()->SmallD,
            "SmallD was set for ARGV on $role");
    }

    ok($meta->name->new_with_options({ argv => ['-D'], no_ignore_case => 1})
            ->BigD,
        "BigD was set for argv -d on $role");

    {
        my $obj = $meta->name->new_with_options(
                { argv => ['-D', "-d"], no_ignore_case => 1}
            );

        ok($obj->BigD, "BigD was set for argv -D -d on $role");
        ok($obj->SmallD, "SmallD was set for argv -D -d on $role");

    }
}

done_testing;
