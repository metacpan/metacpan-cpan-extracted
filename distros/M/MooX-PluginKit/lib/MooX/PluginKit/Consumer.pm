package MooX::PluginKit::Consumer;
use 5.008001;
use strictures 2;
our $VERSION = '0.06';

=head1 NAME

MooX::PluginKit::Consumer - Declare a class as a consumer of
PluginKit plugins.

=head1 SYNOPSIS

    package My::Class;
    use Moo;
    use MooX::PluginKit::Consumer;
    
    # Optional, defaults to just 'My::Class'.
    plugin_namespace 'My::Class::Plugin';
    
    has_pluggable_object some_object => (
        class => 'Some::Object',
    );
    
    my $object = My::Class->new(
        plugins => [...],
        some_object=>{...},
    );

=head1 DESCRIPTION

This module, when C<use>d, sets the callers base class to the
L<MooX::PluginKit::ConsumerBase> class, applies the
L<MooX::PluginKit::ConsumerRole> role to the caller, and
exports several candy functions (see L</CANDY>) into the
caller.

Some higher-level documentation about how to consume plugins can
be found at L<MooX::PluginKit/CONSUMING PLUGINS>.

=cut

use MooX::PluginKit::Core;
use MooX::PluginKit::ConsumerRole;
use Types::Standard -types;
use Types::Common::String -types;
use Class::Method::Modifiers qw( install_modifier );
use Module::Runtime qw( require_module );
use Scalar::Util qw( blessed );
use Carp qw( croak );
use Exporter qw();

use namespace::clean;

our @EXPORT = qw(
    plugin_namespace
    has_pluggable_object
    has_pluggable_class
);

sub import {
    {
        my $caller = (caller())[0];
        init_consumer( $caller );
        get_consumer_moo_extends( $caller )->('MooX::PluginKit::ConsumerBase');
        get_consumer_moo_with( $caller )->('MooX::PluginKit::ConsumerRole');
    }

    goto &Exporter::import;
}

=head1 CANDY

=head2 plugin_namespace

    plugin_namespace 'Location::Of::My::Plugins';

When the L<MooX::PluginKit::ConsumerRole/plugins> argument is set
the user may choose to pass relative plugins.  Setting this namespace
changes the default root namespace used to resolve these relative
plugin names to absolute ones.

This defaults to the package name of the class which uses this module.

Read more about this at L<MooX::PluginKit/Relative Plugin Namespace>.

=cut

sub plugin_namespace {
    my ($consumer) = caller();
    local $Carp::Internal{ (__PACKAGE__) } = 1;
    set_consumer_namespace( $consumer, @_ );
    return;
}

=head2 has_pluggable_object

    has_pluggable_object foo_bar => (
        class => 'Foo::Bar',
    );

This function acts like L<Moo/has> but adds a bunch of functionality,
making it easy to cascade the creation of objects which automatically
have applicable plugins applied to them, at run-time.

In the above C<foo_bar> example, the user of your class can then specify
the C<foo_bar> argument as a hashref.  This hashref will be used to
create an object of the C<Foo::Bar> class, but not until after any
applicable plugins set on the consumer class have been applied to it.

Documented below are the L<Moo/has> argument which are supported as well
as several custom arguments (like C<class>, above).

Note that you MUST set either L</class>, L<class_arg>, or L<class_builder>.

Read more about this at L<MooX::PluginKit/Object Attributes>.

=head3 Moo Arguments

This function only supports a subset of the arguments that L<Moo/has>
supports.  They are:

    builder
    default
    handles
    init_arg
    isa
    required
    weak_ref

=head3 class

Setting this to a class name does two things, 1) it declares the C<isa> on
the attributes to validate that the final value is an instance of the class
or a subclass of it, and 2) sets L</default_class> to it.

=head3 default_class

If no class is specified this will be the default class used.  A common idiom
of using both L</class> and this is:

    has_pluggable_object foo => (
        class         => 'Foo',
        default_class => 'Foo::SubClass',
    );

