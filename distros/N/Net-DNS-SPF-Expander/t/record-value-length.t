use strict;
use warnings;
use lib 'lib';

use Net::DNS::SPF::Expander;

use Test::More;
use Test::Exception;

my $file_to_expand = 't/etc/test_zonefile_complex';

my $expander;
lives_ok {
    $expander = Net::DNS::SPF::Expander->new( input_file => $file_to_expand, );
}
"I can make a new expander";

my $new_spf_records = $expander->new_spf_records;
my $max_length      = $expander->maximum_record_length;
for my $zone ( keys %$new_spf_records ) {
    for my $recordset ( @{ $new_spf_records->{$zone} } ) {
        for my $record (@$recordset) {
            my $length = length( $record->txtdata );
            ok(
                $length <= $max_length,
"The length of this record ($length) is less than or equal to the max length ($max_length)"
            );
        }
    }
}
done_testing;
