package Parse::PayPal::TxFinderReport;

our $DATE = '2018-11-06'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_paypal_txfinder_report);

use DateTime; # XXX use a more lightweight alternative

our %SPEC;

sub _parse_date {
    my ($fmt, $date) = @_;
    if ($fmt eq 'MM/DD/YYYY') {
        $date =~ m!^(\d\d?)/(\d\d?)/(\d\d\d\d)$!
            or die "Invalid date format in '$date', must be MM/DD/YYYY";
        return DateTime->new(year => $3, month => $1, day => $2)->epoch;
    } elsif ($fmt eq 'DD/MM/YYYY') {
        $date =~ m!^(\d\d?)/(\d\d?)/(\d\d\d\d)$!
            or die "Invalid date format in '$date', must be DD/MM/YYYY";
        return DateTime->new(year => $3, month => $2, day => $1)->epoch;
    } else {
        die "Unknown date format, please use MM/DD/YYYY or DD/MM/YYYY";
    }
}

sub _parse_num {
    my ($thousands_sep, $decimal_point, $num) = @_;
    if ($thousands_sep) {
        $num =~ s/\Q$thousands_sep//g;
    }
    if ($decimal_point && $decimal_point ne '.') {
        $num =~ s/\Q$decimal_point/./;
    }
    $num;
}

$SPEC{parse_paypal_txfinder_report} = {
    v => 1.1,
    summary => 'Parse PayPal transaction detail report into data structure',
    description => <<'_',

The result will be a hashref. The main key is `transactions` which will be an
arrayref of hashrefs.

Dates will be converted into Unix timestamps.

_
    args => {
        file => {
            schema => ['filename*'],
            description => <<'_',

File can be in tab-separated or comma-separated (CSV) format.

_
            pos => 0,
        },
        string => {
            schema => ['str*'],
            description => <<'_',

Instead of `files`, you can alternatively provide the file contents in
`strings`.

_
        },
        format => {
            schema => ['str*', in=>[qw/tsv csv/]],
            description => <<'_',

If unspecified, will be deduced from the filename's extension (/csv/i for
CSV, or /txt|tsv|tab/i for tab-separated).

_
        },
        date_format => {
            schema => ['str*', in=>['MM/DD/YYYY', 'DD/MM/YYYY']],
            default => 'MM/DD/YYYY',
        },
        thousands_sep => {
            schema => ['str*', in=>['.', '', ',']],
            default => ',',
        },
        decimal_point => {
            schema => ['str*', in=>['.', ',']],
            default => '.',
        },
    },
    args_rels => {
        req_one => ['file', 'string'],
    },
};
sub parse_paypal_txfinder_report {
    my %args = @_;

    my $format = $args{format};
    my $date_format   = $args{date_format}   // 'MM/DD/YYYY';
    my $thousands_sep = $args{thousands_sep} // ',';
    my $decimal_point = $args{decimal_point} // '.';

    my $handle;
    my $file;
    if (defined(my $str0 = $args{string})) {
        require IO::Scalar;
        require String::BOM;

        if (!$format) {
            $format = $str0 =~ /\t/ ? 'tsv' : 'csv';
        }
        my $str = String::BOM::strip_bom_from_string($str0);
        $handle = IO::Scalar->new(\$str);
        $file = "(string)";
    } elsif (defined(my $file = $args{file})) {
        require File::BOM;

        if (!$format) {
            $format = $file =~ /\.(csv)\z/i ? 'csv' : 'tsv';
        }
        open $handle, "<:encoding(utf8):via(File::BOM)", $file
            or return [500, "Can't open file '$file': $!"];
    } else {
        return [400, "Please specify files (or strings)"];
    }

    my $res = [200, "OK", {
        format => "txfinder",
        transactions => [],
    }];

    my $column_names;
    my $variant; # STR="Search Transaction Results", TF="Transaction Finder"
    my $state;   # header, data, postamble
    my $code_parse_row = sub {
        my ($row, $rownum) = @_;
        if ($rownum == 1) {
            return [412, "There are no rows"] unless @$row;
            if ($row->[0] eq 'Search Transactions Results') {
                $variant = 'STR';
            } elsif ($row->[0] eq 'Transaction Finder') {
                $variant = 'TF';
            } else {
                return [400, "Doesn't find signature in first row"];
            }
            $state = 'header';
            return;
        }
        if ($state eq 'postamble') {
            return $res;
        }
        if (!@$row || @$row == 1 && $row->[0] eq '') {
            if ($state eq 'header') {
                $state = 'data';
            } elsif ($state eq 'data') {
                $state = 'postamble';
            }
            return;
        }
        if ($state eq 'header') {
            # set column names as the last row in header
            $column_names = $row;
            return;
        }
        if ($state eq 'data') {
            return if $row->[0] eq 'Total';
            my $hash = {};
            for (0..@$row) {
                my $key = $column_names->[$_] // "";
                last unless length $key;
                my $v;
                if ($key =~ /^Date$/) {
                    $v = _parse_date($date_format, $row->[$_]);
                } elsif ($key =~ /Amount|Fee/) {
                    $v = _parse_num($thousands_sep, $decimal_point, $row->[$_]);
                } else {
                    $v = $row->[$_];
                }
                $hash->{$key} = $v;
            }
            push @{ $res->[2]{transactions} }, $hash;
            return;
        }
        return;
    }; # code_parse_row

    if ($format eq 'csv') {
        require Text::CSV;
        my $csv = Text::CSV->new
            or return [500, "Cannot use CSV: ".Text::CSV->error_diag];
        my $rownum = 0;
        while (my $row = $csv->getline($handle)) {
            $rownum++;
            my $row_res = $code_parse_row->($row, $rownum);
            return $row_res if $row_res;
        }
    } else {
        my $rownum = 0;
        while (my $line = <$handle>) {
            $rownum++;
            chomp($line);
            my $row_res = $code_parse_row->([split /\t/, $line], $rownum);
            return $row_res if $row_res;
        }
    }

  RETURN_RES:
    $res;
}

