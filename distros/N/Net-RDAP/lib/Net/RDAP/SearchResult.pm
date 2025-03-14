package Net::RDAP::SearchResult;
use base qw(Net::RDAP::Object);
use strict;
use warnings;

sub domains     { $_[0]->objects('Net::RDAP::Object::Domain',        $_[0]->{'domainSearchResults'})        }
sub nameservers { $_[0]->objects('Net::RDAP::Object::Nameserver',    $_[0]->{'nameserverSearchResults'})    }
sub entities    { $_[0]->objects('Net::RDAP::Object::Entity',        $_[0]->{'entitySearchResults'})        }

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

Returns an array of L<Net::RDAP::Object::Entity> objects which matched
the search parameters.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut
