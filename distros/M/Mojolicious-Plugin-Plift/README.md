# NAME

Mojolicious::Plugin::Plift - Plift ♥ Mojolicious

# SYNOPSIS

package PliftApp;

    use Mojo::Base 'Mojolicious';

    sub startup {
        my $app = shift;

        $app->plugin('Plift');
        # $app->renderer->default_handler('plift');

        my $r = $app->routes;
        $r->get('/' => { template => 'index', handler => 'plift' });

        ...
    }

    1;

# DESCRIPTION

Plugs [Plift](https://metacpan.org/pod/Plift) to Mojolicious.

# WHAT IS PLIFT?

Out of the box, [Plift](https://metacpan.org/pod/Plift) looks like yet another "designer friendly" HTML
templating engine. It does all common templating stuff like interpolating data
into placeholders, including other templates (e.g. header, footer) wrapping a
template with another (e.g. site layout), etc...

But Plift is more than that. It supports the "View First" approach to web page
development, via ["SNIPPETS"](#snippets). And allows the development of reusable custom
HTML elements, see ["CUSTOM ELEMENTS"](#custom-elements).

# VIEW FIRST

Plift was inspired by the template system provided by [Lift](http://liftweb.net/)
(hence the name), a web framework for the Scala programming language.
They apply a concept called "View-First", which differs from the traditional
"Controller-First" concept popularized by the MVC frameworks.

On the "Controller-First" approach, the Controller is executed first, and is
responsible for pulling data from the "Model", then making this data available
to the "View". This creates a tight coupling between the controller and the
final rendered webpage, since it needs to know and gather all data possibly
need by the webpage templates. Thats perfect for well defined webapp actions,
but not so perfect for creating reusable website components.

On the other hand, a "View-First" framework starts by parsing the view, then
executing small, well-defined pieces of code triggered by special html attributes
found in the template itself. These code snippets are responsible for rendering
dynamic data using the html element (that triggered it) as the data template.

The next section describes how to work with snippets in [Plift](https://metacpan.org/pod/Plift).

## SNIPPETS

Snippets are trigerred from html elements via the `data-snippet` attribute:

    <div data-snippet="say_hello"></div>

Which will map the string `say_hello` to a snippet class. The mapping is made
by camelizing the string and concatenating to the class namespaces supplied in
the ["snippet\_namespaces"](#snippet_namespaces) config. The default namespace is
`<MojocliousAppClass>::Snippet`. For the `say_hello` snippet on a app
named 'MyApp', you would have to define the `MyApp::Snippet::SayHello` class.

    package MyApp::Snippet::SayHello;
    use Mojo::Base -base;

    sub process {
        my ($self, $element) = @_;
        $element->text('Hello, stranger.')
    }

As you can see, the `process` method is called by default, and a reference to
the element that triggered the snippet is passed as the first argument. The
element is an instance of [XML::LibXML::jQuery](https://metacpan.org/pod/XML::LibXML::jQuery). The output of this example is:

    <div>Hello, stranger.</div>

### The context object

Ok.. nice.. but you obviously need access to the rest of your app in order to
get useful information. This is done via the context object that is
passed as the second argument. This object is an instace of `Plift::Context`
that AUTOLOADs methods from a supplied 'helper' object, which in our case is
the [controller](https://metacpan.org/pod/Mojolicious::Controller) that called ["render" in Mojolicious::Controller](https://metacpan.org/pod/Mojolicious::Controller#render).

    sub process {
        my ($self, $element, $c) = @_;
        my $name = $c->stash->{name} || 'stranger';

        # Or call methods directly on the controller, needed when
        # calling methods that are also AUTOLOADed from the controller
        # instance:
        #
        # $c->helper->csrf_token

        $element->text("Hello, $name.")
    }

### Parameters

You can pass parameters to the snippet via URI query string syntax.

    <div data-snippet="say_hello?name=Cafe"></div>

Parameters are passed as the third argument to the snippet method.

    sub process {
        my ($self, $element, $c, $params) = @_;
        my $name = $params->{name} || 'stranger';
        $element->text("Hello, $name.")
    }

### Actions

Finally, you can add multiple actions in a single snippet class, and specify
which action to call in the `data-snippet` attribute.

Lets create a more generic snippet called `MyApp::Snippet::Say`, which can not
only say 'hello' but can also say 'goodbye'. Amazing, uh?

    package MyApp::Snippet::Say;
    use Mojo::Base -base;

    sub hello {
        my ($self, $element, $c, $params) = @_;
        $element->text("Hello, $params->{name}!")
    }

    sub goodbye {
        my ($self, $element, $c, $params) = @_;
        $element->text("Goodbye, $params->{name}!")
    }

Now you can specify the 'hello' or 'goodbye' action in the data-snippet attribute.

    <div data-snippet="say/hello?name=Cafe"></div>
    <div data-snippet="say/goodbye?name=Cafe"></div>

Outputs:

    <div>Hello, Cafe!</div>
    <div>Goodbye, Cafe!</div>

Note that specifying only `data-snippet="say"` (without the "/&lt;action>" part)
will throw an exception, since we haven't defined the default `process` method
on `MyApp::Snippet::Say`.

### Parameters and new()

The parameters specified in the query string part of the `data-snippet`
attribute is also supplied as constructor parameter for the snippet instance.
The `MyApp::Snippet::Say` snippet could be written as:

    package MyApp::Snippet::Say;
    use Mojo::Base -base;

    has 'name';

    sub hello {
        my ($self, $element) = @_;
        $element->text(sprintf "Hello, %s!", $self->name);
    }

    sub goodbye {
        my ($self, $element) = @_;
        $element->text(sprintf "Goodbye, %s!", $self->name);
    }

### Render using directives

In all examples up until now we have been rendering data by manipulating the
`$element` object directly (e.g. calling ["text" in XML::LibXML::jQuery](https://metacpan.org/pod/XML::LibXML::jQuery#text)). While
this is ok, thats a simple and repetitive task that can quickly become tedious.

A better approach is to use [Plift](https://metacpan.org/pod/Plift) renderer directives. You do that via the
context object's methods ["set" in Plift::Context](https://metacpan.org/pod/Plift::Context#set) and ["at" in Plift::Context](https://metacpan.org/pod/Plift::Context#at).

Let's rewrite the `hello()` method using render directives:

    sub hello {
        my ($self, $element, $c, $params) = @_;
        my $selector = $c->selector_for($element);

        $c->set( greeting => "Hello, $params->{name}!")
          ->at( $selector => 'greeting');
    }

Okay, although for this particular short example the reimplemented method using
render directives actually has more lines of code, anything more complex than
that would really benefit of directives capabilities.

For more information on how directives work, see
["RENDER DIRECTIVES" in Plift::Manual::Tutorial](https://metacpan.org/pod/Plift::Manual::Tutorial#RENDER-DIRECTIVES).

## CUSTOM ELEMENTS

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz &lt;cafe@kreato.com.br>
