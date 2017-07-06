package Template::Lace;

our $VERSION = '0.007';

1;

=head1 NAME

Template::Lace - Logic-less, strongly typed, and componentized HTML templates.

=head1 SYNOPSIS

A Template Model:

    package MyApp::Template::User;

    use Moo;

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub template {
      return q[
        <html>
          <head>
            <title>User Info</title>
          </head>
            <body>
              <dl id='user'>
                <dt>Name</dt>
                <dd id='name'> -NAME- </dd>
                <dt>Age</dt>
                <dd id='age'> -AGE- </dd>
                <dt>Motto</dt>
                <dd id='motto'> -MOTTO- </dd>
              </dl>
            </body>
        </html>
      ]
    }

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', +{
        age=>$self->age,
        name=>$self->name,
        motto=>$self->motto});
    }

    1;

A Factory and Renderer

    my $factory = Template::Lace::Factory->new(
      model_class=>'MyApp::Template::User');

    # Once the $factory is created you can reuse it to build new
    # template renderer instances.

    my $renderer = $factory->create(
      age=>42,
      name=>'John',
      motto=>'Life in the Fast Lane!');

    print $renderer->render;

Outputs:

    <html>
      <head>
        <title>
          User Info
        </title>
      </head>
      <body id="body">
        <dl id="user">
          <dt>
            Name
          </dt>
          <dd id="name">
            John
          </dd>
          <dt>
            Age
          </dt>
          <dd id="age">
            42
          </dd>
          <dt>
            Motto
          </dt>
          <dd id="motto">
            Why Not?
          </dd>
        </dl>
      </body>
    </html>

=head1 DISCLAIMER

L<Template::Lace> is a toolkit for building HTML pages using logic-less and componentized
templates.  As such this distribution is currently not aimed at standalone use but rather
exists as all the reusable bits that fell out when I refactored L<Catalyst::View::Template::Lace>.
So currently this toolkit then exists to support the L<Catalyst> View and as a result documentation
here is high level and API level.  If you want to integrate L<Template::Lace> into other
web frameworks you might wish to review L<Catalyst::View::Template::Lace> for a possible
approach.  Ideas about how to make this distribution more usefully stand alone are quite welcomed!
Examples given here are probably more verbose than it would be if using this under a web
framework like L<Catalyst> (see L<Catalyst::View::Template::Lace>).

You may wish to review the files under the C</examples> directory of this distribution to
see a L<Web::Simple> proof of concept.

B<NOTE> Since this is still under heavy development and review I reserve the right to make
breaking changes, or to conclude the approach is fundementally flawed and exit the project. Do
not use this code in production aimed systems unless you are skilled enough to take on that
risk and responsibility.

=head1 DESCRIPTION

L<Template::Lace> is a toolkit that makes it possible to bind HTML templates to plain old Perl
classes as long as they provide a defined interface. These
templates are fully HTML markup only; they contain no display logic, only valid HTML and component
declarations.  We use L<Template::Lace::DOM> (which is a subclass of L<Mojo::DOM58>) to alter the 
template for presentation at request time.  L<Template::Lace::DOM> provides an API to transform
the template into HTML using instance data and methods provided by the class.  See the class
L<Template::Lace::DOM> and L<Mojo::DOM58> for more about how these classes allow you to inspect
and modify a DOM.

When you have a Perl class that conform to these requirements we call that a 'Model' class
Here's an example of a very simple Model class:

    package  MyApp::Template::User;

    use Moo;

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub template { q[
      <html>
        <head>
          <title>User Info</title>
        </head>
          <body>
            <dl id='user'>
              <dt>Name</dt>
              <dd id='name'> -NAME- </dd>
              <dt>Age</dt>
              <dd id='age'> -AGE- </dd>
              <dt>Motto</dt>
              <dd id='motto'> -MOTTO- </dd>
            </dl>
          </body>
      </html>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', +{
        age=>$self->age,
        name=>$self->name,
        motto=>$self->motto});
    }

    1;

