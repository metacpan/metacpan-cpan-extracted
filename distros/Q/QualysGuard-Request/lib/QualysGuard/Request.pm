package QualysGuard::Request;

use warnings;
use strict;

use QualysGuard::Response;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use Carp;

our $VERSION = '0.04';

my $QUALYS_FUNCTIONS        = {
    'asset_data_report'     => 1,
    'asset_domain'          => 1,
    'asset_domain_list'     => 1,
    'asset_group'           => 1,
    'asset_group_delete'    => 1,
    'asset_group_list'      => 1,
    'asset_ip'              => 1,
    'asset_ip_list'         => 1,
    'asset_range_info'      => 1,
    'asset_search'          => 1,
    'get_host_info'         => 1,
    'get_tickets'           => 1,
    'iscanner_list'         => 1,
    'map'                   => 1,
    'map-2'                 => 1,
    'map_report'            => 1,
    'map_report_list'       => 1,
    'report_template_list'  => 1,
    'scan'                  => 1,
    'scan_cancel'           => 1,
    'scan_options'          => 1,
    'scan_report'           => 1,
    'scan_report_delete'    => 1,
    'scan_report_list'      => 1,
    'scan_running_list'     => 1,
    'scan_target_history'   => 1,
    'scheduled_scans'       => 1,
    'ticket_delete'         => 1,
    'ticket_edit'           => 1,
    'ticket_list'           => 1,
    'ticket_list_deleted'   => 1,
};

$QualysGuard::Request::Username = undef;
$QualysGuard::Request::Password = undef;

# -------------------------------------------------------------------
#   new
# -------------------------------------------------------------------
sub new {
    my ( $class, $function ) = @_; 
    my $self = bless {}, ref($class) || $class;
    
    if ( ! exists $QUALYS_FUNCTIONS->{$function} ) { 
        croak "Qualys function '$function' does not exist";
    }   

    $self->{function} = $function;

    return $self;
}



# -------------------------------------------------------------------
#   attributes
# -------------------------------------------------------------------
sub attributes {
    my $self = shift;
    my $attr = shift;

    while ( my ($a,$v) = each( %$attr ) ) { 
        $self->{a}{lc($a)} = $v; 
    }   

    return $self->{a};
}



# -------------------------------------------------------------------
#   submit
# -------------------------------------------------------------------
sub submit {
    my $self     = shift;
    my $url      = $self->_url();
    my $function = $self->{function};

    my $http_request = HTTP::Request->new( GET=>$url );

    if ( ! defined $QualysGuard::Request::Username ) {
        croak "Error : Undefined Qualys username.";
    }

    if ( ! defined $QualysGuard::Request::Password ) {
        croak "Error : Undefined Qualys password.";
    }

    $http_request->authorization_basic( 
        $QualysGuard::Request::Username,
        $QualysGuard::Request::Password
    );

    my $ua = LWP::UserAgent->new();

    my $http_response = $ua->request( $http_request );

    if ( ! $http_response->is_success() ) {
        croak "HTTP Error: " . $http_response->status_line();
    }

    my $qualys_response = $self->_get_qualys_response_from( $http_response );

    return $qualys_response;
}



# -------------------------------------------------------------------
#   _url
# -------------------------------------------------------------------
sub _url {
    my $self = shift;
    my $attr = $self->attributes();
    my @kvps = ();

    while ( my ($k,$v) = each( %$attr ) ) {
        $k = uri_escape( $k );
        $v = uri_escape( $v );
        push( @kvps, "$k=$v" );
    }

    return 'https://qualysapi.qualys.com/msp/' . $self->{function} . '.php?' . join('&', @kvps);
}



