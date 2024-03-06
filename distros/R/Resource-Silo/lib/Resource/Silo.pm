package Resource::Silo;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.1203';

use Carp;
use Scalar::Util qw( set_prototype );

use Resource::Silo::Metadata;
use Resource::Silo::Container;

# This is a dummy block to hint IDEs.
# see 'import' below for _real_ resource & silo implementation
use parent 'Exporter';
our @EXPORT = qw( resource silo );
#@returns Resource::Silo::Container
sub silo     ();  ## no critic 'prototypes'
sub resource (@); ## no critic 'prototypes'

# We'll need a global metadata storage
#     to allow extending container classes
our %metadata;

sub import {
    my ($self, @param) = @_;
    my $caller = caller;
    my $target;
    my $shortcut = "silo";

    while (@param) {
        my $flag = shift @param;
        if ($flag eq '-class') {
            $target = $caller;
        } elsif ($flag eq '-shortcut') {
            $shortcut = shift @param;
            croak "-shortcut must be an identifier"
                unless $shortcut and !ref $shortcut and $shortcut =~ /^[a-z_][a-z_0-9]*$/i;
        } else {
            # TODO if there's more than 3 elsifs, use jump table instead
            croak "Unexpected parameter to 'use $self': '$flag'";
        };
    };

    $target ||= __PACKAGE__."::container::".$caller;

    my $spec = Resource::Silo::Metadata->new($target);
    $metadata{$target} = $spec;

    my $instance;
    my $silo = set_prototype {
        # cannot instantiate target until the package is fully defined,
        # thus go lazy
        $instance //= $target->new;
    } '';

    no strict 'refs'; ## no critic
    no warnings 'redefine', 'once'; ## no critic

    push @{"${target}::ISA"}, 'Resource::Silo::Container';

    push @{"${caller}::ISA"}, 'Exporter';
    push @{"${caller}::EXPORT"}, $shortcut;
    *{"${caller}::resource"} = $spec->_make_dsl;
    *{"${caller}::$shortcut"}     = $silo;
};

1; # End of Resource::Silo

__END__

=head1 NAME

Resource::Silo - lazy declarative resource container for Perl.

=head1 DESCRIPTION

This module provides a container that manages initialization, caching, and
cleanup of resources that the application needs to talk to the outside world,
such as configuration files, database connections, queues,
external service endpoints, and so on.

Upon use, a one-off container class based on L<Resource::Silo::Container>
with a one-and-true (but not necessarily only) instance is created.

The resources are then defined using a L<Moose>-like DSL,
and their identifiers become method names in said class.
Apart from a name, each resource has an initialization routine,
and optionally dependencies, cleanup routine, and various flags.

Resources are instantiated on demand and cached.
The container is fork-aware and will reset its cache
whenever the process ID changes.

=head1 SYNOPSIS

Declaring the resources:

    package My::App;

    # This creates 'resource' and 'silo' functions
    # and *also* makes 'silo' re-exportable via Exporter
    use Resource::Silo;

    # A literal resource, that is, initialized with a constant value
    resource config_file =>
        literal => '/etc/myapp/myapp.yaml';

    # A typical resource with a lazy-loaded module
    resource config =>
        require => 'YAML::XS',
        init    => sub {
            my $self = shift;
            YAML::XS::LoadFile( $self->config_file );
        };

    # Derived resource is a front end to other resources
    # without side effects of its own.
    resource app_name =>
        derived => 1,
        init    => sub { $_[0]->config->{name} };

    # An RDBMS connection is one of the most expected things here
    resource dbh =>
        require      => [ 'DBI' ],      # loading multiple modules is fine
        dependencies => [ 'config' ],
        init         => sub {
            my $self = shift;
            my $config = $self->config->{database};
            DBI->connect(
                $config->{dsn},
                $config->{username},
                $config->{password},
                { RaiseError => 1 }
            );
        };

    # A full-blown Spring style dependency injection
    resource myclass =>
        derived => 1,
        class   => 'My::App::Class',  # call My::App::Class->new
        dependencies => {
            dbh => 1,                 # pass 'dbh' resource to new()
            name => 'app_name',       # set 'name' parameter to 'app_name' resource
            version => \3.14,         # pass a literal value
        };

Accessing the resources in the app itself:

    use My::App qw(silo);

    my $app = silo->myclass; # this will initialize all the dependencies
    $app->frobnicate;

Partial resource usage and fine-grained control,
e.g. in a maintenance script:

    use 5.010;
    use My::App qw(silo);

    # Override a resource with something else
    silo->ctl->override( config => shift );

    # This will derive a database connection from the given configuration file
    my $dbh = silo->dbh;

    say $dbh->selectall_arrayref('SELECT count(*) FROM users')->[0][0];

