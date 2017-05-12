use 5.006;
use warnings;
use strict;

package Template::Declare;
use Template::Declare::Buffer;
use Class::ISA;
use String::BufferStack;

our $VERSION = '0.47';

use base 'Class::Data::Inheritable';
__PACKAGE__->mk_classdata('dispatch_to');
__PACKAGE__->mk_classdata('postprocessor');
__PACKAGE__->mk_classdata('strict');
__PACKAGE__->mk_classdata('templates');
__PACKAGE__->mk_classdata('private_templates');
__PACKAGE__->mk_classdata('buffer');
__PACKAGE__->mk_classdata('imported_into');
__PACKAGE__->mk_classdata('around_template');

__PACKAGE__->dispatch_to( [] );
__PACKAGE__->postprocessor( sub { return wantarray ? @_ : $_[0] } );
__PACKAGE__->templates(         {} );
__PACKAGE__->private_templates( {} );
__PACKAGE__->buffer( String::BufferStack->new );
__PACKAGE__->around_template( undef );

*String::BufferStack::data = sub {
    my $ref = shift;
    if (@_) {
        warn "Template::Declare->buffer->data called with argument; this usage is deprecated";
        ${$ref->buffer_ref} = join("", @_);
    }
    return $ref->buffer;
};

our $TEMPLATE_VARS;

=head1 NAME

Template::Declare - Perlish declarative templates

=head1 SYNOPSIS

Here's an example of basic HTML usage:

    package MyApp::Templates;
    use Template::Declare::Tags; # defaults to 'HTML'
    use base 'Template::Declare';

    template simple => sub {
        html {
            head {}
            body {
                p { 'Hello, world wide web!' }
            }
        }
    };

    package main;
    use Template::Declare;
    Template::Declare->init( dispatch_to => ['MyApp::Templates'] );
    print Template::Declare->show( 'simple' );

And here's the output:

 <html>
  <head></head>
  <body>
   <p>Hello, world wide web!
   </p>
  </body>
 </html>

=head1 DESCRIPTION

C<Template::Declare> is a pure-Perl declarative HTML/XUL/RDF/XML templating
system.

Yes. Another one. There are many others like it, but this one is ours.

A few key features and buzzwords:

=over

=item *

All templates are 100% pure Perl code

=item *

Simple declarative syntax

=item *

No angle brackets

=item *

"Native" XML namespace and declaration support

=item *

Mixins

=item *

Inheritance

=item *

Delegation

=item *

Public and private templates

=back

=head1 GLOSSARY

=over

=item template class

A subclass of Template::Declare in which one or more templates are defined
using the C<template> keyword, or that inherits templates from a super class.

=item template

Created with the C<template> keyword, a template is a subroutine that uses
C<tags> to generate output.

=item attribute

An XML element attribute. For example, in C<< <img src="foo.png" /> >>, C<src>
is an attribute of the C<img> element.

=item tag

A subroutine that generates XML element-style output. Tag subroutines execute
blocks that generate the output, and can call other tags to generate a
properly hierarchical structure.

=item tag set

A collection of related tags defined in a subclass of
L<Template::Declare::TagSet> for a particular purpose, and which can be
imported into a template class. For example,
L<Template::Declare::TagSet::HTML> defines tags for emitting HTML elements.

=item wrapper

A subroutine that wraps the output from a template. Useful for wrapping
template output in common headers and footers, for example.

=item dispatch class

A template class that has been passed to L<C<init()>|/init> via the
C<dispatch_to> parameter. When L<show|/"show TEMPLATE"> is called, only
templates defined in or mixed into the dispatch classes will be executed.

=item path

The name specified for a template when it is created by the C<template>
keyword, or when a template is mixed into a template class.

=item mixin

A template mixed into a template class via L</mix>. Mixed-in templates may be
mixed in under prefix paths to distinguish them from the templates defined in
the dispatch classes.

=item alias

A template aliased into a template class via L</alias>. Aliased templates may
be added under prefix paths to distinguish them from the templates defined in
the dispatch classes.

=item package variable

Variables defined when mixing templates into a template class. These variables
are available only to the mixed-in templates; they are not even accessible
from the template class in which the templates were defined.

=item helper

A subroutine used in templates to assist in the generation of output, or in
template classes to assist in the mixing-in of templates. Output helpers
include C<outs()> for rending text output and C<xml_decl()> for rendering XML
declarations. Mixin helpers include C<into> for specifying a template class to
mix into, and C<under> for specifying a path prefix under which to mix
templates.

=back

=head1 USAGE

Like other Perl templating systems, there are two parts to Template::Declare:
the templates and the code that loads and executes the templates. Unlike other
template systems, the templates are written in Perl classes. A simple HTML
example is in the L</SYNOPSIS>.

=head2 A slightly more advanced example

In this example, we'll show off how to set attributes on HTML tags, how to
call other templates, and how to declare a I<private> template that can't be
called directly. We'll also show passing arguments to templates. First, the
template class:

    package MyApp::Templates;
    use base 'Template::Declare';
    use Template::Declare::Tags;

    private template 'util/header' => sub {
        head {
            title { 'This is a webpage' };
            meta  {
                attr { generator => "This is not your father's frontpage" }
            }
        }
    };

    private template 'util/footer' => sub {
        my $self = shift;
        my $time = shift || gmtime;

        div {
            attr { id => "footer"};
            "Page last generated at $time."
        }
    };

    template simple => sub {
        my $self = shift;
        my $user = shift || 'world wide web';

        html {
            show('util/header');
            body {
                img { src is 'hello.jpg' }
                p {
                    attr { class => 'greeting'};
                    "Hello, $user!"
                };
            };
            show('util/footer', 'noon');
        }
    };

A few notes on this example:

=over

=item *

Since no parameter was passed to C<use Template::Declare::Tags>, the HTML tags
are imported by default.

=item *

