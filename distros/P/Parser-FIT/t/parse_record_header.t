use Test::More;
use Parser::FIT;

my $fit = Parser::FIT->new();


subtest "is normal record header" => sub {
    my $normalRecordHeader = $fit->_parse_record_header(127);
    ok($normalRecordHeader->{isNormalHeader}, "this is a normal record header");

    my $notNormalRecordHeader = $fit->_parse_record_header(255);
    ok(!$notNormalRecordHeader->{isNormalHeader}, "this is not a normal record header");

    my $realHeader = $fit->_parse_record_header(79);
    ok($realHeader->{isNormalHeader}, "is a normal header");
    ok($realHeader->{isDefinitionMessage}, "is a definition message");
    is(15, $realHeader->{localMessageType}, "defines local message type 15");
};

subtest "is definition message" => sub {
    # all bits 1
    ok($fit->_parse_record_header(255)->{isDefinitionMessage}, "255 indicates a definition message");

    # only def msg bit 1
    ok($fit->_parse_record_header(64)->{isDefinitionMessage}, "64 indicates a definition message");

    # all bits 0
    ok(!$fit->_parse_record_header(0)->{isDefinitionMessage}, "0 does not indicate a definition message");

    # only bit 6 == 0
    ok(!$fit->_parse_record_header(191)->{isDefinitionMessage}, "191 does not indicate a definition message");
};

subtest "is developer data flag message" => sub {
    # all bits 1
    ok($fit->_parse_record_header(255)->{isDeveloperData}, "255 does indicate developer data");

    # only def msg bit 1
    ok($fit->_parse_record_header(32)->{isDeveloperData}, "32 does indicate developer data");

    # all bits 0
    ok(!$fit->_parse_record_header(0)->{isDeveloperData}, "0 does not indicate developer data");

    # only bit 6 == 0
    ok(!$fit->_parse_record_header(223)->{isDeveloperData}, "232 does not indicate developer data");
};

subtest "localMessageType" => sub {
    # all bits 1
    is($fit->_parse_record_header(255)->{localMessageType}, 15, "Right localMessageType");

    # only first bit 1
    is($fit->_parse_record_header(1)->{localMessageType}, 1, "Right localMessageType");

    # all bits 0
    is($fit->_parse_record_header(0)->{localMessageType}, 0, "Right localMessageType");

    # bit 4 and 2
    is($fit->_parse_record_header(10)->{localMessageType}, 10, "Right localMessageType");
};


done_testing;