Writing tests:

    use Test::More;
    use My::All qw(silo);

    # replace side effect with mocks
    silo->ctl->override( config => $config_hash, dbh => $local_sqlite );

    # make sure no other side effects will ever be triggered
    # (unless 'derived' flag is set or resource is a literal)
    silo->ctl->lock;

    my $app = silo->myclass;
    # run actual tests below

=head1 IMPORT/EXPORT

The following functions will be exported into the calling module,
unconditionally:

=over

=item * resource - resource declaration DSL;

=item * silo - a re-exportable prototyped function
returning the one and true container instance.

=back

Additionally, L<Exporter> is added to the calling package's C<@ISA>
and C<silo> is appended to C<our @EXPORT>.

B<NOTE> If the module has other exported functions, they should be added
via

    push our @EXPORT, qw( foo bar quux );

or else the C<silo> function in that array will be overwritten.

=head2 USE OPTIONS

=head3 -class

If a C<-class> argument is given on the use line,
the calling package will itself become the container class.

Such a class may have normal fields and methods in addition to resources
and will also be L<Moose>- and L<Moo>-compatible.

=head3 -shortcut <function name>

If specified, use that name for main instance, instead of C<silo>.
Name must be a valid identifier, i.e. C</[a-z_][a-z_0-9]*/i>.

=head2 resource

    resource 'name' => sub { ... };
    resource 'name' => %options;

If the number of arguments is odd,
the last one is popped and considered to be the initializer.

%options may include:

=head3 init => sub { $container, $name, [$argument] }

The initializer coderef.
Required, unless C<literal> or C<class> are specified.

The arguments to the initializer are the container itself,
resource name, and an optional argument or an empty string if none given.
(See C<argument> below).

Returning an C<undef> value is considered an error.

Using C<Carp::croak> in the initializer will blame the code
that has requested the resource, skipping Resource::Silo's internals.

=head3 literal => $value

Consider the resource to be a value known at startup time.
This may be e.g. a configuration file name or an environmental variable:

    resource config_file =>
        literal => $ENV{MY_CONFIG} // '/etc/myapp/config.yaml';

Replaces initializer with C<sub { $value }>.

In addition, C<derived> flag is set,
and an empty C<dependencies> list is implied.

=head3 class => 'Class::Name'

Turn on Spring-style dependency injection.
This forbids the C<argument> parameter
and requires C<dependencies> to be a hash.

The dependencies' keys become the arguments to C<Class::Name-E<gt>new>,
and the values format is as follows:

=over

=item * argument_name => resource_name

Use a resource without parameter;

=item * argument_name => [ resource_name => argument ]

Use a parametric resource;

=item * resource_name => 1

Shorthand for C<resource_name =E<gt> resource_name>;

=item * name => \$literal_value

Pass $literal_value to the constructor as is.

=back

So this:

    resource foo =>
        class           => 'My::Foo',
        dependencies    => {
            dbh     => 1,
            redis   => [ redis => 'session' ],
            version => \3.14,
        };

Is roughly equivalent to:

    resource foo =>
        dependencies    => [ 'dbh', 'redis' ],
        init            => sub {
            my $c = shift;
            require My::Foo;
            My::Foo->new(
                dbh     => $c->dbh,
                redis   => $c->redis('session'),
                version => 3.14,
            );
        };

C<init>, C<literal>, and C<class> are mutually exclusive.

=head3 require => 'Module::Name' || \@module_list

Load module(s) specified before calling the initializer.

This is exactly the same as calling require 'Module::Name' in the initializer
itself except that it's more explicit.

=head3 dependencies => \@list

List other resources that may be requested in the initializer.
Unless C<loose_deps> is specified (see below),
the dependencies I<must> be declared I<before> the dependant.

A resource with parameter may also depend on itself.

The default is all eligible resources known so far.

B<NOTE> This behavior was different prior to v.0.09
and may be change again in the near future.

This parameter has a different structure
if C<class> parameter is in action (see below).

=head3 loose_deps => 1|0

Allow dependencies that have not been declared yet.

Not specifying the C<dependencies> parameter would now mean
there are no restrictions whatsoever.

B<NOTE> Having to resort to this flag may be
a sign of a deeper architectural problem.

=head3 argument => C<sub { ... }> || C<qr( ... )>

Declare a (possibly infinite) set of sibling resources under the same name,
distinguished by a string parameter.
Said parameter will be passed to the C<init> function.

