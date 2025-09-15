package Task::MemManager::View;
$Task::MemManager::View::VERSION = '0.01';
use strict;
use warnings;
use Module::Find;
use Module::Runtime 'use_module';

BEGIN {
    require Task::MemManager unless defined &Task::MemManager::VERSION;
    use constant DEBUG => $ENV{DEBUG} // 0;

    # Save the original DESTROY
    our $destroyer = *Task::MemManager::DESTROY{CODE};
}

## Switch to Task::MemManager namespace, since we are extending it
package Task::MemManager;
$Task::MemManager::VERSION = '0.01';
use Carp;
no warnings 'redefine';    # We are redefining DESTROY

# Find implemented memory views under this namespace

my %view_function_with;
my @view_modules   = findsubmod 'Task::MemManager::View';
my @view_functions = qw(create_view clone_view);

my %view_buffer_of  = ();
my %view_type_of    = ();
my %options_of_view = ();

TEST_MODULE: foreach my $module_name (@view_modules) {
    ( my $key = $module_name ) =~ s/Task::MemManager::View:://;
    my $view_module = use_module($module_name);    # Load the module
    my $number_of_functions =
      grep { $view_module->can($_) } @view_functions;
    if ( $number_of_functions < @view_functions ) {
        warn "Module $view_module does not implement all required methods: "
          . "(@view_functions).\nThis module will not be used for "
          . "creating views.\n";
        next TEST_MODULE;
    }    ## zero implemented functions is OK, it may be a utility module

    # Store the mandatory and optional functions of the allocator
    foreach my $function (@view_functions) {
        $view_function_with{$key}{$function} = $view_module->can($function);
    }
}

###############################################################################
# Usage       : $view =  $buffer->create_view($view_type, \%options);
# Purpose     : Create a view of the specified type for the buffer
# Returns     : The created view
# Parameters  : $view_type - type of the view (e.g. 'PDL')
#               \%options - hash reference with options for the view. The
#                           option view_name is reserved for naming the view.
#                           If not specified, a default name is used.
#               The options are passed as-is to the view's create_view method.
#               See the documentation of each view module for the supported
#               options.
# Throws      : n/a
# Comments    : Returns undef if the view creation fails for any reason.
#               Warnings will be generated if DEBUG is set to a non-zero value.

sub create_view {
    my ( $self, $view_type, $opts_ref ) = @_;
    my $identifier = ident $self;

    # Sanity checks
    unless ( ref($self) ) {
        if (DEBUG) {
            carp "Cannot call create_view as class method.\n";
        }
        return undef;
    }
    unless ( defined $view_type ) {
        if (DEBUG) {
            carp "View type must be specified.\n";
        }
        return undef;
    }
    unless ( exists $view_function_with{$view_type} ) {
        if (DEBUG) {
            carp "View type '$view_type' is not supported.\n";
        }
        return undef;
    }

    # Create the view
    my $view =
      $view_function_with{$view_type}->{create_view}
      ->( $self->get_buffer, $self->get_buffer_size, $opts_ref );
    unless ( defined $view ) {
        if (DEBUG) {
            carp "View creation failed for type '$view_type'.\n";
        }
        return undef;
    }

    # store the view, it's type, and options
    my $view_name = $opts_ref->{view_name} // "$view_type\_default";
    $view_buffer_of{$identifier}{$view_name}  = $view;
    $view_type_of{$identifier}{$view_name}    = $view_type;
    $options_of_view{$identifier}{$view_name} = $opts_ref // {};
    return $view;
}

###############################################################################
# Usage       : $buffer->delete_view($view_name);
# Purpose     : Delete the specified view of the buffer
# Returns     : nothing
# Parameters  : $view_name - name of the view to delete
# Throws      : n/a
# Comments    : If the view does not exist, nothing happens.
#               Warnings will be generated if DEBUG is set to a non-zero value
#               and the view name is not specified, or not found.

