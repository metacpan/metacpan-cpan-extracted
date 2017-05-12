package Net::Dynect::REST::QPSReport;

# $Id: QPSReport.pm 177 2010-09-28 00:50:02Z james $
use strict;
use warnings;
use Carp;
use Net::Dynect::REST::RData;
our $VERSION = do { my @r = ( q$Revision: 177 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME 

Net::Dynect::REST::QPSReport - Get queries per second report

=head1 SYNOPSIS

  use Net::Dynect::REST:QPSReport;
  my @records = Net::Dynect::REST:QPSReport->delete(connection => $dynect, 
                                           zone => $zone, fqdn => $fqdn);

=head1 METHODS

=head2 Creating

=over 4

=item  Net::Dynect::REST:QPSReport->find(connection => $dynect, start_ts=> $time, end_ts => $time);

This will return an string containing a CSV, if successful. You must supply the start timestamp and end timestamps, as Unix Epoch time (number of seconds since 1 Jan 1970). You may also optionally specify what to break down - either by hosts, by resource records, or by zones. You can also optionally filter by hosts, recource records, and zones. For example, to see the report per resource record, but only for A and CNAME lookups, you could set I<breakdown => 'rrec', rrecs => qw(A CNAME)>.

Valid options for 'breakdown' are:

=over 4

=item * hosts

=item * rrecs

=item * zones

=back

Note the time date range must not be more than 45 days.

=cut

sub find {
    my $proto = shift;
    my %args  = @_;
    if (
        not( defined( $args{connection} )
            && ref( $args{connection} ) eq "Net::Dynect::REST" )
      )
    {
        carp "Need a connection (Net::Dynect::REST)";
        return;
    }

    if ( not defined( $args{start_ts} ) ) {
        carp "Need start time stamp start_ts";
        return;
    }
    if ( not defined( $args{end_ts} ) ) {
        carp "Need end time stamp end_ts";
        return;
    }

    my $params = {
        start_ts => $args{start_ts},
        end_ts   => $args{end_ts}
    };
    $params->{breakdown} = $args{breakdown} if ( defined $args{breakdown} );
    $params->{hosts}     = $args{hosts}     if ( defined $args{hosts} );
    $params->{rrecs}     = $args{rrecs}     if ( defined $args{rrecs} );
    $params->{zones}     = $args{zones}     if ( defined $args{zones} );

    my $request = Net::Dynect::REST::Request->new(
        operation => 'create',
        service   => __PACKAGE__->_service_base_uri,
        params    => $params
    );
    if ( not $request ) {
        carp "Request not valid: $request";
        return;
    }

    my $response = $args{connection}->execute($request);

    if ( $response->status !~ /^success$/i ) {
        carp $response;
        return;
    }
    return $response->data->csv;
}

sub _service_base_uri {
    return "QPSReport";
}

1;

=back

=head1 AUTHOR

James Bromberger, james@rcpt.to

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::info>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