1;
# ABSTRACT: Parse PayPal transaction detail report into data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::PayPal::TxFinderReport - Parse PayPal transaction detail report into data structure

=head1 VERSION

This document describes version 0.003 of Parse::PayPal::TxFinderReport (from Perl distribution Parse-PayPal-TxFinderReport), released on 2018-11-06.

=head1 SYNOPSIS

 use Parse::PayPal::TxFinderReport qw(parse_paypal_txfinder_report);

 my $res = parse_paypal_txfinder_report(file => );

Sample result when there is a parse error:

 [400, "Doesn't find signature in first row"]

Sample result when parse is successful:

 [200, "OK", {
     format => "txfinder",
     transactions           => [
         {
             "3PL Reference ID"                   => "",
             "Auction Buyer ID"                   => "",
             "Auction Closing Date"               => "",
             "Auction Site"                       => "",
             "Authorization Review Status"        => 1,
             ...
             "Transaction Completion Date"        => 1467273397,
             ...
         },
         ...
     ],
 }]

=head1 DESCRIPTION

PayPal provides various kinds reports which you can retrieve from their website
under Reports menu. This module provides routine to parse PayPal transaction
finder report into a Perl data structure. The CSV format is supported. No
official documentation of the format is available, but it's mostly regular CSV.

This module can recognize two variants of the report:

=head2 Search Transaction Results (STR)

Some characteristics of this variant:

=over

=item * Date is MM/DD/YYYY only without hour/minute/second information

Date will be converted to Unix epoch in the returned data structure.

=item * No transaction status field

=back

=head2 Transaction Finder (TF)

Some characteristics of this variant:

=over

=item * Dates are locale-formatted (e.g. DD/MM/YYYY)

Date will be converted to Unix epoch in the returned data structure. Make sure
you set the correct C<date_format> parameter.

=item * Numbers are locale-formatted (e.g. 1,23 instead of 1.23 when using comma as decimal character)

Formatting will be removed. Make sure you set the correct C<thousands_sep> and
C<decimal_point> parameters.

=back

=head1 FUNCTIONS


=head2 parse_paypal_txfinder_report

Usage:

 parse_paypal_txfinder_report(%args) -> [status, msg, payload, meta]

Parse PayPal transaction detail report into data structure.

The result will be a hashref. The main key is C<transactions> which will be an
arrayref of hashrefs.

Dates will be converted into Unix timestamps.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date_format> => I<str> (default: "MM/DD/YYYY")

=item * B<decimal_point> => I<str> (default: ".")

=item * B<file> => I<filename>

File can be in tab-separated or comma-separated (CSV) format.

=item * B<format> => I<str>

If unspecified, will be deduced from the filename's extension (/csv/i for
CSV, or /txt|tsv|tab/i for tab-separated).

=item * B<string> => I<str>

Instead of C<files>, you can alternatively provide the file contents in
C<strings>.

=item * B<thousands_sep> => I<str> (default: ",")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

L<https://www.paypal.com>

L<Parse::PayPal::TxDetailReport>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
