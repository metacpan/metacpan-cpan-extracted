use strict;
use warnings;
use utf8;
use PICA::Data qw(pica_parser pica_writer pica_value);
use Test::Exception;
use Test::More;
use Test::Warn;

my $first = pica_parser(plain => 't/files/pica.plain')->next;
ok $first->{_id} eq '12345', 'record _id';
ok $first->{record}->[0][0] eq '002@', 'tag from first field';
is_deeply $first->{record}->[1], ['003@', '', 0 => '12345'], 'second field';
is_deeply $first->{record}->[4], ['012X', '', 0 => '0', x => '', y => ''],
    'empty subfields';
is $first->{record}->[6]->[7], '柳经纬主编;', 'Unicode';
is_deeply $first->{record}->[11],
    ['145Z', '40', 'a', '$', 'b', 'test$', 'c', '...'], 'sub field with $';

foreach my $type (qw(Plain Plus JSON Binary XML PPXML)) {
    my $module = "PICA::Parser::$type";
    my $file   = 't/files/pica.' . lc($type);

    note $module;
    my $parser = pica_parser($type => $file);
    is ref($parser), "PICA::Parser::$type", "parser from file";

    my $record = $parser->next;
    isnt ref($record), 'PICA::Data', 'not blessed by default';

    is_deeply $record, $first;

    ok $parser->next()->{_id} eq '67890', 'next record';
    ok !$parser->next, 'parsed all records';

    foreach my $mode ('<', '<:utf8') {
        next
            if ($mode eq '<' and $type ne 'XML')
            or ($mode eq '<:utf8' and $type eq 'XML');
        open(my $fh, $mode, $file);
        my $record = pica_parser($type => $fh)->next;
        is_deeply pica_value($record, '021A$h'), '柳经纬主编;',
            'read from handle';
    }

    # read file as Unicode text string
    my $data = do {
        open my $fh, "<:encoding(UTF-8)", $file;
        join '', <$fh>;
    };

    # read from string reference
    $record = pica_parser($type, \$data)->next;
    is $record->{record}[6][7], '柳经纬主编;',
        'Unicode from string reference';

}

# TODO: dump.dat, bgb.example, sru_picaxml.xml
# test XML with BOM

my $xml
    = q{<record xmlns="info:srw/schema/5/picaXML-v1.0"><datafield tag="003@"><subfield code="0">1234€</subfield></datafield></record>};
my $record = pica_parser(xml => $xml)->next;
is_deeply $record->{record}, [['003@', '', '0', '1234€']],
    'xml from string';

note 'XML with namespace';
$xml = <<XML;
<p:record xmlns:p="info:srw/schema/5/picaXML-v1.0">
 <p:datafield p:tag="003@">
   <p:subfield p:code="0">1234€</p:subfield>
 </p:datafield>
</p:record>
XML

$record = pica_parser(xml => $xml)->next;
is_deeply $record->{record}, [['003@', '', '0', '1234€']],
    'xml with namespace';

$record = pica_parser(plain => \"003@ ƒ0123\n123A/01 ƒx1ƒy\$2")->next;
is_deeply $record->{record},
    [['003@', '', '0', '123'], [qw(123A 01 x 1 y $2)]],
    'plain parser supports U+0192 as subfield indicator';
is $record->{_id}, '123', 'include PPN (#80)';

note 'error handling';
{
    my $plus
        = "X01A \x{1F}01\x{1E}001A/0 \x{1F}01\x{1E}001A/AB \x{1F}01\x{1E}";
    warnings_exist {PICA::Parser::Plus->new(\$plus)->next}[
        qr{no valid PICA field structure},
        qr{no valid PICA field structure},
        qr{no valid PICA field structure}
    ],
        'skip faulty fields with warnings';
    dies_ok {PICA::Parser::Plus->new(\$plus, strict => 1)->next}
    'die on faulty fields with option strict';
    my $plain = "X01@ \$01\n\n001@/0 \$01\n\n001@/AB \$01";
    warnings_exist {PICA::Parser::Plain->new(\$plain)->next}[
        qr{no valid PICA field structure},
        qr{no valid PICA field structure},
        qr{no valid PICA field structure}
    ],
        'skip faulty fields with warnings';
    dies_ok {PICA::Parser::Plain->new(\$plain, strict => 1)->next}
    'die on faulty fields with option strict';

    dies_ok {pica_parser('doesnotexist')} 'unknown parser';
    dies_ok {pica_parser(xml => '')} 'invalid handle';
    dies_ok {pica_parser(plus => [])} 'invalid handle';
    dies_ok {pica_parser(plain => bless({}, 'MyFooBar'))} 'invalid handle';
}

note '3-digit occurrence';
{
    my $data   = '00045     003@ 012345231@/102 d10j19660d11j1970';
    my $parser = PICA::Parser::Plus->new(\$data);
    my $record = $parser->next;
    is $record->{record}->[1]->[1], '102', '3-digit occurrence';
}

done_testing;
