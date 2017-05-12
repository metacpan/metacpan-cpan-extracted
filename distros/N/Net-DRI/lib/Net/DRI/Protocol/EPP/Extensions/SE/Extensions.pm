## Domain Registry Interface, .SE EPP Domain/Contact Extensions for Net::DRI
## Contributed by Elias Sidenbladh and Ulrich Wisser from NIC SE
##
## Copyright (c) 2006,2008,2009,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::SE::Extensions;

use strict;
use warnings;
use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SE::Extensions - .SE EPP Domain/Contact Extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008,2009,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

###################################################################################################

sub register_commands {
    my ( $class, $version ) = @_;
    my $domain = {
        info             => [ undef,             \&domain_parse ],
        create           => [ undef,             \&domain_parse ],
        update           => [ \&domain_update,   \&domain_parse ],
        transfer_request => [ \&domain_transfer, undef ],
        notifyDelete     => [ undef,             \&delete_parse ],
    };
    my $contact = {
        info             => [ undef,            \&contact_parse ],
        create           => [ \&contact_create, undef ],
        update           => [ \&contact_update, undef ],
        transfer_request => [ undef,            \&contact_transfer_parse ],
    };
    my $host = {
        info             => [ undef, \&host_parse ],
        transfer_request => [ undef, \&host_transfer_parse ],
    };
    return { 'domain' => $domain, 'contact' => $contact, 'host' => $host, };
}

sub capabilities_add {
    return ( [ 'domain_update', 'client_delete', [ 'set', ] ], );
}
###################################################################################################

sub get_notify {
    my $mes = shift;
    my $ns=$mes->ns('iis');
    # only one of these will be given, but we can't know which in advance
    return 'create'   if defined $mes->get_response($ns, 'createNotify' );
    return 'update'   if defined $mes->get_response($ns, 'updateNotify' );
    return 'delete'   if defined $mes->get_response($ns, 'deleteNotify' );
    return 'transfer' if defined $mes->get_response($ns, 'transferNotify' );

    # done, no notify found
    return;
}

##################################################################################################
########### Query commands

# parse domain info
sub domain_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    # only domain info should be parsed
    return if ( ( !defined $otype ) || ( $otype ne 'domain' ) );

    # check for notify
    my $notify = get_notify($mes);
    $rinfo->{domain}->{$oname}->{notify} = $notify if defined $notify;

    # get <iis:infData/> from <extension/>
    my $infData = $mes->get_extension( $mes->ns('iis'), 'infData' );
    return unless defined $infData;

    # parse deleteDate (optional)
    foreach my $el ( $infData->getElementsByTagNameNS( $mes->ns('iis'), 'delDate' ) ) {
        $rinfo->{domain}->{$oname}->{delDate} = $po->parse_iso8601( $el->textContent() );
    }

    # parse deactDate (optional)
    foreach my $el ( $infData->getElementsByTagNameNS( $mes->ns('iis'), 'deactDate' ) ) {
        $rinfo->{domain}->{$oname}->{deactDate} = $po->parse_iso8601( $el->textContent() );
    }

    # parse relDate (optional)
    foreach my $el ( $infData->getElementsByTagNameNS( $mes->ns('iis'), 'relDate' ) ) {
        $rinfo->{domain}->{$oname}->{relDate} = $po->parse_iso8601( $el->textContent() );
    }

    # parse state
    foreach my $el ( $infData->getElementsByTagNameNS( $mes->ns('iis'), 'state' ) ) {
        $rinfo->{domain}->{$oname}->{state} = $el->textContent();
    }

    # done
    return;
}

# parse contact info
sub contact_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    # only contact info should be parsed
    return if ( ( !defined $otype ) || ( $otype ne 'contact' ) );

    # check for notify
    my $notify = get_notify($mes);
    $rinfo->{contact}->{$oname}->{notify} = $notify if defined $notify;

    # get <iis:infData/> from <extension/>
    my $result = $mes->get_extension( $mes->ns('iis'), 'infData' );
    return unless defined $result;

    # parse orgno (mandatory)
    foreach my $el ( $result->getElementsByTagNameNS( $mes->ns('iis'), 'orgno' ) ) {
        $rinfo->{contact}->{$oname}->{self}->orgno( $el->textContent() );
    }

    # parse vatno (optional)
    foreach my $el ( $result->getElementsByTagNameNS( $mes->ns('iis'), 'vatno' ) ) {
        $rinfo->{contact}->{$oname}->{self}->vatno( $el->textContent() );
    }

    # done
    return;
}