In this example the Model class defines two methods, C<process_dom> and C<template>.  Any Perl class
can be used as Model class as long as it provides these methods (as well as a stub for C<prepare_dom>
which will we discuss later).  The C<template> method
just needs to return a string.  It should contain your desired HTML markup.  The C<process_dom> method
is an instance method on your class, and it gets both C<$self> and C<$dom>, where C<$dom> is a
DOM representation of your template (via L<Template::Lace::DOM>).  Anything you want to change about
the template should be done via the L<Template::Lace::DOM> API.  This is a subclass of L<Mojo::DOM58>
a Jquery like API for transforming HTML.  Our custom subclass contains some additional helper methods
to make common types of transforms easier.  For example here we use the custom helper C<dl> to find
a C<dl> tag by its id and then populate its data by matching hash keys to tag ids.

So how do you get a rendered template out of a Model class?  That's the job of two additional
classes, L<Template::Lace::Factory> and L<Template::Lace::Renderer> (with a tag team by 
L<Template::Lace::Components> should your template contain components; to be discussed later).

L<Template::Lace::Factory> wraps your model class and inspects it to create an initial DOM representation
of the template (as well as prepare a component hierarchy, should you have components).  Most
simply it looks like this:

    my $factory = Template::Lace::Factory->new(
      model_class=>'MyApp::Template::User');

Next you call the C<create> method on the C<$factory> instance with the initial arguments you want to
pass to the Model.  Create doesn't return the Model directly, but instead returns an instance of
L<Template::Lace::Renderer> which is wrapping the model:

    my $renderer = $factory->create(
      age=>42,
      name=>'John',
      motto=>'Life in the Fast Lane!');

    $renderer->model; # this is the actual instance of MyApp::Template::User via
                      # the provided args to ->create.

Those initial arguments are passed to the model and used to create an instance of the model.  But the
wrapping C<$renderer> exposes methods that are used to do the actual transformation.  For example

    print $renderer->render;

Would return:

    <html>
      <head>
        <title>
          User Info
        </title>
      </head>
      <body id="body">
        <dl id="user">
          <dt>
            Name
          </dt>
          <dd id="name">
            John
          </dd>
          <dt>
            Age
          </dt>
          <dd id="age">
            42
          </dd>
          <dt>
            Motto
          </dt>
          <dd id="motto">
            Why Not?
          </dd>
        </dl>
      </body>
    </html>

And that is the basics of it!  Once you have a C<$factory> you can call C<create> on it as many times
as you like to make different versions of the rendered page.

=head1 PREPARING THE DOM

Sometimes a Model may wish to make some modifications to its DOM once at setup time.  For
example you might add some debugging information to the header.  Although you can do this
in C<process_dom> it might seem wasteful if the change isn't dynamic, or bound to something
that can change for each request.  In this case your Model may add a class method C<prepare_dom>
which gets access to the DOM of the template during its initial setup.  Any changes you make
at this point will become cloned for all subsequent requests.  For example:

    package  MyApp::Template::List;

    use Moo;
    with 'Template::Lace::Model::AutoTemplate';

    has [qw/form items copywrite/] => (is=>'ro', required=>1);

    sub time { return scalar localtime }

    sub prepare_dom {
      my ($class, $dom, $merged_args) = @_;

      # Add some meta-data
      $dom->at('head')
        ->prepend_content("<meta startup='${\$self->time}'>");
    }

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->ol('#todos', $self->items);
    }

In this case we'd add a startup timestamp to the header area of the template, which might be
useful for debugging for example.

This example also used the role L<Template::Lace::Model::AutoTemplate> which allows you to
pull your template from a standalone file using a simple naming convention.  When your
templates are larger and more complex, or when you have HTML designer that prefers standalone
templates instead of ones mixed into Perl code, you can use this role to achieve that.  See
the docs in L<Template::Lace::Model::AutoTemplate> for more.

=head1 ADVANCED TEMPLATE MANIPULATION

