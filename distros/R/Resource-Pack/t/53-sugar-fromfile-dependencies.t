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

    extends 'Resource::Pack::FromFile';

    has '+name' => (default => 'other');
    has '+resource_file' => (
        default => sub { ::file(::data_dir, 'other', 'resources') }
    );
}

{
    package My::App::Resources;
    use Moose;

    extends 'Resource::Pack::FromFile';

    has '+name' => (default => 'my_app');
    has '+resource_file' => (
        default => sub { ::file(::data_dir, 'resources') }
    );
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
