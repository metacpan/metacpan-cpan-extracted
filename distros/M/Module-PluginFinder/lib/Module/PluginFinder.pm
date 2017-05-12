#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2009 -- leonerd@leonerd.org.uk

package Module::PluginFinder;

use strict;
use warnings;

use Carp;

use Module::Pluggable::Object;

our $VERSION = '0.04';

=head1 NAME

C<Module::PluginFinder> - automatically choose the most appropriate plugin
module.

=head1 SYNOPSIS

 use Module::PluginFinder;

 my $finder = Module::PluginFinder->new(
                 search_path => 'MyApp::Plugin',

                 filter => sub {
                    my ( $module, $searchkey ) = @_;
                    $module->can( $searchkey );
                 },
              );

 my $ball = $finder->construct( "bounce" );
 $ball->bounce();

 my $fish = $finder->construct( "swim" );
 $fish->swim();

=head1 DESCRIPTION

This module provides a factory class. Objects in this class search for a
specific plugin module to fit some criteria. Each time a new object is to be
constructed by the factory, the caller should provide a value which in some
way indicates the kind of object required. The factory's filter function is
then used to determine which plugin module fits the criteria.

The most flexible way to determine the required module is to provide a filter
function. When looking for a suitable module, the function is called once for
each candidate module, and is passed the module's name and the search key. The
function can then return a boolean to indicate whether the module will be
suitable. The value of the search key is not directly used by the
C<Module::PluginFinder> in this case, and therefore is not restricted to being
a simple scalar value; any sort of reference may be passed.

Instead of a filter function, the factory can inspect a package variable or
constant method in each of the candidate modules, looking for a string match
with the search key; see the C<typevar> and C<typefunc> constructor arguments.
When using this construction, a map from type names to module names will be
cached at the time the C<Module::PluginFinder> object is created, and will
therefore not be sensitive to changes in the values once this is done. Because
of this, the key should be a simple string, rather than a reference.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $finder = Module::PluginFinder->new( %args )

Constructs a new C<Module::PluginFinder> factory object. The constructor will
search the module path for all available plugins, as determined by the
C<search_path> key and store them.

The C<%args> hash must take the following keys:

=over 8

=item search_path => STRING or ARRAY

A string declaring the module namespace, or an array reference of module
namespaces to search for plugins (passed to L<Module::Pluggable::Object>).

=back

In order to specify the way candidate modules are selected, one of the
following keys must be supplied.

=over 8

=item filter => CODE

The filter function for determining whether a module is suitable as a plugin

=item typevar => STRING

The name of a package variable to match against the search key

=item typefunc => STRING

The name of a package method to call to return the type name. The method will
be called in scalar context with no arguments; as

 $type = $module->$typefunc();

If it returns C<undef> or throws an exception, then the module will be ignored

=back

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $search_path = delete $args{search_path} or croak "Expected a 'search_path' key";

   my $finder = Module::Pluggable::Object->new(
      search_path => $search_path,
      require     => 1,
      inner       => 0,
   );

   my $self = bless {
      finder  => $finder,
      modules => [],
   }, $class;

   if( exists $args{filter} ) {
      my $filter = delete $args{filter};
      ref $filter eq "CODE" or croak "Expected that 'filter' argument be a CODE ref";

      $self->{filter} = $filter;
   }
   elsif( exists $args{typevar} ) {
      $self->{typevar} = delete $args{typevar};
   }
   elsif( exists $args{typefunc} ) {
      $self->{typefunc} = delete $args{typefunc};
   }
   else {
      croak "Expected a 'filter', 'typefunc' or 'typevar' argument";
   }

   $self->rescan;

   return $self;
}

=head1 METHODS

=cut

=head2 @modules = $finder->modules()

Returns the list of module names available to the finder.

=cut

sub modules
{
   my $self = shift;
   return @{ $self->{modules} };
}

=head2 $module = $finder->find_module( $searchkey )

Search for a plugin module that matches the search key. Returns the name of
the first module for which the filter returns true, or C<undef> if no suitable
module was found.

=over 8

=item $searchkey

A value to pass to the stored filter function.

=back

=cut