# -------------------------------------------------------------------
#   Factory method that creates the appropriate Response Object
# -------------------------------------------------------------------
sub _get_qualys_response_from {
    my ( $self, $http_response ) = @_;
    my $function      = $self->{function};
    my $xml_content   = $http_response->content();
    my $qualys_return = undef;


    if ( $function eq 'asset_data_report' ) {
        require QualysGuard::Response::AssetDataReport;
        $qualys_return = QualysGuard::Response::AssetDataReport->new( $xml_content );
    }

    elsif ( 
        $function eq 'asset_domain'         ||
        $function eq 'asset_group'          ||
        $function eq 'asset_group_delete'   ||
        $function eq 'asset_ip'             ||
        $function eq 'scan_cancel'          ||
        $function eq 'scan_report_delete' )
    {
        require QualysGuard::Response::GenericReturn;
        $qualys_return = QualysGuard::Response::GenericReturn->new( $xml_content );
    }

    elsif ( $function eq 'asset_domain_list' ) {
        require QualysGuard::Response::AssetDomainList;
        $qualys_return = QualysGuard::Response::AssetDomainList->new( $xml_content );
    }

    elsif ( $function eq 'asset_group_list' ) {
        require QualysGuard::Response::AssetGroupList;
        $qualys_return = QualysGuard::Response::AssetGroupList->new( $xml_content );
    }

    elsif ( $function eq 'asset_ip_list' ) {
        require QualysGuard::Response::AssetHostList;
        $qualys_return = QualysGuard::Response::AssetHostList->new( $xml_content );
    }

    elsif ( $function eq 'asset_range_info' ) {
        require QualysGuard::Response::AssetRangeInfo;
        $qualys_return = QualysGuard::Response::AssetRangeInfo->new( $xml_content );
    }

    elsif ( $function eq 'asset_search' ) {
        require QualysGuard::Response::AssetSearchReport;
        $qualys_return = QualysGuard::Response::AssetSearchReport->new( $xml_content );
    }

    elsif ( $function eq 'get_host_info' ) {
        require QualysGuard::Response::HostInfo;
        $qualys_return = QualysGuard::Response::HostInfo->new( $xml_content );
    }

    elsif ( $function eq 'get_tickets' ) {
        require QualysGuard::Response::RemediationTickets;
        $qualys_return = QualysGuard::Response::RemediationTickets->new( $xml_content );
    }

    elsif ( $function eq 'iscanner_list' ) {
        require QualysGuard::Response::IScannerList;
        $qualys_return = QualysGuard::Response::IScannerList->new( $xml_content );
    }

    elsif ( 
        $function eq 'map' ||
        $function eq 'map_report' )
    {
        require QualysGuard::Response::MapReport;
        $qualys_return = QualysGuard::Response::MapReport->new( $xml_content );
    }

    elsif ( $function eq 'map_report_list' ) {
        require QualysGuard::Response::MapReportList;
        $qualys_return = QualysGuard::Response::MapReportList->new( $xml_content );
    }

    elsif ( $function eq 'report_template_list' ) {
        require QualysGuard::Response::ReportTemplateList;
        $qualys_return = QualysGuard::Response::ReportTemplateList->new( $xml_content );
    }

    elsif ( 
        $function eq 'scan' ||
        $function eq 'scan_report' )
    {
        require QualysGuard::Response::ScanReport;
        $qualys_return = QualysGuard::Response::ScanReport->new( $xml_content );
    }

    elsif ( $function eq 'scan_options' ) {
        require QualysGuard::Response::ScanOptions;
        $qualys_return = QualysGuard::Response::ScanOptions->new( $xml_content );
    }

    elsif ( $function eq 'scan_report_list' ) {
        require QualysGuard::Response::ScanReportList;
        $qualys_return = QualysGuard::Response::ScanReportList->new( $xml_content );
    }

    elsif ( $function eq 'scan_running_list' ) {
        require QualysGuard::Response::ScanRunningList;
        $qualys_return = QualysGuard::Response::ScanRunningList->new( $xml_content );
    }

    elsif ( $function eq 'scan_target_history' ) {
        require QualysGuard::Response::ScanTargetHistory;
        $qualys_return = QualysGuard::Response::ScanTargetHistory->new( $xml_content );
    }

    elsif ( $function eq 'scheduled_scans' ) {
        require QualysGuard::Response::ScheduledScans;
        $qualys_return = QualysGuard::Response::ScheduledScans->new( $xml_content );
    }

    elsif ( $function eq 'ticket_delete' ) {
        require QualysGuard::Response::TicketDelete;
        $qualys_return = QualysGuard::Response::TicketDelete->new( $xml_content );
    }

    elsif ( $function eq 'ticket_edit' ) {
        require QualysGuard::Response::TicketEdit;
        $qualys_return = QualysGuard::Response::TicketEdit->new( $xml_content );
    }

    elsif ( $function eq 'ticket_list' ) {
        require QualysGuard::Response::TicketList;
        $qualys_return = QualysGuard::Response::TicketList->new( $xml_content );
    }

    elsif ( $function eq 'ticket_list_deleted' ) {
        require QualysGuard::Response::TicketListDeleted;
        $qualys_return = QualysGuard::Response::TicketListDeleted->new( $xml_content );
    }

    return $qualys_return;
}



