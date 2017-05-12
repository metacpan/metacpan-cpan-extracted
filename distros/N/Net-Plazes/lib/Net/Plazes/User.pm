#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2008-08-13
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package Net::Plazes::User;
use strict;
use warnings;
use base qw(Net::Plazes::Base);
use Net::Plazes::Activity;

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(fields());
__PACKAGE__->has_many();

sub service {
  return q[http://plazes.com/users];
}

sub fields {
  return qw(id created_at full_name name updated_at avatar_url);
}

sub activities {
  my $self     = shift;

  if(!$self->id()) {
    return [];
  }

  if(!$self->{activities}) {
    my $obj_uri  = sprintf '%s/%d/activities', $self->service(), $self->id();
    my $root_activity = Net::Plazes::Activity->new({
						    useragent => $self->useragent(),
						   });
    $root_activity->list($obj_uri);
    $self->{activities} = $root_activity->activities();
  }

  return $self->{activities};
}

1;
__END__

=head1 NAME

Net::Plazes::User - representation of remote resource http://plazes.com/users(.*)

=head1 VERSION

$Revision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 service

=head2 fields - list of accessors for resources of this type

 my @aFields = $oObj->fields();

=head2 activities - Arrayref of Net::Plazes::Activity objects for this user

 my $arActivities = $oUser->activities();

=head2 accessors

=over

=item id

=item created_at

=item full_name

=item name

=item updated_at

=item avatar_url

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
