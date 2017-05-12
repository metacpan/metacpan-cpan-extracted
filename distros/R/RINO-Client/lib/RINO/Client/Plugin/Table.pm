package RINO::Client::Plugin::Table;

use strict;
require Text::Table;

sub write_out {
    my $class = shift;
    my $ref = shift;
    my @array = @{$ref};

    # our first item in the array is always an array of the headers in the order we want
    my @header = @{$array[0]};
    my @cols = @header;
    @header = map { $_, { is_sep => 1, title => '|' } } @header;
    my $table = Text::Table->new(@header);
    foreach my $rec (1 ... $#array){
        $table->load([ map { $array[$rec]->{$_} } @cols ]);
    }

    return($table);
}

1;
