use strict;
use warnings;
use utf8;
use PICA::Data qw(pica_parser pica_writer pica_value);
use PICA::Parser::Plain;
use PICA::Parser::Plus;
use PICA::Parser::XML;
use Test::Exception;
use Test::More;
use Test::Warn;

foreach my $type (qw(Plain Plus XML Binary)) {
    my $module = "PICA::Parser::$type";
    my $file   = 't/files/pica.' . lc($type);

    note $module;
    my $parser = pica_parser( $type => $file );
    is ref($parser), "PICA::Parser::$type", "parser from file";

    my $record = $parser->next;
    isnt ref($record), 'PICA::Data', 'not blessed by default';

    ok $record->{_id} eq '12345', 'record _id';
    ok $record->{record}->[0][0] eq '002@', 'tag from first field';
    is_deeply $record->{record}->[1], [ '003@', '', 0 => '12345' ],
        'second field';
    is_deeply $record->{record}->[4],
        [ '012X', '', 0 => '0', x => '', y => '' ], 'empty subfields';
    is $record->{record}->[6]->[7], '柳经纬主编;', 'Unicode';
    is_deeply $record->{record}->[11],
        [ '145Z', '40', 'a', '$', 'b', 'test$', 'c', '...' ],
        'sub field with $';

    ok $parser->next()->{_id} eq '67890', 'next record';
    ok !$parser->next, 'parsed all records';

    foreach my $mode ( '<', '<:utf8' ) {
        next
            if ( $mode eq '<' and $type ne 'XML' )
            or ( $mode eq '<:utf8' and $type eq 'XML' );
        open( my $fh, $mode, $file );
        my $record = pica_parser( $type => $fh )->next;
        is_deeply pica_value( $record, '021A$h' ), '柳经纬主编;', 'read from handle';
    }

    my $data = do { local ( @ARGV, $/ ) = $file; <> };

    # read from string reference
    $parser = eval "PICA::Parser::$type->new(\\\$data, bless => 1 )";
    isa_ok $parser, "PICA::Parser::$type";
    $record = $parser->next;
    isa_ok $record, 'PICA::Data';
    is $record->{record}->[6]->[7], '柳经纬主编;', 'Unicode';

}

note 'PICA::Parser::PPXML';
{
    use PICA::Parser::PPXML;
    my $parser = PICA::Parser::PPXML->new('./t/files/ppxml.xml');
    is ref($parser), "PICA::Parser::PPXML", "parser from file";
    my $record = $parser->next;
    isnt ref($record), 'PICA::Data', 'not blessed by default';
    ok $record->{_id} eq '1027146724', 'record _id';
    ok $record->{record}->[0][0] eq '001@', 'tag from first field';
    is_deeply $record->{record}->[7], [ '003@', '', '0', '1027146724' ],
        'id field';
    ok $parser->next()->{_id} eq '988352591', 'next record';
    ok !$parser->next, 'parsed all records';
}

# TODO: dump.dat, bgb.example, sru_picaxml.xml
# test XML with BOM

my $xml
    = q{<record xmlns="info:srw/schema/5/picaXML-v1.0"><datafield tag="003@"><subfield code="0">1234€</subfield></datafield></record>};
my $record = pica_parser( xml => $xml )->next;
is_deeply $record->{record}, [ [ '003@', '', '0', '1234€' ] ],
    'xml from string';

note 'XML with namespace';
$xml = <<XML;
<p:record xmlns:p="info:srw/schema/5/picaXML-v1.0">
 <p:datafield p:tag="003@">
   <p:subfield p:code="0">1234€</p:subfield>
 </p:datafield>
</p:record>
XML

$record = pica_parser( xml => $xml )->next;
is_deeply $record->{record}, [ [ '003@', '', '0', '1234€' ] ],
    'xml with namespace';


note 'error handling';
{
    my $plus = "X01A \x{1F}01\x{1E}001A/0 \x{1F}01\x{1E}001A/AB \x{1F}01\x{1E}";
    warnings_exist {PICA::Parser::Plus->new( \$plus )->next} [qr{no valid PICA field structure},qr{no valid PICA field structure},qr{no valid PICA field structure}], 'skip faulty fields with warnings';
    dies_ok { PICA::Parser::Plus->new( \$plus, strict => 1 )->next } 'die on faulty fields with option strict';
    my $plain = "X01@ \$01\n\n001@/0 \$01\n\n001@/AB \$01";
    warnings_exist { PICA::Parser::Plain->new( \$plain )->next } [qr{no valid PICA field structure},qr{no valid PICA field structure},qr{no valid PICA field structure}], 'skip faulty fields with warnings';
    dies_ok { PICA::Parser::Plain->new( \$plain, strict => 1 )->next } 'die on faulty fields with option strict';

    dies_ok { pica_parser('doesnotexist') } 'unknown parser';
    dies_ok { pica_parser( xml => '' ) } 'invalid handle';
    dies_ok { pica_parser( plus => [] ) } 'invalid handle';
    dies_ok { pica_parser( plain => bless( {}, 'MyFooBar' ) ) } 'invalid handle';
}

note '3-digit occurrence';
{
    my $data = '00045     003@ 012345231@/102 d10j19660d11j1970';
    my $parser = PICA::Parser::Plus->new(\$data);
    my $record = $parser->next;
    is $record->{record}->[1]->[1], '102', '3-digit occurrence';
}

SKIP: {
    my $str
        = '003@ '
        . PICA::Parser::Plus::SUBFIELD_INDICATOR . '01234'
        . PICA::Parser::Plus::END_OF_FIELD . '021A '
        . PICA::Parser::Plus::SUBFIELD_INDICATOR
        . 'aHello $¥!'
        . PICA::Parser::Plus::END_OF_RECORD;

    skip "utf8 is driving me crazy", 1;

    # TODO: why UTF-8 encoded while PICA plain is not?
    # See https://travis-ci.org/gbv/PICA-Data/builds/35711139
    use Encode;
    $record = [
        [ '003@', '', '0', '1234' ],

        # ok in perl <= 5.16
        [ '021A', '', 'a', encode( 'UTF-8', "Hello \$\N{U+00A5}!" ) ]

        # ok in perl >= 5.18
        # [ '021A', '', 'a', 'Hello $¥!' ]
    ];

    open my $fh, '<', \$str;
    is_deeply pica_parser( plus => $fh )->next,
        {
        _id    => 1234,
        record => $record
        },
        'Plus format UTF-8 from string';
}

done_testing;
