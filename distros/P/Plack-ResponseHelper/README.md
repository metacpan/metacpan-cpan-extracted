# NAME

Plack::ResponseHelper

# SYNOPSIS

You can treat it as a micro-framework:

in app.psgi

    use Plack::Request;
    use Plack::ResponseHelper json => 'JSON',
                              text => 'Text';

    my $app = sub {
        my $env = shift;
        my $form = Plack::Request->new($env)->parameters();
        my $controller = ...;
        respond $controller->($form);
    };

somewhere in your controllers

    sub my_controller {
        ...
        return json => {status => 'ok', data => [1, 2, 3]};
    }

    # or
    sub dummy_controller {
        return text => "It works!";
    }

Or if your app is even less sophisticated, just

    use Plack::ResponseHelper text => 'Text';
    sub {
        respond text => 'Hello world!';
    }

# DESCRIPTION

A very thin layer that abstracts Plack's specifics.

Bundled with
[Plack::ResponseHelper::Attachment](http://search.cpan.org/perldoc?Plack::ResponseHelper::Attachment),
[Plack::ResponseHelper::JSON](http://search.cpan.org/perldoc?Plack::ResponseHelper::JSON),
[Plack::ResponseHelper::Redirect](http://search.cpan.org/perldoc?Plack::ResponseHelper::Redirect),
[Plack::ResponseHelper::Text](http://search.cpan.org/perldoc?Plack::ResponseHelper::Text).

# METHODS

## use options

    use Plack::ResponseHelper $type1 => $helper1, ...;

Here you declare your types, it means that you have to use these types
in your calls to `respond`.

`$helper` is short helper's name, a plus sign can be used:

    # will load Plack::ResponseHelper::JSON
    use Plack::ResponseHelper json => 'JSON';

    # will load Plack::ResponseHelper::My::Helper
    use Plack::ResponseHelper my_helper => '+My::Helper';

## respond

    respond $type => $response;

`respond` is always imported.
Two arguments are required: the type of response and the response itself.

# AUTHORING YOUR OWN HELPERS

Your module just has to contain a `helper` function that returns a coderef
for processing the response data structure that is passed to `respond`.

For more complex helpers you may need to be able to customize their behaviour,
this is achieved by passing an `$init` parameter:

    use Plack::ResponseHelper my_helper => ['My::Helper', $init];

`$init` can be anything that PX::RH::My::Helper supports, e.g. a code ref
that returns some dynamic data, or just a hashref with configuration options.

    package Plack::ResponseHelper::My::Helper;
    use strict;
    use warnings;

    sub helper {
        my $init = shift;
        my $content_type = $init && $init->{content_type} || 'text/plain';

        return sub {
            my $r = shift;
            return [
                200,
                ['Content-type' => $content_type],
                ['Hello world!']
            ];
        };
    }

    1;

# LICENSE

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
