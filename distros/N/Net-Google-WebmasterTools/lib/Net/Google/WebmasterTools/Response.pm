package Net::Google::WebmasterTools::Response;
{
  $Net::Google::WebmasterTools::Response::VERSION = '0.03';
}
use strict;

# ABSTRACT: Google Webmaster Tools API response

use Class::XSAccessor
    accessors => [ qw(
        is_success
        code message content
        total_results start_index items_per_page
        contains_sampled_data
        profile_info
        rows
        _column_headers
        _totals
    ) ],
    constructor => 'new';

sub error_message {
    my $self = shift;

    return join(' ', $self->code,  $self->message, $self->content);
}

sub _parse_json {
    my ($self, $json) = @_;

    $self->items_per_page($json->{itemsPerPage});
    $self->total_results($json->{totalResults});
    $self->contains_sampled_data($json->{containsSampledData});
    $self->profile_info($json->{profileInfo});

    my $json_totals = $json->{totalsForAllResults};
    my %totals;

    while (my ($json_name, $total) = each(%$json_totals)) {
        my $column_name = _parse_column_name($json_name);
        $totals{$column_name} = $total;
    }

    $self->_totals(\%totals);

    my @column_headers;

    for my $column_header (@{ $json->{columnHeaders} }) {
        push(@column_headers, {
            name        => _parse_column_name($column_header->{name}),
            column_type => $column_header->{columnType},
            data_type   => $column_header->{dataType},
        });
    }

    $self->_column_headers(\@column_headers);

    my $class = Net::Google::WebmasterTools::Row->_gen_class(\@column_headers);

    my @rows = map { $class->new($_) } @{ $json->{rows} };
    $self->rows(\@rows);
}

sub _parse_column_name {
    my $name = shift;

    my ($res) = $name =~ /^(?:ga|rt):(\w{1,64})\z/
        or die("invalid column name: $name");
    # convert camel case
    $res =~ s/[A-Z]/'_' . lc($&)/ge;

    return $res;
}

sub metrics {
    my $self = shift;

    return $self->_columns('METRIC');
}

sub dimensions {
    my $self = shift;

    return $self->_columns('DIMENSION');
}

sub totals {
    my ($self, $metric) = @_;
    return $self->_totals->{$metric};
}

sub _columns {
    my ($self, $type) = @_;

    my $column_headers = $self->_column_headers;
    my @results;

    for my $column_header (@$column_headers) {
        if ($column_header->{column_type} eq $type) {
            push(@results, $column_header->{name});
        }
    }

    return @results;
}

sub project {
    my ($self, $proj_dim_names, $projection) = @_;

    my (@metric_indices, @proj_column_headers);
    my $column_headers = $self->_column_headers;

    for (my $i = 0; $i < @$column_headers; ++$i) {
        my $column_header = $column_headers->[$i];

        if ($column_header->{column_type} eq 'METRIC') {
            push(@metric_indices, $i);
            push(@proj_column_headers, { %$column_header });
        }
    }

    for my $name (@$proj_dim_names) {
        push(@proj_column_headers, {
            name        => $name,
            column_type => 'DIMENSION',
        });
    }

    my $class = Net::Google::WebmasterTools::Row->_gen_class(\@proj_column_headers);

    # Projected rows are collected in hash %proj_rows. The keys of the hash
    # are the the projected dimension values joined with zero bytes.

    my %proj_rows;

    for my $row (@{ $self->rows }) {
        my @proj_dim_values = $projection->($row);
        my $key = join("\0", @proj_dim_values);

        my $proj_row = $proj_rows{$key};

        if (!$proj_row) {
            my @proj_metric_values = map { $row->[$_] } @metric_indices;
            $proj_rows{$key} = $class->new(
                [ @proj_metric_values, @proj_dim_values ],
            );
        }
        else {
            for (my $i = 0; $i < @metric_indices; ++$i) {
                my $mi = $metric_indices[$i];
                $proj_row->[$i] += $row->[$mi];
            }
        }
    }

    $self->rows([ values(%proj_rows) ]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Google::WebmasterTools::Response - Google Webmaster Tools API response

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $res = $wmt->retrieve($req);
    die("GWMT error: " . $res->error_message) if !$res->is_success;

    print
        "Results: 1 - ", $res->items_per_page,
        " of ", $res->total_results, "\n\n";

    for my $row (@{ $res->rows }) {
        print
            $row->get_source,  ": ",
            $row->get_visits,  " visits, ",
            $row->get_bounces, " bounces\n";
    }

    print
        "\nTotal: ",
        $res->totals("visits"),  " visits, ",
        $res->totals("bounces"), " bounces\n";

=head1 DESCRIPTION

Response class for L<Net::Google::WebmasterTools> web service.

=head1 NAME

Net::Google::WebmasterTools::Response - Google Webmaster Tools API response

=head1 VERSION

version 0.03

=head1 CONSTRUCTOR

=head2 new

=head1 ACCESSORS

=head2 is_success

True for successful requests, false in case of an error.

=head2 code

The HTTP status code.

=head2 message

The HTTP status message.

=head2 content

In case of an error, this field contains a JSON string with additional
information about the error from the response body.

=head2 error_message

The full error message.

=head2 total_results

The total number of results for the query, regardless of the number of
results in the response.

=head2 start_index

The 1-based start index of the result rows.

=head2 items_per_page

The number of rows returned.

=head2 contains_sampled_data

Returns true if the results contain sampled data.

=head2 profile_info

A hashref containing information about the analytics profile.

=head2 rows

An arrayref of result rows of type L<Net::Google::WebmasterTools::Row>.

=head2 dimensions

An array of all dimension names.

=head1 METHODS

=head2 totals

    my $total = $res->totals($metric);

Returns the sum of all results for a metric regardless of the actual subset
of results returned. $metric is a metric name without the 'ga:' prefix and
converted to lower case with underscores.

=head2 project

    $res->project(\@proj_dim_names, \&projection);

Projects the dimension values of every result row to new dimension values using
subroutine reference \&projection. The metrics of rows that are mapped to the
same dimension values are summed up.

Argument \@proj_dim_names is an arrayref containing the names of the
new dimensions.

The projection subroutine takes as single argument a
L<Net::Google::WebmasterTools::Row> object and must return an array of dimension
values.

The following example maps a single dimension of type ga:pagePath to
categories.

    $res->project([ 'category' ], sub {
        my $row = shift;

        my $page_path = $row->get_page_path;

        return ('flowers') if $page_path =~ m{^/(tulips|roses)};
        return ('fruit')   if $page_path =~ m{^/(apples|oranges)};

        return ('other');
    });

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Hammond <contact@rjh.am>, Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
