##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Reporting/ReportRun.pm
## Version 0.1
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/01/19
## Modified 2020/01/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Reporting::ReportRun;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub error { return( shift->_set_get_scalar( 'error', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub parameters
{
	return( shift->_set_get_class( 'parameters',
	{
	columns => { type => 'array_as_object' },
	connected_account => { type => 'scalar_as_object' },
	currency => { type => 'scalar_as_object' },
	interval_end => { type => 'datetime' },
	interval_start => { type => 'datetime' },
	payout => { type => 'scalar_as_object' },
	reporting_category => { type => 'scalar_as_object' },
	}, @_ ) );
}

sub report_type { return( shift->_set_get_scalar( 'report_type', @_ ) ); }

sub result { return( shift->_set_get_object( 'result', 'Net::APi::Stripe::File', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub succeeded_at { return( shift->_set_get_datetime( 'succeeded_at', @_ ) ); }

1;

=encoding utf8

=head1 NAME

Net::API::Stripe::Reporting::ReportRun - Stripe API Reporting Run Object

=head1 SYNOPSIS

=head1 VERSION

    0.1

=head1 DESCRIPTION

The Report Run object represents an instance of a report type generated with specific run parameters. Once the object is created, Stripe begins processing the report. When the report has finished running, it will give you a reference to a file where you can retrieve your results. For an overview, see API Access to Reports (L<https://stripe.com/docs/reporting/statements/api>).

Note that reports can only be run based on your live-mode data (not test-mode data), and thus related requests must be made with a live-mode API key (L<https://stripe.com/docs/keys#test-live-modes>).

=head1 CONSTRUCTOR

=over 4

=item B<new>( %arg )

Creates a new C<Net::API::Stripe::Reporting::ReportRun> objects.
It may also take an hash like arguments, that also are method of the same name.

=over 8

=item I<debug>

Toggles debug mode on/off

=back

=head1 METHODS

=over 4

=item B<id>() string

Unique identifier for the object.

=item B<object>() string, value is "reporting.report_run"

String representing the object’s type. Objects of the same type share the same value.

=item B<created>() timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<error>() string

If something should go wrong during the run, a message about the failure (populated when status=failed).

=item B<livemode>() boolean

Always true: reports can only be run on live-mode data.

=item B<parameters>() hash

Parameters of this report run.

=over 8

=item I<columns> array containing strings

The set of output columns requested for inclusion in the report run.

=item I<connected>_account string

Connected account ID by which to filter the report run.

=item I<urrency> currency

Currency of objects to be included in the report run.

=item I<interval_end> timestamp

Ending timestamp of data to be included in the report run (exclusive).

=item I<interval_start> timestamp

Starting timestamp of data to be included in the report run.

=item I<payout> string

Payout ID by which to filter the report run.

=item I<reporting_category> string

Category of balance transactions to be included in the report run.

=back

=item B<report_type>() string

The ID of the report type to run, such as "balance.summary.1".

=item B<result>() hash

The file object (C<Net::APi::Stripe::File>) representing the result of the report run (populated when status=succeeded).

=item B<status>() string

Status of this report run. This will be pending when the run is initially created. When the run finishes, this will be set to succeeded and the result field will be populated. Rarely, we may encounter an error, at which point this will be set to failed and the error field will be populated.

=item B<succeeded_at>() timestamp

Timestamp at which this run successfully finished (populated when status=succeeded). Measured in seconds since the Unix epoch.

=back

=head1 API SAMPLE

	{
	  "id": "frr_1G2dqECeyNCl6fY2KeuZWZ14",
	  "object": "reporting.report_run",
	  "created": 1579440566,
	  "error": null,
	  "livemode": true,
	  "parameters": {
		"interval_end": 1525132800,
		"interval_start": 1522540800
	  },
	  "report_type": "balance.summary.1",
	  "result": {
		"id": "file_1D4e5EF5IfL0eXz9mGVilzEx",
		"object": "file",
		"created": 1535589144,
		"filename": "file_1D4e5EF5IfL0eXz9mGVilzEx",
		"links": {
		  "object": "list",
		  "data": [],
		  "has_more": false,
		  "url": "/v1/file_links?file=file_1D4e5EF5IfL0eXz9mGVilzEx"
		},
		"purpose": "finance_report_run",
		"size": 9863,
		"title": null,
		"type": "csv",
		"url": "https://files.stripe.com/v1/files/file_1D4e5EF5IfL0eXz9mGVilzEx/contents"
	  },
	  "status": "succeeded",
	  "succeeded_at": 1525192811
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


