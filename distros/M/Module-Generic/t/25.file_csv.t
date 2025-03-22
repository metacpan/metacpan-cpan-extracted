#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use Test::More;
    use_ok( 'Module::Generic::File', ('file') ) || BAIL_OUT( "Unable to load Module::Generic::File" );
    local $@;
    eval( 'require Text::CSV' );
    if( $@ )
    {
        plan(skip_all => 'These tests require Text::CSV to be installed.');
    }
    else
    {
        plan();
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
use utf8;

# There are 69 lines, including 1 line for the header
my $parent    = file(__FILE__)->parent;
my $csv_in    = $parent->child( 'test_in.csv' );
my $csv_out   = $parent->child( 'test_out.csv' );
my $csv_empty = $parent->child( 'test_empty.csv' );
$csv_out->remove if( $csv_out->exists );
$csv_empty->remove if( $csv_empty->exists );
# expect 67 rows
$csv_in->debug($DEBUG);
# NOTE: headers => 'auto'
my $all = $csv_in->load_csv( headers => 'auto' ) || BAIL_OUT( $csv_in->error );
isa_ok( $all => 'Module::Generic::Array', 'array object returned' );
is( scalar( @$all ), 3, 'count' );
is( ref( $all->[0] // '' ), 'HASH', 'returns array of hash reference.' );
is( $all->[0]->{narration}, 'ﾔﾏﾄ　ﾅﾃﾞﾋｺ', 'CSV row content' );

$csv_in->close;
# NOTE: headers => 'skip'
$all = $csv_in->load_csv( headers => 'skip' ) || BAIL_OUT( $csv_in->error );
is( scalar( @$all ), 3, 'count' );
is( ref( $all->[0] // '' ), 'ARRAY', 'returns array of array reference.' );

# NOTE: headers => 'discard'
$csv_in->close;
$all = $csv_in->load_csv(headers => 'discard') || BAIL_OUT($csv_in->error);
is( scalar( @$all ), 3, 'count' );
is( ref( $all->[0] // '' ), 'ARRAY', 'returns array of array reference' );

$csv_in->close;
# NOTE: headers => 'uc'
$all = $csv_in->load_csv( headers => 'uc' ) || BAIL_OUT( $csv_in->error );
my $headers = [sort( keys( %{$all->[0]} ) )];
is_deeply( $headers => [qw( BALANCE CREDIT DATE DEBIT NARRATION TYPE )], 'uppercase headers' );

$csv_in->close;
# NOTE: headers => 'uc'
$all = $csv_in->load_csv( headers => 'lc' ) || BAIL_OUT( $csv_in->error );
$headers = [sort( keys( %{$all->[0]} ) )];
is_deeply( $headers => [qw( balance credit date debit narration type )], 'lowercase headers' );

# date,type,narration,debit,credit,balance
my $switch_headers = sub
{
    my $row = shift( @_ );
    # We just upper case one every other header
    for( my $i = 0; $i < scalar( @$row ); $i++ )
    {
        $row->[$i] = uc( $row->[$i] ) if( $i % 2 );
    }
    return( $row );
};

$csv_in->close;
# NOTE: headers => 'callback'
$all = $csv_in->load_csv(
    headers => $switch_headers,
) || BAIL_OUT( $csv_in->error );
$headers = [sort{ lc( $a ) cmp lc( $b ) } keys( %{$all->[0]} )];
is_deeply( $headers => [qw( BALANCE credit date DEBIT narration TYPE )], 'headers modified by callback' );

# NOTE: headers as a hash map
$csv_in->close;
$all = $csv_in->load_csv( headers => {date => 'trans_date', type => 'trans_type'} ) || BAIL_OUT( $csv_in->error );
is_deeply( [sort( keys( %{$all->[0]} ) )], [qw(balance credit debit narration trans_date trans_type)], 'mapped headers from hash' );

# NOTE: headers as an array
# date,type,narration,debit,credit,balance
$csv_in->close;
$all = $csv_in->load_csv( headers => [qw( trans_date trans_type desc debit credit total_balance )] ) || BAIL_OUT( $csv_in->error );
is_deeply( [sort( keys( %{$all->[0]} ) )], [qw( credit debit desc total_balance trans_date trans_type)], 'mapped headers from array' );

# NOTE: Custom column order
$csv_in->close;
{
    no warnings 'Module::Generic';
    $all = $csv_in->load_csv( columns => ['date', 'balance', 'debit'] ) || BAIL_OUT( $csv_in->error );
    is_deeply( [sort( keys( %{$all->[0]} ) )], [qw(balance date debit)], 'selected column order' );
}

# NOTE: Missing columns handled
$csv_in->close;
{
    no warnings 'Module::Generic';
    $all = $csv_in->load_csv( columns => ['missing_col', 'balance'] ) || BAIL_OUT( $csv_in->error );
    is_deeply( [sort( keys( %{$all->[0]} ) )], [qw(balance missing_col)], 'handles missing columns correctly' );
}

# NOTE: load_csv with callback
$csv_in->close;
my $result = [];
$csv_in->load_csv(
    headers => 'auto',
    callback => sub
    {
        my $row = shift( @_ );
        push( @$result, $row );
    },
) || BAIL_OUT( $csv_in->error );
is( scalar( @$result ), 3, 'count' );
is_deeply( [sort( keys( %{$result->[0]} ) )], [qw( balance credit date debit narration type )], 'load_csv with callback' );


$csv_empty->unload_utf8( "date,type,narration\n2024-01-01,a,b\n\n2024-01-02,c,d" ) ||
    BAIL_OUT( $csv_empty->error );
my $rows = $csv_empty->load_csv( headers => 'auto' );
SKIP:
{
    if( !$rows )
    {
        fail( "Failed loading CSV file with empty line: " . $csv_empty->error );
        skip( "CSV file load failed", 1 );
    }
    is( $rows->length, 3, "Empty line included" );
    is_deeply( $rows->[1], { date => undef, type => undef, narration => undef }, "Empty line as empty hash" );
};

# NOTE: testing unload_csv
$csv_out->debug($DEBUG);

# Sample data to write
my $sample_data = [
    { date => '2024-02-08', type => '振込', narration => 'ﾔﾏﾄ　ﾅﾃﾞﾋｺ', debit => 0, credit => 3000, balance => '7,234,799' },
    { date => '2024-02-09', type => '振込', narration => 'ｽﾄﾗｲﾌﾟｼﾞｬﾊﾟﾝ(ｶ', debit => 0, credit => 9699, balance => '7,244,498' },
    { date => '2024-02-19', type => '利息', narration => '', debit => 0, credit => 17, balance => '7,244,515' },
];

# Unload data to CSV
$csv_out->unload_csv( $sample_data, headers => 'auto' ) || BAIL_OUT( $csv_out->error );

# Reload data from CSV
my $loaded_data = $csv_out->load_csv( headers => 'auto' ) || BAIL_OUT( $csv_out->error );

# Validate data consistency
is_deeply( $loaded_data, $sample_data, 'Loaded data matches original unloaded data' );

# NOTE: unload_csv with a callback
my $cnt = -1;
$csv_out->close;
$csv_out->remove if( $csv_out->exists );
$csv_out->unload_csv(sub
{
    # Will return undef when $cnt exceed the size of the array.
    return( $sample_data->[ ++$cnt ] );
}, headers => 'auto' ) || BAIL_OUT( $csv_out->error );
is( $cnt, 3, 'unload_csv with callback' );
$loaded_data = $csv_out->load_csv( headers => 'auto' ) || BAIL_OUT( $csv_out->error );
is_deeply( $loaded_data, $sample_data, 'Loaded data matches original unloaded data' );

foreach my $enc (qw( utf-16be utf-16le utf-32be utf-32le ))
{
    my $fname = "test_in_${enc}.csv";
    subtest "load_csv() with encoding ${enc}" => sub
    {
        SKIP:
        {
            my $f = $parent->child( $fname );
            # Soft fail
            if( !$f )
            {
                diag( "Error getting a file object for $f: ", $parent->error );
                fail( "Create file object for $fname: !" );
                skip( "Failed creating file object for $fname", 1 );
            }
            my $rows = $f->load_csv( headers => 'auto' );
            if( !$rows )
            {
                diag( "Error loading CSV: ", $f->error );
                fail( "load_csv( $fname ) returns array object" );
                skip( "Failed to get array object.", 1 );
            }
            is( $rows->length => 3, "Number of rows of data." );
            is( $rows->[0]->{narration}, 'ﾔﾏﾄ　ﾅﾃﾞﾋｺ', "CSV row content" );
        };
    };
}

done_testing();

__END__