Meaning, in the above example, that the final object may be any subclass of the
C<Foo> class, but if no class is specified, it will be constructed from the
C<Foo::SubClass> class.

=head3 class_arg

If the class to be instantiated can be derived from the hashref argument to
this attribute then set this to the name of the key in the hashref to get the
class from.  Setting this to a C<1> is the same as setting it to C<class>.  So,
these are the same:

    has_pluggable_object foo => ( class_arg=>1 );
    has_pluggable_object foo => ( class_arg=>'class' );

Then when passing the hashref the class can be declared as part of it:

    my $thing = YourClass->new( foo=>{ class=>'Foo::Stuff', ... } );

=head3 class_builder

Set this to a method name or a code ref which will be used to build the
class name.  This sub will be called as a method and passed the args hashref
and is expected to return a class name.

If this is set to C<1> then the method name will be automatically generated
based on the attribute name.  So, these are identical:

    has_pluggable_object foo => ( class_builder=>1 );
    has_pluggable_object foo => ( class_builder=>'_foo_build_class' );

Then make the sub:

    sub _foo_build_class { my ($self, $args) = @_; ...; return $class }

Note that the class builder will not be called if L</class_arg> if set and
the user has specified a class argument.

=head3 class_namespace

Set this to allow the class to be relative.  This way if the class starts with
C<::> then this namespace will be automatically prefixed to it.

=head3 args_builder

Set this to a method name or a code ref which will be used to adjust the
hashref arguments before the object is constructed from them.  This sub will
be called as a method and passed the args hashref and is epxected to return
an args hashref.

If this is set to C<1> then the method name will be automatically generated
based on the attribute name.  So, these are identical:

    has_pluggable_object foo => ( args_builder=>1 );
    has_pluggable_object foo => ( args_builder=>'_foo_build_args' );

Then make the sub:

    sub _foo_build_args { my ($self, $args) = @_; ...; return $args }

=cut

sub has_pluggable_object {
    my ($name, %args) = @_;
    my $consumer_class = (caller())[0];
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    my $has = get_consumer_moo_has( $consumer_class );

    my $class_builder = _normalize_class_builder( $name, $consumer_class, %args );
    my $args_builder = _normalize_args_builder( $name, $consumer_class, %args );

    my $isa = delete $args{isa};
    my $class = delete $args{class};

    if (!defined $isa) {
        $isa = InstanceOf[ $class ] if defined $class;
        $isa ||= Object;
    }

    my $init_name = "_init_$name";
    my $init_isa = $isa | HashRef;

    $has->(
        $init_name,
        init_arg => $name,
        is       => 'ro',
        isa      => $init_isa,
        lazy     => 1,
        (
            map { $_ => $args{$_} }
            grep { exists $args{$_} }
            qw( default builder required weak_ref init_arg )
        ),
    );

    my $attr_isa = $isa;
    $attr_isa = $attr_isa | Undef if !$args{required};

    $has->(
        $name,
        init_arg => undef,
        is       => 'lazy',
        isa      => $attr_isa,
        (
            map { $_ => $args{$_} }
            grep { exists $args{$_} }
            qw( handles weak_ref )
        ),
        builder => _build_attr_builder(
            $init_name, $args_builder, $class_builder,
        ),
    );

    return;
}

# Avoid circular references by making this anonymous sub into a separate closure.
sub _build_attr_builder {
    my ($init_name, $args_builder, $class_builder) = @_;

    return sub{
        my ($self) = @_;

        my $args = $self->$init_name();
        return $args if ref($args) ne 'HASH';
        $args = $self->$args_builder({ %$args }) if defined $args_builder;

        my $class = $self->$class_builder( $args );

        return $self->class_new_with_plugins(
            $class, $args,
        );
    };
}