The C<private> keyword indicates that a template is private. That means that
it can only be executed by other templates within the template class in which
it's declared. By default, C<< Template::Declare->show >> will not dispatch to
it.

=item *

The two private templates have longer paths than we've seen before:
C<util/header> and C<util/footer>. They must of course be called by their full
path names. You can put any characters you like into template names, but the
use of Unix filesystem-style paths is the most common (following on the
example of L<HTML::Mason|HTML::Mason>).

=item *

The first argument to a template is a class name. This can be useful for
calling methods defined in the class.

=item *

The C<show> sub executes another template. In this example, the C<simple>
template calls C<show('util/header')> and C<show('util/footer')> in order to
execute those private templates in the appropriate places.

=item *

Additional arguments to C<show> are passed on to the template being executed.
Here, C<show('util/footer', 'noon')> is passing "noon" to the C<util/footer>
template, with the result that the "last generated at" string will display
"noon" instead of the default C<gmtime>.

=item *

In the same way, note that the C<simple> template expects an additional
argument, a user name.

=item *

In addition to using C<attr> to declare attributes for an element, you can
use C<is>, as in

    img { src is 'hello.jpg' }

=back

Now for executing the template:

    package main;
    use Template::Declare;
    Template::Declare->init( dispatch_to => ['MyApp::Templates'] );
    print Template::Declare->show( '/simple', 'TD user');

We've told Template::Declare to dispatch to templates defined in our template
class. And note how an additional argument is passed to C<show()>; that
argument, "TD user", will be passed to the C<simple> template, where it will
be used in the C<$user> variable.

The output looks like this:

 <html>
  <head>
   <title>This is a webpage</title>
   <meta generator="This is not your father&#39;s frontpage" />
  </head>
  <body>
   <img src="hello.jpg" />
   <p class="greeting">Hello, TD user!</p>
  </body>
  <div id="footer">Page last generated at Thu Sep  3 20:56:14 2009.</div>
 </html>

Note that the single quote in C<father's> was quoted for you. We sanitize
your output for you to help prevent cross-site scripting attacks.

=head2 XUL

Template::Declare isn't limited to just HTML. Let's do XUL!

    package MyApp::Templates;
    use base 'Template::Declare';
    use Template::Declare::Tags 'XUL';

    template main => sub {
        xml_decl { 'xml', version => '1.0' };
        xml_decl {
            'xml-stylesheet',
            href => "chrome://global/skin/",
            type => "text/css"
        };
        groupbox {
            caption { attr { label => 'Colors' } }
            radiogroup {
                for my $id ( qw< orange violet yellow > ) {
                    radio {
                        attr {
                            id    => $id,
                            label => ucfirst($id),
                            $id eq 'violet' ? (selected => 'true') : ()
                        }
                    }
                } # for
            }
        }
    };

The first thing to do in a template class is to subclass Template::Declare
itself. This is required so that Template::Declare always knows that it's
dealing with templates. The second thing is to C<use Template::Declare::Tags>
to import the set of tag subroutines you need to generate the output you want.
In this case, we've imported tags to support the creation of XUL. Other tag
sets include HTML (the default), and RDF.

Templates are created using the C<template> keyword:

    template main => sub { ... };

The first argument is the name of the template, also known as its I<path>. In
this case, the template's path is C<main> (or C</main>, both are allowed (to
keep both PHP and L<HTML::Mason> fans happy). The second argument is an
anonymous subroutine that uses the tag subs (and any other necessary code) to
generate the output for the template.

The tag subs imported into your class take blocks as arguments, while a
number of helper subs take other arguments. For example, the C<xml_decl>
helper takes as its first argument the name of the XML declaration to be
output, and then a hash of the attributes of that declaration:

    xml_decl { 'xml', version => '1.0' };

Tag subs are used by simply passing a block to them that generates the output.
Said block may of course execute other tag subs in order to represent the
hierarchy required in your output. Here, the C<radiogroup> tag calls the
C<radio> tag for each of three different colors:

    radiogroup {
        for my $id ( qw< orange violet yellow > ) {
            radio {
                attr {
                    id    => $id,
                    label => ucfirst($id),
                    $id eq 'violet' ? (selected => 'true') : ()
                }
            }
        } # for
    }

Note the C<attr> sub. This helper function is used to add attributes to the
element created by the tag in which they appear. In the previous example, the
C<id>, C<label>, and C<selected> attributes are added to each C<radio>
output.

Once you've written your templates, you'll want to execute them. You do so by
telling Template::Declare what template classes to dispatch to and then asking
it to show you the output from a template:

    package main;
    Template::Declare->init( dispatch_to => ['MyApp::Templates'] );
    print Template::Declare->show( 'main' );

The path passed to C<show> can be either C<main> or </main>, as you prefer. In
either event, the output would look like this:

 <?xml version="1.0"?>
 <?xml-stylesheet href="chrome://global/skin/" type="text/css"?>

 <groupbox>
  <caption label="Colors" />
  <radiogroup>
   <radio id="orange" label="Orange" />
   <radio id="violet" label="Violet" selected="true" />
   <radio id="yellow" label="Yellow" />
  </radiogroup>
 </groupbox>

=head2 Postprocessing

Sometimes you just want simple syntax for inline elements. The following shows
how to use a postprocessor to emphasize text _like this_.

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template before => sub {
        h1 {
            outs "Welcome to ";
            em { "my" };
            outs " site. It's ";
            em { "great" };
            outs "!";
        };
    };

    template after => sub {
        h1  { "Welcome to _my_ site. It's _great_!" };
        h2  { outs_raw "This is _not_ emphasized." };
        img { src is '/foo/_bar_baz.png' };
    };

Here we've defined two templates in our template class, with the paths
C<before> and C<after>. The one new thing to note is the use of the C<outs>
and C<outs_raw> subs. C<outs> XML-encodes its argument and outputs it. You can
also just specify a string to be output within a tag call, but if you need to
mix tags and plain text within a tag call, as in the C<before> template here,
you'll need to use C<outs> to get things to output as you would expect.
C<outs_raw> is the same, except that it does no XML encoding.

