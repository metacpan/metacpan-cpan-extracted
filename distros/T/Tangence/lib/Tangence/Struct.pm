#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::Struct 0.32;
class Tangence::Struct :isa(Tangence::Meta::Struct);

use Carp;

use meta 0.003_002;
no warnings 'meta::experimental';

use Tangence::Type;
use Tangence::Meta::Field;

=head1 NAME

C<Tangence::Struct> - server implementation of a C<Tangence> struct

=head1 DESCRIPTION

This module is a component of L<Tangence::Server>. It is not intended for
end-user use directly.

=cut

our %STRUCTS_BY_NAME;
our %STRUCTS_BY_PERLNAME;

sub make ( $class, %args )
{
   my $name = $args{name};

   return $STRUCTS_BY_NAME{$name} //= $class->new( %args );
}

sub declare ( $class, $perlname, %args )
{
   ( my $name = $perlname ) =~ s{::}{.}g;
   $name = $args{name} if $args{name};

   my @fields;
   for( $_ = 0; $_ < @{$args{fields}}; $_ += 2 ) {
      push @fields, Tangence::Meta::Field->new(
         name => $args{fields}[$_],
         type => Tangence::Type->make_from_sig( $args{fields}[$_+1] ),
      );
   }

   my $self = $class->make( name => $name );
   $self->_set_perlname( $perlname );

   $self->define(
      fields => \@fields,
   );

   $STRUCTS_BY_PERLNAME{$perlname} = $self;
   return $self;
}

sub declare_builtin
{
   my $class = shift;
   my $self = $class->declare( @_ );

   $Tangence::Stream::ALWAYS_PEER_HASSTRUCT{$self->perlname} = [ $self, my $structid = ++$Tangence::Struct::BUILTIN_STRUCTIDS ];
   $Tangence::Stream::BUILTIN_ID2STRUCT{$structid} = $self;

   return $self;
}

sub define
{
   my $self = shift;
   $self->SUPER::define( @_ );

   my $class = $self->perlname;
   my $classmeta = meta::package->get( $class );
   my @fieldnames = map { $_->name } $self->fields;

   # Now construct the actual perl package
   my %subs = (
      new => sub ( $class, %args ) {
         exists $args{$_} or croak "$class is missing $_" for @fieldnames;
         bless [ @args{@fieldnames} ], $class;
      },
   );
   $subs{$fieldnames[$_]} = do { my $i = $_; sub { shift->[$i] } } for 0 .. $#fieldnames;

   foreach my $name ( keys %subs ) {
      next if $classmeta->can_symbol( '&' . $name );
      $classmeta->add_symbol( '&' . $name => $subs{$name} );
   }
}

sub for_name ( $class, $name )
{
   return $STRUCTS_BY_NAME{$name} // croak "Unknown Tangence::Struct for '$name'";
}

sub for_perlname ( $class, $perlname )
{
   return $STRUCTS_BY_PERLNAME{$perlname} // croak "Unknown Tangence::Struct for '$perlname'";
}

field $perlname :writer(_set_perlname);

method perlname
{
   return $perlname if defined $perlname;
   ( $perlname = $self->name ) =~ s{\.}{::}g; # s///rg in 5.14
   return $perlname;
}

Tangence::Struct->declare_builtin(
   "Tangence::Struct::Class",
   name => "Tangence.Class",
   fields => [
      methods      => "dict(any)",
      events       => "dict(any)",
      properties   => "dict(any)",
      superclasses => "list(str)",
   ],
);

Tangence::Struct->declare_builtin(
   "Tangence::Struct::Method",
   name => "Tangence.Method",
   fields => [
      arguments => "list(str)",
      returns   => "str",
   ],
);

Tangence::Struct->declare_builtin(
   "Tangence::Struct::Event",
   name => "Tangence.Event",
   fields => [
      arguments => "list(str)",
   ],
);

Tangence::Struct->declare_builtin(
   "Tangence::Struct::Property",
   name => "Tangence.Property",
   fields => [
      dimension => "int",
      type      => "str",
      smashed   => "bool",
   ],
);

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