sub delete_view {

    my ( $self, $view_name ) = @_;
    unless ( ref($self) ) {
        if (DEBUG) {
            carp "Cannot call get_view as class method.\n";
        }
        return undef;
    }
    unless ( defined $view_name ) {
        if (DEBUG) {
            carp "View name must be specified.\n";
        }
        return undef;
    }

    my $identifier = ident $self;
    delete $view_buffer_of{$identifier}{$view_name};
}

###############################################################################
# Usage       : $view =  $buffer->get_view($view_name);
# Purpose     : Retrieve the specified view of the buffer
# Returns     : The view, or undef if any error occurs
# Parameters  : $view_name - name of the view to retrieve
# Throws      : n/a
# Comments    : Warnings will be generated if DEBUG is set to a non-zero value
#               and the view name is not specified, or not found.

sub get_view {
    my ( $self, $view_name ) = @_;

    unless ( ref($self) ) {
        if (DEBUG) {
            carp "Cannot call get_view as class method.\n";
        }
        return undef;
    }
    unless ( defined $view_name ) {
        if (DEBUG) {
            carp "View name must be specified.\n";
        }
        return undef;
    }

    my $identifier = ident $self;
    return $view_buffer_of{$identifier}{$view_name};
}

###############################################################################
# Usage       : $cloned_view =  $buffer->clone_view($view_name);
# Purpose     : Clone the specified view of the buffer
# Returns     : The cloned view, or undef if any error occurs
# Parameters  : $view_name - name of the view to clone
# Throws      : n/a
# Comments    : Warnings will be generated if DEBUG is set to a non-zero value
#               and the view name is not specified, or not found.

sub clone_view {
    my ( $self, $view_name ) = @_;
    if (DEBUG) {
        carp "Cannot call clone_view as class method.\n" unless ref($self);
        carp "View name must be specified.\n"
          unless defined $view_name;
    }

    my $identifier = ident $self;
    my $view       = $view_buffer_of{$identifier}{$view_name};

    unless ( defined $view ) {
        if (DEBUG) {
            carp "View '$view_name' not found for cloning.\n"
              unless defined $view;
        }
        return undef;
    }

    return $view_function_with{ $view_type_of{$identifier}{$view_name} }
      ->{clone_view}->($view);
}

## redefinition of DESTROY to clean up properties of views.
sub DESTROY {
    my ($self) = @_;
    my $identifier = ident $self;

    # recursively destroy all views associated with this buffer
    if ( exists $view_buffer_of{$identifier} ) {
        foreach my $view_name ( keys %{ $view_buffer_of{$identifier} } ) {
            delete $view_buffer_of{$identifier}{$view_name};
            if (DEBUG) {
                print "\nDESTROYED view $view_name of "
                  . "Task::MemManager::View $identifier, $self\n";
            }
        }
        delete $view_buffer_of{$identifier};
    }

    $Task::MemManager::View::destroyer->($self);
}
1;

=head1 NAME

Task::MemManager::View - Provides convenient views for Task::MemManager buffers

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Task::MemManager;
    use Task::MemManager::View; # automatically loaded if Task::MemManager is used

    my $buffer = Task::MemManager->new( size => 1000, 1 );

    # Create a PDL view - implied an unsigned 8-bit integer view if pgl_type is not
    # specified
    my $pdl_view = $buffer->create_view('PDL', { view_name => 'my_pdl_view' });

    # Retrieve the view later
    my $retrieved_view = $buffer->get_view('my_pdl_view');

    # Clone the view
    my $cloned_view = $buffer->clone_view('my_pdl_view');

    # Delete the view when no longer needed
    $buffer->delete_view('my_pdl_view');

    # New view using a different type PDL type
    my $pdl_view_16 = $buffer->create_view('PDL', { view_name => 'my_pdl_uint16',
                                              pdl_type => 'ushort' });


=head1 DESCRIPTION

