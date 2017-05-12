package Orochi;
use Moose;
use Data::Visitor::Callback;
use Module::Pluggable::Object;
use Orochi::Injection::BindValue;
use Orochi::Injection::Constructor;
use Orochi::Injection::Literal;
use Path::Router;
use Scalar::Util qw(refaddr);
use namespace::clean -except => qw(meta);

use constant DEBUG => ($ENV{OROCHI_DEBUG} || 0);

our $VERSION = '0.00010';

has prefix => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_prefix',
);

has router => (
    is         => 'ro',
    isa        => 'Path::Router',
    lazy_build => 1,
);

has _expander => (
    is         => 'ro',
    isa        => 'Data::Visitor',
    lazy_build => 1,
);

has _expanded_values => ( # cache
    is         => 'ro',
    isa        => 'HashRef',
    default    => sub { {} }
);

sub _build_router {
    return Path::Router->new();
}

sub _build__expander {
    my $self = shift;
    return Data::Visitor::Callback->new(
        object_final => sub {
            my ($visitor, $object) = @_;
            my $ret  = $object;
            my $DOES = $object->can('DOES');
            if ($DOES && $DOES->($object, 'Orochi::Injection')) {
                $ret = $object->expand( $self );
                $_ = $ret;
            }
            return $ret;
        }
    )
}

our $Indent = -1;
sub _debug { # don't use this, ok?
    my $fmt = shift;
    my $indent = '   ' x ($Indent >= 0 ? $Indent : 0);
    printf STDERR ("[Orochi]: $indent$fmt\n", @_);
}

sub get {
    my ($self, $path) = @_;

    if (DEBUG()) {
        Orochi::_debug("Orochi: fetching '%s'", $path);
    }
    local $Indent = $Indent + 1;

    $path = $self->mangle_path( $path );

    my ($cached, $matched, $value);
    if (exists $self->_expanded_values->{$path}) {
        $cached = 1;
    }

    if ($cached) {
        $value = $self->_expanded_values->{$path};
    } else {
        $matched = $self->router->match( $path );
        if ( $matched ) {
            eval {
                $value = $matched->target->expand( $self );
            };
            if ($@) {
                die "An error occurred while attempting to expand for $path: $@";
            }
            $self->_expanded_values->{$path} = $value;
        }
    }

    if ($matched && (my $post_expand = $matched->target->can('post_expand'))) {
        $post_expand->( $matched->target, $self, $value );
    }

    if (DEBUG()) {
        Orochi::_debug("Orochi: '%s' resolves to '%s' (MATCH: %s, CACHE: %s)", $path, $value || '(null)', $matched ? "YES" : "NO", $cached ? "YES" : "NO");
    }
    return $value;
}

sub mangle_path {
    my ($self, $path) = @_;
    if ( my $prefix = $self->prefix ) {
        if ($path !~ /^\//) {
            if ($prefix !~ /\/$/) {
                $prefix .= '/';
            }
            $path = $prefix . $path;
        }
    }
    return $path;
}

sub inject_from_config {
    my ($self, $config) = @_;

    if (my $injections = $config->{injections}) {
        while ( my($name, $value) = each %$injections ) {
            if (! blessed $value ) {
                $value = Orochi::Injection::Literal->new( value => $value );
            }
            $self->inject($name, $value);
        }
    }

    if (my $classes = $config->{classes})  {
        foreach my $class ( @$classes ) {
            $self->inject_class( $class );
        }
    }

    if (my $namespaces = $self->{namespaces}) {
        foreach my $namespace (@$namespaces) {
            $self->inject_namespace( $namespace );
        }
    }
}
        
sub inject {
    my ($self, $path, $injection) = @_;

    confess "no path specified" unless $path;

    $path = $self->mangle_path($path);

    if (DEBUG()) {
        Orochi::_debug("Injecting %s", $path);
    }
    $self->router->insert_route($path => (target => $injection));
}

sub bind_value {
    my ($self, $path) = @_;

    my $value;
    if (blessed $path) {
        if (! $path->isa('Orochi::Injection::BindValue')) {
            confess "inject_vind_value requires a Orochi::Injection::BindValue object";
        }
        $value = $path;
    } else {
        $value = Orochi::Injection::BindValue->new(bind_to => $path);
    }
    return $value;
}

sub inject_constructor {
    my ($self, $path, @args) = @_;

    my $injection;
    if (@args == 1) {
        if (! blessed $args[0] || ! $args[0]->isa('Orochi::Injection::Constructor') ) {
            confess "inject_constructor requires a Orochi::Injection::Constructor object";
        }
        $injection = $args[0];
    } else {
        $injection = Orochi::Injection::Constructor->new(@args);
    }
    $self->inject($path, $injection);
    return $injection;
}

