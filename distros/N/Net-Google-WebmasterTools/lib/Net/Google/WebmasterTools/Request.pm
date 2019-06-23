package Net::Google::WebmasterTools::Request;
{
    $Net::Google::WebmasterTools::Request::VERSION = '0.03';
}
use strict;

# ABSTRACT: Google Webmaster Tools API request

use Class::XSAccessor accessors => [
    qw(
        site_url
        report_name
        method
        dimension
        dimensions
        dimension_filter_groups
        operator
        expression
        sort
        filters
        segment
        start_index row_limit
        fields
        pretty_print
        user_ip quota_user
        )
    ],
    constructor => 'new';

my @param_map = (
    dimensions              => 'dimensions',
    dimension_filter_groups => 'dimensionFilterGroups',
    filters                 => 'filters',
    dimension               => 'dimension',
    operator                => 'operator',
    expression              => 'expression',
    search_type             => 'searchType',
    start_date              => 'startDate',
    end_date                => 'endDate',
    row_limit               => 'rowLimit',
    pretty_print            => 'prettyPrint',
    user_ip                 => 'userIp',
    quota_user              => 'quotaUser',
);

sub _params {
    my $self = shift;

    # for my $name (qw(site_url report_name)) {
    #     my $value = $self->{$name};
    #     die("parameter $name is empty")
    #         if !defined($value) || $value eq '';
    # }

    my %params;

    for ( my $i = 0; $i < @param_map; $i += 2 ) {
        my $from = $param_map[$i];
        my $to   = $param_map[ $i + 1 ];

        my $value = $self->{$from};
        $params{$to} = $value if defined($value);
    }

    return %params;
}

1;

=pod

=head1 NAME

Net::Google::WebmasterTools::Request - Google Webmaster Tools API request

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $req = $wmt->new_request(
        site_url         => "http://www.example.com",
        report_name  => "searchAnalytics",
        method     => "query",
        dimensions     => "[query,country,device]",
        search_type => "web",
        start_date  => "2015-08-01",
        end_date    => "2015-08-05",
        row_limit => 5,
    );

    my $res = $wmt->retrieve($req);

=head1 DESCRIPTION

Request class for L<Net::Google::WebmasterTools> web service.

=head1 CONSTRUCTOR

=head2 new

    my $req = Net::Google::WebmasterTools::Request->new(param => $value, ...);
    my $req = $wmt->new_request(param => $value, ...);

Creates a new request object with the given parameters. You can also use the
shorthand L<Net::Google::WebmasterTools/new_request>.

=head1 ACCESSORS

    $req->site_url('http://example.com');
    $req->method('query');

See the
L<API reference|https://developers.google.com/webmaster-tools/v3/parameters>
for a description of the request parameters. The provided parameter values must
not be URL encoded.

=head2 site_url

Required

=head2 report_name

Required

=head2 method

Required

=head2 start_date

Required

=head2 end_date

Required

=head2 dimensions

=head2 row_limit

=head2 fields

=head2 pretty_print

=head2 user_ip

=head2 quota_user

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