sub host_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    # only contact info should be parsed
    return if ( ( !defined $otype ) || ( $otype ne 'host' ) );

    # check for notify
    my $notify = get_notify($mes);
    $rinfo->{host}->{$oname}->{notify} = $notify if defined $notify;

    # done
    return;
}

# parse <host:trnData/>
# copied from Net::DRI::Protocol::EPP::Core::Domain
sub host_transfer_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    my $trndata = $mes->get_response( $mes->ns('host'), 'trnData' );
    return unless defined $trndata;

    foreach my $el (Net::DRI::Util::xml_list_children($trndata))
    {
     my ($name,$c)=@$el;
        if ( $name eq 'name' ) {
            $oname                             = $c->textContent();
            $rinfo->{host}->{$oname}->{action} = 'transfer';
            $rinfo->{host}->{$oname}->{exist}  = 1;
        }
        elsif ( $name =~ m/^(trStatus|reID|acID)$/ ) {
            $rinfo->{host}->{$oname}->{$1} = $c->textContent();
        }
        elsif ( $name =~ m/^(reDate|acDate|exDate)$/ ) {
            $rinfo->{host}->{$oname}->{$1} = $po->parse_iso8601( $c->textContent() );
        }
    }

    # check for notify
    my $notify = get_notify($mes);
    $rinfo->{host}->{$oname}->{notify} = $notify if defined $notify;

    # done
    return;
}

sub contact_transfer_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $mes = $po->message();
    return unless $mes->is_success();

    my $trndata = $mes->get_response( $mes->ns('contact'), 'trnData' );
    return unless defined $trndata;

    foreach my $el (Net::DRI::Util::xml_list_children($trndata))
    {
     my ($name,$c)=@$el;
        if ( $name eq 'id' ) {
            $oname                             = $c->textContent();
            $rinfo->{contact}->{$oname}->{action} = 'transfer';
            $rinfo->{contact}->{$oname}->{exist}  = 1;
        }
        elsif ( $name =~ m/^(trStatus|reID|acID)$/ ) {
            $rinfo->{contact}->{$oname}->{$1} = $c->textContent();
        }
        elsif ( $name =~ m/^(reDate|acDate|exDate)$/ ) {
            $rinfo->{contact}->{$oname}->{$1} = $po->parse_iso8601( $c->textContent() );
        }
    }

    # check for notify
    my $notify = get_notify($mes);
    $rinfo->{contact}->{$oname}->{notify} = $notify if defined $notify;

    # done
    return;
}

# parse delete message
sub delete_parse {
    my ( $po, $otype, $oaction, $oname, $rinfo ) = @_;
    my $nametag;
    my $mes = $po->message();
    return unless $mes->is_success();

    # check for notify
    my $notify = get_notify($mes);
    return if ( ( !defined $notify ) || ( $notify ne 'delete' ) );

    # check for host
    my $host = $mes->get_response( $mes->ns('host'), 'name' );
    if ( defined $host ) {
        $oname = $host->textContent();
        $otype = 'host';
    }

    # check for contact
    my $contact = $mes->get_response( $mes->ns('contact'), 'id' );
    if ( defined $contact ) {
        $oname = $contact->textContent();
        $otype = 'contact';
    }

    # check for domain
    my $domain = $mes->get_response( $mes->ns('domain'), 'name' );
    if ( defined $domain ) {
        $oname = $domain->textContent();
        $otype = 'domain';
    }

    $rinfo->{$otype}->{$oname}->{notify} = $notify;
    $rinfo->{$otype}->{$oname}->{action} = 'delete';
    $rinfo->{$otype}->{$oname}->{exist}  = 0;

    # done
    return;
}