1;

__END__

=head1 NAME

QualysGuard::Request - Simple interface to QualysGuard API

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use QualysGuard::Request;

    $QualysGuard::Request::Username = "username";
    $QualysGuard::Request::Password = "password";

    my $qualys_request = QualysGuard::Request->new( 'map_report_list' );

    # - provide map_report_list function arguments

    $qualys_request->attributes({
        'last'    => 'yes',
        'domain'  => 'example.com', 
    });

    # - qualys_response is a QualysGuard::Response::MapReportList object

    my $qualys_response = $qualys_request->submit();

    if ( $qualys_response->is_error() ) {
        die $qualys_response->get_error(); 
    }

    # - QualysGuard::Response is a subclass of XML::XPath which allows
    # - XML::XPath functionality in each of the QualysGuard::Response subclasses.
    # - In short you can extract data using the XML::XPath interface.

    my @map_refs = $qualys_response->findnodes('/SOME/XPATH/');

    ...


=head1 DESCRIPTION

Each XML response from the QualysGuard API has an associated doctype definition (DTD). Therefore each DTD has
an associated subclass of QualysGuard::Response. Below is a list of the QualysGuard functions supported
by QualysGuard::Request. 

=over

=item B<Qualys Function>           B<QualysGuard::Response Subclass>

=item ------------------        --------------------------------------

=item asset_data_report         QualysGuard::Response::AssetDataReport

=item asset_domain              QualysGuard::Response::GenericReturn

=item asset_domain_list         QualysGuard::Response::AssetDomainList 

=item asset_group               QualysGuard::Response::GenericReturn

=item asset_group_delete        QualysGuard::Response::GenericReturn

=item asset_group_list          QualysGuard::Response::AssetGroupList

=item asset_ip                  QualysGuard::Response::GenericReturn

=item asset_ip_list             QualysGuard::Response::AssetHostList

=item asset_range_info          QualysGuard::Response::AssetRangeInfo

=item asset_search              QualysGuard::Response::AssetSearchReport

=item get_host_info             QualysGuard::Response::HostInfo

=item get_tickets               QualysGuard::Response::RemediationTickets

=item iscanner_list             QualysGuard::Response::IScannerList

=item map                       QualysGuard::Response::MapReport

=item map-2                     QualysGuard::Response::MapReport2

=item map_report                QualysGuard::Response::MapReport

=item map_report_list           QualysGuard::Response::MapReportList

=item report_template_list      QualysGuard::Response::ReportTemplateList

=item scan                      QualysGuard::Response::ScanReport

=item scan_cancel               QualysGuard::Response::GenericReturn

=item scan_options              QualysGuard::Response::ScanOptions

=item scan_report               QualysGuard::Response::ScanReport

=item scan_report_delete        QualysGuard::Response::GenericReturn

=item scan_report_list          QualysGuard::Response::ScanReportList

=item scan_running_list         QualysGuard::Response::ScanRunningList

=item scan_target_history       QualysGuard::Response::ScanTargetHistory

=item scheduled_scans           QualysGuard::Response::ScheduledScans

=item ticket_delete             QualysGuard::Response::TicketDelete

=item ticket_edit               QualysGuard::Response::TicketEdit

=item ticket_list               QualysGuard::Response::TicketList

=item ticket_list_deleted       QualysGuard::Response::TicketListDeleted

=back


=head1 PUBLIC INTERFACE

=over 4

=item new ( QUALYS_FUNCTION )

Returns a new C<QualysGuard::Request> object. 

=item attributes ( $QUALYS_FUNCTION_ARGS )

The C<attributes> method takes a single hashref argument. The hashref should
contain all of the needed QualysGuard function arguments. Refer to the
QualysGuard API documentation for list of arguments for each of the available
functions.

L<http://www.qualys.com/docs/QualysGuard_API_User_Guide.pdf>


=item submit ()

Submits the request and returns a new subclass of C<QualysGuard::Response>.

=back


=head1 AUTHOR

Patrick Devlin, C<< <pdevlin at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-qualysguard-request at rt.cpan.org>, or through
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

L<QualysGuard::Response>


=head1 COPYRIGHT & LICENSE

Copyright 2008 Patrick Devlin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Qualys and the QualysGuard product are registered trademarks of Qualys, Inc.
