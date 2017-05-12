package Net::LDAPxs::Entry;

use 5.006;
use strict;
use vars qw($VERSION);

$VERSION = '1.00';


sub dn { shift->{objectName}; }

sub attributes {
	my $self = shift;

	map { $_->{type} } @{$self->{attributes}};
}

sub get_value {
	my $self = shift;
	my $type = shift;

	my $attrs = _build_attrs($self);
	return unless $attrs->{$type};
	@{$attrs->{$type}};
}

sub _build_attrs {
	+{ map { $_->{type}, $_->{vals} }  @{$_[0]->{attributes}} };
}


1;

__END__


=head1 NAME

Net::LDAPxs::Entry - An LDAP entry object

=head1 SYNOPSIS

  use Net::LDAPxs;
  
  $ldap = Net::LDAPxs->new ( $host );
  $msg = $ldap->search ( @search_args );
  
  @entries = $msg->entries();

  foreach my $entry (@entries) {
      foreach my $attr ($entry->attributes()) {
          foreach my $val ($entry->get_value($attr)) {
              print "$attr, $val\n";
          }
      }
  }

=head1 DESCRIPTION

The B<Net::LDAPxs::Entry> object represents a single entry in the
directory.  It is a container for attribute-value pairs.

=head1 METHODS

=over 4

=item attributes ( OPTIONS )

Return a list of attributes in this entry

=item dn ( )

Get the DN of the entry.

=item get_value ( ATTR )

Get the values for the attribute C<ATTR>. In a list context returns
all values for the given attribute, or the empty list if the attribute
does not exist. In a scalar context returns the first value for the
attribute.

=back

=head1 ACKNOWLEDGEMENTS

This document is based on the document of L<Net::LDAP::Entry>

=head1 AUTHOR

Pan Yu <xiaocong@vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
