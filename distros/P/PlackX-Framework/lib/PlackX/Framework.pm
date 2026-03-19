# strict (5.12), warnings (5.35), signatures (5.36)
use v5.36;

package PlackX::Framework 0.26 {
  use PXF::Util ();
  use List::Util qw(any);

  our @plugins = ();
  sub required_modules { qw(Handler Request Response Router Router::Engine) }
  sub optional_modules { qw(Config Template URIx), @plugins }

  # Export ->app, load parent classes and load or create subclasses
  sub import (@options) {
    my %required = map { $_ => 1 } required_modules(); # not memoized to save ram
    my $want_all = any { $_ =~ m/^[:+]all$/ } @options;
    my $want_mod = ($want_all or sub { any { $_ =~ m/^[:+]{0,2}$_[0]$/i } @options });
    my $caller   = caller(0);
    export_app_sub($caller);

    # Load or create required modules, attempt to load optional ones
    # Distinguish between modules not existing and modules with errors
    foreach my $module (required_modules(), optional_modules()) {
      eval 'require PlackX::Framework::'.$module
        or die $@ if $required{$module};
      eval 'require '.$caller.'::'.$module or do {
        die $@ if PXF::Util::is_module_broken($caller.'::'.$module);
        generate_subclass($caller.'::'.$module, 'PlackX::Framework::'.$module)
          if $required{$module} or $want_all or $want_mod->($module);
      };
      export_app_namespace_sub($caller, $module)
        if PXF::Util::is_module_loaded($caller.'::'.$module);
    }
  }

  # Export app() sub to the app's main package
  sub export_app_sub ($to_package) {
    my $code = sub ($class, @opts) { ($class.'::Handler')->build_app(@opts) };
    no strict 'refs';
    *{$to_package.'::app'} = *{$to_package.'::to_app'} = $code;
  }

  # Export app_namespace() to App::Request, App::Response, etc.
  sub export_app_namespace_sub ($namespace, $module) {
    no strict 'refs';
    my $exists = eval $namespace.'::'.$module.'::app_namespace()';
    die "app_namespace(): expected $namespace, got $exists" if $exists and $exists ne $namespace;
    *{$namespace.'::'.$module.'::app_namespace'} = sub { $namespace } unless $exists;
  }

  # Helper to create a subclass and mark as loaded
  sub generate_subclass ($new_class, $parent_class) {
    eval "package $new_class; use parent '$parent_class'; 1" or die "Cannot create class: $@";
    PXF::Util::mark_module_loaded($new_class);
  }

  # Keep name to 16B. Memoize so we don't have compute md5 each time.
  sub flash_cookie_name ($class) {
    state %names; $names{$class} ||= 'flash'. PXF::Util::md5_ushort($class, 11);
  }
}

1;

=pod

=head1 NAME

PlackX::Framework - A thin framework for PSGI/Plack web apps.


=head1 SYNOPSIS

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
separate files, for example in MyProject::Controller::* modules. Each should
use MyProject::Router if the DSL-style routing is desired.

This software is considered to be in an experimental, "alpha" stage.


=head1 DESCRIPTION

=head2 Overview and Required Components

PlackX::Framework consists of the required modules:

=over 4

=item PlackX::Framework

=item PlackX::Framework::Handler

=item PlackX::Framework::Request

=item PlackX::Framework::Response

=item PlackX::Framework::Router

=item PlackX::Framework::Router::Engine

=back

And the following optional modules:

=over 4

=item PlackX::Framework::Config

=item PlackX::Framework::Template

=item PlackX::Framework::URIx

=back

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


=head2 Optional Components

The Config, Template, URIx modules are included in the distribution, but
loading them is optional to save memory and compile time when not needed.
Just as with the required modules, you can subclass them yourself, or you can
have them automatically generated.

To set up all optional modules, import with the :all (or +all) tag.

    # The following are equivalent
    use PlackX::Framework qw(:all);
    use PlackX::Framework qw(+all);

Note that 'use Module -option' syntax is not supported, because it can be mis-
read by human readers as "minus option" which might give the impression that
the named option is being turned off.

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


=head2 The Pieces and How They Work Together

=head3 PlackX::Framework

PlackX::Framework is basically a management module that is responsible for
loading required and optional components. It will automatically subclass
required, and desired optional classes for you if you have not done so already.
It exports one symbol, app(), to the calling package; it also exports an
app_namespace() sub to your app's subclasses, which returns the name of the
root class.

  # Example app
  package MyApp {
    # The following statement will load, or automatically create,
    # MyApp::Handler, MyApp::Request, MyApp::Response, MyApp::Router, etc.
    # It will create a MyApp::app() function, and an app_namespace() function
    # in each respective subclassed module if one does not already exist.
    use PlackX::Framework qw(:all);
  }



=head3 PlackX::Framework::Handler

PlackX::Framework::Handler is the package responsible for request processing.
You would not normally have to subclass this module manually unless you would
like to customize its behavior. It will prepare request and response objects,
a stash, and if set up, templating.


=head3 PlackX::Framework::Request

=head3 PlackX::Framework::Response

The PlackX::Framework::Request and PlackX::Framework::Response modules are
subclasses of Plack::Request and Plack::Response sprinkled with additional
features, described below.

=over 4

=item stash()

Both feature a shared "stash" which is a hashref in which you can store any
data you would like. The "stash" is not a user session but a way to
temporarily store information during a request/response cycle. It is
re-initialized for each cycle.

