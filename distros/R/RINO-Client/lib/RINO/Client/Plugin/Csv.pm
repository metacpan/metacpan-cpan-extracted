package RINO::Client::Plugin::Csv;

use strict;
require Class::CSV;

sub write_out {
    my $class = shift;
    my $ref = shift;
    my @array = @{$ref};
    my @header = @{$array[0]};

    my $csv = Class::CSV->new(
        fields  => \@header,
    );

    foreach my $rec (1 ... $#array){
        $csv->add_line([map { $array[$rec]->{$_} } @header]);
    }
    my $header = join(",",@{$csv->fields()});
    my $str = $header."\n";
    $str .= $csv->string();
    return $str;
}

1;
