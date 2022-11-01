package Net::API::Stripe::Reporting::ReportType;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.2.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub data_available_end { return( shift->_set_get_datetime( 'data_available_end', @_ ) ); }

sub data_available_start { return( shift->_set_get_datetime( 'data_available_start', @_ ) ); }

sub default_columns { return( shift->_set_get_array( 'default_columns', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }

sub updated { return( shift->_set_get_datetime( 'updated', @_ ) ); }

sub version { return( shift->_set_get_number( 'version', @_ ) ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Reporting::ReportType - The Report Type object

=head1 SYNOPSIS

    my $type = $stripe->report_type({
        data_available_end => '2020-11-17T12:15:20',
        data_available_start => '2020-03-01T07:30:20',
        default_columns => $some_array,
        name => 'type name',
        updated => 'now',
        version => 1,
    });

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The Report Type resource corresponds to a particular type of report, such as the "Activity summary" or "Itemized payouts" reports. These objects are identified by an ID belonging to a set of enumerated values. See [API Access to Reports documentation](/docs/reporting/statements/api) for those Report Type IDs, along with required and optional parameters.
 Note that reports can only be run based on your live-mode data (not test-mode data), and thus related requests must be made with a [live-mode API key](/docs/keys#test-live-modes).

=head1 METHODS

=head2 id string

The [ID of the Report Type](/docs/reporting/statements/api#available-report-types), such as `balance.summary.1`.

=head2 object string

String representing the object's type. Objects of the same type share the same value.

=head2 data_available_end timestamp

Most recent time for which this Report Type is available. Measured in seconds since the Unix epoch.

=head2 data_available_start timestamp

Earliest time for which this Report Type is available. Measured in seconds since the Unix epoch.

=head2 default_columns string_array

List of column names that are included by default when this Report Type gets run. (If the Report Type doesn't support the `columns` parameter, this will be null.)

=head2 livemode boolean

Has the value C<true> if the object exists in live mode or the value C<false> if the object exists in test mode.

=head2 name string

Human-readable name of the Report Type

=head2 updated timestamp

When this Report Type was latest updated. Measured in seconds since the Unix epoch.

=head2 version integer

Version of the Report Type. Different versions report with the same ID will have the same purpose, but may take different run parameters or have different result schemas.

=head1 API SAMPLE

    {
      "id": "balance.summary.1",
      "object": "reporting.report_type",
      "data_available_end": 1604966400,
      "data_available_start": 1385769600,
      "default_columns": [
        "category",
        "description",
        "net_amount",
        "currency"
      ],
      "name": "Balance summary",
      "updated": 1605009363,
      "version": 1
    }

=head1 HISTORY

=head2 v0.1.0

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api#reporting_report_type_object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
