#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2008-08-13
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package Net::Plazes::Plaze;
use strict;
use warnings;
use base qw(Net::Plazes::Base);

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(fields());
__PACKAGE__->has_many();

sub service {
  return q[http://plazes.com/plazes];
}

sub fields {
  return qw(id address category city country_code has_free_wifi created_at link name state timezone updated_at zip_code latitude longitude country picture_url);
}

1;
__END__

=head1 NAME

Net::Plazes::Plaze - representation of remote resource http://plazes.com/plazes(.*)

=head1 VERSION

$Revision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 service

=head2 fields - list of accessors for resources of this type

 my @aFields = $oObj->fields();

Accessors are:

=over

=item id

=item address

=item category

=item city

=item country_code

=item created_at

=item name

=item state

=item timezone

=item updated_at

=item zip_code

=item latitude

=item longitude

=item country

=item has_free_wifi

=item link

=item picture_url

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item Net::Plazes::Base

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
