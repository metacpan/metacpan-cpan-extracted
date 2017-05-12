package Mojolicious::Plugin::Plift;

use Mojo::Base 'Mojolicious::Plugin';
use Plift;
use Mojo::Util qw/decode/;

our $VERSION = "0.02";

__PACKAGE__->attr([qw/ plift config /]);


sub register {
    my ( $self, $app, $config ) = @_;

    $self->config($config || {});
    $self->plift($self->_build_plift($config));

    $app->helper( plift => sub { $self->plift });

    $app->renderer->add_handler(
        plift => sub { $self->_render(@_) }
    );
}


sub _render {
    my ( $self, $renderer, $c, $output, $options ) = @_;

    # setup plift
    my $plift = $self->plift;
    $plift->paths( $renderer->paths );

    my $template =
        defined $options->{inline} ?  \($options->{inline})
        : defined $options->{template} && $plift->has_template($options->{template}) ? $options->{template}
        : \($renderer->get_data_template($options));

    # TODO prevent render deep recursion when for exception pages when plift
    # is the default handler
    return unless defined $template;
    return if ref $template && !defined $$template;

    # snippet_namespaces
    my $snippet_namespaces = $c->stash->{'plift.snippet_namespaces'}
        || $self->config->{'snippet_namespaces'}
        || [(ref $c->app).'::Snippet'];

    # resolve data
    my $stash = $c->stash;
    my $data_key = $stash->{'plift.data_key'} || $self->config->{data_key};
    my $data = defined $data_key ? $stash->{$data_key} : $stash;

    my $plift_tpl = $plift->template($template, {
        encoding => $renderer->encoding,
        paths    => $renderer->paths,
        helper   => $c,
        data     => $data,
        snippet_namespaces => $snippet_namespaces
    });

    # delete 'layout' metadata set by previous (e.g. inner content) template
    my $metadata = $plift_tpl->metadata;
    delete $metadata->{layout};

    # render
    my $document = $plift_tpl->render;

    # meta.layout
    $stash->{layout} = $metadata->{layout}
        if defined $metadata->{layout};

    # insert inner content
    if (defined $stash->{'mojo.content'}->{content}) {

        my $wrapper_selector = $stash->{'plift.wrapper_selector'}
            || $self->config->{wrapper_selector} || '#content';

        $document->find($wrapper_selector)
                 ->append($stash->{'mojo.content'}->{content});
    }

    # pass the rendered result back to the renderer
    $$output = defined $c->res->body && length $c->res->body
        ? $c->res->body : decode 'UTF-8', $document->as_html;
}


sub _build_plift {
    my $self = shift;
    my $cfg = $self->config;

    my $plift = Plift->new(
        plugins => $cfg->{plugins} || []
    );

    # x-link
    $plift->add_handler({
        name => 'link-tag',
        tag => 'x-link',
        handler => sub {
            my ($el, $c) = @_;
            my $node = $el->get(0);
            my $path;

            if ($node->hasAttribute('to')) {

                $path = $node->getAttribute('to');
                $node->removeAttribute('to');
            }

            $node->setAttribute('href', $c->url_for($path));
            $node->setNodeName('a');
        }
    });

    # x-csrf-field
    $plift->add_handler({
        name => 'csrf-field-tag',
        tag => 'x-csrf-field',
        handler => sub {
            my ($el, $c) = @_;
            my $node = $el->get(0);

            $node->setNodeName('input');
            $node->setAttribute('value', $c->helper->csrf_token) ;
            $node->setAttribute('type', 'hidden') ;
            $node->setAttribute('name', 'csrf_token')
                unless $node->hasAttribute('name');
        }
    });


    $plift;
}



1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Plift - Plift ♥ Mojolicious

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Plugs L<Plift> to Mojolicious.

=head1 WHAT IS PLIFT?

Out of the box, L<Plift> looks like yet another "designer friendly" HTML
templating engine. It does all common templating stuff like interpolating data
into placeholders, including other templates (e.g. header, footer) wrapping a
template with another (e.g. site layout), etc...

But Plift is more than that. It supports the "View First" approach to web page
development, via L</SNIPPETS>. And allows the development of reusable custom
HTML elements, see L</"CUSTOM ELEMENTS">.

=head1 VIEW FIRST

Plift was inspired by the template system provided by L<Lift|http://liftweb.net/>
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

The next section describes how to work with snippets in L<Plift>.

=head2 SNIPPETS

Snippets are trigerred from html elements via the C<data-snippet> attribute:

    <div data-snippet="say_hello"></div>

Which will map the string C<say_hello> to a snippet class. The mapping is made
by camelizing the string and concatenating to the class namespaces supplied in
the L</snippet_namespaces> config. The default namespace is
C<< <MojocliousAppClass>::Snippet >>. For the C<say_hello> snippet on a app
named 'MyApp', you would have to define the C<MyApp::Snippet::SayHello> class.

    package MyApp::Snippet::SayHello;
    use Mojo::Base -base;

    sub process {
        my ($self, $element) = @_;
        $element->text('Hello, stranger.')
    }

As you can see, the C<process> method is called by default, and a reference to
the element that triggered the snippet is passed as the first argument. The
element is an instance of L<XML::LibXML::jQuery>. The output of this example is:

    <div>Hello, stranger.</div>

=head3 The context object

Ok.. nice.. but you obviously need access to the rest of your app in order to
get useful information. This is done via the context object that is
passed as the second argument. This object is an instace of C<Plift::Context>
that AUTOLOADs methods from a supplied 'helper' object, which in our case is
the L<controller|Mojolicious::Controller> that called L<Mojolicious::Controller/render>.

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


=head3 Parameters

You can pass parameters to the snippet via URI query string syntax.

    <div data-snippet="say_hello?name=Cafe"></div>

Parameters are passed as the third argument to the snippet method.

    sub process {
        my ($self, $element, $c, $params) = @_;
        my $name = $params->{name} || 'stranger';
        $element->text("Hello, $name.")
    }


=head3 Actions

Finally, you can add multiple actions in a single snippet class, and specify
which action to call in the C<data-snippet> attribute.

Lets create a more generic snippet called C<MyApp::Snippet::Say>, which can not
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

Note that specifying only C<data-snippet="say"> (without the "/<action>" part)
will throw an exception, since we haven't defined the default C<process> method
on C<MyApp::Snippet::Say>.


=head3 Parameters and new()

The parameters specified in the query string part of the C<data-snippet>
attribute is also supplied as constructor parameter for the snippet instance.
The C<MyApp::Snippet::Say> snippet could be written as:

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

=head3 Render using directives

In all examples up until now we have been rendering data by manipulating the
C<$element> object directly (e.g. calling L<XML::LibXML::jQuery/text>). While
this is ok, thats a simple and repetitive task that can quickly become tedious.

A better approach is to use L<Plift> renderer directives. You do that via the
context object's methods L<Plift::Context/set> and L<Plift::Context/at>.

Let's rewrite the C<hello()> method using render directives:

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
L<Plift::Manual::Tutorial/"RENDER DIRECTIVES">.


=head2 CUSTOM ELEMENTS

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
