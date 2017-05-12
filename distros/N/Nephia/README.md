# NAME

Nephia - A microcore architecture WAF

# SYNOPSIS

    use Nephia plugins => [...];
    app {
        my $req  = req;         ### Request object
        my $id   = param('id'); ### query-param that named "id" 
        my $body = sprintf('ID is %s', $id);
        [200, [], $body];
    };

# DESCRIPTION

Nephia is microcore architecture WAF. 

# GETTING STARTED

Let's try to create your project.

    nephia-setup YourApp::Web

Then, you may plackup on your project directory.

Please see [Nephia::Setup::Plugin::Basic](http://search.cpan.org/perldoc?Nephia::Setup::Plugin::Basic) for detail.

# BOOTSTRAP A MINIMALIST STRUCTURE

Use "--plugins Minimal" option to minimalistic setup.

    nephia-setup --plugins Minimal YourApp::Mini

Please see [Nephia::Setup::Plugin::Minimal](http://search.cpan.org/perldoc?Nephia::Setup::Plugin::Minimal) for detail.

# LOAD OPTIONS 

Please see [Nephia::Core](http://search.cpan.org/perldoc?Nephia::Core).

# DSL

## app

    app { ... };

Specify code-block of your webapp.

## other two basic DSL

Please see [Nephia::Plugin::Basic](http://search.cpan.org/perldoc?Nephia::Plugin::Basic).

## dispatcher DSL

Please see [Nephia::Plugin::Dispatch](http://search.cpan.org/perldoc?Nephia::Plugin::Dispatch).

# EXPORTS

## run

In app.psgi, run() method returns your webapp as coderef.

    use YourApp::Web;
    YourApp::Web->run;

# CLASS METHOD

## call

Returns external logic as coderef.

    my $external_logic = Nephia->call('C::Root#index');

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