sub find_module
{
   my $self = shift;
   my ( $searchkey ) = @_;

   if( exists $self->{typemap} ) {
      return $self->{typemap}->{$searchkey};
   }

   my $filter = $self->{filter};

   foreach my $module ( @{ $self->{modules} } ) {
      return $module if $filter->( $module, $searchkey );
   }

   return undef;
}

=head2 $object = $finder->construct( $searchkey, @constructorargs )

Search for a plugin module that matches the search key, then attempt to create
a new object in that class. If a suitable module  is found to match the
C<$searchkey> then the C<new> method is called on it, passing the
C<@constructorargs>. If no suitable module is found then an exception is
thrown.

=over 8

=item $searchkey

A value to pass to the stored filter function.

=item @constructorargs

A list to pass to the class constructor.

=back

=cut

sub construct
{
   my $self = shift;
   my ( $searchkey, @constructorargs ) = @_;

   my $class = $self->find_module( $searchkey );

   return $class->new( @constructorargs ) if defined $class;

   croak "Unable to find a suitable class";
}

=head2 $finder->rescan()

Perform another search for plugin modules. This method is useful whenever new
modules may be present since the object was first constructed.

=cut

sub rescan
{
   my $self = shift;

   my $finder = $self->{finder};

   @{ $self->{modules} } = $finder->plugins;

   if( exists $self->{typevar} ) {
      my $typevar = $self->{typevar};
      my %typemap;

      foreach my $module ( $self->modules ) {
         no strict qw( refs );

         next unless defined ${$module."::".$typevar};
         my $moduletype = ${$module."::".$typevar};

         if( exists $typemap{$moduletype} ) {
            carp "Already found module '$typemap{$moduletype}' for type '$moduletype'; not adding '$module' as well";
            next;
         }

         $typemap{$moduletype} = $module;
      }

      $self->{typemap} = \%typemap;
   }
   elsif( exists $self->{typefunc} ) {
      my $typefunc = $self->{typefunc};
      my %typemap;

      foreach my $module ( $self->modules ) {
         no strict qw( refs );

         next unless $module->can( $typefunc );
         my $moduletype = eval { $module->$typefunc() };
         next unless defined $moduletype;

         if( exists $typemap{$moduletype} ) {
            carp "Already found module '$typemap{$moduletype}' for type '$moduletype'; not adding '$module' as well";
            next;
         }

         $typemap{$moduletype} = $module;
      }

      $self->{typemap} = \%typemap;
   }

   return; # Avoid implicit return-of-last-expression
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 EXAMPLES

The filter function allows various ways to select plugin modules on different
criteria. The following examples indicate a few ways to do this.

=head2 Availability of a function / method

 my $f = Module::PluginFinder->new(
            search_path => ...,

            filter => sub {
               my ( $module, $searchkey ) = @_;

               return $module->can( $searchkey );
            },
         );

Each plugin then simply has to implement the required function or method in
order to be automatically selected.

=head2 Value of a method call

 my $f = Module::PluginFinder->new(
            search_path => ...,

            filter => sub {
               my ( $module, $searchkey ) = @_;

               return 0 unless $module->can( "is_plugin_for" );
               return $module->is_plugin_for( $searchkey );
            },
         );

Each plugin then needs to implement a method called C<is_plugin_for>, that
should examine the $searchkey and perform whatever testing it requires, then
return a boolean to indicate if the plugin is suitable.

=head2 Value of a constant

Because a constant declared by the C<use constant> pragma is a plain function,
it can be called by the C<typefunc> filter:

 my $f = Module::PluginFinder->new(
            search_path => ...,

            typefunc => 'PLUGIN_TYPE',
         );

Each plugin can then declare its type using a constuction like

 use constant PLUGIN_TYPE => "my type here";

Alternatively, a normal package method may be created that performs any work
required to determine the plugin's type

 sub PLUGIN_TYPE
 {
    my $class = shift;

    ...

    return $typename;
 }

Note that the type function in each module will only be called once, and the
returned value cached.

=head2 Value of a package scalar

The C<typevar> constructor argument generates the filter function
automatically.

 my $f = Module::PluginFinder->new(
            search_path => ...,

            typevar => 'PLUGIN_TYPE',
         );

Each plugin can then declare its type using a normal C<our> scalar variable:

 our $PLUGIN_TYPE = "my type here";

=head1 SEE ALSO

=over 4

=item *

L<Module::Pluggable> - automatically give your module the ability to have
plugins

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
