use strict;
use warnings;
use utf8;

package Net::IANA::Services;
$Net::IANA::Services::VERSION = '0.004000';
BEGIN {
  $Net::IANA::Services::AUTHORITY = 'cpan:LESPEA';
}

#ABSTRACT:  Makes working with named ip services easier


#  Import needed modules
use YAML::Any qw/ LoadFile /;
use File::ShareDir qw/ dist_file /;


#  Export our vars/subs
use Exporter::Easy (
    TAGS => [
        hashes => [qw(
            $IANA_HASH_INFO_FOR_SERVICE
            $IANA_HASH_PORTS_FOR_SERVICE
            $IANA_HASH_SERVICES_FOR_PORT
            $IANA_HASH_SERVICES_FOR_PORT_PROTO
        )],

        regexes => [qw(
            $IANA_REGEX_PORTS
            $IANA_REGEX_PORTS_DCCP
            $IANA_REGEX_PORTS_SCTP
            $IANA_REGEX_PORTS_TCP
            $IANA_REGEX_PORTS_UDP
            $IANA_REGEX_SERVICES
            $IANA_REGEX_SERVICES_DCCP
            $IANA_REGEX_SERVICES_SCTP
            $IANA_REGEX_SERVICES_TCP
            $IANA_REGEX_SERVICES_UDP
        )],

        subs => [qw(
            iana_has_port
            iana_has_service
            iana_info_for_port
            iana_info_for_service
        )],

        all => [qw/ :hashes  :regexes  :subs /],
    ],
    VARS => 1,
);


#  Constants
my $_HASHES_REF = LoadFile dist_file q{Net-IANA-Services}, q{services_hashes_dump.yml};






#####################
#  Regex constants  #
#####################



