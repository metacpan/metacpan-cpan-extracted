package MooX::PluginRoles;

use strict;
use warnings;
use 5.008_005;

our $VERSION = '0.02';

use MooX::PluginRoles::Base;
use Eval::Closure;
use namespace::clean;

my $DEFAULT_PLUGIN_DIR = 'Plugins';
my $DEFAULT_ROLE_DIR   = 'Roles';

my %PLUGIN_CORES;

sub _register_plugins {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my %args = @_;

    my $core = $PLUGIN_CORES{ $args{base_class} } ||=
      MooX::PluginRoles::Base->new(
        base_class => $args{base_class},
        classes    => $args{classes},
        plugin_dir => $args{plugin_dir},
        role_dir   => $args{role_dir},
      );

    $core->add_client(
        pkg     => $args{client_pkg},
        file    => $args{client_file},
        line    => $args{client_line},
        plugins => $args{plugins},
    );

    return;
}

sub import {
    my ( $me, %opts ) = @_;

    my ($base_class) = caller;

    {
        my $old_import = $base_class->can('import');

        no strict 'refs';          ## no critic (ProhibitNoStrict)
        no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

        my $code = <<'EOF';
        sub {
            # FIXME - validate args
            #   base options:
            #     plugin_dir (valid package name part)
            #     plugin_role_dir (valid package name part)
            #     plugin_classes (arrayref of >0 class names)
            #   client options:
            #     plugins (arrayref of 0 or more plugin path names)
            my $caller_opts = { @_[ 1 .. $#_ ] };
            $old_import->(@_)
              if $old_import;
            my ( $client_pkg, $client_file, $client_line ) = caller;
            MooX::PluginRoles::_register_plugins(
                %$caller_opts,
                base_class  => $base_class,
                client_pkg  => $client_pkg,
                client_file => $client_file,
                client_line => $client_line,
                plugin_dir  => $opts{plugin_dir} || $default_plugin_dir,
                role_dir    => $opts{plugin_role_dir} || $default_role_dir,
                plugins     => $caller_opts->{plugins} || [],
                classes     => $opts{plugin_classes} || [],
            );
        }
EOF
        *{"${base_class}::import"} = eval_closure(
            source      => $code,
            environment => {
                '$base_class'         => \$base_class,
                '$old_import'         => \$old_import,
                '%opts'               => \%opts,
                '$default_plugin_dir' => \$DEFAULT_PLUGIN_DIR,
                '$default_role_dir'   => \$DEFAULT_ROLE_DIR,
            }
        );
    }

    return;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::PluginRoles - add plugins via sets of Moo roles

=head1 SYNOPSIS

  # base class that accepts plugins
  package MyPkg;

  use Moo;                  # optional
  use MooX::PluginRoles (
    plugin_dir      => 'Plugins',   # default
    plugin_role_dir => 'Roles',     # default
    plugin_classes  => [ 'Foo' ],   # must be Moo classes
  );

  # class within MyPkg that can be extended by plugin roles
  package MyPkg::Foo;
  use Moo;

  # class that is excluded from extending with plugin roles
  package MyPkg::NotMe;
  use Moo;

  # Readable plugin - provides role with read method for Foo class
  package MyPkg::Plugins::Readable::Roles::Foo;
  use Moo::Role;

  sub read { ...  }

  # Writeable plugin - provides role with write method for Foo class
  package MyPkg::Plugins::Writeable::Roles::Foo;
  use Moo::Role;

  sub write { ...  }

  # client using just the Readable plugin
  package ClientReadOnly;
  use MyPkg plugins => ['Readable'];

  $p = MyPkg->new();
  $p->read;             # succeeds

  # client using both Readable and Writeable plugins
  package ClientReadWrite;
  use MyPkg plugins => ['Readable', 'Writeable'];

  $p = MyPkg->new;
  $p->read;             # succeeds
  $p->write('quux');    # succeeds

=head1 STATUS

This is an alpha release of C<MooX::PluginRoles>. The API is simple
enough that it is unlikely to change much, but one never knows until
users start testing the edge cases.

The implementation works well, but is still a bit rough. It needs
more work to detect and handle error cases better, and likely needs
optimization as well.

=head1 DESCRIPTION

C<MooX::PluginRoles> is a plugin framework that allows plugins to be
specified as sets of Moo roles that are applied to the Moo classes in
the calling namespace.

Within the Moo* frameworks, it is simple to extend the behavior of a
single class by applying one or more roles. C<MooX::PluginRoles> extends
that concept to a complete namespace.

=head2 Nomenclature

=over

=item base class

The base class is the class that uses C<MooX::PluginRoles> to provide
plugins. It specifies where to find the plugins (C<plugin_dir> and
C<plugin_role_dir>), and which classes may be extended (C<plugin_classes>)

=item client package

The client package is the package that uses the base class, and
specifies which plugins should be used (C<plugins>).

=item extendable classes

The extendable classes are the classes listed by the base class in
C<plugin_classes>. These classes must be in the namespace of the base
class, and plugin roles will be applied to them.

=item plugin

A plugin provides roles that will be applied to the extendable classes.

=back

Each plugin creates the needed roles in a hierarchy that matches the
base class hierarchy. For instance, if a client uses the base class
C<MyBase> with the plugin C<P>, and C<MyBase> lists C<C> as an
extendable class, then the plugin role C<MyBase::Plugins::P::Roles::C>
will be applied to the extendable class C<MyBase::C>.

  package MyBase;
  use MooX::PluginRoles ( plugin_classes => ['C'] );

  package MyBase::C;
  has name => ( is => 'ro' );

  # role within P plugin for MyBase::C class
  package MyBase::Plugins::P::Roles::C;
  has old_name => ( is => 'ro' );

  package MyClient;
  use MyBase ( plugins => ['MyP'] );

  $c = MyBase::C->new();
  say $c->name;         # succeeds
  say $c->old_name;     # succeeds

At this point, when C<< MyBase::C->new() >> is called, and the calling
package starts with C<MyClient::>, the constructor will return an
instance of an anonymous class created by applying the C<P> plugin
role to the C<C> extendable class.

A plugin is free to create additional packages as needed, as long
as they are not in the C<::Roles> directory.

=head2 Parameters in base class

=over

=item plugin_dir

Directory that contains the plugins. Defaults to C<"Plugins">

=item plugin_role_dir

Directory within C<plugin_dir> that contains the roles. Defaults to
C<"Roles">

=item plugin_classes

Classes within the base class namespace that may be extended by
plugin roles, as an ArrayRef of class names relative to the
base class's namespace.

NOTE: Defaults to an empty list, so no classes will be extended
unless they are explicitly listed here.

=back

=head2 Parameters in client

=over

=item plugins

ArrayRef of plugins that should be applied to the base class when
it is being used in this client.

=back

=head2 Internals

When C<MooX::PluginRoles> is used, adds a wrapper around the caller's
C<import> method that creates a L<MooX::PluginRoles::Base> instance for
the caller, and saves it in a class-scoped hash.

The C<Base> instance finds the available plugins and roles, creates
anonymous classes with the plugin roles applied, and creates an
anonymous role for each base class that wraps the C<new> method so that
the proper anonymous class can be used to create the instances.

C<Module::Pluggable::Object> is used to find the roles within each
plugin.

=head1 LIMITATIONS

The plugin roles will only work if the immediate caller of the
C<new> constructor is in the namespace of the client that used the
base class.

=head1 SEE ALSO

=over

=item * L<Moo> and L<Moo::Role>

Moo object-orientation system

=item * L<MooX::Role::Pluggable>, L<MooX::Object::Pluggable>

Packages that apply plugin roles to instances of a single Moo class

=item * L<MooX::Roles::Pluggable>

Package that applies plugin roles to a single Moo class

=item * L<MooseX::Object::Pluggable>

Package that applies plugin roles to instances of a single Moose class

=back

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016 Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
