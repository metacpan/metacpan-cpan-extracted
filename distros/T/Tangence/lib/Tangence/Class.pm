#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Tangence::Class;

use strict;
use warnings;
use base qw( Tangence::Meta::Class );

use Tangence::Constants;

use Tangence::Property;

use Tangence::Meta::Method;
use Tangence::Meta::Event;
use Tangence::Meta::Argument;

use Carp;

BEGIN {
   if( eval { require Sub::Name } ) {
      Sub::Name->import(qw( subname ));
   }
   else {
      # Emulate it by just returning the CODEref and ignoring setting the name
      *subname = sub { $_[1] };
   }
}

our $VERSION = '0.24';

our %metas; # cache one per class, keyed by _Tangence_ class name

sub new
{
   my $class = shift;
   my %args = @_;
   my $name = $args{name};

   return $metas{$name} ||= $class->SUPER::new( @_ );
}

sub _new_type
{
   my ( $sig ) = @_;
   return Tangence::Type->new_from_sig( $sig );
}

sub declare
{
   my $class = shift;
   my ( $perlname, %args ) = @_;

   ( my $name = $perlname ) =~ s{::}{.}g;

   my $self;
   if( exists $metas{$name} ) {
      $self = $metas{$name};
      local $metas{$name};

      my $newself = $class->new( name => $name );

      %$self = %$newself;
   }
   else {
      $self = $class->new( name => $name );
   }

   my %methods;
   foreach ( keys %{ $args{methods} } ) {
      $methods{$_} = Tangence::Meta::Method->new(
         name => $_,
         %{ $args{methods}{$_} },
         arguments => [ map {
            Tangence::Meta::Argument->new( name => $_->[0], type => _new_type( $_->[1] ) )
         } @{ $args{methods}{$_}{args} } ],
         ret => _new_type( $args{methods}{$_}{ret} ),
      );
   }

   my %events;
   foreach ( keys %{ $args{events} } ) {
      $events{$_} = Tangence::Meta::Event->new(
         name => $_,
         %{ $args{events}{$_} },
         arguments => [ map {
            Tangence::Meta::Argument->new( name => $_->[0], type => _new_type( $_->[1] ) )
         } @{ $args{events}{$_}{args} } ],
      );
   }

   my %properties;
   foreach ( keys %{ $args{props} } ) {
      $properties{$_} = Tangence::Property->new(
         name => $_,
         %{ $args{props}{$_} },
         dimension => $args{props}{$_}{dim} || DIM_SCALAR,
         type => _new_type( $args{props}{$_}{type} ),
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

sub define
{
   my $self = shift;
   $self->SUPER::define( @_ );

   my $class = $self->perlname;

   my %subs;

   foreach my $prop ( values %{ $self->direct_properties } ) {
      $prop->build_accessor( \%subs );
   }

   no strict 'refs';
   foreach my $name ( keys %subs ) {
      next if defined &{"${class}::${name}"};
      *{"${class}::${name}"} = subname "${class}::${name}" => $subs{$name};
   }
}

sub for_name
{
   my $class = shift;
   my ( $name ) = @_;

   return $metas{$name} || croak "Unknown Tangence::Class for '$name'";
}

sub for_perlname
{
   my $class = shift;
   my ( $perlname ) = @_;

   ( my $name = $perlname ) =~ s{::}{.}g;
   return $metas{$name} || croak "Unknown Tangence::Class for '$perlname'";
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

sub method
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->methods->{$name};
}

sub event
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->events->{$name};
}

sub property
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->properties->{$name};
}

sub smashkeys
{
   my $self = shift;
   return $self->{smashkeys} ||= do {
      my %smash;
      $smash{$_->name} = 1 for grep { $_->smashed } values %{ $self->properties };
      $Tangence::Message::SORT_HASH_KEYS ? [ sort keys %smash ] : [ keys %smash ];
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
