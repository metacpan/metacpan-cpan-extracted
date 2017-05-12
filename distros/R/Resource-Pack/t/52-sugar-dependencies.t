#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

{
    package jQuery::Resource;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'jquery');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            url core => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js';
        };
    }
}

{
    package Other::Resource;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'other');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            install_from(::dir(::data_dir, 'other'));

            resource(jQuery::Resource->new);

            file js => (
                file         => 'other.js',
                dependencies => ['css', 'jquery/core'],
            );

            dir 'css';

            file optional_js => 'other_extras.js';
        };
    }
}

{
    package My::App::Resources;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'my_app');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            install_from(::data_dir);

            resource(jQuery::Resource->new);

            resource(Other::Resource->new(name => 'external'));

            file app_js => (
                file         => 'app.js',
                dependencies => ['jquery/core', 'external/js'],
            );

            file app_css => (
                file       => 'app.css',
                install_to => 'css',
            );

            dir 'images';
        };
    }
}

test_install(
    My::App::Resources->new(install_to => 'app'),
    sub {
        like(file('app', 'jquery.min.js')->slurp,
             qr/jQuery JavaScript Library/,
             "got correct jquery");
        ok(!-e file('app', 'other_extras.js'), "optional js wasn't installed");
    },
    map { file('app', $_) }
        ('app.js', 'other.js', file('css', 'app.css'), file('css', 'foo.css'),
         file('css', 'bar.css'), file('images', 'logo.png'), 'jquery.min.js'),
);

done_testing;
