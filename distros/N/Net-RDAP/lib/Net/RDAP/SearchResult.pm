package Net::RDAP::SearchResult;
use base qw(Net::RDAP::Object);
use strict;

sub domains	{ $_[0]->objects('Net::RDAP::Object::Domain',		$_[0]->{'domainSearchResults'})		}
sub nameservers	{ $_[0]->objects('Net::RDAP::Object::Nameserver',	$_[0]->{'nameserverSearchResults'})	}
sub entities	{ $_[0]->objects('Net::RDAP::Object::Entity',		$_[0]->{'entitySearchResults'})		}

1;

__END__

=head1 NAME

L<Net::RDAP::Searchresult> - a module representing an RDAP search result.

=head1 DESCRIPTION

L<Net::RDAP::Searchresult> represents the results of an RDAP
search. Search result objects are return by the search methods of
L<Net::RDAP::Service>.

L<Net::RDAP::Searchresult> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

Other methods include:

	$result->domains;

Returns an array of L<Net::RDAP::Object::Domain> objects which matched
the search parameters.

	$result->nameservers;

Returns an array of L<Net::RDAP::Object::Nameserver> objects which matched
the search parameters.

	$result->entities;

Returns an array of L<Net::RDAP::Object::Entities> objects which matched
the search parameters.

=head1 COPYRIGHT

Copyright 2018 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
