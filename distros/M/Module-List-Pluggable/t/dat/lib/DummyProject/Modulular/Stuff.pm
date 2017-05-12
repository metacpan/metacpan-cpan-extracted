package DummyProject::Modulular::Stuff;
use base qw( Class::Base );

=head1 NAME

DummyProject::Modulular::Stuff - stub that imports methods via Module::List::Pluggable

=head1 SYNOPSIS

   use DummyProject::Modulular::Stuff;
   # whatever

=head1 DESCRIPTION

I have tests that verify that Module::List::Pluggable can be used
to import routines into the "main" namespace, this is a stub
module needed to make sure there are no suprises with other
namespaces.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
# use Hash::Util qw( lock_keys unlock_keys ); # eliminate perl 5.8 dep
use Module::List::Pluggable qw(:all);

our $VERSION = '0.01';
my $DEBUG = 1;

=item new

Instantiates a new List::Filter::Profile object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments, the newly created profile will be empty.

=cut

# Note: "new" (inherited from Class::Base)
# calls the following "init" routine automatically.

=item init

Initialize object attributes and then locks them down to prevent
accidental creation of new ones.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  # unlock_keys( %{ $self } ); # eliminate perl 5.8 dep

  # $self->SUPER::init( $args );  # uncomment if this is a child class

  # define new attributes
  my $attributes = {
           ### fill-in name/value pairs of attributes here
           # name          => $args->{ name },
           plugin_root       => $args->{ plugin_root },
           plugin_exceptions => $args->{ plugin_exceptions },

           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  $self->git_methods_from_plugins();

  # lock_keys( %{ $self } ); # eliminate perl 5.8 dep
  return $self;
}


=item git_methods_from_plugins

Does an import of plugins from the object's plugin_root,
skipping those in the object's plugin_exceptions list.

Returns the number of plugin modules successfully imported.

=cut

sub git_methods_from_plugins {
  my $self = shift;
  my $plugin_root        = $self->plugin_root;
  my $plugin_exceptions  = $self->plugin_exceptions;

  my $count =
    import_modules( $plugin_root,
                    { exceptions => $plugin_exceptions,
                    } );

  return $count;
}



=item test_method_nothing_much

=cut

sub test_method_nothing_much {
  my $self = shift;

  my $retvalue = 0;
  my $result = $self->nothing_much();
  if( $result eq "Nothing much. What's with you?" ) {
    $retvalue = 1;
  }
  return $retvalue;
}


=item test_method_back_atcha

=cut

sub test_method_back_atcha {
  my $self   = shift;
  my $string = shift | 'Ut!';

  my $retvalue = 0;

  my $result = $self->back_atcha( $string );
  if( $result eq "Do you say: $string" ) {
    $retvalue = 1;
  }
  return $retvalue;
}

=back

=head2 basic setters and getters

=over

=item plugin_root

Getter for object attribute plugin_root

=cut

sub plugin_root {
  my $self = shift;
  my $plugin_root = $self->{ plugin_root };
  return $plugin_root;
}

=item set_plugin_root

Setter for object attribute set_plugin_root

=cut

sub set_plugin_root {
  my $self = shift;
  my $plugin_root = shift;
  $self->{ plugin_root } = $plugin_root;
  return $plugin_root;
}


=item plugin_exceptions

Getter for object attribute plugin_exceptions

=cut

sub plugin_exceptions {
  my $self = shift;
  my $plugin_exceptions = $self->{ plugin_exceptions };
  return $plugin_exceptions;
}

=item set_plugin_exceptions

Setter for object attribute set_plugin_exceptions

=cut

sub set_plugin_exceptions {
  my $self = shift;
  my $plugin_exceptions = shift;
  $self->{ plugin_exceptions } = $plugin_exceptions;
  return $plugin_exceptions;
}





1;

=head1 SEE ALSO

L<Module::List::Pluggable>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
13 May 2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