our $IANA_REGEX_PORTS = qr{\b(?<!-)(?:1(?:1(?:1(?:[234589]|0[345689]?|6[12345]?|7[12345]?|1[012]?)?|3(?:[034589]|2[01]?|19?|67?|71?)?|7(?:[0134678]|2[03]?|51?|96?)?|2(?:[23456789]|0[128]?|1?1)?|9(?:[01234578]|9[789]?|67?)?|0(?:[1234678]|0[01]?|9?5)?|6(?:[13456789]|0?0|23?)?|8(?:[012345689]|7[67]?)?|4(?:[01245679]|30?|89?)|5\d?)?|0(?:1(?:0[012347]?|1[0134567]|6[012]|2[89])?|0(?:0[012345789]?|5[015]|8[01]|10|23)|8(?:[234579]|0[059]?|10?|60?|80?)?|5(?:[12356789]|4[01234]?|0?0)?|2(?:[1279]|0[01]|52?|60?|88)?|4(?:[012456789]|39?)?|6(?:[012456789]|31?)?|9(?:[012345678]|90?)?|3(?:[3456789]|21)?|7\d?)|9(?:0(?:[13456789]|0[07]?|20?)?|5(?:[01256789]|4[01]?|39?)?|4(?:[023456789]|1[012]?)?|1(?:[012345678]|9[14]?)?|3(?:[02345678]|15?|98?)?|9(?:[012345678]|9[89]?)?|2(?:[012345679]|83?)?|7(?:[012345679]|8?8)?|6\d?|8\d?)?|8(?:1(?:[1245679]|8[1234567]?|04?|36?)?|2(?:[01235789]|4[123]?|62?)?|6(?:[012456789]|3[45]?)?|8(?:[012345679]|8[18]?)?|0(?:[123456789]|0?0)?|4(?:[012345789]|63?)?|7(?:[012345789]|69?)?|9[012346789]?|3\d?|5\d?)?|3(?:8(?:[0345678]|2[0123]?|1[89]?|94?)?|7(?:[01345679]|2[0124]?|8[2356]?)?|2(?:[03456789]|1[678]?|2[34]?)?|9(?:[01456789]|29?|30?)?|1(?:[012345789]|60?)?|4(?:[123456789]|0?0)?|0\d?|3\d?|5\d?|6\d?)?|5(?:0(?:[123456789]|0[02]?)?|3(?:[01235789]|45?|63?)?|9(?:[012345678]|9[89]?)?|1(?:[023456789]|18?)?|5(?:[012346789]|5?5)?|6(?:[012345789]|60?)?|7(?:[012356789]|40?)?|2[012345679]?|4\d?|8\d?)|6(?:3(?:[234579]|6[0178]?|1[01]?|09?|84?)?|9(?:[1234678]|9[12345]?|0?0|50?)?|0(?:[13456789]|0[0123]?|2[01]?)?|1(?:[012345789]|6[12]?)?|6(?:[02345789]|19?|6?6)?|2\d?|4\d?|5\d?|7\d?|8\d?)|7(?:2(?:[0456789]|2[012]?|3[45]?|19?)?|7(?:[0134689]|5[456]?|29?|7?7)?|1(?:[012345679]|8[45]?)?|5(?:[12346789]|0?0|5?5)?|0(?:[123456789]|07?)?|8[012456789]?|3\d?|4\d?|6\d?|9\d?)?|2(?:3(?:[1356789]|0[02]?|2[12]?|45?)?|1(?:[134589]|09?|21?|68?|72?)?|0(?:[23456789]|1[023]?|0\d?)?|7(?:[012346789]|53?)?|8(?:[012345789]|65?)?|2\d?|4\d?|5\d?|6\d?|9\d?)|4(?:1(?:[01236789]|4[1259]?|5[04]?)?|0(?:[12456789]|0[012]?|3[34]?)?|9(?:[02456789]|3[67]?)?|2(?:[012346789]|50?)?|4(?:[023456789]|14?)?|3\d?|5\d?|6\d?|7\d?|8\d?))?|2(?:4(?:0(?:[123456789]|0[0123456]?)|6(?:[01234569]|7[678]?|80?)?|3(?:[01345679]|2[12]?|86?)?|2(?:[01235789]|4[29]?)?|4(?:[012345789]|65?)?|5(?:[012346789]|54?)?|7(?:[012346789]|54?)?|8(?:[012346789]|50?)?|9(?:[013456789]|2?2)|1\d)|2(?:3(?:[1236789]|4[37]?|5[01]?|05?)?|0(?:[123456789]|0[012345]?)?|1(?:[013456789]|2[58]?)?|2(?:[01345689]|2?2|73?)?|5(?:[0124678]|37?|5?5)|7(?:[012345789]|63?)|8(?:[123456789]|0?0)|9(?:[012346789]|51?)|4\d?|6\d)?|0(?:0(?:[256789]|0[01235]?|1[234]?|4[689]?|34?)?|2(?:[13456789]|02?|2?2)?|1(?:[012345789]|67?)?|4(?:[012345679]|80?)?|6(?:[012345689]|70?)?|9(?:[012345678]|9?9)?|3\d?|5\d?|7\d?|8\d?)?|3(?:0(?:[12346789]|0[012345]?|53?)|4(?:[12346789]|0[012]?|5[67]?)|2(?:[012345689]|72?)|3(?:[012456789]|3?3)|5(?:[012356789]|46?)|6[012345678]|8[123456789]|7[0123456]|1\d|9\d)?|5(?:9(?:[12346789]|0[0123]?|5[45]?)?|0(?:[123456789]|0\d?)|6(?:[123456789]|04?)?|7(?:[012345678]|93?)?|4(?:[012345689]|71?)|5(?:[012345689]|76?)|1\d|2\d|3\d|8\d)?|6(?:2(?:[12345789]|6[0123]?|08?)?|4(?:[012345679]|8[679]?)?|0(?:[123456789]|0?0)?|1(?:[012456789]|3?3)?|8[013456789]?|9[012456789]?|3\d?|5\d?|6\d?|7\d?)|7(?:3(?:[012356789]|45?)|4(?:[012356789]|42?)|5(?:[123456789]|04?)|7(?:[012345679]|82?)|8(?:[012345689]|76?)|9(?:[01235678]|9?9)|0\d?|1\d?|2\d|6\d)?|1(?:8(?:[12356789]|4[56789]?|0?0)?|5(?:[01234678]|5[34]?|90?)?|0(?:[23456789]|0?0|10?)?|9[0123789]?|1\d?|2\d?|3\d?|4\d?|6\d?|7\d?)?|8(?:0(?:[123456789]|0[01]?)?|2(?:[1236789]|0?0|40?)?|1(?:[023456789]|19?)?|7[012456789]?|3\d?|4\d?|6\d?|5\d|8\d|9\d)|9(?:1(?:[02345789]|6[789]?|18?)|9(?:[012345678]|9?9)|2[012346789]|0\d|3\d|4\d|5\d|6\d|7\d|8\d)?)?|3(?:2(?:7(?:[01234589]|7[01234567]?|6[789]?)|8(?:[2345678]|01?|1?1|96?)|6(?:[012456789]|3[56]?)|0(?:[012456789]|34?)?|2(?:[012356789]|49?)?|4(?:[012345679]|83?)?|1\d?|3\d?|5\d|9\d)|1(?:4(?:[2346789]|0?0|16?|57?)?|0(?:[013456789]|2[09]?)?|6(?:[01345679]|20?|85?)?|9(?:[012356789]|4[89]?)?|7(?:[012345789]|65?)?|2[012345789]?|1\d?|3\d?|5\d?|8\d?)?|6(?:4(?:[0356789]|4[34]?|12?|2?2)?|0(?:[123456789]|01?)?|5(?:[013456789]|24?)?|6(?:[123456789]|02?)?|8(?:[012345789]|65?)?|9[01256789]?|1\d?|2\d?|3\d?|7\d?)|3(?:3(?:[012456789]|3[134]?)?|1(?:[013456789]|23?)|4(?:[012456789]|34?)|6(?:[012346]|56?)|0[23456789]|7[23456789]|2[016789]|5\d|8\d|9\d)?|4(?:9(?:[01234579]|6[234]?|80?)?|3(?:[012345689]|7[89]?)|5(?:[012345789]|67?)?|2(?:[012356789]|49?)|0[01256789]|4\d?|6\d?|7\d?|8\d?|1\d)|0(?:0(?:[123456789]|0[01234]?)|8(?:[012456789]|32?)?|2(?:[012345789]|60?)|9(?:[01345678]|9?9)?|1\d|3\d|4\d|5\d|6\d|7\d)|5(?:0(?:[123456789]|0[0123456]?)?|3(?:[012346789]|5[4567]?)?|4[012345789]?|1\d?|2\d?|5\d?|6\d?|7\d?|8\d?|9\d?)|8(?:2(?:[123456789]|0[123]?)?|8(?:[12345789]|0?0|65?)?|0\d?|1\d?|3\d?|4\d?|5\d?|6\d?|7\d?|9\d?)?|7(?:4(?:[01234569]|75?|83?)?|6(?:[01234789]|54?)?|0\d?|1\d?|2\d?|3\d?|5\d?|7\d?|8\d?|9\d?)?|9(?:6(?:[012345679]|81?)?|9[012356789]?|0\d?|1\d?|2\d?|3\d?|4\d?|5\d?|7\d?|8\d?)?)?|4(?:3(?:4(?:[01256789]|4[01]?|39?)?|1(?:[012346]|8[89]|9[01])?|0(?:[123456789]|0?0)?|2(?:[023456789]|10?)?|9[0123456]?|6[01289]?|3[013]?|5\d?|7\d?|89?)?|4(?:5(?:[0123678]|4?4|53?)?|4(?:[12356789]|4?4)?|3(?:[013]|2[123]?)?|8(?:[4567]|1?8)?|1(?:[01]|23)?|2[56789]?|6(?:00)?|9(?:00)?|0\d?|7)?|8(?:0(?:[123]|0[012345]?|49?|50)?|6(?:[78]|1?9|53)?|5(?:[01]|56)?|1(?:2[89])?|7[016789]?|8[012345]?|3[789]?|9[49]?|4\d?|27?)?|7(?:[79]|8(?:[456789]|0[689])?|0(?:[1234]|0[01]?)?|5(?:[0123]|57)?|4[01234579]?|3[0123789]?|2[56789]?|1(?:00)?|6(?:24)?)?|1(?:7(?:[012345678]|9[4567]?)?|1(?:[03456789]|1?1|21?)?|2[123456789]?|4[012356789]?|9[01239]?|0\d?|3\d?|5\d?|6\d?|8\d?)?|0(?:8(?:[01236789]|4[123]?|53?)?|0(?:[123456789]|0?0)?|4(?:[12345679]|04?)?|1\d?|2\d?|3\d?|5\d?|6\d?|7\d?|9\d?)|5(?:[12]|9(?:[012345789]|6?6)?|0(?:0[01]?|45|54|2)?|6(?:[3689]|78?)?|8(?:2[45])?|3[45678]?|4[56789]?|5\d?|70?)?|9(?:0(?:[12]|0?0)?|8[456789]?|1[2345]?|4[0129]?|5[0123]?|9[019]?|37?|69?|70?|2)?|6(?:[1234]|9(?:[012]|9[89])?|0[01234]?|5[89]?|6\d?|7\d?|8\d?)?|2(?:[012346789]|5(?:0[89]|10)?)?)|5(?:0(?:4[23456789]?|7[0123459]?|8[0123456]?|1[012345]?|9[012349]?|3[012]?|0\d?|2\d?|5\d?|6\d?)?|1(?:5[01234567]?|6[12345678]?|9[0123456]?|0[012345]?|1[124567]?|3[34567]?|4[56]?|20?|72?|8)|2(?:2[12345678]?|3[234567]?|0[01239]?|4[56789]?|5[0123]?|6[459]?|7[012]?|8[012]?|9[89]?|1)?|7(?:4[12345678]?|8[01234567]?|1[3456789]?|6[6789]?|5[057]?|7[017]?|9[34]?|2\d?|30?|0)|5(?:[1234]|0[0123456]?|8[012345]?|5[34567]?|6[6789]?|7[3459]?|9[789]?)?|3(?:[378]|1[02345678]?|6[01234]?|4[349]?|9[789]?|2[01]?|0\d?|5\d?)?|6(?:[56]|8[0123489]?|0[012345]?|2[789]?|9[36]?|3\d?|7\d?|18?|46?)?|4(?:[789]|3[01234567]?|6[12345]?|5[3456]?|4[35]?|0\d?|1\d?|2\d?)?|9(?:[23457]|8[456789]?|1[0123]?|9[0129]?|6[389]?|0?0)|8(?:[0237]|1[34]?|6[38]?|42?|5?9|83?)?)?|6(?:6(?:2[012345678]?|6(?:5-6669)?|7[012389]?|5[3567]?|0[012]?|3[234]?|8[789]?|9[67]?|19?|40?)?|3(?:2[012456]?|4[3467]?|0[016]?|1[567]?|5[05]?|6[03]?|8[29]?|70?|90?|3)?|5(?:[23]|0[012356789]?|1[01345]?|4[34789]?|8[0123]?|5[018]?|6[68]?|79?)?|0(?:[12345]|0(?:0-6063)?|7[01234567]?|8[12345678]?|6[45689]?|9?9)|7(?:[2345]|0[123456]?|8[456789]?|7[0178]?|6[789]?|1[45]?|9[01]?)?|1(?:[789]|1[012345678]?|2[1234]?|6[0123]?|3[03]?|0\d?|4\d?|59?)?|4(?:[069]|4[3456]?|1[789]?|2[01]?|5[56]?|8\d?|32?|71?)?|9(?:[1278]|6[1234569]?|9[789]?|3[56]?|01?|46?|51?)?|2(?:[13789]|4[1234]?|5[123]?|6[789]?|0[01]?|2?2)?|8(?:[279]|4[12]?|01?|17?|31?|50?|68?|8?8)?)|7(?:7(?:[156]|2[04567]?|4[12347]?|0[078]?|7[789]?|8[1679]|9[4789]|3[48]?)|0(?:[56]|1[01234589]?|2[012345]?|7[013]?|9[59]?|3[01]|0\d?|40?|80)?|5(?:[239]|4[23456789]?|0[0189]?|6[0369]|1[01]?|[57]0|8?8)|1(?:[345]|6[123456789]?|7[01234]|0[017]?|2[189]?|8?1)?|4(?:2[16789]?|7[134]?|0[012]|1[01]?|3[017]|43?|91?|8)?|6(?:[015]|7[234567]?|2[46789]?|3[013]?|8[09]|48?|97?)?|2(?:7[23456789]|8[0123]|2[789]|3[567]|0[01]|62|9)?|9(?:0[0123]|8[012]|9[789]|3[23]|6[27]|13|79)?|8(?:0[012]?|7[0128]|4[567]|8[07]|10|69)?|3(?:[01]|9[123457]|65)?)?|8(?:0(?:5[123456789]|0[012358]?|8[0123678]|2[01256]|4[0234]|3[234]|6[06]|9[17]|19?|74)?|1(?:9[12459]|0[012]?|1[5678]|2[1289]|8[1234]|3[012]|6[012]|4[89]|53)|4(?:0[012345]|7[01234]?|4[2345]|1[567]|5[07]|8)?|6(?:1[012345]?|0[09]?|6[56]|8[68]|75|99|2)?|3(?:7[6789]|0[01]?|2[01]?|8[03]|13?|51|3)?|7(?:6[3456]|3[23]?|7[08]|8[67]|11|50|93)|9(?:1[0123]|9[0189]|0[01]|5[34]|37|89)?|2(?:0[01245678]|9[234]?|80?|30|43|76)?|8(?:8[01389]?|9[012349]|0[04]|73?|6)?|5(?:0[012]|5[45]|67)?)|9(?:0(?:8[023456789]|2[0123456]?|0[012789]?|9[0123]|5[01]|10?|3)?|9(?:5[0123456]?|0[01239]?|8[78]?|9\d?|1?1|25?|6?6|78?|3)?|2(?:1[01234567]|8[01234567]|9[2345]|7[789]|0\d|22|55)?|6(?:1[24678]|3[012]|6[678]|2[89]|9[45]|[04]0)?|1(?:0[01234567]?|6[01234]|2[23]?|19?|31?|91)?|3(?:8[0789]|4[346]|9[067]|0[06]|1[28]|21|74)?|5(?:9[23456789]|3[56]|00|22|55)?|8(?:0[012]|7[568]|9[89]?|8[89])?|4(?:0[012]|4[345]|18|50)?|7(?:5[03]|00|47|62)?)?)\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_SERVICES = qr{\b(?<![-])(?:s(?:e(?:[pt]|r(?:v(?:e(?:r(?:view(?:-(?:asn?|icc|gf|rm)|dbms)|-find|graph|start|wsd2)|xec)|i(?:ce(?:-ctrl|meter|tags)|staitsm)|s(?:erv|tat))|comm-(?:scadmin|wlink)|ialgateway|aph)|c(?:-(?:t4net-(?:clt|srv)|pc2fax-srv|ntb-clnt)|ur(?:e-(?:cfg-svr|mqtt|ts)|itychase)|layer-t(?:cp|ls)|rmmsafecopya)|n(?:t(?:inel(?:-(?:ent|lm)|srm)?|lm-srv2srv|-lm)|omix0[12345678]|ip|d)|a(?:gull(?:-ai|lm)s|rch(?:-agent)?|odbc|view)|ma(?:phore|ntix)|ispoc|si-lm)|u(?:[am]|n(?:-(?:s(?:r-(?:iiop(?:-aut|s)?|https?|jm[sx]|admin)|ea-port)|as-(?:j(?:mxrmi|pda)|iiops(?:-ca)?|nodeagt)|user-https|mc-grp|dr|lm)|c(?:acao-(?:(?:jmx|sn)mp|websvc|csa|rmi)|luster(?:geo|mgr))|scalar-(?:dns|svc)|proxyadmin|webadmins?|lps-http|fm-port|vts-rmi|rpc)|r(?:f(?:controlcpa|pass)?|veyinst|-meas|ebox)|b(?:mi(?:t(?:server)?|ssion)|ntbcst[-_]tftp)|p(?:er(?:cell|mon)|dup)|it(?:case|jd)|(?:uc|g)p|-mit-tg)|i(?:m(?:p(?:l(?:e(?:-(?:push(?:-s)?|tx-rx)|ment-tie)|ifymedia)|-all)|ba(?:service|expres|-c)s|on(?:-disc)?|c(?:tlp|o)|-control|slink)|l(?:verp(?:eak(?:comm|peer)|latter)|k(?:p[1234]|meter)|houette|c)|g(?:n(?:a(?:cert-agent|l)|et-ctf)|ma-port|htline)|t(?:ara(?:(?:serve|di)r|mgmt)|ewatch)|x(?:-degrees|xsconfig|netudr|trak)|e(?:mensgsm|bel-ns|ve)|(?:ft-uf|s-em|ipa)t|a(?:-ctrl-plane|m)|cct(?:-sdp)?|ps?)|y(?:n(?:c(?:hro(?:n(?:et-(?:rtc|upd|db)|ite)|mesh)|server(?:ssl)?|-em7|test)|o(?:tics-(?:broker|relay)|ptics-trap)|aps(?:e(?:-nhttps?)?|is-edge)|el-data)|s(?:t(?:em(?:-monitor|ics-sox)|at)|log(?:-(?:conn|tls))?|erverremote|o(?:pt|rb)|info-sp|scanner|comlan|rqd)|base(?:anywhere|-sqlany|dbsynch|srvmon)|m(?:antec-s(?:fdb|im)|b-sb-port|plex)|am-(?:webserver|agent|smc)|pe-transport|chrond)|t(?:a(?:r(?:t(?:-network|ron)|(?:quiz-por|bo)t|s(?:chool)?|gatealerts|fish)|t(?:-(?:results|scanner|cc)|s(?:ci[12]-lm|rv)|usd)|nag-5066)|r(?:e(?:et(?:-stream|perfect|talk)|amcomm-ds|sstester|xec-[ds]|letz)|yker-com)|o(?:ne(?:-design-1|falls)|r(?:view|man))|un(?:-(?:p(?:[123]|ort)|behaviors?)|s)?|m(?:[-_]pproc|f)|(?:e-sms|dpt)c|(?:gxfw|s)s|t(?:unnel)?|i-envision|vp|x)|c(?:o(?:-(?:(?:(?:ine|d)t|sys)mgr|websrvrmg[3r]|peer-tta|aip)|tty-(?:disc|ft)|i2odialog|remgr|help|l)|i(?:n(?:tilla|et)|entia-s?sdb|pticslsrvr)|p(?:i-(?:telnet|raw)|-config)?|t(?:e(?:104|30)|p-tunneling)|r(?:eencast|iptview|abble)|c(?:-security|ip-media)|e(?:n(?:ccs|idm)|anics)|an(?:-change|stat-1)|up(?:-disc)?|s(?:erv|c)p|x-proxy)|a(?:n(?:t(?:ak-up|ool)s|avigator|e-port|ity)|g(?:e(?:-best-com[12]|ctlpanel)|xtsds)|s(?:(?:-remote-hl)?p|g(?:gprs)?)|i(?:s(?:c?m|eh)?|[-_]sentlm)|lient-(?:dtasrv|usrmgr|mux)|m(?:sung-(?:unidex|disc)|d)|b(?:a(?:rsd|ms)|p-signal)|p(?:hostctrls?|v1)|(?:-msg-por|van)t|f(?:etynetp|t)|r(?:atoga|is)|uterdongle|c(?:red)?|h-lm)|o(?:l(?:id-(?:e-engine|mux)|era-(?:epmap|lpn)|aris-audit|ve)|n(?:us(?:(?:-loggin|callsi)g)?|ar(?:data)?|iqsync)|s(?:s(?:d-(?:(?:collec|agen)t|disc)|ecollector))?|ft(?:rack-meter|dataphone|audit|cm|pc)|c(?:(?:orf|k)s|ial-alarm|p-[ct]|alia)|a(?:p-(?:bee|htt)p|gateway)|p(?:hia-lm|s)|undsvirtual|r-update)|m(?:a(?:r(?:t(?:-(?:diagnose|install|lm)|card-(?:port|tls)|packets|sdp)|-se-port[12])|(?:uth-por|kyne)t|clmgr|-spw|p)|s(?:-(?:r(?:emctrl|cinfo)|chat|xfer)|q?p|d)|c(?:-(?:https?|admin|jmx)|luster)|p(?:p(?:pd)?|nameres|te)|-(?:pas-[12345]|disc)|(?:ntubootstra|t)p|i(?:le|p)|bdirect|wan|ux)|p(?:e(?:ct(?:ard(?:ata|b)|raport)|edtrace(?:-disc)?|arway)|r(?:ams(?:ca|d)|emotetablet)|s(?:s(?:-lm)?|-tunnel|c)|w-d(?:nspreload|ialer)|a(?:ndataport|mtrap)|i(?:ral-admin|[ck]e)|t(?:-automation|x)|litlock(?:-gw)?|hinx(?:api|ql)|c(?:sdlobby)?|ytechphone|oc[kp]|d[py]|ugna|mp)|n(?:s(?:-(?:a(?:dmin|gent)|qu(?:ery|ote)|dispatcher|channels|protocol|gateway)|s)|mp(?:(?:dtls|ssh)(?:-trap)?|t(?:ls(?:-trap)?|rap)|-tcp-port)?|a(?:p(?:[dp]|enetio)?|(?:resecu)?re|(?:-c|ga)s|c)|i(?:ffer(?:client|server|data)|p-slave)|t(?:p-heartbeat|lkeyssrvr)|[cp]p)|s(?:m(?:[cd]|-(?:c(?:ssp|v)|el)s|pp)|o(?:-(?:control|service)|watch)|t(?:p-[12]|sys-lm)?|r(?:-servermgr|ip)|d(?:ispatch|t?p)|h(?:-mgmt|ell)?|sl(?:ic|og)-mgr|-idi(?:-disc)?|c(?:-agent|an)|p(?:-client)?|e-app-config|7ns|ad|lp|ql)|d(?:p(?:-(?:portmapper|id-port)|roxy)|-(?:capacity|request|data|elmd)|s(?:-admin|erver|c-lm)?|(?:(?:nsk|m)m|hel|d)p|(?:e-discover|bprox)y|o(?:-(?:ssh|tls))?|t(?:-lmd)?|client|l-ets|func|r)?|w(?:i(?:s(?:mgr[12]|trap|pol)|ft(?:-rvf|net))|(?:eetware-app|ldy-sia)s|x(?:-gate|admin)|r(?:-port|mi)|dtp(?:-sv)?|tp-port[12]|a-[1234]|-orion)|h(?:a(?:r(?:p-server|eapp)|perai(?:-disc)?|dowserver)|i(?:va(?:[-_]confsrvr|discovery|sound|hose)|lp)|o(?:ckwave2?|far)|rinkwrap|ell)|g(?:i-(?:e(?:ventmond|sphttp)|s(?:torman|oap)|arrayd|dmfmgr|lk)|e[-_](?:qmaster|execd)|mp(?:-traps)?|(?:ci?|sa)p|-lm)|l(?:i(?:n(?:kysearch|terbase|gshot)|m-devices)|c-(?:ctrlrloops|systemlog)|s(?:lavemon|cc)|p(?:-notify)?|m-api|ush)|f(?:t(?:[pu]|dst-port|srv)|s-(?:smp-net|config)|m(?:-db-server|sso)|l(?:ow|m)|-lm)|k(?:ip-(?:cert-(?:recv|send)|mc-gikreq)|y(?:-transpor|telne)t|ronk)|v(?:n(?:et(?:works)?)?|(?:backu|dr)p|s-omagent|cloud|rloc)|r(?:vc[-_]registry|p-feedback|[dm]p|ssend|cp?|uth)|q(?:l(?:exec(?:-ssl)?|[-*]net|se?rv)|dr)|b(?:(?:acku|ca)p|i-agent|ook|l)|-(?:openmail|net)|1(?:-control|02)|8-client-port|x(?:upt|m)p|3db)|a(?:p(?:p(?:l(?:e(?: remote desktop \(net assistant\)|-(?:vpns-rp|licman|sasl)|qtc(?:srvr)?|ugcontrol)|i(?:ance-cfg|x)|us(?:service)?)|s(?:erv-https?|witch-emp|s-lm)|arenet-(?:(?:tp?|a)s|ui)|man-server|iq-mgmt|worxsrv)|c(?:-(?:2(?:16[01]|260)|3(?:052|506)|545[456]|654[789]|995[012]|784[56]|necmp)|upsd)|o(?:llo-(?:(?:statu|gm)s|admin|relay|data|cc)|geex-port|cd)|w(?:i-(?:(?:rxs(?:pool|erv)|imserv)er|disc)|-registry)|e(?:x-(?:edge|mesh)|rtus-ldp)|ri(?:go-cs|-lm)|x500api-[12]|ani[12345]|m-link|dap|lx)?|s(?:p(?:e(?:n(?:-services|tec-lm)|clmd)|coordination|rovatalk)|t(?:er(?:gate(?:-disc|fax)?|ix)|ro(?:med-main|link))|a(?:p-(?:(?:sct|tc)p(?:-tls)?|udp)|-appl-proto|m)?|s(?:uria-(?:ins|slm)|oc-disc|yst-dr)|i(?:p(?:-webadmin|registry)|hpi|a)?|c(?:trl-agent|omalarm|-slmd|i-val)|-(?:servermap|debug)|g(?:cypresstcps|enf)|f(?:-secure)?-rmcp|mp(?:-mon|s)?|naacceler8db|oki-sma|dis|r)|c(?:c(?:e(?:ss(?:builder|network)|l(?:enet(?:-data)?)?)|u(?:racer(?:-dbms)?|-lmgr)|topus-(?:cc|st)|ord-mgc|-raid)|p(?:-(?:p(?:o(?:licy|rt)|roto)|discovery|conduit)|tsys|lt)?|t(?:i(?:ve(?:memory|sync)|fio-c2c)|net|er)|m(?:aint[-_](?:trans|db)d|s(?:oda)?|e)|e-(?:s(?:vr-prop|erver)|client|proxy)|-(?:cluster|tech)|l-manager|r-nema|a[ps]|d-pm|is?|net)|r(?:m(?:a(?:getronad|dp)|centerhttps?|techdaemon|i-server)|e(?:pa-(?:raft|cas)|aguard-neo|na-server)|d(?:us(?:-(?:m?trns|cntl)|mul|uni)|t)|i(?:e(?:s-kfinder|l[123])|liamulti|a)|(?:ray-manag|uba-serv)er|s-(?:master|vista)|c(?:isdms|pd?)|gis-(?:ds|te)|bortext-lm|tifact-msg|kivio|ns)|m(?:t(?:-(?:(?:(?:cnf|esd)-pro|blc-por)t|redir-t(?:cp|ls)|soap-https?))?|p(?:r-(?:in(?:ter|fo)|rcmd)|l-(?:tableproxy|lic)|ify)?|x-(?:web(?:admin|linx)|axbnet|icsp|rms)|i(?:con-fpsu-(?:ra|s)|ganetfs|net)|a(?:hi-anywhere|nda)|b(?:it-lm|eron)|(?:qp|c)s?|dsched|s)|l(?:t(?:a(?:v-(?:remmgt|tunnel)|-ana-lm|link)|ova(?:-lm(?:-disc)?|central)|serviceboot|(?:bsd|c)p)|l(?:joyn(?:-(?:mc|st)m)?|(?:storcn|peer)s)|ar(?:m(?:-clock-[cs])?|is-disc)|p(?:ha(?:tech-lm|-sms)|es)|(?:esquer|chem)y|mobile-system|fin|ias)|u(?:t(?:o(?:cue(?:time|log|smi|ds)|(?:no|pa)c|desk-n?lm|trac-acp|build)|h(?:entx)?)|r(?:[ap]|ora(?:-(?:balaena|cmgr))?|i(?:ga-router|s))|di(?:o(?:-activmail|juggler)|t(?:-transfer|d)?))|t(?:m(?:-(?:zip-office|uhas)|(?:tc)?p)|-(?:[3578]|(?:rtm|nb)p|echo|zis)|tachmate-(?:(?:s2|ut)s|g32)|c-(?:appserver|lm)|s(?:c-mh-ssc)?|i-ip-to-ncpe|ex[-_]elmd|hand-mmp|links|ul)|v(?:a(?:nt(?:i[-_]cdp|ageb2b)|uthsrvprtcl|ilant-mgr)|i(?:nstalldisc|va-sna|an)|ocent-(?:adsap|proxy)|t(?:-profile-[12]|p)|-emb-config|en(?:ue|yo)|securemgmt|decc)|n(?:s(?:ys(?:l(?:md|i)|-lm)|a(?:notify|trader)|oft-lm-[12]|wersoft-lm|-console)|t(?:idotemgrsvr|hony-data)|et(?:-[bhlm])?|oto-rendezv|-pcp|d-lm)|f(?:s(?:3-(?:(?:(?:file|ka|pr)serv|v(?:lserv|ols))er|(?:error|rmtsy|bo)s|callback|update))?|(?:ore-vdp-dis|esc-m)c|povertcp|filiate|tmux|rog)?|d(?:(?:te(?:mpusclien|ch-tes)|i-gxp-srvpr)t|a(?:p(?:t(?:ecmgr|-sna))?|-cip)|obeserver-[12345]|min(?:s-lms|d)|(?:re|c)p|s(?:-c)?|vant-lm|ws)|i(?:r(?:s(?:hot|ync)?|onetddp)|c(?:-(?:oncrpc|np)|c-cmi)|mpp-(?:port-req|hello)|pn-(?:auth|reg)|agent|bkup|lith|ses)|b(?:a(?:t(?:emgr|jss)|cus-remote|rsd)|c(?:voice-port|software)|b(?:accuray|-escp|s)|r-(?:secure|api)|out)|e(?:s(?:-(?:discovery|x170)|op)|ro(?:flight-(?:ads|ret))?|quus(?:-alt)?|d-512|gate)|g(?:ent(?:sease-db|view|x)|ri(?:-gateway|server)|p(?:s-port|olicy)|cat|slb)|1(?:[45]|(?:[67]-an|3)-an|-(?:msc|bs))|2(?:[56]-fap-fgw|1-an-1xbs|7-ran-ran)|(?:h(?:-esp-enca|s)|ker-cd)p|a(?:irnet-[12]|l-lm|m?p|s)|w(?:acs-ice|g-proxy|s-brf)|o(?:l(?:-[123])?|cp|dv)|x(?:is-wimp-port|on-lm)|z(?:eti(?:-bd)?|tec)|[34]-sdunode|ja-ntv4-disc|yiya)|c(?:o(?:m(?:m(?:plex-(?:link|main)|(?:onspa|er)ce|tact-https?|linx-avl|andport|unity)|p(?:aq-(?:[sw]cp|https|evm)|osit-server|x-lockview|ressnet)|otion(?:master|back)|box-web-acc|cam(?:-io)?|-bardac-dw|s(?:at|cm))|n(?:n(?:e(?:ct(?:-(?:client|server)|ion|ed)?|ndp)|lcli)|t(?:(?:clientm|inuu)s|amac[-_]icm|entserver)|f(?:(?:ig-por|luen)t|erence(?:talk)?)?|c(?:urrent-lm|lave-cpp|omp1)|s(?:ul-insight|piracy)|dor)?|r(?:e(?:l(?:[-_]vncadmin|video|ccam)|rjd)|ba(?:-iiop(?:-ssl)?|loc))|d(?:a(?:srv(?:-se)?|auth2)|emeter(?:-cmwan)?|ima-rtp)|g(?:n(?:ex-(?:dataman|insight)|ima)|sys-lm|itate)|p(?:y(?:-disc|cat)?|(?:s-tl)?s)|l(?:lab(?:orato|e)r|ubris)|a(?:uthor|ps?)|s(?:mocall|ir)|u(?:chdb|rier)|ord-svr|via)|a(?:n(?:o(?:n-(?:c(?:pp-disc|apt)|bjnp[1234]|mfnp)|central[01])|-(?:(?:ferret|nds)(?:-ssl)?|dch)|d(?:itv|r?p)|it[-_]store|to-roboflow|ex-watch)|d(?:key-(?:licman|tablet)|(?:abra|si)-lm|encecontrol|is-[12]|view-3d|lock2?)|r(?:t(?:ographerxmp|-o-rama)|d(?:box(?:-http)?|ax)|rius-rshell)?|l(?:l(?:-(?:sig-trans|logging)|waveiam|trax|er9)|dsoft-backup)?|p(?:wap-(?:control|data)|fast-lmd|ioverlan|s-lm|mux)?|s(?:(?:answmgm|rmagen)t|p(?:ssl)?|torproxy|-mapi)?|i(?:(?:storagemg|ds-senso)r|cci(?:pc)?|lic)|-(?:[12]|audit-d[as]|web-update|idms)|b(?:-protocol|leport-ax|sm-comm)|c(?:sambroker|i-lm)|u(?:pc-remote|tcpd)|m(?:bertx-lm|ac|p)|t(?:chpole|alyst)|ac(?:lang2|ws)|e(?:rpc|vms)|jo-discovery|was)|s(?:o(?:ft(?:-p(?:lusclnt|rev)|ragent|1)|auth)?|-(?:remote-db|auth-svr|services|live)|d(?:-m(?:gmt-port|onitor)|m(?:base)?)|p(?:m(?:lockmgr|ulti)|(?:clmult|un)i)|c(?:c(?:firewall|redir)|[-_]proxy|p)|vr(?:-(?:ssl)?proxy)?|n(?:et-ns|otify)|r(?:egagent|pc)|i-(?:lfa|sgw)p|l(?:istener|g)|bphonemaster|edaemon|t-port|s[cp]|ms2?)|i(?:s(?:co(?:-(?:s(?:ccp|nat|ys)|(?:ipsl|fn)a|t(?:dp|na)|vpath-tun|net-mgmt|redu|wafs|avp)|csdb)|-secure)?|t(?:rix(?:ima(?:client)?|-rtmp|admin|uppg?)|y(?:search|nl)|adel)|n(?:egrfx-(?:elmd|lm)|dycollab)|phire-(?:data|serv)|ch(?:ild-lm|lid)|3-software-[12]|m(?:plex|trak)|rcle-x|fs)|l(?:e(?:a(?:r(?:case|visn)|nerliverc)|ver-(?:ctrace|tcpip))|o(?:anto-(?:net-1|lm)|udsignaling|se-combat)|-(?:db-(?:re(?:quest|mote)|attach)|1)|u(?:ster(?:-disc|xl)|tild)|a(?:riion-evr01|ssic)|ient-(?:wakeup|ctrl)|vm-cfg|\/1|p)|p(?:q(?:rpm-(?:server|agent)|-(?:tasksmart|wbem))|-(?:spx(?:rpts|dpy|svr)|cluster)|lscrambler-(?:al|in|lg)|d(?:i-pidas-cm|lc)|(?:udpenca|pd)p|s(?:comm|p)?)|h(?:i(?:ldkey-(?:notif|ctrl)|p(?:-lm|per)|mera-hwm)|e(?:ck(?:(?:point-rt|su)m|outdb)|vinservices)|oiceview-(?:ag|cl)t|ar(?:setmgr|gen)|romagrafx|shell|md)|r(?:uise-(?:(?:swrou|upda)te|config|diags|enum)|e(?:ative(?:partn|serve)r|stron-c[it]ps?)|(?:-websystem|msbit)?s|i(?:nis-hb|p)|yptoadmin)|e(?:r(?:t-(?:initiato|responde)r|nsysmgmtagt|a-bcm)|sd(?:cd(?:ma|tr)n|inv)|nt(?:erline|ra)|quint-cityid|dros[-_]fds|fd-vmp|latalk|csvc)|t(?:i(?:(?:programloa|-redwoo)d|systemmsg)|d(?:[bp]|hercules)|x(?:-bridge|lic)|echlicensing|p(?:-state)?|t-broker|2nmcs|[cs]d|lptc|f)|c(?:m(?:a(?:il|d)|-port|comm|rmi)|s(?:-software|s-q[ms]m)|u-comm-[123]|-tracking|tv-port|ag-pib|owcmr|nx|p)|y(?:b(?:(?:org-system|ro-a-bu)s|ercash)|press(?:-stat)?|c(?:leserv2?)?|mtec-port|link-c|tel-lm|aserv)|d(?:[ns]|(?:l-serv|brok)er|dbp(?:-alt)?|3o-protocol|(?:fun)?c|id)|m(?:ip-(?:agent|man)|tp-(?:mgt|av)|a(?:dmin)?|mdriver|c-port)?|u(?:mulus(?:-admin)?|elink(?:-disc)?|s(?:eeme|tix)|illamartin)|n(?:c(?:kadserver|p)|rp(?:rotocol)?|s-srv-port|(?:hr|a)p)|v(?:c(?:[-_]hostd)?|s(?:pserver|up)|m?mon|d)|f(?:[sw]|t-[01234567]|engine|dptkt)|g(?:n-(?:config|stat)|i-starapi|ms)|b(?:(?:os-ip-por)?t|server|a8)|qg-netlan(?:-1)?|-h-it-port|x(?:tp|ws)|1222-acse|wmp|3)|m(?:s(?:-(?:s(?:na-(?:server|base)|(?:-s)?ideshow|treaming|ql-[ms]|huttle|mlbiz)|(?:(?:aler|thea)t|wbt-serv)er|r(?:ule-engin|om)e|l(?:icensing|a)|ilm(?:-sts)?|cluster-net|olap[1234]|v-worlds)|f(?:w-(?:(?:s-)?storage|control|replica|array)|t-(?:gc(?:-ssl)?|dpm-cert)|rs)|i(?:-(?:cps-rm(?:-disc)?|selectplay)|ccp|ms)|g(?:-(?:auth|icp)|s(?:rvr|ys)|clnt)|r(?:-plugin-port|p)|(?:tmg-sst|n)p|d(?:fsr|ts1|p)|exch-routing|h(?:net|vlm)|olap-ptp2|p(?:-os)?|l[-_]lmd|ync|mq|ss)|e(?:d(?:i(?:a(?:(?:-agen)?t|cntrlnfsd|vault-gui|space|box)|mageportal)|-(?:(?:sup|lt)p|fsp-[rt]x|net-svc|ovw|ci)|evolve)|t(?:a(?:edit-(?:mu|se|ws)|s(?:torm|age|ys)|tude-mds|console|-corp|agent|lbend|gram|5)|ric(?:s-pas|adbc)|er)|n(?:andmice(?:-(?:dns|lpm|mon|noh|upg)|_noh)|ta(?:client|server))|ga(?:r(?:dsvr-|egsvr)port|co-h248)|s(?:sage(?:service|asap)|avistaco)|r(?:c(?:ury-disc|antile)|egister)|mcache|comm|vent)|a(?:g(?:ic(?:control|notes|om)|aya-network|enta-logic|bind|pie)|i(?:l(?:box(?:-lm)?|prox|q)|n(?:control|soft-lm)|trd)|c(?:on-(?:tc|ud)p|-srvr-admin|romedia-fcs|bak)|pper-(?:(?:ws[-_]|map)ethd|nodemgr)|t(?:ip-type-[ab]|rix[-_]vnet|ahari)|n(?:yone-(?:http|xml)|age-exec|et)|r(?:kem-dcp|cam-lm|talk)|x(?:im-asics|umsp)?|d(?:ge-ltd|cap)|s(?:qdialer|c)|ytagshuffle|o)|i(?:c(?:ro(?:muse-(?:ncp[sw]|lm)|talon-(?:com|dis)|s(?:oft-ds|an)|com-sbp)|om-pfs|e)|n(?:d(?:array-ca|filesys|print)|i(?:-sql|lock|vend|pay)|otaur-sa|ger)|t(?:-(?:ml-de|do)v|eksys-lm)|l(?:-2045-47001|es-apart)|r(?:oconnect|rtex|a)|(?:pv6tl|va-mq)s|b-streaming|dnight-tech|ami-bcast|key|mer)|o(?:b(?:il(?:e(?:-(?:file-dl|p2p)|analyzer|ip-agent)|i(?:tysrv|p-mn))|rien-chat)|s(?:-(?:(?:low|upp)er|soap(?:-opt)?|aux)|ai(?:csyssvc1|xcc)|hebeeri)|n(?:(?:tage-l|keyco)m|etra(?:-admin)?|itor|dex|p)?|l(?:dflow-lm|ly)|rtgageware|vaz-ssc|y-corp|untd)|c(?:s-(?:m(?:essaging|ailsvr)|calypsoicf|fastmail)|-(?:(?:brk|gt)-srv|c(?:lient|omm)|appserver)|t(?:et-(?:gateway|master|jserv)|feed|p)|(?:(?:(?:cwebsv|e)r-|re)por|agen)t|n(?:s-(?:tel-ret|sec)|tp)|(?:2studio|ida|3s)s|(?:k-ivpi|ft)p|p(?:-port)?)|p(?:s(?:(?:ysrmsv|serve)r|-raft|hrsv)|njs(?:o(?:m[bg]|cl|sv)|c)|p(?:olicy-(?:mgr|v5))?|l(?:-gprs-port|s-pm)|m(?:-(?:flags|snd))?|f(?:oncl|wsas)|idc(?:agt|mgr)|c-lifenet|hlpdmc|tn)|u(?:lti(?:p(?:-msg|lex)|cast-ping|ling-http)|s(?:t-(?:backplane|p2p)|(?:iconlin)?e)|r(?:ray|x)|pdate|mps|nin)|y(?:sql(?:-(?:c(?:m-agent|luster)|proxy|im))?|(?:nahautostar|blas)t|l(?:ex-mapd|xamport)|q-termlink|rtle)|t(?:p(?:ort(?:-regist|mon))?|(?:-scale|s)server|cevrunq(?:man|ss)|l8000-matrix|i-tcs-comm|rgtrans|qp|n)|g(?:c(?:p-(?:callagent|gateway)|s-mfp-port)|e(?:supervision|management)|xswitch)|d(?:ns(?:responder)?|(?:-cg-ht)?tp|bs[-_]daemon|c-portmapper|ap-port|qs|m)|n(?:(?:p-exchang|gsuit)e|et-discovery|i-prot-rout|s-mail)|m(?:a(?:-discovery|comm|eds)|c(?:als?|c)|pft)|x(?:o(?:dbc-connect|mss)|xrlogin|it?)|v(?:(?:el|x)-lm|s-capacity)|z(?:ca-a(?:ction|lert)|ap)|2(?:mservices|[pu]a|ap)|3(?:da(?:-disc)?|ap|ua)|b(?:l-battd|g-ctrl|us)|r(?:ssrendezvous|ip|m)|l(?:-svnet|oadd|sn|e)|f(?:server|cobol|tp)|qe-(?:broker|agent)|4-network-as|km-discovery|-wnn)|i(?:n(?:t(?:e(?:r(?:s(?:ys-cache|erver|an)|act(?:ionweb)?|w(?:orld|ise)|hdl[-_]elmd|pathpanel|intelli|mapper|base)|l(?:-rci(?:-mp)?|listor-lm|_rci|sync)|gr(?:a(?:-sme|l)|ius-stp)|co(?:m-ps[12]|urier))|u(?:-ec-(?:svcdisc|client)|itive-edge)|r(?:a(?:intra|star)|epid-ssl|insa)|-rcv-cntrl|v)|f(?:o(?:rm(?:atik-lm|er)|(?:brigh|cryp)t|m(?:over|an)|libria|exch|seek|wave|tos)|iniswitchcl|luence)|d(?:i(?:go-(?:v(?:bcp|rmi)|server))?|ex-(?:pc-wb|net)|x-dds|ura|y)|s(?:t(?:l[-_]boot[cs]|-discovery|antia)|i(?:tu-conf|s)|pect)|i(?:nmessaging|serve-port|tlsmsad)|ova(?:port[123456]|-ip-disco)|v(?:ision(?:-ag)?|okator)|gres(?:-net|lock)|c(?:ognitorv|p)|nosys(?:-acl)?|business)|s(?:o(?:-(?:t(?:sap(?:-c2)?|p0s?)|i(?:ll|p))|ipsigport-[12]|de-dua|ft-p2p|mair)|i(?:s(?:-(?:am(?:bc)?|bcast))?|-(?:irp|gl))|m(?:aeasdaq(?:live|test)|server|c)|c(?:si(?:-target)?|ape|hat)|s(?:-mgmt-ssl|d)|bconference[12]|p(?:ipes|mmgr)|n(?:etserv|s)|g-uda-server|rp-port|99[cs]|ysg-lm|d[cd]|akmp|lc)|c(?:l(?:pv-(?:(?:[dp]|ws)m|s(?:as|c)|nl[cs])|cnet(?:-(?:locate|svinfo)|_svinfo)|-twobase(?:[23456789]|10?)|id)|e(?:-s?(?:location|router)|edcp[-_][rt]x)|on(?:-discover|structsrv|p)|g-(?:iprelay|bridge|swp)|a(?:browser|d-el|p)?|s(?:hostsvc|lap)?|p(?:v2|p)?|crushmore|m(?:pd|s)|i)|p(?:[px]|c(?:s(?:-command|erver)|d3?|ore)|(?:ether232por|osplane|r-dgl)t|d(?:tp-port|cesgbs|r-sp|d)|-(?:provision|qsig|blf)|h-policy-(?:adm|cli)|se(?:c-nat-t|ndmsg)|f(?:ltbcst|ixs?)|(?:ulse-ic|as)s|t-anri-anri)|b(?:m(?:-(?:d(?:i(?:radm(?:-ssl)?|al-out)|(?:t-|b)2)|m(?:q(?:series2?|isdp)|gr)|r(?:syscon|es)|a(?:btact|pp)|(?:cic|pp)s|wrless-lan|ssd)|_wrless_lan|3494)|ridge-(?:data|mgmt)|(?:eriagame|u)s|p(?:rotocol)?|ar)|t(?:a(?:c(?:tionserver[12]|h)|-(?:manager|agent)|p-ddtp|lk)|m-(?:mc(?:ell-[su]|cs)|lm)|e(?:lserverport|m)|o(?:-e-gui|se)|u-bicc-stc|v-control|wo-server|internet|scomm-ns)|d(?:e(?:afarm-(?:panic|door)|n(?:t(?:ify)?|-ralp)|esrv)|o(?:nix-metane|tdis)t|a(?:-discover[12]|c)|p(?:-infotrieve|s)?|m(?:gratm|aps)|ware-router|ig[-_]mux|[cftx]p|rs)|m(?:q(?:(?:tunnel|stomp)s?|brokerd)|a(?:ge(?:query|pump)|p[3s]?)|i(?:p(?:-channels)?|nk)|tc-m(?:ap|cs)|medianet-bcn|p(?:era|rs)|s(?:ldoc|p)|oguia-port|docsvc|games|yx)|a(?:s(?:-(?:a(?:dmind|uth)|(?:pagin|re)g|neighbor|session)|control(?:-oms)?|d)|tp-(?:normal|high)pri|dt(?:-(?:disc|tls))?|f(?:server|dbase)|nywhere-dbns|pp|x)|r(?:is(?:-(?:xpcs?|beep|lwz)|a)|c(?:(?:s-)?u|-serv)?|a(?:cinghelper|pp)|d(?:g-post|mi2?)|on(?:storm|mail)|trans|p)|v(?:(?:collecto|manage)r|s(?:-video|d)|econ-port|ocalize)|e(?:e(?:e-m(?:ms(?:-ssl)?|ih)|-qfx)|c-104(?:-sec)?|s-lm)|f(?:s(?:f-hb-port|p)|or-protocol|e[-_]icorp|cp-port)|w(?:(?:listen|serv)er|b-whiteboard|-mmogame|ec|g1)|o(?:-dist-(?:group|data)|nixnetmon|c-sea-lm|p)|g(?:o-incognito|r(?:id|s)|mpv3lite|i-lm|cp)|q(?:(?:net-por|objec)t|server|rm|ue)|i(?:-admin|w-port|ms|op)|-(?:net-2000-npr|zipqd)|u(?:hsctpassoc|a)|3-sessionmgr|l(?:[dl]|ss)|zm)|n(?:e(?:t(?:c(?:o(?:nf(?:-(?:beep|ssh|tls)|soap(?:bee|htt)p)|mm[12])|h(?:eque|at)|abinet-com|(?:li)?p|elera)|b(?:i(?:ll-(?:(?:cre|pro)d|keyrep|trans|auth)|os-(?:dgm|ssn|ns))|oo(?:kmark|t-pxe)|lox)|s(?:c(?:-(?:prod|dev)|ript)|peak-(?:(?:cp?|i)s|acd)|erialext[1234]|upport2?|teward)|o(?:p(?:-(?:school|rc)|ia-vo[12345]|s-broker)|-(?:wol-server|dcs)|bjects[12])|w(?:a(?:tcher-(?:mon|db)|re-(?:cs|i)p|ve-ap-mgmt|ll)|kpathengine|orklens?s)|i(?:q(?:-(?:endp(?:oin)?t|qcheck|voipa|ncap|mc))?|nfo-local)|a(?:pp-ic(?:data|mgmt)|ttachsdmp|dmin|gent|ngel|spi|rx)|m(?:o(?:-(?:default|http)|unt|n)|a(?:p[-_]lm|gic)|pi|l)|x(?:ms-(?:(?:agen|mgm)t|sync)|-(?:server|agent))|view(?:-aix-(?:[23456789]|1[012]?)|dm[123])|r(?:i(?:x-sftm|sk)|js-[1234]|ockey6|cs|ek)|p(?:la(?:y-port[12]|n)|ort-id|erf)|-(?:projection|steward|device)|t(?:gain-nms|est)|eh(?:-ext)?|db-export|2display|labs-lm|8-cman|uitive|news|gw)|w(?:lix(?:(?:confi|re)g|engine)|(?:height)?s|bay-snc-mc|wavesearch|genpay|-rwho|oak)|x(?:storindltd|us-portal|entamv|tstep|gen)|s(?:t-protocol|h-broker|sus)|o(?:d[12]|iface|n24x7|4j)|c(?:-raidplus|kar|p)|i-management|veroffline|rv)|o(?:v(?:a(?:r-(?:global|alarm|dbase)|storbakcup|tion)|ell-(?:lu6[-.]2|ipx-cmd|zen))|t(?:e(?:zilla-lan|share|it)|ify(?:[-_]srvr)?|ateit(?:-disc)?)|(?:(?:it-transpo|rton-lambe)r|wcontac)t|a(?:(?:apor|gen)t|dmin)|kia-ann-ch[12]|m(?:ad|db))|a(?:t(?:i-(?:vi-server|svrloc|logos|dstp)|dataservice|tyserver|uslink)|v(?:-(?:data(?:-cmd)?|port)|isphere(?:-sec)?|egaweb-port|buddy)|m(?:e(?:server|munge)?|p)|s(?:-metering|manager)?|-(?:localise|er-tip)|c(?:agent|nl)|ap|ni)|i(?:m(?:-(?:vdrshell|wan)|r(?:od-agent|eg)|busdb(?:ctrl)?|s(?:pooler|h)|controller|aux|gtw|hub)?|c(?:e(?:tec-(?:nmsvc|mgmt)|link)|name)|-(?:visa-remote|mail|ftp)|linkanalyst|p(?:robe)?|observer|fty-hmi|trogen|naf|rp)|m(?:s(?:[dp]|-(?:topo-serv|dpnss)|_topo_serv|igport|server)?|-(?:game-(?:server|admin)|asses(?:-admin|sor))|(?:a(?:soveri)?|m)p|ea-(?:onenet|0183)|c-disc)|s(?:s(?:a(?:gen|ler)tmgr|ocketport|-routing|tp)?|(?:(?:-cfg)?-serve|esrv)r|jtp-(?:ctrl|data)|c-(?:posa|ccs)|deepfreezectl|w(?:-fe|s)|(?:rm?)?p|iiops|t)?|c(?:(?:a(?:cn-ip-tc|dg-ip-ud)|xc)p|d(?:loadbalance|mirroring)|p(?:m-(?:hip|ft|pm))?|u(?:-[12]|be-lm)|r[-_]ccl|config|ld?|ed)|d(?:m(?:-(?:(?:request|serv)er|agent-port)|ps?)|l-(?:a(?:[alp]s|hp-svc)|tcp-ois-gw)|s(?:[-_]sso|connect|auth|p)|np?|tp)|p(?:mp(?:-(?:local|trap|gui))?|d(?:s-tracke|bgmng)r|(?:(?:pm)?|s)p|ep-messaging|qes-test)|u(?:t(?:s[-_](?:bootp|dem))?|cleus(?:-sand)?|paper-ss|auth|xsl|fw)|b(?:x-(?:(?:di|se)r|au|cc)|t-(?:wol|pc)|urn[-_]id|db?)|t(?:z-(?:p2p-storage|tracker)|a(?:-[du]s|lk)|p)|f(?:s(?:d-keepalive|rdma)?|oldman|a)|2(?:(?:nremot|receiv)e|h2server)|v(?:(?:msg)?d|c(?:net)?|-video)|l(?:g-data|ogin|s-tl)|1-(?:rmgmt|fwp)|h(?:server|ci)|n(?:tps?|s?p)|x(?:edit|lmd)|(?:g-umd|q)s|jenet-ssl|w-license|rcabq-lm|kd)|p(?:r(?:o(?:s(?:hare(?:[12]|(?:audi|vide)o|-mc-[12]|request|notify|data)|pero(?:-np)?)|fi(?:net-(?:rtm?|cm)|le(?:mac)?)|a(?:ctiv(?:esrvr|ate)|xess)|x(?:i(?:ma-l)?m|y-gateway)|d(?:igy-intrnet|uctinfo)|g(?:istics|rammar)|(?:-e|of)d|pel-msgsys|cos-lm|remote|link)|i(?:v(?:ate(?:chat|wire|ark)|ilege|oxy)|nt(?:er(?:[-_]agent)?|-srv|opia)|sm(?:iq-plugin|-deploy)|ority-e-com|maserver|zma)|e(?:cise-(?:comm|sft|vip|i3)|s(?:onus-ucnet|ence|s)|datar-comms|x-tcp|lude)|(?:chat-(?:serv|us)|regist)er|n(?:request|status)|a(?:[-_]elmd|t)|m-[ns]m(?:-np)?|(?:sv|g)?p)|a(?:r(?:a(?:(?:dym-31por|gen)t|llel)|sec-(?:(?:mast|pe)er|game)|(?:k-age|lia)nt|timage)|n(?:a(?:golin-ident|sas)?|do-(?:pub|sec)|golin-laser)|trol(?:-(?:(?:mq-[gn]|is)m|coll|snmp)|view)?|ss(?:w(?:rd-policy|ord-chg)|go(?:-tivoli)?)|y(?:cash-(?:online|wbp)|-per-view|router)|c(?:e(?:-licensed|rforum)|mand|om)|g(?:o-services[12]|ing-port)|l(?:ace-[123456]|com-disc)|d(?:l2sim|s)|mmr(?:at|p)c|fec-lm|wserv)|c(?:s(?:-(?:sf-ui-man|pcw)|ync-https?)|-(?:mta-addrmap|telecommute)|p(?:-multicast|tcpservice)?|i(?:a(?:-rxp-b|rray)|hreq)|o(?:ip(?:-mgmt)?|nnectmgr)|le(?:multimedia|-infex)|anywhere(?:data|stat)|m(?:k-remote|ail-srv)|c-(?:image-port|mfp)|t(?:tunnell|rader)|ep)|e(?:r(?:son(?:a(?:l(?:-(?:agent|link)|os-001))?|nel)|i(?:scope|mlan)|f(?:-port|d)|mabit-cs|rla)|g(?:asus(?:-ctl)?|board)|er(?:book-port|wire)|(?:arldoc-xac|por)t|oc(?:oll|tlr)|ntbox-sim|-mike|help)|o(?:w(?:er(?:g(?:uardian|emplus)|alert-nsa|clientcsf|exchange|school|burst|onnud)|wow-(?:client|server))|p(?:up-reminders|3s?|2)|l(?:icyserve|esta)r|rtgate-auth|stgresql|v-ray)|i(?:c(?:trography|colo|knfs|odbc|hat)|p(?:e(?:[-_]server|s))?|m-(?:rp-disc|port)|ng(?:-pong|hgl)|r(?:anha[12]|p)|t-vpn)|l(?:a(?:ysta2-(?:app|lob)|to(?:-lm)?)|(?:cy-net-svc|uribu)s|bserve-port|ysrv-https?|ethora|gproxy)|d(?:a(?:-(?:data|gate|sys)|(?:p-n)?p)|(?:[ru]nc|efmn)?s|l-datastream|-admin|net|ps?|tp|b)|m(?:c(?:[ps]|d(?:proxy)?)|ip6-(?:cntl|data)|d(?:fmgt|mgr)?|sm-webrctl|-cmdsvr|webapi|as)|k(?:t(?:cable(?:mm|-)cops|-krb-ipsec)|ix-(?:timestamp|3-ca-ra|cmc)|-electronics|agent)?|s(?:(?:(?:(?:d?b|pr?|r)s)?erv|l(?:serv|ics))er|c(?:l-mgt|ribe|upd)|i-ptt|-ams|mond|sc?)|h(?:o(?:ne(?:x-port|book)|enix-rpc|turis)|ar(?:masoft|os)|relay(?:dbg)?|ilips-vc)?|u(?:r(?:enoise|ityrpc)|(?:lsonixnl|shn)s|p(?:router|arp)|bliqare-sync|mp)|n(?:et-(?:conn|enc)|-requester2?|aconsult-lm|bs(?:cada)?|rp-port|s)|t(?:p(?:-(?:general|event))?|cnameservice|2-discover|k-alink|-tls)|p(?:t(?:conference|p)|s(?:uitemsg|ms)|activation|control)|xc-(?:s(?:p[lv]r(?:-ft)?|apxom)|epmap|ntfy|roid|pin)|v(?:xplus(?:cs|io)|sw(?:-inet)?|uniwien|access)|w(?:g(?:ippfax|wims|psi)|d(?:gen|is)|rsevent)|2(?:p(?:community|group|q)|5cai)|q(?:s(?:flows|p)|-lic-mgmt)|-net-(?:remote|local)|f(?:u-prcallback|tp)|g(?:bouncer|ps)|4p-portal|6ssmc|jlink|yrrho)|d(?:i(?:r(?:ec(?:t(?:v(?:-(?:catlg|soft|tick|web)|data)|play(?:srvr|8)?|net)?|pc-(?:video|dll|si))|gis)|a(?:l(?:og(?:ic-elmd|-port)|pad-voice[12])|g(?:nose-proc|mond)|m(?:ondport|eters?))|s(?:c(?:p-(?:client|server)|overy-port|lose|ard)|t(?:inct(?:32)?|-upgrade|cc)|play)|c(?:om(?:-(?:iscl|tls))?|t(?:-lookup)?|-aida)|gi(?:tal-(?:notary|vrc)|vote|man)|-(?:(?:tracewar|as)e|drm|msg)|f-port|xie)|e(?:c(?:-(?:mbadmin(?:-h)?|notes|dlm)|a(?:uth|p)|vms-sysmgt|ladebug|_dlm|bsrv|talk)|l(?:l(?:-(?:eql-asm|rm-port)|webadmin-[12]|pwrappks)|os-dms|ta-mcp|ibo)|-(?:s(?:erver|pot)|cache-query|noc)|s(?:k(?:top-dna|share|view)|cent3)|v(?:shr-nts|basic|ice2?)|y-(?:keyneg|sapi)|nali-server|ploymentmap|rby-repli|i-icda|os)|a(?:t(?:a(?:s(?:caler-(?:ctl|db)|urfsrv(?:sec)?)|-(?:insurance|port)|captor|lens)|ex-asn|usorb)|y(?:lite(?:server|touch)|time)|n(?:dv-tester|f-ak2)|(?:rcorp-l|qstrea)m|s(?:hpas-port|p)|i(?:-shell|shi)|mewaremobgtwy|b-sti-c|li-port|vsrcs?|ap|wn)|s(?:m(?:cc-(?:c(?:onfig|cp)|download|passthru|session)|eter[-_]iatc|-scm-target|ipv6)|-(?:s(?:rvr?|lp)|admin|clnt|mail|user)|x(?:-(?:monitor|agent)|_monitor)|e(?:rver|tos)|lremote-mgmt|p(?:3270)?|om-server|f(?:gw)?|siapi|atp|dn|c)|o(?:c(?:e(?:ri-(?:view|ctl)|nt)|umentum(?:[-_]s)?|(?:-serve|sto)r|ker(?:-s)?|1lm)|wn(?:tools(?:-disc)?)?|m(?:ain(?:time)?|iq)|glms(?:-notify)?|ip-d(?:ata|isc)|nnyworld|ssier|om)|b(?:control(?:-(?:agent|oms)|_agent)|s(?:(?:yncarbite|ta)r|a-lm)|(?:a(?:bbl|s)|brows)e|-lsp(?:-disc)?|isamserver[12]|re(?:porter|f)|eregister|db|m)|t(?:a(?:-systems|g-ste-sb)|p(?:-(?:dia|net)|t)?|s(?:erver-port|pcd)?|-(?:mgmtsvc|vra)|n(?:-bundle|1)|v-chan-req|k)|2(?:k-(?:datamover|tapestry)[12]|000(?:webserver|kernel)|d(?:datatrans|config))|h(?:c(?:p(?:v6-(?:client|server)|-failover2?)|t-(?:alert|statu)s)|analakshmi|e)|n(?:6-(?:nlm-au|smm-re)d|s(?:-llq|2go|ix)|a(?:-cml|p)?|p(?:-sec)?|c-port|o?x)|p(?:s(?:erve(?:admin)?|i)|m(?:-a(?:gent|cm))?|(?:i-p)?roxy|keyserv|[ac]p)|r(?:m(?:-production|s(?:fsd|mc))|i(?:veappserver|zzle|p)|agonfly|wcs|p)|l(?:s(?:-mon(?:itor)?|r(?:ap|pn)|wpn)?|(?:px-s|i)p|[-_]agent|ms-cosem)|v(?:t-(?:system|data)|l-activemail|cprov-port|bservdsc|r-esm|apps)|c(?:s(?:l-backup|-config|oftware)?|c(?:p-udp|m)|utility|ap?|t?p)?|d(?:i-(?:tc|ud)p-[1234567]|m-(?:dfm|rdb|ssl)|ns-v3|repl|dp|gn|t)|m(?:(?:af-(?:cast|serv)|docbrok)er|od-workspace|express|idi|p)|yn(?:a(?:-(?:access|lm)|mi(?:c3)?d)|iplookup|-site)|-(?:cinema-(?:cs|rr)p|data(?:-control)?|fence|s-n)|x(?:messagebase[12]|-instrument|admind|spider)|w(?:(?:msgserve)?r|nmshttp|f)|z(?:oglserver|daemon)|f(?:(?:ox)?server|n)|g(?:pf-exchg|i-serv)|k(?:messenger|a)|j-i(?:ce|lm)|3winosfi)|t(?:r(?:i(?:m(?:-(?:event|ice))?|(?:tium-ca|omotio)n|s(?:pen-sra|oap)|p(?:(?:wir)?e)?|dent-data|quest-lm|vnet[12]|butary)|a(?:p(?:-(?:port(?:-mom)?|daemon))?|v(?:soft-ipx-t|ersal)|ns(?:mit-por|ac)t|c(?:eroute|k)|ingpsdata|gic|m)|u(?:ste(?:stablish|d-web)|ckstar|ecm)|e(?:ndchip-dcp|ehopper)|-rsrb-p(?:[123]|ort)|nsprntproxy|c-netpoll|off|p)|a(?:l(?:arian-(?:m(?:cast[12345]|qs)|(?:tc|ud)p)|on-(?:webserver|engine|disc)|i(?:kaserver|gent-lm)|-pod|net|k)|s(?:kma(?:ster2000|n-port)|erver|p-net)|c(?:(?:ac(?:s-d)?|new)s|ticalauth)|r(?:gus-getdata[123]?|antella)|p(?:e(?:stry|ware)|pi-boxnet)|g-(?:ups-1|pm)|m(?:bora|s)|ep-as-svc|urus-wh|iclock|bula)|e(?:l(?:e(?:(?:niumdaemo|sis-licma)n|lpath(?:attack|start)|finder)|l(?:umat-nms)?|net(?:cpcd|s)?|aconsole|ops-lmd|indus)|r(?:a(?:dataordbms|base)|minaldb|edo)|(?:c5-sdct|edta)p|mp(?:est-port|o)|n(?:tacle|fold)|amcoherence|sla-sys-msg|trinet|xa[ir]|kpls)|i(?:m(?:e(?:stenbroker|flies|lot|d)?|buktu(?:-srv[1234])?)|p(?:[2c]|-app-server)|vo(?:connect|li-npm)|c(?:f-[12]|k-port)|n(?:ymessage|c)|g(?:v2)?|dp)|t(?:c(?:-(?:etap(?:-[dn]s)?|ssl)|mremotectrl)?|l(?:-publisher|priceproxy)|n(?:repository|tspauto)|g-protocol|at3lb|yinfo)|o(?:(?:mato-spring|uchnetplu|nidod)s|p(?:flow(?:-ssl)?|ovista-data|x)|ad(?:-bi-appsrvr)?|l(?:teces|fab)|ruxserver)|c(?:p(?:dataserver|nethaspsrv|-id-port|mux)|o(?:(?:flash|reg)agent|addressbook)|lprodebugger|im-control|c-http)|n(?:-t(?:l-(?:[rw]|fd)[12]|iming)|p(?:-discover|1-port)?|s-(?:server|adv|cml)|os-(?:dps?|sp)|etos|mpv2)|u(?:n(?:a(?:lyzer|tic)|gsten-https?|stall-pnc|nel)|r(?:bonote-[12]|ns?))|l(?:1(?:-(?:raw(?:-ssl)?|telnet|ssh|lv))?|-ipcproxy|isrv)|s(?:(?:ccha|rmag)t|(?:spma)?p|dos390|erver|af?|b2?|ilb)|d(?:-(?:postman|replica|service)|p-suite|access|moip)|m(?:o(?:-icon-sync|phl7mts|sms[01])|esis-upshot|i)|v(?:dumtray-port|networkvideo|e-announce|bus|pm)|w(?:(?:(?:sd|c)s|d)s|amp-control|-auth-key|rpc)|h(?:e(?:rmo-calc|ta-lm)|t-treasure|r(?:tx|p))|1(?:distproc(?:60)?|-e1-over-ip|28-gateway)|p(?:csrvr|du|ip|md)|ftp(?:-mcast|s)?|g(?:cconnect|p)|5-straton|2-[bd]rm|ksocket|qdata|brpf)|e(?:m(?:c(?:-(?:xsw-dc(?:onfig|ache)|vcas-(?:tc|ud)p|pp-mgmtsvc|gateway)|rmir(?:cc)?d|symapiport|ads|e)|p(?:rise-l(?:ls|sc)|-server[12]|ire-empuma|owerid|erion)|b(?:race-dp-[cs]|-proj-cmd|l-ndt)|(?:a-sent-l|7-seco)m|fis-(?:cntl|data)|w(?:avemsg|in)|s(?:d-port)?|gmsg)|n(?:t(?:rust(?:-(?:a(?:a[am]s|sh)|kmsh|sps)|time)|ext(?:(?:me|xi)d|netwk|high|low)|-engine|omb|p)|c(?:-(?:eps(?:-mc-sec)?|tunnel(?:-sec)?)|rypted(?:-(?:admin|llrp)|_admin)|ore)|rp(?:-sctp(?:-tls)?)?|l(?:-name)?|p[cp]|fs)|s(?:p(?:-(?:encap|lm)|eech(?:-rtp)?|s-portal)|c(?:ale \(newton dock\)|vpnet|p-ip)|r(?:o-(?:emsdp|gen)|i[-_]sde)|i(?:nstall|mport|p)|m(?:manager|agent)|s(?:web-gw|base|p)|(?:erver-pa|tam)p|nm-zoning|broker|-elmd|l-lm)|l(?:(?:pro[-_]tunne|fiq-rep)l|vin[-_](?:client|server)|a(?:n(?:lm)?|telink|d)|i(?:pse-rec)?|ektron-admin|m-momentum|c(?:sd|n)|lpack|xmgmt|s)|x(?:o(?:line-(?:tc|ud)p|config|net)|a(?:softport1|pt-lmgr)|c(?:e(?:rpts?)?|w)|p(?:[12]|resspay)|bit-escp|lm-agent|tensis|ec)|d(?:m-(?:m(?:gr-(?:cntrl|sync)|anager)|st(?:d-notify|ager)|adm-notify)|b(?:-server[12]|srvr)|i(?:tbench|x)|tools)|p(?:(?:-(?:ns|pc)|l-sl)p|ortcomm(?:data)?|n(?:cdp2|sdp)|m(?:ap|d)|t-machine|icon|pc?|c)|t(?:h(?:er(?:net(?:\/|-)ip-[12]|cat)|oscan)|lservicemgr|c-control|(?:ft)?p|ebac5|b4j|s)|v(?:e(?:nt(?:-(?:listener|port)|_listener)|rydayrc)|tp(?:-data)?|(?:b-el)?m|-services)|c(?:o(?:lor-imager|visiong6-1|mm)|mp(?:-data|ort)?|ho(?:net)?|sqdmn|wcfg|n?p)|r(?:unbook[-_](?:server|agent)|p(?:-scale|c)|istwoguns|golight)|w(?:-(?:disc-cmd|mgmt)|c(?:appsrv|tsp)|installer|all|dgs|nn)|i(?:con-(?:s(?:erver|lp)|x25)|s(?:p(?:ort)?)?|ms-admin)|q(?:3-(?:config|update)|-office-494[012]|uationbuilder)|-(?:d(?:esign-(?:net|web)|pnet)|builder|mdu|net|woa)|f(?:[rs]|i(?:-(?:lm|mg)|diningport)|orward|b-aci|cp)|z(?:me(?:eting(?:-2)?|ssagesrv)|proxy(?:-2)?|relay)|h(?:(?:p-backu|t)p|s(?:-ssl)?|ome-ms)|a(?:sy(?:-soft-mux|engine)|psp|1)?|ye(?:2eye|link|tv)|(?:udora-s|en)et|o(?:r-game|ss)|b(?:insite|a)|3consultants|g(?:ptlm|s))|r(?:e(?:m(?:o(?:te(?:-(?:(?:ki|a)s|winsock|collab)|ware-(?:srv|cl|un)|deploy|fs)|graphlm)|c(?:ap|tl))|s(?:o(?:urce[-_]mgr|rcs)|ponse(?:logic|net)|(?:-s|c)ap|acommunity)?|d(?:sto(?:rm[-_](?:diag|find|info|join)|ne-cpss)|wood-chat)|a(?:l(?:m-rusd|secure)|chout)|p(?:s(?:cmd|vc)|liweb|cmd)|l(?:oad-config|lpack|ief)|t(?:s(?:-ssl)?|rospect|p)|c(?:vr-r(?:c-dis)?c|ipe)|-(?:conn-proto|mail-ck)|gistrar|version|ftek|xecj|101|bol)|a(?:d(?:i(?:us(?:-(?:dynauth|acct))?|o(?:-(?:bc|sm))?|x)|w(?:are-rpm(?:-s)?|iz-nms-srv)|(?:an-htt|ec-cor)p|min(?:-port|d)|clientport|s(?:ec)?|pdf)|p(?:i(?:d(?:mq-(?:center|reg)|base|o-ip))?|-(?:service|listen|ip))?|i(?:d-(?:c[cds]|a[cm]|sf)|lgun-webaccl)|ve(?:n(?:t(?:bs|dm)|-r[dm]p)|hd)|t(?:io-adp|l)|qmon-pdu|w-serial|xa-mgmt|admin|sadv|zor|cf|mp)|t(?:-(?:(?:(?:devicemap|hel)p|classmanag|labtrack|view)er|event(?:-s)?|sound)|s(?:p(?:-alt|s)?|client|serv)|ps-d(?:iscovery|d-[mu]t)|c(?:-pm-port|m-sc104)|(?:mp-por|elne)t|raceroute|nt-[12]|ip)|s(?:v(?:p(?:-(?:encap-[12]|tunnel)|_tunnel)|d)|c(?:[ds]|-robot)|i(?:sysaccess|p)|-(?:pias|rmi)|m(?:tp|s)|qlserver|h-spx|f-1|ync|ap|om)|o(?:b(?:o(?:traconteur|e(?:da|r))|cad-lm|ix)|c(?:kwell-csp[12]|rail)|ute(?:match|r)|verlog|ketz|otd)|m(?:i(?:a(?:ctivation|ux)|registry)|o(?:nitor(?:[-_]secure)?|pagt)|t(?:server)?|lnk|pp|c)|d(?:m(?:net-(?:device|ctrl)|-tfs)|(?:b-dbs-dis|la)p|s(?:-i[bp]|2)?|c-wh-eos|rmshc|a)|i(?:c(?:ardo-lm|h-cp)|d(?:geway[12])?|m(?:f-ps|sl)|s(?:-cm|e)?|b-slm|png)|b(?:r-d(?:iscovery|ebug)|t-(?:wanopt|smc)|akcup[12]|lcheckd|system)|p(?:ki-rtr(?:-tls)?|-reputation|c2portmap|asswd|rt|i)|r(?:i(?:(?:[lm]w|fm)m|rtr|sat)|d?p|ac|h)|l(?:m(?:-(?:admin|disc))?|zdbase|p)|f(?:[abe]|i(?:d-rp1|le|o)|x-lm|mp)|u(?:s(?:b-sys-port|hd)|gameonline)|c(?:(?:c-ho)?st|ip-itu|ts|p)|(?:vs-isdn-dc|hp-iib|gt)p|n(?:m(?:ap)?|rp|a)|j(?:cdb-vcards|e)|(?:kb-osc|whoi)s|x(?:api|mon|e))|b(?:m(?:c(?:-(?:p(?:erf-(?:(?:mgr|s)d|agent)|atroldb)|(?:messag|report)ing|net-(?:adm|svc)|g(?:ms|rx)|data-coll|ctd-ldap|jmx-port|onekey|ar|ea)|_(?:ctd_ldap|patroldb)|patrol(?:agent|rnvu))|[ap]p|dss)|o(?:o(?:t(?:client|server|p[cs])|sterware|merang)|ks(?:[-_](?:serv[cm]|clntd))?|x(?:backupstore|p)|ard-(?:roar|voip)|inc-client|ldsoft-lm|rland-dsj|unzza|scap|nes)|a(?:c(?:k(?:up(?:-express|edge)|roomnet|burner)|ula-(?:[fs]d|dir)|net)|n(?:yan-(?:net|rpc|vip)|dwiz-system)|dm[-_]p(?:riv|ub)|rracuda-bbs|lour|tman|bel|se)|i(?:n(?:tec-(?:[ct]api|admin)|derysupport|gbang|kp)|o(?:link-auth|server)|t(?:forestsrv|speer)|s-(?:sync|web)|(?:ap-m)?p|imenu|m-pem|ff)|r(?:i(?:dgecontrol|ghtcore)|(?:oker[-_]servic)?e|c(?:m-comm-port|d)|u(?:tus|ce)|lp-[0123]|-channel|vread|dptc|f-gw|ain|p)|e(?:a(?:con-port(?:-2)?|rs-0[12])|s(?:erver-msg-q|api|s)|x-(?:webadmin|xr)|eyond(?:-media)?|yond-remote|rknet|orl)|l(?:ue(?:ctrlproxy|berry-lm|lance)|a(?:ck(?:board|jack)|ze)|ock(?:ade(?:-bpsp)?|s)|wnkl-port|p[12345]|izwow|-idm)|v(?:-(?:queryengine|smcsrv|[di]s|agent)|c(?:daemon-port|ontrol)|tsonar|eapi)|u(?:s(?:(?:chtromme|yca)l|iness|boy)|es[-_]service|llant-s?rap|ddy-draw)|f(?:d-(?:(?:multi-ct|contro)l|echo|lag)|-(?:master|game)|lckmgr|tp)|c(?:s(?:-(?:lmserv|brok)er|logc)?|tp(?:-server)?|inameservice|cp)|t(?:p(?:p2(?:sectrans|audctr1)|rjctrl)|s-(?:appserver|x73)|rieve)|s(?:fs(?:vr-zn-ssl|erver-zn)|quare-voip|pne-pcc)|p(?:c(?:p-(?:poll|trap)|d)|java-msvc|[mr]d|dbm)|h(?:oe(?:dap4|tty)|(?:fh|md)s|event|611)|n(?:et(?:(?:fil|gam)e)?|t-manager|gsync)|2(?:-(?:licens|runtim)e|n)|d(?:ir[-_]p(?:riv|ub)|p)|b(?:n-mm[cx]|ars)?|g(?:s-nsi|m?p)|-novative-ls|z(?:flag|r)|ytex|xp)|o(?:p(?:e(?:n(?:ma(?:il(?:pxy|ns|g)?|th)|v(?:ms-sysipc|pn)|(?:stack-|hp)id|(?:webne|por)t|nl(?:-voice)?|t(?:able|rac)|remote-ctrl|c(?:ore|m)|deploy|queue|flow)|quus-server)|s(?:e(?:c-(?:(?:el|le)a|u(?:aa|fp)|cvp|omi|sam)|ssion-(?:clnt|prxy|srvr))|w(?:manager|agent)|view-envoy|mgr)|t(?:i(?:ka-emedia|ma-vnet|wave-lm|logic)|o(?:host00[234]|control)|ech-port1-lm)|c(?:ua-(?:t(?:cp|ls)|udp)|-job-(?:start|track)|on-xps)|alis-r(?:bt-ipc|obot|dv)|us-services|net-smp|-probe|i-sock)|r(?:a(?:cle(?:-(?:(?:em|vp)[12]|oms)|n(?:et8cman|ames)|as-https)?|-(?:oap|lm)|srv)|b(?:i(?:x(?:-(?:c(?:fg-ssl|onfig)|loc(?:-ssl|ator))|d)|ter)|plus-iiop)|i(?:go-(?:native|sync)|on(?:-rmi-reg)?)|dinox-(?:server|dbase)|tec-disc)|m(?:a(?:-(?:[imr]lp(?:-s)?|dcdocbs|ulp)|bcastltkm|sgport)|s(?:-nonsecure|topology|contact|erv|dk)?|ni(?:vision(?:esx)?|link-port|sky)|(?:ginitialref|h)s|vi(?:server|agent))|v(?:s(?:am-(?:d-agen|mgm)t|essionmgr|db)|alarmsrv(?:-cmd)?|(?:hpa|bu|ob)s|-nnm-websrv|rimosdbman|[el]admgr|topmd|wdb)|n(?:e(?:home-(?:remote|help)|p-tls|saf)|t(?:obroker|ime)|base-dds|psocket|screen|mux)|s(?:m(?:-(?:appsrvr|oev)|osis-aeea)|p(?:f-lite)?|-licman|u-nms|b-sd|aut|dcp)|d(?:e(?:umservlink|tte-ftps?)|n(?:-castraq|sp)|bcpathway|i-port|mr|si)|c(?:e(?:-snmp-trap|ansoft-lm)|s(?:[-_][ac]mu|erver)|binder|topus|-lm)|b(?:j(?:ect(?:ive-dbc|manager)|call)|servium-agent|rpd|ex)|em(?:cacao-(?:websvc|jmxmp|rmi)|-agent)|f(?:fice(?:link2000|-tools)|sd)|i(?:d(?:ocsvc|sr)|rtgsvc|-2000)|t(?:p(?:atch)?|[lm]p|tp?|v)|w(?:amp-control|server|ms)|h(?:mtrigger|imsrv|sc)|gs-(?:client|server)|l(?:s[rv]|host)|2server-port|ob-ws-https?|a-system|utlaws)|f(?:i(?:le(?:net-(?:p(?:owsrm|eior|ch|a)|r(?:mi|pc|e)|obrok|nch|tms|cm)|(?:x-lpor|cas)t|sphere|mq)|r(?:e(?:monrcc|power|fox)|st(?:-defense|call42))|n(?:(?:isa|ge)r|d(?:viatv)?|le-lm|trx)|o(?:rano-(?:msg|rtr)svc|-cmgmt)|botrader-com|s(?:a-svc)?|veacross)|a(?:c(?:sys-(?:router|ntp)|ilityview|-restore|elink)|x(?:(?:portwin|stfx-)port|comservice|imum)|st(?:-rem-serv|lynx)|zzt-(?:admin|ptp)|t(?:pipe|serv)|(?:gordn|md)c|irview|renet)|j(?:i(?:ppol-(?:po(?:rt[12]|lsvr)|swrly|cnsl)|(?:tsuapp|nv)mgr|cl-tep-[abc])|s(?:v(?:-gssagt|mpor)|wapsnp)|mp(?:(?:jp|s)s|cm)|d(?:ocdist|mimgr)|(?:hpj|c)p|appmgrbulk|-hdnet)|c(?:p(?:-(?:(?:addr-srvr|srvr-inst)[12]|cics-gw1|udp))?|-(?:faultnotify|cli|ser)|i(?:s(?:-disc)?|p-port)|opys?-server|msys)|u(?:nk(?:-(?:l(?:icense|ogger)|dialout)|proxy)|jitsu-(?:d(?:tc(?:ns)?|ev)|mmpdc|neat)|script|trix)|l(?:a(?:sh(?:filer|msg)|menco-proxy)|(?:irtmitmi|ukeserve)r|r[-_]agent|orence|n-spx|exlm|crs|y)|t(?:p(?:-(?:agent|data)|s(?:-data)?)?|ra(?:pid-[12]|nhc)|s(?:ync|rv)|-role|nmtp)|o(?:r(?:esyte-(?:clear|sec)|tisphere-vm)|(?:togca|un)d|nt-service|liocorp|dms)|s(?:[er]|-(?:(?:agen|mgm)t|rh-srv|server|qos)|portmap|c-port)|m(?:p(?:ro-(?:(?:intern|fd)al|v6))?|sas(?:con)?|[tw]p)|r(?:ee(?:zexservice|civ)|c(?:-[hlm]p|s)|yeserv|onet)|e(?:itianrockey|rrari-foam|booti-aw|mis)|f(?:-(?:lr-port|annunc|fms|sm)|server)|x(?:aengine-net|(?:upt)?p)|5-(?:globalsite|iquery)|g-(?:sysupdate|fps|gip)|p(?:(?:o-fn|ram)s|itp)|dt(?:-rcatp|racks)|net-remote-ui|yre-messanger|h(?:sp|c)|ksp-audit)|l(?:i(?:s(?:p(?:-(?:con(?:trol|s)|data)|works-orb)|t(?:crt-port(?:-2)?|mgr-port))|n(?:k(?:test(?:-s)?|name)?|ogridengine|x)|ebdevmgmt[-_](?:[ac]|dm)|ve(?:stats|lan)|mnerpressure|censedaemon|berty-lm|psinc1?|onhead|ght)|a(?:n(?:s(?:urveyor(?:xml)?|chool(?:-mpt)?|erver|ource)|rev(?:server|agent)|900[-_]remote|yon-lantern|messenger|dmarks|ner-lm)|(?:(?:unchbird|venir)-l)?m|zy-ptop|es-bf|plink|brat)|o(?:c(?:us-(?:disc|con|map)|alinfosrvr|kstep)|n(?:talk-(?:urgnt|norm)|ewolf-lm|works2?)|t(?:us(?:mtap|note)|105-ds-upd)|rica-(?:out|in)(?:-sec)?|a(?:probe|dav)|fr-lm|gin)|m(?:-(?:(?:(?:webwatch|sserv)e|instmg)r|perfworks|dta|mon|x)|s(?:ocialserver)?|d?p|cs)|d(?:s(?:-d(?:istrib|ump)|s)|oms-m(?:gmt|igr)|ap(?:-admin|s)?|gateway|x?p)|v(?:-(?:f(?:rontpanel|fx)|auth|pici|not|jc)|ision-lm)|s(?:i-(?:raid-mgm|bobca)t|3(?:bcast)?|p-ping|[dt]p)|nv(?:ma(?:ilmon|ps)|console|poller|status|alarm)|b(?:[fm]|c-(?:watchdog|control|measure|sync))|3(?:-(?:h(?:bmon|awk)|ranger|exprt)|t-at-an)|e(?:(?:croy-vic|oi)p|ecoposserver|gent-[12])|l(?:m(?:-(?:pass|csv)|nr)|surfup-https?|rp)|2(?:c-(?:d(?:ata|isc)|control)|tp|f)|t(?:p(?:-deepspace)?|c(?:tc|ud)p)|p(?:srecommender|ar2rrd|cp|dg)|(?:5nas-parcha|jk-logi)n|u(?:mimgrd|t[ac]p|pa)|c(?:m-server|s-ap)|r(?:s-paging|p)|-acoustics|xi-evntsvc|kcmserver|yskom|htp)|h(?:p(?:-(?:s(?:e(?:ssmon|rver)|an-mgmt|c[aio]|tatus)|d(?:ataprotect|evice-disc)|p(?:dl-datastr|xpib)|web(?:admin|qosdb)|c(?:ollector|lic)|(?:nnm-dat|rd)a|hcip(?:-gwy)?|managed-node|3000-telnet|alarm-mgr)|v(?:mm(?:control|agent|data)|irt(?:ctrl|grp)|room)|s(?:s(?:-ndapi|mgmt|d)|tgmgr2?)|o(?:ms-(?:dps|ci)-lstn|cbus)|i(?:dsa(?:dmin|gent)|od)|p(?:ronetman|pssvr)|(?:blade|dev)ms)|a(?:cl-(?:p(?:robe|oll)|monitor|[gq]s|local|test|cfg|hb)|(?:r(?:t-i)?|gel-dum)?p|ipe-(?:discover|otnk)|-cluster|ssle|wk|o)|e(?:a(?:lth(?:-(?:polling|trap)|d)|rtbeat|thview)|r(?:odotus-net|e-lm|mes)|l(?:lo(?:-port)?|ix)|cmtl-db|xarc|ms)|i(?:[dq]|p(?:(?:erscan-i|pa)d|-nat-t)|(?:[cn]|sli)p|ve(?:stor|p)|gh-criteria|llrserv)|y(?:per(?:(?:wave-is|i)p|scsi-port|cube-lm|-g)|brid(?:-pop)?|d(?:ap|ra)|lafax)|t(?:tp(?:-(?:(?:rpc-ep|w)map|(?:mgm|al)t)|s(?:-wmap)?|x)?|uilsrv|rust|cp)|o(?:me(?:portal-web|steadglory)|u(?:dini-lm|ston)|tu-chat|stname|nyaku)|323(?:gate(?:disc|stat)|hostcall(?:sc)?|callsigalt)|2(?:250-annex-g|48-binary|63-video|gf-w-2m)|r(?:d-n(?:s-disc|cs)|pd-ith-at-an|i-port)|d(?:e-lcesrvr-[12]|l-srv|ap)|s(?:rp(?:v6)?|l-storm|-port)|u(?:b-open-net|ghes-ap|sky)|hb-(?:handheld|gateway)|l(?:(?:serve|ibmg)r|7)|fcs(?:-manager)?|b(?:-engine|ci)|mmp-(?:ind|op)|k(?:s-lm|p)|cp-wismar|nmp?)|v(?:i(?:s(?:i(?:on(?:[-_](?:server|elmd)|pyramid)|cron-vs|net-gui|tview)|t(?:ium-share|a-4gl)|d)|d(?:e(?:o(?:-activmail|beans|tex)|te-cipc)|s-avtp|igo)?|r(?:tual(?:-(?:places|time)|tape|user)|prot-lm)|p(?:era(?:-ssl)?|remoteagent)|ziblebrowser|talanalysis|nainstall|eo-fe)|e(?:r(?:i(?:tas(?:-(?:u(?:dp1|cl)|vis[12]|tcp1|pbx)|_pbx)|smart)|s(?:a(?:-te|tal)k|iera)|gencecm|acity|onica)|(?:stasdl|ttc)p|nus(?:-se)?|mmi)|r(?:t(?:s(?:-(?:a(?:uth|t)-port|ipcserver|registry|tdd)|trapserver)|l-vmf-(?:ds|sa)|p)?|(?:xpservma|p)n|(?:commer|a)ce)|s(?:a(?:mredirector|t-control|iport)|i(?:-omega|admin|net|xml)|(?:econnecto|-serve)r|(?:nm-agen|ta)t|(?:lm|c)p|pread)|a(?:t(?:-control|ata|p)?|(?:-pac|ult)base|(?:lisys-l|prt)m|cdsm-(?:app|sws)|ntronix-mgmt|radero-[012]|d)|o(?:caltec-(?:admin|phone|wconf|gold|hos)|(?:fr-gatewa|lle)y|ispeed-port|p(?:ied)?|xelstorm)|p(?:a(?:(?:-dis)?c|d)?|p(?:s-(?:qu|vi)a)?|(?:[2j]|m-ud)p|sipport|v[cd]|nz)|c(?:s(?:-app|cmd)|net-link-v10|om-tunnel|hat|rp|e)|m(?:(?:ware-fd|ode)m|svc(?:-2)?|pwscs|net|rdp)|t(?:s(?:-rpc|as)|r-emulator|u-comms|-ssl|p)|n(?:s(?:-tp|str)|wk-prapi|etd|as|yx)|ytalvault(?:(?:brt|vsm)p|pipe)|x(?:(?:-auth-|crnbu)port|lan)|f(?:bp(?:-disc)?|mobile|o)|vr-(?:control|data)|(?:-one-sp|q)p|d(?:mplay|ab)|2g-secc|lsi-lm|ulture|5ua|hd)|w(?:a(?:p-(?:wsp(?:-(?:wtp(?:-s)?|s))?|push(?:-https?|secure)?|vca(?:rd|l)(?:-s)?)|t(?:c(?:h(?:do(?:c(?:-pod)?|g-nt)|me-7272)|omdebug)|ershed-lm|ilapp)|g(?:o-(?:io-system|service)|-service)|r(?:m(?:spotmgmt|ux)|ehouse(?:-sss)?)|(?:asclust|nscal)er|cp|fs)|i(?:n(?:p(?:o(?:planmess|rt)|haraoh|cs)|d(?:(?:rea|l)m|d(?:lb|x)|b)|s(?:hadow(?:-hd)?)?|install-ipc|jaserver|qedit|fs|rm)|l(?:kenlistener|ly)|m(?:axasncp|sic|d)|(?:egan|zar|re)d|p-port|bukey|free)|e(?:b(?:m(?:a(?:chine|il-2)|ethods-b2b)|s(?:phere-snmp|ter|m)|a(?:dmstart|ccess)|(?:2ho|ya)st|(?:phon|ti)e|emshttp|objects|login|data)|ste(?:c-connect|ll-stats)|a(?:ndsf|ve)|llo)|s(?:m(?:-server(?:-ssl)?|ans?|lb)|d(?:api(?:-s)?|l-event)|(?:o2esb-consol|pip)e|s(?:comfrmwk|authsvc)|(?:-discover|icop)y|ynch)|m(?:e(?:re(?:ceiv|port)ing|distribution)|(?:s-messeng|lserv)er|c-log-svc)|h(?:o(?:s(?:ockami|ells)|is(?:\+\+|pp)|ami)?|erehoo|isker)|or(?:ld(?:fusion[12]|scores|-lm)|kflow)|w(?:w(?:-(?:ldap-gw|http|dev))?|iotalk)|r(?:s(?:[-_]registry|pice)|itesrv)|(?:ta-ws(?:p-wt)?p-|p(?:age|g))s|v-csp-(?:sms(?:-cir)?|udp-cir)|bem-(?:exp-https|https?|rmi)|c(?:(?:backu|p)p|r-remlib)|f(?:(?:remotert)?m|c)|(?:g-netforc|usag)e|k(?:stn-mon|ars)|l(?:anauth|bs)|nn6(?:-ds)?|ysdm[ac]|xbrief)|g(?:a(?:l(?:axy(?:-(?:network|server)|7-data|4d)|ileo(?:log)?)|m(?:e(?:smith-port|lobby|gen1)|mafetchsvr)|d(?:getgate[12]way|ugadu)|ndalf-lm|t-lmd|rcon|c?p|ia)|e(?:n(?:i(?:e(?:-lm)?|sar-port|uslm)|e(?:ralsync|ous|ve)|rad-mux|stat)|o(?:gnosis(?:man)?|locate)|mini-lm|arman|rhcs)|r(?:i(?:d(?:gen-elmd|-alt)?|ffin|s)|o(?:ove(?:-dpp)?|upwise)|a(?:decam|phics)|f-port|cm?p|ubd)|l(?:o(?:b(?:al-(?:cd-port|dtserv|wlink)|e(?:cast-id)?|msgsvc)|gger)|(?:ish)?d|rpc|bp)|s(?:i(?:(?:dca|ft)p|gatekeeper)?|m(?:(?:p-anc|ta)p|s)|s-(?:xlicen|http)|akmp)|t(?:p-(?:control|user)|rack-(?:server|ne)|e(?:gsc-lm|-samp)|-proxy|aua)|d(?:s(?:(?:-adppiw)?-|_)db|o(?:map|i)|rive-sync|bremote|p-port)|o(?:(?:ldleaf-licma|-logi)n|ahead-fldup|todevice|pher)|i(?:(?:ga-pocke|s)?t|latskysurfer|op(?:-ssl)?|nad)|w(?:-(?:call-port|asv|log)|(?:en-sony|h)a)?|p(?:rs-(?:cube|data|sig)|pitnp|fs|sd)|n(?:u(?:tella-(?:rtr|svc)|net)|tp)|c(?:m(?:onitor|-app)|-config|sp)|b(?:mt-stars|s-s[mt]p|jd816)|x(?:s-data-port|telmd)|m(?:rupdateserv|mp)|u(?:ttersnex|ibase)|v(?:-(?:pf|us)|cp)|g(?:f-ncp|z)|-talk|2tag|hvpn|5m|f)|u(?:n(?:i(?:s(?:ys-(?:eportal|lm)|ql(?:-java)?)|v(?:erse[-_]suite|-appserver|ision)|fy(?:-(?:adapter|debug)|admin)?|(?:c(?:ontro|al)|mobilectr)l|(?:x-stat|zens)us|hub-server|data-ldm|keypro|port|eng|te)|bind-cluster|[eo]t|do-lm|glue)|p(?:s(?:-(?:onlinet|engine)|notifyprot|triggervsw)?|notifyps?|grade)|l(?:t(?:r(?:a(?:seek-http|bac)|ex)|imad)|p(?:net)?|istproc)|d(?:p(?:-sr-port|radio)|r(?:awgraph|ive)|t[-_]os)|s(?:-(?:(?:sr|g)v|cli)|icontentpush|er-manager)|a(?:(?:-secureagen|iac)t|(?:dt|a)c|(?:rp|c)s)|u(?:cp(?:-(?:rlogin|path))?|idgen)|r(?:[dm]|(?:ld-por|bisne)t)|t(?:(?:mp[cs]|c)d|sftp|ime)|b(?:-dns-control|roker|xd)|c(?:entric-ds|ontrol)|f(?:astro-instr|mp)|m(?:m-port|sp?|a)|o(?:host|rb)|-dbap|ec|is)|x(?:m(?:l(?:i(?:nk-connect|pcregsvc)|tec-xmlmail|rpc-beep|blaster)|p(?:p-(?:client|server|bosh)|cr-interface|v7)|query|api|ms2|cp|sg)|n(?:s-(?:c(?:ourier|h)|auth|mail|time)|m(?:-(?:clear-text|ssl)|p)|ds)|i(?:n(?:u(?:expansion[1234]|pageserver)|g(?:mpeg|csm))|ostatus|ip|c)|s(?:s(?:-srv)?-port|-openstorage|(?:msv|yn)c|ip-network|erveraid)|p(?:r(?:int-server|tld)|(?:ane)?l|ilot)|a(?:ct-backup|ndros-cms|dmin|p-ha|api)|2(?:5-svc-port|-control|e-disc)|y(?:brid-(?:cloud|rt)|plex-mux)|t(?:r(?:eamx|ms?)|lserv|gui)|d(?:(?:mc|t)p|s(?:xdm)?|as)|r(?:pc-registry|ibs|l)|(?:ecp-nod|9-icu)e|(?:xnetserve|fe?)r|o(?:-wave|raya|ms)|-bone-(?:api|ctl)|(?:kotodrc|vtt)p|(?:gri|qos)d|500ms|box|11)|k(?:e(?:r(?:beros(?:-(?:adm|iv))?|mit)|ys(?:(?:erve|rv)r|hadow)|ntrox-prot)|a(?:sten(?:chasepad|xpipe)|(?:za|n)a|r2ouche|0wuc|li)|o(?:ns(?:hus-lm|pire2b)|pek-httphead|fax-svr)|i(?:n(?:g(?:domsonline|fisher)|k)|osk|tim|s)|f(?:tp(?:-data)?|xaclicensing|server)|t(?:i(?:-icad-srvr|ckets-rest)|elnet)|r(?:b5(?:gatekeeper|24)|yptolan)|v(?:-(?:server|agent)|m-via-ip)|m(?:e-trap-port|scontrol|ip)|(?:jtsiteserve|z-mig)r|3software-(?:cli|svr)|p(?:asswd|n-icw|dp)|s(?:ysguard|hell)|w(?:db-commn|tc)|l(?:ogin|io)|yoceranetdev|ca-service|d(?:net|m)|net-cmp|-block)|j(?:a(?:u(?:gsremotec-[12]|s)|m(?:serverport|link)|xer-(?:manager|web)|cobus-lm|nus-disc|leosnd|rgon)|e(?:t(?:form(?:preview)?|cmeserver|stream)|ol-nsd[dt]p-[1234]|diserver|rand-lm|smsjc)|o(?:(?:ajewelsuit|urne)e|mamqmonitor|ltid|ost)|m(?:(?:q-daemon-|b-cds)[12]|act[356]|evt2|s)|d(?:l-dbkitchen|atastore|mn-port|p-disc)|w(?:(?:alk)?server|pc(?:-bin)?|client)|b(?:oss-iiop(?:-ssl)?|roker)|v(?:l-mactalk|client|server)|t(?:400(?:-ssl)?|ag-server)|i(?:ni-discovery|be-eb)|-(?:l(?:an-p|ink)|ac)|p(?:egmpeg|rinter|s)|u(?:xml-port|te)|licelmd|stel|cp)|q(?:u(?:e(?:st(?:-(?:d(?:ata-hub|isc)|agent|vista)|db2-lnchr|notify)|ueadm)|a(?:(?:sar-serve|ntasto)r|rtus-tcl|ilnet|ddb|ke)|ick(?:booksrds|suite)|o(?:tad|sa)|bes)|s(?:net-(?:(?:assi|work)st|trans|cond|nucl)|m-(?:remote|proxy|gui)|oft)|t(?:(?:ms-bootstra)?p|-serveradmin)|ip-(?:(?:audu|qdhc)p|login|msgd)|b(?:-db-server|ikgdp|db)|f(?:t(?:est-lookup)?|p)|(?:db2servic|3ad|wav)e|o(?:t(?:ps|d)|-secure)|admif(?:event|oper)|n(?:xnetman|ts-orb)|p(?:asa-agent|tlmd)|m(?:[qt]p|video)|(?:en)?cp|ke-llc-v3|55-pcc|rh|vr)|z(?:e(?:n(?:ginkyo-[12]|-pawn|ted)|p(?:hyr-(?:clt|srv|hm))?)|a(?:bbix-(?:trapper|agent)|nnet|rkov)|i(?:(?:on-l|co)m|gbee-ips?|eto-sock)|(?:ymed-zp|oomc|m)p|firm-shiprush3|se(?:cure|rv)|-wave(?:-s)?|39[-.]50|re-disc)|3(?:com(?:-(?:n(?:jack-[12]|et-mgmt|sd)|webview|tsmux|amp3)|faxrpc|netman)|par-(?:mgmt(?:-ssl)?|rcopy|evts)|(?:gpp-cbs|exm)p|d(?:-nfsd|s-lm)|l(?:-l1|ink)|m-image-lm)|4(?:-tieropm(?:cli|gw)|talk)|9(?:14c(?:\/|-)g|pfs)|y(?:o-mai|aw)n|802-11-iapp|1ci-smcs|2ping|6a44)(?![-])\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_PORTS_DCCP = qr{\b(?<!-)(?:1(?:02[12]|113)|500[45]|4556|6514|9)\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_PORTS_SCTP = qr{\b(?<!-)(?:2(?:9(?:1(?:6[89]|18)|0[45]|4[45])|0(?:0?49)?|(?:547)?1|2(?:25)?)|5(?:0(?:6[01]|9[01])|91[0123]|67[25]|445|868)|3(?:64(?:4[34]|[12]2)|86[348]|097|565)|1(?:1(?:99[789]|67)|02[12]|4001|79)|4(?:7(?:39|40)|(?:33|4)3|502)|9(?:90[012]|08[24])?|8(?:471|0)|670[456]|7626)\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_PORTS_TCP = qr{\b(?<!-)(?:1(?:1(?:1(?:[234589]|0[34569]?|6[12345]?|7[2345]?|1[012]?)?|3(?:[034589]|2[01]?|19?|67?|71?)?|7(?:[0134678]|2[03]?|51?|96?)?|2(?:[23456789]|0[128]?|1?1)?|0(?:[1234678]|0[01]?|9?5)?|6(?:[13456789]|0?0|23?)?|8(?:[012345689]|76?)?|9(?:[012345789]|67?)?|4(?:[012345679]|89?)|5\d?)?|0(?:1(?:0[012347]?|1[034567]|6[012]|2[89])?|0(?:0[012345789]?|5[015]|8[01]|10)|8(?:[1234579]|0[059]?|60?|80?)?|2(?:[129]|0[01]|52?|60?|88)?|5(?:[012356789]|4[01234]?)?|6(?:[012456789]|31?)?|9(?:[012345678]|90?)?|3(?:[3456789]|21)?|4\d?|7\d?)|8(?:1(?:[1245679]|8[1234567]?|04?|36?)?|2(?:[01235789]|4[123]?|62?)?|6(?:[012456789]|3[45]?)?|8(?:[012345679]|8[18]?)?|0(?:[123456789]|0?0)?|4(?:[012345789]|63?)?|7(?:[012345789]|69?)?|9[012346789]?|3\d?|5\d?)?|9(?:0(?:[13456789]|0[07]?|20?)?|5(?:[01256789]|4[01]?|39?)?|4(?:[023456789]|1[012]?)?|1(?:[012345678]|9[14]?)?|3(?:[02345678]|15?|98?)?|9(?:[012345678]|9[89]?)?|2(?:[012345679]|83?)?|6\d?|7\d?|8\d?)?|3(?:8(?:[0345678]|2[0123]?|1[89]?|94?)?|7(?:[01345679]|2[0124]?|8[2356]?)?|2(?:[03456789]|1[678]?|2[34]?)?|9(?:[01456789]|29?|30?)?|1(?:[012345789]|60?)?|4(?:[123456789]|0?0)?|0\d?|3\d?|5\d?|6\d?)?|6(?:3(?:[234579]|6[0178]?|1[01]?|09?|84?)?|9(?:[1234678]|9[12345]?|0?0|50?)?|0(?:[13456789]|0[012]?|2[01]?)?|1(?:[012345789]|6[12]?)?|6(?:[023456789]|19?)?|2\d?|4\d?|5\d?|7\d?|8\d?)|2(?:0(?:[23456789]|0[012345678]?|1[023]?)?|3(?:[1356789]|0[02]?|2[12]?|45?)?|1(?:[134589]|09?|21?|68?|72?)?|7(?:[012346789]|53?)?|8(?:[012345789]|65?)?|2\d?|4\d?|5\d?|6\d?|9\d?)|7(?:2(?:[0456789]|2[01]?|3[45]?|19?)?|7(?:[0134689]|5[456]?|29?|7?7)?|1(?:[012345679]|8[45]?)?|5(?:[12346789]|0?0|5?5)?|0(?:[123456789]|07?)?|8[012456789]?|3\d?|4\d?|6\d?|9\d?)?|5(?:0(?:[123456789]|0[02]?)?|3(?:[01235789]|45?|63?)?|5(?:[012346789]|5?5)?|6(?:[012345789]|60?)?|7(?:[012356789]|40?)?|9(?:[012345678]|9?9)?|2[012345679]?|1\d?|4\d?|8\d?)|4(?:1(?:[01236789]|4[1259]?|5[04]?)?|0(?:[12456789]|0[01]?|3[34]?)?|9(?:[02456789]|3[67]?)?|2(?:[012346789]|50?)?|4(?:[023456789]|14?)?|3\d?|5\d?|6\d?|7\d?|8\d?))?|2(?:2(?:3(?:[1236789]|4[37]?|5[01]?|05?)?|0(?:[123456789]|0[012345]?)?|1(?:[013456789]|2[58]?)?|2(?:[01345689]|2?2|73?)?|5(?:[0124678]|37?|5?5)|7(?:[012345789]|63?)|8(?:[123456789]|0?0)|9(?:[012346789]|51?)|4\d?|6\d)?|4(?:0(?:[123456789]|0[0123456]?)|6(?:[01234569]|7[678]?|80?)?|3(?:[01345679]|21?|86?)?|2(?:[01235789]|4[29]?)?|4(?:[012345789]|65?)?|5(?:[012346789]|54?)?|7(?:[012346789]|54?)?|9(?:[013456789]|2?2)|8\d?|1\d)|0(?:0(?:[256789]|0[01235]?|4[689]?|1[34]?|34?)?|2(?:[13456789]|02?|2?2)?|1(?:[012345789]|67?)?|4(?:[012345679]|80?)?|6(?:[012345689]|70?)?|9(?:[012345678]|9?9)?|3\d?|5\d?|7\d?|8\d?)?|3(?:0(?:[12346789]|0[012345]?|53?)|4(?:[12346789]|0[012]?|5[67]?)|3(?:[012456789]|3?3)|5(?:[012356789]|46?)|6[012345678]|8[123456789]|7[0123456]|1\d|2\d|9\d)?|6(?:2(?:[12345789]|6[0123]?|08?)?|4(?:[012345679]|8[679]?)?|0(?:[123456789]|0?0)?|1(?:[012456789]|3?3)?|8[013456789]?|9[012456789]?|3\d?|5\d?|6\d?|7\d?)|7(?:3(?:[012356789]|45?)|4(?:[012356789]|42?)|5(?:[123456789]|04?)|7(?:[012345679]|82?)|8(?:[012345689]|76?)|9(?:[01235678]|9?9)|1\d?|0\d|2\d|6\d)?|5(?:9(?:[123456789]|0[0123]?)?|0(?:[123456789]|0\d?)|6(?:[123456789]|04?)?|7(?:[012345678]|93?)?|5(?:[012345689]|76?)|1\d|2\d|3\d|4\d|8\d)?|1(?:8(?:[12356789]|4[56789]?|0?0)?|5(?:[01234678]|5[34]?|90?)?|0(?:[23456789]|0?0|10?)?|9[0123789]?|1\d?|2\d?|3\d?|4\d?|6\d?|7\d?)?|8(?:0(?:[123456789]|0[01]?)?|2(?:[1236789]|0?0|40?)?|7[012456789]?|1\d?|3\d?|4\d?|6\d?|5\d|8\d|9\d)|9(?:1(?:[012345789]|67?)|9(?:[012345678]|9?9)|2[012346789]|0\d|3\d|4\d|5\d|6\d|7\d|8\d)?)?|3(?:2(?:7(?:[01234589]|7[01234567]?|6[789]?)|8(?:[2345678]|01?|1?1|96?)|6(?:[012456789]|3[56]?)|0(?:[012456789]|34?)?|2(?:[012356789]|49?)?|4(?:[012345679]|83?)?|1\d?|3\d?|5\d|9\d)|1(?:4(?:[2346789]|0?0|16?|57?)?|6(?:[01345679]|20?|85?)?|9(?:[012356789]|4[89]?)?|0(?:[013456789]|20?)?|7(?:[012345789]|65?)?|2[012345789]?|1\d?|3\d?|5\d?|8\d?)?|3(?:3(?:[012456789]|3[134]?)?|1(?:[013456789]|23?)|4(?:[012456789]|34?)|6(?:[012346]|56?)|0[23456789]|7[23456789]|2[016789]|5\d|8\d|9\d)?|4(?:9(?:[01234579]|6[234]?|80?)?|3(?:[012345689]|7[89]?)|5(?:[012345789]|67?)?|2(?:[012356789]|49?)|0[01256789]|4\d?|6\d?|7\d?|8\d?|1\d)|6(?:0(?:[123456789]|01?)?|5(?:[013456789]|24?)?|6(?:[123456789]|02?)?|8(?:[012345789]|65?)?|9[01256789]?|1\d?|2\d?|3\d?|4\d?|7\d?)|5(?:0(?:[123456789]|0[0123456]?)?|3(?:[012346789]|5[4567]?)?|4[012345789]?|1\d?|2\d?|5\d?|6\d?|7\d?|8\d?|9\d?)|0(?:0(?:[123456789]|0[0123]?)|2(?:[012345789]|60?)|9(?:[0134568]|9?9)?|8\d?|1\d|3\d|4\d|5\d|6\d|7\d)|8(?:2(?:[123456789]|0[123]?)?|8(?:[12345789]|0?0|65?)?|0\d?|1\d?|3\d?|4\d?|5\d?|6\d?|7\d?|9\d?)?|7(?:4(?:[01234569]|75?|83?)?|6(?:[01234789]|54?)?|0\d?|1\d?|2\d?|3\d?|5\d?|7\d?|8\d?|9\d?)?|9(?:6(?:[012345679]|81?)?|9[012356789]?|0\d?|1\d?|2\d?|3\d?|4\d?|5\d?|7\d?|8\d?)?)?|4(?:3(?:4(?:[01256789]|4[01]?|39?)?|1(?:[012346]|8[89]|9[01])?|0(?:[123456789]|0?0)?|2(?:[023456789]|10?)?|9[012356]?|3[013]?|6[089]?|5\d?|7\d?|89?)?|4(?:[67]|5(?:[01234678]|53?)?|3(?:[013]|2[123]?)?|4(?:[2356789]|4?4)?|8(?:[4567]|1?8)?|1(?:[01]|23)?|2[56789]?|9(?:00)?|0\d?)?|8(?:0(?:[123]|0[012345]?|49|50)?|6(?:[78]|1?9|53)?|5(?:[01]|56)?|1(?:2[89])?|7[01679]?|8[0345]?|3[789]?|9[49]?|4\d?|27?)?|1(?:7(?:[01245678]|9[4567]?)?|1(?:[03456789]|1?1|21?)?|2[123456789]?|4[012356789]?|9[0239]?|0\d?|3\d?|5\d?|6\d?|8\d?)?|0(?:8(?:[01235789]|4[123])?|0(?:[123456789]|0?0)?|4(?:[12345679]|04?)?|7[012345689]?|1\d?|2\d?|3\d?|5\d?|6\d?|9\d?)|5(?:[12]|9(?:[01345789]|6?6)?|0(?:0[01]?|45|54)?|6(?:[3689]|78?)?|5[01234569]?|8(?:2[45])?|4[56789]?|3[5678]?|70?)?|7(?:[179]|0(?:[1234]|0[01]?)?|8(?:[4678]|0[68])?|5(?:[0123]|57)?|4[0123459]?|3[013789]?|6(?:24)?|2[578]?)?|9(?:[23]|0(?:[12]|0?0)?|8[456789]?|1[2345]?|4[0129]?|5[0123]?|9[019]?|69?|70?)?|6(?:[1234]|9(?:[012]|9[89])?|0[01234]?|5[89]?|6\d?|7\d?|8\d?)?|2(?:[012346789]|5(?:0[89]|10)?)?)|5(?:0(?:5[012345679]?|8[0123456]?|4[234589]?|7[012345]?|1[01235]?|9[349]?|3[02]?|0\d?|2\d?|6\d?)?|2(?:2[12345678]?|3[234567]?|0[01239]?|5[0123]?|4[589]?|6[459]?|7[012]?|8[012]?|9[89]?|1)?|1(?:5[01234567]?|6[12345678]?|9[0123456]?|1[12457]?|0[0123]?|3[3457]?|4[56]?|20?|72?|8)|7(?:4[12345678]?|1[3456789]?|8[01235]?|6[6789]?|5[057]?|7[017]?|2\d?|30?|93?|0)|3(?:[378]|1[02345678]?|5[23456789]?|6[0123]?|4[349]?|9[789]?|2[01]?|0\d?)?|5(?:[1234]|0[0123456]?|8[012345]?|5[34567]?|6[6789]?|7[3459]?|9[789]?)?|4(?:[789]|3[012345]?|6[12345]?|5[3456]?|4[35]?|0\d?|1\d?|2\d?)?|6(?:[56]|0[012345]?|8[0189]?|2[789]?|9[36]?|3\d?|7\d?|18?|46?)?|9(?:[23457]|8[456789]?|1[0123]?|9[0129]?|6[389]?|0?0)|8(?:[0237]|1[34]?|6[38]?|42?|5?9|83?)?)?|6(?:6(?:2[012345678]?|6(?:5-6669)?|7[012389]?|0[012]?|5[356]?|8[789]?|19?|32?|40?|97?)?|5(?:[23]|0[012356789]?|4[34789]?|1[0345]?|8[0123]?|5[018]?|6[68]?|79?)?|3(?:2[012456]?|4[3467]?|0[016]?|1[567]?|5[05]?|8[29]?|60?|70?|90?|3)?|1(?:[789]|1[01234567]?|2[1234]?|6[0123]?|3[03]?|0\d?|4\d?|59?)?|0(?:[12345]|0(?:0-6063)?|7[01234567]?|6[45689]?|8[45678]?|9?9)|7(?:[2345]|8[56789]?|7[0178]?|0[123]?|6[789]?|1[45]?|9[01]?)?|4(?:[069]|4[3456]?|1[789]?|2[01]?|5[56]?|8\d?|32?|71?)?|9(?:[1278]|6[1234569]?|9[789]?|3[56]?|01?|46?|51?)?|2(?:[13789]|4[1234]?|5[123]?|6[789]?|0?0|2?2)?|8(?:[279]|4[12]?|01?|17?|31?|50?|68?|8?8)?)|7(?:7(?:[156]|2[04567]?|4[12347]?|0[078]?|7[789]?|8[1679]|9[4789]|3[48]?)|0(?:[456]|1[01234589]?|2[012345]?|7[013]?|3[01]|0\d?|9?9|80)?|4(?:2[16789]?|7[134]?|0[012]|1[01]?|3[017]|43?|91?|8)?|5(?:[239]|4[23456789]?|0[0189]?|6[0369]|1[01]?|8?8|70)|6(?:[015]|7[234567]?|2[46789]?|3[013]?|8[09]|48?|97?)?|1(?:[1345]|6[123456789]|7[01234]|2[189]?|0[01]?)?|2(?:7[23456789]|8[0123]|2[789]|0[01]|3[67]|62|9)?|9(?:0[0123]|8[012]|3[23]|6[27]|9[79]|13|79)?|8(?:0[01]?|4[567]|7[018]|8[07]|10|69)?|3(?:[01]|9[123457]|65)?)?|8(?:0(?:5[123456789]|0[012358]?|8[0123678]|2[01256]|4[0234]|3[234]|9[17]|19?|66|74)?|1(?:9[12459]|0[012]?|1[5678]|2[1289]|8[1234]|3[012]|6[012]|48|53)|4(?:0[012345]|7[01234]?|4[2345]|1[567]|5[07]|8)?|3(?:7[6789]|0[01]?|2[01]?|8[03]|13?|51|3)?|6(?:1[012345]?|6[56]|8[68]|0?0|75|99|2)?|7(?:(?:3?|9)3|6[3456]|7[08]|8[67]|11|50)|9(?:1[0123]|9[0189]|0[01]|5[34]|37|89)?|2(?:0[0145678]|9[234]?|80?|30|43|76)?|8(?:8[01389]?|9[012349]|0[04]|73?|6)?|5(?:0[012]|5[45]|67)?)|9(?:0(?:2[0123456]?|8[03456789]|0[01289]?|9[0123]|5[01]|10?|3)?|9(?:5[012345]?|0[09]?|8[78]?|9\d?|1?1|25?|6?6|78?|3)?|2(?:1[01234567]|8[0123457]|9[2345]|7[89]|0\d|22|55)?|1(?:0[01234567]?|6[01234]|2[23]?|19?|31?|91)?|3(?:8[0789]|4[346]|9[067]|0[06]|1[28]|21|74)?|6(?:1[24678]|6[678]|2[89]|3[01]|9[45]|[04]0)?|5(?:9[23456789]|3[56]|00|55)?|8(?:0[012]|7[56]|8[89]|98?)?|4(?:0[012]|4[345]|18|50)?|7(?:5[03]|00|47|62)?)?)\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_PORTS_UDP = qr{\b(?<!-)(?:1(?:1(?:1(?:[234589]|6[12345]?|0[68]?|1[12]?|71?)?|3(?:[034589]|2[01]?|19?|67?|71?)?|7(?:[0134678]|2[03]?|51?|96?)?|2(?:[23456789]|0[18]?|1?1)?|0(?:[1234678]|0[01]?|9?5)?|8(?:[012345689]|7[67]?)?|6(?:[123456789]|0?0)?|9(?:[012345789]|67?)?|4(?:[012456789]|30?)|5\d?)?|0(?:1(?:0[012347]?|1[0134567]|6[012]|28)?|8(?:[234579]|0[05]?|10?|60?|80?)?|0(?:0[0123789]?|5[01]|8[01]|23)|5(?:[12356789]|4[01234]?|0?0)?|2(?:[1279]|0[01]|52?|60?|88)?|4(?:[012456789]|39?)?|9(?:[012345678]|90?)?|3[3456789]?|6\d?|7\d?)|9(?:5(?:[01256789]|4[01]?|39?)?|4(?:[023456789]|1[012]?)?|0(?:[123456789]|0[07]?)?|1(?:[012345678]|9[14]?)?|3(?:[02345678]|15?|98?)?|2(?:[012345679]|83?)?|7(?:[012345679]|8?8)?|9(?:[012345678]|9?9)?|6\d?|8\d?)?|8(?:1(?:[012345679]|8[1234567]?)?|2(?:[01235789]|41?|62?)?|6(?:[012456789]|3[45]?)?|8(?:[012345679]|8[18]?)?|0(?:[123456789]|0?0)?|4(?:[012345789]|63?)?|7(?:[012345789]|69?)?|9[012346789]?|3\d?|5\d?)?|3(?:7(?:[01345679]|2[0124]?|8[2356]?)?|8(?:[0345678]|2[012]?|1[89]?|94?)?|2(?:[03456789]|1[678]?|2[34]?)?|1(?:[012345789]|60?)?|4(?:[123456789]|0?0)?|9(?:[013456789]|29?)?|0\d?|3\d?|5\d?|6\d?)?|5(?:3(?:[01235789]|45?|63?)?|0(?:[123456789]|0?0)?|1(?:[023456789]|18?)?|5(?:[012346789]|5?5)?|6(?:[012345789]|60?)?|7(?:[012356789]|40?)?|9(?:[012345678]|98?)?|2[012345679]?|4\d?|8\d?)|6(?:3(?:[234579]|6[0178]?|1[01]?|09?|84?)?|9(?:[1234678]|9[12345]?|0?0|50?)?|0(?:[123456789]|03?)?|1(?:[012345789]|61?)?|6(?:[012345789]|6?6)?|2\d?|4\d?|5\d?|7\d?|8\d?)|7(?:2(?:[0456789]|2[012]?|3[45]?|19?)?|7(?:[01346789]|5[456]|29?)?|0(?:[123456789]|07?)?|1(?:[012345679]|85?)?|5(?:[12456789]|0?0)?|8[012456789]?|3\d?|4\d?|6\d?|9\d?)?|4(?:0(?:[12456789]|0[012]?|3[34]?)?|1(?:[01236789]|4[1259]?|54?)?|9(?:[02456789]|3[67]?)?|2(?:[012346789]|50?)?|4(?:[023456789]|14?)?|3\d?|5\d?|6\d?|7\d?|8\d?)|2(?:1(?:[134589]|09?|21?|68?|72?)?|3(?:[1356789]|2[12]?|0?0|45?)?|0(?:[23456789]|1[23]?|0\d?)?|7(?:[012346789]|53?)?|2\d?|4\d?|5\d?|6\d?|8\d?|9\d?))?|2(?:4(?:6(?:[01234569]|7[678]?|80?)?|0(?:[12345679]|0[0123456]?)|3(?:[01345679]|2[12]?|86?)?|2(?:[01235789]|4[29]?)?|4(?:[012345789]|65?)?|5(?:[012346789]|54?)?|8(?:[012346789]|50?)?|9(?:[013456789]|2?2)|7\d?|1\d)|2(?:3(?:[1236789]|4[37]?|05?|50?)?|0(?:[123456789]|0[012345]?)?|2(?:[01234689]|73?)?|7(?:[012345789]|63?)|8(?:[123456789]|0?0)|9(?:[012346789]|51?)|5(?:[01234678]|5?5)|1\d?|4\d?|6\d)?|0(?:0(?:[256789]|0[01235]?|4[689]?|1[24]?|34?)?|2(?:[13456789]|02?|2?2)?|1(?:[012345789]|67?)?|4(?:[012345679]|80?)?|6(?:[012345689]|70?)?|9(?:[012345678]|9?9)?|3\d?|5\d?|7\d?|8\d?)?|6(?:2(?:[12345789]|6[0123]?|08?)?|4(?:[012345679]|8[679]?)?|0(?:[123456789]|0?0)?|1(?:[012456789]|3?3)?|8[013456789]?|9[012456789]?|3\d?|5\d?|6\d?|7\d?)|3(?:0(?:[123456789]|0[012345]?)|4(?:[123456789]|0[012]?)|2(?:[012345689]|72?)|3(?:[012456789]|3?3)|6[012345678]|8[123456789]|7[02]|1\d|5\d|9\d)?|7(?:3(?:[012356789]|45?)|4(?:[012356789]|42?)|5(?:[123456789]|04?)|7(?:[012345679]|82?)|9(?:[01235678]|9?9)|0\d?|1\d|2\d|6\d|8\d)?|1(?:8(?:[123567]|4[56789]?|0?0)?|5(?:[01234678]|54?|90?)?|0(?:[123456789]|0?0)?|9[0123789]?|1\d?|2\d?|3\d?|4\d?|6\d?|7\d?)?|8(?:2(?:[1236789]|0?0|40?)?|0(?:[123456789]|0?0)?|1(?:[023456789]|19?)?|7[012456789]?|5[012346789]|3\d?|4\d?|6\d?|8\d|9\d)|5(?:9(?:[12346789]|0[0123]?|5[45]?)?|0(?:[123456789]|0\d?)|7(?:[012345678]|93?)?|6\d?|1\d|2\d|3\d|4\d|5\d|8\d)?|9(?:1(?:[012345789]|67?)|0[012346789]|2[012346789]|3\d|4\d|5\d|6\d|7\d|8\d|9\d)?)?|3(?:2(?:7(?:[01234589]|7[01234567]?|6[789]?)|6(?:[012456789]|3[56]?)|8(?:[12345678]|01?|96?)|0(?:[012456789]|34?)?|2(?:[012356789]|49?)?|4(?:[012345679]|83?)|1\d?|3\d|5\d|9\d)|1(?:4(?:[02346789]|16?|57?)?|9(?:[012356789]|4[89]?)?|0(?:[013456789]|29?)?|6(?:[013456789]|20?)?|7(?:[012345789]|65?)?|2[02345789]?|1\d?|3\d?|5\d?|8\d?)?|3(?:3(?:[012456789]|3[14]?)?|1(?:[013456789]|23?)|4(?:[012456789]|34?)|6(?:[012346]|56?)|0[23456789]|7[23456789]|2[016789]|5\d|8\d|9\d)?|4(?:9(?:[01234579]|6[234]?|80?)?|3(?:[012345689]|7[89]?)|2(?:[012356789]|49?)|0[01256789]|4\d?|5\d?|6\d?|7\d?|8\d?|1\d)|0(?:0(?:[23456789]|0[1234]?)|8(?:[012456789]|32?)?|2(?:[012345789]|60?)|9(?:[0134568]|9?9)?|1\d|3\d|4\d|5\d|6\d|7\d)|5(?:0(?:[123456789]|0[14]?)?|3(?:[012346789]|5?5)?|4[012345789]?|6[01234789]?|1\d?|2\d?|5\d?|7\d?|8\d?|9\d?)|7(?:4(?:[012345689]|75?)?|6(?:[01234789]|54?)?|3[012345689]?|0\d?|1\d?|2\d?|5\d?|7\d?|8\d?|9\d?)?|6(?:0(?:[123456789]|01?)?|8(?:[012345789]|65?)?|9[01256789]?|1\d?|2\d?|3\d?|4\d?|5\d?|6\d?|7\d?)|8(?:2(?:[123456789]|0[123]?)?|6[01235679]?|0\d?|1\d?|3\d?|4\d?|5\d?|7\d?|8\d?|9\d?)?|9(?:6(?:[012345679]|81?)?|9[012356789]?|0\d?|1\d?|2\d?|3\d?|4\d?|5\d?|7\d?|8\d?)?)?|4(?:3(?:4(?:[01256789]|4[01]?|39?)?|0(?:[123456789]|0?0)?|2(?:[02345678]|10?)?|1(?:8[89]|9?0)?|7[012356789]?|6[1289]?|9[045]?|5\d?|3?3|89?)?|1(?:1(?:[023456789]|1?1)?|7(?:[23478]|9[45]?)?|2[123456789]?|4[012356789]?|8[0123458]?|9[129]?|0\d?|3\d?|5\d?|6\d?)?|4(?:[17]|5(?:[0123678]|4?4|53?)?|3(?:2[12]?|0)?|8(?:[46]|1?8)?|4[123456789]?|0[0123456]?|6(?:00)?|9(?:00)?|2[56]?)?|8(?:0(?:[1234]|0[0123]?)?|6(?:[78]|1?9|53)?|5(?:[01]|56)?|1(?:2[89])?|7[01678]?|8[1245]?|3[789]?|9[49]?|4\d?|27?)?|7(?:[79]|8(?:[459]|0[689])?|5(?:[0123]|57)?|0(?:[12]|0?0)?|4[01234579]?|2[56789]?|3[02789]?|1(?:00)?|6(?:24)?)?|0(?:8(?:[01269]|4[123]?|5?3)?|0(?:[123456789]|0?0)?|4[012345679]?|7[012345679]?|1\d?|2\d?|3\d?|5\d?|6\d?|9\d?)|5(?:[127]|9(?:[12345789]|6?6)?|6(?:[689]|78?)?|5[012456789]?|0(?:0?0|54)?|3[45678]?|4[56789]?|8(?:25)?)?|9(?:4[0129]?|8[6789]?|5[012]?|9[019]?|0?0|14?|37?|69?|70?|2)?|6(?:[1234]|9(?:[012]|99)?|0[01]?|5[89]?|6\d?|7\d?|8\d?)?|2(?:[012346789]|5(?:0[89]|10)?)?)|5(?:0(?:2[012345679]?|5[012356789]?|6[01245679]?|4[234679]?|7[012349]?|8[012345]?|1[01234]?|9[2349]?|3[01]?|0\d?)?|7(?:4[12345678]?|1[3456789]?|2[0123489]?|8[1234567]?|6[6789]?|5[057]?|7[017]?|9[34]?|30?|0)|2(?:2[34567]?|4[56789]?|0[0123]?|3[4567]?|5[012]?|7[012]?|6[45]?|9[89]?|82?|1)?|1(?:[78]|0[01245]?|5[01245]?|6[45678]?|9[0123]?|1[126]?|3[367]?|20?|45?)|5(?:[1234]|0[0123456]?|8[012345]?|5[3456]?|6[789]?|9[789]?|73?)?|4(?:[789]|3[01234567]?|6[12345]?|5[3456]?|0\d?|1\d?|2\d?|43?)?|6(?:[14569]|8[0123489]?|0[012345]?|3[01234]?|2[789]?|7\d?)?|3(?:[2378]|1[02345]?|6[01234]?|4[349]?|9[789]?|0\d?|5\d?)?|9(?:[23457]|8[456789]?|1[0123]?|9[0129]?|6[389]?|0?0)|8(?:[023478]|1[34]?|5?9|63?)?)?|6(?:5(?:[23]|0[012356789]?|4[34789]?|1[0145]?|8[0123]?|5[018]?|6[68]?|79?)?|3(?:2[0124]?|0[016]?|1[567]?|4[367]?|5[05]?|6[03]?|8[29]?|70?|90?|3)?|6(?:[046]|2[0123678]?|7[012389]?|3[34]?|5[37]?|19?|89?|96?)?|7(?:[2345]|8[456789]?|0[123]?|6[789]?|1[45]?|7[01]?|9[01]?)?|0(?:[123459]|0(?:0-6063)?|8[1235678]?|7[01234]?|6[4569]?)|1(?:[5789]|1[0128]?|6[0123]?|2[234]?|0\d?|4\d?|3?3)?|2(?:[13789]|4[1234]?|5[123]?|0[01]?|6[89]?|2?2)?|4(?:[0369]|4[3456]?|2[01]?|5[56]?|8\d?|17?|71?)?|9(?:[01278]|6[1234569]?|9[789]?|3[56]?|46?|51?)?|8(?:[1279]|4[12]?|01?|31?|50?|68?|8?8)?)|7(?:7(?:[156]|2[04567]?|4[1347]?|7[789]?|8[1679]|9[4789]|0[78]?|3[48]?)|0(?:[56]|1[0123459]?|2[012345]?|7[01]?|9[59]?|[38]0|0\d?|40?)?|5(?:[239]|4[23456789]?|0[01]?|1[01]?|6[06]|[57]0|8?8)|1(?:[345]|6[1234569]?|0[017]?|2[189]?|7[014]|8?1)?|4(?:2[16789]?|0[012]|1[01]?|3[017]|43?|73?|91?|8)?|6(?:[015]|2[4789]?|7[4567]?|8[09]|3?3|48?|97?)?|9(?:0[0123]|3[23]|6[27]|8[02]|9[89]|13|79)?|2(?:7[23456789]|8[012]|0[01]|27|35|62|9)?|8(?:0[012]?|4[56]|8[07]|10|72)?|3(?:[01]|9[123457]|65)?)?|8(?:0(?:5[23456789]|0[012358]?|8[0123678]|2[01256]|3[234]|[46]0|19?|74|97)?|1(?:2[1289]|9[2459]|1[568]|3[012]|4[89]|6[01]|8[24]|0?0)|4(?:0[0123]|4[2345]|7[234]?|1[67]|50|8)?|3(?:7[6789]|0[01]?|2[01]?|8[03]|5?1|3)?|2(?:0[01245678]|9[24]?|80?|30|43|76)?|8(?:9[012349]|8[0389]?|0[04]|73?|6)?|9(?:1[0123]|9[019]|0[01]|54|89)?|7(?:6[3456]|3[23]?|8[67]|70|93)|6(?:1[01234]?|0[09]?|75|86|2)?|5(?:0[01]|5[45]|67)?)|9(?:2(?:1[01234567]|8[01234567]|9[2345]|7[789]|0\d|22|55)?|0(?:[13]|2[0123456]?|8[0456789]|0[01279]?|9[012])?|9(?:[237]|5[012356]?|0[0139]?|9\d?|1?1|6?6|87?)?|1(?:0[0123456]?|6[01234]|19?|31?|91|2)?|6(?:1[28]|2[89]|6[78]|9[45]|00|32)?|3(?:4[346]|9[67]|[08]0|18|21|74)?|5(?:9[23456789]|3[56]|00|22|55)?|8(?:0[012]|9[89]?|7[58]|8[89])?|4(?:0[012]|4[34]|18|50)?|7(?:5[03]|00|47|62)?)?)\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_SERVICES_DCCP = qr{\b(?<![-])(?:(?:avt-profile-|exp)[12]|d(?:tn-bundle|iscard)|ltp-deepspace|syslog-tls)(?![-])\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_SERVICES_SCTP = qr{\b(?<![-])(?:a(?:sap-sctp(?:-tls)?|(?:hs|mq)p|25-fap-fgw|urora|ds-c)|s(?:i(?:mco|ps?)|(?:bc|gs)ap|1-control|mbdirect|sh|ua)|i(?:u(?:hsctpassoc|a)|tu-bicc-stc|pfixs?)|m(?:2(?:[pu]a|ap)|3(?:ap|ua)|egaco-h248)|wme(?:re(?:ceiv|port)ing|distribution)|f(?:tp(?:-data)?|rc-[hlm]p|is)|c(?:isco-ipsla|pdlc|xtp|ar|m)|e(?:nrp-sctp(?:-tls)?|xp[12])|h(?:248-binary|ttps?)|di(?:ameters?|scard)|r(?:cip-itu|na)|(?:lcs-a|bg)p|nfs(?:rdma)?|x2-control|pim-port|v5ua)(?![-])\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_SERVICES_TCP = qr{\b(?<![-])(?:s(?:e(?:[pt]|r(?:v(?:e(?:r(?:view(?:-(?:asn?|icc|gf|rm)|dbms)|-find|graph|start|wsd2)|xec)|i(?:ce(?:-ctrl|meter|tags)|staitsm)|stat)|comm-(?:scadmin|wlink)|ialgateway|aph)|c(?:-(?:t4net-(?:clt|srv)|pc2fax-srv|ntb-clnt)|ur(?:e-(?:cfg-svr|mqtt|ts)|itychase)|layer-t(?:cp|ls)|rmmsafecopya)|n(?:t(?:inel(?:-(?:ent|lm)|srm)?|lm-srv2srv|-lm)|omix0[12345678]|ip|d)|a(?:gull(?:-ai|lm)s|rch(?:-agent)?|odbc|view)|ma(?:phore|ntix)|ispoc|si-lm)|u(?:[am]|n(?:-(?:s(?:r-(?:iiop(?:-aut|s)?|https?|jm[sx]|admin)|ea-port)|as-(?:j(?:mxrmi|pda)|iiops(?:-ca)?|nodeagt)|user-https|mc-grp|dr|lm)|c(?:acao-(?:(?:jmx|sn)mp|websvc|csa|rmi)|luster(?:geo|mgr))|scalar-(?:dns|svc)|proxyadmin|webadmins?|lps-http|fm-port|vts-rmi|rpc)|r(?:f(?:controlcpa|pass)?|veyinst|-meas|ebox)|b(?:mi(?:t(?:server)?|ssion)|ntbcst[-_]tftp)|p(?:er(?:cell|mon)|dup)|it(?:case|jd)|(?:uc|g)p|-mit-tg)|i(?:m(?:p(?:l(?:e(?:-(?:push(?:-s)?|tx-rx)|ment-tie)|ifymedia)|-all)|ba(?:service|expres|-c)s|c(?:tlp|o)|-control|slink|on)|l(?:verp(?:eak(?:comm|peer)|latter)|k(?:p[1234]|meter)|houette|c)|g(?:n(?:a(?:cert-agent|l)|et-ctf)|ma-port|htline)|t(?:ara(?:(?:serve|di)r|mgmt)|ewatch)|x(?:-degrees|xsconfig|netudr|trak)|(?:ft-uf|s-em|ipa|cc)t|e(?:mensgsm|bel-ns|ve)|a(?:-ctrl-plane|m)|ps?)|y(?:n(?:c(?:hro(?:n(?:et-(?:rtc|upd|db)|ite)|mesh)|server(?:ssl)?|-em7|test)|o(?:tics-(?:broker|relay)|ptics-trap)|aps(?:e(?:-nhttps?)?|is-edge)|el-data)|s(?:t(?:em(?:-monitor|ics-sox)|at)|log-(?:conn|tls)|erverremote|o(?:pt|rb)|info-sp|scanner|comlan|rqd)|base(?:anywhere|-sqlany|dbsynch|srvmon)|m(?:antec-s(?:fdb|im)|b-sb-port|plex)|am-(?:webserver|agent|smc)|pe-transport|chrond)|t(?:a(?:r(?:t(?:-network|ron)|(?:quiz-por|bo)t|s(?:chool)?|gatealerts|fish)|t(?:-(?:results|scanner|cc)|s(?:ci[12]-lm|rv)|usd)|nag-5066)|r(?:e(?:et(?:-stream|perfect|talk)|amcomm-ds|sstester|xec-[ds]|letz)|yker-com)|o(?:ne(?:-design-1|falls)|r(?:view|man))|un(?:-(?:p(?:[123]|ort)|behaviors?)|s)?|m(?:[-_]pproc|f)|(?:e-sms|dpt)c|(?:gxfw|s)s|t(?:unnel)?|i-envision|vp|x)|a(?:n(?:t(?:ak-up|ool)s|avigator|e-port|ity)|g(?:e(?:-best-com[12]|ctlpanel)|xtsds)|s(?:(?:-remote-hl)?p|g(?:gprs)?)|i(?:s(?:c?m|eh)?|[-_]sentlm)|lient-(?:dtasrv|usrmgr|mux)|b(?:a(?:rsd|ms)|p-signal)|m(?:sung-unidex|d)|p(?:hostctrls?|v1)|(?:-msg-por|van)t|f(?:etynetp|t)|r(?:atoga|is)|uterdongle|c(?:red)?|h-lm)|c(?:o(?:-(?:(?:(?:ine|d)t|sys)mgr|websrvrmg[3r]|peer-tta|aip)|i2odialog|tty-ft|remgr|help|l)|i(?:n(?:tilla|et)|entia-s?sdb|pticslsrvr)|p(?:i-(?:telnet|raw)|-config)?|r(?:eencast|iptview|abble)|c(?:-security|ip-media)|e(?:n(?:ccs|idm)|anics)|an(?:-change|stat-1)|(?:s(?:erv|c)|u)p|te(?:104|30)|x-proxy)|o(?:l(?:id-(?:e-engine|mux)|era-(?:epmap|lpn)|aris-audit|ve)|n(?:us(?:(?:-loggin|callsi)g)?|ar(?:data)?|iqsync)|s(?:s(?:d-(?:collec|agen)t|ecollector))?|ft(?:rack-meter|dataphone|audit|cm|pc)|c(?:(?:orf|k)s|ial-alarm|alia)|a(?:p-(?:bee|htt)p|gateway)|p(?:hia-lm|s)|undsvirtual|r-update)|m(?:a(?:r(?:t(?:-(?:diagnose|install|lm)|card-(?:port|tls)|packets|sdp)|-se-port[12])|(?:uth-por|kyne)t|clmgr|p)|s(?:-(?:r(?:emctrl|cinfo)|chat|xfer)|q?p|d)|c(?:-(?:https?|admin|jmx)|luster)|p(?:p(?:pd)?|nameres|te)|(?:ntubootstra|t)p|-pas-[12345]|i(?:le|p)|bdirect|wan|ux)|p(?:e(?:ct(?:ard(?:ata|b)|raport)|edtrace|arway)|r(?:ams(?:ca|d)|emotetablet)|s(?:s(?:-lm)?|-tunnel|c)|w-d(?:nspreload|ialer)|a(?:ndataport|mtrap)|i(?:ral-admin|[ck]e)|t(?:-automation|x)|litlock(?:-gw)?|hinx(?:api|ql)|c(?:sdlobby)?|ytechphone|oc[kp]|ugna|dy|mp)|n(?:s-(?:a(?:dmin|gent)|qu(?:ery|ote)|dispatcher|channels|protocol|gateway)|mp(?:t(?:ls(?:-trap)?|rap)|ssh(?:-trap)?|-tcp-port)?|a(?:p(?:[dp]|enetio)?|(?:resecu)?re|(?:-c|ga)s|c)|i(?:ffer(?:client|server|data)|p-slave)|t(?:p-heartbeat|lkeyssrvr)|[cp]p)|s(?:o(?:-(?:control|service)|watch)|m(?:-(?:c(?:ssp|v)|el)s|pp|c)|t(?:p-[12]|sys-lm)?|r(?:-servermgr|ip)|d(?:ispatch|t?p)|h(?:-mgmt|ell)?|sl(?:ic|og)-mgr|c(?:-agent|an)|p(?:-client)?|e-app-config|-idi|7ns|ad|lp|ql)|d(?:p(?:-(?:portmapper|id-port)|roxy)|s(?:-admin|erver|c-lm)?|-(?:request|data|elmd)|(?:(?:nsk|m)m|hel|d)p|(?:e-discover|bprox)y|o(?:-(?:ssh|tls))?|t(?:-lmd)?|client|l-ets|func|r)?|w(?:i(?:s(?:mgr[12]|trap|pol)|ft(?:-rvf|net))|(?:eetware-app|ldy-sia)s|x(?:-gate|admin)|r(?:-port|mi)|dtp(?:-sv)?|tp-port[12]|a-[1234]|-orion)|h(?:i(?:va(?:[-_]confsrvr|discovery|hose)|lp)|a(?:r(?:p-server|eapp)|dowserver|perai)|o(?:ckwave2?|far)|rinkwrap|ell)|l(?:i(?:n(?:kysearch|terbase|gshot)|m-devices)|c-(?:ctrlrloops|systemlog)|s(?:lavemon|cc)|p(?:-notify)?|m-api|ush)|g(?:i-(?:e(?:ventmond|sphttp)|s(?:torman|oap)|arrayd|dmfmgr|lk)|e[-_](?:qmaster|execd)|mp(?:-traps)?|ci?p|-lm)|f(?:t(?:[pu]|dst-port|srv)|s-(?:smp-net|config)|m(?:-db-server|sso)|l(?:ow|m)|-lm)|k(?:ip-(?:cert-(?:recv|send)|mc-gikreq)|y(?:-transpor|telne)t|ronk)|v(?:n(?:et(?:works)?)?|(?:backu|dr)p|s-omagent|cloud|rloc)|r(?:vc[-_]registry|p-feedback|[dm]p|ssend|cp?|uth)|q(?:l(?:exec(?:-ssl)?|[-*]net|se?rv)|dr)|b(?:i-agent|ackup|ook|l)|-(?:openmail|net)|8-client-port|x(?:upt|m)p|3db)|c(?:o(?:m(?:m(?:plex-(?:link|main)|(?:onspa|er)ce|tact-https?|linx-avl|andport|unity)|p(?:aq-(?:[sw]cp|https|evm)|osit-server|x-lockview|ressnet)|otion(?:master|back)|box-web-acc|cam(?:-io)?|-bardac-dw|scm)|n(?:n(?:e(?:ct(?:-(?:client|server)|ion|ed)?|ndp)|lcli)|t(?:(?:clientm|inuu)s|amac[-_]icm|entserver)|f(?:(?:ig-por|luen)t|erence(?:talk)?)?|c(?:urrent-lm|lave-cpp|omp1)|s(?:ul-insight|piracy)|dor)?|r(?:e(?:l(?:[-_]vncadmin|video|ccam)|rjd)|ba(?:-iiop(?:-ssl)?|loc))|d(?:a(?:srv(?:-se)?|auth2)|emeter(?:-cmwan)?|ima-rtp)|g(?:n(?:ex-(?:dataman|insight)|ima)|sys-lm|itate)|l(?:lab(?:orato|e)r|ubris)|p(?:(?:s-tl)?s|y(?:cat)?)|(?:ord-sv|autho)r|s(?:mocall|ir)|u(?:chdb|rier)|via)|a(?:n(?:o(?:n-(?:bjnp[1234]|capt|mfnp)|central[01])|-(?:(?:ferret|nds)(?:-ssl)?|dch)|d(?:itv|r?p)|it[-_]store|to-roboflow|ex-watch)|d(?:key-(?:licman|tablet)|(?:abra|si)-lm|encecontrol|is-[12]|view-3d|lock2?)|l(?:l(?:-(?:sig-trans|logging)|waveiam|trax|er9)|dsoft-backup)?|r(?:t(?:ographerxmp|-o-rama)|d(?:box(?:-http)?|ax)|rius-rshell)|s(?:(?:answmgm|rmagen)t|p(?:ssl)?|torproxy|-mapi)?|i(?:(?:storagemg|ds-senso)r|cci(?:pc)?|lic)|-(?:[12]|audit-d[as]|web-update|idms)|b(?:-protocol|leport-ax|sm-comm)|p(?:fast-lmd|ioverlan|s-lm|mux)?|c(?:sambroker|i-lm)|u(?:pc-remote|tcpd)|m(?:bertx-lm|ac|p)|t(?:chpole|alyst)|ac(?:lang2|ws)|e(?:rpc|vms)|jo-discovery|was)|s(?:o(?:ft(?:-p(?:lusclnt|rev)|ragent|1)|auth)?|-(?:remote-db|auth-svr|services|live)|d(?:-m(?:gmt-port|onitor)|m(?:base)?)|p(?:m(?:lockmgr|ulti)|(?:clmult|un)i)|c(?:c(?:firewall|redir)|[-_]proxy|p)|vr(?:-(?:ssl)?proxy)?|n(?:et-ns|otify)|r(?:egagent|pc)|i-(?:lfa|sgw)p|l(?:istener|g)|bphonemaster|edaemon|t-port|s[cp]|ms2?)|i(?:s(?:co(?:-(?:s(?:ccp|nat|ys)|(?:ipsl|fn)a|t(?:dp|na)|net-mgmt|wafs|avp)|csdb)|-secure)?|t(?:rix(?:ima(?:client)?|-rtmp|admin|uppg?)|y(?:search|nl)|adel)|n(?:egrfx-(?:elmd|lm)|dycollab)|phire-(?:data|serv)|ch(?:ild-lm|lid)|3-software-[12]|m(?:plex|trak)|rcle-x|fs)|l(?:e(?:a(?:r(?:case|visn)|nerliverc)|ver-(?:ctrace|tcpip))|-(?:db-(?:re(?:quest|mote)|attach)|1)|o(?:anto-(?:net-1|lm)|se-combat)|u(?:ster(?:-disc|xl)|tild)|a(?:riion-evr01|ssic)|ient-(?:wakeup|ctrl)|vm-cfg|\/1|p)|h(?:i(?:ldkey-(?:notif|ctrl)|p(?:-lm|per)|mera-hwm)|e(?:ck(?:(?:point-rt|su)m|outdb)|vinservices)|oiceview-(?:ag|cl)t|ar(?:setmgr|gen)|romagrafx|shell|md)|p(?:q(?:rpm-(?:server|agent)|-(?:tasksmart|wbem))|-(?:spx(?:dpy|svr)|cluster)|lscrambler-(?:al|in|lg)|d(?:i-pidas-cm|lc)|(?:udpenca|pd)p|s(?:comm)?)|r(?:uise-(?:(?:swrou|upda)te|config|diags|enum)|e(?:ative(?:partn|serve)r|stron-c[it]ps?)|(?:-websystem|msbit)?s|i(?:nis-hb|p)|yptoadmin)|t(?:i(?:(?:programloa|-redwoo)d|systemmsg)|d(?:[bp]|hercules)|x(?:-bridge|lic)|echlicensing|p(?:-state)?|t-broker|2nmcs|[cs]d|lptc|f)|e(?:r(?:t-(?:initiato|responde)r|nsysmgmtagt|a-bcm)|sd(?:cd(?:ma|tr)n|inv)|nt(?:erline|ra)|quint-cityid|dros[-_]fds|latalk|csvc)|c(?:m(?:a(?:il|d)|-port|comm|rmi)|s(?:-software|s-q[ms]m)|u-comm-[123]|-tracking|tv-port|ag-pib|owcmr|nx|p)|y(?:b(?:(?:org-system|ro-a-bu)s|ercash)|press(?:-stat)?|c(?:leserv2?)?|mtec-port|link-c|tel-lm|aserv)|d(?:[ns]|(?:l-serv|brok)er|dbp(?:-alt)?|3o-protocol|(?:fun)?c|id)|m(?:(?:c-por|tp-mg)t|ip-(?:agent|man)|a(?:dmin)?|mdriver)?|u(?:mulus(?:-admin)?|s(?:eeme|tix)|illamartin|elink)|n(?:rp(?:rotocol)?|ckadserver|s-srv-port|(?:hr|a)p)|v(?:c(?:[-_]hostd)?|s(?:pserver|up)|m?mon|d)|f(?:[sw]|t-[01234567]|engine|dptkt)|g(?:n-(?:config|stat)|i-starapi|ms)|b(?:(?:os-ip-por)?t|server|a8)|qg-netlan(?:-1)?|-h-it-port|1222-acse|wmp|xws|3)|a(?:p(?:p(?:l(?:e(?: remote desktop \(net assistant\)|-(?:vpns-rp|licman|sasl)|qtc(?:srvr)?|ugcontrol)|us(?:service)?|iance-cfg)|s(?:erv-https?|witch-emp|s-lm)|arenet-(?:(?:tp?|a)s|ui)|man-server|iq-mgmt|worxsrv)|c(?:-(?:2(?:16[01]|260)|3(?:052|506)|545[456]|654[789]|995[012]|784[56]|necmp)|upsd)|o(?:llo-(?:(?:statu|gm)s|admin|relay|data|cc)|geex-port|cd)|w(?:i-(?:rxs(?:pool|erv)|imserv)er|-registry)|e(?:x-(?:edge|mesh)|rtus-ldp)|ri(?:go-cs|-lm)|x500api-[12]|ani[12345]|m-link|dap|lx)?|c(?:c(?:e(?:ss(?:builder|network)|l(?:enet)?)|u(?:racer(?:-dbms)?|-lmgr)|(?:topus-c|ord-mg)c|-raid)|p(?:-(?:p(?:o(?:licy|rt)|roto)|discovery|conduit)|tsys|lt)?|t(?:i(?:ve(?:memory|sync)|fio-c2c)|net|er)|e-(?:s(?:vr-prop|erver)|client|proxy)|-(?:cluster|tech)|m(?:s(?:oda)?|e)|l-manager|r-nema|a[ps]|d-pm|is?|net)|s(?:t(?:er(?:gate(?:fax)?|ix)|ro(?:med-main|link))|p(?:e(?:n(?:-services|tec-lm)|clmd)|rovatalk)|a(?:p-tcp(?:-tls)?|-appl-proto|m)?|i(?:p(?:-webadmin|registry)|a)?|s(?:uria-(?:ins|slm)|yst-dr)|c(?:trl-agent|-slmd|i-val)|-(?:servermap|debug)|g(?:cypresstcps|enf)|naacceler8db|oki-sma|mps?|dis|r)|r(?:e(?:pa-(?:raft|cas)|aguard-neo|na-server)|m(?:centerhttps?|techdaemon|i-server|adp)|d(?:us(?:-(?:m?trns|cntl)|mul|uni)|t)|i(?:e(?:s-kfinder|l[123])|liamulti|a)|(?:ray-manag|uba-serv)er|s-(?:master|vista)|c(?:isdms|pd?)|gis-(?:ds|te)|bortext-lm|tifact-msg|kivio|ns)|m(?:t(?:-(?:(?:(?:cnf|esd)-pro|blc-por)t|redir-t(?:cp|ls)|soap-https?))?|p(?:r-(?:in(?:ter|fo)|rcmd)|l-(?:tableproxy|lic)|ify)?|x-(?:web(?:admin|linx)|axbnet|icsp|rms)|i(?:con-fpsu-ra|ganetfs|net)|a(?:hi-anywhere|nda)|b(?:it-lm|eron)|(?:qp|c)s?|dsched|s)|l(?:t(?:a(?:v-(?:remmgt|tunnel)|-ana-lm|link)|ova(?:central|-lm)|serviceboot|(?:bsd|c)p)|ar(?:m(?:-clock-[cs])?|is-disc)|l(?:(?:storcn|peer)s|joyn-stm)|p(?:ha(?:tech-lm|-sms)|es)|(?:esquer|chem)y|mobile-system|ias)|u(?:t(?:o(?:cue(?:log|smi|ds)|(?:no|pa)c|desk-n?lm|trac-acp|build)|h(?:entx)?)|r(?:[ap]|ora(?:-(?:balaena|cmgr))?|i(?:ga-router|s))|di(?:o(?:-activmail|juggler)|t(?:-transfer|d)?))|t(?:m(?:-(?:zip-office|uhas)|(?:tc)?p)|-(?:[3578]|(?:rtm|nb)p|echo|zis)|tachmate-(?:(?:s2|ut)s|g32)|c-(?:appserver|lm)|i-ip-to-ncpe|(?:link)?s|ex[-_]elmd|hand-mmp|ul)|v(?:a(?:nt(?:i[-_]cdp|ageb2b)|uthsrvprtcl|ilant-mgr)|i(?:nstalldisc|va-sna|an)|ocent-(?:adsap|proxy)|t(?:-profile-[12]|p)|-emb-config|en(?:ue|yo)|securemgmt|decc)|n(?:s(?:ys(?:l(?:md|i)|-lm)|a(?:notify|trader)|oft-lm-[12]|wersoft-lm|-console)|t(?:idotemgrsvr|hony-data)|et(?:-[bhlm])?|oto-rendezv|-pcp|d-lm)|d(?:(?:te(?:mpusclien|ch-tes)|i-gxp-srvpr)t|a(?:p(?:t(?:ecmgr|-sna))?|-cip)|obeserver-[12345]|min(?:s-lms|d)|(?:re|c)p|s(?:-c)?|vant-lm|ws)|f(?:s(?:3-(?:(?:(?:file|ka|pr)serv|v(?:lserv|ols))er|(?:error|rmtsy|bo)s|callback|update))?|povertcp|filiate|esc-mc|tmux|rog)?|i(?:r(?:s(?:hot|ync)?|onetddp)|c(?:-(?:oncrpc|np)|c-cmi)|mpp-(?:port-req|hello)|pn-(?:auth|reg)|agent|bkup|lith|ses)|b(?:a(?:t(?:emgr|jss)|cus-remote|rsd)|c(?:voice-port|software)|b(?:accuray|-escp|s)|r-(?:secure|api))|g(?:ent(?:sease-db|view|x)|ri(?:-gateway|server)|p(?:s-port|olicy)|cat|slb)|e(?:roflight-(?:ads|ret)|quus(?:-alt)?|s-discovery|d-512|gate)|1(?:[45]|(?:[67]-an|3)-an|-(?:msc|bs))|(?:h(?:-esp-enca|s)|ker-cd)p|a(?:irnet-[12]|l-lm|m?p|s)|w(?:acs-ice|g-proxy|s-brf)|o(?:l(?:-[123])?|cp|dv)|x(?:is-wimp-port|on-lm)|[34]-sdunode|z(?:eti|tec)|21-an-1xbs|yiya)|m(?:s(?:-(?:s(?:na-(?:server|base)|(?:-s)?ideshow|treaming|ql-[ms]|huttle|mlbiz)|(?:(?:aler|thea)t|wbt-serv)er|r(?:ule-engin|om)e|l(?:icensing|a)|ilm(?:-sts)?|cluster-net|olap[1234]|v-worlds)|f(?:w-(?:(?:s-)?storage|control|replica|array)|t-(?:gc(?:-ssl)?|dpm-cert)|rs)|g(?:-(?:auth|icp)|s(?:rvr|ys)|clnt)|i(?:-(?:selectplay|cps-rm)|ccp|ms)|r(?:-plugin-port|p)|(?:tmg-sst|n)p|d(?:fsr|ts1|p)|exch-routing|h(?:net|vlm)|olap-ptp2|p(?:-os)?|l[-_]lmd|ync|mq|ss)|e(?:d(?:i(?:a(?:(?:-agen)?t|cntrlnfsd|vault-gui|space|box)|mageportal)|-(?:(?:sup|lt)p|fsp-[rt]x|net-svc|ovw|ci)|evolve)|t(?:a(?:edit-(?:mu|se|ws)|s(?:torm|age|ys)|tude-mds|console|-corp|agent|lbend|gram|5)|ric(?:s-pas|adbc)|er)|n(?:andmice(?:-(?:dns|lpm|mon|noh|upg)|_noh)|ta(?:client|server))|ga(?:r(?:dsvr-|egsvr)port|co-h248)|s(?:sage(?:service|asap)|avistaco)|r(?:c(?:ury-disc|antile)|egister)|mcache|comm|vent)|a(?:g(?:ic(?:control|notes|om)|aya-network|enta-logic|bind)|i(?:l(?:box(?:-lm)?|prox|q)|n(?:control|soft-lm)|trd)|c(?:-srvr-admin|romedia-fcs|on-tcp|bak)|pper-(?:(?:ws[-_]|map)ethd|nodemgr)|t(?:ip-type-[ab]|rix[-_]vnet|ahari)|n(?:yone-(?:http|xml)|age-exec|et)|r(?:kem-dcp|cam-lm|talk)|x(?:im-asics|umsp)?|d(?:ge-ltd|cap)|s(?:qdialer|c)|ytagshuffle|o)|i(?:c(?:ro(?:muse-(?:ncp[sw]|lm)|talon-(?:com|dis)|s(?:oft-ds|an)|com-sbp)|om-pfs|e)|n(?:d(?:array-ca|filesys|print)|i(?:-sql|lock|vend|pay)|ger)|t(?:-(?:ml-de|do)v|eksys-lm)|l(?:-2045-47001|es-apart)|r(?:oconnect|rtex|a)|b-streaming|dnight-tech|va-mqs|key|mer)|o(?:b(?:il(?:e(?:-(?:file-dl|p2p)|analyzer|ip-agent)|i(?:tysrv|p-mn))|rien-chat)|s(?:-(?:(?:low|upp)er|soap(?:-opt)?|aux)|ai(?:csyssvc1|xcc)|hebeeri)|n(?:(?:tage-l|keyco)m|etra(?:-admin)?|itor|dex|p)?|l(?:dflow-lm|ly)|rtgageware|vaz-ssc|y-corp|untd)|c(?:s-(?:m(?:essaging|ailsvr)|calypsoicf|fastmail)|t(?:et-(?:gateway|master|jserv)|feed|p)|-(?:(?:brk|gt)-srv|appserver|client)|(?:(?:(?:cwebsv|e)r-|re)por|agen)t|n(?:s-(?:tel-ret|sec)|tp)|(?:2studio|ida|3s)s|(?:k-ivpi|ft)p|p(?:-port)?)|p(?:s(?:(?:ysrmsv|serve)r|-raft|hrsv)|njs(?:o(?:m[bg]|cl|sv)|c)|(?:l-gprs-por|c-lifene)t|p(?:olicy-(?:mgr|v5))?|m(?:-(?:flags|snd))?|f(?:oncl|wsas)|idc(?:agt|mgr)|hlpdmc|tn)|u(?:s(?:t-(?:backplane|p2p)|(?:iconlin)?e)|lti(?:p(?:-msg|lex)|ling-http)|r(?:ray|x)|pdate|mps|nin)|y(?:sql(?:-(?:c(?:m-agent|luster)|proxy|im))?|(?:nahautostar|blas)t|l(?:ex-mapd|xamport)|rtle)|t(?:p(?:ort(?:-regist|mon))?|(?:-scale|s)server|l8000-matrix|i-tcs-comm|rgtrans|qp|n)|g(?:c(?:p-(?:callagent|gateway)|s-mfp-port)|e(?:supervision|management)|xswitch)|d(?:ns(?:responder)?|(?:-cg-ht)?tp|bs[-_]daemon|c-portmapper|ap-port|qs|m)|n(?:(?:p-exchang|gsuit)e|et-discovery|i-prot-rout|s-mail)|x(?:o(?:dbc-connect|mss)|xrlogin|it?)|m(?:a(?:comm|eds)|c(?:als?|c)|pft)|v(?:(?:el|x)-lm|s-capacity)|b(?:l-battd|g-ctrl|us)|r(?:ssrendezvous|ip|m)|2(?:mservices|[pu]a)|f(?:server|cobol|tp)|l(?:-svnet|oadd|sn)|qe-(?:broker|agent)|z(?:ca-action|ap)|4-network-as|km-discovery|3[du]a|-wnn)|i(?:n(?:t(?:e(?:r(?:s(?:ys-cache|erver|an)|act(?:ionweb)?|w(?:orld|ise)|hdl[-_]elmd|pathpanel|intelli|mapper|base)|l(?:-rci(?:-mp)?|listor-lm|_rci|sync)|gr(?:a(?:-sme|l)|ius-stp)|co(?:m-ps[12]|urier))|u(?:-ec-(?:svcdisc|client)|itive-edge)|r(?:a(?:intra|star)|epid-ssl|insa)|-rcv-cntrl|v)|f(?:o(?:rm(?:atik-lm|er)|(?:brigh|cryp)t|m(?:over|an)|libria|exch|seek|wave|tos)|iniswitchcl|luence)|d(?:i(?:go-(?:v(?:bcp|rmi)|server))?|ex-(?:pc-wb|net)|x-dds|ura|y)|s(?:t(?:l[-_]boot[cs]|antia)|i(?:tu-conf|s)|pect)|i(?:nmessaging|serve-port|tlsmsad)|ova(?:port[123456]|-ip-disco)|v(?:ision(?:-ag)?|okator)|gres(?:-net|lock)|c(?:ognitorv|p)|nosys(?:-acl)?|business)|s(?:o(?:-(?:t(?:sap(?:-c2)?|p0s?)|i(?:ll|p))|ipsigport-[12]|de-dua|ft-p2p|mair)|i(?:s(?:-(?:am(?:bc)?|bcast))?|-(?:irp|gl))|m(?:aeasdaq(?:live|test)|server|c)|c(?:si(?:-target)?|hat)|s(?:-mgmt-ssl|d)|bconference[12]|p(?:ipes|mmgr)|n(?:etserv|s)|g-uda-server|rp-port|99[cs]|ysg-lm|d[cd]|akmp|lc)|c(?:l(?:pv-(?:(?:[dp]|ws)m|s(?:as|c)|nl[cs])|cnet(?:-(?:locate|svinfo)|_svinfo)|-twobase(?:[23456789]|10?)|id)|e(?:-s?(?:location|router)|edcp[-_][rt]x)|on(?:-discover|structsrv|p)|g-(?:iprelay|bridge|swp)|a(?:browser|d-el|p)?|s(?:hostsvc|lap)?|p(?:v2|p)?|crushmore|m(?:pd|s)|i)|p(?:[px]|c(?:s(?:-command|erver)|d3?|ore)|(?:ether232por|osplane|r-dgl)t|d(?:tp-port|cesgbs|r-sp|d)|-(?:provision|qsig|blf)|h-policy-(?:adm|cli)|se(?:c-nat-t|ndmsg)|f(?:ltbcst|ixs?)|(?:ulse-ic|as)s|t-anri-anri)|b(?:m(?:-(?:d(?:i(?:radm(?:-ssl)?|al-out)|(?:t-|b)2)|m(?:q(?:series2?|isdp)|gr)|r(?:syscon|es)|a(?:btact|pp)|(?:cic|pp)s|wrless-lan|ssd)|_wrless_lan|3494)|ridge-(?:data|mgmt)|(?:eriagame|u)s|p(?:rotocol)?)|d(?:e(?:afarm-(?:panic|door)|n(?:t(?:ify)?|-ralp)|esrv)|o(?:nix-metane|tdis)t|a(?:-discover[12]|c)|p(?:-infotrieve|s)?|m(?:gratm|aps)|ware-router|ig[-_]mux|[cftx]p|rs)|m(?:q(?:(?:tunnel|stomp)s?|brokerd)|a(?:ge(?:query|pump)|p[3s]?)|i(?:p(?:-channels)?|nk)|tc-m(?:ap|cs)|medianet-bcn|p(?:era|rs)|s(?:ldoc|p)|oguia-port|docsvc|games|yx)|t(?:a(?:c(?:tionserver[12]|h)|-(?:manager|agent)|p-ddtp|lk)|m-(?:mc(?:ell-[su]|cs)|lm)|e(?:lserverport|m)|o(?:-e-gui|se)|v-control|wo-server|internet|scomm-ns)|a(?:s(?:-(?:a(?:dmind|uth)|(?:pagin|re)g|neighbor|session)|control(?:-oms)?|d)|tp-(?:normal|high)pri|f(?:server|dbase)|nywhere-dbns|dt(?:-tls)?|pp|x)|r(?:is(?:-(?:xpcs?|beep|lwz)|a)|c(?:(?:s-)?u|-serv)?|a(?:cinghelper|pp)|d(?:g-post|mi2?)|on(?:storm|mail)|trans|p)|v(?:(?:collecto|manage)r|s(?:-video|d)|econ-port|ocalize)|e(?:e(?:e-m(?:ms(?:-ssl)?|ih)|-qfx)|c-104(?:-sec)?|s-lm)|f(?:s(?:f-hb-port|p)|or-protocol|e[-_]icorp|cp-port)|w(?:(?:listen|serv)er|b-whiteboard|-mmogame|ec|g1)|o(?:-dist-data|nixnetmon|c-sea-lm|p)|q(?:(?:net-por|objec)t|server|rm|ue)|g(?:o-incognito|r(?:id|s)|i-lm|cp)|i(?:-admin|w-port|ms|op)|-(?:net-2000-npr|zipqd)|3-sessionmgr|l(?:[dl]|ss)|ua|zm)|n(?:e(?:t(?:c(?:o(?:nf(?:-(?:beep|ssh|tls)|soap(?:bee|htt)p)|mm1)|h(?:eque|at)|abinet-com|(?:li)?p|elera)|b(?:i(?:ll-(?:(?:cre|pro)d|keyrep|trans|auth)|os-(?:dgm|ssn|ns))|oo(?:kmark|t-pxe))|s(?:c(?:-(?:prod|dev)|ript)|peak-(?:(?:cp?|i)s|acd)|erialext[1234]|upport2?|teward)|o(?:p(?:-(?:school|rc)|ia-vo[12345]|s-broker)|-(?:wol-server|dcs)|bjects[12])|w(?:a(?:tcher-(?:mon|db)|re-(?:cs|i)p|ve-ap-mgmt|ll)|kpathengine|orklens?s)|i(?:q(?:-(?:endp(?:oin)?t|qcheck|voipa|ncap|mc))?|nfo-local)|a(?:pp-ic(?:data|mgmt)|ttachsdmp|dmin|gent|ngel|spi|rx)|m(?:o(?:-(?:default|http)|unt|n)|a(?:p[-_]lm|gic)|pi|l)|x(?:ms-(?:(?:agen|mgm)t|sync)|-(?:server|agent))|view(?:-aix-(?:[23456789]|1[012]?)|dm[123])|r(?:i(?:x-sftm|sk)|js-[1234]|ockey6|cs|ek)|p(?:la(?:y-port[12]|n)|ort-id|erf)|-(?:projection|steward|device)|t(?:gain-nms|est)|eh(?:-ext)?|db-export|2display|labs-lm|8-cman|uitive|news|gw)|w(?:lix(?:(?:confi|re)g|engine)|(?:height)?s|bay-snc-mc|wavesearch|genpay|-rwho|oak)|x(?:storindltd|us-portal|entamv|tstep|gen)|s(?:t-protocol|h-broker|sus)|o(?:d[12]|iface|n24x7|4j)|c(?:-raidplus|kar|p)|i-management|veroffline|rv)|o(?:v(?:a(?:r-(?:global|alarm|dbase)|storbakcup|tion)|ell-(?:lu6[-.]2|ipx-cmd|zen))|t(?:e(?:zilla-lan|share|it)|ify[-_]srvr|ateit)|(?:(?:it-transpo|rton-lambe)r|wcontac)t|a(?:(?:apor|gen)t|dmin)|kia-ann-ch[12]|m(?:ad|db))|i(?:m(?:-(?:vdrshell|wan)|r(?:od-agent|eg)|busdb(?:ctrl)?|s(?:pooler|h)|controller|aux|gtw|hub)?|c(?:e(?:tec-(?:nmsvc|mgmt)|link)|name)|-(?:visa-remote|mail|ftp)|linkanalyst|p(?:robe)?|observer|fty-hmi|trogen|naf|rp)|a(?:t(?:i-(?:vi-server|svrloc|logos|dstp)|dataservice|tyserver|uslink)|v(?:-(?:data-cmd|port)|isphere(?:-sec)?|egaweb-port|buddy)|m(?:e(?:server|munge)?|p)|s(?:-metering|manager)?|-(?:localise|er-tip)|cagent|ap|ni)|s(?:s(?:a(?:gen|ler)tmgr|ocketport|-routing|tp)?|(?:(?:-cfg)?-serve|esrv)r|jtp-(?:ctrl|data)|c-(?:posa|ccs)|deepfreezectl|w(?:-fe|s)|(?:rm?)?p|iiops|t)?|m(?:s(?:[dp]|-(?:topo-serv|dpnss)|_topo_serv|igport|server)?|-(?:game-(?:server|admin)|asses(?:-admin|sor))|(?:a(?:soveri)?|m)p|ea-0183)|c(?:(?:a(?:cn-ip-tc|dg-ip-ud)|xc)p|d(?:loadbalance|mirroring)|p(?:m-(?:hip|ft|pm))?|u(?:-[12]|be-lm)|r[-_]ccl|config|ld?|ed)|d(?:m(?:-(?:(?:request|serv)er|agent-port)|ps?)|l-(?:a(?:[alp]s|hp-svc)|tcp-ois-gw)|s(?:[-_]sso|connect|auth|p)|[nt]p)|p(?:mp(?:-(?:local|trap|gui))?|d(?:s-tracke|bgmng)r|(?:(?:pm)?|s)p|ep-messaging|qes-test)|u(?:t(?:s[-_](?:bootp|dem))?|cleus(?:-sand)?|paper-ss|auth|xsl|fw)|b(?:x-(?:(?:di|se)r|au|cc)|t-(?:wol|pc)|urn[-_]id|db?)|t(?:z-(?:p2p-storage|tracker)|a(?:-[du]s|lk)|p)|v(?:(?:msg)?d|c(?:net)?|-video)|f(?:s(?:rdma)?|oldman|a)|2(?:h2server|nremote)|l(?:g-data|ogin|s-tl)|1-(?:rmgmt|fwp)|h(?:server|ci)|n(?:tps?|s?p)|x(?:edit|lmd)|(?:g-umd|q)s|jenet-ssl|w-license|rcabq-lm|kd)|p(?:r(?:o(?:s(?:hare(?:[12]|(?:audi|vide)o|-mc-[12]|request|notify|data)|pero(?:-np)?)|fi(?:net-(?:rtm?|cm)|le(?:mac)?)|a(?:ctiv(?:esrvr|ate)|xess)|x(?:i(?:ma-l)?m|y-gateway)|d(?:igy-intrnet|uctinfo)|g(?:istics|rammar)|(?:-e|of)d|pel-msgsys|cos-lm|remote|link)|i(?:v(?:ate(?:chat|wire|ark)|ilege|oxy)|nt(?:er(?:[-_]agent)?|-srv|opia)|sm(?:iq-plugin|-deploy)|ority-e-com|maserver|zma)|e(?:cise-(?:comm|sft|vip|i3)|datar-comms|s(?:ence|s)|x-tcp|lude)|(?:chat-(?:serv|us)|regist)er|n(?:request|status)|a(?:[-_]elmd|t)|m-[ns]m(?:-np)?|(?:sv|g)?p)|a(?:r(?:a(?:(?:dym-31por|gen)t|llel)|sec-(?:(?:mast|pe)er|game)|(?:k-age|lia)nt|timage)|n(?:a(?:golin-ident|sas)|do-(?:pub|sec)|golin-laser)|trol(?:-(?:(?:mq-[gn]|is)m|coll|snmp)|view)?|ss(?:w(?:rd-policy|ord-chg)|go(?:-tivoli)?)|y(?:cash-(?:online|wbp)|-per-view|router)|c(?:e(?:-licensed|rforum)|mand|om)|g(?:o-services[12]|ing-port)|lace-[123456]|d(?:l2sim|s)|mmr(?:at|p)c|fec-lm|wserv)|c(?:s(?:-(?:sf-ui-man|pcw)|ync-https?)|-(?:mta-addrmap|telecommute)|i(?:a(?:-rxp-b|rray)|hreq)|o(?:ip(?:-mgmt)?|nnectmgr)|le(?:multimedia|-infex)|anywhere(?:data|stat)|m(?:k-remote|ail-srv)|c-(?:image-port|mfp)|t(?:tunnell|rader)|ptcpservice|ep)|e(?:r(?:son(?:a(?:l(?:-(?:agent|link)|os-001))?|nel)|i(?:scope|mlan)|f(?:-port|d)|mabit-cs|rla)|g(?:asus(?:-ctl)?|board)|er(?:book-port|wire)|(?:arldoc-xac|por)t|oc(?:oll|tlr)|ntbox-sim|-mike|help)|o(?:w(?:er(?:g(?:uardian|emplus)|alert-nsa|clientcsf|exchange|school|burst|onnud)|wow-(?:client|server))|p(?:up-reminders|3s?|2)|l(?:icyserve|esta)r|rtgate-auth|stgresql|v-ray)|l(?:a(?:ysta2-(?:app|lob)|to(?:-lm)?)|(?:cy-net-svc|uribu)s|bserve-port|ysrv-https?|ethora|gproxy)|i(?:c(?:trography|colo|knfs|odbc|hat)|m-(?:rp-disc|port)|r(?:anha[12]|p)|p(?:es)?|nghgl|t-vpn)|d(?:a(?:-(?:data|gate|sys)|(?:p-n)?p)|(?:[ru]nc|efmn)?s|l-datastream|-admin|net|ps?|tp|b)|k(?:t(?:cable(?:mm|-)cops|-krb-ipsec)|ix-(?:timestamp|3-ca-ra|cmc)|-electronics|agent)?|s(?:(?:(?:(?:d?b|pr?|r)s)?erv|l(?:serv|ics))er|c(?:l-mgt|ribe|upd)|i-ptt|-ams|mond|sc?)|h(?:o(?:ne(?:x-port|book)|enix-rpc|turis)|ar(?:masoft|os)|relay(?:dbg)?|ilips-vc)?|m(?:c(?:[ps]|d(?:proxy)?)|d(?:fmgt|mgr)?|sm-webrctl|-cmdsvr|webapi|as)|n(?:et-(?:conn|enc)|-requester2?|aconsult-lm|bs(?:cada)?|rp-port|s)|t(?:p(?:-(?:general|event))?|cnameservice|2-discover|k-alink|-tls)|u(?:r(?:enoise|ityrpc)|(?:lsonixnl|shn)s|bliqare-sync|prouter|mp)|p(?:t(?:conference|p)|s(?:uitemsg|ms)|activation|control)|xc-(?:s(?:p[lv]r(?:-ft)?|apxom)|epmap|ntfy|roid|pin)|v(?:xplus(?:cs|io)|sw(?:-inet)?|uniwien|access)|w(?:g(?:ippfax|wims|psi)|d(?:gen|is)|rsevent)|q(?:s(?:flows|p)|-lic-mgmt)|2p(?:community|group|q)|-net-(?:remote|local)|f(?:u-prcallback|tp)|g(?:bouncer|ps)|4p-portal|6ssmc|jlink|yrrho)|d(?:i(?:r(?:ec(?:t(?:v(?:-(?:catlg|soft|tick|web)|data)|play(?:srvr|8)?|net)?|pc-(?:video|dll|si))|gis)|a(?:l(?:og(?:ic-elmd|-port)|pad-voice[12])|g(?:nose-proc|mond)|m(?:ondport|eters?))|s(?:c(?:p-(?:client|server)|overy-port|lose|ard)|t(?:inct(?:32)?|-upgrade|cc)|play)|c(?:om(?:-(?:iscl|tls))?|t(?:-lookup)?|-aida)|gi(?:tal-(?:notary|vrc)|vote|man)|-(?:(?:tracewar|as)e|drm|msg)|f-port|xie)|e(?:c(?:-(?:mbadmin(?:-h)?|notes|dlm)|a(?:uth|p)|vms-sysmgt|ladebug|_dlm|bsrv|talk)|l(?:l(?:-(?:eql-asm|rm-port)|webadmin-[12]|pwrappks)|os-dms|ta-mcp|ibo)|-(?:s(?:erver|pot)|cache-query|noc)|s(?:k(?:top-dna|share|view)|cent3)|v(?:shr-nts|basic|ice2?)|y-(?:keyneg|sapi)|nali-server|ploymentmap|rby-repli|i-icda|os)|a(?:t(?:a(?:s(?:caler-(?:ctl|db)|urfsrv(?:sec)?)|-(?:insurance|port)|captor|lens)|ex-asn|usorb)|y(?:lite(?:server|touch)|time)|n(?:dv-tester|f-ak2)|(?:rcorp-l|qstrea)m|s(?:hpas-port|p)|i(?:-shell|shi)|mewaremobgtwy|b-sti-c|li-port|vsrcs?|ap|wn)|s(?:m(?:cc-(?:c(?:onfig|cp)|download|passthru|session)|eter[-_]iatc|-scm-target)|-(?:s(?:rvr?|lp)|admin|clnt|mail|user)|x(?:-(?:monitor|agent)|_monitor)|e(?:rver|tos)|lremote-mgmt|p(?:3270)?|om-server|f(?:gw)?|siapi|atp|dn|c)|b(?:control(?:-(?:agent|oms)|_agent)|s(?:(?:yncarbite|ta)r|a-lm)|(?:a(?:bbl|s)|brows)e|isamserver[12]|re(?:porter|f)|eregister|-lsp|db|m)|o(?:c(?:umentum(?:[-_]s)?|(?:-serve|sto)r|e(?:ri-ctl|nt)|ker(?:-s)?|1lm)|main(?:time)?|wn(?:tools)?|nnyworld|ip-data|ssier|glms|om)|t(?:a(?:-systems|g-ste-sb)|s(?:erver-port|pcd)?|-(?:mgmtsvc|vra)|n(?:-bundle|1)|p(?:-dia|t)?|v-chan-req|k)|2(?:k-(?:datamover|tapestry)[12]|000(?:webserver|kernel)|d(?:datatrans|config))|h(?:c(?:p(?:v6-(?:client|server)|-failover2?)|t-(?:alert|statu)s)|analakshmi|e)|n(?:6-(?:nlm-au|smm-re)d|s(?:-llq|2go|ix)|a(?:-cml|p)?|p(?:-sec)?|c-port|o?x)|p(?:s(?:erve(?:admin)?|i)|m(?:-a(?:gent|cm))?|(?:i-p)?roxy|keyserv|[ac]p)|r(?:m(?:-production|s(?:fsd|mc))|i(?:veappserver|zzle|p)|agonfly|wcs|p)|l(?:s(?:-mon(?:itor)?|r(?:ap|pn)|wpn)?|(?:px-s|i)p|[-_]agent|ms-cosem)|v(?:t-(?:system|data)|l-activemail|cprov-port|bservdsc|r-esm|apps)|d(?:m-(?:dfm|rdb|ssl)|i-tcp-[1234567]|ns-v3|repl|dp|gn|t)|c(?:s(?:l-backup|-config|oftware)?|utility|ap?|t?p|cm)?|m(?:(?:af-serv|docbrok)er|od-workspace|express|idi)|yn(?:a(?:-(?:access|lm)|mi(?:c3)?d)|iplookup|-site)|-(?:cinema-(?:cs|rr)p|data(?:-control)?|fence|s-n)|x(?:messagebase[12]|-instrument|admind|spider)|w(?:(?:msgserve)?r|nmshttp|f)|z(?:oglserver|daemon)|f(?:(?:ox)?server|n)|g(?:pf-exchg|i-serv)|k(?:messenger|a)|j-i(?:ce|lm)|3winosfi)|t(?:r(?:i(?:m(?:-(?:event|ice))?|(?:tium-ca|omotio)n|s(?:pen-sra|oap)|p(?:(?:wir)?e)?|dent-data|quest-lm|vnet[12]|butary)|a(?:p(?:-(?:port(?:-mom)?|daemon))?|v(?:soft-ipx-t|ersal)|ns(?:mit-por|ac)t|c(?:eroute|k)|gic|m)|u(?:ste(?:stablish|d-web)|ckstar|ecm)|e(?:ndchip-dcp|ehopper)|-rsrb-p(?:[123]|ort)|nsprntproxy|c-netpoll|off|p)|a(?:l(?:arian-(?:m(?:cast[12345]|qs)|tcp)|on-(?:webserver|engine|disc)|i(?:kaserver|gent-lm)|-pod|net|k)|s(?:kma(?:ster2000|n-port)|erver|p-net)|c(?:(?:ac(?:s-d)?|new)s|ticalauth)|r(?:gus-getdata[123]?|antella)|p(?:e(?:stry|ware)|pi-boxnet)|g-(?:ups-1|pm)|m(?:bora|s)|ep-as-svc|urus-wh|iclock|bula)|e(?:l(?:e(?:(?:niumdaemo|sis-licma)n|lpath(?:attack|start)|finder)|l(?:umat-nms)?|net(?:cpcd|s)?|aconsole|ops-lmd|indus)|r(?:a(?:dataordbms|base)|minaldb|edo)|(?:c5-sdct|edta)p|mp(?:est-port|o)|n(?:tacle|fold)|amcoherence|sla-sys-msg|trinet|xa[ir]|kpls)|i(?:m(?:e(?:stenbroker|flies|lot|d)?|buktu(?:-srv[1234])?)|vo(?:connect|li-npm)|c(?:f-[12]|k-port)|p(?:-app-server|2)|g(?:v2)?|dp|nc)|t(?:c(?:-(?:etap(?:-[dn]s)?|ssl)|mremotectrl)?|l(?:-publisher|priceproxy)|n(?:repository|tspauto)|g-protocol|at3lb|yinfo)|o(?:(?:mato-spring|uchnetplu|nidod)s|p(?:flow(?:-ssl)?|ovista-data|x)|ad(?:-bi-appsrvr)?|l(?:teces|fab)|ruxserver)|c(?:p(?:dataserver|nethaspsrv|-id-port|mux)|o(?:(?:flash|reg)agent|addressbook)|lprodebugger|im-control|c-http)|n(?:-t(?:l-(?:fd[12]|[rw]1)|iming)|p(?:-discover|1-port)?|s-(?:server|adv|cml)|os-(?:dps?|sp)|etos|mpv2)|u(?:n(?:a(?:lyzer|tic)|gsten-https?|stall-pnc|nel)|r(?:bonote-[12]|ns?))|l(?:1(?:-(?:raw(?:-ssl)?|telnet|ssh|lv))?|-ipcproxy|isrv)|s(?:(?:ccha|rmag)t|(?:spma)?p|dos390|erver|af?|b2?|ilb)|d(?:-(?:postman|replica|service)|p-suite|access|moip)|m(?:o(?:-icon-sync|phl7mts|sms[01])|esis-upshot|i)|v(?:dumtray-port|networkvideo|e-announce|bus|pm)|w(?:(?:(?:sd|c)s|d)s|amp-control|-auth-key|rpc)|1(?:distproc(?:60)?|-e1-over-ip|28-gateway)|h(?:t-treasure|r(?:tx|p)|eta-lm)|p(?:csrvr|du|ip|md)|ftp(?:-mcast|s)?|g(?:cconnect|p)|5-straton|2-[bd]rm|ksocket|qdata|brpf)|e(?:m(?:c(?:-(?:xsw-dc(?:onfig|ache)|pp-mgmtsvc|vcas-tcp|gateway)|rmir(?:cc)?d|symapiport|ads)|p(?:rise-l(?:ls|sc)|-server[12]|ire-empuma|owerid|erion)|b(?:race-dp-[cs]|l-ndt)|(?:a-sent-l|7-seco)m|fis-(?:cntl|data)|w(?:avemsg|in)|s(?:d-port)?|gmsg)|s(?:p(?:-(?:encap|lm)|eech(?:-rtp)?|s-portal)|c(?:ale \(newton dock\)|vpnet|p-ip)|r(?:o-(?:emsdp|gen)|i[-_]sde)|i(?:nstall|mport|p)|m(?:manager|agent)|s(?:web-gw|base|p)|(?:erver-pa|tam)p|nm-zoning|broker|-elmd|l-lm)|n(?:t(?:rust(?:-(?:a(?:a[am]s|sh)|kmsh|sps)|time)|ext(?:(?:me|xi)d|netwk|high|low)|-engine|omb|p)|c(?:-(?:eps(?:-mc-sec)?|tunnel(?:-sec)?)|rypted(?:-(?:admin|llrp)|_admin)|ore)|l(?:-name)?|p[cp]|fs)|l(?:(?:pro[-_]tunne|fiq-rep)l|vin[-_](?:client|server)|a(?:n(?:lm)?|telink|d)|i(?:pse-rec)?|ektron-admin|m-momentum|c(?:sd|n)|lpack|xmgmt|s)|x(?:o(?:line-tcp|config|net)|a(?:softport1|pt-lmgr)|c(?:e(?:rpts?)?|w)|p(?:[12]|resspay)|bit-escp|lm-agent|tensis|ec)|d(?:m-(?:m(?:gr-(?:cntrl|sync)|anager)|st(?:d-notify|ager)|adm-notify)|b(?:-server[12]|srvr)|i(?:tbench|x)|tools)|p(?:(?:-(?:ns|pc)|l-sl)p|ortcomm(?:data)?|n(?:cdp2|sdp)|m(?:ap|d)|t-machine|icon|pc?|c)|t(?:h(?:er(?:net(?:\/|-)ip-[12]|cat)|oscan)|lservicemgr|c-control|(?:ft)?p|ebac5|b4j|s)|v(?:e(?:nt(?:-(?:listener|port)|_listener)|rydayrc)|tp(?:-data)?|(?:b-el)?m|-services)|c(?:o(?:lor-imager|visiong6-1|mm)|ho(?:net)?|mp(?:ort)?|sqdmn|wcfg|n?p)|r(?:unbook[-_](?:server|agent)|p(?:-scale|c)|istwoguns|golight)|i(?:con-(?:s(?:erver|lp)|x25)|s(?:p(?:ort)?)?|ms-admin)|-(?:d(?:esign-(?:net|web)|pnet)|builder|mdu|net|woa)|f(?:[rs]|i(?:-(?:lm|mg)|diningport)|orward|b-aci|cp)|z(?:me(?:eting(?:-2)?|ssagesrv)|proxy(?:-2)?|relay)|w(?:c(?:appsrv|tsp)|installer|-mgmt|all|dgs|nn)|q(?:-office-494[012]|uationbuilder|3-update)|h(?:(?:p-backu|t)p|s(?:-ssl)?|ome-ms)|a(?:sy(?:-soft-mux|engine)|psp|1)?|(?:3consultant|os)s|ye(?:2eye|link|tv)|(?:udora-s|en)et|b(?:insite|a)|g(?:ptlm|s))|r(?:e(?:m(?:o(?:te(?:-(?:(?:ki|a)s|winsock|collab)|ware-(?:srv|cl|un)|deploy|fs)|graphlm)|c(?:ap|tl))|s(?:o(?:urce[-_]mgr|rcs)|ponse(?:logic|net)|(?:-s|c)ap|acommunity)?|d(?:sto(?:rm[-_](?:diag|find|info|join)|ne-cpss)|wood-chat)|a(?:l(?:m-rusd|secure)|chout)|p(?:s(?:cmd|vc)|liweb|cmd)|t(?:s(?:-ssl)?|rospect|p)|-(?:conn-proto|mail-ck)|l(?:oad-config|ief)|c(?:vr-rc|ipe)|gistrar|version|ftek|xecj|101|bol)|a(?:d(?:i(?:us(?:-(?:dynauth|acct))?|o(?:-sm)?|x)|w(?:are-rpm(?:-s)?|iz-nms-srv)|(?:an-htt|ec-cor)p|min(?:-port|d)|clientport|s(?:ec)?|pdf)|p(?:i(?:d(?:mq-(?:center|reg)|base|o-ip))?|-(?:service|listen|ip))?|ve(?:n(?:t(?:bs|dm)|-r[dm]p)|hd)|i(?:lgun-webaccl|d-(?:am|cc))|t(?:io-adp|l)|qmon-pdu|w-serial|xa-mgmt|admin|sadv|zor|cf|mp)|t(?:-(?:(?:(?:devicemap|hel)p|classmanag|labtrack|view)er|event(?:-s)?|sound)|s(?:p(?:-alt|s)?|client|serv)|ps-d(?:iscovery|d-[mu]t)|c(?:-pm-port|m-sc104)|(?:mp-por|elne)t|raceroute|nt-[12]|ip)|s(?:v(?:p(?:-(?:encap-[12]|tunnel)|_tunnel)|d)|i(?:sysaccess|p)|-(?:pias|rmi)|c(?:-robot|d)|m(?:tp|s)|qlserver|h-spx|f-1|ync|ap|om)|o(?:b(?:o(?:traconteur|e(?:da|r))|cad-lm|ix)|c(?:kwell-csp[12]|rail)|utematch|verlog|ketz|otd)|m(?:i(?:a(?:ctivation|ux)|registry)|o(?:nitor(?:[-_]secure)?|pagt)|t(?:server)?|lnk|pp|c)|d(?:m(?:net-ctrl|-tfs)|(?:b-dbs-dis|la)p|s(?:-i[bp]|2)?|c-wh-eos|rmshc|a)|i(?:c(?:ardo-lm|h-cp)|d(?:geway[12])?|m(?:f-ps|sl)|s(?:-cm|e)?|b-slm|png)|b(?:r-d(?:iscovery|ebug)|t-(?:wanopt|smc)|akcup[12]|lcheckd|system)|p(?:ki-rtr(?:-tls)?|c2portmap|asswd|rt|i)|r(?:i(?:(?:[lm]w|fm)m|rtr|sat)|d?p|ac|h)|f(?:[abe]|i(?:d-rp1|le|o)|x-lm|mp)|u(?:s(?:b-sys-port|hd)|gameonline)|c(?:(?:c-ho)?st|ip-itu|ts|p)|l(?:m(?:-admin)?|zdbase|p)|(?:vs-isdn-dc|hp-iib|gt)p|j(?:cdb-vcards|e)|(?:kb-osc|whoi)s|n(?:m(?:ap)?|rp)|x(?:api|mon|e))|b(?:m(?:c(?:-(?:p(?:erf-(?:(?:mgr|s)d|agent)|atroldb)|(?:messag|report)ing|net-(?:adm|svc)|g(?:ms|rx)|data-coll|ctd-ldap|jmx-port|onekey|ar|ea)|_(?:ctd_ldap|patroldb)|patrol(?:agent|rnvu))|[ap]p|dss)|o(?:o(?:t(?:server|p[cs])|sterware|merang)|ks(?:[-_](?:serv[cm]|clntd))?|x(?:backupstore|p)|ard-(?:roar|voip)|inc-client|ldsoft-lm|rland-dsj|unzza|scap|nes)|a(?:c(?:k(?:up(?:-express|edge)|roomnet|burner)|ula-(?:[fs]d|dir)|net)|n(?:yan-(?:net|rpc|vip)|dwiz-system)|dm[-_]p(?:riv|ub)|rracuda-bbs|lour|tman|se)|i(?:n(?:tec-(?:[ct]api|admin)|derysupport|gbang|kp)|o(?:link-auth|server)|t(?:forestsrv|speer)|s-(?:sync|web)|(?:ap-m)?p|imenu|m-pem)|e(?:a(?:con-port(?:-2)?|rs-0[12])|s(?:erver-msg-q|api|s)|x-(?:webadmin|xr)|eyond(?:-media)?|yond-remote|rknet|orl)|l(?:ue(?:ctrlproxy|berry-lm|lance)|a(?:ck(?:board|jack)|ze)|ock(?:ade(?:-bpsp)?|s)|wnkl-port|p[12345]|izwow|-idm)|r(?:(?:idgecontro|-channe)l|(?:oker[-_]servic)?e|c(?:m-comm-port|d)|u(?:tus|ce)|lp-[0123]|vread|dptc|f-gw|ain|p)|v(?:-(?:queryengine|smcsrv|[di]s|agent)|c(?:daemon-port|ontrol)|tsonar|eapi)|c(?:s(?:-(?:lmserv|brok)er|logc)?|tp(?:-server)?|inameservice|cp)|t(?:p(?:p2(?:sectrans|audctr1)|rjctrl)|s-(?:appserver|x73)|rieve)|u(?:s(?:iness|ycal|boy)|es[-_]service|llant-s?rap|ddy-draw)|s(?:fs(?:vr-zn-ssl|erver-zn)|quare-voip|pne-pcc)|p(?:c(?:p-(?:poll|trap)|d)|java-msvc|[mr]d|dbm)|f(?:d-(?:(?:multi-ct|contro)l|echo)|lckmgr|tp)|h(?:oe(?:dap4|tty)|(?:fh|md)s|event|611)|n(?:et(?:(?:fil|gam)e)?|t-manager)|2(?:-(?:licens|runtim)e|n)|d(?:ir[-_]p(?:riv|ub)|p)|b(?:n-mm[cx]|ars)?|g(?:s-nsi|m?p)|-novative-ls|z(?:flag|r)|ytex|xp)|o(?:p(?:e(?:n(?:ma(?:il(?:pxy|ns|g)?|th)|v(?:ms-sysipc|pn)|(?:stack-|hp)id|(?:webne|por)t|nl(?:-voice)?|t(?:able|rac)|remote-ctrl|c(?:ore|m)|deploy|queue|flow)|quus-server)|s(?:e(?:c-(?:(?:el|le)a|u(?:aa|fp)|cvp|omi|sam)|ssion-(?:clnt|prxy|srvr))|w(?:manager|agent)|view-envoy|mgr)|t(?:i(?:ka-emedia|ma-vnet|wave-lm|logic)|o(?:host00[234]|control)|ech-port1-lm)|c(?:-job-(?:start|track)|ua-t(?:cp|ls)|on-xps)|alis-r(?:bt-ipc|obot|dv)|us-services|net-smp|-probe|i-sock)|r(?:a(?:cle(?:-(?:(?:em|vp)[12]|oms)|n(?:et8cman|ames)|as-https)|-(?:oap|lm)|srv)|b(?:i(?:x(?:-(?:c(?:fg-ssl|onfig)|loc(?:-ssl|ator))|d)|ter)|plus-iiop)|i(?:go-(?:native|sync)|on(?:-rmi-reg)?)|dinox-(?:server|dbase))|m(?:a(?:-(?:[imr]lp(?:-s)?|dcdocbs|ulp)|bcastltkm|sgport)|s(?:-nonsecure|topology|contact|erv|dk)?|ni(?:vision(?:esx)?|link-port|sky)|(?:ginitialref|h)s|vi(?:server|agent))|v(?:s(?:am-(?:d-agen|mgm)t|essionmgr|db)|alarmsrv(?:-cmd)?|(?:hpa|bu|ob)s|-nnm-websrv|rimosdbman|[el]admgr|topmd|wdb)|n(?:e(?:home-(?:remote|help)|p-tls|saf)|t(?:obroker|ime)|base-dds|screen|mux)|s(?:m(?:-(?:appsrvr|oev)|osis-aeea)|p(?:f-lite)?|-licman|u-nms|b-sd|aut|dcp)|d(?:e(?:umservlink|tte-ftps?)|n(?:-castraq|sp)|bcpathway|i-port|mr|si)|c(?:e(?:-snmp-trap|ansoft-lm)|s(?:[-_][ac]mu|erver)|binder|topus|-lm)|b(?:j(?:ect(?:ive-dbc|manager)|call)|servium-agent|rpd|ex)|em(?:cacao-(?:websvc|jmxmp|rmi)|-agent)|f(?:fice(?:link2000|-tools)|sd)|i(?:d(?:ocsvc|sr)|rtgsvc|-2000)|t(?:p(?:atch)?|[lm]p|tp?|v)|w(?:amp-control|server|ms)|l(?:s[rv]|host)|h(?:imsrv|sc)|2server-port|ob-ws-https?|gs-server|a-system|utlaws)|f(?:i(?:le(?:net-(?:p(?:owsrm|eior|ch|a)|r(?:mi|pc|e)|obrok|nch|tms|cm)|(?:x-lpor|cas)t|sphere|mq)|r(?:e(?:monrcc|power|fox)|st(?:-defense|call42))|n(?:(?:isa|ge)r|d(?:viatv)?|le-lm|trx)|o(?:rano-(?:msg|rtr)svc|-cmgmt)|botrader-com|s(?:a-svc)?|veacross)|a(?:c(?:sys-(?:router|ntp)|ilityview|-restore|elink)|x(?:(?:portwin|stfx-)port|comservice|imum)|st(?:-rem-serv|lynx)|zzt-(?:admin|ptp)|t(?:pipe|serv)|(?:gordn|md)c|irview|renet)|j(?:i(?:ppol-(?:po(?:rt[12]|lsvr)|swrly|cnsl)|(?:tsuapp|nv)mgr|cl-tep-[abc])|s(?:v(?:-gssagt|mpor)|wapsnp)|mp(?:(?:jp|s)s|cm)|d(?:ocdist|mimgr)|(?:hpj|c)p|appmgrbulk|-hdnet)|c(?:p(?:-(?:(?:addr-srvr|srvr-inst)[12]|cics-gw1|udp))?|-(?:faultnotify|cli|ser)|i(?:p-port|s)|opys?-server|msys)|u(?:nk(?:-(?:l(?:icense|ogger)|dialout)|proxy)|jitsu-(?:d(?:tc(?:ns)?|ev)|mmpdc|neat)|script|trix)|l(?:a(?:sh(?:filer|msg)|menco-proxy)|(?:irtmitmi|ukeserve)r|r[-_]agent|orence|n-spx|exlm|crs|y)|t(?:p(?:-(?:agent|data)|s(?:-data)?)?|ra(?:pid-[12]|nhc)|-role|nmtp|srv)|o(?:resyte-(?:clear|sec)|(?:togca|un)d|nt-service|liocorp|dms)|s(?:[er]|-(?:(?:agen|mgm)t|rh-srv|server|qos)|portmap|c-port)|m(?:p(?:ro-(?:(?:intern|fd)al|v6))?|sas(?:con)?|[tw]p)|e(?:itianrockey|rrari-foam|booti-aw|mis)|r(?:ee(?:zexservice|civ)|yeserv|onet|cs)|f(?:-(?:lr-port|annunc|fms|sm)|server)|x(?:aengine-net|(?:upt)?p)|5-(?:globalsite|iquery)|g-(?:sysupdate|fps|gip)|p(?:(?:o-fn|ram)s|itp)|dt(?:-rcatp|racks)|net-remote-ui|yre-messanger|h(?:sp|c)|ksp-audit)|l(?:i(?:s(?:p(?:-(?:cons|data)|works-orb)|t(?:crt-port(?:-2)?|mgr-port))|n(?:k(?:test(?:-s)?|name)?|ogridengine|x)|ebdevmgmt[-_](?:[ac]|dm)|ve(?:stats|lan)|mnerpressure|censedaemon|berty-lm|psinc1?|onhead|ght)|a(?:n(?:s(?:urveyor(?:xml)?|chool|erver|ource)|rev(?:server|agent)|900[-_]remote|yon-lantern|messenger|dmarks|ner-lm)|(?:(?:unchbird|venir)-l)?m|zy-ptop|es-bf|plink|brat)|o(?:n(?:talk-(?:urgnt|norm)|ewolf-lm|works2?)|c(?:us-(?:con|map)|alinfosrvr|kstep)|t(?:us(?:mtap|note)|105-ds-upd)|rica-(?:out|in)(?:-sec)?|aprobe|fr-lm|gin)|m(?:-(?:(?:(?:webwatch|sserv)e|instmg)r|perfworks|dta|mon|x)|s(?:ocialserver)?|d?p|cs)|d(?:s(?:-d(?:istrib|ump)|s)|oms-m(?:gmt|igr)|ap(?:-admin|s)?|gateway|x?p)|v(?:-(?:f(?:rontpanel|fx)|auth|pici|not|jc)|ision-lm)|nv(?:ma(?:ilmon|ps)|console|poller|status|alarm)|s(?:i-(?:raid-mgm|bobca)t|3(?:bcast)?|p-ping|tp)|b(?:[fm]|c-(?:watchdog|control|measure|sync))|3(?:-(?:h(?:bmon|awk)|ranger|exprt)|t-at-an)|e(?:(?:croy-vic|oi)p|ecoposserver|gent-[12])|l(?:m(?:-(?:pass|csv)|nr)|surfup-https?|rp)|p(?:srecommender|ar2rrd|cp|dg)|2(?:c-(?:control|data)|tp|f)|t(?:p(?:-deepspace)?|ctcp)|(?:5nas-parcha|jk-logi)n|u(?:mimgrd|t[ac]p|pa)|(?:cm-|kcm)server|r(?:s-paging|p)|-acoustics|xi-evntsvc|yskom|htp)|h(?:p(?:-(?:s(?:e(?:ssmon|rver)|an-mgmt|c[aio]|tatus)|d(?:ataprotect|evice-disc)|p(?:dl-datastr|xpib)|web(?:admin|qosdb)|c(?:ollector|lic)|(?:nnm-dat|rd)a|hcip(?:-gwy)?|managed-node|3000-telnet|alarm-mgr)|v(?:mm(?:control|agent|data)|irt(?:ctrl|grp)|room)|s(?:s(?:-ndapi|mgmt|d)|tgmgr2?)|o(?:ms-(?:dps|ci)-lstn|cbus)|i(?:dsa(?:dmin|gent)|od)|p(?:ronetman|pssvr)|(?:blade|dev)ms)|a(?:cl-(?:p(?:robe|oll)|monitor|[gq]s|local|test|cfg|hb)|(?:r(?:t-i)?|gel-dum)?p|ipe-(?:discover|otnk)|-cluster|ssle|wk|o)|e(?:a(?:lth(?:-(?:polling|trap)|d)|rtbeat|thview)|r(?:odotus-net|e-lm|mes)|l(?:lo(?:-port)?|ix)|cmtl-db|xarc|ms)|y(?:per(?:(?:wave-is|i)p|scsi-port|cube-lm|-g)|brid(?:-pop)?|d(?:ap|ra)|lafax)|t(?:tp(?:-(?:(?:rpc-ep|w)map|(?:mgm|al)t)|s(?:-wmap)?|x)?|uilsrv|rust|cp)|i(?:p(?:erscan-i|pa)d|(?:[cn]|sli)p|ve(?:stor|p)|gh-criteria|llrserv|q)|o(?:me(?:portal-web|steadglory)|u(?:dini-lm|ston)|tu-chat|stname|nyaku)|323(?:gate(?:disc|stat)|hostcall(?:sc)?|callsigalt)|2(?:250-annex-g|48-binary|63-video|gf-w-2m)|d(?:e-lcesrvr-[12]|l-srv|ap)|s(?:rp(?:v6)?|l-storm|-port)|hb-(?:handheld|gateway)|l(?:(?:serve|ibmg)r|7)|u(?:b-open-net|sky)|r(?:i-port|d-ncs)|fcs(?:-manager)?|b(?:-engine|ci)|mmp-(?:ind|op)|k(?:s-lm|p)|cp-wismar|nmp?)|v(?:i(?:s(?:i(?:on(?:[-_](?:server|elmd)|pyramid)|cron-vs|net-gui|tview)|t(?:ium-share|a-4gl)|d)|d(?:e(?:o(?:-activmail|beans|tex)|te-cipc)|s-avtp|igo)?|r(?:tual(?:-(?:places|time)|tape|user)|prot-lm)|p(?:era(?:-ssl)?|remoteagent)|ziblebrowser|talanalysis|nainstall|eo-fe)|e(?:r(?:i(?:tas(?:-(?:vis[12]|tcp1|pbx|ucl)|_pbx)|smart)|s(?:a(?:-te|tal)k|iera)|gencecm|acity|onica)|(?:stasdl|ttc)p|nus(?:-se)?|mmi)|r(?:t(?:s(?:-(?:a(?:uth|t)-port|ipcserver|registry|tdd)|trapserver)|l-vmf-(?:ds|sa)|p)?|(?:xpservma|p)n|(?:commer|a)ce)|s(?:a(?:mredirector|t-control|iport)|i(?:-omega|admin|net|xml)|(?:econnecto|-serve)r|(?:nm-agen|ta)t|(?:lm|c)p|pread)|a(?:t(?:-control|ata|p)?|(?:-pac|ult)base|(?:lisys-l|prt)m|cdsm-(?:app|sws)|ntronix-mgmt|radero-[012]|d)|o(?:caltec-(?:admin|wconf|gold|hos)|(?:fr-gatewa|lle)y|ispeed-port|p(?:ied)?|xelstorm)|p(?:p(?:s-(?:qu|vi)a)?|sipport|a[cd]?|[2j]p|v[cd]|nz)|c(?:s(?:-app|cmd)|net-link-v10|om-tunnel|hat|rp|e)|m(?:(?:ware-fd|ode)m|svc(?:-2)?|pwscs|net|rdp)|t(?:s(?:-rpc|as)|r-emulator|u-comms|-ssl)|ytalvault(?:(?:brt|vsm)p|pipe)|n(?:wk-prapi|sstr|etd|as|yx)|x(?:-auth-|crnbu)port|vr-(?:control|data)|f(?:mobile|bp|o)|(?:-one-sp|q)p|d(?:mplay|ab)|lsi-lm|ulture|5ua|hd)|w(?:a(?:p-(?:wsp(?:-(?:wtp(?:-s)?|s))?|push(?:-https?|secure)?|vca(?:rd|l)(?:-s)?)|t(?:c(?:h(?:do(?:c(?:-pod)?|g-nt)|me-7272)|omdebug)|ershed-lm|ilapp)|g(?:o-(?:io-system|service)|-service)|r(?:m(?:spotmgmt|ux)|ehouse(?:-sss)?)|nscaler|cp|fs)|i(?:n(?:p(?:o(?:planmess|rt)|haraoh|cs)|d(?:(?:rea|l)m|d(?:lb|x)|b)|s(?:hadow(?:-hd)?)?|install-ipc|jaserver|qedit|fs|rm)|l(?:kenlistener|ly)|m(?:axasncp|sic|d)|(?:egan|re)d|p-port|bukey|free)|e(?:b(?:m(?:a(?:chine|il-2)|ethods-b2b)|s(?:phere-snmp|ter|m)|a(?:dmstart|ccess)|(?:2ho|ya)st|(?:phon|ti)e|emshttp|objects|login|data)|ste(?:c-connect|ll-stats)|a(?:ndsf|ve)|llo)|s(?:m(?:-server(?:-ssl)?|ans?|lb)|d(?:api(?:-s)?|l-event)|(?:o2esb-consol|pip)e|s(?:comfrmwk|authsvc)|(?:-discover|icop)y|ynch)|h(?:o(?:s(?:ockami|ells)|is(?:\+\+|pp)|ami)|erehoo|isker)|or(?:ld(?:fusion[12]|scores|-lm)|kflow)|w(?:w(?:-(?:ldap-gw|http|dev))?|iotalk)|m(?:(?:s-messeng|lserv)er|c-log-svc)|r(?:s(?:[-_]registry|pice)|itesrv)|(?:ta-ws(?:p-wt)?p-|p(?:age|g))s|v-csp-(?:sms(?:-cir)?|udp-cir)|bem-(?:exp-https|https?|rmi)|c(?:(?:backu|p)p|r-remlib)|f(?:(?:remotert)?m|c)|(?:g-netforc|usag)e|k(?:stn-mon|ars)|l(?:anauth|bs)|nn6(?:-ds)?|ysdm[ac]|xbrief)|g(?:a(?:l(?:axy(?:-(?:network|server)|7-data|4d)|ileolog)|m(?:e(?:smith-port|lobby|gen1)|mafetchsvr)|d(?:getgate[12]way|ugadu)|ndalf-lm|t-lmd|rcon|c?p|ia)|e(?:n(?:i(?:e(?:-lm)?|sar-port|uslm)|e(?:ralsync|ous)|rad-mux|stat)|o(?:gnosis(?:man)?|locate)|mini-lm|arman|rhcs)|r(?:i(?:d(?:gen-elmd|-alt)?|ffin|s)|o(?:ove(?:-dpp)?|upwise)|a(?:decam|phics)|f-port|cm?p|ubd)|l(?:o(?:b(?:al-(?:cd-port|dtserv|wlink)|e(?:cast-id)?|msgsvc)|gger)|(?:ish)?d|rpc|bp)|t(?:p-(?:control|user)|rack-(?:server|ne)|e(?:gsc-lm|-samp)|-proxy|aua)|s(?:i(?:(?:dca|ft)p|gatekeeper)?|s-(?:xlicen|http)|m(?:p-ancp|s)|akmp)|d(?:s(?:(?:-adppiw)?-|_)db|o(?:map|i)|rive-sync|bremote|p-port)|o(?:(?:ldleaf-licma|-logi)n|ahead-fldup|todevice|pher)|i(?:(?:ga-pocke)?t|latskysurfer|op(?:-ssl)?|nad)|w(?:-(?:call-port|asv|log)|(?:en-sony|h)a)?|n(?:u(?:tella-(?:rtr|svc)|net)|tp)|p(?:rs-(?:cube|data)|pitnp|fs|sd)|c(?:m(?:onitor|-app)|-config|sp)|b(?:mt-stars|s-s[mt]p|jd816)|x(?:s-data-port|telmd)|m(?:rupdateserv|mp)|u(?:ttersnex|ibase)|v(?:-(?:pf|us)|cp)|g(?:f-ncp|z)|-talk|2tag|5m|f)|u(?:n(?:i(?:s(?:ys-(?:eportal|lm)|ql(?:-java)?)|v(?:erse[-_]suite|-appserver|ision)|fy(?:-(?:adapter|debug)|admin)?|(?:c(?:ontro|al)|mobilectr)l|(?:x-stat|zens)us|hub-server|data-ldm|keypro|port|eng|te)|bind-cluster|[eo]t|do-lm|glue)|p(?:s(?:-(?:onlinet|engine)|notifyprot|triggervsw)?|notifyps?|grade)|l(?:t(?:r(?:a(?:seek-http|bac)|ex)|imad)|p(?:net)?|istproc)|d(?:p(?:-sr-port|radio)|r(?:awgraph|ive)|t[-_]os)|a(?:(?:-secureagen|iac)t|(?:dt|a)c|(?:rp|c)s)|s(?:-(?:(?:sr|g)v|cli)|er-manager)|u(?:cp(?:-(?:rlogin|path))?|idgen)|r(?:[dm]|(?:ld-por|bisne)t)|t(?:(?:mp[cs]|c)d|sftp|ime)|b(?:-dns-control|roker|xd)|c(?:entric-ds|ontrol)|f(?:astro-instr|mp)|m(?:m-port|sp?|a)|o(?:host|rb)|-dbap|ec|is)|x(?:m(?:l(?:i(?:nk-connect|pcregsvc)|tec-xmlmail|rpc-beep|blaster)|p(?:p-(?:client|server|bosh)|cr-interface|v7)|query|api|ms2|cp|sg)|n(?:s-(?:c(?:ourier|h)|auth|mail|time)|m(?:-(?:clear-text|ssl)|p)|ds)|i(?:n(?:u(?:expansion[34]|pageserver)|g(?:mpeg|csm))|ostatus|ip|c)|s(?:s(?:-srv)?-port|-openstorage|(?:msv|yn)c|ip-network|erveraid)|p(?:r(?:int-server|tld)|(?:ane)?l|ilot)|a(?:ct-backup|ndros-cms|dmin|p-ha|api)|y(?:brid-(?:cloud|rt)|plex-mux)|t(?:r(?:eamx|ms?)|lserv|gui)|d(?:(?:mc|t)p|s(?:xdm)?|as)|(?:ecp-nod|9-icu)e|(?:xnetserve|fe?)r|o(?:-wave|raya|ms)|r(?:pc-registry|l)|-bone-(?:api|ctl)|(?:kotodrc|vtt)p|(?:gri|qos)d|25-svc-port|500ms|box|11)|k(?:e(?:ys(?:(?:erve|rv)r|hadow)|r(?:beros(?:-adm)?|mit)|ntrox-prot)|a(?:sten(?:chasepad|xpipe)|(?:za|n)a|r2ouche|0wuc|li)|o(?:ns(?:hus-lm|pire2b)|pek-httphead|fax-svr)|i(?:n(?:g(?:domsonline|fisher)|k)|osk|tim|s)|f(?:tp(?:-data)?|xaclicensing|server)|t(?:i(?:-icad-srvr|ckets-rest)|elnet)|r(?:b5(?:gatekeeper|24)|yptolan)|v(?:-(?:server|agent)|m-via-ip)|m(?:e-trap-port|scontrol|ip)|(?:jtsiteserve|z-mig)r|3software-(?:cli|svr)|p(?:asswd|n-icw|dp)|s(?:ysguard|hell)|w(?:db-commn|tc)|l(?:ogin|io)|yoceranetdev|net-cmp|-block|dm)|j(?:a(?:u(?:gsremotec-[12]|s)|m(?:serverport|link)|xer-(?:manager|web)|cobus-lm|leosnd|rgon)|e(?:t(?:form(?:preview)?|cmeserver|stream)|ol-nsdtp-[1234]|diserver|rand-lm|smsjc)|o(?:(?:ajewelsuit|urne)e|mamqmonitor|ltid|ost)|m(?:(?:q-daemon-|b-cds)[12]|act[356]|evt2|s)|w(?:(?:alk)?server|pc(?:-bin)?|client)|d(?:l-dbkitchen|atastore|mn-port)|b(?:oss-iiop(?:-ssl)?|roker)|t(?:400(?:-ssl)?|ag-server)|i(?:ni-discovery|be-eb)|-(?:l(?:an-p|ink)|ac)|p(?:egmpeg|rinter|s)|v(?:client|server)|u(?:xml-port|te)|licelmd|stel|cp)|q(?:u(?:e(?:st(?:-(?:data-hub|agent|vista)|db2-lnchr|notify)|ueadm)|a(?:(?:sar-serve|ntasto)r|rtus-tcl|ilnet|ddb|ke)|ick(?:booksrds|suite)|o(?:tad|sa)|bes)|s(?:net-(?:(?:assi|work)st|trans|cond|nucl)|m-(?:remote|proxy|gui)|oft)|t(?:(?:ms-bootstra)?p|-serveradmin)|ip-(?:(?:audu|qdhc)p|login|msgd)|b(?:-db-server|ikgdp|db)|f(?:t(?:est-lookup)?|p)|(?:db2servic|3ad|wav)e|o(?:t(?:ps|d)|-secure)|admif(?:event|oper)|n(?:xnetman|ts-orb)|p(?:asa-agent|tlmd)|m(?:[qt]p|video)|(?:en)?cp|ke-llc-v3|55-pcc|rh|vr)|z(?:e(?:n(?:ginkyo-[12]|-pawn|ted)|p(?:hyr-(?:clt|srv|hm))?)|a(?:bbix-(?:trapper|agent)|nnet|rkov)|i(?:(?:on-l|co)m|gbee-ips?|eto-sock)|(?:ymed-zp|oomc|m)p|firm-shiprush3|se(?:cure|rv)|-wave(?:-s)?|39[-.]50)|3(?:com(?:-(?:n(?:jack-[12]|et-mgmt|sd)|webview|tsmux|amp3)|faxrpc|netman)|par-(?:mgmt(?:-ssl)?|rcopy|evts)|(?:gpp-cbs|exm)p|d(?:-nfsd|s-lm)|l(?:-l1|ink)|m-image-lm)|4(?:-tieropm(?:cli|gw)|talk)|9(?:14c(?:\/|-)g|pfs)|802-11-iapp|1ci-smcs|yo-main)(?![-])\b}i;  ## no critic(RegularExpressions)



our $IANA_REGEX_SERVICES_UDP = qr{\b(?<![-])(?:s(?:u(?:[am]|n(?:-(?:s(?:r-(?:iiop(?:-aut|s)?|https?|jm[sx]|admin)|ea-port)|as-(?:j(?:mxrmi|pda)|iiops(?:-ca)?|nodeagt)|user-https|mc-grp|dr|lm)|c(?:acao-(?:(?:jmx|sn)mp|websvc|csa|rmi)|luster(?:geo|mgr))|scalar-(?:dns|svc)|proxyadmin|webadmins?|lps-http|fm-port|vts-rmi|rpc)|r(?:f(?:controlcpa|pass)?|veyinst|-meas|ebox)|b(?:mi(?:tserver|ssion)|ntbcst[-_]tftp)|p(?:er(?:cell|mon)|dup)|it(?:case|jd)|(?:uc|g)p|-mit-tg)|e(?:[pt]|r(?:v(?:er(?:view(?:-(?:asn?|icc|gf|rm)|dbms)|-find|graph|start|wsd2)|i(?:ce(?:-ctrl|meter|tags)|staitsm)|s(?:erv|tat))|comm-(?:scadmin|wlink)|ialgateway|aph)|c(?:-(?:t4net-(?:clt|srv)|pc2fax-srv|ntb-clnt)|ur(?:e-(?:cfg-svr|mqtt|ts)|itychase)|layer-t(?:cp|ls))|n(?:t(?:inel(?:-(?:ent|lm)|srm)?|lm-srv2srv|-lm)|omix0[12345678]|ip|d)|a(?:gull(?:-ai|lm)s|rch-agent|odbc|view)|ma(?:phore|ntix)|ispoc|si-lm)|y(?:n(?:c(?:hro(?:n(?:et-(?:rtc|upd|db)|ite)|mesh)|server(?:ssl)?|-em7)|o(?:tics-(?:broker|relay)|ptics-trap)|aps(?:e(?:-nhttps?)?|is-edge)|el-data)|s(?:t(?:em(?:-monitor|ics-sox)|at)|log(?:-(?:conn|tls))?|o(?:pt|rb)|info-sp|scanner|comlan|rqd)|base(?:anywhere|-sqlany|dbsynch|srvmon)|m(?:antec-s(?:fdb|im)|b-sb-port|plex)|am-(?:webserver|agent|smc)|pe-transport|chrond)|t(?:[tx]|a(?:r(?:t(?:-network|ron)|(?:quiz-por|bo)t|s(?:chool)?|gatealerts|fish)|t(?:-(?:results|scanner|cc)|s(?:ci[12]-lm|rv)|usd)|nag-5066)|r(?:e(?:et(?:-stream|perfect|talk)|amcomm-ds|sstester|xec-[ds])|yker-com)|o(?:ne(?:-design-1|falls)|r(?:view|man))|un(?:-(?:p(?:[123]|ort)|behaviors?)|s)?|m(?:[-_]pproc|f)|(?:e-sms|dpt)c|(?:gxfw|s)s|i-envision|vp)|i(?:m(?:p(?:l(?:e(?:-(?:push(?:-s)?|tx-rx)|ment-tie)|ifymedia)|-all)|ba(?:service|expres|-c)s|-control|on-disc|slink|ctlp)|l(?:verp(?:eak(?:comm|peer)|latter)|k(?:p[1234]|meter)|houette|c)|t(?:ara(?:(?:serve|di)r|mgmt)|ewatch)|g(?:n(?:et-ctf|al)|ma-port|htline)|x(?:-degrees|xsconfig|netudr|trak)|(?:ft-uf|s-em|ipa)t|e(?:mensgsm|bel-ns)|cct-sdp|ps?|am)|c(?:o(?:-(?:(?:(?:ine|d)t|sys)mgr|websrvrmg[3r]|peer-tta|aip)|tty-(?:disc|ft)|i2odialog|remgr|help|l)|i(?:n(?:tilla|et)|entia-s?sdb|pticslsrvr)|p(?:i-(?:telnet|raw)|-config)?|t(?:e(?:104|30)|p-tunneling)|r(?:eencast|iptview|abble)|c(?:-security|ip-media)|e(?:n(?:ccs|idm)|anics)|an(?:-change|stat-1)|s(?:erv|c)p|up-disc|x-proxy)|a(?:n(?:t(?:ak-up|ool)s|avigator|e-port|ity)|g(?:e(?:-best-com[12]|ctlpanel)|xtsds)|s(?:(?:-remote-hl)?p|g(?:gprs)?)|i(?:s(?:c?m|eh)?|[-_]sentlm)|lient-(?:dtasrv|usrmgr|mux)|m(?:sung-(?:unidex|disc)|d)|b(?:a(?:rsd|ms)|p-signal)|p(?:hostctrls?|v1)|(?:-msg-por|van)t|f(?:etynetp|t)|r(?:atoga|is)|c(?:red)?|h-lm)|m(?:a(?:r(?:t(?:card-(?:port|tls)|-(?:diagnose|lm)|packets|sdp)|-se-port[12])|(?:uth-por|kyne)t|clmgr|-spw|p)|s(?:-(?:r(?:emctrl|cinfo)|chat|xfer)|q?p|d)|p(?:p(?:pd)?|nameres|te)|c-(?:https?|admin|jmx)|-(?:pas-[12345]|disc)|(?:ntubootstra|t)p|i(?:le|p)|wan|ux)|o(?:n(?:us(?:(?:-loggin|callsi)g)?|ar(?:data)?|iqsync)|l(?:id-(?:e-engine|mux)|era-(?:epmap|lpn)|ve)|ft(?:rack-meter|dataphone|audit|cm|pc)|s(?:s(?:ecollector|d-disc))?|a(?:p-(?:bee|htt)p|gateway)|c(?:(?:orf|k)s|p-[ct]|alia)|p(?:hia-lm|s)|undsvirtual|r-update)|n(?:s(?:-(?:a(?:dmin|gent)|qu(?:ery|ote)|dispatcher|channels|protocol|gateway)|s)|a(?:p(?:[dp]|enetio)?|(?:resecu)?re|(?:-c|ga)s|c)|i(?:ffer(?:client|server|data)|p-slave)|mp(?:dtls(?:-trap)?|-tcp-port|trap)?|t(?:p-heartbeat|lkeyssrvr)|[cp]p)|p(?:e(?:ct(?:ard(?:ata|b)|raport)|edtrace-disc|arway)|s(?:s(?:-lm)?|-tunnel|c)|w-d(?:nspreload|ialer)|a(?:ndataport|mtrap)|i(?:ral-admin|[ck]e)|litlock(?:-gw)?|c(?:sdlobby)?|rams(?:ca|d)|t-automation|ytechphone|oc[kp]|[dm]p|ugna)|s(?:o(?:-(?:control|service)|watch)|m(?:-(?:c(?:ssp|v)|el)s|pp|d)|t(?:p-[12]|sys-lm)?|r(?:-servermgr|ip)|d(?:ispatch|t?p)|h(?:-mgmt|ell)?|sl(?:ic|og)-mgr|c(?:-agent|an)|p(?:-client)?|e-app-config|-idi-disc|7ns|ad|lp|ql)|d(?:p(?:-(?:portmapper|id-port)|roxy)|-(?:capacity|data|elmd)|s(?:-admin|erver|c-lm)?|(?:(?:nsk|m)m|hel|d)p|(?:e-discover|bprox)y|o(?:-(?:ssh|tls))?|t(?:-lmd)?|client|l-ets|func)|w(?:i(?:s(?:mgr[12]|trap|pol)|ft(?:-rvf|net))|(?:eetware-app|ldy-sia)s|x(?:-gate|admin)|r(?:-port|mi)|dtp(?:-sv)?|tp-port[12]|a-[1234])|h(?:a(?:r(?:p-server|eapp)|perai-disc|dowserver)|i(?:va(?:[-_]confsrvr|discovery|sound)|lp)|o(?:ckwave2?|far)|rinkwrap)|l(?:i(?:n(?:kysearch|terbase|gshot)|m-devices)|c-(?:ctrlrloops|systemlog)|p(?:-notify)?|slavemon|m-api|ush)|g(?:i-(?:e(?:ventmond|sphttp)|storman|arrayd|lk)|e[-_](?:qmaster|execd)|mp(?:-traps)?|ci?p|-lm)|k(?:ip-(?:cert-(?:recv|send)|mc-gikreq)|y(?:-transpor|telne)t|ronk)|f(?:t(?:[pu]|dst-port|srv)|s-(?:smp-net|config)|l(?:ow|m)|-lm)|r(?:vc[-_]registry|p-feedback|[dm]p|ssend|cp?)|q(?:l(?:exec(?:-ssl)?|[-*]net|se?rv)|dr)|v(?:n(?:et(?:works)?)?|s-omagent|rloc)|b(?:i-agent|ook|l)|-(?:openmail|net)|8-client-port|x(?:upt|m)p|102|3db)|c(?:o(?:m(?:m(?:plex-(?:link|main)|(?:onspa|er)ce|tact-https?|linx-avl|andport|unity)|p(?:aq-(?:[sw]cp|https|evm)|osit-server|x-lockview|ressnet)|otion(?:master|back)|box-web-acc|cam(?:-io)?|-bardac-dw|s(?:at|cm))|n(?:n(?:e(?:ct(?:-(?:client|server)|ion|ed)?|ndp)|lcli)|t(?:(?:clientm|inuu)s|amac[-_]icm|entserver)|f(?:(?:ig-por|luen)t|erence(?:talk)?)|c(?:urrent-lm|lave-cpp|omp1)|s(?:ul-insight|piracy)|dor)?|r(?:e(?:l(?:[-_]vncadmin|video|ccam)|rjd)|ba(?:-iiop(?:-ssl)?|loc))|d(?:a(?:srv(?:-se)?|auth2)|ima-rtp|emeter)|g(?:n(?:ex-insight|ima)|sys-lm|itate)|l(?:lab(?:orato|e)r|ubris)|p(?:(?:s-tl)?s|y-disc)|a(?:uthor|ps?)|u(?:chdb|rier)|ord-svr|smocall|via)|a(?:n(?:o(?:n-(?:c(?:pp-disc|apt)|bjnp[1234]|mfnp)|central[01])|-(?:(?:ferret|nds)(?:-ssl)?|dch)|d(?:itv|r?p)|ex-watch)|d(?:key-(?:licman|tablet)|(?:abra|si)-lm|encecontrol|is-[12]|view-3d|lock2?)|r(?:t(?:ographerxmp|-o-rama)|d(?:box(?:-http)?|ax)|rius-rshell)|p(?:wap-(?:control|data)|fast-lmd|ioverlan|s-lm|mux)?|l(?:l(?:-(?:sig-trans|logging)|waveiam|trax|er9))?|i(?:(?:storagemg|ds-senso)r|cci(?:pc)?|lic)|s(?:p(?:ssl)?|answmgmt|torproxy|-mapi)?|-(?:[12]|audit-d[as]|web-update|idms)|b(?:-protocol|leport-ax|sm-comm)|c(?:sambroker|i-lm)|u(?:pc-remote|tcpd)|m(?:bertx-lm|ac|p)|t(?:chpole|alyst)|ac(?:lang2|ws)|e(?:rpc|vms)|jo-discovery|was)|s(?:o(?:ft(?:-p(?:lusclnt|rev)|ragent|1))?|-(?:remote-db|auth-svr|services|live)|d(?:-m(?:gmt-port|onitor)|m(?:base)?)|p(?:m(?:lockmgr|ulti)|(?:clmult|un)i)|c(?:c(?:firewall|redir)|p)|(?:bphonemast|listen)er|vr(?:-(?:ssl)?proxy)?|(?:regagen|t-por)t|n(?:et-ns|otify)|i-(?:lfa|sgw)p|ms2?)|i(?:s(?:co(?:-(?:s(?:ccp|nat|ys)|(?:ipsl|fn)a|t(?:dp|na)|vpath-tun|net-mgmt|redu|wafs)|csdb)|-secure)?|t(?:rix(?:ima(?:client)?|-rtmp|admin)|y(?:search|nl)|adel)|n(?:egrfx-(?:elmd|lm)|dycollab)|phire-(?:data|serv)|ch(?:ild-lm|lid)|3-software-[12]|m(?:plex|trak)|rcle-x|fs)|l(?:o(?:anto-(?:net-1|lm)|udsignaling|se-combat)|-(?:db-(?:re(?:quest|mote)|attach)|1)|ea(?:r(?:case|visn)|nerliverc)|a(?:riion-evr01|ssic)|ient-(?:wakeup|ctrl)|u(?:ster-disc|tild)|vm-cfg|\/1|p)|p(?:q(?:rpm-(?:server|agent)|-(?:tasksmart|wbem))|-(?:spx(?:rpts|dpy|svr)|cluster)|lscrambler-(?:al|in|lg)|d(?:i-pidas-cm|lc)|(?:udpenca|pd)p|sp?)|e(?:r(?:t-(?:initiato|responde)r|nsysmgmtagt|a-bcm)|sd(?:cd(?:ma|tr)n|inv)|nt(?:erline|ra)|quint-cityid|dros[-_]fds|fd-vmp|latalk|csvc)|r(?:uise-(?:(?:swrou|upda)te|config|diags|enum)|e(?:ative(?:partn|serve)r|stron-c[it]p)|(?:-websystem|msbit)?s|i(?:nis-hb|p)|yptoadmin)|h(?:i(?:ldkey-(?:notif|ctrl)|p(?:-lm|per)|mera-hwm)|e(?:ck(?:(?:point-rt|su)m|outdb)|vinservices)|ar(?:setmgr|gen)|romagrafx|shell|md)|t(?:i(?:(?:programloa|-redwoo)d|systemmsg)|d(?:[bp]|hercules)|x(?:-bridge|lic)|echlicensing|p(?:-state)?|t-broker|2nmcs|[cs]d|lptc|f)|c(?:m(?:a(?:il|d)|-port|comm|rmi)|s(?:-software|s-q[ms]m)|u-comm-[123]|-tracking|tv-port|ag-pib|owcmr|nx|p)|y(?:b(?:(?:org-system|ro-a-bu)s|ercash)|c(?:leserv2?)?|mtec-port|link-c|tel-lm|aserv)|d(?:[ns]|(?:l-serv|brok)er|3o-protocol|(?:fun)?c|dbp-alt|id)|u(?:mulus(?:-admin)?|s(?:eeme|tix)|elink-disc|illamartin)|m(?:ip-(?:agent|man)|a(?:dmin)?|mdriver|c-port|tp-av)?|v(?:c(?:[-_]hostd)?|s(?:pserver|up)|m?mon|d)|n(?:rp(?:rotocol)?|(?:[ac]|hr)p|s-srv-port)|g(?:n-(?:config|stat)|i-starapi|ms)|f(?:t-[01234567]|engine|dptkt|s)|b(?:(?:os-ip-por)?t|server|a8)|qg-netlan(?:-1)?|-h-it-port|1222-acse|wmp|xws|3)|a(?:p(?:p(?:l(?:e(?: remote desktop \(net assistant\)|-(?:vpns-rp|licman|sasl)|qtc(?:srvr)?|ugcontrol)|i(?:ance-cfg|x)|us)|s(?:erv-https?|witch-emp|s-lm)|arenet-(?:(?:tp?|a)s|ui)|man-server|iq-mgmt|worxsrv)|c(?:-(?:2(?:16[01]|260)|3(?:052|506)|545[456]|654[789]|995[012]|784[56]|necmp)|upsd)|o(?:llo-(?:(?:statu|gm)s|admin|relay|data|cc)|geex-port|cd)|e(?:x-(?:edge|mesh)|rtus-ldp)|w(?:-registry|i-disc)|x500api-[12]|ani[12345]|m-link|ri-lm|dap|lx)?|c(?:c(?:e(?:ss(?:builder|network)|l(?:enet-data)?)|u(?:racer(?:-dbms)?|-lmgr)|topus-st|ord-mgc|-raid)|p(?:-(?:p(?:o(?:licy|rt)|roto)|discovery|conduit)|tsys)?|m(?:aint[-_](?:trans|db)d|s(?:oda)?|e)|e-(?:s(?:vr-prop|erver)|client|proxy)|t(?:ive(?:memory|sync)|net|er)|-(?:cluster|tech)|l-manager|r-nema|a[ps]|d-pm|is?|net)|s(?:p(?:e(?:n(?:-services|tec-lm)|clmd)|coordination|rovatalk)|i(?:p(?:-webadmin|registry)|hpi|a)?|c(?:trl-agent|omalarm|-slmd|i-val)|t(?:er(?:gate-disc|ix)|romed-main)|a(?:-appl-proto|p-udp|m)?|s(?:uria-slm|oc-disc)|-(?:servermap|debug)|f(?:-secure)?-rmcp|naacceler8db|oki-sma|mp-mon|dis|r)|r(?:m(?:a(?:getronad|dp)|centerhttps?|techdaemon|i-server)|d(?:us(?:-(?:m?trns|cntl)|mul|uni)|t)|i(?:e(?:s-kfinder|l[123])|liamulti|a)|e(?:pa-(?:raft|cas)|na-server)|(?:ray-manag|uba-serv)er|s-(?:master|vista)|c(?:isdms|pd?)|gis-(?:ds|te)|bortext-lm|tifact-msg|kivio|ns)|l(?:t(?:a(?:v-(?:remmgt|tunnel)|-ana-lm|link)|ova(?:-lm-disc|central)|serviceboot|(?:bsd|c)p)|l(?:(?:storcn|peer)s|joyn(?:-mcm)?)|ar(?:m(?:-clock-[cs])?|is-disc)|p(?:ha(?:tech-lm|-sms)|es)|(?:esquer|chem)y|mobile-system|fin|ias)|m(?:t(?:-(?:(?:(?:cnf|esd)-pro|blc-por)t|redir-t(?:cp|ls)|soap-https?))?|x-(?:web(?:admin|linx)|axbnet|icsp|rms)|i(?:con-fpsu-(?:ra|s)|ganetfs|net)|p(?:r-(?:in(?:ter|fo)|rcmd)|ify)?|b(?:it-lm|eron)|(?:qp|c)s?|dsched|anda|s)|t(?:m(?:-(?:zip-office|uhas)|(?:tc)?p)|-(?:[3578]|(?:rtm|nb)p|echo|zis)|tachmate-(?:(?:s2|ut)s|g32)|c-(?:appserver|lm)|s(?:c-mh-ssc)?|i-ip-to-ncpe|ex[-_]elmd|hand-mmp|links|ul)|u(?:t(?:o(?:cue(?:time|smi|ds)|(?:no|pa)c|desk-n?lm)|h(?:entx)?)|r(?:[ap]|ora(?:-(?:balaena|cmgr))?|i(?:ga-router|s))|di(?:o(?:-activmail|juggler)|t(?:-transfer|d)?))|v(?:a(?:nt(?:i[-_]cdp|ageb2b)|uthsrvprtcl|ilant-mgr)|i(?:nstalldisc|va-sna|an)|ocent-(?:adsap|proxy)|t(?:-profile-[12]|p)|-emb-config|en(?:ue|yo)|securemgmt|decc)|n(?:s(?:ys(?:l(?:md|i)|-lm)|a(?:notify|trader)|oft-lm-[12]|wersoft-lm|-console)|t(?:idotemgrsvr|hony-data)|et(?:-[bhlm])?|oto-rendezv|-pcp|d-lm)|f(?:s(?:3-(?:(?:(?:file|ka|pr)serv|v(?:lserv|ols))er|(?:error|rmtsy|bo)s|callback|update))?|(?:ore-vdp-dis|esc-m)c|povertcp|filiate|tmux|rog)?|d(?:(?:te(?:mpusclien|ch-tes)|i-gxp-srvpr)t|a(?:p(?:t(?:ecmgr|-sna))?|-cip)|obeserver-[12345]|min(?:s-lms|d)|s(?:-c)?|vant-lm|rep)|i(?:r(?:s(?:hot|ync)?|onetddp)|c(?:-(?:oncrpc|np)|c-cmi)|mpp-(?:port-req|hello)|pn-(?:auth|reg)|agent|bkup|ses)|b(?:a(?:t(?:emgr|jss)|cus-remote|rsd)|c(?:voice-port|software)|b(?:accuray|-escp|s)|r-(?:secure|api)|out)|g(?:ent(?:sease-db|view|x)|ri(?:-gateway|server)|p(?:s-port|olicy)|cat|slb)|e(?:s(?:-(?:discovery|x170)|op)|ro(?:flight-(?:ads|ret))?|d-512|gate)|1(?:[45]|(?:[67]-an|3)-an|-(?:msc|bs))|2(?:1-an-1xbs|6-fap-fgw|7-ran-ran)|(?:h(?:-esp-enca|s)|ker-cd)p|a(?:irnet-[12]|l-lm|m?p|s)|w(?:acs-ice|g-proxy|s-brf)|o(?:l(?:-[123])?|cp|dv)|x(?:is-wimp-port|on-lm)|z(?:eti-bd|tec)|[34]-sdunode|ja-ntv4-disc|yiya)|m(?:s(?:-(?:s(?:na-(?:server|base)|(?:-s)?ideshow|treaming|ql-[ms]|huttle|mlbiz)|(?:(?:aler|thea)t|wbt-serv)er|r(?:ule-engin|om)e|l(?:icensing|a)|cluster-net|olap[1234]|v-worlds)|f(?:w-(?:(?:s-)?storage|control|replica|array)|t-gc(?:-ssl)?|rs)|i(?:-(?:cps-rm-disc|selectplay)|ccp|ms)|g(?:-(?:auth|icp)|s(?:rvr|ys)|clnt)|(?:r-plugin-por|hne)t|d(?:fsr|ts1|p)|exch-routing|olap-ptp2|p(?:-os)?|l[-_]lmd|ync|mq|np)|e(?:d(?:i(?:a(?:cntrlnfsd|vault-gui|-agent|space|box)|mageportal)|-(?:(?:sup|lt)p|fsp-[rt]x|net-svc|ovw|ci))|t(?:a(?:edit-(?:mu|se|ws)|s(?:torm|age|ys)|tude-mds|console|-corp|agent|gram|5)|ric(?:s-pas|adbc)|er)|n(?:andmice(?:-(?:dns|lpm|mon|noh)|_noh)|ta(?:client|server))|ga(?:r(?:dsvr-|egsvr)port|co-h248)|s(?:sage(?:service|asap)|avistaco)|r(?:c(?:ury-disc|antile)|egister)|mcache|comm|vent)|a(?:g(?:ic(?:notes|om)|aya-network|enta-logic|bind|pie)|i(?:n(?:control|soft-lm)|l(?:box-lm|prox|q)|trd)|c(?:-srvr-admin|romedia-fcs|on-udp|bak)|pper-(?:(?:ws[-_]|map)ethd|nodemgr)|n(?:yone-(?:http|xml)|age-exec|et)|r(?:kem-dcp|cam-lm)|x(?:im-asics|umsp)?|d(?:ge-ltd|cap)|s(?:qdialer|c)|tip-type-[ab]|ytagshuffle|o)|i(?:c(?:ro(?:muse-(?:ncp[sw]|lm)|talon-(?:com|dis)|s(?:oft-ds|an)|com-sbp)|om-pfs|e)|n(?:i(?:-sql|lock|vend|pay)|d(?:filesys|print)|otaur-sa|ger)|t(?:-(?:ml-de|do)v|eksys-lm)|l(?:-2045-47001|es-apart)|r(?:oconnect|rtex|a)|(?:pv6tl|va-mq)s|b-streaming|dnight-tech|ami-bcast|key|mer)|c(?:s-(?:m(?:essaging|ailsvr)|calypsoicf|fastmail)|-(?:(?:brk|gt)-srv|c(?:lient|omm)|appserver)|t(?:et-(?:gateway|master|jserv)|feed|p)|(?:(?:(?:cwebsv|e)r-|re)por|agen)t|n(?:s-(?:tel-ret|sec)|tp)|(?:2studio|ida|3s)s|(?:k-ivpi|ft)p|p(?:-port)?)|o(?:s(?:-(?:(?:low|upp)er|soap(?:-opt)?|aux)|ai(?:csyssvc1|xcc)|hebeeri)|b(?:il(?:e(?:-(?:file-dl|p2p)|ip-agent)|i(?:tysrv|p-mn))|rien-chat)|n(?:(?:tage-l|keyco)m|itor|dex|p)?|l(?:dflow-lm|ly)|rtgageware|vaz-ssc|y-corp|untd)|p(?:s(?:(?:ysrmsv|serve)r|-raft|hrsv)|njs(?:o(?:m[bg]|cl|sv)|c)|p(?:olicy-(?:mgr|v5))?|l(?:-gprs-port|s-pm)|m(?:-(?:flags|snd))?|f(?:oncl|wsas)|idc(?:agt|mgr)|c-lifenet|hlpdmc|tn)|u(?:lti(?:p(?:-msg|lex)|cast-ping|ling-http)|s(?:t-(?:backplane|p2p)|(?:iconlin)?e)|r(?:ray|x)|pdate|mps|nin)|y(?:sql(?:-(?:c(?:m-agent|luster)|proxy|im))?|(?:nahautostar|blas)t|l(?:ex-mapd|xamport)|q-termlink|rtle)|t(?:p(?:ort(?:-regist|mon))?|cevrunq(?:man|ss)|-scaleserver|l8000-matrix|i-tcs-comm|rgtrans|qp|n)|g(?:c(?:p-(?:callagent|gateway)|s-mfp-port)|e(?:supervision|management)|xswitch)|d(?:ns(?:responder)?|(?:-cg-ht)?tp|bs[-_]daemon|c-portmapper|ap-port|qs)|n(?:(?:p-exchang|gsuit)e|et-discovery|i-prot-rout|s-mail)|m(?:a(?:-discovery|comm|eds)|c(?:als?|c)|pft)|v(?:(?:el|x)-lm|s-capacity)|b(?:l-battd|g-ctrl|us)|r(?:ssrendezvous|ip|m)|x(?:xrlogin|omss|it?)|f(?:server|cobol|tp)|qe-(?:broker|agent)|2(?:mservices|ua)|z(?:ca-alert|ap)|l(?:oadd|sn|e)|4-network-as|km-discovery|3da-disc|-wnn)|i(?:n(?:t(?:e(?:r(?:s(?:ys-cache|erver|an)|act(?:ionweb)?|w(?:orld|ise)|hdl[-_]elmd|pathpanel|intelli|base)|l(?:-rci(?:-mp)?|listor-lm|_rci|sync)|gr(?:a(?:-sme|l)|ius-stp)|co(?:m-ps[12]|urier))|u(?:-ec-(?:svcdisc|client)|itive-edge)|r(?:a(?:intra|star)|epid-ssl|insa)|-rcv-cntrl|v)|f(?:o(?:rm(?:atik-lm|er)|(?:brigh|cryp)t|m(?:over|an)|libria|exch|seek|wave|tos)|iniswitchcl|luence)|d(?:i(?:go-(?:v(?:bcp|rmi)|server))?|ex-(?:pc-wb|net)|x-dds|ura|y)|s(?:t(?:l[-_]boot[cs]|-discovery|antia)|i(?:tu-conf|s)|pect)|i(?:nmessaging|serve-port|tlsmsad)|ova(?:port[123456]|-ip-disco)|gres(?:-net|lock)|c(?:ognitorv|p)|nosys(?:-acl)?|vision(?:-ag)?|business)|s(?:o(?:-(?:t(?:sap(?:-c2)?|p0s?)|i(?:ll|p))|ipsigport-[12]|de-dua|ft-p2p|mair)|i(?:s(?:-(?:am(?:bc)?|bcast))?|-(?:irp|gl))|m(?:aeasdaq(?:live|test)|server|c)|c(?:si(?:-target)?|ape|hat)|s(?:-mgmt-ssl|d)|bconference[12]|p(?:ipes|mmgr)|n(?:etserv|s)|g-uda-server|rp-port|99[cs]|ysg-lm|d[cd]|akmp|lc)|c(?:l(?:pv-(?:(?:[dp]|ws)m|s(?:as|c)|nl[cs])|cnet(?:-(?:locate|svinfo)|_svinfo)|-twobase(?:[23456789]|10?))|e(?:-s?(?:location|router)|edcp[-_][rt]x)|g-(?:iprelay|bridge|swp)|a(?:browser|d-el|p)?|on(?:-discover|p)|p(?:v2|p)?|crushmore|m(?:pd|s)|slap|i)|b(?:m(?:-(?:d(?:i(?:radm(?:-ssl)?|al-out)|(?:t-|b)2)|m(?:q(?:series2?|isdp)|gr)|r(?:syscon|es)|a(?:btact|pp)|(?:cic|pp)s|wrless-lan|ssd)|_wrless_lan|3494)|ridge-(?:data|mgmt)|(?:eriagame|u)s|p(?:rotocol)?|ar)|p(?:[px]|c(?:s(?:-command|erver)|d3?|ore)|d(?:tp-port|cesgbs|r-sp|d)|-(?:provision|qsig|blf)|(?:ether232por|r-dgl)t|h-policy-(?:adm|cli)|se(?:c-nat-t|ndmsg)|f(?:ltbcst|ixs?)|(?:ulse-ic|as)s|t-anri-anri)|d(?:e(?:afarm-(?:panic|door)|n(?:-ralp|tify)|esrv)|o(?:nix-metane|tdis)t|a(?:-discover[12]|c)|p(?:-infotrieve|s)?|m(?:gratm|aps)|ware-router|ig[-_]mux|[cfx]p|rs)|m(?:a(?:ge(?:query|pump)|p[3s]?)|q(?:tunnels?|brokerd)|ip(?:-channels)?|tc-m(?:ap|cs)|medianet-bcn|p(?:era|rs)|s(?:ldoc|p)|oguia-port|docsvc|games|yx)|t(?:a(?:c(?:tionserver[12]|h)|-(?:manager|agent)|p-ddtp|lk)|m-(?:mc(?:ell-[su]|cs)|lm)|e(?:lserverport|m)|o(?:-e-gui|se)|v-control|internet|scomm-ns)|a(?:s(?:-(?:a(?:dmind|uth)|(?:pagin|re)g|neighbor|session)|control(?:-oms)?|d)|tp-(?:normal|high)pri|f(?:server|dbase)|nywhere-dbns|dt-disc|pp|x)|r(?:is(?:-(?:xpcs?|beep|lwz)|a)|a(?:cinghelper|pp)|d(?:g-post|mi2?)|on(?:storm|mail)|c(?:-serv)?|trans)|v(?:(?:collecto|manage)r|s(?:-video|d)|econ-port|ocalize)|f(?:s(?:f-hb-port|p)|or-protocol|e[-_]icorp|cp-port)|w(?:(?:listen|serv)er|b-whiteboard|-mmogame|ec|g1)|e(?:e(?:e-m(?:ms(?:-ssl)?|ih)|-qfx)|c-104|s-lm)|g(?:o-incognito|r(?:id|s)|mpv3lite|i-lm|cp)|o(?:(?:-dist-grou)?p|nixnetmon|c-sea-lm)|q(?:(?:net-por|objec)t|server|rm|ue)|i(?:-admin|w-port|ms|op)|-(?:net-2000-npr|zipqd)|3-sessionmgr|l(?:[dl]|ss)|ua|zm)|n(?:e(?:t(?:b(?:i(?:ll-(?:(?:cre|pro)d|keyrep|trans|auth)|os-(?:dgm|ssn|ns))|oo(?:kmark|t-pxe)|lox)|s(?:c(?:-(?:prod|dev)|ript)|peak-(?:(?:cp?|i)s|acd)|erialext[1234]|upport2?|teward)|c(?:o(?:nf(?:soap(?:bee|htt)p|-(?:beep|ssh))|mm2)|h(?:eque|at)|(?:li)?p|elera)|o(?:p(?:-(?:school|rc)|ia-vo[12345]|s-broker)|-(?:wol-server|dcs)|bjects[12])|w(?:a(?:tcher-(?:mon|db)|re-(?:cs|i)p|ve-ap-mgmt|ll)|kpathengine|orklens?s)|i(?:q(?:-(?:endp(?:oin)?t|qcheck|voipa|ncap|mc))?|nfo-local)|m(?:o(?:-(?:default|http)|unt|n)|a(?:p[-_]lm|gic)|pi|l)|x(?:ms-(?:(?:agen|mgm)t|sync)|-(?:server|agent))|view(?:-aix-(?:[23456789]|1[012]?)|dm[123])|r(?:i(?:x-sftm|sk)|js-[1234]|ockey6|cs|ek)|a(?:ttachsdmp|dmin|gent|ngel|spi|rx)|-(?:projection|steward|device)|p(?:la(?:y-port[12]|n)|ort-id)|t(?:gain-nms|est)|eh(?:-ext)?|db-export|2display|labs-lm|8-cman|uitive|news|gw)|w(?:lix(?:(?:confi|re)g|engine)|bay-snc-mc|wavesearch|heights|genpay|-rwho|oak)|x(?:storindltd|us-portal|tstep|gen)|s(?:t-protocol|h-broker|sus)|o(?:d[12]|iface|n24x7)|c(?:-raidplus|kar|p)|i-management|veroffline|rv)|a(?:t(?:i-(?:vi-server|svrloc|logos|dstp)|dataservice|tyserver|uslink)|v(?:isphere(?:-sec)?|-(?:data|port)|egaweb-port|buddy)|m(?:e(?:server|munge)?|p)|s(?:-metering|manager)?|-(?:localise|er-tip)|cnl|ap|ni)|i(?:m(?:-(?:vdrshell|wan)|r(?:od-agent|eg)|s(?:pooler|h)|controller|aux|gtw|hub)?|c(?:e(?:tec-(?:nmsvc|mgmt)|link)|name)|-(?:visa-remote|mail|ftp)|linkanalyst|p(?:robe)?|observer|fty-hmi|trogen|naf|rp)|o(?:v(?:a(?:r-(?:global|alarm|dbase)|storbakcup|tion)|ell-(?:lu6[-.]2|ipx-cmd|zen))|t(?:ify(?:[-_]srvr)?|e(?:share|it)|ateit-disc)|(?:rton-lamber|wcontac)t|a(?:(?:apor|gen)t|dmin)|kia-ann-ch[12]|mdb)|m(?:s(?:[dp]|-(?:topo-serv|dpnss)|_topo_serv|igport|server)?|-(?:game-(?:server|admin)|asses(?:-admin|sor))|(?:a(?:soveri)?|m)p|ea-(?:onenet|0183)|c-disc)|s(?:s(?:a(?:gen|ler)tmgr|ocketport|-routing|tp)?|jtp-(?:ctrl|data)|(?:-cfg)?-server|c-(?:posa|ccs)|deepfreezectl|w(?:-fe|s)|(?:rm?)?p|iiops|t)?|c(?:(?:a(?:cn-ip-tc|dg-ip-ud)|xc)p|d(?:loadbalance|mirroring)|p(?:m-(?:hip|ft|pm))?|u(?:-[12]|be-lm)|r[-_]ccl|config|ld?|ed)|d(?:m(?:-(?:(?:request|serv)er|agent-port)|p)|l-(?:a(?:[alp]s|hp-svc)|tcp-ois-gw)|s(?:[-_]sso|connect|auth|p)|np?|tp)|p(?:mp(?:-(?:local|trap|gui))?|d(?:s-tracke|bgmng)r|ep-messaging|(?:pm)?p)|u(?:t(?:s[-_](?:bootp|dem))?|cleus(?:-sand)?|paper-ss|auth|xsl|fw)|b(?:x-(?:(?:di|se)r|au|cc)|t-(?:wol|pc)|urn[-_]id|db)|f(?:s(?:d-keepalive|rdma)?|oldman|a)|2(?:(?:nremot|receiv)e|h2server)|l(?:g-data|ogin|s-tl)|t(?:a(?:-[du]s|lk)|p)|v(?:-video|cnet|d)|1-(?:rmgmt|fwp)|h(?:server|ci)|n(?:tps?|s?p)|x(?:edit|lmd)|(?:g-umd|q)s|jenet-ssl|w-license|rcabq-lm|kd)|p(?:r(?:o(?:s(?:hare(?:[12]|(?:audi|vide)o|-mc-[12]|request|notify|data)|pero(?:-np)?)|fi(?:net-(?:rtm?|cm)|le(?:mac)?)|a(?:ctiv(?:esrvr|ate)|xess)|x(?:i(?:ma-l)?m|y-gateway)|d(?:igy-intrnet|uctinfo)|(?:pel-msgsy|gistic)s|(?:-e|of)d|cos-lm|link)|i(?:v(?:ate(?:chat|wire|ark)|ilege|oxy)|nt(?:er(?:[-_]agent)?|-srv)|sm(?:iq-plugin|-deploy)|ority-e-com|maserver|zma)|e(?:cise-(?:comm|sft|vip|i3)|s(?:onus-ucnet|ence|s)|lude)|(?:chat-(?:serv|us)|regist)er|n(?:request|status)|a(?:[-_]elmd|t)|m-[ns]m(?:-np)?|(?:sv|g)?p)|a(?:r(?:a(?:(?:dym-31por|gen)t|llel)|sec-(?:(?:mast|pe)er|game)|(?:k-age|lia)nt|timage)|n(?:a(?:golin-ident|sas)?|do-(?:pub|sec)|golin-laser)|trol(?:-(?:(?:mq-[gn]|is)m|coll|snmp)|view)?|ss(?:w(?:rd-policy|ord-chg)|go(?:-tivoli)?)|y(?:cash-(?:online|wbp)|-per-view|router)|g(?:o-services[12]|ing-port)|l(?:ace-[123456]|com-disc)|c(?:(?:erforu|o)m|mand)|(?:dl2si|fec-l)m|mmr(?:at|p)c|wserv)|c(?:-(?:mta-addrmap|telecommute)|p(?:-multicast|tcpservice)?|i(?:a(?:-rxp-b|rray)|hreq)|le(?:multimedia|-infex)|anywhere(?:data|stat)|c-(?:image-port|mfp)|s(?:ync-https?|-pcw)|t(?:tunnell|rader)|o(?:nnectmgr|ip)|mail-srv)|o(?:w(?:er(?:g(?:uardian|emplus)|alert-nsa|clientcsf|exchange|school|burst|onnud)|wow-(?:client|server))|p(?:up-reminders|3s?|2)|l(?:icyserve|esta)r|rtgate-auth|stgresql|v-ray)|e(?:r(?:son(?:a(?:l(?:-(?:agent|link)|os-001))?|nel)|i(?:scope|mlan)|f(?:-port|d)|mabit-cs)|g(?:asus(?:-ctl)?|board)|er(?:book-port|wire)|(?:arldoc-xac|por)t|-mike|help)|i(?:c(?:trography|colo|knfs|odbc|hat)|p(?:e(?:[-_]server|s))?|ng(?:-pong|hgl)|r(?:anha[12]|p)|m-rp-disc|t-vpn)|l(?:a(?:ysta2-(?:app|lob)|to(?:-lm)?)|(?:cy-net-svc|uribu)s|bserve-port|ysrv-https?|ethora|gproxy)|d(?:a(?:-(?:data|gate|sys)|(?:p-n)?p)|(?:[ru]nc|efmn)?s|l-datastream|-admin|net|ps?|tp|b)|k(?:t(?:cable(?:mm|-)cops|-krb-ipsec)|ix-(?:timestamp|3-ca-ra)|-electronics|agent)?|h(?:o(?:ne(?:x-port|book)|enix-rpc|turis)|ar(?:masoft|os)|relay(?:dbg)?|ilips-vc)?|m(?:c(?:[ps]|d(?:proxy)?)|ip6-(?:cntl|data)|d(?:fmgt|mgr)?|sm-webrctl|-cmdsvr|as)|s(?:(?:(?:(?:d?b|pr?|r)s)?erv|l(?:serv|ics))er|c(?:ribe|upd)|-ams|mond|sc?)|n(?:et-(?:conn|enc)|-requester2?|aconsult-lm|bs(?:cada)?|rp-port|s)|t(?:p(?:-(?:general|event))?|cnameservice|2-discover|k-alink)|xc-(?:s(?:p[lv]r(?:-ft)?|apxom)|epmap|ntfy|roid|pin)|p(?:t(?:conference|p)|s(?:uitemsg|ms)|control)|w(?:g(?:ippfax|wims|psi)|d(?:gen|is)|rsevent)|u(?:p(?:router|arp)|lsonixnls|renoise|mp)|v(?:sw(?:-inet)?|uniwien|xpluscs)|2(?:p(?:community|group|q)|5cai)|-net-(?:remote|local)|f(?:u-prcallback|tp)|q-lic-mgmt|4p-portal|jlink|yrrho|gps)|d(?:i(?:r(?:ec(?:t(?:v(?:-(?:catlg|soft|tick|web)|data)|play(?:srvr|8)?|net)?|pc-(?:video|dll|si))|gis)|s(?:c(?:p-(?:client|server)|overy-port|lose|ard)|t(?:inct(?:32)?|-upgrade|cc))|a(?:l(?:og(?:ic-elmd|-port)|pad-voice[12])|g(?:nose-proc|mond)|mondport)|c(?:om(?:-(?:iscl|tls))?|t(?:-lookup)?|-aida)|gi(?:tal-(?:notary|vrc)|vote|man)|-(?:(?:tracewar|as)e|drm|msg)|f-port|xie)|e(?:c(?:-(?:mbadmin(?:-h)?|notes|dlm)|a(?:uth|p)|vms-sysmgt|ladebug|_dlm|bsrv)|l(?:l(?:webadmin-[12]|-rm-port|pwrappks)|os-dms|ta-mcp|ibo)|-(?:s(?:erver|pot)|cache-query|noc)|s(?:k(?:top-dna|share|view)|cent3)|v(?:shr-nts|basic|ice2?)|nali-server|rby-repli|i-icda|os)|s(?:m(?:cc-(?:c(?:onfig|cp)|download|passthru|session)|eter[-_]iatc|-scm-target|ipv6)|-(?:s(?:rvr?|lp)|admin|clnt|mail|user)|(?:lremote-mgm|x-agen)t|e(?:rver|tos)|p(?:3270)?|om-server|f(?:gw)?|siapi|atp|dn|c)|a(?:t(?:a(?:-(?:insurance|port)|surfsrv(?:sec)?|captor|lens)|ex-asn|usorb)|n(?:dv-tester|f-ak2)|(?:rcorp-l|qstrea)m|s(?:hpas-port|p)|b-sti-c|li-port|vsrcs?|ytime|ishi|ap|wn)|o(?:c(?:umentum(?:[-_]s)?|(?:-serve|sto)r|e(?:ri-view|nt)|1lm)|m(?:ain(?:time)?|iq)|(?:wntools|ip)-disc|glms-notify|nnyworld|ssier|om)|b(?:control(?:-(?:agent|oms)|_agent)|(?:a(?:bbl|s)|brows)e|isamserver[12]|re(?:porter|f)|s(?:a-lm|tar)|-lsp-disc|eregister|db|m)|t(?:a(?:-systems|g-ste-sb)|p(?:-(?:dia|net)|t)?|s(?:erver-port|pcd)?|n(?:-bundle|1)|v-chan-req|k)|n(?:6-(?:nlm-au|smm-re)d|s(?:-llq|2go|ix)|a(?:-cml|p)?|p(?:-sec)?|c-port|o?x)|h(?:c(?:p(?:v6-(?:client|server)|-failover2?)|t-(?:alert|statu)s)|e)|p(?:s(?:erve(?:admin)?|i)|(?:i-p)?roxy|m(?:-agent)?|keyserv|[ac]p)|r(?:m(?:-production|s(?:fsd|mc))|i(?:veappserver|p)|agonfly|wcs|p)|v(?:t-(?:system|data)|l-activemail|cprov-port|bservdsc|r-esm|apps)|l(?:s(?:-mon(?:itor)?|r(?:ap|pn)|wpn)?|[-_]agent|ms-cosem|ip)|2(?:k-(?:datamover|tapestry)[12]|000(?:webserver|kernel))|d(?:m-(?:dfm|rdb|ssl)|i-udp-[1234567]|ns-v3|repl|dp|gn|t)|c(?:s(?:-config|oftware)?|c(?:p-udp|m)|utility|t?p|a)|m(?:(?:af-cast|docbrok)er|od-workspace|express|idi|p)|yn(?:a(?:-(?:access|lm)|mi(?:c3)?d)|iplookup|-site)|x(?:messagebase[12]|-instrument|admind|spider)|-(?:data(?:-control)?|cinema-rrp|fence|s-n)|w(?:(?:msgserve)?r|nmshttp|f)|z(?:oglserver|daemon)|f(?:(?:ox)?server|n)|k(?:messenger|a)|j-i(?:ce|lm)|gpf-exchg|3winosfi)|t(?:r(?:i(?:m(?:-(?:event|ice))?|(?:tium-ca|omotio)n|s(?:pen-sra|oap)|p(?:(?:wir)?e)?|dent-data|quest-lm|vnet[12]|butary)|a(?:p(?:-(?:port(?:-mom)?|daemon))?|v(?:soft-ipx-t|ersal)|ns(?:mit-por|ac)t|c(?:eroute|k)|ingpsdata|gic|m)|u(?:ste(?:stablish|d-web)|ckstar|ecm)|e(?:ndchip-dcp|ehopper)|-rsrb-p(?:[123]|ort)|nsprntproxy|c-netpoll|p)|a(?:l(?:arian-(?:m(?:cast[12345]|qs)|udp)|on-(?:webserver|engine|disc)|i(?:kaserver|gent-lm)|-pod|net|k)|s(?:kma(?:ster2000|n-port)|erver|p-net)|c(?:(?:ac(?:s-d)?|new)s|ticalauth)|r(?:gus-getdata[123]?|antella)|p(?:e(?:stry|ware)|pi-boxnet)|g-(?:ups-1|pm)|m(?:bora|s)|ep-as-svc|urus-wh|iclock|bula)|e(?:l(?:e(?:(?:niumdaemo|sis-licma)n|lpath(?:attack|start)|finder)|l(?:umat-nms)?|net(?:cpcd|s)?|aconsole|ops-lmd|indus)|r(?:a(?:dataordbms|base)|minaldb|edo)|(?:c5-sdct|edta)p|mp(?:est-port|o)|amcoherence|trinet|nfold|kpls|xar)|i(?:m(?:e(?:stenbroker|flies|lot|d)?|buktu(?:-srv[1234])?)|p(?:[2c]|-app-server)|vo(?:connect|li-npm)|c(?:f-[12]|k-port)|n(?:ymessage|c)|g(?:v2)?|dp)|t(?:c(?:-(?:etap(?:-[dn]s)?|ssl)|mremotectrl)?|l(?:-publisher|priceproxy)|n(?:repository|tspauto)|g-protocol|at3lb)|c(?:p(?:dataserver|nethaspsrv|-id-port|mux)|o(?:(?:flash|reg)agent|addressbook)|lprodebugger|im-control|c-http)|n(?:-t(?:l-(?:fd[12]|[rw]2)|iming)|p(?:-discover|1-port)?|s-(?:server|adv|cml)|os-(?:dps?|sp)|etos|mpv2)|o(?:(?:mato-spring|uchnetplu|nidod)s|p(?:flow(?:-ssl)?|ovista-data|x)|l(?:teces|fab)|ad)|u(?:n(?:a(?:lyzer|tic)|gsten-https?|stall-pnc|nel)|r(?:bonote-[12]|ns?))|s(?:(?:ccha|rmag)t|(?:spma)?p|dos390|erver|af?|b2?|ilb)|d(?:-(?:postman|replica|service)|p-suite|access|moip)|m(?:o(?:-icon-sync|phl7mts|sms[01])|esis-upshot|i)|v(?:dumtray-port|networkvideo|e-announce|bus|pm)|l(?:1(?:-(?:raw(?:-ssl)?|telnet|ssh|lv))?|isrv)|h(?:e(?:rmo-calc|ta-lm)|t-treasure|r(?:tx|p))|1(?:distproc(?:60)?|-e1-over-ip|28-gateway)|w(?:amp-control|(?:sd|c)ss|-auth-key|rpc)|p(?:csrvr|du|ip|md)|ftp(?:-mcast|s)?|g(?:cconnect|p)|2-[bd]rm|ksocket|qdata|brpf)|e(?:s(?:p(?:-(?:encap|lm)|eech(?:-rtp)?|s-portal)|c(?:ale \(newton dock\)|vpnet|p-ip)|r(?:o-(?:emsdp|gen)|i[-_]sde)|i(?:nstall|mport|p)|m(?:manager|agent)|s(?:web-gw|base|p)|(?:erver-pa|tam)p|nm-zoning|broker|-elmd|l-lm)|m(?:p(?:rise-l(?:ls|sc)|-server[12]|ire-empuma|owerid|erion)|c(?:-(?:xsw-dcache|vcas-udp|gateway)|symapiport|ads|e)|b(?:race-dp-[cs]|-proj-cmd|l-ndt)|fis-(?:cntl|data)|w(?:avemsg|in)|s(?:d-port)?|a-sent-lm)|n(?:t(?:rust(?:-(?:a(?:a[am]s|sh)|kmsh|sps)|time)|ext(?:(?:me|xi)d|netwk|high|low)|-engine|p)|c(?:-(?:eps(?:-mc-sec)?|tunnel(?:-sec)?)|rypted(?:-(?:admin|llrp)|_admin)|ore)|l(?:-name)?|p[cp]|rp)|l(?:(?:pro[-_]tunne|fiq-rep)l|vin[-_](?:client|server)|a(?:n(?:lm)?|telink|d)|i(?:pse-rec)?|ektron-admin|m-momentum|c(?:sd|n)|xmgmt|s)|x(?:o(?:line-udp|config|net)|a(?:softport1|pt-lmgr)|c(?:e(?:rpts?)?|w)|p(?:[12]|resspay)|bit-escp|lm-agent|tensis)|d(?:m-(?:m(?:gr-(?:cntrl|sync)|anager)|st(?:d-notify|ager)|adm-notify)|i(?:tbench|x)|b-server[12]|tools)|p(?:(?:-(?:ns|pc)|l-sl)p|ortcomm(?:data)?|n(?:cdp2|sdp)|m(?:ap|d)|t-machine|icon|pc?|c)|t(?:h(?:er(?:net(?:\/|-)ip-[12]|cat)|oscan)|lservicemgr|c-control|(?:ft)?p|ebac5|b4j|s)|c(?:o(?:lor-imager|visiong6-1|mm)|mp(?:-data|ort)|ho(?:net)?|sqdmn|wcfg|n?p)|v(?:e(?:nt(?:-(?:listener|port)|_listener)|rydayrc)|tp(?:-data)?|(?:b-el)?m)|i(?:con-(?:s(?:erver|lp)|x25)|s(?:p(?:ort)?)?|ms-admin)|-(?:d(?:esign-(?:net|web)|pnet)|builder|mdu|net|woa)|w(?:c(?:appsrv|tsp)|-disc-cmd|installer|all|dgs|nn)|q(?:-office-494[012]|uationbuilder|3-config)|f(?:i(?:-(?:lm|mg)|diningport)|orward|cp)|h(?:(?:p-backu|t)p|s(?:-ssl)?|ome-ms)|z(?:(?:meeting|proxy)(?:-2)?|relay)|r(?:istwoguns|golight|pc)|a(?:sy-soft-mux|psp|1)?|ye(?:2eye|link|tv)|(?:udora-s|en)et|o(?:r-game|ss)|b(?:insite|a)|3consultants|g(?:ptlm|s))|r(?:e(?:m(?:ote(?:-(?:(?:ki|a)s|winsock|collab)|ware-(?:srv|cl|un)|deploy|fs)|ctl)|d(?:sto(?:rm[-_](?:diag|find|info|join)|ne-cpss)|wood-chat)|s(?:ponse(?:logic|net)|ource[-_]mgr|(?:-s|c)ap|acommunity)?|a(?:l(?:m-rusd|secure)|chout)|p(?:s(?:cmd|vc)|liweb|cmd)|-(?:conn-proto|mail-ck)|t(?:s(?:-ssl)?|rospect)|c(?:vr-rc-disc|ipe)|l(?:lpack|ief)|gistrar|ftek|xecj|101|bol)|a(?:d(?:i(?:us(?:-(?:dynauth|acct))?|o(?:-bc)?|x)|(?:an-htt|ec-cor)p|min(?:-port|d)|wiz-nms-srv|clientport|sec)|p(?:i(?:d(?:mq-(?:center|reg)|base|o-ip))?|-(?:service|listen|ip))?|ve(?:n(?:t(?:bs|dm)|-r[dm]p)|hd)|id-(?:a[cm]|c[ds]|sf)|t(?:io-adp|l)|qmon-pdu|w-serial|admin|sadv|zor|mp)|t(?:-(?:(?:classmanag|view)er|event(?:-s)?)|s(?:p(?:-alt|s)?|client|serv)|ps-d(?:iscovery|d-[mu]t)|c(?:-pm-port|m-sc104)|(?:mp-por|elne)t|raceroute|nt-[12]|ip)|s(?:v(?:p(?:-(?:encap-[12]|tunnel)|_tunnel)|d)|c(?:[ds]|-robot)|i(?:sysaccess|p)|-(?:pias|rmi)|(?:mt|a)p|qlserver|h-spx|f-1|ync|om)|o(?:b(?:o(?:traconteur|e(?:da|r))|cad-lm|ix)|ckwell-csp[12]|ute(?:match|r)|verlog|ketz|otd)|m(?:i(?:a(?:ctivation|ux)|registry)|o(?:nitor(?:[-_]secure)?|pagt)|t(?:server)?|lnk|pp|c)|i(?:c(?:ardo-lm|h-cp)|m(?:f-ps|sl)|s(?:-cm|e)?|dgeway[12]|b-slm|png)|d(?:(?:b-dbs-dis|la)p|s(?:-i[bp]|2)?|mnet-device|c-wh-eos|rmshc|a)|b(?:r-d(?:iscovery|ebug)|akcup[12]|t-wanopt|lcheckd)|r(?:i(?:(?:[lm]w|fm)m|rtr|sat)|d?p|ac|h)|f(?:[abe]|i(?:d-rp1|o)|x-lm|mp)|p(?:-reputation|c2portmap|rt|i)|(?:vs-isdn-dc|hp-iib|gt)p|c(?:(?:c-ho)?st|ts|p)|l(?:m-disc|zdbase|p)|us(?:b-sys-port|hd)|j(?:cdb-vcards|e)|(?:kb-osc|whoi)s|n(?:m(?:ap)?|rp)|x(?:mon|e))|b(?:m(?:c(?:-(?:p(?:erf-(?:(?:mgr|s)d|agent)|atroldb)|(?:messag|report)ing|net-(?:adm|svc)|data-coll|ctd-ldap|jmx-port|onekey|grx|ar|ea)|_(?:ctd_ldap|patroldb)|patrol(?:agent|rnvu))|[ap]p)|a(?:c(?:k(?:up(?:-express|edge)|roomnet|burner)|ula-(?:[fs]d|dir)|net)|n(?:yan-(?:net|rpc|vip)|dwiz-system)|dm[-_]p(?:riv|ub)|rracuda-bbs|lour|tman|bel|se)|o(?:o(?:t(?:client|server|p[cs])|sterware|merang)|ks(?:[-_](?:serv[cm]|clntd))?|ard-(?:roar|voip)|(?:sca|x)p|inc-client|ldsoft-lm|rland-dsj|unzza|nes)|r(?:i(?:dgecontrol|ghtcore)|(?:oker[-_]servic)?e|c(?:m-comm-port|d)|u(?:tus|ce)|lp-[0123]|-channel|vread|dptc|f-gw|ain|p)|i(?:n(?:tec-(?:[ct]api|admin)|derysupport|kp)|o(?:link-auth|server)|s-(?:sync|web)|(?:ap-m)?p|tspeer|imenu|m-pem|ff)|l(?:ue(?:ctrlproxy|berry-lm|lance)|a(?:ck(?:board|jack)|ze)|ock(?:ade(?:-bpsp)?|s)|wnkl-port|p[12345]|izwow|-idm)|e(?:a(?:con-port(?:-2)?|rs-0[12])|s(?:erver-msg-q|api|s)|x-(?:webadmin|xr)|eyond(?:-media)?|yond-remote|orl)|v(?:-(?:queryengine|smcsrv|[di]s|agent)|c(?:daemon-port|ontrol)|tsonar|eapi)|u(?:s(?:(?:chtromme|yca)l|iness)|es[-_]service|llant-s?rap|ddy-draw)|f(?:d-(?:(?:multi-ct|contro)l|echo|lag)|-(?:master|game)|lckmgr|tp)|t(?:p(?:p2(?:sectrans|audctr1)|rjctrl)|s-(?:appserver|x73)|rieve)|c(?:s(?:-(?:lmserv|brok)er|logc)?|tp(?:-server)?|inameservice)|p(?:c(?:p-(?:poll|trap)|d)|java-msvc|[mr]d|dbm)|h(?:oe(?:dap4|tty)|(?:fh|md)s|event|611)|n(?:et(?:(?:fil|gam)e)?|t-manager|gsync)|2(?:-(?:licens|runtim)e|n)|d(?:ir[-_]p(?:riv|ub)|p)|s(?:quare-voip|pne-pcc)|b(?:n-mm[cx]|ars)?|g(?:s-nsi|m?p)|-novative-ls|z(?:flag|r)|ytex|xp)|o(?:p(?:e(?:n(?:ma(?:il(?:pxy|ns|g)?|th)|v(?:ms-sysipc|pn)|(?:webne|por)t|nl(?:-voice)?|t(?:able|rac)|c(?:ore|m)|deploy|queue|flow|hpid)|quus-server)|s(?:e(?:c-(?:(?:el|le)a|u(?:aa|fp)|cvp|omi|sam)|ssion-(?:clnt|prxy|srvr))|w(?:manager|agent)|view-envoy|mgr)|t(?:i(?:ka-emedia|ma-vnet|wave-lm|logic)|o(?:host00[234]|control)|ech-port1-lm)|c(?:-job-(?:start|track)|ua-(?:tls|udp)|on-xps)|alis-r(?:bt-ipc|obot|dv)|us-services|net-smp|-probe|i-sock)|r(?:a(?:cle(?:-(?:(?:em|vp)[12]|oms)|n(?:et8cman|ames)|as-https)?|-lm|srv)|b(?:i(?:x(?:-(?:c(?:fg-ssl|onfig)|loc(?:-ssl|ator))|d)|ter)|plus-iiop)|dinox-(?:server|dbase)|ion(?:-rmi-reg)?|tec-disc)|m(?:a(?:-(?:[imr]lp(?:-s)?|dcdocbs|ulp)|bcastltkm|sgport)|s(?:-nonsecure|topology|contact|erv|dk)?|ni(?:vision(?:esx)?|link-port|sky)|(?:ginitialref|h)s)|v(?:s(?:am-(?:d-agen|mgm)t|essionmgr)|alarmsrv(?:-cmd)?|(?:hpa|bu|ob)s|-nnm-websrv|rimosdbman|[el]admgr|topmd|wdb)|n(?:e(?:home-(?:remote|help)|saf)|t(?:obroker|ime)|base-dds|psocket|screen|mux)|s(?:m(?:-(?:appsrvr|oev)|osis-aeea)|-licman|pf-lite|u-nms|b-sd|aut|dcp)|d(?:e(?:umservlink|tte-ftps?)|n(?:-castraq|sp)|bcpathway|i-port|mr|si)|c(?:e(?:-snmp-trap|ansoft-lm)|s(?:[-_][ac]mu|erver)|binder|topus|-lm)|b(?:j(?:ect(?:ive-dbc|manager)|call)|rpd|ex)|(?:(?:gs-cli|em-ag)en|2server-por)t|f(?:fice(?:link2000|-tools)|sd)|i(?:d(?:ocsvc|sr)|rtgsvc|-2000)|w(?:amp-control|server)|h(?:mtrigger|imsrv|sc)|t(?:[lm]p|patch|tp?|v)|l(?:s[rv]|host)|a-system|utlaws)|f(?:i(?:le(?:net-(?:p(?:owsrm|eior|ch|a)|r(?:mi|pc|e)|obrok|nch|tms|cm)|(?:x-lpor|cas)t|sphere)|r(?:e(?:monrcc|power|fox)|st(?:-defense|call42))|n(?:(?:isa|ge)r|d(?:viatv)?|le-lm|trx)|orano-(?:msg|rtr)svc|(?:veacros)?s|botrader-com)|j(?:i(?:ppol-(?:po(?:rt[12]|lsvr)|swrly|cnsl)|(?:tsuapp|nv)mgr|cl-tep-[abc])|s(?:v(?:-gssagt|mpor)|wapsnp)|mp(?:(?:jp|s)s|cm)|d(?:ocdist|mimgr)|(?:hpj|c)p|appmgrbulk|-hdnet)|a(?:c(?:sys-(?:router|ntp)|ilityview|-restore|elink)|x(?:(?:portwin|stfx-)port|comservice|imum)|st(?:-rem-serv|lynx)|zzt-(?:admin|ptp)|t(?:pipe|serv)|(?:gordn|md)c|irview)|c(?:p(?:-(?:(?:addr-srvr|srvr-inst)[12]|cics-gw1|udp))?|-(?:faultnotify|cli|ser)|i(?:p-port|s-disc)|opys?-server|msys)|u(?:nk(?:-(?:l(?:icense|ogger)|dialout)|proxy)|jitsu-(?:d(?:tc(?:ns)?|ev)|mmpdc|neat)|script|trix)|l(?:a(?:sh(?:filer|msg)|menco-proxy)|(?:irtmitmi|ukeserve)r|orence|n-spx|exlm)|t(?:p(?:-(?:agent|data)|s(?:-data)?)?|ra(?:pid-[12]|nhc)|s(?:ync|rv)|-role)|o(?:r(?:esyte-(?:clear|sec)|tisphere-vm)|nt-service|liocorp|togcad|dms)|s(?:[er]|-(?:rh-srv|qos)|portmap|c-port)|m(?:p(?:ro-(?:(?:intern|fd)al|v6))?|tp)|f(?:-(?:lr-port|annunc|fms|sm)|server)|r(?:ee(?:zexservice|civ)|yeserv|onet)|e(?:itianrockey|rrari-foam|mis)|x(?:aengine-net|(?:upt)?p)|5-(?:globalsite|iquery)|g-(?:sysupdate|fps|gip)|p(?:(?:o-fn|ram)s|itp)|net-remote-ui|yre-messanger|h(?:sp|c)|ksp-audit|dt-rcatp)|l(?:i(?:s(?:p(?:-(?:control|data)|works-orb)|t(?:crt-port(?:-2)?|mgr-port))|n(?:k(?:test(?:-s)?|name)?|ogridengine|x)|ebdevmgmt[-_](?:[ac]|dm)|ve(?:stats|lan)|censedaemon|berty-lm|psinc1?|onhead|ght)|a(?:n(?:s(?:urveyor(?:xml)?|chool-mpt|erver|ource)|rev(?:server|agent)|900[-_]remote|yon-lantern|messenger|dmarks|ner-lm)|(?:(?:unchbird|venir)-l)?m|zy-ptop|es-bf|plink|brat)|o(?:c(?:us-(?:disc|con|map)|alinfosrvr|kstep)|n(?:talk-(?:urgnt|norm)|ewolf-lm|works2?)|t(?:us(?:mtap|note)|105-ds-upd)|rica-(?:out|in)(?:-sec)?|a(?:probe|dav)|fr-lm)|m(?:-(?:(?:(?:webwatch|sserv)e|instmg)r|perfworks|dta|mon|x)|s(?:ocialserver)?|d?p|cs)|d(?:s(?:-d(?:istrib|ump)|s)|ap(?:-admin|s)?|oms-mgmt|gateway|x?p)|v(?:-(?:f(?:rontpanel|fx)|auth|pici|not|jc)|ision-lm)|nv(?:ma(?:ilmon|ps)|console|poller|status|alarm)|b(?:[fm]|c-(?:watchdog|control|measure|sync))|3(?:-(?:h(?:bmon|awk)|ranger|exprt)|t-at-an)|e(?:(?:croy-vic|oi)p|ecoposserver|gent-[12])|l(?:m(?:-(?:pass|csv)|nr)|surfup-https?|rp)|s(?:3(?:bcast)?|i-raid-mgmt|p-ping|[dt]p)|t(?:p(?:-deepspace)?|cudp)|(?:5nas-parcha|jk-logi)n|2(?:c-d(?:ata|isc)|tp|f)|p(?:srecommender|cp|dg)|(?:cm-|kcm)server|r(?:s-paging|p)|u(?:mimgrd|pa)|-acoustics|xi-evntsvc|yskom|htp)|v(?:i(?:s(?:i(?:on(?:[-_](?:server|elmd)|pyramid)|cron-vs|net-gui|tview)|t(?:ium-share|a-4gl)|d)|d(?:e(?:o(?:-activmail|beans|tex)|te-cipc)|s-avtp|igo)?|r(?:tual(?:-(?:places|time)|tape|user)|prot-lm)|p(?:era(?:-ssl)?|remoteagent)|ziblebrowser|talanalysis|nainstall|eo-fe)|r(?:t(?:s(?:-(?:a(?:uth|t)-port|ipcserver|registry|tdd)|trapserver)|l-vmf-(?:ds|sa)|p)?|(?:xpservma|p)n|(?:commer|a)ce)|e(?:r(?:i(?:tas(?:-(?:u(?:dp1|cl)|vis[12]|pbx)|_pbx)|smart)|sa(?:-te|tal)k|gencecm|acity|onica)|nus(?:-se)?|ttcp|mmi)|s(?:a(?:mredirector|t-control|iport)|i(?:-omega|admin|net|xml)|(?:econnecto|-serve)r|(?:nm-agen|ta)t|(?:lm|c)p|pread)|a(?:t(?:-control|ata|p)?|(?:-pac|ult)base|(?:lisys-l|prt)m|cdsm-(?:app|sws)|ntronix-mgmt|radero-[012]|d)|o(?:caltec-(?:admin|phone|gold|hos)|(?:fr-gatewa|lle)y|ispeed-port|xelstorm|pied)|p(?:p(?:s-(?:qu|vi)a)?|a(?:(?:-dis)?c|d)|(?:[2j]|m-ud)p|sipport|v[cd]|nz)|m(?:(?:ware-fd|ode)m|svc(?:-2)?|pwscs|net|rdp)|c(?:net-link-v10|(?:s-ap|r)p|om-tunnel|hat|e)|t(?:(?:u-comm|sa)s|r-emulator|-ssl|p)|n(?:s(?:-tp|str)|wk-prapi|etd|as)|ytalvault(?:(?:brt|vsm)p|pipe)|x(?:(?:-auth-|crnbu)port|lan)|vr-(?:control|data)|(?:-one-sp|q)p|f(?:bp-disc|o)|2g-secc|dmplay|lsi-lm|ulture|5ua|hd)|h(?:p(?:-(?:s(?:e(?:ssmon|rver)|an-mgmt|c[aio]|tatus)|d(?:ataprotect|evice-disc)|p(?:dl-datastr|xpib)|web(?:admin|qosdb)|c(?:ollector|lic)|hcip(?:-gwy)?|managed-node|3000-telnet|alarm-mgr|nnm-data)|v(?:mm(?:control|agent|data)|irt(?:ctrl|grp))|s(?:s(?:-ndapi|mgmt|d)|tgmgr2?)|o(?:ms-(?:dps|ci)-lstn|cbus)|i(?:dsa(?:dmin|gent)|od)|p(?:ronetman|pssvr))|a(?:cl-(?:p(?:robe|oll)|monitor|[gq]s|local|test|cfg|hb)|(?:r(?:t-i)?|gel-dum)?p|ipe-(?:discover|otnk)|-cluster|ssle|o)|e(?:a(?:lth(?:-(?:polling|trap)|d)|rtbeat)|r(?:odotus-net|e-lm|mes)|l(?:lo(?:-port)?|ix)|cmtl-db|xarc|ms)|t(?:tp(?:-(?:(?:rpc-ep|w)map|(?:mgm|al)t)|s(?:-wmap)?|x)?|uilsrv|rust|cp)|o(?:me(?:portal-web|steadglory)|u(?:dini-lm|ston)|tu-chat|stname|nyaku)|y(?:per(?:(?:wave-is|i)p|scsi-port|cube-lm|-g)|brid(?:-pop)?|lafax|dap)|i(?:[dq]|p(?:-nat-t|pad)|ve(?:stor|p)|gh-criteria|llrserv|cp)|323(?:gate(?:disc|stat)|hostcall(?:sc)?|callsigalt)|2(?:250-annex-g|48-binary|63-video|gf-w-2m)|r(?:pd-ith-at-an|d-ns-disc|i-port)|d(?:e-lcesrvr-[12]|l-srv|ap)|s(?:rp(?:v6)?|l-storm|-port)|hb-(?:handheld|gateway)|l(?:(?:serve|ibmg)r|7)|fcs(?:-manager)?|u(?:ghes-ap|sky)|b(?:-engine|ci)|mmp-(?:ind|op)|k(?:s-lm|p)|cp-wismar|nmp?)|w(?:a(?:p-(?:wsp(?:-(?:wtp(?:-s)?|s))?|push(?:-https?|secure)?|vca(?:rd|l)(?:-s)?)|t(?:c(?:h(?:do(?:c(?:-pod)?|g-nt)|me-7272)|omdebug)|ershed-lm|ilapp)|g(?:o-(?:io-system|service)|-service)|r(?:m(?:spotmgmt|ux)|ehouse(?:-sss)?)|(?:asclust|nscal)er|cp|fs)|i(?:n(?:p(?:o(?:planmess|rt)|haraoh|cs)|d(?:(?:rea|l)m|d(?:lb|x)|b)|s(?:hadow(?:-hd)?)?|install-ipc|jaserver|qedit|fs)|l(?:kenlistener|ly)|m(?:axasncp|sic|d)|(?:egan|zar|re)d|p-port|bukey|free)|e(?:b(?:m(?:a(?:chine|il-2)|ethods-b2b)|s(?:phere-snmp|ter|m)|(?:object|acces)s|(?:phon|ti)e|emshttp|2host|login|data)|stell-stats|ave|llo)|s(?:m(?:-server(?:-ssl)?|ans?|lb)|(?:-discover|icop)y|o2esb-console|dapi(?:-s)?|sauthsvc|ynch)|h(?:o(?:s(?:ockami|ells)|is(?:\+\+|pp)|ami)?|erehoo|isker)|or(?:ld(?:fusion[12]|scores|-lm)|kflow)|w(?:w(?:-(?:ldap-gw|http|dev))?|iotalk)|(?:ta-ws(?:p-wt)?p-|p(?:age|g))s|v-csp-(?:sms(?:-cir)?|udp-cir)|bem-(?:exp-https|https?|rmi)|c(?:(?:backu|p)p|r-remlib)|m(?:s-messenger|c-log-svc)|r(?:s[-_]registry|itesrv)|f(?:(?:remotert)?m|c)|(?:g-netforc|usag)e|k(?:stn-mon|ars)|l(?:anauth|bs)|nn6(?:-ds)?|ysdm[ac]|xbrief)|g(?:a(?:l(?:axy(?:-(?:network|server)|7-data)|ileo(?:log)?)|m(?:e(?:smith-port|lobby|gen1)|mafetchsvr)|d(?:getgate[12]way|ugadu)|ndalf-lm|t-lmd|c?p|ia)|e(?:n(?:i(?:e(?:-lm)?|sar-port|uslm)|e(?:ralsync|ous|ve)|rad-mux)|o(?:gnosis(?:man)?|locate)|mini-lm|arman)|l(?:o(?:b(?:al-(?:cd-port|dtserv|wlink)|e(?:cast-id)?|msgsvc)|gger)|ishd|rpc|bp)|r(?:i(?:d(?:gen-elmd|-alt)?|ffin|s)|o(?:ove(?:-dpp)?|upwise)|aphics|f-port|ubd)|t(?:p-(?:control|user)|rack-(?:server|ne)|e(?:gsc-lm|-samp)|-proxy|aua)|s(?:i(?:gatekeeper|ftp)?|s-(?:xlicen|http)|(?:akm|mta)p)|o(?:(?:ldleaf-licma|-logi)n|ahead-fldup|todevice|pher)|d(?:s(?:(?:-adppiw)?-|_)db|o(?:map|i)|bremote|p-port)|i(?:(?:ga-pocke|s)?t|latskysurfer|op(?:-ssl)?|nad)|w(?:-(?:call-port|asv|log)|(?:en-sony|h)a)|c(?:m(?:onitor|-app)|-config|sp)|p(?:rs-(?:cube|sig)|pitnp|fs|sd)|b(?:mt-stars|s-s[mt]p|jd816)|nu(?:tella-(?:rtr|svc)|net)|x(?:s-data-port|telmd)|m(?:rupdateserv|mp)|v(?:-(?:pf|us)|cp)|g(?:f-ncp|z)|uibase|-talk|2tag|hvpn|5m|f)|u(?:n(?:i(?:s(?:ys-(?:eportal|lm)|ql(?:-java)?)|v(?:erse[-_]suite|-appserver|ision)|fy(?:-(?:adapter|debug)|admin)?|(?:c(?:ontro|al)|mobilectr)l|(?:x-stat|zens)us|hub-server|data-ldm|keypro|port|eng|te)|bind-cluster|[eo]t|glue)|p(?:s(?:-(?:onlinet|engine)|notifyprot|triggervsw)?|notifyps?|grade)|l(?:t(?:r(?:a(?:seek-http|bac)|ex)|imad)|p(?:net)?|istproc)|d(?:p(?:-sr-port|radio)|r(?:awgraph|ive)|t[-_]os)|s(?:-(?:(?:sr|g)v|cli)|icontentpush|er-manager)|a(?:(?:-secureagen|iac)t|(?:dt|a)c|(?:rp|c)s)|u(?:cp(?:-(?:rlogin|path))?|idgen)|t(?:(?:mp[cs]|c)d|sftp|ime)|r(?:(?:ld-por|bisne)t|m)|c(?:entric-ds|ontrol)|f(?:astro-instr|mp)|m(?:m-port|sp?|a)|b(?:roker|xd)|o(?:host|rb)|-dbap|is)|x(?:m(?:l(?:i(?:nk-connect|pcregsvc)|tec-xmlmail|rpc-beep|blaster)|p(?:cr-interface|v7)|query|api|ms2|sg)|n(?:s-(?:c(?:ourier|h)|auth|mail|time)|m(?:-(?:clear-text|ssl)|p)|ds)|i(?:n(?:u(?:expansion[1234]|pageserver)|g(?:mpeg|csm))|ostatus|ip)|s(?:s(?:-srv)?-port|-openstorage|(?:msv|yn)c|ip-network|erveraid)|a(?:ct-backup|ndros-cms|dmin|p-ha|api)|p(?:r(?:int-server|tld)|ilot|l)|d(?:(?:mc|t)p|s(?:xdm)?|as)|2(?:5-svc-port|e-disc)|r(?:pc-registry|ibs|l)|t(?:r(?:eamx|ms?)|gui)|(?:ecp-nod|9-icu)e|(?:xnetserve|fe?)r|-bone-(?:api|ctl)|(?:kotodrc|vtt)p|(?:yplex-mu|bo)x|o(?:-wave|raya)|(?:gri|qos)d|500ms|11)|k(?:e(?:r(?:beros(?:-(?:adm|iv))?|mit)|ys(?:(?:erve|rv)r|hadow)|ntrox-prot)|a(?:sten(?:chasepad|xpipe)|(?:za|n)a|r2ouche|0wuc|li)|o(?:ns(?:hus-lm|pire2b)|pek-httphead|fax-svr)|i(?:n(?:g(?:domsonline|fisher)|k)|osk|s)|f(?:tp(?:-data)?|xaclicensing|server)|r(?:b5(?:gatekeeper|24)|yptolan)|v(?:-(?:server|agent)|m-via-ip)|m(?:e-trap-port|scontrol)|t(?:i-icad-srvr|elnet)|3software-(?:cli|svr)|s(?:ysguard|hell)|p(?:asswd|n-icw)|w(?:db-commn|tc)|jtsiteserver|l(?:ogin|io)|yoceranetdev|ca-service|d(?:net|m)|net-cmp|-block)|j(?:a(?:u(?:gsremotec-[12]|s)|xer-(?:manager|web)|mserverport|cobus-lm|nus-disc|leosnd|rgon)|e(?:t(?:form(?:preview)?|cmeserver)|ol-nsddp-[1234]|diserver|rand-lm|smsjc)|o(?:(?:ajewelsuit|urne)e|mamqmonitor|ltid|ost)|m(?:(?:q-daemon-|b-cds)[12]|act[356]|evt2|s)|d(?:l-dbkitchen|atastore|mn-port|p-disc)|b(?:oss-iiop(?:-ssl)?|roker)|v(?:l-mactalk|client|server)|t(?:400(?:-ssl)?|ag-server)|w(?:(?:alk)?server|client)|i(?:ni-discovery|be-eb)|p(?:egmpeg|rinter|s)|-(?:lan-p|ac)|uxml-port|licelmd|stel|cp)|q(?:u(?:e(?:st(?:-(?:agent|vista|disc)|db2-lnchr|notify)|ueadm)|a(?:sar-server|rtus-tcl|ilnet|ddb|ke)|ick(?:booksrds|suite)|o(?:tad|sa)|bes)|s(?:net-(?:(?:assi|work)st|trans|cond|nucl)|m-(?:remote|proxy|gui)|oft)|t(?:(?:ms-bootstra)?p|-serveradmin)|ip-(?:(?:audu|qdhc)p|login|msgd)|b(?:-db-server|ikgdp|db)|f(?:t(?:est-lookup)?|p)|(?:db2servic|3ad|wav)e|o(?:t(?:ps|d)|-secure)|admif(?:event|oper)|n(?:xnetman|ts-orb)|m(?:[qt]p|video)|pasa-agent|(?:en)?cp|ke-llc-v3|55-pcc|rh)|z(?:e(?:n(?:ginkyo-[12]|-pawn|ted)|p(?:hyr-(?:clt|srv|hm))?)|a(?:bbix-(?:trapper|agent)|nnet|rkov)|i(?:(?:on-l|co)m|gbee-ips?|eto-sock)|(?:ymed-zp|m)p|firm-shiprush3|39[-.]50|re-disc|-wave|serv)|3(?:com(?:-(?:n(?:jack-[12]|et-mgmt|sd)|webview|tsmux|amp3)|faxrpc|netman)|par-(?:mgmt(?:-ssl)?|rcopy|evts)|d(?:-nfsd|s-lm)|l(?:-l1|ink)|m-image-lm)|4(?:-tieropm(?:cli|gw)|talk)|9(?:14c(?:\/|-)g|pfs)|y(?:o-mai|aw)n|802-11-iapp|1ci-smcs|2ping|6a44)(?![-])\b}i;  ## no critic(RegularExpressions)




####################
#  Hash constants  #
####################



our $IANA_HASH_INFO_FOR_SERVICE = $_HASHES_REF->{ q{service_info} };




our $IANA_HASH_SERVICES_FOR_PORT = $_HASHES_REF->{ q{port} };




our $IANA_HASH_SERVICES_FOR_PORT_PROTO = $_HASHES_REF->{ q{port_proto} };




our $IANA_HASH_PORTS_FOR_SERVICE = $_HASHES_REF->{ q{service} };




#################
#  Subroutines  #
#################



sub iana_has_port {
    my ($port, $protocol) = @_;
    if (defined $protocol) {
        my $port_ref = $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ $port };
        if (defined $port_ref) {
            return $port_ref->{ $protocol } ? 1 : 0;
        }
        else {
            return 0;
        }
    }
    else {
        return $IANA_HASH_SERVICES_FOR_PORT->{ $port } ? 1 : 0;
    }
}




sub iana_has_service {
    my ($service, $protocol) = @_;
    if (defined $protocol) {
        my $serv_ref = $IANA_HASH_INFO_FOR_SERVICE->{ $service };
        if (defined $serv_ref) {
            return $serv_ref->{ $protocol } ? 1 : 0;
        }
        else {
            return 0;
        }
    }
    else {
        return $IANA_HASH_PORTS_FOR_SERVICE->{ $service } ? 1 : 0;
    }
}




sub iana_info_for_port {
    my ($port, $protocol) = @_;
    my $ret;
    if  (defined $protocol) {
        my $port_ref = $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ $port };
        if  (defined $port_ref) {
            $ret = $port_ref->{ $protocol };
        }
    }
    else {
        $ret = $IANA_HASH_SERVICES_FOR_PORT->{ $port };
    }
    if (defined $ret) {
        return wantarray  ?  @$ret  :  $ret;
    }
    else {
        return;
    }
}




sub iana_info_for_service {
    my ($service, $protocol) = @_;
    my $serv_ref = $IANA_HASH_INFO_FOR_SERVICE->{ $service };
    my $ret;
    if  (defined $serv_ref) {
        $ret = defined $protocol ? $serv_ref->{ $protocol } : $serv_ref;
    }
    if (defined $ret) {
        return wantarray  ?  %$ret  :  $ret;
    }
    else {
        return;
    }
}




#  Happy ending
1;

__END__

=pod

=head1 NAME

Net::IANA::Services - Makes working with named ip services easier

=head1 VERSION

version 0.004000

=head1 SYNOPSIS

    #  Load the module
    use Net::IANA::Services (
        #  Import the regular expressions to test for services/ports
        ':regexes',

        #  Import the hashes to test for services/ports or get info for a service/protocol
        ':hashes',

        #  Import the subroutines to test for services/ports or get info for a service/protocol
        ':subs',

        #  Alternatively this loads everything
        #  ':all',
    );


    #  Declare some strings to test
    my $service = 'https';
    my $port    = 22;


    #  How the regexes work
    $service =~ $IANA_REGEX_SERVICES;      # 1
    $service =~ $IANA_REGEX_SERVICES_UDP;  # 1
    $port    =~ $IANA_REGEX_PORTS;         # 1
    $port    =~ $IANA_REGEX_PORTS_TCP;     # 1


    #  Demonstration of the service hashes
    $IANA_HASH_INFO_FOR_SERVICE-> { $service }{ tcp }{ 443 }; # { name => 'https', desc => 'http protocol over TLS/SSL', note => '' }
    $IANA_HASH_PORTS_FOR_SERVICE->{ $service };               # [qw/ 443 /]  --  List of all the services that use that port

    #  Demonstration  of the port hashes
    $IANA_HASH_SERVICES_FOR_PORT      ->{ $port }     ;  # [qw/ ssh /]  --  List of all the services that use that port
    $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ $port }{tcp};  # [qw/ ssh /]  --  Hash of all the protocol/services that use that port


    #  Demonstration of the service/port checker subroutines
    iana_has_service( $service        );  # 1
    iana_has_service( $service, 'tcp' );  # 1
    iana_has_service( $service, 'bla' );  # 0
    iana_has_port   ( $port           );  # 1

    #  Demonstration of the service/port info subroutines
    iana_info_for_service( $service        );  # Returns a hash of the different protocol definitions
    iana_info_for_service( $service, 'tcp' );  # Returns a hash of the info for https over tcp
    iana_info_for_port   ( $port           );  # Returns a list all services that go over that port (regardless of the protocol)
    iana_info_for_port   ( $port, 'tcp'    );  # Returns a list all services that go over that port on tcp

=head1 DESCRIPTION

Working with named services can be a pain when you want to go back and forth between the port and
its real name.  This module helps alleviate some of those pain points by defining some helping
hashes, functions, and regular expressions.

=head1 CONSTANTS

=head2 $IANA_REGEX_PORTS

Regular expression to match any port, irregardless of which protocol it goes over.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $port =~ $IANA_REGEX_PORTS;

    # Won't match
    $non_port =~ $IANA_REGEX_PORTS;

=head2 $IANA_REGEX_SERVICES

Regular expression to match any service, irregardless of which protocol it goes over.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $service =~ $IANA_REGEX_SERVICES;

    # Won't match
    $non_service =~ $IANA_REGEX_SERVICES;

=head2 $IANA_REGEX_PORTS_DCCP

Regular expression to match any port that is known to work over dccp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $port_dccp =~ $IANA_REGEX_PORTS_DCCP;

    # Won't match
    $non_port_dccp =~ $IANA_REGEX_PORTS_DCCP;

=head2 $IANA_REGEX_PORTS_SCTP

Regular expression to match any port that is known to work over sctp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $port_sctp =~ $IANA_REGEX_PORTS_SCTP;

    # Won't match
    $non_port_sctp =~ $IANA_REGEX_PORTS_SCTP;

=head2 $IANA_REGEX_PORTS_TCP

Regular expression to match any port that is known to work over tcp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $port_tcp =~ $IANA_REGEX_PORTS_TCP;

    # Won't match
    $non_port_tcp =~ $IANA_REGEX_PORTS_TCP;

=head2 $IANA_REGEX_PORTS_UDP

Regular expression to match any port that is known to work over udp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $port_udp =~ $IANA_REGEX_PORTS_UDP;

    # Won't match
    $non_port_udp =~ $IANA_REGEX_PORTS_UDP;

=head2 $IANA_REGEX_SERVICES_DCCP

Regular expression to match any service that is known to work over dccp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $service_dccp =~ $IANA_REGEX_SERVICES_DCCP;

    # Won't match
    $non_service_dccp =~ $IANA_REGEX_SERVICES_DCCP;

=head2 $IANA_REGEX_SERVICES_SCTP

Regular expression to match any service that is known to work over sctp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $service_sctp =~ $IANA_REGEX_SERVICES_SCTP;

    # Won't match
    $non_service_sctp =~ $IANA_REGEX_SERVICES_SCTP;

=head2 $IANA_REGEX_SERVICES_TCP

Regular expression to match any service that is known to work over tcp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $service_tcp =~ $IANA_REGEX_SERVICES_TCP;

    # Won't match
    $non_service_tcp =~ $IANA_REGEX_SERVICES_TCP;

=head2 $IANA_REGEX_SERVICES_UDP

Regular expression to match any service that is known to work over udp.

While this is a highly optimized regex, you should consider using the hashes or subroutines instead
as they are much better.  This is merely for your convenience.

Case is ignored and the protocol must match on a word boundary!

=head3 Examples

    # Matches
    $service_udp =~ $IANA_REGEX_SERVICES_UDP;

    # Won't match
    $non_service_udp =~ $IANA_REGEX_SERVICES_UDP;

=head2 $IANA_HASH_INFO_FOR_SERVICE

This maps a service and a protocol to the information provided to us by IANA.

=head3 Examples

    #  Get info for ssh over tcp
    $ssh_tcp_info = $IANA_HASH_INFO_FOR_SERVICE->{ ssh }{ tcp };

    Dumper $ssh_tcp_info;
    #   22 => {
    #      desc => 'The Secure Shell (SSH) Protocol'
    #      name => 'ssh'
    #      note => 'Defined TXT keys: u=<username> p=<password>'
    #   }


    #  Get info for http over any protocol
    $http_info = $IANA_HASH_INFO_FOR_SERVICE->{ http };

    Dumper $http_info;
    #   sctp => {
    #       '80' => {
    #           desc => 'HTTP',
    #           name => 'http',
    #           note => 'Defined TXT keys: u=<username> p=<password> path=<path to document>',
    #       },
    #   },
    #   tcp => {
    #       '80' => {
    #           desc => 'World Wide Web HTTP',
    #           name => 'http',
    #           note => 'Defined TXT keys: u=<username> p=<password> path=<path to document>',
    #       },
    #   },
    #   udp => {
    #       '80' => {
    #           desc => 'World Wide Web HTTP',
    #           name => 'http',
    #           note => 'Defined TXT keys: u=<username> p=<password> path=<path to document>',
    #       },
    #   },

=head2 $IANA_HASH_SERVICES_FOR_PORT

This lists all of the services for the given port, irregardless of the protocol.

An empty list will be returned if nothing is found.  This respects wantarray>

=head3 Examples

    my $port_22 = $IANA_HASH_SERVICES_FOR_PORT->{ 22 };
    Dumper $port_22;
    # [qw/ ssh /]

    my $port_1110 = $IANA_HASH_SERVICES_FOR_PORT->{ 1110 };
    Dumper $port_1110;
    # [qw/ nfsd-keepalive  webadmstart /]

=head2 $IANA_HASH_SERVICES_FOR_PORT_PROTO

This lists all of the services for the given port and protocol.

=head3 Examples

    my $port_22 = $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ 22 }{ tcp };
    Dumper $port_22;
    # [qw/ ssh /]

    my $port_tcp_1110 = $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ 1110 }{ tcp };
    Dumper $port_tcp_1110;
    # [qw/ webadmstart /]

    my $port_udp_1110 = $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ 1110 }{ udp };
    Dumper $port_udp_1110;
    # [qw/ nfsd-keepalive /]

=head2 $IANA_HASH_PORTS_FOR_SERVICE

This lists all of the ports for the given service, irregardless of the protocol.

=head3 Example

    my $service_http_alt = $IANA_HASH_PORTS_FOR_SERVICE->{ 'http-alt' };
    Dumper $service_http_alt;
    # [qw/ 591  8008  8080 /];

=head1 METHODS

=head2 iana_has_port

Helper function to check if the given port (and optional protocol) is defined by IANA.

If only the port is given, then it will be checked across all protocols while restricting the search
to just the provided protocol if one is given.

=head3 Arguments

=over 4

=item 1

Port

=over 4

=item *

Required

=item *

C<Port (int)>

=item *

Port you want looked up

=back

=item 2

Protocol

=over 4

=item *

I<Optional>

=item *

C<String>

=item *

Limit the search to only this protocol if specified

=back

=back

=head3 Returns

=over 4

=item 1

Search results

=over 4

=item *

C<Boolean>

=item *

1 if the match was found, 0 otherwise

=back

=back

=head3 Examples

    iana_has_port( 22 );    # 1
    iana_has_port( 34221 ); # 0

    iana_has_port( 271, 'tcp' );  # 1
    iana_has_port( 271, 'udp' );  # 0

=head2 iana_has_service

Helper function to check if the given service (and optional protocol) is defined by IANA.

If only the service name is given, then it will be checked across all protocols while restricting
the search to just the provided protocol if one is given.

=head3 Arguments

=over 4

=item 1

Service Name

=over 4

=item *

Required

=item *

C<String>

=item *

Service name you want looked up

=back

=item 2

Protocol

=over 4

=item *

I<Optional>

=item *

C<String>

=item *

Limit the search to only this protocol if specified

=back

=back

=head3 Returns

=over 4

=item 1

Search results

=over 4

=item *

C<Boolean>

=item *

1 if the match was found, 0 otherwise

=back

=back

=head3 Examples

    iana_has_service( 'ssh' );    # 1
    iana_has_service( 'not-ss' ); # 0

    iana_has_service( 'xmpp-server', 'tcp' );  # 1
    iana_has_service( 'xmpp-server', 'udp' );  # 0

=head2 iana_info_for_port

Helper function to get the known services for the given port and optional protocol, as defined by
IANA.

If only the port is given, then you will get back an array ref containing all of the services that
are defined by IANA.  If a protocol is specified, then the returned prtocols will be limited to
those running over that type.

=head3 Arguments

=over 4

=item 1

Port

=over 4

=item *

Required

=item *

C<Port (int)>

=item *

Port you want looked up

=back

=item 2

Protocol

=over 4

=item *

I<Optional>

=item *

C<String>

=item *

Limit the search to only this protocol if specified

=back

=back

=head3 Returns

=over 4

=item 1

Search results

=over 4

=item *

C<Array>

=item *

The list of protocols running over the specified info (arrayref if in scalar context)

=item *

Undefined if the searched was unsuccessful!

=back

=back

=head3 Examples

    iana_info_for_port( 22 );    # [qw/ ssh /]
    iana_info_for_port( 34221 ); # undef

    iana_info_for_port( 271, 'tcp' );  # [qw/ pt-tls /]
    iana_info_for_port( 271, 'udp' );  # undef

=head2 iana_info_for_service

Helper function to get the known information for the given service and optional protocol, as defined
by IANA.

If only the service is given, then you will get back a hash ref containing the normal return
information hash for each defined protocol for that service.

=head3 Arguments

=over 4

=item 1

Service Name

=over 4

=item *

Required

=item *

C<String>

=item *

Service name you want looked up

=back

=item 2

Protocol

=over 4

=item *

I<Optional>

=item *

C<String>

=item *

Limit the search to only this protocol if specified

=back

=back

=head3 Returns

=over 4

=item 1

Service information (for a provided protocol)

=over 4

=item *

C<Hash>

=item *

Undefined if the searched was unsuccessful!

=back

The returned hash contains the following pieces of information (keys are lower case):

=over 4

=item Name

The full name (with proper capitalization) for the requested service

=item Desc

A short synopsis of the service, usually a sentence or two long

=item Note

Any additional information they wanted to provided that users should be aware of

=back

=back

=head3 Examples

    iana_info_for_service( 'xribs' );  # { udp => { 2025 => { desc => '', name => 'xribs', note => '' } } }
    iana_info_for_service( 'not-ss' ); # undef

    iana_info_for_service( 'xribs', 'tcp' );  # undef
    iana_info_for_service( 'xribs', 'udp' );  # { 2025 => { desc => '', name => 'xribs', note => '' } }

=encoding utf8

=begin Pod::Coverage




=end Pod::Coverage

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Net::IANA::Services

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Net-IANA-Services>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Net-IANA-Services>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-IANA-Services>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Net-IANA-Services>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Net-IANA-Services>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Net-IANA-Services>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Net-IANA-Services>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/N/Net-IANA-Services>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Net-IANA-Services>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Net::IANA::Services>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-net-iana-services at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IANA-Services>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/lespea/net-iana-services>

  git clone git://github.com/lespea/net-iana-services.git

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
