package Neo4j::Bolt::CTypeHandlers;
use v5.12;
use warnings;

BEGIN {
  our $VERSION = "0.5001";
  require XSLoader;
  XSLoader::load();
}

use JSON::PP; # operator overloading for boolean values
use Neo4j::Bolt::Node;
use Neo4j::Bolt::Relationship;
use Neo4j::Bolt::Path;
use Neo4j::Bolt::Point;
use Neo4j::Bolt::DateTime;
use Neo4j::Bolt::Duration;
use Neo4j::Bolt::Bytes;

=head1 NAME

Neo4j::Bolt::TypeHandlersC - Low level Perl to Bolt converters

=head1 SYNOPSIS

 // how Neo4j::Bolt::ResultStream uses it
  for (i=0; i<n; i++) {
    value = neo4j_result_field(result, i);
    perl_value = neo4j_value_to_SV(value);
    Inline_Stack_Push( perl_value );
  }

=head1 DESCRIPTION

L<Neo4j::Bolt::TypeHandlersC> is all C code, managed by L<Inline::C>.
It tediously defines methods to convert Perl structures to Bolt
representations, and also tediously defines methods convert Bolt
data to Perl representations.

=head1 METHODS

=over

=item neo4j_value_t SV_to_neo4j_value(SV *sv)

Attempt to create the appropriate
L<libneo4j-client|https://github.com/cleishm/libneo4j-client>
representation of the Perl SV argument.

=item SV* neo4j_value_to_SV( neo4j_value_t value )

Attempt to create the appropriate Perl SV representation of the
L<libneo4j-client|https://github.com/cleishm/libneo4j-client>
neo4j_value_t argument.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Bolt::NeoValue>, L<Inline::C>,
L<libneo4j-client API|http://neo4j-client.net/doc/latest/neo4j-client_8h.html>.

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