sub inject_literal {
    my ($self, $path, @args) = @_;

    my $injection;
    if (@args == 1) {
        if (blessed $args[0] && $args[0]->isa('Orochi::Injection::Literal') ) {
            $injection = $args[0];
        }
    };

    if (! $injection) {
        $injection = Orochi::Injection::Literal->new(@args);
    }
    $self->inject($path, $injection);
    return $injection;
}

sub inject_class {
    my ($self, $class) = @_;

    if (DEBUG()) {
        Orochi::_debug("inject_class( $class )");
    }

    if (! Class::MOP::is_class_loaded($class)) {
        Class::MOP::load_class($class);
    }

    my $meta;

    # Find the first Orochi meta class in the inheritance tree
    if ($class->can('meta') && $class->meta->can('linearized_isa')) {
        foreach my $a_class ( $class->meta->linearized_isa ) {
            my $foo;
            $foo = Moose::Util::find_meta($a_class);
            if (Moose::Util::does_role($foo, 'MooseX::Orochi::Meta::Class')) {
                if ($foo->bind_path) {
                    $meta = $foo;
                    last;
                }
            }
        }
    }

    if (! $meta) {
        return;
    }

    if (! $meta->bind_path ) {
        Carp::cluck( "No bind_path specified for $class. Did you specify it via bind_constructor?" );
        return;
    } 

    if (! $meta->bind_injection ) {
        Carp::cluck( "No bind_injection specified for $class. Did you specify it via bind_constructor?" );
        return;
    } 

    # if we're using that of our parent class, then we should clone the
    # injection object. if not, just create our own
    my $new_injection = $meta->bind_injection->meta->clone_object( $meta->bind_injection );
    $new_injection->class( $class );
    $self->inject( $meta->bind_path, $new_injection );

    my $injections = $meta->injections;
    while ( my($path, $injection) = each %$injections) {
        $self->inject( $path, $injection );
    }
}

sub inject_namespace {
    my ($self, $namespace) = @_;
    my $mpo = Module::Pluggable::Object->new(
        search_path => $namespace,
    );
    $self->inject_class($_) for $mpo->plugins;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Orochi - A DI Container For Perl

=head1 SYNOPSIS

    use Orochi;

    my $c = Orochi->new();
    $c->inject_constructor('/myapp/foo' => (
        class  => 'SomeClass',
        args   => {
            bar => $c->bind_value('/myapp/bar')
        }
    );
    $c->inject_literal( '/myapp/bar' => [ 'a', 'b', 'c' ] );

=head1 BEFORE YOU USE THIS MODULE

WARNING: I'd rather use Bread::Board, but I have a need for a particular
kind of DI I<NOW>, and Bread::Board currently doesn't have those features.
Therefore here's my version of it.

If/When Bread::Board becomes suitable for my needs, this module may simply 
be replaced / deleted from CPAN. You've been warned.

=head1 DESCRIPTION

Orochi is a simple Dependency Injection -ish system. Orochi in itself is just
a big Key/Value store, with a bit of runtime lazy expansion / instantiation of
objects mixed in.

=head1 USAGE WITH MOOSE CLASSES

This is probably how you'd want to use this module.
Please see L<MooseX::Orochi|MooseX::Orochi> for details

=head1 METHODS

=head2 new(%args)

You may specify the following arguments:

=over 4

=item prefix

If specified, adds a prefix to the given path through C<mangle_path()>.

=back

=head2 get($path)

Retrieves the value associated with the given $path. If the value needs to be
expanded (i.e., create an object), then it will be done automatically.

=head2 mangle_path($path)

Fixes the given path, if necessary. This adds the prefix specified in the
Orochi constructor, for example

=head2 inject($path, $injection_object)

Injects a Orochi::Injection object.

=head2 bind_value($path) or bind_value(\@paths)

Creates a BindValue injection, which is a lazy evaluation based on a 
Orochi key.

If given a list, will cascade through the given paths until one returns a
defined value

=head2 inject_constructor($path => %injection_args)

Injects an object constructor. Setter injection also uses this

=head2 inject_literal($path => %injection_args)

Injects a literal value.

=head2 inject_class($class)

Injects a MooseX::Orochi based class. The class that is being injected
does NOT have to use MooseX::Orochi, as long as one of the meta classes in the
inheritance hierarchy does so.

=head2 inject_namespace($namespace)

Looks for modules in the given namespace, and calls inject_class on each class.

=head1 SEE ALSO

L<Bread::Board|Bread::Board>

=head1 TODO

Documentation. Samples. Tests.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut