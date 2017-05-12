#!/usr/bin/env perl
use lib 't/lib';
use Test::Resource::Pack;

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

            url jquery => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js';
            file app_js => 'app.js';
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
    },
    map { file('app', $_) }
        ('app.js', file('css', 'app.css'), file('images', 'logo.png'),
         'jquery.min.js'),
);

done_testing;
