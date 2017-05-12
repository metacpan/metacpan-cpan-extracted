package Net::NationalRail::LiveDepartureBoards;

use strict;
use warnings;

use SOAP::Lite
    proxy => 'http://www.livedepartureboards.co.uk/ldbws/ldb2.asmx';

use constant {
    URI_PREFIX => 'http://thalesgroup.com/RTTI/2008-02-20/ldb/',
};

=head1 NAME

Net::NationalRail::LiveDepartureBoards - Live Departure Boards information

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Provides an interface to the National Rail Enquiries Live Departure Boards
SOAP API, as documented at http://www.livedepartureboards.co.uk/ldbws/.

    use Net::NationalRail::LiveDepartureBoards;

    my $ldb = Net::NationalRail::LiveDepartureBoards->new();
    my $hashref = $ldb->departures(rows => 10, crs => 'RUG');

    # Or filter by trains going to another place
    my $hashref = $ldb->departures(rows => 10, crs => 'RUG', filtercrs => 'SOU');

    # Or get trains arriving from another place
    my $hashref = $ldb->departures(rows => 10, crs => 'SOU',
        filtercrs => 'RUG', filtertype => 'from');

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    bless \%args, $class;
}

=head2 departures

=cut

sub departures {
    return _station_board_request('GetDepartureBoard', @_);
}

=head2 arrivals

=cut

sub arrivals {
    return _station_board_request('GetArrivalBoard', @_);
}

=head2 arrivals_and_departures

=cut

sub arrivals_and_departures {
    return _station_board_request('GetArrivalDepartureBoard', @_);
}

sub _station_board_request {
    my $method = shift;
    my $self = shift;
    my %arg = @_;

    my @opt_args;
    if (exists($arg{filtercrs})) {
        push @opt_args, SOAP::Data->name(filterCrs => $arg{filtercrs});

	my $type = (exists $arg{filtertype} ? $arg{filtertype} : 'to');
	push @opt_args, SOAP::Data->name(filterType => $type);
    }

    my $result = _soap_request(
         $method,
         URI_PREFIX . 'types',
         SOAP::Data->name(numRows => $arg{'rows'}),
         SOAP::Data->name(crs => $arg{'crs'}),
         @opt_args
    );

    if ($result->fault) {
         die join ', ', $result->faultcode, $result->faultstring;
    } else {
         return $result->result();
    }
}

sub _soap_request {
    my $method = shift;
    my $target_namespace = shift;

    return SOAP::Lite
        ->on_action(sub { URI_PREFIX . $method })
        ->call( SOAP::Data->name($method . 'Request')->attr(
                    {xmlns => $target_namespace}),
                @_,
        );
}

=head1 AUTHOR

Tim Retout, C<< <diocles at cpan.org> >>

=head1 BUGS

This is version 0.02. The API is probably not stable yet. There are
probably bugs. The module could break at any time at the whim of ATOC.


Please report any bugs or feature requests to C<bug-net-nationalrail-livedepartureboards at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-NationalRail-LiveDepartureBoards>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::NationalRail::LiveDepartureBoards


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-NationalRail-LiveDepartureBoards>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-NationalRail-LiveDepartureBoards>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-NationalRail-LiveDepartureBoards>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-NationalRail-LiveDepartureBoards>

=back


=head1 COPYRIGHT & LICENSE

Copyright (C) 2009, 2010 Tim Retout, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::NationalRail>, L<WWW::LiveDepartureBoards>

=cut

1; # End of Net::NationalRail::LiveDepartureBoards
