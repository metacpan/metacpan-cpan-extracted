##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Sigma/ScheduledQueryRun.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/sigma/scheduled_queries/object
package Net::API::Stripe::Sigma::ScheduledQueryRun;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Generic );
    our( $VERSION ) = '0.1';
};

sub id { shift->_set_get_scalar( 'id', @_ ); }

sub object { shift->_set_get_scalar( 'object', @_ ); }

sub created { shift->_set_get_datetime( 'created', @_ ); }

sub data_load_time { shift->_set_get_datetime( 'data_load_time', @_ ); }

sub error { shift->_set_get_hash( 'error', @_ ); }

sub file { shift->_set_get_object( 'file', 'Net::API::Stripe::File', @_ ); }

sub livemode { shift->_set_get_boolean( 'livemode', @_ ); }

sub result_available_until { shift->_set_get_datetime( 'result_available_until', @_ ); }

sub sql { shift->_set_get_scalar( 'sql', @_ ); }

sub status { shift->_set_get_scalar( 'status', @_ ); }

sub title { shift->_set_get_scalar( 'title', @_ ); }

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::Sigma::ScheduledQueryRun - A Stripe Schedule Query Run Object

=head1 SYNOPSIS

    my $query = $stripe->schedule_query({
        created => '2020-06-12T08:00:00',
        data_load_time => '2020-06-12T08:00:02',
        file => $file_object,
        livemode => $stripe->false,
        result_available_until => '2020-05-31',
        sql => <<EOT,
	select
	  id,
	  amount,
	  fee,
	  currency
	from balance_transactions
	where
	  created < data_load_time and
	  created >= data_load_time - interval '1' month
	order by created desc
	limit 10
    EOT
        status => 'completed',
        title => 'Monthly balance transactions',
    });

See documentation in L<Net::API::Stripe> for example to make api calls to Stripe to create those objects.

=head1 VERSION

    0.1

=head1 DESCRIPTION

If you have scheduled a L<Sigma query|https://stripe.com/docs/sigma/scheduled-queries>, you'll receive a sigma.scheduled_query_run.created webhook each time the query runs. The webhook contains a ScheduledQueryRun object, which you can use to retrieve the query results.

=head1 CONSTRUCTOR

=over 4

=item B<new>( %ARG )

Creates a new L<Net::API::Stripe::Sigma::ScheduledQueryRun> object.
It may also take an hash like arguments, that also are method of the same name.

=back

=head1 METHODS

=over 4

=item B<id> string

Unique identifier for the object.

=item B<object> string, value is "scheduled_query_run"

String representing the object’s type. Objects of the same type share the same value.

=item B<created> timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=item B<data_load_time> timestamp

When the query was run, Sigma contained a snapshot of your Stripe data at this time.

=item B<error> hash

If the query run was not successful, this field contains information about the failure.

This is a L<Net::API::Stripe::Error> object.

=item B<file> hash

The file object representing the results of the query.

This is a L<Net::API::Stripe::File> object.

=item B<livemode> boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=item B<result_available_until> timestamp

Time at which the result expires and is no longer available for download.

=item B<sql> string

SQL for the query.

=item B<status> string

The query’s execution status, which will be completed for successful runs, and canceled, failed, or timed_out otherwise.

=item B<title> string

Title of the query.

=back

=head1 API SAMPLE

	{
	  "id": "sqr_fake123456789",
	  "object": "scheduled_query_run",
	  "created": 1571480457,
	  "data_load_time": 1571270400,
	  "file": {
		"id": "file_fake123456789",
		"object": "file",
		"created": 1537498020,
		"filename": "path",
		"links": {
		  "object": "list",
		  "data": [],
		  "has_more": false,
		  "url": "/v1/file_links?file=file_fake123456789"
		},
		"purpose": "sigma_scheduled_query",
		"size": 500,
		"title": null,
		"type": "csv",
		"url": "https://files.stripe.com/v1/files/file_fake123456789/contents"
	  },
	  "livemode": false,
	  "result_available_until": 1603065600,
	  "sql": "SELECT count(*) from charges",
	  "status": "completed",
	  "title": "Count all charges"
	}

=head1 HISTORY

=head2 v0.1

Initial version

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api/sigma/scheduled_queries>, L<https://stripe.com/docs/sigma/scheduled-queries>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
