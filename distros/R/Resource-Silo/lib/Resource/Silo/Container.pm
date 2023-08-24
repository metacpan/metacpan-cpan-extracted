package Resource::Silo::Container;

use strict;
use warnings;
our $VERSION = '0.08';

=head1 NAME

Resource::Silo::Container - base resource container class for L<Resource::Silo>.

=head1 DESCRIPTION

L<Resource::Silo> isolates resources by storing them
inside a container object.

The methods of such an object are generated on the fly and stored either
in a special virtual package, or the calling module.

This class provides some common functionality that allows to access resources,
as well as a doorway into a fine-grained control interface.

=head1 METHODS

=cut

use Carp;
use Scalar::Util qw( blessed refaddr reftype weaken );
use Module::Load qw( load );

my $ID_REX = qr/^[a-z][a-z_0-9]*$/i;

=head2 new( resource => $override, ... )

Create a new container (also available as C<silo-E<gt>new>).

If arguments are given, they will be passed to the
L</override> method (see below).

=cut

# NOTE to the editor. As we want to stay compatible with Moo/Moose,
# please make sure all internal fields start with a hyphen ("-").

my %active_instances;
my $not_once = \%Resource::Silo::metadata; # avoid once warning

sub new {
    my $class = shift;
    $class = ref $class if blessed $class;

    my $spec = $Resource::Silo::metadata{$class}
        or croak "Failed to locate \$Resource::Silo::metadata for class $class";

    my $self = bless {
        -pid  => $$,
        -spec => $spec,
    }, $class;
    if (@_) {
        croak "Odd number of additional arguments in new()"
            if @_ % 2;
        $self->_override_resources({ @_ });
    };
    $active_instances{ refaddr $self } = $self;
    weaken $active_instances{ refaddr $self };
    return $self;
};

sub DESTROY {
    my $self = shift;
    delete $active_instances{ refaddr $self };
    $self->ctl->cleanup;
};

# As container instances inside the silo() function will be available forever,
# we MUST enforce freeing the resources before program ends
END {
    foreach my $container (values %active_instances) {
        next unless $container;
        $container->ctl->cleanup;
    };
};

=head2 C<ctl>

As the container class may contain arbitrary resource names and
user-defined methods to boot, we intend to declare as few public methods
as possible.

Instead, we create a facade object that has access to container's internals
and can perform fine-grained management operations.
See L</CONTROL INTERFACE> below.

Example:

    # Somewhere in a test file
    use Test::More;
    use My::App qw(silo);

    silo->ctl->override( dbh => $fake_database_connection );
    silo->ctl->lock; # forbid instantiating new resources

Returns a facade object.

B<NOTE> Such object contains a weak reference to the parent object
and thus must not be saved anywhere, lest you be surprised.
Use it and discard immediately.

=cut

sub ctl {
    my $self = shift;
    my $facade = bless \$self, 'Resource::Silo::Container::Dashboard';
    weaken $$facade;
    confess "Attempt to close over nonexistent value"
        unless $$facade;
    return $facade;
};

