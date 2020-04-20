use strict;
use warnings;
use Test::More;

my $pkg;

BEGIN {
    $pkg = 'PICA::Data';
    use_ok $pkg, qw(:all);
}

require_ok $pkg;

my $record = {
    record => [
        [ '005A', '', '0', '1234-5678' ],
        [ '005A', '', '0', '1011-1213' ],
        [   '009Q', '', 'u', 'http://example.org/', 'x', 'A', 'z', 'B', 'z',
            'C'
        ],
        [ '021A', '', 'a', 'Title', 'd', 'Supplement' ],
        [   '031N', '',     'j', '1600', 'k', '1700',
            'j',    '1800', 'k', '1900', 'j', '2000'
        ],
        [ '045F', '01', 'a', '001' ],
        [ '045F', '02', 'a', '002' ],
        [ '045U', '', 'e', '003', 'e', '004' ],
        [ '045U', '', 'e', '005' ]
    ],
    _id => 1234
};

note('Check for specific (sub)field');

{
    my $match = pica_match( $record, '021A', value => 'found' );
    is( $match, 'found', 'found field' );
}

{
    my $match = pica_match( $record, '021Aa', value => 'found' );
    is( $match, 'found', 'found subfield' );
}

{
    my $match = pica_match( $record, '021Ax', value => 'found' );
    is( $match, undef, 'not found' );
}

note('Single field, no subfield repetition');

{
    my $match = pica_match( $record, '021A', join => '' );
    is( $match, 'TitleSupplement', 'match field' );
}

{
    my $match = pica_match( $record, '021Aa' );
    is( $match, 'Title', 'match subfield' );
}

{
    my $match = pica_match( $record, '021Aad' );
    is( $match, 'TitleSupplement', 'match subfields' );
}

{
    my $match = pica_match( $record, '021Ada' );
    is( $match, 'TitleSupplement', 'match subfields' );
}

{
    my $match = pica_match( $record, '021Ada', pluck => 1 );
    is( $match, 'SupplementTitle', 'match subfields pluck' );
}

{
    my $match = pica_match( $record, '021Ada', pluck => 1, join => ' ' );
    is( $match, 'Supplement Title', 'match subfields pluck join' );
}

{
    my $match = pica_match( $record, '021A', force_array => 1 );
    is_deeply( $match, ['TitleSupplement'], 'match field force_array' );
}

{
    my $match = pica_match( $record, '021Aa', force_array => 1 );
    is_deeply( $match, ['Title'], 'match subfield force_array' );
}

{
    my $match = pica_match( $record, '021A', split => 1 );
    is_deeply( $match, [ 'Title', 'Supplement' ], 'match field split' );
}

{
    my $match = pica_match( $record, '021A', force_array => 1, split => 1 );
    is_deeply(
        $match,
        [ [ 'Title', 'Supplement' ] ],
        'match field force_array split'
    );
}

{
    my $match = pica_match( $record, '021A', nested_arrays => 1 );
    is_deeply(
        $match,
        [ [ 'Title', 'Supplement' ] ],
        'match field split nested_arrays'
    );
}

{
    my $match = pica_match(
        $record, '021A',
        force_array   => 1,
        split         => 1,
        nested_arrays => 1
    );
    is_deeply(
        $match,
        [ [ [ 'Title', 'Supplement' ] ] ],
        'match field force_array split nested_arrays'
    );
}

note('Single field, repeated subfields');

{
    my $match = pica_match( $record, '009Q' );
    is( $match, 'http://example.org/ABC', 'match field' );
}

{
    my $match = pica_match( $record, '009Qz' );
    is( $match, 'BC', 'match subfield' );
}

{
    my $match = pica_match( $record, '009Q', force_array => 1 );
    is_deeply( $match, ['http://example.org/ABC'],
        'match field force_array' );
}

{
    my $match = pica_match( $record, '009Q', split => 1 );
    is_deeply(
        $match,
        [ 'http://example.org/', 'A', 'B', 'C' ],
        'match field split'
    );
}

