[![Build Status](https://travis-ci.org/cafe01/template-plift.svg?branch=master)](https://travis-ci.org/cafe01/template-plift) [![Coverage Status](https://img.shields.io/coveralls/cafe01/template-plift/master.svg?style=flat)](https://coveralls.io/r/cafe01/template-plift?branch=master)
# NAME

Plift - HTML Template Engine + Custom HTML Elements

# SYNOPSIS

    use Plift;

    my $plift = Plift->new(
        path    => \@paths,                               # default ['.']
        plugins => [qw/ Script Blog Gallery GoogleMap /], # plugins not included
    );

    my $tpl = $plift->template("index");

    # set render directives
    $tpl->at({
        '#name' => 'fullname',
        '#contact' => [
            '.phone' => 'contact.phone',
            '.email' => 'contact.email'
        ]
    });

    # render render with data
    my $document = $tpl->render({

        fullname => 'Carlos Fernando Avila Gratz',
        contact => {
            phone => '+55 27 1234-5678',
            email => 'cafe@example.com'
        }
    });

    # print
    print $document->as_html;

# DESCRIPTION

Plift is a HTML template engine which enforces strict separation of business logic
from the view. It is designer friendly, safe, extensible and fast enough to
be used as a web request renderer. This engine tries to follow the principles
described in the paper _Enforcing Strict Model-View Separation in Template Engines_
by Terence Parr of University of San Francisco. The goal is to provide suficient
power without providing constructs that allow separation violations.

# MANUAL

This document is the reference for the Plift class. The manual pages (not yet
complete) are:

- [Plift::Manual::Tutorial](https://metacpan.org/pod/Plift::Manual::Tutorial)

    Step-by-step intruduction to Plift. "Hello World" style.

- [Plift::Manual::DesignerFriendly](https://metacpan.org/pod/Plift::Manual::DesignerFriendly)

    Pure HTML5 template files makes everything easier to write and better to maintain.
    Designers can use their WYSIWYG editor, backend developers can unit test their
    element renderers.

- [Plift::Manual::Inception](https://metacpan.org/pod/Plift::Manual::Inception)

    Talks about the web framework that inspired Plift, and its 'View-First'
    approach to web request handling. (As opposed to the widespread 'Controller-First').

- [Plift::Manual::CustomHandler](https://metacpan.org/pod/Plift::Manual::CustomHandler)

    Explains how Plift is just an engine for reading/parsing HTML files, and
    dispaching subroutine handlers bound to XPath expressions. You will learn how
    to write your custom handlers using the same dispaching loop as the builtin
    handlers.

# METHODS

## add\_handler

- Arguments: \\%parameters

Binds a handler to one or more html tags, attributes, or xpath expression.
Valid parameters are:

- tag

    Scalar or arrayref of HTML tags bound to this handler.

- attribute

    Scalar or arrayref of HTML attributes bound to this handler.

- xpath

    XPath expression matching the nodes bound this handler.

See [Plift::Manual::CustomHandler](https://metacpan.org/pod/Plift::Manual::CustomHandler).

## template

    $context = $plift->template($template_name, \%options)

Creates a new [Plift::Context](https://metacpan.org/pod/Plift::Context) instance, which will load, process and render
template `$template_name`. See ["at" in Plift::Context](https://metacpan.org/pod/Plift::Context#at), ["set" in Plift::Context](https://metacpan.org/pod/Plift::Context#set) and
["render" in Plift::Context](https://metacpan.org/pod/Plift::Context#render).

## process

    $document = $plift->process($template_name, \%data, \@directives)

A shortcut method.
A new context is created via  ["template"](#template), rendering directives are set via
["at" in Plift::Context](https://metacpan.org/pod/Plift::Context#at) and finally the template is rendered via ["render" in Plift::Context](https://metacpan.org/pod/Plift::Context#render).
Returns a [XML::LibXML::jQuery](https://metacpan.org/pod/XML::LibXML::jQuery) object representing the final processed document.

    my %data = (
        fullname => 'John Doe',
        contact => {
            phone => 123,
            email => 'foo@example'
        }
    );

    my @directives =
        '#name' => 'fullname',
        '#name@title' => 'fullname',
        '#contact' => {
            'contact' => [
                '.phone' => 'phone',
                '.email' => 'email',
            ]
    );

    my $document = $plift->process('index', \%data, \@directives);

    print $document->as_html;

## render

    $html = $plift->render($template_name, \%data, \@directives)

A shortcut for `$plift->process()->as_html`.

## load\_components

    $plift = $plift->load_components(@components)

Loads one or more Plift components. For each component, we build a class name
by prepending `Plift::` to the component name, then load the class, instantiate
a new object and call `$component->register($self)`.

See [Plift::Manual::CustomHandler](https://metacpan.org/pod/Plift::Manual::CustomHandler).

# SIMILAR PROJECTS

This is a list of modules (that I know of) that pursue similar goals:

- [HTML::Template](https://metacpan.org/pod/HTML::Template)

    Probably one of the first to use (almost) valid html files as templates, and
    encourage less business logic to be embedded in the templates.

- [Template::Pure](https://metacpan.org/pod/Template::Pure)

    Perl implementation of Pure.js. This module inspired Plift's render directives.

- [Template::Semantic](https://metacpan.org/pod/Template::Semantic)

    Similar to Template::Pure, but the render directives points to the actual data
    values, instead of datapoints. Which IMHO makes the work harder.

- [Template::Flute](https://metacpan.org/pod/Template::Flute)

    Uses a XML specification format for the rendering directives. Has lots of other
    features.

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@kreato.com.br>
