package Prancer;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

# using Web::Simple in this context will implicitly make Prancer a subclass of
# Web::Simple::Application. that will cause a number of things to be imported
# into the Prancer namespace. see ->import below for more details.
use Web::Simple 'Prancer';

use Cwd ();
use Module::Load ();
use Try::Tiny;
use Carp;

use Prancer::Core;
use Prancer::Request;
use Prancer::Response;
use Prancer::Session;

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

# the list of methods that will be created on the fly, linked to private
# methods of the same name, and exported to the caller. this makes things like
# the bareword call to "config" work. this list is populated in ->import
our @TO_EXPORT = ();

# a super private method
my $enable_static = sub {
    my ($self, $app) = @_;
    return $app unless defined($self->{'_core'}->config());

    my $config = $self->{'_core'}->config->get('static');
    return $app unless defined($config);

    try {
        # this intercepts requests for documents under the configured URL
        # and checks to see if the requested file exists in the configured
        # file system path. if it does exist then it is served up. if it
        # doesn't exist then the request will pass through to the handler.
        die "no directory is configured for the static file loader\n" unless defined($config->{'dir'});
        my $dir = Cwd::realpath($config->{'dir'});
        die "${\$config->{'dir'}} does not exist\n" unless defined($dir);
        die "${\$config->{'dir'}} is not readable\n" unless (-r $dir);

        # this is the url under which static files will be stored
        my $path = $config->{'path'} || '/static';

        require Plack::Middleware::Static;
        $app = Plack::Middleware::Static->wrap($app,
            'path'         => sub { s/^$path//x },
            'root'         => $dir,
            'pass_through' => 1,
        );
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        carp "initialization warning generated while trying to load the static file loader: ${error}";
    };

    return $app;
};

# a super private method
my $enable_sessions = sub {
    my ($self, $app) = @_;
    return $app unless defined($self->{'_core'}->config());

    my $config = $self->{'_core'}->config->get('session');
    return $app unless defined($config);

    try {
        # load the session state package first
        # this will probably be a cookie
        my $state_package = undef;
        my $state_options = undef;
        if (ref($config->{'state'}) && ref($config->{'state'}) eq "HASH") {
            $state_package = $config->{'state'}->{'driver'};
            $state_options = $config->{'state'}->{'options'};
        }

        # make sure state options are legit
        if (defined($state_options) && (!ref($state_options) || ref($state_options) ne "HASH")) {
            die "session state configuration options are invalid -- expected a HASH\n";
        }

        # set defaults and then load the state package
        $state_package ||= "Prancer::Session::State::Cookie";
        $state_options ||= {};
        Module::Load::load($state_package);

        # set the default for the cookie name because the plack default is dumb
        $state_options->{'session_key'} ||= (delete($state_options->{'key'}) || "PSESSION");

        # now load the store package
        my $store_package = undef;
        my $store_options = undef;
        if (ref($config->{'store'}) && ref($config->{'store'}) eq "HASH") {
            $store_package = $config->{'store'}->{'driver'};
            $store_options = $config->{'store'}->{'options'};
        }

        # make sure store options are legit
        if (defined($store_options) && (!ref($store_options) || ref($store_options) ne "HASH")) {
            die "session store configuration options are invalid -- expected a HASH\n";
        }

        # set defaults and then load the store package
        $store_package ||= "Prancer::Session::Store::Memory";
        $store_options ||= {};
        Module::Load::load($store_package);

        require Plack::Middleware::Session;
        $app = Plack::Middleware::Session->wrap($app,
            'state' => $state_package->new(%{$state_options}),
            'store' => $store_package->new(%{$store_options}),
        );
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        carp "initialization warning generated while trying to load the session handler: ${error}";
    };

    return $app;
};

sub new {
    my ($class, $configuration_file) = @_;
    my $self = bless({}, $class);

    # the core is where our methods *really* live
    # we mostly just proxy through to that
    $self->{'_core'} = Prancer::Core->new($configuration_file);

    # @TO_EXPORT is an array of arrayrefs representing methods that we want to
    # make available in our caller's namespace. each arrayref has two values:
    #
    #   0 = namespace into which we'll import the method
    #   1 = the method that will be imported (must be implemented in Prancer::Core)
    #
    # this makes "namespace::method" resolve to "$self->{'_core'}->method()".
    for my $method (@TO_EXPORT) {
        # don't import things that can't be resolved
        croak "Prancer::Core does not implement ${\$method->[1]}" unless $self->{'_core'}->can($method->[1]);

        no strict 'refs';
        no warnings 'redefine';
        *{"${\$method->[0]}::${\$method->[1]}"} = sub {
            my $internal = "${\$method->[1]}";
            return $self->{'_core'}->$internal(@_);
        };
    }

    # here are things that will always be exported into the Prancer namespace.
    # this DOES NOT export things things into our children's namespace, only
    # into the Prancer namespace. this makes things like "$app->config()" work.
    for my $method (qw(config)) {
        # don't export things that can't be resolved
        croak "Prancer::Core does not implement ${\$method->[1]}" unless $self->{'_core'}->can($method);

        no strict 'refs';
        no warnings 'redefine';
        *{"${\__PACKAGE__}::${method}"} = sub {
            return $self->{'_core'}->$method(@_);
        };
    }

    $self->initialize();
    return $self;
}

sub import {
    my ($class, @options) = @_;

    # store what namespace are importing things to
    my $namespace = caller(0);

    {
        # this block makes our caller a child class of this class
        no strict 'refs';
        unshift(@{"${namespace}::ISA"}, __PACKAGE__);
    }

    # this is used by Web::Simple to not complain about keywords in prototypes
    # like HEAD and GET. but we need to extend it to classes that implement us
    # so it is being adding it here, too.
    warnings::illegalproto->unimport();

    # keep track of what has been loaded so someone doesn't put the same thing
    # into the import list in twice.
    my $loaded = {};

    my @actions = ();
    for my $option (@options) {
        next if exists($loaded->{$option});
        $loaded->{$option} = 1;

        # these options will be exported as proxies to real methods
        if ($option =~ /^(config)$/x) {
            no strict 'refs';

            # need to predefine the exported method so that barewords work
            *{"${\__PACKAGE__}::${1}"} = *{"${namespace}::${1}"} = sub { return; };

            # this will tell ->new() to create the actual method
            push(@TO_EXPORT, [ $namespace, $1 ]);

            next;
        }

        croak "${option} is not exported by the ${\__PACKAGE__} package";
    }

    return;
}

sub to_psgi_app {
    my $self = shift;
    croak "cannot call ->to_psgi_app before calling ->new" unless (ref($self) && $self->isa(__PACKAGE__));

    # get the PSGI app from Web::Simple and wrap middleware around it
    my $app = $self->SUPER::to_psgi_app();

    # enable static document loading
    $app = $enable_static->($self, $app);

    # enable sessions
    $app = $enable_sessions->($self, $app);

    return $app;
}

# NOTE: your program can definitely implement ->dispatch_request instead of
# ->handler but ->handler will give you easier access to request and response
# data using Prancer::Request and Prancer::Response.
sub dispatch_request {
    my ($self, $env) = @_;

    my $request = Prancer::Request->new($env);
    my $response = Prancer::Response->new();
    my $session = Prancer::Session->new($env);

    return $self->handler($env, $request, $response, $session);
}

sub handler {
    croak "->handler must be implemented in child class";
}

sub initialize {
    return;
}

1;

=head1 NAME

Prancer

=head1 SYNOPSIS

When using as part of a web application:

    ===> foobar.yml

    session:
        state:
            driver: Prancer::Session::State::Cookie
            options:
                session_key: PSESSION
        store:
            driver: Prancer::Session::Store::Storable
            options:
                dir: /tmp/prancer/sessions

    static:
        path: /static
        dir: /srv/www/resources

    ===> myapp.psgi

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use Plack::Runner;

    # this just returns a PSGI application. $x can be wrapped with additional
    # middleware before sending it along to Plack::Runner.
    my $x = MyApp->new("/path/to/foobar.yml")->to_psgi_app();

    # run the psgi app through Plack and send it everything from @ARGV. this
    # way Plack::Runner will get options like what listening port to use and
    # application server to use -- Starman, Twiggy, etc.
    my $runner = Plack::Runner->new();
    $runner->parse_options(@ARGV);
    $runner->run($x);

    ===> MyApp.pm

    package MyApp;

    use strict;
    use warnings;

    use Prancer qw(config);

    sub initialize {
        my $self = shift;

        # in here we can initialize things like plugins
        # but this method is not required to be implemented

        return;
    }

    sub handler {
        my ($self, $env, $request, $response, $session) = @_;

        sub (GET + /) {
            $response->header("Content-Type" => "text/plain");
            $response->body("Hello, world!");
            return $response->finalize(200);
        }, sub (GET + /foo) {
            $response->header("Content-Type" => "text/plain");
            $response->body(sub {
                my $writer = shift;
                $writer->write("Hello, world!");
                $writer->close();
                return;
            });
        }
    }

    1;

If you save the above snippet as C<myapp.psgi> and run it like this:

    plackup myapp.psgi

You will get "Hello, world!" in your browser. Or you can use Prancer as part of
a standalone command line application:

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use Prancer::Core qw(config);

    # the advantage to using Prancer in a standalone application is the ability
    # to use a standard configuration and to load plugins for things like
    # loggers and database connectors and template engines.
    my $x = Prancer::Core->new("/path/to/foobar.yml");
    print "Hello, world!;

=head1 DESCRIPTION

Prancer is yet another PSGI framework that provides routing and session
management as well as plugins for logging, database access, and template
engines. It does this by wrapping L<Web::Simple> to handle routing and by
wrapping other libraries to bring easy access to things that need to be done in
web applications.

There are two parts to using Prancer for a web application: a package to
contain your application and a script to call your application. Both are
necessary.

The package containing your application should contain a line like this:

    use Prancer;

This modifies your application package such that it inherits from Prancer. It
also means that your package must implement the C<handler> method and
optionally implement the C<initialize> method. As Prancer inherits from
Web::Simple it will also automatically enable the C<strict> and C<warnings>
pragmas.

As mentioned, putting C<use Prancer;> at the top of your package will require
you to implement the C<handler> method, like this:

    sub handler {
        my ($self, $env, $request, $response, $session) = @_;

        # routing goes in here.
        # see Web::Simple for documentation on writing routing rules.
        sub (GET + /) {
            $response->header("Content-Type" => "text/plain");
            $response->body("Hello, world!");
            return $response->finalize(200);
        }
    }

The C<$request> variable is a L<Prancer::Request> object. The C<$response>
variable is a L<Prancer::Response> object. The C<$session> variable is a
L<Prancer::Session> object. If there is no configuration for sessions in any of
your configuration files then C<$session> will be C<undef>.

You may implement your own C<new> method in your application but you B<MUST>
call C<$class-E<gt>SUPER::new(@_);> to get the configuration file loaded and
any methods exported. As an alternative to implemeting C<new> and remembering
to call C<SUPER::new>, Prancer will make a call to C<-E<gt>initialize> at the
end of its own implementation of C<new> so things that you might put in C<new>
can instead be put into C<initialize>, like this:

    sub initialize {
        my $self = shift;

        # this is where you can initialize things when your package is created

        return;
    }

By default, Prancer does not export anything into your package's namespace.
However, that doesn't mean that there is not anything that it I<could> export
were one to ask:

    use Prancer qw(config);

Importing C<config> will make the keyword C<config> available which gives
access to any configuration options loaded by Prancer.

The second part of the Prancer equation is the script that creates and calls
your package. This can be a pretty small and standard little script, like this:

    my $myapp = MyApp->new("/path/to/foobar.yml")
    my $psgi = $myapp->to_psgi_app();

C<$myapp> is just an instance of your package. You can pass to C<new> either
one specific configuration file or a directory containing lots of configuration
files. The functionality is documented in C<Prancer::Config>.

C<$psgi> is just a PSGI app that you can send to L<Plack::Runner> or whatever
you use to run PSGI apps. You can also wrap middleware around C<$app>.

    my $psgi = $myapp->to_psgi_app();
    $psgi = Plack::Middleware::Runtime->wrap($psgi);

=head1 CONFIGURATION

Prancer needs a configuration file. Ok, it doesn't I<need> a configuration
file. By default, Prancer does not require any configuration. But it is less
useful without one. You I<could> always create your application like this:

    my $app = MyApp->new->to_psgi_app();

How Prancer loads configuration files is documented in L<Prancer::Config>.
Anything you put into your configuration file is available to your application.

There are two special configuration keys reserved by Prancer. The key
C<session> will configure Prancer's session as documented in
L<Prancer::Session>. The key C<static> will configure static file loading
through L<Plack::Middleware::Static>.

To configure static file loading you can add this to your configuration file:

    static:
        path: /static
        dir: /path/to/my/resources

The C<dir> option is required to indicate the root directory for your static
resources. The C<path> option indicates the web path to link to your static
resources. If no path is not provided then static files can be accessed under
C</static> by default.

=head1 CREDITS

This module could have been written except on the shoulders of the following
giants:

=over

=item

The name "Prancer" is a riff on the popular PSGI framework L<Dancer> and
L<Dancer2>. L<Prancer::Config> is derived directly from
L<Dancer2::Core::Role::Config>. Thank you to the Dancer/Dancer2 teams.

=item

L<Prancer::Database> is derived from L<Dancer::Plugin::Database>. Thank you to
David Precious.

=item

L<Prancer::Request>, L<Prancer::Request::Upload>, L<Prancer::Response>,
L<Prancer::Session> and the session packages are but thin wrappers with minor
modifications to L<Plack::Request>, L<Plack::Request::Upload>,
L<Plack::Response>, and L<Plack::Middleware::Session>. Thank you to Tatsuhiko
Miyagawa.

=item

The entire routing functionality of this module is offloaded to L<Web::Simple>.
Thank you to Matt Trout for some great code that I am able to easily leverage.

=back

=head1 COPYRIGHT

Copyright 2013, 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<Plack>

=item

L<Web::Simple>

=back

=cut
