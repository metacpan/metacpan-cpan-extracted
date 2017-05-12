package MooX::PluginRoles::Base;

use Moo;

use Module::Pluggable::Object 4.9;
use Eval::Closure;
use Module::Runtime;
use namespace::clean;

my %SPEC_PLUGINS;

has base_class => (
    is       => 'ro',
    required => 1,
);

has classes => (
    is       => 'ro',
    required => 1,
);

has plugin_dir => (
    is       => 'ro',
    required => 1,
);

has role_dir => (
    is       => 'ro',
    required => 1,
);

has class_plugin_roles => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_class_plugin_roles',
);

sub _build_class_plugin_roles {
    my $self = shift;

    my %class_plugin_roles;

    my $base_class = $self->base_class;
    my $plugin_dir = $self->plugin_dir;
    my $role_dir   = $self->role_dir;

    my $search_path = join '::', $base_class, $plugin_dir, $role_dir;
    my $finder = Module::Pluggable::Object->new( search_path => $search_path );

    for my $found ( $finder->plugins ) {
        my ( $plugin, $class ) =
          $found =~ / ^ $search_path :: ([^:]+) :: (.*) $ /x;
        my $full_class = join '::', $base_class, $class;
        $class_plugin_roles{$full_class}->{$plugin} = $found;
    }

    return \%class_plugin_roles;
}

my $wrapper_code = <<'EOF';
use Moo::Role;
around new => sub {
    my ( $orig, $class, @args ) = @_;
    my ($caller) = caller(2);

    for my $client ( @{ $core->_clients } ) {
        if ( $caller =~ /^$client->{pkg}(?:$|::)/ ) {
            if ( my $new_class = $spec_plugins->{ $client->{spec} }->{$class} )
            {
                return $new_class->new(@args);
            }
            last;
        }
    }

    return $class->$orig(@args);
};
EOF

sub _wrap_class {
    my ( $self, $class ) = @_;

    Module::Runtime::use_module($class);

    my $wrapper_role = 'MooX::PluginRoles::Wrapped::' . $class;
    return if $class->does($wrapper_role);

    my $eval = eval_closure(
        source => [ 'sub {', "package $wrapper_role;", $wrapper_code, '}', ],
        environment => {
            '$core'         => \$self,
            '$spec_plugins' => \\%SPEC_PLUGINS,
        },
    );

    $eval->();

    Moo::Role->apply_roles_to_package( $class, $wrapper_role );

    return;
}

# create plugin roles for given plugins, and return spec and role mapping
sub _spec_plugins {
    my ( $self, $plugins ) = @_;

    my $spec = join '||', sort @$plugins;

    my $classes = $SPEC_PLUGINS{$spec};

    if ( !$classes ) {
        my $cpr = $self->class_plugin_roles;
        $classes = {};
        for my $class ( @{ $self->classes } ) {
            my $full_class = join '::', $self->base_class, $class;
            my $pr = $cpr->{$full_class}
              or next;
            $self->_wrap_class($full_class);    # idempotent
            my @roles = grep { defined } map { $pr->{$_} } @$plugins
              or next;
            $classes->{$full_class} =
              Moo::Role->create_class_with_roles( $full_class, @roles );
        }

        $SPEC_PLUGINS{$spec} = $classes;
    }
    return ( $spec, $classes );
}

has _clients => (
    is      => 'rw',
    default => sub { []; },
);

sub add_client {
    my ( $self, %client_args ) = @_;

    # FIXME - validate arguments
    my ( $spec, $classes ) = $self->_spec_plugins( $client_args{plugins} );

    my $client = {
        spec    => $spec,
        classes => $classes,
        pkg     => $client_args{pkg},
        file    => $client_args{file},
        line    => $client_args{line},
    };

    # store clients sorted by descending package length, so that searching
    # will find the longest match
    $self->_clients(
        [
            sort { length $b->{pkg} <=> length $a->{pkg} }
              ( @{ $self->_clients }, $client ),
        ]
    );

    return;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::PluginRoles::Base - find and apply plugin roles

=head1 SYNOPSIS

  # do not use directly

=head1 DESCRIPTION

C<MooX::PluginRoles::Base> implements the core PluginRoles logic. It
is used by C<MooX::PluginRoles>, and is not expected to be used directly.

=head2 Required Parameters

=over

=item base_class

Name of the package that is calling C<MooX::PluginRoles>

=item classes

ArrayRef of classes within the base namespace that can be extended

=item plugin_dir

Directory to search for plugins

=item role_dir

Directory within C<plugin_dir> to search for roles

=back

=head2 Attributes

=over

=item class_plugin_roles

Roles provided for each class by each available plugin,
hashed by extendable class and plugin

=back

=head2 Methods

=over

=item add_client

Add the given client to the list of clients using this base package.

Parameters:

=over

=item pkg

Name of client package

=item file

File of client package

=item line

Line number where client package included base class

=item plugins

ArrayRef of plugins to use

=back

=back

=head2 Internals

L<Module::Pluggable::Object> is used to search the plugin role
directories.

An anonymous class is created for each base class with each unique
set of plugins, using L<Eval::Closure>.

All clients are tracked, with their specified set of plugins, so that
the proper anonymous classes can be used when the base class constructors
are called within each client's namespace.

The base class constructors are wrapped by creating an anonymous role
wrapping C<new> method, using the caller's namespace to determine the
appropriate anonymous class to construct.

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016 Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