{
    my $match = pica_match( $record, '009Qz', split => 1 );
    is_deeply( $match, [ 'B', 'C' ], 'match subfield split' );
}

{
    my $match = pica_match( $record, '009Qxz', split => 1 );
    is_deeply( $match, [ 'A', 'B', 'C' ], 'match subfields split' );
}

{
    my $match
        = pica_match( $record, '009Qz', split => 1, nested_arrays => 1 );
    is_deeply(
        $match,
        [ [ 'B', 'C' ] ],
        'match subfield split nested_arrays'
    );
}

{
    my $match = pica_match(
        $record, '009Qz',
        force_array   => 1,
        split         => 1,
        nested_arrays => 1
    );
    is_deeply(
        $match,
        [ [ [ 'B', 'C' ] ] ],
        'match subfield force_array split nested_arrays'
    );
}

note('Repeated Field, no subfield repetition');

{
    my $match = pica_match( $record, '005A' );
    is( $match, '1234-56781011-1213', 'match field' );
}

{
    my $match = pica_match( $record, '005A0' );
    is( $match, '1234-56781011-1213', 'match subfield' );
}

{
    my $match = pica_match( $record, '005A', force_array => 1 );
    is_deeply(
        $match,
        [ '1234-5678', '1011-1213' ],
        'match field force_array'
    );
}

{
    my $match = pica_match( $record, '005A', split => 1 );
    is_deeply( $match, [ '1234-5678', '1011-1213' ], 'match field split' );
}

{
    my $match = pica_match( $record, '005A0', split => 1 );
    is_deeply( $match, [ '1234-5678', '1011-1213' ], 'match subfield split' );
}

{
    my $match = pica_match( $record, '005A', force_array => 1, split => 1 );
    is_deeply(
        $match,
        [ [ '1234-5678', '1011-1213' ] ],
        'match field force_array split'
    );
}

{
    my $match = pica_match( $record, '005A', split => 1, nested_arrays => 1 );
    is_deeply(
        $match,
        [ ['1234-5678'], ['1011-1213'] ],
        'match field split nested_arrays'
    );
}

{
    my $match = pica_match(
        $record, '005A',
        force_array   => 1,
        split         => 1,
        nested_arrays => 1
    );
    is_deeply(
        $match,
        [ [ ['1234-5678'], ['1011-1213'] ] ],
        'match field force_array split nested_arrays'
    );
}

note('Repeated field with repeated subfields');

{
    my $match = pica_match( $record, '045U' );
    is( $match, '003004005', 'match field' );
}

{
    my $match = pica_match( $record, '045Ue' );
    is( $match, '003004005', 'match subfield' );
}

{
    my $match = pica_match( $record, '045U', force_array => 1 );
    is_deeply( $match, [ '003004', '005' ], 'match field force_array' );
}

{
    my $match = pica_match( $record, '045U', split => 1 );
    is_deeply( $match, [ '003', '004', '005' ], 'match field split' );
}

{
    my $match = pica_match( $record, '045Ue', split => 1 );
    is_deeply( $match, [ '003', '004', '005' ], 'match subfield split' );
}

{
    my $match = pica_match( $record, '045U', force_array => 1, split => 1 );
    is_deeply(
        $match,
        [ [ '003', '004', '005' ] ],
        'match field force_array split'
    );
}

{
    my $match = pica_match( $record, '045U', split => 1, nested_arrays => 1 );
    is_deeply(
        $match,
        [ [ '003', '004' ], ['005'] ],
        'match field split nested_arrays'
    );
}

{
    my $match = pica_match(
        $record, '045U',
        force_array   => 1,
        split         => 1,
        nested_arrays => 1
    );
    is_deeply(
        $match,
        [ [ [ '003', '004' ], ['005'] ] ],
        'match field force_array split nested_arrays'
    );
}