So far we've seen how to use C<process_dom> (and the related C<prepare_dom>) to transform your
template.  Strickly speaking however you do not actually need to declare these methods in your
view model.  You may instead choose to allow the renderer to 'call into' the model.  This approach
can give the end user a bit more control over how the template is actually rendered.  Example:

    package Local::Template::NoProcessDom;

    use Moo;

    sub template { qq{
      <section>
        Hello <span id="name">NAME</span>, you are <span id="age"></span> years old!
      </section>
    }}

    sub fill_name {
      my ($self, $dom, $name) = @_;
      $dom->do('#name', $name);
    }

    sub fill_age {
      my ($self, $dom, $age) = @_;
      $dom->do('#age', $age);
    }

    my $factory = Template::Lace::Factory->new(
      model_class=>'Local::Template::NoProcessDom');

    my $renderer = $factory->create();

    $renderer->call('fill_name', 'John');
    $renderer->call('fill_age', '42');
    
    my $html = $renderer->render;
    print $html;

Returns:

    <section>
      Hello <span id="name">John</span>, you are <span id="age">42</span> years old!
    </section>

You might find this approach useful when you have a template where you process it differently
depending on logic under the control of the code that gets the renderer.  For example you might
have a form that may or may not have errors.  

B<NOTE> You can combine both approachs, have a C<process_dom> and yet also call into the view
model to handle special display conditions.

=head1 COMPONENTS

Most template systems have a mechanism to make it possible to divide your template into
discrete, re-usable chunks.  L<Template::Lace> provides this via Components.  Components are
custom tags embedded into your template, usually with some markup which allows you to control
the passing of information into the component from the Model class.  In your template you
would declare a component like this:

    <prefix-name
        attr1='literal value'
        attr2='$.foo'
        attr3=\'title:content'>
      [some additional content such as HTML markup and text]
    </prefix-name>

A component doesn't have to contain anything (like the <br/> or <hr/> tag) in which case
its just:

    <prefix-name
        attr1='literal value'
        attr2='$.foo'
        attr3=\'title:content' />
    
Here's an example:

    <view-footer copydate='$.copywrite' />

And another example:

    <lace-form
        method="post" 
        action="$.post_url">
      <input type='text' name='user' />
      <input type='text' name='age' />
      <input type='text' name='motto' />
      <input type='submit' />
    </lace-form>

Canonically a component is a tag in the form of '$prefix-$name' (like <prefix-name ...>)
and typically will contain HTML attributes (like 'attr1="Literal"') and it may also
have content, as in "<lace-form><input id='content' type="submit"/></lace-form>".  When you render
a template containing components, any HTML attributes will be converted to a real value
and passed to the component as initialization arguments.  There are three different
ways your attributes will be processed:

=over4

=item literal values

Example: <prefix-name attr='1984'/>

When a value is a simple literal that value is passed as is.

=item a path from the model instance

Example: <prefix-name attr='$.foo'/>

This returns the value of "$self->foo", where $self is the model instance that the factory
created.  You can follow a data path similarly to Template Toolkit, for example:

    <prefix-name attr="$.foo.bar.baz" />

Would be the value of "$self->foo->bar->baz" (or possibly $self->foo->{bar}{baz} since we
follow either a method name or the key of a hash).  Currently we do not follow arrayrefs.

You'll probably use this quite often to pass instance information to your component.  If
the path does not exist that will return a run time error.

=item a CSS match 

Examples: <prefix-name title=\'title:content' css=\'@link' />

When the value of the attribute begins with a '\' that means we want to get the value of
a CSS match to the current DOM.  In Perl when a variable starts with a '\' the means its
a reference; so you can think of this as a reference to a point in the current DOM.

In general the value here is just a normal CSS match specification (see L<Mojo::DOM58> for
details on the match specifications supported).  However we have added two minor bits to
how L<Mojo::DOM58> works to make some types matching easier.  First, if a match specification
ends in ':content' that means 'match the content, not the full node'.  In the example case
"title=\'title:content'" that would get the text value of the title tag.  Second, in the case
where you want the match to return a collection of nodes all matching the specification, you
would prepend a '@' to the front of it (think in Perl @variable means an array variable). In
the given example "css=\'@link'" we want the attribute 'css' to be a collection of all the
linked stylesheets in the current DOM.

