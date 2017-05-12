#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2008-08-13
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package Net::Plazes::Activity;
use strict;
use warnings;
use base qw(Net::Plazes::Base);
use Net::Plazes::User;
use Net::Plazes::Plaze;
use Carp;

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(fields());
__PACKAGE__->has_many();

sub service {
  return q[http://plazes.com/activities];
}

sub fields {
  return qw(id created_at device plaze_id scheduled_at status user_id);
}

sub process_dom {
  my ($self, $obj, $dom) = @_;
  $self->SUPER::process_dom($obj, $dom);

  my $plz_els = $dom->getElementsByTagName('plaze');
  if($plz_els) {
    my $el = $plz_els->[0];
    if($el) {
      my $plaze = Net::Plazes::Plaze->new({
					   usergent => $self->useragent(),
					  });
      $obj->{plaze} = $plaze->process_dom($plaze, $el);
    }
  }

  my $usr_els = $dom->getElementsByTagName('user');
  if($usr_els) {
    my $el = $usr_els->[0];
    if($el) {
      my $user = Net::Plazes::User->new({
					 usergent => $self->useragent(),
					});
      $obj->{user} = $user->process_dom($user, $el);
    }
  }

  return $obj;
}

sub user {
  my $self = shift;

  if(!$self->{user}) {
    $self->read();
    $self->{user} ||= Net::Plazes::User->new({
					      useragent => $self->useragent(),
					      id        => $self->user_id(),
					     });
  }

  return $self->{user};
}

sub plaze {
  my $self = shift;

  if(!$self->{plaze}) {
    $self->read();
    $self->{plaze} ||= Net::Plazes::Plaze->new({
						useragent => $self->useragent(),
						id        => $self->plaze_id(),
					       });
  }

  return $self->{plaze};
}


1;
__END__

=head1 NAME

Net::Plazes::Activity - representation of remote resource http://plazes.com/presence(.*)

=head1 VERSION

$Revision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 service

=head2 fields - list of accessors for resources of this type

 my @aFields = $oObj->fields();

=head2 user - Net::Plazes::User representing the user for the user_id in this presense

 my $oUser = $oPresense->user();

=head2 plaze - Net::Plazes::Plaze representing the plaze for the plaze_id in this presense

 my $oPlaze = $oPresense->plaze();

=head2 process_dom - Additional internal DOM processing to pull in presence.plaze and presence.user

 $oPlaze->process_dom();

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
