##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/Sigma/ScheduledQueryRun.pm
## Version v0.100.0
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2020/05/15
## 
##----------------------------------------------------------------------------
## https://stripe.com/docs/api/sigma/scheduled_queries/object
package Net::API::Stripe::Sigma::ScheduledQueryRun;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Net::API::Stripe::Generic );
    use vars qw( $VERSION );
    our( $VERSION ) = 'v0.100.0';
};

use strict;
use warnings;

sub id { return( shift->_set_get_scalar( 'id', @_ ) ); }

sub object { return( shift->_set_get_scalar( 'object', @_ ) ); }

sub created { return( shift->_set_get_datetime( 'created', @_ ) ); }

sub data_load_time { return( shift->_set_get_datetime( 'data_load_time', @_ ) ); }

sub error { return( shift->_set_get_hash( 'error', @_ ) ); }

sub file { return( shift->_set_get_object( 'file', 'Net::API::Stripe::File', @_ ) ); }

sub livemode { return( shift->_set_get_boolean( 'livemode', @_ ) ); }

sub result_available_until { return( shift->_set_get_datetime( 'result_available_until', @_ ) ); }

sub sql { return( shift->_set_get_scalar( 'sql', @_ ) ); }

sub status { return( shift->_set_get_scalar( 'status', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

1;
# NOTE: POD
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

    v0.100.0

=head1 DESCRIPTION

If you have scheduled a L<Sigma query|https://stripe.com/docs/sigma/scheduled-queries>, you'll receive a sigma.scheduled_query_run.created webhook each time the query runs. The webhook contains a ScheduledQueryRun object, which you can use to retrieve the query results.

=head1 CONSTRUCTOR

=head2 new( %ARG )

Creates a new L<Net::API::Stripe::Sigma::ScheduledQueryRun> object.
It may also take an hash like arguments, that also are method of the same name.

=head1 METHODS

=head2 id string

Unique identifier for the object.

=head2 object string, value is "scheduled_query_run"

String representing the object’s type. Objects of the same type share the same value.

=head2 created timestamp

Time at which the object was created. Measured in seconds since the Unix epoch.

=head2 data_load_time timestamp

When the query was run, Sigma contained a snapshot of your Stripe data at this time.

=head2 error hash

If the query run was not successful, this field contains information about the failure.

This is a L<Net::API::Stripe::Error> object.

=head2 file hash

The file object representing the results of the query.

This is a L<Net::API::Stripe::File> object.

=head2 livemode boolean

Has the value true if the object exists in live mode or the value false if the object exists in test mode.

=head2 result_available_until timestamp

Time at which the result expires and is no longer available for download.

=head2 sql string

SQL for the query.

=head2 status string

The query’s execution status, which will be completed for successful runs, and canceled, failed, or timed_out otherwise.

=head2 title string

Title of the query.

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
