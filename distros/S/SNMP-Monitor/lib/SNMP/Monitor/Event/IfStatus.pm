# -*- perl -*-
#
#
#   SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#

use strict;


package SNMP::Monitor::Event::IfStatus;

use vars qw(@ISA $VERSION);

$VERSION = '0.1000';
@ISA = qw(SNMP::Monitor::Event);


sub new ($$$) {
    my($proto, $session, $attr) = @_;
    my $self = $proto->SUPER::new($session, $attr);

    my $table = "interfaces.ifTable.ifEntry";
    my $num = $self->{num};
    $self->{vars} = [ SNMP::Varbind->new(["$table.ifDescr", $num]),
		      SNMP::Varbind->new(["$table.ifAdminStatus", $num]),
		      SNMP::Varbind->new(["$table.ifOperStatus", $num])];
    $self;
}


sub Process ($) {
    my($self) = @_;
    my $session = $self->{session};
    my $vr_session = $session->{vars_registered};
    my $vr_self = $self->{vars_registered};

    # The following list corresponds to the list in the 'new' method.
    # This is important when calculation the index $i in $vr_self->[$i].
    my $ifDescr = $vr_session->[$vr_self->[0]]->[0]->[2];
    my $ifAdminStatus = $vr_session->[$vr_self->[1]]->[0]->[2];
    my $ifOperStatus = $vr_session->[$vr_self->[2]]->[0]->[2];
    my $num = $self->{num};

    if (exists($self->{ifAdminStatus})) {
	if ($self->{ifAdminStatus} ne $ifAdminStatus  ||
	    $self->{ifOperStatus} ne $ifOperStatus) {
	    my $name = $session->{name};
	    my $host = $session->{DestHost};
	    my $aStatus = ($ifAdminStatus == 1) ? "Up" : "Down";
	    my $oStatus = ($ifOperStatus == 1) ? "Up" : "Down";
	    $self->Message(subject => "Interface state change",
			   body => <<"MSG")

An interface state change was detected at the host $name ($host),
interface $ifDescr. The current state is:

    Administrative status:  $aStatus
    Operative status:       $oStatus

You won't receive any further messages until the next status change.
MSG
	}
    }
    $self->{ifAdminStatus} = $ifAdminStatus;
    $self->{ifOperStatus} = $ifOperStatus;
}


1;
