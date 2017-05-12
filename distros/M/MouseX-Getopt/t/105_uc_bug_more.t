use strict;
use warnings;
use Test::More;
use Mouse ();
use Mouse::Meta::Class;

foreach my $role (qw/
    MouseX::Getopt
    MouseX::Getopt::GLD
    MouseX::Getopt::Basic
/) {
    Mouse::Util::load_class($role);

    my $meta = Mouse::Meta::Class->create_anon_class(
        superclasses => ['Mouse::Object'],
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

