#########################

use Test;
BEGIN { plan tests => 30 };

use P2P::pDonkey::Meta ':all';
use Socket;

########################
# basic data
ok(unpackB(packB(1)) == 1);
ok(unpackW(packW(1)) == 1);
ok(unpackD(packD(1)) == 1);
#ok(unpackF(packF(1.1)) == 1.1);
ok(unpackS(packS('test')) eq 'test');
ok(unpackS(packS('0123456789abcdef0123456789abcdef')) eq '0123456789abcdef0123456789abcdef');
my $off;
ok(join(',',@{unpackSList(packSList(['first', 'second']), $off=0)})
   eq join(',',('first', 'second')));
ok(join(',',@{unpackHashList(packHashList(['0123456789abcdef0123456789abcdef', '0123456789abcdef0123456789abcdef']), $off=0)}) 
   eq join(',',('0123456789abcdef0123456789abcdef', '0123456789abcdef0123456789abcdef')));

ok(join(',',unpackAddr(packAddr(688132272,4661), $off=0)) eq join(',',(688132272,4661)));
ok(join(',',@{unpackAddrList(packAddrList([688132272,4661,688132271,4660]), $off=0)}) eq join(',',(688132272,4661,688132271,4660)));

########################
# meta tags
for my $v (makeMeta(TT_NAME,'My'),
           makeMeta(TT_TYPE, 'Video'),
           makeMeta(TT_DESCRIPTION, 'just desc'),
           makeMeta(TT_TEMPFILE, 'temp.file'),
           makeMeta(TT_FORMAT, 'avi')) {
    my $rv = unpackMeta(packMeta($v), $off=0);
    ok(sameMetaType($v, $rv) && $v->{Value} eq $rv->{Value});
}
for my $v (makeMeta(TT_SIZE, 1234),
           makeMeta(TT_COPIED, 1234),
           makeMeta(TT_GAPSTART, 1234, "12"),
           makeMeta(TT_GAPEND, 1234, "12"),
           makeMeta(TT_PING, 120),
           makeMeta(TT_FAIL, 1),
           makeMeta(TT_PREFERENCE, 1),
           makeMeta(TT_PORT, 1),
           makeMeta(TT_IP, 1),
           makeMeta(TT_VERSION, 1),
           makeMeta(TT_PRIORITY, 1),
           makeMeta(TT_STATUS, 1),
           makeMeta(TT_AVAILABILITY, 1)) {
    my $rv = unpackMeta(packMeta($v), $off=0);
    ok(sameMetaType($v, $rv) && $v->{Value} == $rv->{Value});
}

########################
# search query
my $v = {Type => ST_COMBINE, 
         Op => ST_AND,
         Q1 => {Type => ST_COMBINE,
                Op => ST_OR,
                Q1 => {Type => ST_NAME,
                       Value => 'This'},
                Q2 => {Type => ST_META,
                       MetaName => {Type => TT_TYPE, Name => MetaTagName(TT_TYPE)},
                       Value => 'Video'}},
         Q2 => {Type => ST_COMBINE,
                Op => ST_ANDNOT,
                Q1 => {Type => ST_MINMAX,
                       Compare => ST_MIN,
                       MetaName => {Type => TT_SIZE, Name => MetaTagName(TT_SIZE)},
                       Value => 123},
                Q2 => {Type => ST_MINMAX,
                       Compare => ST_MAX,
                       MetaName => {Type => TT_SIZE, Name => MetaTagName(TT_SIZE)},
                       Value => 321}}};
my $ok = 1;
my $sql = makeSQLExpr($v, \$ok, {Name => VT_STRING, Type => VT_STRING, Size => VT_INTEGER});
ok($ok && $sql eq "(Name LIKE 'This' OR Type LIKE 'Video') AND Size >= 123 AND NOT Size <= 321");
$ok = 1;
$sql = makeSQLExpr(unpackSearchQuery(packSearchQuery($v), $off=0), \$ok, {Name => VT_STRING, Type => VT_STRING, Size => VT_INTEGER});
ok($ok && $sql eq "(Name LIKE 'This' OR Type LIKE 'Video') AND Size >= 123 AND NOT Size <= 321");

########################
# file info
my $i = makeFileInfo('t/224.avi');
my $packed_i_1 = packFileInfo($i);
my $packed_i_2 = packFileInfo(unpackFileInfo($packed_i_1, $off=0), $off=0);
ok($packed_i_1 eq $packed_i_2);

