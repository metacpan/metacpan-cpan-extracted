package MooseX::Object::Pluggable; # git description: v0.0013-5-g45105f2
# ABSTRACT: Make your classes pluggable
$MooseX::Object::Pluggable::VERSION = '0.0014';
use Carp;
use Moose::Role;
use Module::Runtime 'use_module';
use Scalar::Util 'blessed';
use Try::Tiny;
use Module::Pluggable::Object;
use Moose::Util 'find_meta';
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod     package MyApp;
#pod     use Moose;
#pod
#pod     with 'MooseX::Object::Pluggable';
#pod
#pod     ...
#pod
#pod     package MyApp::Plugin::Pretty;
#pod     use Moose::Role;
#pod
#pod     sub pretty{ print "I am pretty" }
#pod
#pod     1;
#pod
#pod     #
#pod     use MyApp;
#pod     my $app = MyApp->new;
#pod     $app->load_plugin('Pretty');
#pod     $app->pretty;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module is meant to be loaded as a role from Moose-based classes.
#pod It will add five methods and four attributes to assist you with the loading
#pod and handling of plugins and extensions for plugins. I understand that this may
#pod pollute your namespace, however I took great care in using the least ambiguous
#pod names possible.
#pod
#pod =head1 How plugins Work
#pod
#pod Plugins and extensions are just Roles by a fancy name. They are loaded at runtime
#pod on demand and are instance, not class based. This means that if you have more than
#pod one instance of a class they can all have different plugins loaded. This is a feature.
#pod
#pod Plugin methods are allowed to C<around>, C<before>, C<after>
#pod their consuming classes, so it is important to watch for load order as plugins can
#pod and will overload each other. You may also add attributes through C<has>.
#pod
#pod Please note that when you load at runtime you lose the ability to wrap C<BUILD>
#pod and roles using C<has> will not go through compile time checks like C<required>
#pod and C<default>.
#pod
#pod Even though C<override> will work, I B<STRONGLY> discourage its use
#pod and a warning will be thrown if you try to use it.
#pod This is closely linked to the way multiple roles being applied is handled and is not
#pod likely to change. C<override> behavior is closely linked to inheritance and thus will
#pod likely not work as you expect it in multiple inheritance situations. Point being,
#pod save yourself the headache.
#pod
#pod =head1 How plugins are loaded
#pod
#pod When roles are applied at runtime an anonymous class will wrap your class and
#pod C<< $self->blessed >>, C<< ref $self >> and C<< $self->meta->name >>
#pod will no longer return the name of your object;
#pod they will instead return the name of the anonymous class created at runtime.
#pod See C<_original_class_name>.
#pod
#pod =head1 Usage
#pod
#pod For a simple example see the tests included in this distribution.
#pod
#pod =head1 Attributes
#pod
#pod =head2 _plugin_ns
#pod
#pod String. The prefix to use for plugin names provided. C<MyApp::Plugin> is sensible.
#pod
#pod =head2 _plugin_app_ns
#pod
#pod An ArrayRef accessor that automatically dereferences into array on a read call.
#pod By default it will be filled with the class name and its precedents. It is used
#pod to determine which directories to look for plugins as well as which plugins
#pod take precedence upon namespace collisions. This allows you to subclass a pluggable
#pod class and still use its plugins while using yours first if they are available.
#pod
#pod =head2 _plugin_locator
#pod
#pod An automatically built instance of L<Module::Pluggable::Object> used to locate
#pod available plugins.
#pod
#pod =head2 _original_class_name
#pod
#pod =for stopwords instantiation
#pod
#pod Because of the way roles apply, C<< $self->blessed >>, C<< ref $self >>
#pod and C<< $self->meta->name >> will
#pod no longer return what you expect. Instead, upon instantiation, the name of the
#pod class instantiated will be stored in this attribute if you need to access the
#pod name the class held before any runtime roles were applied.
#pod
#pod =cut

#--------#---------#---------#---------#---------#---------#---------#---------#

has _plugin_ns => (
  is => 'rw',
  required => 1,
  isa => 'Str',
  default => sub{ 'Plugin' },
);

has _original_class_name => (
  is => 'ro',
  required => 1,
  isa => 'Str',
  default => sub{ blessed($_[0]) },
);

has _plugin_loaded => (
  is => 'rw',
  required => 1,
  isa => 'HashRef',
  default => sub{ {} }
);

has _plugin_app_ns => (
  is => 'rw',
  required => 1,
  isa => 'ArrayRef',
  lazy => 1,
  auto_deref => 1,
  builder => '_build_plugin_app_ns',
  trigger => sub{ $_[0]->_clear_plugin_locator if $_[0]->_has_plugin_locator; },
);

