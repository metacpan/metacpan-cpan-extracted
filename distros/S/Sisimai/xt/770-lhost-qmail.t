use strict;
use warnings;
use Test::More;
use lib qw(./lib ./blib/lib);
require './t/600-lhost-code';

my $enginename = 'qmail';
my $samplepath = sprintf("./set-of-emails/private/lhost-%s", lc $enginename);
my $enginetest = Sisimai::Lhost::Code->makeinquiry;
my $isexpected = {
    # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
    '1001'  => [['5.0.910', '',    'filtered',        0]],
    '1002'  => [['5.0.900', '',    'undefined',       0]],
    '1003'  => [['5.0.912', '550', 'hostunknown',     1]],
    '1004'  => [['5.1.1',   '',    'userunknown',     1]],
    '1005'  => [['5.0.912', '550', 'hostunknown',     1]],
    '1006'  => [['5.1.1',   '',    'userunknown',     1]],
    '1007'  => [['5.0.912', '550', 'hostunknown',     1]],
    '1008'  => [['5.1.1',   '',    'userunknown',     1]],
    '1009'  => [['5.1.1',   '',    'userunknown',     1]],
    '1010'  => [['5.0.912', '550', 'hostunknown',     1]],
    '1011'  => [['5.0.912', '550', 'hostunknown',     1]],
    '1012'  => [['5.0.911', '',    'userunknown',     1]],
    '1013'  => [['5.1.1',   '',    'userunknown',     1]],
    '1014'  => [['5.0.975', '550', 'badreputation',   0]],
    '1015'  => [['5.7.1',   '550', 'rejected',        0]],
    '1016'  => [['5.1.2',   '',    'hostunknown',     1]],
    '1017'  => [['5.1.1',   '550', 'userunknown',     1]],
    '1018'  => [['5.1.1',   '',    'userunknown',     1]],
    '1019'  => [['5.0.922', '',    'mailboxfull',     0]],
    '1020'  => [['5.0.910', '554', 'filtered',        0]],
    '1021'  => [['5.1.1',   '',    'userunknown',     1]],
    '1022'  => [['5.1.1',   '550', 'userunknown',     1]],
    '1023'  => [['5.0.911', '550', 'userunknown',     1]],
    '1024'  => [['5.0.911', '550', 'userunknown',     1]],
    '1025'  => [['5.1.1',   '550', 'userunknown',     1],
                ['5.2.1',   '550', 'userunknown',     1]],
    '1026'  => [['5.0.934', '552', 'mesgtoobig',      0]],
    '1027'  => [['5.2.2',   '550', 'mailboxfull',     0]],
    '1028'  => [['5.1.1',   '550', 'userunknown',     1]],
    '1029'  => [['5.0.911', '550', 'userunknown',     1]],
    '1030'  => [['5.1.1',   '550', 'userunknown',     1]],
    '1031'  => [['5.0.911', '550', 'userunknown',     1]],
    '1032'  => [['4.4.1',   '',    'networkerror',    0]],
    '1033'  => [['5.0.922', '',    'mailboxfull',     0]],
    '1034'  => [['4.2.2',   '450', 'mailboxfull',     0]],
    '1035'  => [['5.0.922', '552', 'mailboxfull',     0]],
    '1036'  => [['5.1.1',   '',    'userunknown',     1]],
    '1037'  => [['5.1.2',   '',    'hostunknown',     1]],
    '1038'  => [['5.0.911', '550', 'userunknown',     1]],
    '1039'  => [['5.0.922', '',    'mailboxfull',     0]],
    '1040'  => [['5.1.1',   '',    'mailboxfull',     0]],
    '1041'  => [['5.5.0',   '550', 'userunknown',     1]],
    '1042'  => [['5.1.1',   '550', 'userunknown',     1],
                ['5.2.1',   '550', 'userunknown',     1]],
    '1043'  => [['5.7.1',   '550', 'rejected',        0]],
    '1044'  => [['5.0.0',   '501', 'blocked',         0]],
    '1045'  => [['4.4.3',   '',    'systemerror',     0]],
    '1046'  => [['4.2.2',   '450', 'mailboxfull',     0]],
    '1047'  => [['5.5.0',   '550', 'userunknown',     1]],
    '1048'  => [['5.2.2',   '',    'mailboxfull',     0]],
    '1049'  => [['5.2.2',   '',    'mailboxfull',     0]],
    '1050'  => [['5.1.1',   '',    'userunknown',     1]],
    '1051'  => [['5.0.900', '',    'undefined',       0]],
    '1052'  => [['5.0.921', '554', 'suspend',         0]],
    '1053'  => [['5.0.910', '554', 'filtered',        0]],
    '1054'  => [['5.0.911', '550', 'userunknown',     1]],
    '1055'  => [['5.0.922', '',    'mailboxfull',     0]],
    '1056'  => [['5.1.1',   '',    'userunknown',     1]],
    '1057'  => [['5.0.911', '550', 'userunknown',     1]],
    '1058'  => [['5.1.1',   '550', 'userunknown',     1]],
    '1059'  => [['5.0.911', '',    'userunknown',     1]],
    '1060'  => [['5.0.921', '',    'suspend',         0]],
    '1061'  => [['5.0.910', '554', 'filtered',        0]],
    '1062'  => [['5.0.910', '554', 'filtered',        0]],
    '1063'  => [['5.1.1',   '',    'userunknown',     1]],
    '1064'  => [['5.1.1',   '',    'userunknown',     1]],
    '1065'  => [['5.0.922', '',    'mailboxfull',     0]],
    '1066'  => [['5.1.1',   '',    'userunknown',     1]],
    '1067'  => [['5.1.0',   '550', 'userunknown',     1]],
    '1068'  => [['5.0.911', '550', 'userunknown',     1]],
    '1069'  => [['5.0.910', '',    'filtered',        0]],
    '1070'  => [['5.0.912', '',    'hostunknown',     1],
                ['5.0.912', '',    'hostunknown',     1]],
    '1071'  => [['5.7.1',   '554', 'norelaying',      0]],
    '1072'  => [['5.0.912', '',    'hostunknown',     1]],
    '1073'  => [['5.0.921', '',    'suspend',         0]],
};

plan 'skip_all', sprintf("%s not found", $samplepath) unless -d $samplepath;
$enginetest->($enginename, $isexpected, 1, 0);
done_testing;

