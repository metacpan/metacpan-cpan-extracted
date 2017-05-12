#
# $Id: Switchboard.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp $
#  

package Net::Msmgr::Switchboard;
use strict;
use warnings;
use Net::Msmgr::Connection;

our @ISA = qw ( Net::Msmgr::Connection );

=pod
    
=head1  NAME

Net::Msmgr::Switchboard

=head1 SYNOPSIS

use Net::Msmgr::Switchboard;

=head1 DESCRIPTION

Net::Msmgr::Switchboard is derived from Net::Msmgr::Connection. 

=head1 CONSTRUCTION OPTIONS

Net::Msmgr::Switchboard->new( ssid => ...  );

=cut 

sub _fields { return shift->SUPER::_fields, ( ssid => undef ); } ;

=pod

=head1 PUBLIC METHODS

 The following methods are provided

=over

=item  $sb->ssid;

Return the Switchboard Session ID associated with this
switchboard.

=cut

=cut

1;

#
# $Log: Switchboard.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#
