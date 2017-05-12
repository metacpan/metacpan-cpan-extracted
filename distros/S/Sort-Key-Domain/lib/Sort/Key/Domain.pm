package Sort::Key::Domain;

use strict;
use warnings;

BEGIN {
    our $VERSION = 0.01;
    require XSLoader;
    XSLoader::load('Sort::Key::Domain', $VERSION);
}

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( domainkeysort
                     domainkeysort_inplace
                     rdomainkeysort
                     rdomainkeysort_inplace
                     domainsort
                     domainsort_inplace
                     rdomainsort
                     rdomainsort_inplace
                     mkkey_domain );

use Sort::Key::Register domain => \&mkkey_domain, 'str';

use Sort::Key::Maker domainkeysort => 'domain';
use Sort::Key::Maker rdomainkeysort => '-domain';
use Sort::Key::Maker domainsort => \&mkkey_domain, 'str';
use Sort::Key::Maker rdomainsort => \&mkkey_domain, '-str';

1;

__END__

=head1 NAME

Sort::Key::Domain - Sort domain names

=head1 SYNOPSIS

  use Sort::Key::Domain qw(domainkeysort);

  my @sorted = domainkeysort { $_->domain_name } @url;

=head1 DESCRIPTION

This module extends the L<Sort::Key> family of modules to support
sorting of domain names.

=head2 FUNCTIONS

The functions that can be imported from this module are as follow:

=over 4

=item domainsort @data

Return the domain names in C<@data> sorted.

=item rdomainsort @data

Returns the domain names in C<@data> sorted in descending order.

=item domainkeysort { CALC_KEY($_) } @data

Returns the elements on C<@array> sorted by the domain name
resulting from applying them C<CALC_KEY>.

=item rdomainkeysort { CALC_KEY($_) } @data

Returns the elements on C<@array> sorted by the domain name
resulting from applying them C<CALC_KEY> but in descending order.

=item mkkey_domain $domain

Transforms the given domain name in a key suitable for
lexicographically sorting.

Specifically it reverses the subdomains in the string. For instance,
the domain name C<a.b.c> is converted into C<c.b.a>. An interesting
property of this transformation is that applying a second time just
undoes it.

=item domainsort_inplace @data

=item rdomainsort_inplace @data

=item domainkeysort_inplace { CALC_KEY($_) } @data

=item rdomainkeysort_inplace { CALC_KEY($_) } @data

These functions are similar respectively to C<domainsort>, C<rdomainsort>,
C<domainsortkey> and C<rdomainsortkey>, but they sort the array C<@data> in
place.

=back

=head1 SEE ALSO

L<Sort::Key>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Salvador Fandiño (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