Now let's have a look at how we use these templates with a post-processor:

    package main;
    use Template::Declare;
    Template::Declare->init(
        dispatch_to   => ['MyApp::Templates'],
        postprocessor => \&emphasize,
        strict        => 1,
    );

    print Template::Declare->show( 'before' );
    print Template::Declare->show( 'after'  );

    sub emphasize {
        my $text = shift;
        $text =~ s{_(.+?)_}{<em>$1</em>}g;
        return $text;
    }

As usual, we've told Template::Declare to dispatch to our template class. A
new parameter to C<init()> is C<postprocessor>, which is a code reference that
should expect the template output as an argument. It can then transform that
text however it sees fit before returning it for final output. In this
example, the C<emphasize> subroutine looks for text that's emphasized using
_underscores_ and turns them into C<< <em>emphasis</em> >> HTML elements.

We then execute both the C<before> and the C<after> templates with the output
ending up as:

 <h1>Welcome to
  <em>my</em> site. It&#39;s
  <em>great</em>!</h1>
 <h1>Welcome to <em>my</em> site. It&#39;s <em>great</em>!</h1>
 <h2>This is _not_ emphasized.</h2>
 <img src="/foo/_bar_baz.png" />

The thing to note here is that text passed to C<outs_raw> is not passed
through the postprocessor, and neither are attribute values (like the C<img>'s
C<src>).

=head2 Inheritance

Templates are really just methods. You can subclass your template packages to
override some of those methods:

    package MyApp::Templates::GenericItem;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template 'list' => sub {
        my ($self, @items) = @_;
        div {
            show('item', $_) for @items;
        }
    };
    template 'item' => sub {
        my ($self, $item) = @_;
        span { $item }
    };

    package MyApp::Templates::BlogPost;
    use Template::Declare::Tags;
    use base 'MyApp::Templates::GenericItem';

    template 'item' => sub {
        my ($self, $post) = @_;
        h1  { $post->title }
        div { $post->body }
    };

Here we have two template classes; the second, C<MyApp::Templates::BlogPost>,
inherits from the first, C<MyApp::Templates::GenericItem>. Note also that
C<MyApp::Templates::BlogPost> overrides the C<item> template. So execute these
templates:

    package main;
    use Template::Declare;

    Template::Declare->init( dispatch_to => ['MyApp::Templates::GenericItem'] );
    print Template::Declare->show( 'list', 'foo', 'bar', 'baz' );

    Template::Declare->init( dispatch_to => ['MyApp::Templates::BlogPost'] );
    my $post = My::Post->new(title => 'Hello', body => 'first post');
    print Template::Declare->show( 'item', $post );

First we execute the C<list> template in the base class, passing in some
items, and then we re-C<init()> Template::Declare and execute I<its> C<list>
template with an appropriate argument. Here's the output:

 <div>
  <span>foo</span>
  <span>bar</span>
  <span>baz</span>
 </div>

 <h1>Hello</h1>
 <div>first post</div>

So the override of the C<list> template in the subclass works as expected. For
another example, see L<Jifty::View::Declare::CRUD>.

=head2 Wrappers

There are two levels of wrappers in Template::Declare: template wrappers and
smart tag wrappers.

=head3 Template Wrappers

C<create_wrapper> declares a wrapper subroutine that can be called like a tag
sub, but can optionally take arguments to be passed to the wrapper sub. For
example, if you wanted to wrap all of the output of a template in the usual
HTML headers and footers, you can do something like this:

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    BEGIN {
        create_wrapper wrap => sub {
            my $code = shift;
            my %params = @_;
            html {
                head { title { outs "Hello, $params{user}!"} };
                body {
                    $code->();
                    div { outs 'This is the end, my friend' };
                };
            }
        };
    }

    template inner => sub {
        wrap {
            h1 { outs "Hello, Jesse, s'up?" };
        } user => 'Jesse';
    };

