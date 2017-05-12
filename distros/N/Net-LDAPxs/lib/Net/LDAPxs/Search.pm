package Net::LDAPxs::Search;

use 5.006;
use strict;
use vars qw($VERSION);
use Net::LDAPxs::Entry;

$VERSION = '1.00';


sub count { $#{shift->{entries}}+1; }

sub entries {
	my $self = shift;

	($self->count > 0) ? @{$self->{entries}} : undef;
}

sub shift_entry {
	my $self = shift;

	($self->count > 0) ? shift @{$self->{entries}} : undef;
}

sub pop_entry {
	my $self = shift;

	($self->count > 0) ? pop @{$self->{entries}} : undef;
}

sub all_entries { goto &entries }

sub err {
# This method is to avoid misusing the same function in Exception.pm.
}


1;

__END__

=head1 NAME

Net::LDAPxs::Search - Object returned by Net::LDAPxs search method

=head1 SYNOPSIS

  use Net::LDAPxs;
  
  $msg = $ldap->search( @search_args );
  
  @entries = $msg->entries;

=head1 DESCRIPTION

A B<Net::LDAPxs::Search> object is returned from the
L<search|Net::LDAPxs/item_search> method of a L<Net::LDAPxs> object. It is
a container object which holds the results of the search.

=head1 METHODS

=over 4

=item count

Returns the number of entries returned by the server.

=item entries

Return an array of L<Net::LDAPxs::Entry> objects that were returned from
the server.

=item pop_entry

Pop an entry from the internal list of L<Net::LDAPxs::Entry> objects for
this search. If there are no more entries then C<undef> is returned.

This call will block if the list is empty, until the server returns
another entry.

=item shift_entry

Shift an entry from the internal list of L<Net::LDAPxs::Entry> objects
for this search. 

This call will block if the list is empty, until the server returns
another entry.

=back

=head1 ACKNOWLEDGEMENTS

This document is based on the document of L<Net::LDAP::Search>

=head1 AUTHOR

Pan Yu <xiaocong@vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