has _plugin_locator => (
  is => 'rw',
  required => 1,
  lazy => 1,
  isa => 'Module::Pluggable::Object',
  clearer => '_clear_plugin_locator',
  predicate => '_has_plugin_locator',
  builder => '_build_plugin_locator'
);

#--------#---------#---------#---------#---------#---------#---------#---------#

#pod =head1 Public Methods
#pod
#pod =head2 load_plugins @plugins
#pod
#pod =head2 load_plugin $plugin
#pod
#pod Load the appropriate role for C<$plugin>.
#pod
#pod =cut

sub load_plugins {
    my ($self, @plugins) = @_;
    die("You must provide a plugin name") unless @plugins;

    my $loaded = $self->_plugin_loaded;
    @plugins = grep { not exists $loaded->{$_} } @plugins;

    return if @plugins == 0;

    foreach my $plugin (@plugins)
    {
        my $role = $self->_role_from_plugin($plugin);
        return if not $self->_load_and_apply_role($role);

        $loaded->{$plugin} = $role;
    }

    return 1;
}


sub load_plugin {
  my $self = shift;
  $self->load_plugins(@_);
}

#pod =head1 Private Methods
#pod
#pod There's nothing stopping you from using these, but if you are using them
#pod for anything that's not really complicated you are probably doing
#pod something wrong.
#pod
#pod =head2 _role_from_plugin $plugin
#pod
#pod Creates a role name from a plugin name. If the plugin name is prepended
#pod with a C<+> it will be treated as a full name returned as is. Otherwise
#pod a string consisting of C<$plugin>  prepended with the C<_plugin_ns>
#pod and the first valid value from C<_plugin_app_ns> will be returned. Example
#pod
#pod    #assuming appname MyApp and C<_plugin_ns> 'Plugin'
#pod    $self->_role_from_plugin("MyPlugin"); # MyApp::Plugin::MyPlugin
#pod
#pod =cut

sub _role_from_plugin{
    my ($self, $plugin) = @_;

    return $1 if( $plugin =~ /^\+(.*)/ );

    my $o = join '::', $self->_plugin_ns, $plugin;
    #Father, please forgive me for I have sinned.
    my @roles = grep{ /${o}$/ } $self->_plugin_locator->plugins;

    croak("Unable to locate plugin '$plugin'") unless @roles;
    return $roles[0] if @roles == 1;

    my $i = 0;
    my %precedence_list = map{ $i++; "${_}::${o}", $i } $self->_plugin_app_ns;

    @roles = sort{ $precedence_list{$a} <=> $precedence_list{$b}} @roles;

    return shift @roles;
}

#pod =head2 _load_and_apply_role @roles
#pod
#pod Require C<$role> if it is not already loaded and apply it. This is
#pod the meat of this module.
#pod
#pod =cut

sub _load_and_apply_role {
    my ($self, $role) = @_;
    die("You must provide a role name") unless $role;

    try { use_module($role) }
    catch { confess("Failed to load role: ${role} $_") };

    croak("Your plugin '$role' must be a Moose::Role")
        unless find_meta($role)->isa('Moose::Meta::Role');

    carp("Using 'override' is strongly discouraged and may not behave ".
        "as you expect it to. Please use 'around'")
    if scalar keys %{ $role->meta->get_override_method_modifiers_map };

    Moose::Util::apply_all_roles( $self, $role );

    return 1;
}

#pod =head2 _build_plugin_app_ns
#pod
#pod Automatically builds the _plugin_app_ns attribute with the classes in the
#pod class precedence list that are not part of Moose.
#pod
#pod =cut

sub _build_plugin_app_ns{
    my $self = shift;
    my @names = (grep {$_ !~ /^Moose::/} $self->meta->class_precedence_list);
    return \@names;
}

#pod =head2 _build_plugin_locator
#pod
#pod Automatically creates a L<Module::Pluggable::Object> instance with the correct
#pod search_path.
#pod
#pod =cut

sub _build_plugin_locator{
    my $self = shift;

    my $locator = Module::Pluggable::Object->new
        ( search_path =>
          [ map { join '::', ($_, $self->_plugin_ns) } $self->_plugin_app_ns ]
        );
    return $locator;
}

#pod =head2 meta
#pod
#pod Keep tests happy. See L<Moose>
#pod
#pod =cut

1;

=pod

=encoding UTF-8

=head1 NAME

MooseX::Object::Pluggable - Make your classes pluggable

=head1 VERSION

version 0.0014

=head1 SYNOPSIS

    package MyApp;
    use Moose;

    with 'MooseX::Object::Pluggable';

    ...

    package MyApp::Plugin::Pretty;
    use Moose::Role;

    sub pretty{ print "I am pretty" }

    1;

    #
    use MyApp;
    my $app = MyApp->new;
    $app->load_plugin('Pretty');
    $app->pretty;