Note how the C<wrap> wrapper function is available for calling after it has
been declared in a C<BEGIN> block. Also note how you can pass arguments to the
function after the closing brace (you don't need a comma there!).

The output from the "inner" template will look something like this:

 <html>
  <head>
   <title>Hello, Jesse!</title>
  </head>
  <body>
   <h1>Hello, Jesse, s&#39;up?</h1>
   <div>This is the end, my friend</div>
  </body>
 </html>

=head3 Tag Wrappers

Tag wrappers are similar to template wrappers, but mainly function as syntax
sugar for creating subroutines that behave just like tags but are allowed to
contain arbitrary Perl code and to dispatch to other tags. To create one,
simply create a named subroutine with the prototype C<(&)> so that its
interface is the same as tags. Within it, use
L<C<smart_tag_wrapper>|Template::Declare::Tags/"smart_tag_wrapper"> to do the
actual execution, like so:

    package My::Template;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    sub myform (&) {
        my $code = shift;

        smart_tag_wrapper {
            my %params = @_; # set using 'with'
            form {
                attr { %{ $params{attr} } };
                $code->();
                input { attr { type => 'submit', value => $params{value} } };
            };
        };
    }

    template edit_prefs => sub {
        with(
            attr  => { id => 'edit_prefs', action => 'edit.html' },
            value => 'Save'
        ), myform {
            label { 'Time Zone' };
            input { type is 'text'; name is 'tz' };
        };
    };

Note in the C<edit_prefs> template that we've used
L<C<with>|Template::Declare::Tags/"with"> to set up parameters to be passed to
the smart wrapper. C<smart_tag_wrapper()> is the device that allows you to
receive those parameters, and also handles the magic of making sure that the
tags you execute within it are properly output. Here we've used C<myform>
similarly to C<form>, only C<myform> does something different with the
C<with()> arguments and outputs a submit element.

Executing this template:

    Template::Declare->init( dispatch_to => ['My::Template'] );
    print Template::Declare->show('edit_prefs');

Yields this output:

 <form action="edit.html" id="edit_prefs">
  <label>Time Zone</label>
  <input type="text" name="tz" />
  <input type="submit" value="Save" />
 </form>

=head2 Class Search Dispatching

The classes passed via the C<dispatch_to> parameter to C<init()> specify all
of the templates that can be executed by subsequent calls to C<show()>.
Template::Declare searches through these classes in order to find those
templates. Thus it can be useful, when you're creating your template classes
and determining which to use for particular class to C<show()>, to have
templates that override other templates. This is similar to how an operating
system will search all the paths in the C<$PATH> environment variable for a
program to run, and to L<HTML::Mason> component roots or L<Template::Toolkit>'s
C<INCLUDE_PATH> parameter.

For example, say you have this template class that defines a template that
you'll use for displaying images on your Web site.

    package MyApp::UI::Standard;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template image => sub {
        my ($self, $src, $title) = @_;
        img {
            src is $src;
            title is $title;
        };
    };

As usual, you can use it like so:

    my @template_classes = 'MyApp::UI::Standard';
    Template::Declare->init( dispatch_to => \@template_classes );
    print Template::Declare->show('image', 'foo.png', 'Foo');

We're explicitly using a reference to C<@template_classes> so that we can
manage this list ourselves.

The output of this will be:

 <div class="std">
  <img src="foo.png" title="Foo" />
  <p class="caption"></p>
 </div>

But say that in some sections of your site you need to have a more formal
treatment of your photos. Maybe you publish photos from a wire service and
need to provide an appropriate credit. You might write the template class like
so:

    package MyApp::UI::Formal;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template image => sub {
        my ($self, $src, $title, $credit, $caption) = @_;
        div {
            class is 'formal';
            img {
                src is $src;
                title is $title;
            };
            p {
                class is 'credit';
                outs "Photo by $credit";
            };
            p {
                class is 'caption';
                outs $caption;
            };
        };
    };


This, too, will work as expected, but the useful bit comes in when you're
mixing and matching template classes to pass to C<dispatch_to> before
rendering a page. Maybe you always pass C<MyApp::UI::Standard> to
C<dispatch_to> because it has all of your standard formatting templates.
But when the code realizes that a particular page needs the more formal
treatment, you can prepend the formal class to the list:

    unshift @template_classes, 'MyApp::UI::Formal';
    print Template::Declare->show(
        'image',
        'ap.png',
        'AP Photo',
        'Clark Kent',
        'Big news'
    );
    shift @template_classes;

In this way, the formal C<image> template will be found first, yielding
this output:

 <div class="formal">
  <img src="ap.png" title="AP Photo" />
  <p class="credit">Photo by Clark Kent</p>
  <p class="caption">Big news</p>
 </div>

At the end, we've shifted the formal template class off the C<dispatch_to>
list in order to restore the template classes to the default configuration,
ready for the next request.

=head2 Template Composition

There are two methods of template composition: mixins and delegation. Their
interfaces are very similar, the only difference being the template invocant.

=head3 Mixins

Let's start with a mixin.

    package MyApp::UtilTemplates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template content => sub {
        my $self  = shift;
        my @paras = @_;
        h1 { $self->get_title };
        div {
            id is 'content';
            p { $_ } for @paras;
        };
    };

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';
    mix MyApp::UtilTemplates under '/util';

    sub get_title { 'Kashmir' }

    template story => sub {
        my $self = shift;
        html {
          head {
              title { "My Site: " . $self->get_title };
          };
          body {
              show( 'util/content' => 'first paragraph', 'second paragraph' );
          };
        };
    };

The first template class, C<MyApp::UtilTemplates>, defines a utility template,
called C<content>, for outputting the contents of page. Note its call to
C<< $self->get_title >> even though it doesn't have a C<get_title> method. This
is part of the mixin's "contract": it requires that the class it's mixed into
have a C<get_title()> method.

The second template class, C<MyApp::Templates>, mixes C<MyApp::UtilTemplates>
into itself under the path C</util> and defines a C<get_title()> method as
required by the mixin. Then, its C<story> template calls the mixed-in template
as C<util/content>, because the C<content> template was mixed into the current
template under C</util>. Get it?

Now we can use the usual template invocation:

    package main;
    Template::Declare->init( dispatch_to => ['MyApp::Templates'] );
    print Template::Declare->show('story');

To appreciate our output:

 <html>
  <head>
   <title>My Site: Kashmir</title>
  </head>
  <body>
   <h1>Kashmir</h1>
   <div id="content">
    <p>fist paragraph</p>
    <p>second paragraph</p>
   </div>
  </body>
 </html>

Mixins are a very useful tool for template authors to add reusable
functionality to their template classes. But it's important to pay attention to
the mixin contracts so that you're sure to implement the required API in your
template class (here, the C<get_title()> method).

=head3 Aliases

Aliases are very similar to mixins, but implement delegation as a composition
pattern, rather than mixins. The upshot is that there is no contract provided
by an aliased class: it just works. This is because the invocant is the class
from which the aliases are imported, and therefore it will dispatch to methods
defined in the aliased class.

For example, say that you wanted to output a sidebar on pages that need one
(perhaps your CMS has sidebar things). We can define a template class that
has a template for that:

    package MyApp::UI::Stuff;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    sub img_path { '/ui/css' }

    template sidebar => sub {
        my ($self, $thing) = @_;
        div {
            class is 'sidebar';
            img { src is $self->img_path . '/sidebar.png' };
            p { $_->content } for $thing->get_things;
        };
    };

Note the use of the C<img_path()> method defined in the template class and
used by the C<sidebar> template. Now let's use it:

    package MyApp::Render;
    use Template::Declare::Tags;
    use base 'Template::Declare';
    alias MyApp::UI::Stuff under '/stuff';

    template page => sub {
        my ($self, $page) = @_;
        h1 { $page->title };
        for my $thing ($page->get_things) {
            if ($thing->is('paragraph')) {
                p { $thing->content };
            } elsif ($thing->is('sidebar')) {
                show( '/stuff/sidebar' => $thing );
            }
        }
    };

Here our rendering template class has aliased C<MyApp::UI::Stuff> under
C</stuff>. So the C<page> template calls C<show('/stuff/sidebar')> to invoke
the sidebar template. If we run this:

    Template::Declare->init( dispatch_to => ['MyApp::Render'] );
    print Template::Declare->show( page => $page );

We get output as you might expect:

 <h1>My page title</h1>
 <p>Page paragraph</p>
 <div class="sidebar">
  <img src="/ui/css/sidebar.png" />
  <p>Sidebar paragraph</p>
  <p>Another paragraph</p>
 </div>

Now, let's say that you have political stuff that you want to use a different
image for in the sidebar. If that's the only difference, we can subclass
C<MyApp::UI::Stuff> and just override the C<img_path()> method:

    package MyApp::UI::Stuff::Politics;
    use Template::Declare::Tags;
    use base 'MyApp::UI::Stuff';

    sub img_path { '/politics/ui/css' }

Now let's mix that into a politics template class:

    package MyApp::Render::Politics;
    use Template::Declare::Tags;
    use base 'Template::Declare';
    alias MyApp::UI::Stuff::Politics under '/politics';

    template page => sub {
        my ($self, $page) = @_;
        h1 { $page->title };
        for my $thing ($page->get_things) {
            if ($thing->is('paragraph')) {
                p { $thing->content };
            } elsif ($thing->is('sidebar')) {
                show( '/politics/sidebar' => $thing );
            }
        }
    };

The only difference between this template class and C<MyApp::Render> is that
it aliases C<MyApp::UI::Stuff::Politics> under C</politics>, and then calls
C<show('/politics/sidebar')> in the C<page> template. Running this template:

    Template::Declare->init( dispatch_to => ['MyApp::Render::Politics'] );
    print Template::Declare->show( page => $page );

Yields output using the value of the subclass's C<img_path()> method -- that
is, the sidebar image is now F</politics/ui/css/sidebar.png> instead of
F</ui/css/sidebar.png>:

 <h1>My page title</h1>
 <p>Page paragraph</p>
 <div class="sidebar">
  <img src="/politics/ui/css/sidebar.png" />
  <p>Sidebar paragraph</p>
  <p>Another paragraph</p>
 </div>

=head3 Other Tricks

The delegation behavior of C<alias> actually makes it a decent choice for
template authors to mix and match libraries of template classes as
appropriate, without worrying about side effects. You can even alias templates
in one template class into another template class if you're not the author of
that class by using the C<into> keyword:

    alias My::UI::Widgets into Your::UI::View under '/widgets';

Now the templates defined in C<Your::UI::View> are available in
C<My::UI::Widgets> under C</widgets>. The C<mix> method supports this syntax
as well, though it's not necessarily recommended, given that you would not be
able to fulfill any contracts unless you re-opened the class into which you
mixed the templates. But in any case, authors of framework view classes might
find this functionality useful for automatically aliasing template classes
into a single dispatch template class.

Another trick is to alias or mix your templates with package variables
specific to the composition. Do so via the C<setting> keyword:

    package My::Templates;
    mix Some::Mixin under '/mymix', setting { name => 'Larry' };

The templates mixed from C<Some::Mixin> into C<My::Templates> have package
variables set for them that are accessible I<only> from their mixed-in paths.
For example, if you define this template in C<Some::Mixin>:

    template howdy => sub {
        my $self = shift;
        outs "Howdy, " . $self->package_variable('name') || 'Jesse';
    };

Then C<show('mymix/howdy')> called on C<My::Templates> will output "Howdy,
Larry", while the output from C<show('howdy')> will output "Howdy, Jesse". In
other words, package variables defined for the mixed-in templates are
available only to the mixins and not to the original. The same functionality
exists for C<alias> as well.

=begin comment

=head2 Tag Sets

Wherein we will eventually provide a brief tutorial on creating custom tag sets.

=end comment

=head2 Indentation configuration

By default, Template::Declare renders a readable XML adding end of lines and a
one column indentation. This behavior could break a webpage design or add a
significant amount of chars to your XML output. This could be changed by
overwriting the default values. So,

    $Template::Declare::Tags::TAG_INDENTATION  = 0;
    $Template::Declare::Tags::EOL              = "";
    say Template::Declare->show('main');

will render

    <html><body><p>hi</p></body></html>


=head1 METHODS

=head2 init

This I<class method> initializes the C<Template::Declare> system.

=over

=item dispatch_to

An array reference of classes to search for templates. Template::Declare will
search this list of classes in order to find a template path.

=item roots

B<Deprecated.> Just like C<dispatch_to>, only the classes are searched in
reverse order. Maintained for backward compatibility and for the pleasure of
those who want to continue using Template::Declare the way that Jesse's
"crack-addled brain" intended.

=item postprocessor

A coderef called to postprocess the HTML or XML output of your templates. This
is to alleviate using Tags for simple text markup.

=item around_template

A coderef called B<instead> of rendering each template. The coderef will
receive four arguments: a coderef to invoke to render the template, the
template's path, an arrayref of the arguments to the template, and the coderef
of the template itself. You can use this for instrumentation. For example:

    Template::Declare->init(around_template => sub {
        my ($orig, $path, $args, $code) = @_;
        my $start = time;
        $orig->();
        warn "Rendering $path took " . (time - $start) . " seconds.";
    });

=item strict

Die in exceptional situations, such as when a template can't be found, rather
than just warn. False by default for backward compatibility. The default may
be changed in the future, so specifying the value explicitly is recommended.

=back

=cut

sub init {
    my $class = shift;
    my %args  = (@_);

    if ( $args{dispatch_to} ) {
        $class->dispatch_to( $args{dispatch_to} );
    } elsif ( $args{roots} ) {
        $class->roots( $args{roots} );
    }

    $class->strict( $args{strict} ) if exists $args{strict};
    $class->postprocessor( $args{postprocessor} ) if $args{postprocessor};
    $class->around_template( $args{around_template} ) if $args{around_template};
}

=head2 show TEMPLATE_NAME

    Template::Declare->show( 'howdy', name => 'Larry' );
    my $output = Template::Declare->show('index');

Call C<show> with a C<template_name> and C<Template::Declare> will render that
template. Subsequent arguments will be passed to the template. Content
generated by C<show()> can be accessed via the C<output()> method if the
output method you've chosen returns content instead of outputting it directly.

If called in scalar context, this method will also just return the content
when available.

=cut

sub show {
    my $class    = shift;
    my $template = shift;
    local %Template::Declare::Tags::ELEMENT_ID_CACHE = ();
    return Template::Declare::Tags::show_page($template => @_);
}

=head2 Template Composition

Sometimes you want to mix templates from one class into another class, or
delegate template execution to a class of templates. C<alias()> and C<mix()>
are your keys to doing so.

=head3 mix

    mix Some::Clever::Mixin      under '/mixin';
    mix Some::Other::Mixin       under '/otmix', setting { name => 'Larry' };
    mix My::Mixin into My::View, under '/mymix';

Mixes templates from one template class into another class. When the mixed-in
template is called, its invocant will be the class into which it was mixed.
This type of composition is known as a "mixin" in object-oriented parlance.
See L<Template Composition|/"Template Composition"> for extended examples and
a comparison to C<alias>.

The first parameter is the name of the template class to be mixed in. The
C<under> keyword tells C<mix> where to put the templates. For example,
a C<foo> template in C<Some::Clever::Mixin> will be mixed in as C<mixin/foo>.

The C<setting> keyword specifies package variables available only to the
mixed-in copies of templates. These are available to the templates as
C<< $self->package_variable($varname) >>.

The C<into> keyword tells C<mix> into what class to mix the templates. Without
this keyword, C<mix> will mix them into the calling class.

For those who prefer a direct OO syntax for mixins, just call C<mix()> as a
method on the class to be mixed in. To replicate the above three examples
without the use of the sugar:

    Some::Clever::Mixin->mix( '/mixin' );
    Some::Other::Mixin->mix( '/otmix', { name => 'Larry' } );
    My::Mixin->mix( 'My::View', '/mymix' );

=cut

sub mix {
    my $mixin = shift;
    my ($into, @args) = _into(@_);
    $mixin->_import($into, $into, @args);
}

=head3 alias

    alias Some::Clever:Templates   under '/delegate';
    alias Some::Other::Templates   under '/send_to', { name => 'Larry' };
    alias UI::Stuff into My::View, under '/mystuff';

Aliases templates from one template class into another class. When an alias
called, its invocant will be the class from which it was aliased. This type of
composition is known as "delegation" in object-oriented parlance. See
L<Template Composition|/"Template Composition"> for extended examples and a
comparison to C<mix>.

The first parameter is the name of the template class to alias. The C<under>
keyword tells C<alias> where to put the templates. For example, a C<foo>
template in C<Some::Clever::Templates> will be aliased as C<delegate/foo>.

The C<setting> keyword specifies package variables available only to the
aliases. These are available to the templates as
C<< $self->package_variable($varname) >>.

The C<into> keyword tells C<alias> into what class to alias the templates.
Without this keyword, C<alias> will alias them into the calling class.

For those who prefer a direct OO syntax for mixins, just call C<alias()> as a
method on the class to be mixed in. To replicate the above three examples
without the use of the sugar:

    Some::Clever:Templates->alias( '/delegate' );
    Some::Other::Templates->alias( '/send_to', { name => 'Larry' } );
    UI::Stuff->alias( 'My::View', '/mystuff' );

=cut

sub alias {
    my $mixin = shift;
    my ($into, @args) = _into(@_);
    $mixin->_import($into, undef, @args);
}

=head3 package_variable( VARIABLE )

  $td->package_variable( $varname => $value );
  $value = $td->package_variable( $varname );

Returns a value set for a mixed-in template's variable, if any were specified
when the template was mixed-in. See L</mix> for details.

=cut

sub package_variable {
    my $self = shift;
    my $var  = shift;
    if (@_) {
        $TEMPLATE_VARS->{$self}->{$var} = shift;
    }
    return $TEMPLATE_VARS->{$self}->{$var};
}

=head3 package_variables( VARIABLE )

    $td->package_variables( $variables );
    $variables = $td->package_variables;

Get or set a hash reference of variables for a mixed-in template. See
L</mix> for details.

=cut

sub package_variables {
    my $self = shift;
    if (@_) {
        %{ $TEMPLATE_VARS->{$self} } = shift;
    }
    return $TEMPLATE_VARS->{$self};
}

=head2 Templates registration and lookup

=head3 resolve_template TEMPLATE_PATH INCLUDE_PRIVATE_TEMPLATES

    my $code = Template::Declare->resolve_template($template);
    my $code = Template::Declare->has_template($template, 1);

Turns a template path (C<TEMPLATE_PATH>) into a C<CODEREF>.  If the
boolean C<INCLUDE_PRIVATE_TEMPLATES> is true, resolves private templates
in addition to public ones. C<has_template()> is an alias for this method.

First it looks through all the valid Template::Declare classes defined via
C<dispatch_to>. For each class, it looks to see if it has a template called
$template_name directly (or via a mixin).

=cut

sub resolve_template {
    my $self          = shift;
    my $template_name = shift;
    my $show_private  = shift || 0;

    my @search_packages;

    # If we're being called as a class method on T::D it means "search in any package"
    # Otherwise, it means search only in this specific package"
    if ( $self eq __PACKAGE__ ) {
        @search_packages = @{ Template::Declare->dispatch_to };
    } else {
        @search_packages = ($self);
    }

    foreach my $package (@search_packages) {
        next unless ( $package and $package->isa(__PACKAGE__) );
        if ( my $coderef = $package->_has_template( $template_name, $show_private ) ) {
            return $coderef;
        }
    }
}

=head3 has_template TEMPLATE_PATH INCLUDE_PRIVATE_TEMPLATES

An alias for C<resolve_template>.

=cut

sub has_template { resolve_template(@_) }

=head3 register_template( TEMPLATE_NAME, CODEREF )

    MyApp::Templates->register_template( howdy => sub { ... } );

This method registers a template called C<TEMPLATE_NAME> in the calling class.
As you might guess, C<CODEREF> defines the template's implementation. This
method is mainly intended to be used internally, as you use the C<template>
keyword to create templates, right?

=cut

sub register_template {
    my $class         = shift;
    my $template_name = shift;
    my $code          = shift;
    push @{ __PACKAGE__->templates()->{$class} }, $template_name;
    _register_template( $class, _template_name_to_sub($template_name), $code )
}

=head3 register_private_template( TEMPLATE_NAME, CODEREF )

    MyApp::Templates->register_private_template( howdy => sub { ... } );

This method registers a private template called C<TEMPLATE_NAME> in the
calling class. As you might guess, C<CODEREF> defines the template's
implementation.

Private templates can't be called directly from user code but only from other
templates.

This method is mainly intended to be used internally, as you use the
C<private template> expression to create templates, right?

=cut

sub register_private_template {
    my $class         = shift;
    my $template_name = shift;
    my $code          = shift;
    push @{ __PACKAGE__->private_templates()->{$class} }, $template_name;
    _register_template( $class, _template_name_to_private_sub($template_name), $code );

}

=head3 buffer

Gets or sets the L<String::BufferStack> object; this is a class method.

You can use it to manipulate the output from tags as they are output. It's used
internally to make the tags nest correctly, and be output to the right place.
We're not sure if there's ever a need for you to frob it by hand, but it does
enable things like the following:

    template simple => sub {
       html {
           head {}
           body {
               Template::Declare->buffer->set_filter( sub {uc shift} );
               p { 'Whee!' }
               p { 'Hello, world wide web!' }
               Template::Declare->buffer->clear_top if rand() < 0.5;
           }
       }
    };

...which outputs, with equal regularity, either:

 <html>
  <head></head>
  <body>
   <P>WHEE!</P>
   <P>HELLO, WORLD WIDE WEB!</P>
  </body>
 </html>

...or:

 <html>
  <head></head>
  <body></body>
 </html>

We'll leave it to you to judge whether or not that's actually useful.

=head2 Helpers

You don't need to call any of this directly.

=head3 into

    $class = into $class;

C<into> is a helper method providing semantic sugar for the L</mix> method.
All it does is return the name of the class on which it was called.

=cut

sub into { shift }

=head2 Old, deprecated or just better to avoid

=head3 import_templates

    import_templates MyApp::Templates under '/something';

Like C<mix()>, but without support for the C<into> or C<setting> keywords.
That is, it mixes templates into the calling template class and does not
support package variables for those mixins.

B<Deprecated> in favor of L</mix>. Will be supported for a long time, but
new code should use C<mix()>.

=cut

sub import_templates {
    my $caller = scalar caller(0);
    shift->_import($caller, $caller, @_);
}

=head3 new_buffer_frame

    $td->new_buffer_frame;
    # same as 
    $td->buffer->push( private => 1 );

Creates a new buffer frame, using L<String::BufferStack/push> with C<private>.

B<Deprecated> in favor of dealing with L</buffer> directly.

=cut

sub new_buffer_frame {
    __PACKAGE__->buffer->push( private => 1 );
}

=head3 end_buffer_frame

    my $buf = $td->end_buffer_frame;
    # same as
    my $buf = $td->buffer->pop;

Deletes and returns the topmost buffer, using L<String::BufferStack/pop>.

B<Deprecated> in favor of dealing with L</buffer> directly.

=cut

sub end_buffer_frame {
    __PACKAGE__->buffer->pop;
}

=head3 path_for $template

    my $path = Template::Declare->path_for('index');

Returns the path for the template name to be used for show, adjusted with
paths used in C<mix>. Note that this will only work for the last class into
which you imported the template. This method is, therefore, deprecated.

=cut

# Deprecated in favor of dispatch_to().
sub roots {
    # warn "roots() has been deprecated; use dispatch_to() instead\n";
    my $class = shift;
    $class->dispatch_to( [ reverse @{ +shift } ] ) if @_;
    return [ reverse @{ $class->dispatch_to } ];
}

# Removed methods that no longer work (and were never documented anyway).
# Remove these no-ops after a few releases (added for 0.41).

=begin comment

=head3 aliases

=head3 alias_metadata

=end comment

=cut

sub aliases {
    require Carp;
    Carp::cluck( 'aliases() is a deprecated no-op' );
}

sub alias_metadata {
    require Carp;
    Carp::cluck( 'alias_metadata() is a deprecated no-op' );
}

sub path_for {
    my $class = shift;
    my $template = shift;
    return ($class->imported_into ||'') . '/' . $template;
}

sub _templates_for {
    my $tmpl = shift->templates->{+shift} or return;
    return wantarray ? @{ $tmpl } : $tmpl;
}

sub _private_templates_for {
    my $tmpl = shift->private_templates->{+shift} or return;
    return wantarray ? @{ $tmpl } : $tmpl;
}

sub _has_template {
    # Otherwise find only in specific package
    my $pkg           = shift;
    my $template_name = shift;
    my $show_private  = 0 || shift;

    if ( my $coderef = $pkg->_find_template_sub( _template_name_to_sub($template_name) ) ) {
        return $coderef;
    } elsif ( $show_private and $coderef = $pkg->_find_template_sub( _template_name_to_private_sub($template_name))) {
        return $coderef;
    }

    return undef;
}

sub _dispatch_template {
    my $class = shift;
    my $code  = shift;
    unshift @_, $class;
    goto $code;
}

sub _find_template_sub {
    my $self    = shift;
    my $subname = shift;
    return $self->can($subname);
}

sub _template_name_to_sub {
    return _subname( "_jifty_template_", shift );
}

sub _template_name_to_private_sub {
    return _subname( "_jifty_private_template_", shift );
}

sub _subname {
    my $prefix = shift;
    my $template = shift || '';
    $template =~ s{/+}{/}g;
    $template =~ s{^/}{};
    return join( '', $prefix, $template );
}

sub _register_template {
    my $self    = shift;
    my $class   = ref($self) || $self;
    my $subname = shift;
    my $coderef = shift;
    no strict 'refs';
    no warnings 'redefine';
    *{ $class . '::' . $subname } = $coderef;
}

sub _into {
    my ($into, $under);
    if ( eval { $_[0]->isa(__PACKAGE__) } ) {
        ($into, $under) = (shift, shift);
    } elsif ( eval { $_[1]->isa(__PACKAGE__) } ) {
        ($under, $into) = (shift, shift);
    } else {
        $into  = caller(1);
        $under = shift;
    }
    return $into, $under, @_;
}

sub _import {
    return undef if $_[0] eq __PACKAGE__;
    my ($mixin, $into, $invocant, $prefix, $vars) = @_;


    $prefix =~ s|/+/|/|g;
    $prefix =~ s|/$||;
    $mixin->imported_into($prefix);

    my @packages = reverse grep { $_->isa(__PACKAGE__) }
        Class::ISA::self_and_super_path( $mixin );

    foreach my $from (@packages) {
        for my $tname (  __PACKAGE__->_templates_for($from) ) {
            my $sname = _template_name_to_sub($tname);
            $into->register_template(
                "$prefix/$tname",
                _import_code( $sname, $from, $invocant || $mixin, $vars )
            );
        }
        for my $tname (  __PACKAGE__->_private_templates_for($from) ) {
            my $sname = _template_name_to_private_sub($tname);
            $into->register_private_template(
                "$prefix/$tname",
                _import_code( $sname, $from, $invocant || $mixin, $vars )
            );
        }
    }
}

sub _import_code {
    my ($sname, $from, $mixin, $vars) = @_;
    my $code = $from->_find_template_sub( $sname );
    return $mixin eq $from ? $code : sub { shift; $code->($mixin, @_) }
        unless $vars;
    return sub {
        shift @_;  # Get rid of the passed-in "$self" class.
        local $TEMPLATE_VARS->{$mixin} = $vars;
        $code->($mixin, @_);
    };
}

=head1 PITFALLS

We're reusing the perl interpreter for our templating language, but Perl was
not designed specifically for our purpose here. Here are some known pitfalls
while you're scripting your templates with this module.

=over

=item *

It's quite common to see tag sub calling statements without trailing
semi-colons right after C<}>. For instance,

    template foo => sub {
        p {
            a { attr { src => '1.png' } }
            a { attr { src => '2.png' } }
            a { attr { src => '3.png' } }
        }
    };

