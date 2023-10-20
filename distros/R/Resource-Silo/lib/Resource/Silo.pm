package Resource::Silo;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.11';

=head1 NAME

Resource::Silo - lazy declarative resource container for Perl.

=head1 DESCRIPTION

We assume the following setup:

=over

=item * The application needs to access multiple resources, such as
configuration files, databases, queues, service endpoints, credentials, etc.

=item * The application has helper scripts that don't need to initialize
all the resources at once, as well as a test suite where accessing resources
is undesirable unless a fixture or mock is provided.

=item * The resource management has to be decoupled from the application
logic where possible.

=back

And we propose the following solution:

=over

=item * All available resources are declared in one place
and encapsulated within a single container.

=item * Such container is equipped with methods to access resources,
as well as an exportable prototyped function for obtaining the one and true
instance of it (a.k.a. optional singleton).

=item * Every class or script in the project accesses resources
through this container and only through it.

=back

=head1 SYNOPSIS

The default mode is to create a one-off container for all resources
and export if into the calling class via C<silo> function.

    package My::App;
    use Resource::Silo;

    use DBI;
    use YAML::LoadFile;
    ...

    resource config => sub { LoadFile( ... ) };
    resource dbh    => sub {
        my $self = shift;
        my $conf = $self->config->{dbh};
        DBI->connect( $conf->{dsn}, $conf->{user}, $conf->{pass}, { RaiseError => 1 } );
    };
    resource queue  => sub { My::Queue->new( ... ) };
    ...

    my $statement = silo->dbh->prepare( $sql );
    my $queue = silo->queue;

For more complicated projects, it may make more sense
to create a dedicated class for resource management:

    # in the container class
    package My::Project::Res;
    use Resource::Silo -class;      # resource definitions will now create
                                    # eponymous methods in My::Project::Res

    resource foo => sub { ... };    # declare resources as in the above example
    resource bar => sub { ... };

    1;

    # in all other modules/packages/scripts:

    package My::Project;
    use My::Project::Res qw(silo);

    silo->foo;                      # obtain resources
    silo->bar;

    My::Project::Res->new;          # separate empty resource container

=head1 EXPORT

The following functions will be exported into the calling module,
unconditionally:

=over

=item * silo - a singleton function returning the resource container.
Note that this function will be created separately for every calling module,
and needs to be re-exported to be shared.

=item * resource - a DSL for defining resources, their initialization
and properties. See below.

=back

Additionally, if the C<-class> argument was added to the use line,
the following things happen:

=over

=item * L<Resource::Silo::Container> and L<Exporter> are added to C<@ISA>;

=item * C<silo> function is added to C<@EXPORT> and thus becomes re-exported
by default;

=item * calling C<resource> creates a corresponding method in this package.

=back

=head2 resource

    resource 'name' => sub { ... };
    resource 'name' => %options;

%options may include:

=head3 init => sub { $self, $name, [$argument] }

A coderef to obtain the resource.
Required, unless C<literal> or C<class> are specified.

If the number of arguments is odd,
the last one is popped and considered to be the init function.

=head3 literal => $value

Replace initializer with C<sub { $value }>.

In addition, C<derived> flag is set,
and an empty C<dependencies> list is implied.

=head3 argument => C<sub { ... }> || C<qr( ... )>

If specified, assume that the resource in question may have several instances,
distinguished by a string argument. Such argument will be passed as the 3rd
parameter to the C<init> function.

Only one resource instance will be cached per argument value.

This may be useful e.g. for L<DBIx::Class> result sets,
or for L<Redis::Namespace>.

A regular expression will always be anchored to match I<the whole string>.
A function must return true for the parameter to be valid.

If the argument is omitted, it is assumed to be an empty string.

See L<MORE EXAMPLES> below.

=head3 derived => 1 | 0

Assume that resource can be derived from its dependencies,
or that it introduces no extra side effects compared to them.

This also naturally applies to resources with pure initializers,
i.e. those having no dependencies and adding no side effects on top.

Examples may be L<Redis::Namespace> built on top of a L<Redis> handle
or L<DBIx::Class> built on top of L<DBI> connection.

Derivative resources may be instantiated even in locked mode,
as they would only initialize if their dependencies have already been
initialized or overridden.