You will use this type of value when you are making components that do complex layout
and overlays of the current DOM (such as when you are creating a master layout page for
your website).

=back

In addition to any attributes you pass to a component via a declaration as described above
all components could get some of the following automatic atttributes:

=over 4

=item content

If the component has content as in the following example

    <prefix-name
        attr1='literal value'
        attr2='$.foo'
        attr3=\'title:content'>
      [some addtional content such as HTML markup and text]
    </prefix-name>

That content will be sent to the component under the 'content' attribute

=item container 

If the component is a subcomponent it will receive the instance model of its
parent as the 'container' attribute.

=item model

All components get the 'model' attribute, which is the model instance that contains
the template in which they appear.  I would use this carefully since I think that
you would prefer to pass information from the model to the component via attributes.

=back

If you need to pass complex or structured data to your arguments you may do so using
JSON:

    <prefix-name
        hash={"q":"The query string"}
        array=["1","2","3"]
      [some addtional content such as HTML markup and text]
    </prefix-name>

Components can be an instance of any class that does C<create> and C<process_dom>
but generally you will make your components out of other L<Template::Lace> models
since that provides the most features and template reusability. Components are added to
the Factory at the time you construct it:

    my $factory = Template::Lace::Factory->new(
      model_class=>'Local::Template::List',
      component_handlers=>+{
        layout => sub {
          my ($name, $args, %attrs) = @_;
          $name = ucfirst $name;
          return Template::Lace::Factory->new(model_class=>"Local::Template::$name");
        },
        lace => {
          form => Template::Lace::Factory->new(model_class=>'Local::Template::Form'),
          input => Template::Lace::Factory->new(model_class=>'Local::Template::Input'),
        },
      },
    );

Components are added as a hashref of data associated with the 'component_handlers'
initialization argument for the class L<Template::Lace::Factory>.  You can either
attach a component to a full 'prefix-name' pair, as in the examples for 'form' and
'input', or you can create a component 'generator' for an entire prefix by associating
the prefix with a coderef which is responsible for returning a component based on the
actual name.

If your components are trivial and/or you don't want to make a full model and Factory for
one, you can use the L<Template::Lace::Utils> subroutine C<mk_component> to assist.  This
creates an instance of L<Template::Lace::ComponentCallback> which is a very simple component
defined by a code reference.  These type of components are easy to make and can run faster
when rendering your templates but have the downside of being defined into your Factory and
this reduces reuse.  Example:

    use Template::Lace::Utils 'mk_component';
    my $factory = Template::Lace::Factory->new(
      model_class=>'Local::Template::List',
      component_handlers=>+{
        tags => {
          anchor => mk_component {
            my ($self, %attrs) = @_;
            return "<a href='$_{href}' target='$_{target}'>$_{content}</a>";
          }
        },
      },
    );