is equivalent to

    template foo => sub {
        p {
            a { attr { src => '1.png' } };
            a { attr { src => '2.png' } };
            a { attr { src => '3.png' } };
        };
    };

But C<xml_decl> is a notable exception. Please always put a trailing semicolon
after C<xml_decl { ... }>, or you'll mess up the order of output.

=item *

Another place that requires trailing semicolon is the statements before a Perl
looping statement, an C<if> statement, or a C<show> call. For example:

    p { "My links:" };
    for (@links) {
        with ( src => $_ ), a {}
    }

The C<;> after C< p { ... } > is required here, or Perl will complain about
syntax errors.

Another example is

    h1 { 'heading' };  # this trailing semicolon is mandatory
    show 'tag_tag'

=item *

The C<is> syntax for declaring tag attributes also requires a trailing
semicolon, unless it is the only statement in a block. For example,

    p { class is 'item'; id is 'item1'; outs "This is an item" }
    img { src is 'cat.gif' }

=item *

Literal strings that have tag siblings won't be captured. So the following template

    p { 'hello'; em { 'world' } }

produces

 <p>
  <em>world</em>
 </p>

instead of the desired output

 <p>
  hello
  <em>world</em>
 </p>

You can use C<outs> here to solve this problem:

    p { outs 'hello'; em { 'world' } }

