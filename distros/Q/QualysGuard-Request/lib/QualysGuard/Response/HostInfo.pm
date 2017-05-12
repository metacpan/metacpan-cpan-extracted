package QualysGuard::Response::HostInfo;

use warnings;
use strict;

use base qw( QualysGuard::Response );

our $VERSION = '0.02';


# =============================================================
# - new
# =============================================================
sub new {
    my ( $class, $xml ) = @_; 

    my $self = __PACKAGE__->SUPER::new( $xml );

    bless $self, $class;

    # -- check for QualysGuard function error

    if ( $self->exists('/HOST/ERROR') ) { 
        $self->{error_code} = $self->findvalue('/HOST/ERROR/@number');
        $self->{error_text} = $self->getNodeText('/HOST/ERROR');
        $self->{error_text} =~ s/^\s+(.*)\s+$/$1/m;
    }   

    return $self;
}



# =============================================================
# - various get methods
# =============================================================
sub get_tracking_method  { $_[0]->getNodeText( '/HOST/TRACKING_METHOD'  )->string_value(); }
sub get_security_risk    { $_[0]->getNodeText( '/HOST/SECURITY_RISK'    )->string_value(); }
sub get_ip               { $_[0]->getNodeText( '/HOST/IP'               )->string_value(); }
sub get_dns              { $_[0]->getNodeText( '/HOST/DNS'              )->string_value(); }
sub get_netbios          { $_[0]->getNodeText( '/HOST/NETBIOS'          )->string_value(); }
sub get_operating_system { $_[0]->getNodeText( '/HOST/OPERATING_SYSTEM' )->string_value(); }
sub get_last_scan_date   { $_[0]->getNodeText( '/HOST/LAST_SCAN_DATE'   )->string_value(); }
sub get_comment          { $_[0]->getNodeText( '/HOST/COMMENT'          )->string_value(); }



# =============================================================
# - get_ticket_numbers
# =============================================================
sub get_ticket_numbers {
    my $self    = shift;
    my @nodes   = $self->findnodes('/HOST/TICKETS/*/*/TICKET_NUMBER');
    my @tickets = ();

    foreach my $node ( @nodes ) {
        push( @tickets, $node->string_value() );
    }

    return \@tickets;
}



# =============================================================
# - get_vuln_info
# =============================================================
sub get_vuln_info {
    my $self = shift;
    my @nodes = $self->findnodes('/HOST/*/*/VULNINFO');
    my @vulns = (); 

    foreach my $node ( @nodes ) { 

        my @children = $node->getChildNodes();
        my $vuln     = {}; 

        $vuln->{VULN_LEVEL} = $node->getParentNode()->getParentNode()->getName();

        foreach my $child ( @children ) { 
            next unless ( $child->isa( "XML::XPath::Node::Element" ) );

            my $key = $child->getName();

            # ------- CVSS_SCORE -------------------------------------------

            if ( $key eq "CVSS_SCORE" ) {
                $vuln->{$key} = {};
                my @gc = $child->getChildNodes();

                foreach my $c ( @gc ) {
                    next unless ( $c->isa( "XML::XPath::Node::Element" ) );
                    my $ckey = $c->getName();

                    if ( defined $ckey ) {
                        $vuln->{$key}->{$ckey} = $c->string_value();
                    }
                }
            }

            # ------- LISTS -------------------------------------------------

            elsif ( $key eq "VENDOR_REFERENCE_LIST" || $key eq "CVE_ID_LIST" || $key eq "BUGTRAQ_ID_LIST" ) {
                my @n = $child->findnodes( "*/ID" );
                $vuln->{$key} = ();

                foreach my $id ( @n ) {
                    push( @{$vuln->{$key}}, $id->string_value() );
                }
            }

            else {
                $vuln->{$key} = $child->string_value();
            }
        }   

        push(@vulns, $vuln);
    }   

    return \@vulns;
}



1;

__END__


=head1 NAME

QualysGuard::Response::HostInfo

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

see L<QualysGuard::Request> for more information.


=head1 DESCRIPTION

This module is a subclass of QualysGuard::Response and XML::XPath.

see QualysGuard API documentation for more information.


=head1 PUBLIC INTERFACE

=over 4

=item get_ticket_numbers

Returns an arrayref of all /HOST/TICKETS/*/TICKET_NUMBER nodes.

=item get_vuln_info

Returns an arrayref of hasrefs containing vulnerability info from /HOST/*/*/VULNINFO nodes. 

The method includes the VULN_LEVEL within the hashref.

=item get_tracking_method

Returns the host tracking method assigned to the host. A valid value is “IP address”, 
“DNS hostname”, or “NetBIOS hostname”. 

=item get_security_risk

Returns the current security risk of the host, reflecting the number of vulnerabilities 
detected on the host and the relative security risk of those vulnerabilities. Security 
risk is a value from 1 to 5, where a rating of 5 represents the highest security risk. 

=item get_ip

Returns the IP address of the host. 

=item get_dns

Returns the DNS host name when known.

=item get_netbios

Returns the Microsoft Windows NetBIOS host name if appropriate, when known.

=item get_operating_system

Returns the operating system detected on the host.

=item get_last_scan_date

Returns the date and time when the host was last scanned (most recent scan, in 
YYYY-MM-DDTHH:MM:SSZ format (UTC/GMT). 

=item get_comment

Returns user-supplied host comments. 

=back

=head1 AUTHOR

Patrick Devlin, C<< <pdevlin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-qualysguard-response-assetdatareport at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=QualysGuard::Request>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc QualysGuard::Request


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=QualysGuard::Request>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/QualysGuard::Request>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/QualysGuard::Request>

=item * Search CPAN

L<http://search.cpan.org/dist/QualysGuard::Request>

=back

=head1 SEE ALSO
 
L<QualysGuard::Request>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Patrick Devlin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Qualys and the QualysGuard product are registered trademarks of Qualys, Inc.