Exactly one resource instance will be cached per argument value.

A regular expression will always be anchored to match I<the whole string>.
A function must return true for the parameter to be valid.

If the argument is omitted, it is assumed to be an empty string.

E.g. when using L<Redis::Namespace>:

    package My::App;
    use Resource::Silo;

    resource redis_server => sub { Redis->new() };

    resource redis =>
        require         => 'Redis::Namespace',
        derived         => 1,
        argument        => qr([\w:]*),
        init            => sub {
            my ($c, undef, $ns) = @_;
            Redis::Namespace->new(
                redis     => $c->redis_server,
                namespace => $ns,
            );
        };

=head3 cleanup => sub { $resource_instance }

Undo the init procedure.
Usually it is assumed that the resource will do it by itself in the destructor,
e.g. that's what a L<DBI> connection would do.
However, if it's not the case, or resources refer circularly to one another,
a manual "destructor" may be specified.

It only accepts the resource itself as an argument and will be called before
erasing the object from the cache.

See also C<fork_cleanup>.

=head3 fork_cleanup => sub { $resource_instance }

If present, use this function in place of C<cleanup>
if the process ID has changed.
This may be useful if cleanup is destructive and shouldn't be performed twice.

The default is same as C<cleanup>.

See L</FORKING>.

=head3 cleanup_order => $number

The higher the number, the later the resource will get destroyed.

The default is 0, negative numbers are also valid, if that makes sense for
you application
(e.g. destroy C<$my_service_main_object> before the resources it consumes).

    resource logger =>
        cleanup_order   => 9e9,     # destroy as late as possible
        require         => [ 'Log::Any', 'Log::Any::Adapter' ],
        init            => sub {
            Log::Any::Adapter->set( 'Stderr' );
            # your rsyslog config could be here
            Log::Any->get_logger;
        };

=head3 derived => 1 | 0

Assume the resource introduces no side effects
apart from those already handled by its dependencies.

This also naturally applies to resources with pure initializers,
i.e. those having no dependencies and adding no side effects on top.

Examples may be L<Redis::Namespace> built on top of a L<Redis> handle
or L<DBIx::Class> built on top of L<DBI> connection.

Derivative resources may be instantiated even in locked mode,
as they would only initialize if their dependencies have already been
either initialized, or overridden.

See L<Resource::Silo::Container/lock>.

=head3 ignore_cache => 1 | 0

If set, don't cache resource, always create a fresh one instead.
See also L<Resource::Silo::Container/fresh>.

=head3 preload => 1 | 0

If set, try loading the resource when C<silo-E<gt>ctl-E<gt>preload> is called.
Useful if you want to throw errors when a service is starting,
not during request processing.

See L<Resource::Silo::Container/preload>.

=head2 silo

A re-exportable function returning one and true container instance
associated with the class where the resources were declared.

B<NOTE> Calling C<use Resource::Silo> from a different module will
create a I<separate> container instance. You'll have to re-export
(or otherwise provide access to) this function.

I<This is done on purpose so that multiple projects or modules can coexist
within the same interpreter without interference.>

C<silo-E<gt>new> will create a new instance of the I<same> container class.
The resource container class may therefore be viewed as an
I<optional singleton>.

=head1 CAVEATS AND CONSIDERATIONS

See L<Resource::Silo::Container> for the container implementation.

See L<Resource::Silo::Metadata> for the metadata storage.

=head2 FINE-GRAINED CONTROL INTERFACE

Calling C<$container-E<gt>ctl> will return a frontend object
which allows to control the container itself.
This is done so in order to avoid polluting the container namespace:

    use My::App qw(silo);

    # instantiate a separate instance of a resource, ignoring the cache
    # e.g. for a long and invasive database update
    my $dbh = silo->ctl->fresh("dbh");

See L<Resource::Silo::Container/ctl> for more.

=head2 OVERRIDES AND LOCKING