Note you can always get rid of C<outs> if the string literal is the only
element of the containing block:

    p { 'hello, world!' }

=item *

Look out! If the if block is the last block/statement and the condition part
is evaluated to be 0:

    p { if ( 0 ) { } }

produces

 <p>0</p>

instead of the more intuitive output:

 <p></p>

This is because C<if ( 0 )> is the last expression, so C<0> is returned as the
value of the whole block, which is used as the content of <p> tag.

To get rid of this, just put an empty string at the end so it returns empty
string as the content instead of 0:

    p { if ( 0 ) { } '' }

=back

=head1 BUGS

Crawling all over, baby. Be very, very careful. This code is so cutting edge,
it can only be fashioned from carbon nanotubes. But we're already using this
thing in production :) Make sure you have read the L</PITFALLS>
section above :)

Some specific bugs and design flaws that we'd love to see fixed.

=over

=item Output isn't streamy.

=back

If you run into bugs or misfeatures, please report them to
C<bug-template-declare@rt.cpan.org>.

=head1 SEE ALSO

=over

=item L<Template::Declare::Tags>

=item L<Template::Declare::TagSet>

=item L<Template::Declare::TagSet::HTML>

=item L<Template::Declare::TagSet::XUL>

=item L<Jifty>

=back

=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>

=head1 LICENSE

Template::Declare is Copyright 2006-2010 Best Practical Solutions, LLC.

Template::Declare is distributed under the same terms as Perl itself.

=cut

1;