Task::MemManager::View is a module that extends the C<Task::MemManager> module
by providing convenient views for the memory buffers allocated by the
C<Task::MemManager> module. It does so, by adding additional methods to the
C<Task::MemManager> class to create, delete, and retrieve views.
Views are implemented as separate modules under the C<Task::MemManager::View>
namespace. Each view module must implement a set of mandatory methods
(see below). The view modules are automatically discovered and loaded when
the C<Task::MemManager::View> module is loaded. If you do not need a view, 
do not install the corresponding module, because C<Task::MemManager::View>  is
a graceful module that will load B<every> module under it's namespace.

=head1 METHODS

=head2 create_view

  Usage       : $view =  $buffer->create_view($view_type, \%options);
  Purpose     : Create a view of the specified type for the buffer
  Returns     : The created view
  Parameters  : $view_type - type of the view (e.g. 'PDL')
                \%options - hash reference with options for the view. The
                            option view_name is reserved for naming the view.
                            If not specified, a default name is used.
                The options are passed as-is to the view's create_view method.
                See the documentation of each view module for the supported
                options.
  Throws      : n/a
  Comments    : Returns undef if the view creation fails for any reason.
                Warnings will be generated if DEBUG is set to a non-zero value.

=head2 delete_view

  Usage       : $buffer->delete_view($view_name);
  Purpose     : Delete the specified view of the buffer
  Returns     : nothing
  Parameters  : $view_name - name of the view to delete
  Throws      : n/a
  Comments    : If the view does not exist, nothing happens.
                Warnings will be generated if DEBUG is set to a non-zero value
                and the view name is not specified, or not found.

=head2 get_view

  Usage       : $view = $buffer->get_view($view_name);
  Purpose     : Retrieve the specified view of the buffer
  Returns     : The requested view or undef if not found
  Parameters  : $view_name - name of the view to retrieve
  Throws      : n/a
  Comments    : If the view does not exist, nothing happens.
                Warnings will be generated if DEBUG is set to a non-zero value
                and the view name is not specified, or not found.

=head2 clone_view

  Usage       : $cloned_view = $buffer->clone_view($view_name);
  Purpose     : Clone the specified view of the buffer
  Returns     : The cloned view or undef if not found
  Parameters  : $view_name - name of the view to clone
  Throws      : n/a
  Comments    : If the view does not exist, nothing happens.
                Warnings will be generated if DEBUG is set to a non-zero value
                and the view name is not specified, or not found.

=head1 EXAMPLES

Please see the examples in the module L<Task::MemManager::View::PDL> 

=head1 DIAGNOSTICS

If you set up the environment variable DEBUG to a non-zero value, then
a number of sanity checks will be performed, and the module will carp
with an (informative message ?) if something is wrong.

=head1 DEPENDENCIES

The module extends the C<Task::MemManager> module so this is definitely a
dependency. It also uses the C<Module::Find> and C<Module::Runtime> modules
to find and load the view modules (so you can count them as dependencies too).
By default all installed view modules will be loaded. If you do not need a
specific view, do not install the corresponding module. This may change in
the future, if I decide to add a mechanism to load only specific view modules.

=head1 TODO

Open to suggestions. A few foolish ideas of my own include: adding 
Pandas DataFrame, Polars DataFrame, or Apache Arrow views

=head1 SEE ALSO

=over 4

=item * L<https://metacpan.org/pod/Task::MemManager>

This module exports various internal perl methods that change the internal 
representation or state of a perl scalar. All of these work in-place, that is,
they modify their scalar argument. 

=item * L<https://metacpan.org/pod/Inline::C>

Inline::C is a module that allows you to write Perl subroutines in C. 

=item * L<https://perldoc.perl.org/perlguts> 

Introduction to the Perl API.

=item * L<https://perldoc.perl.org/perlapi>

Autogenerated documentation for the perl public API.

=back

=head1 AUTHOR

Christos Argyropoulos, C<< <chrisarg at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under the
MIT license. The full text of the license can be found in the LICENSE file
See L<https://en.wikipedia.org/wiki/MIT_License> for more information.

=cut