=head1 DESCRIPTION

This module is meant to be loaded as a role from Moose-based classes.
It will add five methods and four attributes to assist you with the loading
and handling of plugins and extensions for plugins. I understand that this may
pollute your namespace, however I took great care in using the least ambiguous
names possible.

=head1 How plugins Work

Plugins and extensions are just Roles by a fancy name. They are loaded at runtime
on demand and are instance, not class based. This means that if you have more than
one instance of a class they can all have different plugins loaded. This is a feature.

Plugin methods are allowed to C<around>, C<before>, C<after>
their consuming classes, so it is important to watch for load order as plugins can
and will overload each other. You may also add attributes through C<has>.

Please note that when you load at runtime you lose the ability to wrap C<BUILD>
and roles using C<has> will not go through compile time checks like C<required>
and C<default>.

Even though C<override> will work, I B<STRONGLY> discourage its use
and a warning will be thrown if you try to use it.
This is closely linked to the way multiple roles being applied is handled and is not
likely to change. C<override> behavior is closely linked to inheritance and thus will
likely not work as you expect it in multiple inheritance situations. Point being,
save yourself the headache.

=head1 How plugins are loaded

When roles are applied at runtime an anonymous class will wrap your class and
C<< $self->blessed >>, C<< ref $self >> and C<< $self->meta->name >>
will no longer return the name of your object;
they will instead return the name of the anonymous class created at runtime.
See C<_original_class_name>.

=head1 Usage

For a simple example see the tests included in this distribution.

=head1 Attributes

=head2 _plugin_ns

String. The prefix to use for plugin names provided. C<MyApp::Plugin> is sensible.

=head2 _plugin_app_ns

An ArrayRef accessor that automatically dereferences into array on a read call.
By default it will be filled with the class name and its precedents. It is used
to determine which directories to look for plugins as well as which plugins
take precedence upon namespace collisions. This allows you to subclass a pluggable
class and still use its plugins while using yours first if they are available.

=head2 _plugin_locator

An automatically built instance of L<Module::Pluggable::Object> used to locate
available plugins.

=head2 _original_class_name

=for stopwords instantiation

Because of the way roles apply, C<< $self->blessed >>, C<< ref $self >>
and C<< $self->meta->name >> will
no longer return what you expect. Instead, upon instantiation, the name of the
class instantiated will be stored in this attribute if you need to access the
name the class held before any runtime roles were applied.

=head1 Public Methods

=head2 load_plugins @plugins

=head2 load_plugin $plugin

Load the appropriate role for C<$plugin>.

=head1 Private Methods

There's nothing stopping you from using these, but if you are using them
for anything that's not really complicated you are probably doing
something wrong.

=head2 _role_from_plugin $plugin

Creates a role name from a plugin name. If the plugin name is prepended
with a C<+> it will be treated as a full name returned as is. Otherwise
a string consisting of C<$plugin>  prepended with the C<_plugin_ns>
and the first valid value from C<_plugin_app_ns> will be returned. Example

   #assuming appname MyApp and C<_plugin_ns> 'Plugin'
   $self->_role_from_plugin("MyPlugin"); # MyApp::Plugin::MyPlugin

=head2 _load_and_apply_role @roles

Require C<$role> if it is not already loaded and apply it. This is
the meat of this module.

=head2 _build_plugin_app_ns

Automatically builds the _plugin_app_ns attribute with the classes in the
class precedence list that are not part of Moose.

=head2 _build_plugin_locator

Automatically creates a L<Module::Pluggable::Object> instance with the correct
search_path.

=head2 meta

Keep tests happy. See L<Moose>

=head1 SEE ALSO

L<Moose>, L<Moose::Role>, L<Class::Inspector>

=head1 BUGS

Holler?

Please report any bugs or feature requests to
C<bug-MooseX-Object-Pluggable at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Object-Pluggable>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX-Object-Pluggable

You can also look for information at:

=for stopwords AnnoCPAN

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Object-Pluggable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Object-Pluggable>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Object-Pluggable>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Object-Pluggable>

=back

=head1 ACKNOWLEDGEMENTS

=for stopwords Stevan

=over 4

=item #Moose - Huge number of questions

=item Matt S Trout <mst@shadowcatsystems.co.uk> - ideas / planning.

=item Stevan Little - EVERYTHING. Without him this would have never happened.

=item Shawn M Moore - bugfixes

=back

=head1 AUTHOR

Guillermo Roditi <groditi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Guillermo Roditi <groditi@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Shawn M Moore Yuval Kogman Robert Boone David Steinbrunner Todd Hepler

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Robert Boone <robo4288@gmail.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Todd Hepler <thepler@employees.org>

=back

=cut

__END__;