When using this approach to creating a component, you define a subroutine that will get C<$self>
and C<%attrs> (where C<%attrs> is the processed attributes from your component declaration in the
template) and you must return
either a string or an instance of L<Template::Lace::DOM>.  To make things easier for creating
simple components we localize '$_' to C<$self> and '%_' to C<%attrs>.  For the most part these
types of components are the same as those defined via a factory but with fewer overall features
(for example they can't currently support C<on_component_add>).  The choice for either style
will depend on your need for reuse and the overall complexity of the component.

When the factory is created, it delegates the job of walking the DOM we made from the Model's
template and creating a hierarchy of components actually found.  All found components need to
match something in 'component_handlers' or they will be silently ignored (this is a feature
since if you are using client side web components you would want those to be passed on
without note).  When we call C<create> on the factory we initialize the component
hierarchy by calling C<create> on each factory component present and then when we render
the template we render each component and replace the full component node with th results
of the rendering.

Here's a full example of a template that is a TODO list which contains a list of 
items 'TODO' as well as a form to add new items (with the ability to give error feedback to
the user if they submit bad items).

    package MyApp::Template::List

    use Moo;

    has [qw/form items copywrite/] => (is=>'ro', required=>1);

    sub template {q[
      <view-master title=\'title:content'
          css=\'@link'
          meta=\'@meta'
          body=\'body:content'>
        <html>
          <head>
            <title>Things To Do</title>
            <link href="/static/summary.css" rel="stylesheet"/>
            <link href="/static/core.css" rel="stylesheet"/>
          </head>
          <body>
            <view-form id="newtodo" fif='$.form.fif' errors='$.form.errors'>
              <view-input id='item'
                  label="Todo"
                  name="item"
                  type="text" />
            </view-form>
            <ol id='todos'>
              <li> -What To Do?- </li>
            </ol>
            <view-footer copydate='$.copywrite' />
          </body>
        </html>
      </view-master>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->ol('#todos', $self->items);
    }

    1;

So this Model declares a template with four components: C<view-master>, C<view-form>, C<view-input>,
and C<view-footer>.  It also declares a C<process_dom> method to populate the C<ol> at id 'todos'.
The C<process_dom> should be straight forward, the C<ol> helper is smart enough to populate the
list for you if you pass it an array reference.  Component wise we have a hierarchy that looks like
this:

    view-master
        view-form
            view-input
      view-footer

And we could create a C<$factory> for this model with a setup like:

    my $factory = Template::Lace::Factory->new(
      model_class=>'MyApp::Template::List',
      component_handlers=>+{
         view => {
          master => Template::Lace::Factory->new(model_class=>'MyApp::Template::Form'),
          form => Template::Lace::Factory->new(model_class=>'MyApp::Template::Form'),
          input => Template::Lace::Factory->new(model_class=>'MyApp::Template::Input'),
          footer => Template::Lace::Factory->new(model_class=>'MyApp::Template::Form'), 
        },
      },
    );

B<NOTE> If you have a strong convention between your component name and the Model class
it would be easy to take advantage of the prefix handler code reference option to automatically
generate your components as needed.  Example given is for ease of understanding!

The 'view-footer' component is the most simple so lets look at that first:

    package  MyApp::View::Footer;

    use Moo;

    has copydate => (is=>'ro', required=>1);

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->at('#copy')
        ->append_content($self->copydate);
    }

    sub template {
      my $class = shift;
      return q[
        <section id='footer'>
          <hr/>
          <p id='copy'>copyright </p>
        </section>
      ];
    }

    1;

When we call:

    my $renderer = $factory->create(copywrite=>2017, ...);
    
That creates an instance of C<MyApp::Template::List> with the attribute 'copywrite' set to '2017'.
During this setup, we walk the component hierarchy and when we get to the 'view-footer' component
we call "->create(copydate=>$renderer->model->copywrite)" on it to create an instance of that
component. Then when we call:

    my $html_string = $renderer->render;

We call "->render" on that component instance and replace the component node with the new
string.  In this case that string would look like:

    <section id='footer'>
      <hr/>
      <p id='copy'>copyright 2017</p>
    </section>

and that would replace the entire node "<view-footer copydate='$.copywrite' />".

This 'view-footer' example is probably the closest thing to a traditional 'include' or
'partial' template as you might have used in other template systems.  For an include this
simple it probably seems like a lot more work and code.  However as you will see the
component system is significantly more powerful than this, and even with an example this
simple you get some powerful benefits including a strong separate between HTML markup
and display logic, the ability to take full advantage of the power of Perl and a strongly
typed interface between your component at the world.  These are all things that I believe
make your code more maintainable and les buggy.  Lets look at a more complex component,
the 'view-form' component:

    package  MyApp::View::Form;

    use Moo;

    has [qw/id fif errors content/] => (is=>'ro', required=>0);

    sub create_child {
      my ($self, $child_factory, %init_args) = @_;
      my $value = $self->fif->{$init_args{name}};
      my @errors = @{$self->errors->{$init_args{name}} ||[]};
      my $child_component = $child_factory->create(
        %init_args, 
        value => $value,
        errors => \@errors);
      return $child_component;
    }

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->at('form')
        ->attr(id=>$self->id)
        ->content($self->content);      
    }

    sub template {
      my $class = shift;
      return q[<form></form>];
    }