=item flash()

They also feature a "flash" cookie which you can use to store information on
the user end for one cycle. It is automatically cleared in the following
cycle. For example...

    $response->flash('Goodbye!'); # Store message in a cookie

On the next request:

    $request->flash; # Returns 'Goodbye!'.

During the response phase, the flash cookie is cleared, unless you set another
one.

=back

=head3 PlackX::Framework::Router

This module exports the route, route_base, global_filter, and filter functions
to give you a minimalistic web app controller DSL. You can import this into
your main app package, as shown in the introduction, or separate packages.

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


=head3 PlackX::Framework::Router::Engine

The PlackX::Framework::Router::Engine is a subclass of Router::Boom with some
extra convenience methods. Normally, you would not have to use this module
directly. It is used by PlackX::Framework::Router internally.


=head3 PlackX::Framework::Config

This module is provided primarily for convenience. Currently not used by PXF
directly except you may optionally store template system configuration there.


=head3 PlackX::Framework::Template

The PlackX::Framework::Template module can automatically load and set up
Template Toolkit, offering several convenience methods. If you desire to use
a different templating system from TT, you may override as many methods as
necessary in your subclass. A new instance of this class is generated for
each request by the app() method of PlackX::Framework::Handler.


=head3 PlackX::Framework::URIx

The PlackX::Framework::URIx is a URI processing module with extended features,
and it is a subclass of URI::Fast. It is made available to your
your request objects through $request->urix (the x is to not confuse it
with the Plack::Request->uri() method). If you have not enabled the URIx
feature in your application, with the :URIx or :all tag, the request->urix
method will cause an error.


=head2 Why Another Framework?

Plack comes with several modules that make it possible to create a bare-bones
web app, but as described in the documentation for Plack::Request, that is a
very low-level way to do it. A framework is recommended. This package
provides a minimalistic framework which takes Plack::Request, Plack::Response,
and several other modules and ties them together.

The end result is a simple framework that is higher level than using the raw
Plack building blocks, although it does not have as many features as other
frameworks. Here are some advantages:

=over 4

=item Load Time

A basic PlackX::Framework "Hello World" application loads 75% faster
than a Dancer2 application and 70% faster than a Mojolicious::Lite app.
(The author has not benchmarked request/response times.)

=item Memory

A basic PlackX::Framework "Hello World" application uses approximately
one-third the memory of either Dancer2 or Mojolicious::Lite (~10MB compared
to ~30MB for each of the other two).

=item Dependencies

PlackX::Framework has few non-core dependencies (it has more than
Mojolicious, which has zero, but fewer than Dancer2, which has a lot.)

=item Magic

PlackX::Framework has some magic, but not too much. It can be easily
overriden with subclassing. You can use the bundled router engine
or supply your own. You can use Template Toolkit automatically or use
a different template engine.

=back

The author makes no claims that this framework is better than any other
framework except for the few trivial metrics described above. It has been
published in the spirit of TIMTOWDI.

=head2 Why Now?

The project was started in 2016, and is used in production by its author.
It seemed well past time to publish it to CPAN (better late than never?).


=head2 Object Orientation and Magic

PlackX::Framework has an object-oriented design philosophy that uses both
inheritance and composition to implement its features. Symbols exported are
limited to avoid polluting your namespace, however, a lot of the "magic" is
implemented with the import() method, so be careful about using empty
parenthesis in your use statements, as this will prevent the import() method
from being called and may break things.

Also be careful about whether you should use a module or subclass it.
Generally, modifying the behavior of the framework itself will involve
manual subclassing, while using the framework as-is will not.


=head2 Configuration

=head3 app_base

=head3 uri_prefix

In your application's root namespace, you can set the base URL for requests
by defining an app_base subroutine; uri_prefix can be used as a synonym.

    package MyApp {
      use PlackX::Framework;
      sub app_base { '/app' } # or uri_prefix
    }

Internally, this uses Plack::App::URLMap to cleave the base from the path_info.
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


=head2 Routes, Requests, and Request Filtering

See PlackX::Framework::Router for detailed documentation on request routing and
filtering.


=head2 Templating

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
add them like this

    use MyApp::Template (INCLUDE_PATH => 'template');

If you want to use your own templating system, you can create a MyApp::Template
module that subclasses PlackX::Framework::Template, then override necessary
methods; however, a simpler way is available if your templating system as a TT
compatible process method, like this:

    use MyApp::Template qw(:manual);
    MyApp::Template->set_engine(My::Template::System->new(%options));


=head2 Model Layer

This framework is databse/ORM agnostic, you are free to choose your own or use
plain DBI/SQL.


=head1 EXPORT

This module will export the "app" method, which returns the code reference of
your app in accordance to the PSGI specification. (This is actually a shortcut
to [ProjectName]::Handler->build_app.)


=head1 DEPENDENCIES

=head2 Required

=over 4

=item perl 5.36 or greater

=item Plack

=item Router::Boom

=item URI::Fast

=back


=head2 Optional

=over 4

=item Config::Any

=item Template

=back

=head1 SEE ALSO

=over 4

=item PSGI

=item Plack

=item Plack::Request

=item Plack::Response

=item Router::Boom

=back


=head1 AUTHOR

Dondi Michael Stroma, E<lt>dstroma@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Dondi Michael Stroma


=cut
