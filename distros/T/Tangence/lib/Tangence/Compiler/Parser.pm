#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::Compiler::Parser 0.33;
class Tangence::Compiler::Parser :isa(Parser::MGC);

use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Match;

use File::Basename qw( dirname );

use Tangence::Constants;

# Parsing is simpler if we treat Package.Name as a simple identifier
use constant pattern_ident => qr/[[:alnum:]_][\w.]*/;

use constant pattern_comment => qr/#.*\n/;

=head1 NAME

C<Tangence::Compiler::Parser> - parse C<Tangence> interface definition files

=head1 DESCRIPTION

This subclass of L<Parser::MGC> parses a L<Tangence> interface definition and
returns a metadata tree.

=cut

=head1 GRAMMAR

The top level of an interface definition file contains C<include> directives
and C<class> and C<struct> definitions.

=head2 include

An C<include> directive imports the definitions from another file, named
relative to the current file.

   include "filename.tan"

=head2 class

A C<class> definition defines the set of methods, events and properties
defined by a named class.

   class N {
      ...
   }

The contents of the class block will be a list of C<method>, C<event>, C<prop>
and C<isa> declarations.

=head2 struct

A C<struct> definition defines the list of fields contained within a named
structure type.

   struct N {
      ...
   }

The contents of the struct block will be a list of C<field> declarations.

=cut

field $_package;

# Parser::MGC version 0.20 adds this method. Before then, this workaround is
# known to be safe
if( $Parser::MGC::VERSION < 0.20 ) {
   *filename = sub ( $self ) { $self->{filename} };
}

method parse
{
   dynamically $_package = \my %package;

   while( !$self->at_eos ) {
      match( $self->token_kw(qw( class struct include )) : eq ) {
         case( 'class' ) {
            my $classname = $self->token_ident;

            exists $package{$classname} and
               $self->fail( "Already have a class or struct called $classname" );

            my $class = $self->make_class( name => $classname );
            $package{$classname} = $class;

            $self->scope_of( '{', sub { $self->parse_classblock( $class ) }, '}' ),
         }
         case( 'struct' ) {
            my $structname = $self->token_ident;

            exists $package{$structname} and
               $self->fail( "Already have a class or struct called $structname" );

            my $struct = $self->make_struct( name => $structname );
            $package{$structname} = $struct;

            $self->scope_of( '{', sub { $self->parse_structblock( $struct ) }, '}' ),
         }
         case( 'include' ) {
            my $filename = dirname($self->filename) . "/" . $self->token_string;

            my $subparser = (ref $self)->new;
            my $included = $subparser->from_file( $filename );

            foreach my $classname ( keys %$included ) {
               exists $package{$classname} and
                  $self->fail( "Cannot include '$filename' as class $classname collides" );

               $package{$classname} = $included->{$classname};
            }
         }
         default {
            $self->fail( "Expected keyword, found $_" );
         }
      }
   }

   return \%package;
}

=head2 method

A C<method> declaration defines one method in the class, giving its name (N)
and types of its arguments and and return (T).

   method N(T, T, ...) -> T;

=head2 event

An C<event> declaration defines one event raised by the class, giving its name
(N) and types of its arguments (T).

   event N(T, T, ...);

=head2 prop

A C<prop> declaration defines one property supported by the class, giving its
name (N), dimension (D) and type (T). It may be declared as a C<smashed>
property.

   [smashed] prop N = D of T;

Scalar properties may omit the C<scalar of>, by supplying just the type

   [smashed] prop N = T;

=head2 isa

An C<isa> declaration declares a superclass of the class, by its name (C)

   isa C;

=cut

method parse_classblock ( $class )
{
   my %methods;
   my %events;
   my %properties;
   my @superclasses;

   while( !$self->at_eos ) {
      match( $_ = $self->token_kw(qw( method event prop smashed isa )) : eq ) {
         case( 'method' ) {
            my $methodname = $self->token_ident;

            exists $methods{$methodname} and
               $self->fail( "Already have a method called $methodname" );

            my $args = $self->parse_arglist;
            my $ret;

            $self->maybe( sub {
               $self->expect( '->' );

               $ret = $self->parse_type;
            } );

            $methods{$methodname} = $self->make_method(
               class     => $class,
               name      => $methodname,
               arguments => $args,
               ret       => $ret,
            );
         }

         case( 'event' ) {
            my $eventname = $self->token_ident;

            exists $events{$eventname} and
               $self->fail( "Already have an event called $eventname" );

            my $args = $self->parse_arglist;

            $events{$eventname} = $self->make_event(
               class     => $class,
               name      => $eventname,
               arguments => $args,
            );
         }

         case( 'smashed' ), case( 'prop' ) {
            my $smashed = 0;

            if( $_ eq 'smashed' ) {
               $smashed = 1;
               $self->expect( 'prop' );
            }

            my $propname = $self->token_ident;

            exists $properties{$propname} and
               $self->fail( "Already have a property called $propname" );

            $self->expect( '=' );

            my $dim = DIM_SCALAR;
            $self->maybe( sub {
               $dim = $self->parse_dim;
               $self->expect( 'of' );
            } );

            my $type = $self->parse_type;

            $properties{$propname} = $self->make_property(
               class      => $class,
               name       => $propname,
               smashed    => $smashed,
               dimension  => $dim,
               type       => $type,
            );
         }

         case( 'isa' ) {
            my $supername = $self->token_ident;

            my $super = $_package->{$supername} or
               $self->fail( "Unrecognised superclass $supername" );

            push @superclasses, $super;
         }
      }

      $self->expect( ';' );
   }

   $class->define(
      methods      => \%methods,
      events       => \%events,
      properties   => \%properties,
      superclasses => \@superclasses,
   );
}

