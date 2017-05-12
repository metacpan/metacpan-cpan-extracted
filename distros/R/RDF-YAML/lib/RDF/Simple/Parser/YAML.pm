# $File: //member/autrijus/RDF-YAML/lib/RDF/Simple/Parser/YAML.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 8524 $ $DateTime: 2003/10/22 05:20:04 $

package RDF::Simple::Parser::YAML;
$RDF::Simple::Parser::YAML::VERSION = '0.01';

use strict;
use YAML;
use Class::MethodMaker new_hash_init => 'new', get_set => [ qw(base ns)];

=head1 NAME

RDF::Simple::Parser::YAML - Simple RDF/YAML parser

=head1 DESCRIPTION

This module is a simple RDF/XML parser.  It reads a string containing
RDF in YAML, and returns an array of RDF triples.

=head1 SYNOPSIS

    my $uri = 'http://www.w3.org/2000/08/w3c-synd/home.rss';
    my $rdf = LWP::Simple::get($uri);

    my $parser = RDF::Simple::Parser::YAML->new(base => $uri)
    my @triples = $parser->parse_rdf($rdf);

    # returns an array of array references which are triples

=head1 METHODS 

=head2 new( base => $uri )

Create a new RDF::Simple::Parser::YAML object.

The optional parameter C<base> supplies a base URI for relative URIs found
in the document.  (This function is currently unimplemented.)

=head2 parse_rdf($rdf)

Accepts a string which is an RDF/YAML document.

Returns an array of array references which are RDF triples.

=cut

sub parse_rdf {
    my ($self, $rdf) = @_;

    my $hash = YAML::Load($rdf) or return [];
    my $ns = $self->ns($hash->{''});
    $ns->{''} = 'urn:empty' unless exists $ns->{''};

    my @rv;
    foreach my $subject (sort grep length, keys %$hash) {
	my $node = $hash->{$subject} or next;
	foreach my $predicate (sort grep length, keys %$node) {
	    my $object = $node->{$predicate};
	    $predicate =~ s/^(\w[^:]*):/$ns->{$1}/g
		or $predicate =~ /:/
		    or $predicate = $ns->{''} . $predicate;
	    push @rv, [ $subject, $predicate, $object ];
	}
    }
    return @rv;
}

1;

=head1 SEE ALSO

L<RDF::YAML>, L<RDF::Simple::Serialiser::YAML>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
