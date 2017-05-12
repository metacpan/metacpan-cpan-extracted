#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

{
    package External::Resource;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'external');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            install_to 'js';
            install_from(::dir(::data_dir, 'external'));
            file js => 'external.js';
        };
    }
}

{
    package My::App::Resource;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'my_app');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            install_from(::data_dir);
            resource(External::Resource->new);
            dir js => (
                dir          => 'js',
                dependencies => ['external/js'],
            );
        };
    }
}

{
    my $resource = My::App::Resource->new(install_to => 'app');
    test_install(
        $resource,
        sub {
            ok(!-e file('app', 'external.js'),
               "doesn't install to the wrong place")
        },
        file('app', 'js', 'app.js'), file('app', 'js', 'external.js'),
    );
}

{
    package My::App::Resource2;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'my_app');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            install_from(::data_dir);
            resource(External::Resource->new, as {
                install_to '';
            });
            dir js => (
                dir          => 'js',
                dependencies => ['external/js'],
            );
        };
    }
}

{
    my $resource = My::App::Resource2->new(install_to => 'app');
    test_install(
        $resource,
        sub {
            ok(!-e file('app', 'js', 'external.js'),
               "doesn't install to the wrong place")
        },
        file('app', 'js', 'app.js'), file('app', 'external.js'),
    );
}

done_testing;
