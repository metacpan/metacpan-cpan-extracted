[![Actions Status](https://github.com/dstroma/PlackX-Framework/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/dstroma/PlackX-Framework/actions?workflow=test)
# NAME

PlackX::Framework - A thin framework for PSGI/Plack web apps.

# SYNOPSIS

This is a small framework for PSGI web apps, based on Plack. A simple
PlackX::Framework application could be all in one .psgi file:

    # app.psgi
    package MyProject {
      use PlackX::Framework; # loads and sets up the framework and subclasses
      use MyProject::Router; # exports router DSL
      route '/' => sub ($request, $response) {
         $response->body('Hello, ', $request->param('name'));
         return $response;
      };
    }
    MyProject->app;

A larger application would be typically laid out with separate modules in
separate files, for example in MyProject::Controller::\* modules. Each should
use MyProject::Router if the DSL-style routing is desired.

This software is considered to be in an experimental, "alpha" stage.

# DESCRIPTION

## Overview and Required Components

PlackX::Framework consists of the required modules:

- PlackX::Framework
- PlackX::Framework::Handler
- PlackX::Framework::Request
- PlackX::Framework::Response
- PlackX::Framework::Router
- PlackX::Framework::Router::Engine

And the following optional modules:

- PlackX::Framework::Config
- PlackX::Framework::Template
- PlackX::Framework::URIx

The statement "use PlackX::Framework" will automatically find and load all of
the required modules. Then it will look for subclasses of the modules listed 
above that exist in your namespace and load them, or create empty subclasses
for any required modules that do not exist. The following example

    package MyProject {
        use PlackX::Framework;
        # ...app logic here...
    }

will attempt to load MyProject::Handler, MyProject::Request,
MyProject::Response and so on, or create them (in memory, not on disk) if
they do not exist.

You only use, not inherit from, PlackX::Framework. However, your
::Handler, ::Request, ::Response, etc. classes should inherit from
PlackX::Framework::Handler, ::Request, ::Response, and so on.

## Optional Components

The Config, Template, URIx modules are included in the distribution, but
loading them is optional to save memory and compilation time when not needed.
Just as with the required modules, you can subclass them yourself, or you can
have them automatically generated.

To set up all optional modules, import with the :all (or +all) tag.

    # The following are equivalent
    use PlackX::Framework qw(:all);
    use PlackX::Framework qw(+all);

Note that 'use Module -option' syntax is not supported, because it can be
misread by humans as "minus option" which might give the false impression that
the option is being turned off.

If you want to pick certain optional modules, you can specify those
individually with the name of the module, optionally preceded by a single
double colon (: or ::) or a plus sign. You may also use lower case.

    # All of the below are equivalent
    use PlackX::Framework qw(Config Template);
    use PlackX::Framework qw(:Config :Template);
    use PlackX::Framework qw(:config :template);
    use PlackX::Framework qw(::Config ::Template);
    use PlackX::Framework qw(+Config +Template);

Third party developers can make additional optional components available, by
pushing to the @PlackX::Framework::plugins array. These can then be loaded by
an application same way as the bundled optional modules.

## The Pieces and How They Work Together

### PlackX::Framework

PlackX::Framework is basically a management module that is responsible for
loading required and optional components. It will automatically subclass
required, and desired optional classes for you if you have not done so already.
It exports one symbol, app(), to the calling package; it also exports an
app\_namespace() sub to your app's subclasses, which returns the name of the
root class.

    # Example app
    package MyApp {
      # The following statement will load, or automatically create,
      # MyApp::Handler, MyApp::Request, MyApp::Response, MyApp::Router, etc.
      # It will create a MyApp::app() function, and an app_namespace() function
      # in each respective subclassed module if one does not already exist.
      use PlackX::Framework qw(:all);
    }

### PlackX::Framework::Handler

PlackX::Framework::Handler is the package responsible for request processing.
You would not normally have to subclass this module manually unless you would
like to customize its behavior. It will prepare request and response objects,
a stash, and if set up, templating.

### PlackX::Framework::Request and ::Response

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features, including various convenience methods, request re-routing (not to be
confused with HTTP redirects), cleanup handlers, and easier PSGI response
streaming.

For more information, see the documentation for [PlackX::Framework::Request](https://metacpan.org/pod/PlackX%3A%3AFramework%3A%3ARequest)
and [PlackX::Framework::Response](https://metacpan.org/pod/PlackX%3A%3AFramework%3A%3AResponse).

Both share common stash and flash properties, described below.

- stash()

    Request and Response objects share a "stash" which is a hashref in which you
    can store any data you would like. This not a user session but a way to
    temporarily store information during a single request/response cycle. It is
    re-initialized to an empty hashref at the start of each cycle.

- flash()

    They also feature a "flash" cookie which you can use to store information on
    the user end for one cycle. It is automatically cleared in the following
    cycle. For example...

        $response->flash('Goodbye!'); # Store message in a cookie

    On the next request:

        $request->flash; # Returns 'Goodbye!'.

    During the response phase, the flash cookie is cleared, unless you set another
    one.

### PlackX::Framework::Router

This module exports the route, base, global\_filter, and filter functions
to give you a minimalistic web app controller DSL. You can import this into
your main app package, as shown in the introduction, or separate packages.
If you manually subclass this module, you can also customize the keywords.

    # Set up the app
    package MyApp {
      use PlackX::Framework;
    }

    # Note: The name of your controller module doesn't matter, but it must
    # import from your router subclass, e.g., MyApp::Router, not directly from
    # PlackX::Framework::Router!
    package MyApp::Controller {
      use MyApp::Router;

      base '/app';

      global_filter before => sub {
        # I will be executed for ANY route ANYWHERE in MyApp!
        ...
      };

      filter before => sub {
        # I will only be executed for the routes listed below in this package.
        ...
      };

      route '/home' => sub {
        ...
      };

      route { post => '/login' } => sub {
        ...
      };
    }

Every route action is called with two arguments: a request object and response
object. The response object is provided for convenience as the application may
return it or a different response object, (or even another request object as
described in the re-routing feature of PlackX::Framework::Request).

Filters are also called the same way, but they should only return a response
object if they wish to stop request processing. If a filter returns a false
value ($response->next is provided for semantic convenience), request processing
continues to the next matching filter or route.

Note that unlike some other frameworks, routes CANNOT cascade, but filters can.

For more information, see [PlackX::Framework::Router](https://metacpan.org/pod/PlackX%3A%3AFramework%3A%3ARouter).

### PlackX::Framework::Router::Engine

The PlackX::Framework::Router::Engine is a subclass of Router::Boom with some
extra convenience methods. Normally, you would not have to use this module
directly. It is used by PlackX::Framework::Router internally.

### PlackX::Framework::Config

This module is provided primarily for convenience. Currently not used by PXF
directly except you may optionally store template system configuration there.

For more information, see [PlackX::Framework::Config](https://metacpan.org/pod/PlackX%3A%3AFramework%3A%3AConfig).

### PlackX::Framework::Template

The PlackX::Framework::Template module can automatically load and set up
Template Toolkit, offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::Handler.

During request handling, PlackX::Framework will check if templating has been
set up by checking if a ::Template module in your application's namespace has
been loaded. If so, it will automatically create an instance of the respective
::Template class and automatically add the template variables STASH, REQUEST,
and RESPONSE to the object.

For more information, see [PlackX::Framework::Template](https://metacpan.org/pod/PlackX%3A%3AFramework%3A%3ATemplate).

### PlackX::Framework::URIx

The PlackX::Framework::URIx is a URI processing module with extended features,
and it is a subclass of URI::Fast. It is made available to your
your request objects through $request->urix (the x is to not confuse it
with the Plack::Request->uri() method). If you have not enabled the URIx
feature in your application, with the :URIx or :all tag, the request->urix
method will cause an error.

For more information, see [PlackX::Framework::URIx](https://metacpan.org/pod/PlackX%3A%3AFramework%3A%3AURIx).

## Middleware

You can trigger PlackX::Framework to build middleware into your app by defining
an apply\_middleware sub in your root application. The sub will be passed a PSGI
code reference and should return a PSGI code reference. (This sub will be called
as a plain sub, not as a class or object method).

    package MyApp {
      use PlackX::Framework;
      sub apply_middleware ($app) {
        $app = Plack::Middleware::Alice->wrap($app, %options);
        $app = Plack::Middleware::Bob->wrap($app, %options);
      }
    }

## Why Another Framework?

Plack comes with several modules that make it possible to create a bare-bones
web app, but as described in the documentation for Plack::Request, that is a
very low-level way to do it. A framework is recommended. This package
provides a minimalistic framework which takes Plack::Request, Plack::Response,
and several other modules and ties them together.

The end result is a simple framework that is higher level than using the raw
Plack building blocks, although it does not have as many features as other
frameworks. Here are some advantages:

- Load Time

    A basic PlackX::Framework "Hello World" application loads 75% faster
    than a Dancer2 application and 70% faster than a Mojolicious::Lite app.
    (The author has not benchmarked request/response times.)

- Memory

    A basic PlackX::Framework "Hello World" application uses approximately
    one-third the memory of either Dancer2 or Mojolicious::Lite (~10MB compared
    to ~30MB for each of the other two).

- Dependencies

    PlackX::Framework has few non-core dependencies (it has more than
    Mojolicious, which has zero, but fewer than Dancer2, which has a lot.)

- Magic

    PlackX::Framework has some magic, but not too much. It can be easily
    overriden with subclassing. You can use the bundled router engine
    or supply your own. You can use Template Toolkit automatically or use
    a different template engine.

The author makes no claims that this framework is better than any other
framework except for the few trivial metrics described above. It has been
published in the spirit of TIMTOWDI.

## Why Now?

The project was started in 2016, and is used in production by its author.
It seemed well past time to publish it to CPAN (better late than never?).

## Object Orientation and Magic

PlackX::Framework has an object-oriented design philosophy that uses both
inheritance and composition to implement its features. Symbols exported are
limited to avoid polluting your namespace, however, a lot of the "magic" is
implemented with the import() method, so be careful about using empty
parenthesis in your use statements, as this will prevent the import() method
from being called and may break things.

Also be careful about whether you should use a module or subclass it.
Generally, modifying the behavior of the framework itself will involve
manual subclassing, while using the framework as-is will not.

## Configuration

### app\_base

### uri\_prefix

In your application's root namespace, you can set the base URL for requests
by defining an app\_base subroutine; uri\_prefix can be used as a synonym.

    package MyApp {
      use PlackX::Framework;
      sub app_base { '/app' } # or uri_prefix
    }

Internally, this uses Plack::App::URLMap to cleave the base from the path\_info.
This feature will not play well if you mount your app to a particular uri path
using Plack::Builder. Use one or the other, not both. If you would like to give
your app flexibility for different environments, you could do something like
the following:

    # Main app package
    package MyApp {
      use PlackX::Framework;
      sub app_base { $ENV{'myapp_base'} }
    }

    # one app .psgi file which uses Builder
    use Plack::Builder;
    $ENV{'myapp_base'} = '';
    builder {
      mount '/myapp' => MyApp->app;
      ...
    };

    # another app .psgi file, perhaps on a different server, not using Builder
    $ENV{'myapp_base'} = '/myapp';
    MyApp->app;

## Routes, Requests, and Request Filtering

See PlackX::Framework::Router for detailed documentation on request routing and
filtering.

## Templating

No Templating system is loaded by default, but PlackX::Framework can
automatically load and set up Template Toolkit if you:

    use MyProject::Template;

(assuming MyProject has imported from PlackX::Framework).

Note that this feature relies on the import() method of your app's
PlackX::Framework::Template subclass being called (this subclass is also
created automatically if you do not have a MyApp/Template.pm file).
Therefore, the following will not load Template Toolkit:

    use MyApp::Template ();  # Template Toolkit is not loaded
    require MyApp::Template; # Template Toolkit is not loaded

If you want to supply Template Toolkit with configuration options, you can
add them by specifying a parameter hashref:

    use MyApp::Template { INCLUDE_PATH => 'template', ... };

If you want to use your own templating system, you can create a MyApp::Template
module that subclasses PlackX::Framework::Template, then override necessary
methods; however, a simpler way is available if your templating system has a TT
compatible process() method, like this:

    use MyApp::Template qw(:manual);
    MyApp::Template->set_engine(My::Template::System->new(%options));

## Model Layer

This framework is database/ORM agnostic, you are free to choose your own or use
plain DBI/SQL.

# EXPORT

This module will export the "app" method, which returns the code reference of
your app in accordance to the PSGI specification. (This is actually a shortcut
to \[ProjectName\]::Handler->build\_app.)

# DEPENDENCIES

## Required

- perl 5.36 or greater
- Plack
- Router::Boom

## Optional

- Config::Any
- Sub::Util

    Due to extensive use of code references, installation of Sub::Util is
    recommended to help debugging your application.

- Template
- URI::Fast

# SEE ALSO

- PSGI
- Plack
- Plack::Request
- Plack::Response
- Router::Boom

# AUTHOR

Dondi Michael Stroma, <dstroma@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Dondi Michael Stroma

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
