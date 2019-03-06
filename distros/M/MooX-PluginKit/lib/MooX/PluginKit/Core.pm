package MooX::PluginKit::Core;
use 5.008001;
use strictures 2;
our $VERSION = '0.06';

=head1 NAME

MooX::PluginKit::Core - The PluginKit internal guts.

=head2 DESCRIPTION

This module tracks metadata about consumers and plugins as well as
providing much of the underlying logic behind the other PluginKit
modules.

Currently this module is not documented because it is not intended
to be used directly.  This may change.

=cut

use Carp qw( croak );
use Moo::Role qw();
use Module::Runtime qw( require_module is_module_name );

require UNIVERSAL::DOES
    unless defined &UNIVERSAL::DOES;

use namespace::clean;

use Exporter qw( import );

our @EXPORT = qw(
    init_plugin
    is_plugin
    resolve_plugin
    does_plugin_apply
    find_applicable_plugins
    build_class_with_plugins
    set_plugin_applies_to
    get_plugin_applies_to
    set_plugin_includes
    get_plugin_includes
    init_consumer
    is_consumer
    get_consumer_moo_extends
    get_consumer_moo_with
    get_consumer_moo_has
    set_consumer_namespace
    get_consumer_namespace
);

my %plugins; # Metadata about roles.
my %consumers; # Metadata about classes.

sub init_plugin {
    my ($plugin_name) = @_;
    $plugins{$plugin_name} = {};
    return;
}

sub is_plugin {
    my ($plugin_name) = @_;
    return $plugins{$plugin_name} ? 1 : 0;
}

sub resolve_plugin {
    my ($plugin_name, $namespace) = @_;
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    croak "An undefined plugin name cannot be resolved"
        if !defined $plugin_name;

    if ($plugin_name =~ m{^::}) {
        croak "The relative plugin $plugin_name cannot be made absolute without a namespace"
            if !defined $namespace;

        $plugin_name = $namespace . $plugin_name;
    }

    croak "The plugin $plugin_name does not appear to be a valid module name"
        if !is_module_name( $plugin_name );

    return $plugin_name if exists $plugins{$plugin_name};

    # Go ahead and shortcircuit here as Moo::Role does not add inlined packages into
    # %INC so the require_module() call could fail in some cases if the module has already
    # been setup but isn't on the filesystem in the expected locations.
    return $plugin_name if Moo::Role->is_role( $plugin_name );

    require_module( $plugin_name );

    croak "Plugin $plugin_name does not appear to be a Moo::Role"
        if !Moo::Role->is_role( $plugin_name );

    return $plugin_name;
}

sub does_plugin_apply {
    my ($plugin_name, $class) = @_;

    my $sub = get_plugin_applies_to( $plugin_name );

    return $sub->( $class ) ? 1 : 0;
}

sub find_applicable_plugins {
    my ($class, @plugins) = @_;

    my @final_plugins;
    while (@plugins) {
        my $plugin = shift( @plugins );
        next if !does_plugin_apply( $plugin, $class );
        push @final_plugins, $plugin;
        unshift @plugins, @{ get_plugin_includes( $plugin ) };
    }

    return \@final_plugins;
}

sub build_class_with_plugins {
    my ($base_class, @plugins) = @_;

    my $roles = find_applicable_plugins( $base_class, @plugins );
    return $base_class if !@$roles;

    return Moo::Role->create_class_with_roles(
        $base_class,
        @$roles,
    );
}

sub set_plugin_applies_to {
    my ($plugin_name, $sub) = @_;
    my $plugin = $plugins{$plugin_name};
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    croak "The applies_to for the $plugin_name plugin has already been set"
        if exists $plugin->{applies_to};

    if (!ref $sub) {
        my $package = $sub;
        $sub = sub{ $_[0]->isa( $package ) or $_[0]->DOES( $package ) };
    }
    elsif (ref($sub) eq 'ARRAY') {
        my $methods = $sub;
        $sub = sub{
            foreach my $method (@$methods) {
                next if $_[0]->can($method);
                return 0;
            }
            return 1;
        };
    }
    elsif (ref($sub) eq 'Regexp') {
        my $re = $sub;
        $sub = sub{
            return ($_[0] =~ $re) ? 1 : 0;
        };
    }

    croak 'Plugin applies_to must be a class name, arrayref of methods, regex, or code ref'
        if ref($sub) ne 'CODE';

    $plugin->{applies_to} = $sub;

    return;
}

sub get_plugin_applies_to {
    my ($plugin_name) = @_;
    my $plugin = $plugins{$plugin_name};

    return $plugin->{applies_to} || sub{ 1 };
}

sub set_plugin_includes {
    my ($plugin_name, @includes) = @_;
    my $plugin = $plugins{$plugin_name};
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    croak "The includes for the $plugin_name plugin has already been set"
        if exists $plugin->{includes};

    $plugin->{includes} = [
        map { resolve_plugin($_, $plugin_name) }
        @includes
    ];

    return;
}

sub get_plugin_includes {
    my ($plugin_name) = @_;
    my $plugin = $plugins{$plugin_name};

    return $plugin->{includes} || [];
}

sub init_consumer {
    my ($consumer_name) = @_;
    my $consumer = $consumers{$consumer_name} = {};
    $consumer->{moo_extends} = $consumer_name->can('extends');
    $consumer->{moo_with} = $consumer_name->can('with');
    $consumer->{moo_has}  = $consumer_name->can('has');
    return;
}

sub is_consumer {
    my ($consumer_name) = @_;
    return $consumers{$consumer_name} ? 1 : 0;
}

sub get_consumer_moo_extends {
    my ($consumer_name) = @_;
    my $consumer = $consumers{$consumer_name};
    return $consumer->{moo_extends};
}

sub get_consumer_moo_with {
    my ($consumer_name) = @_;
    my $consumer = $consumers{$consumer_name};
    return $consumer->{moo_with};
}

sub get_consumer_moo_has {
    my ($consumer_name) = @_;
    my $consumer = $consumers{$consumer_name};
    return $consumer->{moo_has};
}

sub set_consumer_namespace {
    my ($consumer_name, $namespace) = @_;
    my $consumer = $consumers{$consumer_name};
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    croak "The plugin namespace for $consumer has already been set"
        if exists $consumer->{namespace};

    croak "An undefined plugin namespace cannot be set"
        if !defined $namespace;

    croak "The plugin namespace $namespace does not appear to be a valid module name"
        if !is_module_name( $namespace );

    $consumer->{namespace} = $namespace;

    return;
}

sub get_consumer_namespace {
    my ($consumer_name) = @_;
    my $consumer = $consumers{$consumer_name};
    local $Carp::Internal{ (__PACKAGE__) } = 1;

    return $consumer->{namespace} || $consumer_name;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHORS> and L<MooX::PluginKit/LICENSE>.

=cut

