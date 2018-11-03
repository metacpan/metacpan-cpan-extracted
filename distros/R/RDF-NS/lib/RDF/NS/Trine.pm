package RDF::NS::Trine;
use v5.10;
use strict;
use warnings;

our $VERSION = '20181102';

use RDF::Trine::Node::Resource;
use RDF::Trine::Node::Blank;

use base 'RDF::NS';

sub GET {
    RDF::Trine::Node::Resource->new($_[1]);
}

sub BLANK {
    my $id = ($_[1] =~ /^_(:(.+))$/ ? $2 : undef);
    return RDF::Trine::Node::Blank->new( $id );
}

1;
__END__

=head1 NAME

RDF::NS::Trine - Popular RDF namespace prefixes from prefix.cc as RDF::Trine nodes

=head1 SYNOPSIS

  use RDF::NS::Trine;
  use constant NS => RDF::NS::Trine->new('20181102');

  NS->foaf_Person;        # iri('http://xmlns.com/foaf/0.1/Person')
  NS->uri('foaf:Person);  #  same RDF::Trine::Node::Resource
  NS->foaf_Person->uri;   # http://xmlns.com/foaf/0.1/Person

  NS->_;                  # RDF::Trine::Node::Blank
  NS->_abc;               # blank node with id 'abc'
  NS->uri('_:abc');       # same

=head1 DESCRIPTION

RDF::NS::Trine works like L<RDF::NS> but it returns instances of
L<RDF::Trine::Node::Resource> (or L<RDF::Trine::Node::Blank>) instead of
strings.

Before using this module, make sure to install L<RDF::Trine>, which is not
installed automatically together with L<RDF::NS>!

=head1 ADDITIONAL METHODS

=head2 BLANK ( [ $short ] )

Returns a new L<RDF::Trine::Node::Blank>.

=encoding utf8

=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2013- by Jakob Voß.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
