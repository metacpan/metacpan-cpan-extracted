#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::Class 0.33;
class Tangence::Class :isa(Tangence::Meta::Class);

use Tangence::Constants;

use Tangence::Property;

use Tangence::Meta::Method;
use Tangence::Meta::Event;
use Tangence::Meta::Argument;

use Carp;

use meta 0.007;  # set_subname
no warnings 'meta::experimental';

=head1 NAME

C<Tangence::Class> - server implementation of a C<Tangence> class

=head1 DESCRIPTION

This module is a component of L<Tangence::Server>. It is not intended for
end-user use directly.

=cut

our %CLASSES; # cache one per class, keyed by _Tangence_ class name

sub make ( $class, %args )
{
   my $name = $args{name};

   return $CLASSES{$name} //= $class->new( %args );
}

sub _new_type ( $sig )
{
   return Tangence::Type->make_from_sig( $sig );
}

sub declare ( $class, $perlname, %args )
{
   ( my $name = $perlname ) =~ s{::}{.}g;

   if( exists $CLASSES{$name} ) {
      croak "Cannot re-declare $name";
   }

   my $self = $class->make( name => $name );

   my %methods;
   foreach ( keys %{ $args{methods} } ) {
      my %params = %{ $args{methods}{$_} };
      $methods{$_} = Tangence::Meta::Method->new(
         class => $self,
         name => $_,
         arguments => [ map {
            Tangence::Meta::Argument->new( name => $_->[0], type => _new_type( $_->[1] ) )
         } @{ delete $params{args} } ],
         ret => _new_type( delete $params{ret} ),
         %params,
      );
   }

   my %events;
   foreach ( keys %{ $args{events} } ) {
      my %params = %{ $args{events}{$_} };
      $events{$_} = Tangence::Meta::Event->new(
         class => $self,
         name => $_,
         arguments => [ map {
            Tangence::Meta::Argument->new( name => $_->[0], type => _new_type( $_->[1] ) )
         } @{ delete $params{args} } ],
         %params,
      );
   }

   my %properties;
   foreach ( keys %{ $args{props} } ) {
      my %params = %{ $args{props}{$_} };
      $properties{$_} = Tangence::Property->new(
         class => $self,
         name => $_,
         dimension => ( delete $params{dim} ) || DIM_SCALAR,
         type => _new_type( delete $params{type} ),
         %params,
      );
   }

   my @superclasses;
   foreach ( @{ $args{superclasses} } ) {
      push @superclasses, Tangence::Class->for_perlname( $_ );
   }

   $self->define(
      methods      => \%methods,
      events       => \%events,
      properties   => \%properties,
      superclasses => \@superclasses,
   );
}

method define
{
   $self->SUPER::define( @_ );

   my $class = $self->perlname;
   my $classmeta = meta::package->get( $class );

   my %subs;

   foreach my $prop ( values %{ $self->direct_properties } ) {
      $prop->build_accessor( \%subs );
   }

   foreach my $name ( keys %subs ) {
      next if $classmeta->try_get_symbol( '&' . $name );
      $classmeta->add_symbol(
         '&' . $name => $subs{$name}
      )->set_subname( "${class}::${name}" );
   }
}

sub for_name ( $class, $name )
{
   return $CLASSES{$name} // croak "Unknown Tangence::Class for '$name'";
}

sub for_perlname ( $class, $perlname )
{
   ( my $name = $perlname ) =~ s{::}{.}g;
   return $CLASSES{$name} // croak "Unknown Tangence::Class for '$perlname'";
}

sub superclasses
{
   my $self = shift;

   my @supers = $self->SUPER::superclasses;

   if( !@supers and $self->perlname ne "Tangence::Object" ) {
      @supers = Tangence::Class->for_perlname( "Tangence::Object" );
   }

   return @supers;
}

method method ( $name )
{
   return $self->methods->{$name};
}

method event ( $name )
{
   return $self->events->{$name};
}

method property ( $name )
{
   return $self->properties->{$name};
}

field $smashkeys;

method smashkeys
{
   return $smashkeys //= do {
      my %smash;
      $smash{$_->name} = 1 for grep { $_->smashed } values %{ $self->properties };
      $Tangence::Message::SORT_HASH_KEYS ? [ sort keys %smash ] : [ keys %smash ];
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
