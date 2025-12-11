package Neo4j::Bolt::NeoValue;
use v5.12;
use warnings;

BEGIN {
  our $VERSION = "0.5001";
  require Neo4j::Bolt::CTypeHandlers;
  require Neo4j::Bolt::CResultStream;
  require XSLoader;
  XSLoader::load();
}

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

=head1 FUNCTIONS

=over

=item is_bool($scalar)

  $boolean = Neo4j::Bolt::NeoValue::is_bool( $value );

Returns true iff Neo4j::Bolt would treat this Perl value as
a boolean when found in a query parameter.

=back

=head1 AUTHOR

 Mark A. Jensen
 CPAN: MAJENSEN
 majensen -at- cpan -dot- org

=head1 LICENSE

This software is Copyright (c) 2019-2024 by Mark A. Jensen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut




1;