See L<Resource::Silo::Container/lock>.

=head3 ignore_cache => 1 | 0

If set, don't cache resource, always create a fresh one instead.
See also L<Resource::Silo::Container/fresh>.

=head3 preload => 1 | 0

If set, try loading the resource when C<silo-E<gt>ctl-E<gt>preload> is called.
Useful if you want to throw errors when a service is starting,
not during request processing.

=head3 cleanup => sub { $resource_instance }

Undo the init procedure.
Usually it is assumed that the resource will do it by itself in the destructor,
e.g. that's what a L<DBI> connection would do.
However, if it's not the case, or resources refer circularly to one another,
a manual "destructor" may be specified.

It only accepts the resource itself as an argument and will be called before
erasing the object from the cache.

See also C<fork_cleanup>.

=head3 cleanup_order => $number

The higher the number, the later the resource will get destroyed.

The default is 0, negative numbers are also valid, if that makes sense for
you application
(e.g. destroy C<$my_service_main_object> before the resources it consumes).

=head3 fork_cleanup => sub { $resource_instance }

Like C<cleanup>, but only in case a change in process ID was detected.
See L</FORKING>

This may be useful if cleanup is destructive and shouldn't be performed twice.

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

=head3 class => 'Class::Name'

Turn on Spring-style dependency injection.
This forbids C<init> and C<argument> parameters
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

=head3 require => 'Module::Name' || \@module_list

Load module(s) specified before calling the initializer.

This is exactly the same as calling require 'Module::Name' in the initializer
itself except that it's more explicit.

=head2 silo

A re-exportable singleton function returning
one and true L<Resource::Silo::Container> instance
associated with the class where the resources were declared.

B<NOTE> Calling C<use Resource::Silo> from a different module will
create a I<separate> container instance. You'll have to re-export
(or otherwise provide access to) this function.

I<This is done on purpose so that multiple projects or modules can coexist
within the same interpreter without interference.>

C<silo-E<gt>new> will create a new instance of the I<same> container class.

=cut

use Carp;
use Exporter;
use Scalar::Util qw( set_prototype );

use Resource::Silo::Metadata;
use Resource::Silo::Container;

# Store definitions here
our %metadata;

