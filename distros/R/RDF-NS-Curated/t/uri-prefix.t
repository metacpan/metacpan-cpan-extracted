=pod

=encoding utf-8

=head1 PURPOSE

Test that RDF::NS::Curated basic functionality

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use_ok('RDF::NS::Curated');

my $ns = RDF::NS::Curated->new;
isa_ok($ns, 'RDF::NS::Curated');

is($ns->uri('foaf'), 'http://xmlns.com/foaf/0.1/', 'FOAF spec URI is OK');
is($ns->uri('omfgthisisnotaprefix'), undef, 'Non-existent prefix OK');
is($ns->prefix('http://schema.org/'), 'schema', 'Schema.org prefix OK');
is($ns->prefix('http://clearly.invalid/'), undef, 'Non-existent URI OK');
is($ns->prefix('http://creativecommons.org/ns#'), 'cc', 'CC prefix OK, test the cache');

is($ns->qname('http://www.w3.org/ns/rdfa#term'), 'rdfa:term', 'OK qname for rdfa:term');
is($ns->qname('http://www.w3.org/ns/rdfa#term'), 'rdfa:term', 'Check reset: still OK for rdfa:term');

my @got = $ns->qname('http://purl.org/dc/terms/name');
my @expected = ('dc','name');
is_deeply(\@got, \@expected, 'OK qname for dc and name in list context');

is($ns->qname('http://clearly.invalid/vocab#term'), undef, 'OK when non-existing URI');
is(($ns->qname('http://clearly.invalid/vocab#term')), undef, 'OK in list context for non-existing URI');

is(scalar keys(%{$ns->all}), 64, 'Should be 64 pairs in total');

done_testing;

