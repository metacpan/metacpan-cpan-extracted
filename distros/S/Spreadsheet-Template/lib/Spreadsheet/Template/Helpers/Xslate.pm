package Spreadsheet::Template::Helpers::Xslate;
our $AUTHORITY = 'cpan:DOY';
$Spreadsheet::Template::Helpers::Xslate::VERSION = '0.05';
use strict;
use warnings;

use JSON;

my $JSON = JSON->new;

use Sub::Exporter 'build_exporter';

my $import = build_exporter({
    exports => [
        map { $_ => \&_curry_package } qw(format c merge true false)
    ],
    groups => {
        default => [qw(format c merge true false)],
    },
});

my %formats;

sub import {
    my $caller = caller;
    $formats{$caller} = {};
    goto $import;
}

sub format {
    my ($package, $name, $format) = @_;
    $formats{$package}{$name} = $format;
    return '';
}

sub c {
    my ($package, $contents, $format, $type, %args) = @_;

    $type = 'string' unless defined $type;

    return $JSON->encode({
        contents => "$contents",
        format   => _formats($package, $format),
        type     => $type,
        (defined $args{formula}
            ? (formula => $args{formula})
            : ()),
    });
}

sub merge {
    my ($package, $range, $contents, $format, $type, %args) = @_;

    $type = 'string' unless defined $type;

    return $JSON->encode({
        range    => _parse_range($range),
        contents => "$contents",
        format   => _formats($package, $format),
        type     => $type,
        (defined $args{formula}
            ? (formula => $args{formula})
            : ()),
    });
}

sub true  { JSON::true  }
sub false { JSON::false }

sub _parse_range {
    my ($range) = @_;

    $range = [ split ':', $range ]
        if !ref($range);

    return [ map { _cell_to_row_col($_) } @$range ]
}

sub _cell_to_row_col {
    my ($cell) = @_;

    return $cell if ref($cell) eq 'ARRAY';

    my ($col, $row) = $cell =~ /([A-Z]+)([0-9]+)/;

    my $ncol = 0;
    for my $char (split //, $col) {
        $ncol *= 26;
        $ncol += ord($char) - ord('A') + 1;
    }

    return [ $row - 1, $ncol - 1 ];
}

sub _formats {
    my ($package, $format) = @_;

    return $format if ref($format);

    return $formats{$package}{$format};
}

sub _curry_package {
    my ($package, $name) = @_;
    return sub { $package->$name(@_) };
}

=begin Pod::Coverage

 format
 c
 merge
 true
 false

=end Pod::Coverage

=cut

1;
