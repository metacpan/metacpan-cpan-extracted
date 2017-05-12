#ABSTRACT: A tiny plugin system for perl
package Plugin::Tiny;
$Plugin::Tiny::VERSION = '0.012';
use strict;
use warnings;
use Carp 'confess';
use Module::Runtime 'use_package_optimistically';
use Scalar::Util 'blessed';
use Moo;
use MooX::Types::MooseLike::Base qw(Bool Str HashRef ArrayRef Object);
use namespace::clean;

#use Data::Dumper;


has '_registry' => (    #href with phases and plugin objects
    is       => 'ro',
    isa      => HashRef[Object],
    default  => sub { {} },
    init_arg => undef,
);


has 'debug' => (is => 'ro', isa => Bool, default => sub {0});


has 'prefix' => (is => 'ro', isa => Str);


has 'role' => (is => 'ro', isa => ArrayRef[Str]);


#
# METHODS
#


#Re-write init argument 'role' as arrayref if not yet arrayref.
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = @_;

    if ($args{role} && ref ($args{role}) ne 'ARRAY'){
        $args{role}=[$args{role}];
    }
    return $class->$orig(%args);
};



sub register {
    my $self   = shift;
    my %args   = @_;
    my $plugin = delete $args{plugin} or confess "Need plugin";

    if ($self->prefix) {
        $plugin = $self->prefix . $plugin;
    }
    my $phase =
      $args{phase}
      ? delete $args{phase}
      : $self->default_phase($plugin);

    if (defined $self->{_registry}{$phase} && !$args{force}) {
        confess <<END
There is already a plugin registered under this phase. If you really want to 
overwrite the current plugin with a new one, use 'force=>1'.
END
    }

     use_package_optimistically($plugin)->can('new') or confess "Can't load '$plugin'";

    my $roles = $self->role if $self->role;    #default role
    $roles = delete $args{role} if exists $args{role};

    #rewrite scalar as arrayref
    $roles = [$roles] if ($roles && !ref $roles);

    if ($roles && ref $roles eq 'ARRAY') {
        foreach my $role (@{$roles}) {
            if ($plugin->DOES($role)) {
                $self->_debug("Plugin '$plugin' does role '$role'");
            }
            else {
                confess qq(Plugin '$plugin' doesn't do role '$role');
            }
        }
    }

    $self->{_registry}{$phase} = $plugin->new(%args)
      || confess "Can't make $plugin";
    $self->_debug("register $plugin [$phase]");
    return $self->{_registry}{$phase};
}



sub register_bundle {
    my $self = shift;
    my $bundle = shift or return;
    foreach my $plugin (keys %{$bundle}) {
        my %args = %{$bundle->{$plugin}};
        $args{plugin} = $plugin;
        $self->register(%args) or confess "Registering $plugin failed";
    }
    return $bundle;
}



sub get_plugin {
    my $self = shift;
    my $phase = shift or return;
    return if (!$self->{_registry}{$phase});
    return $self->{_registry}{$phase};
}



sub default_phase {
    my $self = shift;
    my $plugin = shift or return;    #a class name

    if ($self->prefix) {
        my $phase  = $plugin;
        my $prefix = $self->prefix;
        $phase =~ s/$prefix//;
        $phase =~ s/:://g;
        return $phase;
    }
    else {
        my @parts = split('::', $plugin);
        return $parts[-1];
    }
}


#Todo: Not sure what it returns on error.


sub get_class {
    my $self = shift;
    my $plugin = shift or return;
    blessed($plugin);
}



sub get_phase {
    my $self = shift;
    my $plugin = shift or return;
    blessed($plugin);
    my $current_class = $self->get_class($plugin);

    #print 'z:['.join(' ', keys %{$self->{_registry}})."]\n";
    foreach my $phase (keys %{$self->{_registry}}) {
        my $registered_class = blessed($self->{_registry}{$phase});
        print "[$phase] $registered_class === $current_class\n";
        return $phase if ("$registered_class" eq "$current_class");
    }

}


#
# PRIVATE
#

sub _debug {
    print $_[1] . "\n" if $_[0]->debug;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plugin::Tiny - A tiny plugin system for perl

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  #a complete 'Hello World' plugin
  package My::Plugin; 
  use Moose; #optional; required is an object with new as constructor
  sub do_something { print "Hello World @_\n" }
  1;


  #in your core
  use Plugin::Tiny;           
  my $ps=Plugin::Tiny->new(); #plugin system
  
  #load My::Plugin: require, import, return My::Plugin->new(@_)
  my $plugin=$ps->register(plugin=>'My::Plugin');


  #elsewhere in core: execute your plugin's methods 
  my $plugin=$ps->get_plugin ($phase); 
  $plugin->do_something(@args);  

=head1 DESCRIPTION

Plugin::Tiny is minimalistic plugin system for perl. Each plugin is associated
with a keyword (referred to as phase). A limitation of Plugin::Tiny is that 
each phase can have only one plugin. 

Plugin::Tiny calls itself tiny because it doesn't attempt to solve all problems
plugin systems could solve, because it consists of one smallish package, and it 
doesn't depend on a whole lot.

=head1 ATTRIBUTES

=head2 debug

Optional. Expects a boolean. Prints additional info to STDOUT.

=head2 prefix

Optional. You can have the prefix added to all plugin classes you
register so save some typing and force plugins in your namespace:

  #without prefix  
  my $ps=Plugin::Tiny->new  
  $ps->register(plugin='Your::App::Plugin::Example1');
  $ps->register(plugin='Your::App::Plugin::Example2');

  #with prefix  
  my $ps=Plugin::Tiny->new (  prefix=>'Your::App::Plugin::' );  
  $ps->register(plugin='Example1');
  $ps->register(plugin='Example2');

=head2 role

Optional. One or more roles that all plugins have to be able to do. Can be 
overwritten in C<register>.

    role=>['Role::One', Role::Two]      #either as ArrayRef 
    role=>'Role::One'                   #or a scalar

=head1 METHODS

=head2 register

Registers a plugin, i.e. loads it and makes a new plugin object. Needs a
plugin package name (plugin). Returns the newly created plugin object on 
success. Confesses on error. Remaining arguments are passed down to the 
plugin constructor:

    $obj=$ps->register(
        plugin=>$plugin_class,   #required
        args=>$more_args,        #optional
    ); #returns result of $plugin_class->new (args=>$args);

N.B. Your plugin cannot use 'phase', 'plugin', 'role', 'force' as named 
arguments.

=over

=item B<plugin>

The package name of the plugin. Required. Internally, the value of C<prefix>
is prepended to plugin.

=item B<phase>

A phase asociated with the plugin. Optional. If not specified, Plugin::Tiny 
uses C<default_phase> to determine the phase.

=item B<role>

One or more roles that the plugin has to appply. Optional. Specify role=>undef 
to unset global roles. Currently, you can't mix global roles (defined via new) 
with local roles (defined via register).

    role=>'Single::Role' #or
    role=>['Role::One','Role:Two']
    role=>undef #unset global roles

=item B<force>

Force re-registration of a previously used phase. Optional.

Normally, Plugin::Tiny confesses if you try to register a phase that has 
previously been assigned. To overwrite this message make force true.

With force both plugins will be loaded (required, imported) and both return new 
objects for their respective plugin classes, but after the second plugin is 
made, the first one cannot be accessed anymore through get_plugin.

=back

=head2 register_bundle

Registers a bundle of plugins in no particular order. A bundle is just a 
hashRef with info needed to issue a series of register calls (see C<register>).

Confesses if a plugin cannot be registered. Otherwise returns $bundle or undef.

  sub bundle{
    return {
      'Store::One' => {   
          phase  => 'Store',
          role   => undef,
          dbfile => $self->core->config->{main}{dbfile},
        },
       'Scan::Monitor'=> {   
          core   => $self->core
        },
    };
  }
  $ps->register_bundle(bundle)

If you want to add or remove plugins, use hashref as usual:

  undef $bundle->{$plugin};                #remove a plugin using package name
  $bundle->{'My::Plugin'}={phase=>'foo'};  #add another plugin

To facilitate inheritance of your plugins perhaps you put the hashref in a 
separate sub, so a child bundle can extend or remove plugins from yours.

=head2 get_plugin

Returns the plugin object associated with the phase. Returns undef on failure.

  my $plugin=$ps->get_plugin ($phase);

=head2 default_phase

Makes a default phase from (the plugin's) class name. Expects a $plugin_class. 
Returns scalar or undef. If prefix is defined it use tail and removes all '::'. 
If no prefix is set default_phase returns the last element of the class name:

    my $ps=Plugin-Tiny->new;
    $ps->default_phase(My::Plugin::Long::Example); #returns 'Example'

    $ps=Plugin-Tiny->new(prefix=>'My::Plugin::');
    $ps->default_phase(My::Plugin::Long::Example); #returns 'LongExample'

=head2 get_class 

Returns the plugin's class (package name). Expects plugin (not its package 
name). Croaks on error.

  my $class=$ps->get_class ($plugin);

=head2 get_phase

returns the plugin's phase. Expects plugin (not its package name). Returns 
undef on failure. (You will not normally need get_phase, because typically your 
code knows the phases.)

  my $phase=$ps->get_phase ($plugin);

=for Pod::Coverage BUILDARGS

=head1 Recommendation: First Register Then Do Things

Plugin::Tiny suggests that you first register (load) all your plugins before 
you actually do something with them. Internal C<require> / C<use> of your 
packages is deferred until runtime. You can control the order in which plugins 
are loaded (in the order you call C<register>), but if you manage to load all 
of them before you do anything, you can forget about order.

You may know Plugin::Tiny's phases at compile time, but not which plugins will 
be loaded.

=head1 Recommendation: Require a Plugin Role

You may want to do a plugin role for all you plugins, e.g. to standardize
the interface for your plugins. Perhaps to make sure that a specific sub is
available in the plugin:

  package My::Plugin; 
  use Moose;
  with 'Your::App::Role::Plugin';
  #...

=head1 Plugin Bundles

You can create bundles of plugins if you pass the plugin system to the 
(bundling) plugin. That way you can load multiple plugins for one phase. You 
still need unique phases for each plugin:

  package My::Core;
  use Moose; 
  has 'plugin_system'=>(
    is=>'ro',
    isa=>'Plugin::Tiny', 
    default=>sub{Plugin::Tiny->new},
  );

  sub BUILD {
    $self->plugins->register(
      plugin=>'PluginBundle', 
      phase=>'Bundle',
      plugin_system=>$self->plugins, 
    );
  }

  #elsewhere in core
  my $b=$self->plugin_system->get_plugin ('Bundle');  
  $b->start();


  package PluginBundle;
  use Moose;
  has 'plugin_system'=>(is=>'ro', isa=>'Plugin::Tiny', required=>1); 

  sub bundle {
      {Plugin::One=>{},Plugin::Two=>{}}
  }  
  sub BUILD {
    #phase defaults to 'One' and 'Two':
    $self->plugins->register_bundle(bundle());
  
    #more or less the same as:    
    #$self->plugins->register (plugin=>'Plugin::One');  
    #$self->plugins->register (plugin=>'Plugin::Two'); 
  }
  
  sub start {
    my $one=$self->plugins->get('One');
    $one->do_something(@args);  
  }

=head1 CONTRIBUTORS

Thanks to Toby Inkster for making Plugin::Tiny tinier.

=head1 SEE ALSO

L<Object::Pluggable> 
L<Module::Pluggable>
L<MooX::Role::Pluggable>
L<MooseX::Object::Pluggable>
L<MooseX::Role::Pluggable>

=head1 AUTHOR

Maurice Mengel <mauricemengel@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Maurice Mengel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