sub _normalize_class_builder {
    my ($name, $consumer_class, %args) = @_;

    my $class = delete $args{class};
    my $default_class = delete $args{default_class};
    my $class_arg = delete $args{class_arg};
    my $class_builder = delete $args{class_builder};
    my $class_namespace = delete $args{class_namespace};

    $default_class = $class if !defined $default_class;
    $class_arg = undef if defined($class_arg) and "$class_arg" eq '0';
    $class_builder = undef if defined($class_builder) and "$class_builder" eq '0';

    $class_arg = 'class' if defined($class_arg) and "$class_arg" eq '1';

    my $class_builder_sub;
    if (ref($class_builder) eq 'CODE') {
        $class_builder_sub = $class_builder;
        $class_builder = 1;
    }
    elsif (!defined $class_builder) {
        $class_builder_sub = sub{ undef };
        $class_builder = 1;
    }

    if (defined($class_builder) and "$class_builder" eq '1') {
        $class_builder = $name . '_build_class';
        $class_builder = '_' . $class_builder if $class_builder !~ m{^_};
    }

    if ($class_builder_sub) {
        install_modifier(
            $consumer_class, 'fresh',
            $class_builder => $class_builder_sub,
        );
    }

    install_modifier(
        $consumer_class, 'around',
        $class_builder => sub{
            my ($orig, $self, $args) = @_;

            my $class = defined($class_arg) ? $args->{$class_arg} : undef;
            $class = $self->$orig( $args ) if !defined $class;
            $class = $default_class if !defined $class;
            return undef if !defined $class;

            $class = $class_namespace . $class if $class =~ m{^::};
            return $class;
        },
    );

    return $class_builder;
}

sub _normalize_args_builder {
    my ($name, $consumer_class, %args) = @_;

    my $args_builder = delete $args{args_builder};

    $args_builder = undef if defined($args_builder) and "$args_builder" eq '0';

    my $args_builder_sub;

    if (ref($args_builder) eq 'CODE') {
        $args_builder_sub = $args_builder;
        $args_builder = 1;
    }

    if (defined($args_builder) and "$args_builder" eq '1') {
        $args_builder = $name . '_build_args';
        $args_builder = '_' . $args_builder if $args_builder !~ m{^_};
    }

    if ($args_builder_sub) {
        install_modifier(
            $consumer_class, 'fresh',
            $args_builder => $args_builder_sub,
        );
    }

    return $args_builder;
}

=head2 has_pluggable_class

    has_pluggable_class foo_bar_class => (
        default => 'Foo::Bar',
    );

This function acts like L<Moo/has> but adds a bunch of functionality,
making it easy to refer to a class that gets plugins applied to it
at run-time.

In the above C<foo_bar_class> example, the user of your class can then specify
the C<foo_bar_class> argument, if they wish, and the class they pass in will
have any relevant plugins applied to it.

This function only supports a subset of the arguments that L<Moo/has>
supports.  They are:

    builder
    default
    init_arg
    isa
    required

=cut

sub has_pluggable_class {
    my ($name, %args) = @_;
    my $consumer_class = (caller())[0];
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    my $has = get_consumer_moo_has( $consumer_class );

    my $init_name = "_init_$name";

    $has->(
        $init_name,
        init_arg => $name,
        is       => 'ro',
        isa      => NonEmptySimpleStr,
        lazy     => 1,
        (
            map { $_ => $args{$_} }
            grep { exists $args{$_} }
            qw( default builder required init_arg )
        ),
    );

    my $isa = $args{isa} || ClassName;
    $isa = $isa | Undef if !$args{required};

    $has->(
        $name,
        init_arg => undef,
        is       => 'lazy',
        isa      => $isa,
        builder => _build_class_attr_builder(
            $init_name,
        ),
    );

    return;
}

sub _build_class_attr_builder {
    my ($init_name) = @_;

    return sub{
        my ($self) = @_;

        my $class = $self->$init_name();

        require_module $class if !$class->can('new');

        return $self->plugin_factory->build_class( $class );
    };
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHORS> and L<MooX::PluginKit/LICENSE>.

=cut