# domain update command extension
sub domain_update {
    my ( $epp, $domain, $rd ) = @_;
    my @data = ();
    my $mes  = $epp->message();

    # iis:clientDelete
    if ( exists $rd->{client_delete} ) {
        Net::DRI::Exception::usererr_invalid_parameters("client_delete can only be '1' or '0'") if ( $rd->{client_delete}[2] !~ /^(0|1)$/ );
        push @data, [ 'iis:clientDelete', $rd->{client_delete}[2] ];
    }

    # only add extension if any data gets added
    return unless @data;

    # create <iis:update/>
    my $iis_extension = $mes->command_extension_register( 'iis:update', 'xmlns:iis="' . $mes->ns('iis') . '" xsi:schemaLocation="' . $mes->ns('iis') . ' iis-1.1.xsd"' );

    # now add extension to message
    $mes->command_extension( $iis_extension, \@data );

    # done
    return;
}

sub domain_transfer {
    my ( $epp, $domain, $rd ) = @_;
    my @data = ();
    my $mes  = $epp->message();

    # new nameservers (optional)
    push @data, [ 'iis:ns',  map { [ 'iis:hostObj', $_ ] } $rd->{ns}->get_names() ] if Net::DRI::Util::has_ns($rd);

    # only add body if any data gets added
    return unless @data;

    # create <iis:transfer/>
    my $iis_extension = $mes->command_extension_register( 'iis:transfer', 'xmlns:iis="' . $mes->ns('iis') . '" xsi:schemaLocation="' . $mes->ns('iis') . ' iis-1.1.xsd" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"' );

    # now add extension to message
    $mes->command_extension( $iis_extension, \@data );

    # done
    return;
}

# contact create command extension
sub contact_create {
    my ( $epp, $contact, $rd ) = @_;
    my @data = ();
    my $mes  = $epp->message();

    # iis:orgno (mandatory)
    my $orgno;
    $orgno = $rd->{orgno}      if exists( $rd->{orgno} );
    $orgno = $contact->{orgno} if exists( $contact->{orgno} );
    $orgno = $contact->orgno   if $contact->can('orgno');

    Net::DRI::Exception::usererr_insufficient_parameters('Attribute orgno must exist') unless defined $orgno;
    push @data, [ 'iis:orgno', $orgno ];

    # iis:vatno (optional)
    my $vatno;
    $vatno = $rd->{orgno}      if exists( $rd->{vatno} );
    $vatno = $contact->{vatno} if exists( $contact->{vatno} );
    $vatno = $contact->vatno   if $contact->can('vatno');
    if ( exists( $rd->{vatno} ) && $vatno ) {
        push @data, [ 'iis:vatno', $vatno ];
    }

    # only add extension if any data gets added
    return unless @data;

    # create <iis:create/>
    my $iis_extension = $mes->command_extension_register( 'iis:create', 'xmlns:iis="' . $mes->ns('iis') . '" xsi:schemaLocation="' . $mes->ns('iis') . ' iis-1.1.xsd"' );

    # now add extension to message
    $mes->command_extension( $iis_extension, \@data );

    # done
    return;
}

# contact update command extension
sub contact_update {
    my ( $epp, $contact, $rd ) = @_;
    my @data = ();
    my $mes  = $epp->message();

    # get the new contact information
    my $newc = $rd->set('info');
    return unless defined $newc && ref $newc;

    # iis:orgno (mandatory)
    Net::DRI::Exception::usererr_insufficient_parameters('Attribute orgno can not be updated') if exists( $newc->{orgno} );

    # iis:vatno (optional)
    if ( exists( $newc->{vatno} ) && defined $newc->{vatno} ) {
        push @data, [ 'iis:vatno', $newc->{vatno} ];
    }

    # only add extension if any data gets added
    return unless @data;

    # create <iis:update/>
    my $iis_extension = $mes->command_extension_register( 'iis:update', 'xmlns:iis="' . $mes->ns('iis') . '" xsi:schemaLocation="' . $mes->ns('iis') . ' iis-1.1.xsd"' );

    # now add extension to message
    $mes->command_extension( $iis_extension, \@data );

    # done
    return;
}


####################################################################################################
1;