In addition to declaring resources, L<Resource::Silo> provides a mechanism
to C<override> an existing initializer with a user-supplied routine.
(If a non-coderef value is given, it's wrapped into a function.)

It also allows to prevent instantiation of new resources via C<lock> method.
After C<$container-E<gt>ctl-E<gt>lock>,
trying to obtain a resource will cause an exception,
unless the resource is overridden, already in the cache,
or marked as C<derived> and thus considered safe,
as long as its dependencies are safe.

The primary use for these is of course providing test fixtures / mocks:

    use Test::More;
    use My::App qw(silo);

    silo->ctl->override(
        config  => $config_hash,     # short hand for sub { $config_hash }
        dbh     => $local_sqlite,
    );
    silo->ctl->lock;

    silo->dbh->do( $sql );                  # works on the mock
    silo->user_agent->get( $partner_url );  # dies unless the UA was also mocked

Passing parameters to the container class constructor
will use C<override> internally, too:

    package My::App;
    use Resource::Silo -class;

    resource foo => sub { ... };

    # later...
    my $app = My::App->new( foo => $foo_value );
    $app->frobnicate();      # will use $foo_value instead of instantiating foo

See L<Resource::Silo::Container/override>, L<Resource::Silo::Container/lock>,
and L<Resource::Silo::Container/unlock> for details.

=head2 CACHING

All resources are cached, the ones with arguments are cached together
with the argument.

=head2 FORKING

If the process forks, resources such as database handles may become invalid
or interfere with other processes' copies.
As of current, if a change in the process ID is detected,
the resource cache is reset altogether.

This may change in the future as some resources
(e.g. configurations or endpoint URLs) are stateless and may be preserved.

=head2 CIRCULAR DEPENDENCIES

If a resource depends on other resources,
those will be simply created upon request.

It is possible to make several resources depend on each other.
Trying to initialize such resource will cause an expection, however.

=head2 COMPATIBILITY

L<Resource::Silo> uses L<Moo> internally and is therefore compatible with
both L<Moo> and L<Moose> when in C<-class> mode:

    package My::App;

    use Moose;
    use Resource::Silo -class;

    has path => is => 'ro', default => sub { '/dev/null' };
    resource fd => sub {
        my $self = shift;
        open my $fd, "<", $self->path;
        return $fd;
    };

Extending such mixed classes will also work.
However, as of current, the resource definitions will be taken
from the nearest ancestor that has any, using breadth first search.

=head2 TROUBLESHOOTING

Resource instantiation order may become tricky in real-life usage.

C<$container-E<gt>ctl-E<gt>list_cached> will output a list of all
resources that have been initialized so far. The ones with arguments
will be in form of "name/argument".
See L<Resource::Silo::Container/list_cached>.

C<$container-E<gt>ctl-E<gt>meta> will return a metaclass object
containing the resource definitions.
See L<Resource::Silo::Container/meta>.

=head1 MORE EXAMPLES

Setting up outgoing HTTP.
Aside from having all the tricky options in one place,
this prevents accidentally talking to production endpoints while running tests.

    resource user_agent =>
        require => 'LWP::UserAgent',
        init => sub {
            my $ua = LWP::UserAgent->new;
            $ua->agent( 'Tired human with red eyes' );
            $ua->protocols_allowed( ['http', 'https'] );
            # insert your custom SSL certificates here
            $ua;
        };

Using L<DBIx::Class> together with a regular L<DBI> connection:

    resource dbh => sub { ... };

    resource schema =>
        derived         => 1,                   # merely a frontend to DBI
        require         => 'My::App::Schema',
        dependencies    => [ 'dbh' ],
        init            => sub {
            my $self = shift;
            return My::App::Schema->connect( sub { $self->dbh } );
        };

    resource resultset =>
        derived         => 1,
        dependencies    => 'schema',
        argument        => qr(\w+),
        init            => sub {
            my ($c, undef, $name) = @_;
            return $c->schema->resultset($name);
        };

=head1 SEE ALSO

L<Bread::Board> - a more mature IoC / DI framework.

=head1 BUGS

This software is still in beta stage. Its interface is still evolving.

=over

=item * Version 0.09 brings a breaking change that forbids forward dependencies.

=item * Forced re-exporting of C<silo> was probably a bad idea
and should have been left as an exercise to the user.

=back

Please report bug reports and feature requests to
L<https://github.com/dallaylaen/resource-silo-p5/issues>
or via RT:
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Resource-Silo>.

=head1 ACKNOWLEDGEMENTS

=over

=item * This module was names after a building in the game
B<I<Heroes of Might and Magic III.>>

=item * This module was inspired in part by my work for
L<Cloudbeds|https://www.cloudbeds.com/>.
That was a great time!

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Resource::Silo

You can also look for information at:

=over

=item * Github: L<https://github.com/dallaylaen/resource-silo-p5>;

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Resource-Silo>;

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Resource-Silo>;

=item * Search CPAN

L<https://metacpan.org/release/Resource-Silo>;

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023-2024, Konstantin Uvarin, C<< <khedin@gmail.com> >>

This program is free software.
You can redistribute it and/or modify it under the terms of either:
the GNU General Public License as published by the Free Software Foundation,
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