sub import {
    my ($self, @param) = @_;
    my $caller = caller;
    my $target;

    while (@param) {
        my $flag = shift @param;
        if ($flag eq '-class') {
            $target = $caller;
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
    push @{"${caller}::EXPORT"}, qw(silo);
    *{"${caller}::resource"} = $spec->_make_dsl;
    *{"${caller}::silo"}     = $silo;
};

=head1 TESTING: LOCK AND OVERRIDES

It's usually a bad idea to access real-world resources in one's test suite,
especially if it's e.g. a partner's endpoint.

Now the #1 rule when it comes to mocks is to avoid mocks and instead design
the modules in such a way that they can be tested in isolation.
This however may not always be easily achievable.

Thus, L<Resource::Silo> provides a mechanism to substitute a subset of resources
with mocks and forbid the instantiation of the rest, thereby guarding against
unwanted side-effects.

The C<lock>/C<unlock> methods in L<Resource::Silo::Container>,
available via C<silo-E<gt>ctl> frontend,
temporarily forbid instantiating new resources.
The resources already in cache will still be OK though.

The C<override> method allows to supply substitutes for resources or
their initializers.

The C<derived> flag in the resource definition may be used to indicate
that a resource is safe to instantiate as long as its dependencies are
either instantiated or mocked, e.g. a L<DBIx::Class> schema is probably fine
as long as the underlying database connection is taken care of.

Here is an example:

    use Test::More;
    use My::Project qw(silo);
    silo->ctl->lock->override(
        dbh => DBI->connect( 'dbi:SQLite:database=:memory:', '', '', { RaiseError => 1 ),
    );

    silo->dbh;                   # a mocked database
    silo->schema;                # a DBIx::Class schema reliant on the dbh
    silo->endpoint( 'partner' ); # an exception as endpoint wasn't mocked

=head1 CAVEATS AND CONSIDERATIONS

See L<Resource::Silo::Container> for resource container implementation.

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
However, the resource definitions will be taken
from the nearest ancestor that has them, using breadth first search.

=head1 MORE EXAMPLES

=head2 Resources with just the init

    package My::App;
    use Resource::Silo;

    resource config => sub {
        require YAML::XS;
        YAML::XS::LoadFile( "/etc/myapp.yaml" );
    };

    resource dbh    => sub {
        require DBI;
        my $self = shift;
        my $conf = $self->config->{database};
        DBI->connect(
            $conf->{dbi}, $conf->{username}, $conf->{password}, { RaiseError => 1 }
        );
    };

    resource user_agent => sub {
        require LWP::UserAgent;
        LWP::UserAgent->new();
        # set your custom UserAgent header or SSL certificate(s) here
    };

Note that though lazy-loading the modules is not necessary,
it may speed up loading support scripts.

=head2 Resources with extra options

    resource logger =>
        cleanup_order   => 9e9,     # destroy as late as possible
        require         => [ 'Log::Any', 'Log::Any::Adapter' ],
        init            => sub {
            Log::Any::Adapter->set( 'Stderr' );
            # your rsyslog config could be here
            Log::Any->get_logger;
        };

    resource schema =>
        derived         => 1,        # merely a frontend to dbi
        require         => 'My::App::Schema',
        init            => sub {
            my $self = shift;
            return My::App::Schema->connect( sub { $self->dbh } );
        };

=head2 Resource with parameter

An useless but short example:

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use Resource::Silo;

    resource fibonacci =>
        argument            => qr(\d+),
        init                => sub {
            my ($self, $name, $arg) = @_;
            $arg <= 1 ? $arg
                : $self->fibonacci($arg-1) + $self->fibonacci($arg-2);
        };

    print silo->fibonacci(shift);

A more pragmatic one:

    package My::App;
    use Resource::Silo;

    resource redis_conn => sub {
        my $self = shift;
        require Redis;
        Redis->new( server => $self->config->{redis} );
    };

    my %known_namespaces = (
        lock    => 1,
        session => 1,
        user    => 1,
    );

    resource redis  =>
        argument        => sub { $known_namespaces{ $_ } },
        require         => 'Redis::Namespace',
        init            => sub {
            my ($self, $name, $ns) = @_;
            Redis::Namespace->new(
                redis     => $self->redis,
                namespace => $ns,
            );
        };

    # later in the code
    silo->redis;            # nope!
    silo->redis('session'); # get a prefixed namespace

=head3 Overriding in test files

    use Test::More;
    use My::App qw(silo);

    silo->ctl->override( dbh => $temp_sqlite_connection );
    silo->ctl->lock;

    my $stuff = My::App::Stuff->new();
    $stuff->frobnicate( ... );        # will only affect the sqlite instance

    $stuff->ping_partner_api();       # oops! the user_agent resource wasn't
                                      # overridden, so there'll be an exception

=head3 Fetching a dedicated resource instance

    use My::App qw(silo);
    my $dbh = silo->ctl->fresh('dbh');

    $dbh->begin_work;
    # Perform a Big Scary Update here
    # Any operations on $dbh won't interfere with normal usage
    #     of silo->dbh by other application classes.

=head1 SEE ALSO

L<Bread::Board> - a more mature IoC / DI framework.

=head1 ACKNOWLEDGEMENTS

=over

=item * This module was names after a building in the game
B<I<Heroes of Might and Magic III.>>

=item * This module was inspired in part by my work for
L<Cloudbeds|https://www.cloudbeds.com/>.
That was a great time and I had great coworkers!

=back

=head1 BUGS

This software is still in beta stage. Its interface is still evolving.

Version 0.09 brings a breaking change that forbids forward dependencies.

Please report bug reports and feature requests to
L<https://github.com/dallaylaen/resource-silo-p5/issues>
or via RT:
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Resource-Silo>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Resource::Silo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Resource-Silo>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Resource-Silo>

=item * Search CPAN

L<https://metacpan.org/release/Resource-Silo>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Konstantin Uvarin, C<< <khedin@gmail.com> >>

This program is free software.
You can redistribute it and/or modify it under the terms of either:
the GNU General Public License as published by the Free Software Foundation,
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Resource::Silo
