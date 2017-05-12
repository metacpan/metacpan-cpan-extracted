package ExtUtils::XSpp::Typemap;
use strict;
use warnings;

require ExtUtils::XSpp::Typemap::parsed;
require ExtUtils::XSpp::Typemap::simple;
require ExtUtils::XSpp::Typemap::reference;

=head1 NAME

ExtUtils::XSpp::Typemap - map types

=cut

sub new {
  my $class = shift;
  my $this = bless {}, $class;

  $this->init( @_ );

  return $this;
}

=head2 ExtUtils::XSpp::Typemap::type

Returns the ExtUtils::XSpp::Node::Type that is used for this typemap.

=cut

sub type { $_[0]->{TYPE} }

=head2 ExtUtils::XSpp::Typemap::cpp_type()

Returns the C++ type to be used for the local variable declaration.

=head2 ExtUtils::XSpp::Typemap::input_code( perl_argument_name, cpp_var_name1, ... )

Code to put the contents of the perl_argument (typically ST(x)) into
the C++ variable(s).

=head2 ExtUtils::XSpp::Typemap::output_code()

=head2 ExtUtils::XSpp::Typemap::cleanup_code()

=head2 ExtUtils::XSpp::Typemap::call_parameter_code( parameter_name )

=head2 ExtUtils::XSpp::Typemap::call_function_code( function_call_code, return_variable )

=cut

sub init { }

sub cpp_type { die; }
sub input_code { die; }
sub precall_code { undef }
sub output_code { undef }
sub cleanup_code { undef }
sub call_parameter_code { undef }
sub call_function_code { undef }
sub output_list { undef }

my @typemaps;

# add typemaps for basic C types
add_default_typemaps();

sub add_typemap_for_type {
  my( $type, $typemap ) = @_;

  unshift @typemaps, [ $type, $typemap ];
}

# a weak typemap does not override an already existing typemap for the
# same type
sub add_weak_typemap_for_type {
  my( $type, $typemap ) = @_;

  foreach my $t ( @typemaps ) {
    return if $t->[0]->equals( $type );
  }
  unshift @typemaps, [ $type, $typemap ];
}

sub get_typemap_for_type {
  my $type = shift;

  foreach my $t ( @typemaps ) {
    return ${$t}[1] if $t->[0]->equals( $type );
  }

  # construct verbose error message:
  my $errmsg = "No typemap for type " . $type->print
               . "\nThere are typemaps for the following types:\n";
  my @types;
  foreach my $t (@typemaps) {
    push @types, "  - " . $t->[0]->print . "\n";
  }

  if (@types) {
    $errmsg .= join('', @types);
  }
  else {
    $errmsg .= "  (none)\n";
  }
  $errmsg .= "Did you forget to declare your type in an XS++ typemap?";

  Carp::confess( $errmsg );
}

# adds default typemaps for C* and C&
sub add_class_default_typemaps {
  my( $name ) = @_;

  my $ptr = ExtUtils::XSpp::Node::Type->new
                ( base    => $name,
                  pointer => 1,
                  );
  my $ref = ExtUtils::XSpp::Node::Type->new
                ( base      => $name,
                  reference => 1,
                  );

  add_weak_typemap_for_type
      ( $ptr, ExtUtils::XSpp::Typemap::simple->new( type => $ptr ) );
  add_weak_typemap_for_type
      ( $ref, ExtUtils::XSpp::Typemap::reference->new( type => $ref ) );
}

sub add_default_typemaps {
  # void, integral and floating point types
  foreach my $t ( 'char', 'short', 'int', 'long',
                  'unsigned char', 'unsigned short', 'unsigned int',
                  'unsigned long', 'void',
                  'float', 'double', 'long double' ) {
    my $type = ExtUtils::XSpp::Node::Type->new( base => $t );

    ExtUtils::XSpp::Typemap::add_typemap_for_type
        ( $type, ExtUtils::XSpp::Typemap::simple->new( type => $type ) );
  }

  # char*, const char*
  my $char_p = ExtUtils::XSpp::Node::Type->new
                   ( base    => 'char',
                     pointer => 1,
                     );

  ExtUtils::XSpp::Typemap::add_typemap_for_type
      ( $char_p, ExtUtils::XSpp::Typemap::simple->new( type => $char_p ) );

  my $const_char_p = ExtUtils::XSpp::Node::Type->new
                         ( base    => 'char',
                           pointer => 1,
                           const   => 1,
                           );

  ExtUtils::XSpp::Typemap::add_typemap_for_type
      ( $const_char_p, ExtUtils::XSpp::Typemap::simple->new( type => $const_char_p ) );
}

1;