So I deliberately made a more complex example here so you could see one of the ways
that parent / child interaction can occur when there is a component hierarchy.  Here
we are letting the parent 'view-form' component be responsible for creating its own
child components.  We are doing this so that the 'view-form' component can give information
about state and any errors to any input type child components.  We could also have
had the children reach into the 'view-form' component to get that information (since
each child does have access to the parent via the 'container' attribute, or we could have
simple pulled it directly from the Model class via an html attribute, for example:

    <view-input id='item'
        label="Todo"
        name="item"
        type="text"
        fif="$.form.fif.item"
        errors="$.form.errors.item"/>

This part of the system is under active development and consideration, its likely
we haven't worked out all the best ways this needs to work, or built in all the API
necessary.  Discussion welcomed!

This component also demonstrates how a component that wraps content might work, since it
collects that content via the 'content' attribute and inserts into into its own
local DOM (via ->content($self->content) using L<Template::Lace::DOM>.  Lets see the
how the 'view-input' component works:

    package  MyApp::View::Input;

    use Moo;

    has [qw/id label name type value errors/] => (is=>'ro');

    sub process_dom {
      my ($self, $dom) = @_;
      
      # Set Label content
      $dom->at('label')
        ->content($self->label)
        ->attr(for=>$self->name);

      # Set Input attributes
      $dom->at('input')->attr(
        type=>$self->type,
        value=>$self->value,
        id=>$self->id,
        name=>$self->name);

      # Set Errors or remove error block
      if($self->errors) {
        $dom->ol('.errors', $self->errors);
      } else {
        $dom->at("div.error")->remove;
      }
    }

    sub template {
      my $class = shift;
      return q[
        <link href="css/main.css" />
        <style id="min">
          div { border: 1px }
        </style>
        <div class="field">
          <label>LABEL</label>
          <input />
        </div>
        <div class="ui error message">
          <ol class='errors'>
            <li>ERROR</li>
          </ol>
        </div>
      ];
    }

    1;

Here I think you start to get the picture of how components can organize complex
display logic without making a messy template.  This component easily encapsulates
many of the parts of an input form, including label setup, value, type, etc.  It
also displays any form errors (for example generated by L<HTML::Formhandler> during
a POST) or removes the HTML markup around errors.  A simple include in TT would
have to contain loops and conditionals, and leave you with a template that was
not tidy at all.  Additionally it would be trivial to make a subclass of this
template that changes the markup, adds new features or behaviors.  For example
you could have a subclass that added CSS markup from one of the popular CSS
frameworks.  Or you could add javascript to make the form AJAXy.  Example:

    package MyApp::Role::View::StyledInput;

    use Moo;

    around 'prepare_dom', sub {
      my ($orig, $self, $dom, @args) = @_;
      $dom->at('input')
        ->attr(class=>'large-input');
      return $self->$orig($dom, @args);
    };

You could that add this role to any input type component.  Basically the full power
of Perl is available!

Finally, lets look at the 'view-master' component, which is a type of layout component
to add common header / footer information to your page (a standard enough thing to do
when building a website:


    package  MyApp::View::Master;

    use Moo;

    has title => (is=>'ro', required=>1);
    has css => (is=>'ro', required=>1);
    has meta => (is=>'ro', required=>1);
    has body => (is=>'ro', required=>1);

    sub on_component_add {
    my ($self, $dom) = @_;
    $dom->title($self->title)
      ->head(sub { $_->append_content($self->css->join) })
      ->head(sub { $_->prepend_content($self->meta->join) })
      ->body(sub { $_->at('h1')->append($self->body) })
      ->at('#header')
        ->content($self->title);
    }

    sub template {
    my $class = shift;
    return q[
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          <meta content="width=device-width, initial-scale=1" name="viewport" />
          <title>Page Title</title>
          <link href="/static/base.css" rel="stylesheet" />
          <link href="/static/index.css" rel="stylesheet"/ >
        </head>
        <body id="body">
          <h1 id="header">Intro</h1>
        </body>
      </html>        
      ];
    }

    1;

This is a type of component intended to perform layout work for you.  In this case we are creating a common
header and footer and some internal market.  The values for it attributes come not from the model class
but from the contained DOM itself.  Lets look again at the top of the component declaration:

    <view-master title=\'title:content'
        css=\'@link'
        meta=\'@meta'
        body=\'body:content'>

So four attributes, all coming from the DOM associated with the 'content' area of this component.  We
grab the content of the title tag and the content of the HTML body tag, as well as the collection (if
any) of the link takes (for css style sheets) and any template specific meta tags.

If you are looking carefully you have noticed instead of a 'process_dom' method we have a 'on_component_add' method.  We could do this with 'process_dom' but that method runs for every request and since this overlay contains no dynamic request bound information its more efficient to run it once ('on_component_add' runs once at setup time; the change it makes becomes part of the base DOM which is cloned for every following request).  So 'on_component_add' is like 'prepare_dom' except it allows a component to modify the DOM of the view that is calling it instead of its own.

Here's a sample of the actual result, rendering all the components (you can peek at the repository which has all the code for these examples to see how it all works)

    <html>
      <head>
        <meta startup="Fri Mar 31 08:43:24 2017">
        <meta charset="utf-8">
        <meta content="width=device-width, initial-scale=1" name="viewport">
        <title>
          Things To Do
        </title>
        <link href="/static/base.css" rel="stylesheet" type="text/css">
        <link href="/css/input.min.css" rel="stylesheet" type="text/css">
        <script src="/js/input.min.js" type="text/javascript"></script>
      </head>
      <body id="body">
        <h1>
          Things To Do
        </h1>
        <form id="newtodo">
          <div class="field">
            <label for="item">Todo</label>
              <input id="item" name="item" type="text" value="milk">
          </div>
          <div class="ui error message">
            <ol class="errors">
              <li>too short
              </li>
              <li>too similar it existing item
              </li>
            </ol>
          </div>
         </form>
        <ol id="todos">
          <li>Buy Milk
          </li>
          <li>Walk Dog
          </li>
        </ol>
        <section id="footer">
          <hr>
          <p id="copy">
            copyright 2017
          </p>
        </section>
      </body>
    </html>

So even though we have a page with a lot happening, we can write a model class that focuses
just on the primary task (display the list of Todos) and let components handle the other work.
A complex template can be logically divided into clear chunks, each dedicated to one function
and each with a clearly defined, strongly typed interface.  I believe this leads to well
organized and concise templates that are maintainable over the long term.

You can review the documentation for each of the main classes in this distribution, and/or
review the test cases for more examples.  Or if you want to use this for building web sites
immediately, see L<Catalyst::View::Template::Lace> as you quickest path.

=head1 IMPORTANT NOTE REGARDING VALID HTML

Please note that L<Mojo::DOM58> tends to enforce rule regarding valid HTML5.  For example, you
cannot nest a block level element inside a 'P' element.  This might at times lead to some
surprising results in your output.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO

L<Template::Lace::Factory>, L<Template::Lace::Component>, L<Template::Lace::Renderer>,
L<Template::Lace::DOM>, L<Template::Lace::Model::AutoTemplate>,
and L<Template::Lace::Factory::InferInitArgsRole>

Other classes defined in this distribution
 
L<Mojo::DOM58>, L<HTML::Zoom>.  Both of these are approaches to programmatically examining and
altering a DOM.

L<Template::Semantic> is a similar system that uses XPATH instead of a CSS inspired matching
specification.  It has more dependencies (including L<XML::LibXML> and doesn't separate the actual
template data from the directives.  You might find this more simple approach appealing, 
so its worth alook.

L<HTML::Seamstress> Seems to also be prior art along these lines but I have trouble following
the code and it seems not active.  Might be worth looking at at least for ideas!

L<Template::Lace> A previous work of my along the same lines but based on pure.js 
L<http://beebole.com/pure/>.

L<PLift>, uses L<XML::LibXML>.

L<Catalyst::View::Template::Lace> Catalyst adaptor for this with some L<Catalyst> specific
enhancements.
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