# Instantiate resource $name with argument $argument.
# This is what a silo->resource_name calls after checking the cache.
sub _instantiate_resource {
    my ($self, $name, $arg) = @_;

    croak "Illegal resource name '$name'"
        unless $name =~ $ID_REX;

    my $spec = $self->{-spec}{resource}{$name};
    $arg //= '';

    croak "Attempting to fetch nonexistent resource '$name'"
        unless $spec;
    croak "Argument for resource '$name' must be a scalar"
        if ref $arg;
    croak "Illegal argument for resource '$name': '$arg'"
        unless $spec->{argument}->($arg);

    croak "Attempting to initialize resource '$name' during cleanup"
        if $self->{-cleanup};
    croak "Attempting to initialize resource '$name' in locked mode"
        if $self->{-locked}
            and !$spec->{derived}
            and !$self->{-override}{$name};

    croak "Attempting to fetch unexpected dependency '$name'"
        if ($self->{-allow} && !$self->{-allow}{$name});
    local $self->{-allow} = $spec->{allowdeps};

    # Detect circular dependencies
    my $key = $name . (length $arg ? "\@$arg" : '');
    if ($self->{-pending}{$key}) {
        my $loop = join ', ', sort keys %{ $self->{-pending} };
        croak "Circular dependency detected for resource $key: {$loop}";
    };
    local $self->{-pending}{$key} = 1;

    foreach my $mod (@{ $spec->{require} }) {
        eval { load $mod; 1 }
            or croak "resource '$name': failed to load '$mod': $@";
    };
    ($self->{-override}{$name} // $spec->{init})->($self, $name, $arg)
        // croak "Fetching resource '$key' failed for no apparent reason";
};

# use instead of delete $self->{-cache}{$name}
sub _cleanup_resource {
    my ($self, $name, @list) = @_;

    # TODO Do we need to validate arguments here?
    my $spec = $self->{-spec}{resource}{$name};

    my $action;
    if (!$self->{-override}{$name}) {
        # 1) skip resources that have overrides
        # 2) if we're in "no pid" mode, use fork_cleanup if available
        $action = $self->{-pid} != $$
            && $spec->{fork_cleanup}
            || $spec->{cleanup};
    };
    my $known = $self->{-cache}{$name};

    @list = keys %$known
        unless @list;

    foreach my $arg (@list) {
        $arg //= '';
        next unless defined $known->{$arg};
        $action->($known->{$arg}) if $action;
        delete $known->{$arg};
    };
};

# We must create resource accessors in this package
#   so that errors get attributed correctly
#   (+ This way no other classes need to know our internal structure)
sub _make_resource_accessor {
    my ($name, $spec) = @_;

    if ($spec->{ignore_cache}) {
        return sub {
            my ($self, $arg) = @_;
            return $self->_instantiate_resource($name, $arg);
        };
    };

    return sub {
        my ($self, $arg) = @_;

        # If there was a fork, flush cache
        if ($self->{-pid} != $$) {
            $self->ctl->cleanup;
            $self->{-pid} = $$;
        };

        croak "Attempting to fetch unexpected dependency '$name'"
            if ($self->{-allow} && !$self->{-allow}{$name});

        # Stringify $arg ASAP, we'll validate it inside _instantiate_resource().
        # The cache entry for an invalid argument will never get populated.
        my $key = defined $arg && !ref $arg ? $arg : '';
        $self->{-cache}{$name}{$key} //= $self->_instantiate_resource($name, $arg);
    };
};

sub _check_overrides {
    my ($self, $subst) = @_;

    my $known = $self->{-spec}{resource};
    my @bad = grep { !$known->{$_} } keys %$subst;
    croak "Attempt to override unknown resource(s): "
        .join ", ", map { "'$_'" } @bad
            if @bad;
};

sub _override_resources {
    my ($self, $subst) = @_;

    my $known = $self->{-spec}{resource};

    foreach my $name (keys %$subst) {
        # Just skip over unknown resources if we're in constructor
        next unless $known->{$name};
        my $init = $subst->{$name};

        # Finalize existing values in cache, just in case
        # BEFORE setting up override
        $self->_cleanup_resource($name);

        if (defined $init) {
            $self->{-override}{$name} = (reftype $init // '') eq 'CODE'
                ? $init
                : sub { $init };
        } else {
            delete $self->{-override}{$name};
        };
    };
}

=head1 CONTROL INTERFACE

The below methods are all accessible via
C<$container-E<gt>ctl-E<gt>$method_name>.

=cut

# We're declaring a different package in the same file because
# 1) it must have access to the internals anyway and
# 2) we want to keep the documentation close to the implementation.
package
    Resource::Silo::Container::Dashboard;

use Carp;
use Scalar::Util qw( reftype );

=head2 override( %substitutes )

Provide a set of overrides for some of the resources.

This can be used e.g. in tests to mock certain external facilities.

%substitutes values are interpreted as follows:

=over

=item * C<sub { ... }> - use this code instead of the resource's C<init>;

=item * C<undef> - erase the override for given resource;

=item * anything else is coerced into an initializer:
$value => sub { return $value }.

=back

Setting overrides has the side effect of clearing cache
for the affected resources.

=cut

sub override {
    my ($self, %subst) = @_;

    $$self->_check_overrides(\%subst);
    $$self->_override_resources(\%subst);

    return $self;
}

=head2 lock

Forbid initializing new resources.

The cached ones instantiated so far, the ones that have been overridden,
and the ones with the C<derived> flag will still be returned.

=cut

sub lock {
    my ($self) = @_;
    $$self->{-locked} = 1;
    return $self;
};

=head2 unlock

Remove the lock set by C<lock>.

=cut

sub unlock {
    my $self = shift;
    delete $$self->{-locked};
    return $self;
};

=head2 preload()

Try loading all the resources that have C<preload> flag set.

May be useful if e.g. a server-side application is starting and must
check its database connection(s) before it starts handling any clients.

In addition, self-check will be called and all declared C<require>'d
modules will be loaded, even if they are not required by preloaded resources.

=cut

sub preload {
    my $self = shift;
    # TODO allow specifying resources to load
    #      but first come up with a way to specify arguments, too.

    my $meta = $$self->{-spec};

    $meta->self_check;

    my $list = $meta->{preload};
    for my $name (@$list) {
        my $unused = $$self->$name;
    };
    return $self;
};

=head2 cleanup

Cleanup all resources.
Once the cleanup is started, no more resources can be created,
and trying to do so will result in exception.
Typically only useful for destruction.

=cut

sub cleanup {
    my $self = ${ $_[0] };
    local $self->{-cleanup} = 1; # This is stronger than lock.

    # NOTE Be careful! cleanup must never ever die!

    my $spec = $self->{-spec}{resource};
    my @order = sort {
        $spec->{$a}{cleanup_order} <=> $spec->{$b}{cleanup_order};
    } keys %{ $self->{-cache} };

    foreach my $name (@order) {
        local $@; # don't pollute $@ if we're in destructor after an exception
        eval {
            # We cannot afford to die here as if we do
            #    a resource that causes exceptions in cleanup
            #    would be stuck in cache forever
            $self->_cleanup_resource($name);
            1;
        } or do {
            my $err = $@;
            Carp::cluck "Failed to cleanup resource '$name', but trying to continue: $err";
        };
    };

    delete $self->{-cache};
    return $_[0];
};

=head2 fresh( $resource_name [, $argument ] )

Instantiate resource and return it, ignoring cached value, if any.
This may be useful if the resource's state is going to be modified
in a manner incompatible with its other consumers within the same process.

E.g. performing a Big Evil SQL Transaction while other parts of the application
are happily using L<DBIx::Class>.

B<NOTE> Use with caution.
Resorting to this method frequently may be a sign of a broader
architectural problem.

=cut

sub fresh {
    return ${+shift}->_instantiate_resource(@_);
};

=head2 meta

Get resource metadata object (a L<Resource::Silo::Metadata>).

=cut

sub meta {
    return ${+shift}->{-spec};
};

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023, Konstantin Uvarin, C<< <khedin@gmail.com> >>

This program is free software.
You can redistribute it and/or modify it under the terms of either:
the GNU General Public License as published by the Free Software Foundation,
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
