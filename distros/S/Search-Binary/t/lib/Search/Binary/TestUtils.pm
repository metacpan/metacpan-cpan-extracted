package Search::Binary::TestUtils;

use strict;
use warnings;
use parent 'Exporter';
our @EXPORT_OK = qw(make_numeric_array_reader);

sub make_numeric_array_reader {
    my ( $array ) = @_;
    my $current_pos = 0;
    return sub {
        my ( $self, $value, $pos ) = @_;
        $pos = $current_pos + 1 unless defined $pos;
        $current_pos = $pos;
        return ( $pos < scalar @{$array}
                 ? $value <=> $array->[$pos]
                 : -1, # see RT #52326
                 $pos );
    };
}

1;
