package Net::Google::Analytics::Request;
$Net::Google::Analytics::Request::VERSION = '3.05';
use strict;
use warnings;

# ABSTRACT: Google Analytics API request

use Class::XSAccessor
    accessors => [ qw(
        realtime
        ids
        start_date end_date
        metrics dimensions
        sort
        filters
        segment
        start_index max_results
        fields
        sampling_level
        pretty_print
        user_ip quota_user
    ) ],
    constructor => 'new';

my @param_map = (
    ids            => 'ids',
    start_date     => 'start-date',
    end_date       => 'end-date',
    metrics        => 'metrics',
    dimensions     => 'dimensions',
    sort           => 'sort',
    filters        => 'filters',
    segment        => 'segment',
    fields         => 'fields',
    sampling_level => 'samplingLevel',
    pretty_print   => 'prettyPrint',
    user_ip        => 'userIp',
    quota_user     => 'quotaUser',
);

sub _params {
    my $self = shift;

    my @required = qw(ids metrics);

    if (!$self->{realtime}) {
        push(@required, qw(start_date end_date));
    }

    for my $name (@required) {
        my $value = $self->{$name};
        die("parameter $name is empty")
            if !defined($value) || $value eq '';
    }

    my @params;

    for (my $i=0; $i<@param_map; $i+=2) {
        my $from = $param_map[$i];
        my $to   = $param_map[$i+1];

        my $value = $self->{$from};
        push(@params, $to => $value) if defined($value);
    }

    return @params;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::Analytics::Request - Google Analytics API request

=head1 VERSION

version 3.05

=head1 SYNOPSIS

    my $req = $analytics->new_request(
        ids         => "ga:$profile_id",
        dimensions  => "ga:medium,ga:source",
        metrics     => "ga:bounces,ga:visits",
        filters     => "ga:medium==referral",
        sort        => "-ga:visits",
        start_date  => "2011-10-01",
        end_date    => "2011-10-31",
        max_results => 5,
    );

    my $res = $analytics->retrieve($req);

=head1 DESCRIPTION

Request class for L<Net::Google::Analytics> web service.

=head1 CONSTRUCTOR

=head2 new

    my $req = Net::Google::Analytics::Request->new(param => $value, ...);
    my $req = $analytics->new_request(param => $value, ...);

Creates a new request object with the given parameters. You can also use the
shorthand L<Net::Google::Analytics/new_request>.

=head1 ACCESSORS

    $req->ids('ga:...');
    $req->dimensions('ga:...');

See the
L<API reference|http://code.google.com/apis/analytics/docs/gdata/v3/reference.html#data_request>
for a description of the request parameters. The provided parameter values must
not be URL encoded.

=head2 realtime

Set this parameter to use the Real Time Reporting API.

=head2 ids

Required

=head2 start_date

Required for non-realtime requests

=head2 end_date

Required for non-realtime requests

=head2 metrics

Required

=head2 dimensions

=head2 sort

=head2 filters

=head2 segment

=head2 sampling_level

=head2 start_index

=head2 max_results

=head2 fields

=head2 pretty_print

=head2 user_ip

=head2 quota_user

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
