#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use Prancer::Core;
use Prancer::Plugin::Xslate ();
use Digest::MD5;

# we are going to undef the Prancer::Core singleton over and over again
no strict 'refs';

# try running without any configuration whatsoever
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new();
    my $plugin = Prancer::Plugin::Xslate->load();

    my $output = $plugin->render('t/templates/simple.tx', { 'foo' => 'bar' });
    is($output, "<html><body>bar<br/></body></html>\n");
}

# basic test of functionality
# finds templates in "."
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/simple.yml');
    my $plugin = Prancer::Plugin::Xslate->load();

    my $output = $plugin->render('t/templates/simple.tx', { 'foo' => 'bar' });
    is($output, "<html><body>bar<br/></body></html>\n");
}

# set a template path with a string
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/simple.yml');
    my $plugin = Prancer::Plugin::Xslate->load();
    $plugin->path('t/templates');

    my $output = $plugin->render('simple.tx', { 'foo' => 'bar' });
    is($output, "<html><body>bar<br/></body></html>\n");
}

# set a template path with an array
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/simple.yml');
    my $plugin = Prancer::Plugin::Xslate->load();
    $plugin->path([ 't/templates1', 't/templates2' ]);

    my $output1 = $plugin->render('simple.tx', { 'foo' => 'bar' });
    is($output1, "<html><body>bar<br/></body></html>\n");
    my $output2 = $plugin->render('simpler.tx', { 'foo' => 'asdf' });
    is($output2, "Hello, asdf.\n");
}

# set a template "path" with a hash
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/simple.yml');
    my $plugin = Prancer::Plugin::Xslate->load();
    $plugin->path({
        'simple.tx' => '<html><body><: $foo :><br/></body></html>',
        'simpler.tx' => 'Hello, <: $foo :>.',
    });

    my $output1 = $plugin->render('simple.tx', { 'foo' => 'bar' });
    is($output1, "<html><body>bar<br/></body></html>");
    my $output2 = $plugin->render('simpler.tx', { 'foo' => 'asdf' });
    is($output2, "Hello, asdf.");
}

# add a module with no imports
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/module-no-import.yml');
    my $plugin = Prancer::Plugin::Xslate->load();

    my $output = $plugin->render('t/templates/module-no-import.tx', { 'foo' => 'bar' });
    is($output, "Hello, \$VAR1 = &#39;bar&#39;;\n.\n");
}

# add a module with imports
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/module-import.yml');
    my $plugin = Prancer::Plugin::Xslate->load();

    my $output = $plugin->render('t/templates/module-import.tx', { 'foo' => 'bar' });
    is($output, "Hello, 37b51d194a7513e45b56f6524f2d51f2.\n");
}

# adding a function
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    my $app = Prancer::Core->new('t/configs/function.yml');
    my $plugin = Prancer::Plugin::Xslate->load();

    my $output = $plugin->render('t/templates/function.tx', { 'foo' => 'bar' }, {
        'function' => {
            'md5_hex' => sub { return Digest::MD5::md5_hex(@_); }
        }
    });
    is($output, "Hello, 37b51d194a7513e45b56f6524f2d51f2.\n");
}

# make sure we remember our settings
{
    ${"Prancer::Core::_instance"} = undef;
    ${"Prancer::Plugin::Xslate::_instance"} = undef;

    {
        my $app = Prancer::Core->new('t/configs/simple.yml');
        my $plugin = Prancer::Plugin::Xslate->load();
        $plugin->path({ 'simple.tx' => 'Hello, <: $foo :>.' });

        my $output = $plugin->render('simple.tx', { 'foo' => 'asdf' });
        is($output, "Hello, asdf.");
    }

    {
        my $app = Prancer::Core->new('t/configs/simple.yml');
        my $plugin = Prancer::Plugin::Xslate->load();

        # don't define the path the second time around

        my $output = $plugin->render('simple.tx', { 'foo' => 'asdf' });
        is($output, "Hello, asdf.");
    }
}

done_testing();
