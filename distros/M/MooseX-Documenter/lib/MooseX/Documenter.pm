package MooseX::Documenter;

use 5.008000;
use strict;
use warnings;

require PPI::Document;
require Exporter;
use vars qw($VERSION);

$VERSION = '0.01';

sub setmooselib {
  my $self = shift;
  my $path = shift;

  $self->{moose_lib} = $path;
}

#requires library path to source of moose objects, and name of moose object to get documentation for..
# example /src/moose/lib TNT::Form
sub new {
  my $classname = shift;
  my $lib       = shift;
  my $object    = shift;

  my $source = $lib . '/' . join( '/', split( '::', $object ) ) . '.pm';

  # load the PPI object
  -e $lib || die "Directory can not be opened: $lib: $!";
  my $document = PPI::Document->new($source);

  # load the moose class object
  eval "use lib '$lib';use $object;";
  die "$@" if $@;
  my $class_meta = $object->meta;

  bless {
    ppi_object             => $document,
    meta_object            => $class_meta,
    user_lib               => $lib,
    moose_lib              => '/opt/local/perl/lib/site_perl/5.10.0',
    object_name            => $object,
    inherited_attributes   => {},
    inherited_methods      => {},
    role_method_exclusions => {},
    parents                => [],
    functions_run          => {}
    },
    $classname;
}

#return undef if no attributes or hashref of attributes
sub local_attributes {
  my $self = shift;

  #must run roles function object before this one
  $self->roles unless $self->{functions_run}->{roles};

  my $meta_object = $self->{'meta_object'};

  for my $attr ( $meta_object->get_attribute_list() ) {
    my $attribute = $meta_object->get_attribute($attr);
    $self->{local_attributes}->{$attr} = get_attribute_details($attribute);
  }

  $self->{functions_run}->{local_attributes} = 1;
  return undef if scalar( keys %{ $self->{local_attributes} } ) == 0;
  return $self->{local_attributes};
}

sub inherited_attributes {
  my $self = shift;

  $self->roles         unless $self->{functions_run}->{roles};
  $self->class_parents unless $self->{functions_run}->{class_parents};

  foreach my $parent ( @{ $self->{parents} } ) {
    my $parent_doc;
    if( $parent eq 'Moose::Object' ) {
      $parent_doc = MooseX::Documenter->new( $self->{moose_lib}, $parent );
    }
    else {
      $parent_doc = MooseX::Documenter->new( $self->{user_lib}, $parent );
    }

    $parent_doc->setmooselib( $self->{moose_lib} );

    my $parent_attributes = $parent_doc->local_attributes;

    $self->{inherited_attributes}->{$parent} = $parent_attributes
      if $parent_attributes;
  }

  return undef
    if scalar( keys %{ $self->{inherited_attributes} } ) == 0;
  return $self->{inherited_attributes};
}

# returns undef or hash ref of local methods.
sub local_methods {
  my $self = shift;

  #must run roles function object before this one
  $self->roles            unless $self->{functions_run}->{roles};
  $self->local_attributes unless $self->{functions_run}->{local_attributes};

  my $meta_object = $self->{'meta_object'};

  for my $method ( $meta_object->get_method_list() ) {
    next
      if $self->{local_attributes}->{ $method
        }; # hide methods that are just attribute accessors if are the same name
    next if $self->{role_method_exclusions}->{$method};
    $self->{local_methods}->{$method} = $self->get_method_source($method);
  }

  $self->{functions_run}->{local_methods} = 1;
  return $self->{local_methods};
}

sub inherited_methods {
  my $self = shift;

  $self->roles         unless $self->{functions_run}->{roles};
  $self->class_parents unless $self->{functions_run}->{class_parents};

  foreach my $parent ( @{ $self->{parents} } ) {
    my $parent_doc;
    if( $parent eq 'Moose::Object' ) {
      $parent_doc = MooseX::Documenter->new( $self->{moose_lib}, $parent );
    }
    else {
      $parent_doc = MooseX::Documenter->new( $self->{user_lib}, $parent );
    }

    $parent_doc->setmooselib( $self->{moose_lib} );

    $self->{inherited_methods}->{$parent} = $parent_doc->local_methods;
  }

  return undef
    if scalar( keys %{ $self->{inherited_methods} } ) == 0;
  return $self->{inherited_methods};
}

#return undef or array ref of parents.
sub class_parents {
  my $self = shift;

  return $self->{parents} if $self->{functions_run}->{class_parents};
  $self->{functions_run}->{class_parents} = 1;

  return undef if $self->is_role;

  my @classes    = $self->{meta_object}->linearized_isa;
  my $class_size = @classes;

  for( my $i = 1 ; $i < $class_size ; $i++ ) {
    push( @{ $self->{parents} }, $classes[$i] );
  }

  return undef if scalar( @{ $self->{parents} } ) == 0;
  return $self->{parents};
}