note('Repeated field with occurrence');

{
    my $match = pica_match( $record, '045F[01]' );
    is( $match, '001', 'match field occurence' );
}

{
    my $match = pica_match( $record, '045F[0.]', split => 1 );
    is_deeply( $match, [ '001', '002' ], 'match field occurence split' );
}

note('Referencing the whole record');

{
    my $match = pica_match( $record, '....' );
    is( $match,
        '1234-56781011-1213http://example.org/ABCTitleSupplement16001700180019002000001002003004005',
        'match field'
    );
}

{
    my $match = pica_match( $record, '....a' );
    is( $match, 'Title001002', 'match subfield' );
}

{
    my $match = pica_match( $record, '....', split => 1 );
    is_deeply(
        $match,
        [   "1234-5678",           "1011-1213",
            "http://example.org/", "A",
            "B",                   "C",
            "Title",               "Supplement",
            1600,                  1700,
            1800,                  1900,
            2000,                  "001",
            "002",                 "003",
            "004",                 "005"
        ],
        'match field split'
    );
}

{
    my $match = pica_match( $record, '....a', split => 1 );
    is_deeply( $match, [ "Title", "001", "002" ], 'match subfield split' );
}

{
    my $match = pica_match( $record, '.....', split => 1, nested_arrays => 1 );
    is_deeply(
        $match,
        [   ["1234-5678"],
            ["1011-1213"],
            [ "http://example.org/", "A", "B", "C", ],
            [ "Title",               "Supplement" ],
            [ 1600, 1700, 1800, 1900, 2000, ],
            ["001"],
            ["002"],
            [ "003", "004" ],
            ["005"]
        ],
        'match field split nested_arrays'
    );
}

{
    my $match = pica_match(
        $record, '....',
        force_array   => 1,
        split         => 1,
        nested_arrays => 1
    );
    is_deeply(
        $match,
        [   [   ["1234-5678"],
                ["1011-1213"],
                [ "http://example.org/", "A", "B", "C", ],
                [ "Title",               "Supplement" ],
                [ 1600, 1700, 1800, 1900, 2000, ],
                ["001"],
                ["002"],
                [ "003", "004" ],
                ["005"]
            ]
        ],
        'match field force_array split nested_arrays'
    );
}

{
    my $match
        = pica_match( $record, '....$a', split => 1, nested_arrays => 1 );
    is_deeply(
        $match,
        [ ["Title"], ["001"], ["002"] ],
        'match subfield split nested_arrays'
    );
}

note('Subtsring from field');

{
    my $match = pica_match( $record, '021A/0-' );
    is( $match, 'TitleSupplement', 'match field substring' );
}

{
    my $match = pica_match( $record, '021A/0-1' );
    is( $match, 'TiSu', 'match field substring' );
}

{
    my $match = pica_match( $record, '021Ada/0-1', pluck => 1 );
    is( $match, 'SuTi', 'match subfields substring pluck' );
}

{
    my $match = pica_match( $record, '021Ada/0-', pluck => 1, split => 1 );
    is_deeply(
        $match,
        [ 'Supplement', 'Title' ],
        'match substring subfields pluck split'
    );
}

note('Field not found');

{
    my $match = pica_match( $record, '999X' );
    is( $match, undef, 'no match found' );
}

{
    my $match = pica_match( $record, '999X', join => ' ' );
    is( $match, undef, 'no match found join' );
}

{
    my $match = pica_match( $record, '999X', split => 1 );
    is( $match, undef, 'no match found split' );
}

{
    my $match = pica_match( $record, '999X', nested_arrays => 1 );
    is( $match, undef, 'no match found nested_arrays' );
}

{
    my $match = pica_match( $record, '004A');
    isnt( $match, '', 'no match no return of empty field' );
}

{
    my $match = pica_match( $record, '004A', split => 1 );
    isnt( ref($match), ref([]), 'no match empty no return of array ref' );
}

done_testing();
