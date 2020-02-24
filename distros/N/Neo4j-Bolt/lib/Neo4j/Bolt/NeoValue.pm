package Neo4j::Bolt::NeoValue;
#use lib '../lib';
#use lib '../../lib';
BEGIN {
  our $VERSION = "0.11";
  require Neo4j::Bolt::TypeHandlersC;
  eval 'require Neo4j::Bolt::Config; 1';
}

use Inline C => Config =>
  LIBS => $Neo4j::Bolt::Config::extl,
  INC => $Neo4j::Bolt::Config::extc,
  version => $VERSION,
  name => __PACKAGE__;
use Inline C => <<'END_NEOVALUE_C';

#include <neo4j-client.h>
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))
#define NVCLASS "Neo4j::Bolt::NeoValue"
extern neo4j_value_t SV_to_neo4j_value(SV*);
extern SV *neo4j_value_to_SV(neo4j_value_t);
struct neovalue {
  neo4j_value_t value;
};
typedef struct neovalue neovalue_t;

SV *_new_from_perl (const char* classname, SV *v) {
   SV *neosv, *neosv_ref;
   neovalue_t *obj;
   Newx(obj, 1, neovalue_t);
   obj->value = SV_to_neo4j_value(v);
   neosv = newSViv((IV) obj);
   neosv_ref = newRV_noinc(neosv);
   sv_bless(neosv_ref, gv_stashpv(classname, GV_ADD));
   SvREADONLY_on(neosv);
   return neosv_ref;
}

const char* _neotype (SV *obj) {
  neo4j_value_t v;
  v = C_PTR_OF(obj,neovalue_t)->value;
  return neo4j_typestr( neo4j_type( v ) ); 
}

SV* _as_perl (SV *obj) {
  SV *ret;
  ret = newSV(0);
  sv_setsv(ret,neo4j_value_to_SV( C_PTR_OF(obj, neovalue_t)->value ));
  return ret;
}

int _map_size (SV *obj) {
  return neo4j_map_size( C_PTR_OF(obj, neovalue_t)->value );
}
void DESTROY(SV *obj) {
  neo4j_value_t *val = C_PTR_OF(obj, neo4j_value_t);
  return;
}

END_NEOVALUE_C

sub of {
  my ($class, @args) = @_;
  my @ret;
  for (@args) {
    push @ret, $class->_new_from_perl($_);
  }
  return @ret;
}

sub is {
  my ($class, @args) = @_;
  my @ret;
  for (@args) {
    push @ret, $_->_as_perl;
  }
  return @ret;
}

sub new {shift->of(@_)}
sub are {shift->is(@_)}

=head1 NAME

Neo4j::Bolt::NeoValue - Container to hold Bolt-encoded values

=head1 SYNOPSIS

  use Neo4j::Bolt::NeoValue;
  
  $neo_int = Neo4j::Bolt::NeoValue->of( 42 );
  $i = $neo_int->_as_perl;
  $neo_node = Neo4j::Bolt::NeoValue->of( 
    bless { id => 1,
      labels => ['thing','chose'],
      properties => {
        texture => 'crunchy',
        consistency => 'gooey',
      },
    }, 'Neo4j::Bolt::Node' );
  if ($neo_node->_neotype eq 'Node') {
    print "Yep, that's a node all right."
  }

  %node = %{ Neo4j::Bolt::NeoValue->is($neo_node)->as_simple };
  
  ($h,$j) = Neo4j::Bolt::NeoValue->are($neo_node, $neo_int);

=head1 DESCRIPTION

L<Neo4j::Bolt::NeoValue> is an interface to convert Perl values to
Bolt protocol byte structures via
L<libneo4j-client|https://github.com/cleishm/libneo4j-client>. It's
useful for testing the package, but you may find it useful in other
ways.

=head1 METHODS

=over

=item of($thing), new($thing)

Class method. Creates a NeoValue from a Perl scalar, arrayref, or
hashref.

=item _as_perl()

Returns a Perl scalar, arrayref, or hashref representing the underlying 
Bolt data stored in the object.

=item _neotype()

Returns a string indicating the type of object that
L<libneo4j-client|https://github.com/cleishm/libneo4j-client> thinks
the Bolt data represents.

=item is($neovalue), are(@neovalues)

Class method. Syntactic sugar; runs L</"_as_perl()"> on the arguments.

=back

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2019-2020 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut




1;

