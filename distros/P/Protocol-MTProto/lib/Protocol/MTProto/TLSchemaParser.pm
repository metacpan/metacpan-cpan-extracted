#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Protocol::MTProto::TLSchemaParser;

use strict;
use warnings;
use base qw( Parser::MGC );
Parser::MGC->VERSION( '0.16' );  # ->committed_scope_of

use Struct::Dumb qw( readonly_struct );

our $VERSION = '0.01';

# C-like block and C++-like line comments
use constant pattern_comment => qr{ //.*\n | /\*(?s:.*)\*/ }x;

# Regular identifiers may not begin with "_"
use constant pattern_ident => qr/[[:alpha:]][[:alnum:]_]*/;

=head1 NAME

C<Protocol::MTProto::TLSchemaParser> - a parser for TL schema declarations

=head1 SYNOPSIS

 my $parser = Protocol::MTProto::TLSchemaParser->new;

 my $declarations = $parser->from_file( "telegram-l57.tl" );

 # $declarations is now a reference to an array of Declarations

=head1 DESCRIPTION

This subclass of L<Parser::MGC> recognises the TL schema grammar. Or, at
least, at this early version it recognises a subset of the grammar sufficient
to pass its own unit tests and to parse the F<Telegram> TL schema files. It
does not yet recognise the full TL grammar.

Details of this module should be considered very subject to change as the
implementation progresses.

=head1 RETURNED TYPES

=cut

# See also
#   https://core.telegram.org/mtproto/TL
#   https://core.telegram.org/mtproto/TL-combinators

sub parse
{
   my $self = shift;

   local $self->{declaration_kind} = "constructor";

   # A schema is simply a sequence of declarations
   return $self->sequence_of( 'parse_decl' );
}

=head2 Declaration

The toplevel parse result is a reference to an array of C<Declaration>
instances. Each instance relates to a single declaration from the schema file.

Responds to the following accessors:

=head3 ident

A string containing the full identifier name, including the namespace prefix.

=head3 number

A 32bit number giving the parsed identification hash from the schema file, or
C<undef> if one was not given in the file. Note that this implementation does
not generate numbers by CRC32 hashes at present.

=head3 optargs

Either C<undef>, or a reference to a non-empty array of C<Argument> instances
relating to the optional arguments of the declaration.

=head3 args

Either C<undef>, or a reference to a non-empty array of C<Argument> instances
relating to the required arguments of the declaration.

=head3 result_type

A L</Type> instance giving this constructor's result type.

=head3 kind

Either the string C<constructor> if the declaration was parsed before
encountering the C<---functions---> marker, or the string C<function> if
parsed after it.

=cut

readonly_struct Declaration => [qw(
   ident number optargs args result_type
   kind
)];

sub parse_decl
{
   my $self = shift;

   # As a special case, we accept the literal
   #   "---functions---"
   # marker
   if( $self->expect( qr/(?:---functions---)?/ ) ) {
      $self->{declaration_kind} = "function";
      return ();
   }

   # A declaration is
   #   NS-IDENT [ "#" NUMBER ] [ OPT-ARGS...] [ ARGS... ] "=" RESULT-TYPE

   my $ident = $self->parse_namespaced_ident;
   $self->commit;

   my $number = $self->maybe( sub {
      $self->expect( "#" );
      $self->commit;
      hex $self->expect( qr/[0-9a-f]{1,8}/i );
   });

   my $optargs = $self->sequence_of( 'parse_optarg' );
   if( $optargs and @$optargs ) {
      # Flatten the lists
      $optargs = [ map { @$_ } @$optargs ];
   }
   else {
      undef $optargs;
   }

   my $args = $self->sequence_of( 'parse_arg' );
   @$args or undef $args;

   $self->expect( "=" );

   my $result_type = $self->parse_result_type;

   $self->expect( ";" );

   return Declaration(
      $ident, $number, $optargs, $args, $result_type,
      $self->{declaration_kind},
   );
}

=head2 Argument

Each element of the C<args> and C<optargs> arrays for a L</Declaration> will
be an C<Argument> instance. Each relates to a single positional argument of
the declaration.

Responds to the following accessors:

=head3 name

Either C<undef> or a string giving the name of the argument.

=head3 type

A L</Type> instance giving this argument's type.

=head3 conditional_on

Either C<undef>, or a string giving the name of an earlier argument that this
argument is conditional on.

=head3 condition_mask

Either C<undef>, or a number giving the bitmask to apply to the earlier that
argument this argument is conditional on.

=head3 has_pling

True if the type of this argument was declared using the C<!> modifier.

=cut

readonly_struct Argument => [qw(
   name type conditional_on condition_mask has_pling
)];

readonly_struct Repetition => [qw(
   multiplicity args
)];

sub parse_arg
{
   my $self = shift;

   # ARG is any of
   #   VAR-IDENT-OPT ":" [ CONDITIONAL-DEF ] [ "!" ] TYPE-TERM
   #   [ VAR-IDENT-OPT ":" ] [ MULTIPLICITY "*" ] "[" [ ARG... ] "]"
   #   "(" [ VAR-IDENT-OPT... ]+ : [ "!" ] TYPE-TERM ")" -- TODO
   #   [ "!" ] TYPE-TERM

   $self->any_of(
      sub {
         my $name = $self->token_var_ident( optional => 1 );
         $self->expect( ":" );

         my $conditional_arg;
         my $condition_mask;
         $self->maybe( sub {
            $conditional_arg = $self->token_var_ident;
            $self->expect( "." );
            $condition_mask = 1 << $self->token_int;
            $self->expect( "?" );
         });

         my $has_pling = $self->expect( qr/!?/ );
         my $type = $self->parse_type_term;
         return Argument( $name, $type, $conditional_arg, $condition_mask, $has_pling );
      },
      sub {
         # TODO -- var-ident-opt, ":"
         # TODO -- multiplicity
         my $args = $self->committed_scope_of(
            "[",
            sub { $self->sequence_of( 'parse_arg' ) },
            "]",
         );
         # TODO: name, multiplicity
         return Repetition( "#", $args );
      },
      sub {
         my $has_pling = $self->expect( qr/!?/ );
         return Argument( undef, $self->parse_type_term, undef, undef, $has_pling );
      },
   );
}

sub parse_optarg
{
   my $self = shift;

   # OPT-ARGS is
   #   "{" [ IDENTS... ]+ ":" [ "!" ] TYPE-EXPR "}"

   $self->committed_scope_of(
      "{",
      sub {
         my $names = $self->sequence_of( 'token_var_ident' );
         @$names or $self->fail( "Expected at least one identifier name" );

         $self->expect( ":" );
         my $has_pling = $self->expect( qr/!?/ );
         my $type = $self->parse_type_expr;

         # Expand the list of names into a list of individual argument instances
         return [ map { Argument( $_, $type, undef, undef, $has_pling ) } @$names ];
      },
      "}"
   );
}

*parse_type_expr = \&parse_expr;
sub parse_expr
{
   my $self = shift;

   # EXPR is a sequence of SUBEXPR
   #   TODO: multiple of them imply being combined together in some 
   #   polymorphic type but I don't quite understand how

   my $exprs = $self->sequence_of( 'parse_subexpr' );
   return $exprs->[0] if @$exprs == 1;

   $self->fail( "TODO: combine subexprs" );
}

sub parse_subexpr
{
   my $self = shift;
   # SUBEXPR is any of
   #   TERM
   #   NAT-CONST "+" SUBEXPR -- TODO
   #   SUBEXPR "+" NAT-CONST -- TODO

   return $self->parse_term;
}

*parse_type_term = \&parse_term; # TODO - check that the result definitely is a type
sub parse_term
{
   my $self = shift;

   # TERM is any of
   #   "(" EXPR ")" -- TODO
   #   TYPE-IDENT [ "<" [ EXPR "," EXPR... ]+ ">" ]
   #   VAR-IDENT -- TODO
   #   NAT-CONST -- TODO
   #   "%" TERM  -- TODO

   $self->parse_type_ident( allow_polymorphic => 1 );
}

=head2 Type

The C<result_type> of a L</Declaration>, and the C<type> of an L</Argument>
will be a C<Type> instance. At present, no attempt is made to intern the
instances; comparison for equallity should be performed on the string name and
its subtypes, not object identity.

Responds to the following accessors:

=head3 name

A string giving the name of the type.

=head3 is_boxed

True if the type is boxed; that is, its name begins with a capital letter.

=head3 is_polymorphic

True if the type is polymorphic.

=head3 subtypes (optional)

If the type is polymorphic, a reference to an array of other L</Type>
instances corresponding to the subtypes. If the type is not polymorphic this
accessor will not exist.

=cut

readonly_struct BaseType => [qw(
   name is_boxed is_polymorphic
)];

readonly_struct PolymorphicType => [qw(
   name is_boxed is_polymorphic subtypes
)];

sub parse_type_ident
{
   my $self = shift;
   my %args = @_;

   # TYPE-IDENT is any of
   #   BOXED-TYPE-IDENT
   #   LC-IDENT-NS
   #   "#"
   #
   # The first two of which are covered by parse_namespaced_ident

   my $base_type = $self->any_of(
      sub {
         my $name = $self->parse_namespaced_ident;
         return BaseType( $name, scalar $name =~ m/(?:\.|^)[A-Z]/, 0 );
      },
      sub { $self->expect( "#" ); return BaseType( "#", 0, 0 ) },
   );

   return $base_type unless $args{allow_polymorphic};

   my $subtypes = $self->maybe( sub {
      $self->committed_scope_of(
         "<",
         sub {
            $self->list_of( ",", 'parse_expr' );
            # TODO - check nonempty, types
         },
         ">",
      );
   });

   return $base_type if !$subtypes;

   return PolymorphicType(
      $base_type->name, $base_type->is_boxed, 1, $subtypes
   );
}

sub parse_result_type
{
   my $self = shift;

   # RESULT-TYPE is any of
   #   BOXED-TYPE-IDENT [ SUBEXPR ... ]
   #   BOXED-TYPE-IDENT "<" [ SUBEXPR "," SUBEXPR... ]+ ">"

   my $type = $self->parse_type_ident( allow_polymorphic => 1 );
   $type->is_boxed or $self->fail( "Result type must be Boxed" );

   return $type if $type->is_polymorphic;

   my $subtypes = $self->sequence_of( 'parse_subexpr' );
   # TODO - check these are types

   if( $subtypes and @$subtypes ) {
      return PolymorphicType(
         $type->name, $type->is_boxed, 1, $subtypes
      );
   }

   return $type;
}

sub parse_namespaced_ident
{
   my $self = shift;

   my $namespace = $self->maybe( sub {
      my $ns = $self->token_ident;
      $self->expect( "." );
      $ns;
   });

   my $ident = $self->token_ident;

   return "$namespace.$ident" if defined $namespace;
   return "$ident";
}

sub token_var_ident
{
   my $self = shift;
   my %args = @_;

   my $ident = $self->token_ident;
   $self->fail( "Require a named identifier" ) if $ident eq "_" and !$args{optional};

   return $ident;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