# returns array_ref of role name(s) or undef
sub roles {
  my $self        = shift;
  my $meta_object = $self->{meta_object};

  my @return = ();

  $self->{functions_run}->{roles} = 1;

  return undef if $self->is_role;

  foreach my $role ( @{ $meta_object->roles } ) {
    my $rolename = $role->name();
    push( @return, $rolename );

    #make document class for the role to populate into here.
    my $role_doc = MooseX::Documenter->new( $self->{user_lib}, $rolename );

    for my $attr ( $role->get_attribute_list() ) {
      my $attribute = $meta_object->get_attribute($attr);
      $self->{inherited_attributes}->{$rolename} =
        get_attribute_details($attribute);
    }

    for my $method ( $role->get_method_list() ) {
      $self->{role_method_exclusions}->{$method} = 1;
      $self->{inherited_methods}->{$rolename}->{$method} =
        $role_doc->get_method_source($method);
    }
  }

  return undef if scalar(@return) == 0;
  return \@return;
}

# if is a role or not, 1=yes, 0 = no
sub is_role {
  my $self = shift;

  return 1 if $self->{meta_object}->isa("Moose::Meta::Role");
  return 0;
}

sub get_attribute_details {
  my $attribute = shift;

  my $details;
  $details->{is}  = $attribute->{is}  || '';
  $details->{isa} = $attribute->{isa} || '';

  my @modifiers;
  foreach
    my $mod (qw/ required lazy lazy_build coerce weak_ref trigger handles /) {
    push @modifiers, $mod if $attribute->{$mod};
  }

  $details->{modifiers} = join ',', @modifiers;

  return $details;
}

# returns undef or the source code of method.
sub get_method_source {
  my $self   = shift;
  my $method = shift;

  # Find all the named subroutines
  my $sub_nodes =
    $self->{ppi_object}
    ->find( sub { $_[1]->isa('PPI::Statement::Sub') and $_[1]->name } );

  return undef unless $sub_nodes;
  my @nodes = @{$sub_nodes};

  foreach my $node (@nodes) {
    if( $node->name eq $method ) { return $node->content; }
  }

  return undef;
}

1;
__END__

=head1 NAME

MooseX::Documenter - class for getting Moose documentation for your Moose classes

=head1 SYNOPSIS

Using the library:

  use MooseX::Documenter;
  my $doc = MooseX::Documenter->new('/path/to/Moose/classes/','module::name::of::class');

Configuring the path to where Moose::Object resides:

  $doc->setmooselib('/path/to/lib/where/Moose/Object/is/');

Getting what local attributes exist for your Moose class:
  
  my $local_attributes = $doc->local_attributes;

Getting what inherited attributes exist for your Moose class:

  my $inherited_attributes = $doc->inherited_attributes;

Getting what local methods exist for your Moose class:

  my $local_methods = $doc->local_methods;

Getting what inherited methods exist for your Moose class:

  my $inherited_methods = $doc->inherited_methods;

Getting what parents exist for your Moose class:

  my $parents = $doc->class_parents;

Getting what roles exist for your Moose class:

  my $roles = $doc->roles;

=head1 DESCRIPTION

This module provides a simple way to autodocument your Moose modules.  While PPI is good for normal perl class and objects, it does not work for Moose.

This module is intended to help make documentation from your Moose classes.  It will not only document what your Moose classes do but also make it easy to see the relationships between your various Moose classes.

=head1 Methods

=head2 new

Params: '/path/to/Moose/classes/','module::name::of::class'
Returns a MooseX::Documenter for the specified moose class.  Takes a path to add to the perl lib path for the system to find your moose class and the name of the moose class.

=head2 setmooselib

Params: '/path/to/lib/where/Moose/Object/is/'
Returns the path that was set.  The path you give should be the perl lib path you'de need to give the system to find the Moose::Object class.  This documenter needs this to document what is in Moose::Object for you as all your non-role Moose items should inherit from Moose::Object.

=head2 local_attributes

Returns undef or a hash ref of attributes.  Each attribute name is the key and each value is another hash ref of information on the individual attribute.  This individual attribute hash ref will have is=>is_value, isa=>isa_value, modifiers=>comma_seperated_list.  This comma seperated list may contain: required, lazy, lazy_build, coerce, weak_ref, trigger, handles.

=head2 inherited_attributes

Returns undef or a hash ref of inherited attributes.  Each parent object name is the key and each value is a hash ref identical to what the local_attributes function returns.

=head2 local_methods

Returns undef or a hash ref of local methods.  Each method name is the key and each value is the source code of the local method.

=head2 inherited_methods

Returns undef or a hash ref of inherited methods.  Each parent object name is the key and each value is a hash ref idential to what the local_methods function returns.

=head2 class_parents

Returns undef or an array ref of all parent names in your Moose class.

=head2 roles

Returns undef or an array ref of all roles in your Moose class.

=head1 SEE ALSO

  You should review the Moose Documentation on cpan on rules for your Moose classes.  This module assumes that Moose syntax and other rules are followed.  For the most part, if its not valid Moose, it'll blow up.

=head1 AUTHOR

David Bury, E<lt>dsbike@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Bury

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