method parse_arglist
{
   return $self->scope_of(
      "(",
      sub { $self->list_of( ",", \&parse_arg ) },
      ")",
   );
}

method parse_arg
{
   my $name;
   my $type = $self->parse_type;
   $self->maybe( sub {
      $name = $self->token_ident;
   } );
   return $self->make_argument( name => $name, type => $type );
}

method parse_structblock ( $struct )
{
   my @fields;
   my %fieldnames;

   while( !$self->at_eos ) {
      match( $self->token_kw(qw( field )) : eq ) {
         case( 'field' ) {
            my $fieldname = $self->token_ident;

            exists $fieldnames{$fieldname} and
               $self->fail( "Already have a field called $fieldname" );

            $self->expect( '=' );

            my $type = $self->parse_type;

            push @fields, $self->make_field(
               name => $fieldname,
               type => $type,
            );
            $fieldnames{$fieldname}++;
         }
      }
      $self->expect( ';' );
   }

   $struct->define(
      fields => \@fields,
   );
}

=head2 Types

The following basic type names are recognised

   bool int str obj any
   s8 s16 s32 s64 u8 u16 u32 u64

Aggregate types may be formed of any type (T) by

   list(T) dict(T)

=cut

my @basic_types = qw(
   bool
   int
   s8 s16 s32 s64 u8 u16 u32 u64
   float
   float16 float32 float64
   str
   obj
   any
);

method parse_type
{
   $self->any_of(
      sub {
         my $aggregate = $self->token_kw(qw( list dict ));

         $self->commit;

         my $membertype = $self->scope_of( "(", \&parse_type, ")" );

         return $self->make_type( $aggregate => $membertype );
      },
      sub {
         my $typename = $self->token_ident;

         grep { $_ eq $typename } @basic_types or
            $self->fail( "'$typename' is not a typename" );

         return $self->make_type( $typename );
      },
   );
}

my %dimensions = (
   scalar => DIM_SCALAR,
   hash   => DIM_HASH,
   queue  => DIM_QUEUE,
   array  => DIM_ARRAY,
   objset => DIM_OBJSET,
);

method parse_dim
{
   my $dimname = $self->token_kw( keys %dimensions );

   return $dimensions{$dimname};
}

=head1 SUBCLASS METHODS

If this class is subclassed, the following methods may be overridden to
customise the behaviour. They allow the subclass to return different objects
in the syntax tree.

=cut

=head2 make_class

   $class = $parser->make_class( name => $name )

Return a new instance of L<Tangence::Meta::Class> to go in a package. The
parser will call C<define> on it.

=cut

method make_class
{
   require Tangence::Meta::Class;
   return Tangence::Meta::Class->new( @_ );
}

=head2 make_struct

   $struct = $parser->make_struct( name => $name )

Return a new instance of L<Tangence::Meta::Struct> to go in a package. The
parser will call C<define> on it.

=cut

method make_struct
{
   require Tangence::Meta::Struct;
   return Tangence::Meta::Struct->new( @_ );
}

=head2 make_method

   $method = $parser->make_method( %args )

=head2 make_event

   $event = $parser->make_event( %args )

=head2 make_property

   $property = $parser->make_property( %args )

Return a new instance of L<Tangence::Meta::Method>, L<Tangence::Meta::Event>
or L<Tangence::Meta::Property> to go in a class.

=cut

method make_method
{
   require Tangence::Meta::Method;
   return Tangence::Meta::Method->new( @_ );
}

method make_event
{
   require Tangence::Meta::Event;
   return Tangence::Meta::Event->new( @_ );
}

method make_property
{
   require Tangence::Meta::Property;
   return Tangence::Meta::Property->new( @_ );
}

=head2 make_argument

   $argument = $parser->make_argument( %args )

Return a new instance of L<Tangence::Meta::Argument> to use for a method
or event argument.

=cut

method make_argument
{
   require Tangence::Meta::Argument;
   return Tangence::Meta::Argument->new( @_ );
}

=head2 make_field

   $field = $parser->make_field( %args )

Return a new instance of L<Tangence::Meta::Field> to use for a structure type.

=cut

method make_field
{
   require Tangence::Meta::Field;
   return Tangence::Meta::Field->new( @_ );
}

=head2 make_type

   $type = $parser->make_type( $primitive_name )

   $type = $parser->make_type( $aggregate_name => $member_type )

Return an instance of L<Tangence::Meta::Type> representing the given
primitive or aggregate type name. An implementation is allowed to use
singleton objects and return identical objects for the same primitive name or
aggregate and member type.

=cut

method make_type
{
   require Tangence::Meta::Type;
   return Tangence::Meta::Type->make( @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
