package Net::Whois::Raw::Data;
$Net::Whois::Raw::Data::VERSION = '2.99031';
# ABSTRACT: Config for Net::Whois::Raw.

use utf8;
use warnings;
use strict;

our @www_whois = qw(
    VN
    TJ
);
# Candidates for www_whois: BD, DO, ES, EG, MG, SH, TM, TP, ZA

our %servers = qw(
    RU                  whois.ripn.net
    NET.RU              whois.nic.net.ru
    ORG.RU              whois.nic.net.ru
    PP.RU               whois.nic.net.ru
    SU                  whois.ripn.net
    XN--P1AI            whois.ripn.net
    XN--D1ACJ3B         whois.ripn.net

    MADRID              whois.madrid.rs.corenic.net
    XN--80ADXHKS        whois.nic.xn--80adxhks
    XN--80ASEHDB        whois.online.rs.corenic.net
    XN--80ASWG          whois.site.rs.corenic.net
    XN--P1ACF           whois.nic.xn--p1acf

    RU.NET              whois.flexireg.net
    COM.RU              whois.flexireg.net
    EXNET.SU            whois.flexireg.net

    ABKHAZIA.SU         whois.flexireg.net
    ADYGEYA.RU          whois.flexireg.net
    ADYGEYA.SU          whois.flexireg.net
    AKTYUBINSK.SU       whois.flexireg.net
    AMURSK.RU           whois.nic.ru
    ARKHANGELSK.SU      whois.flexireg.net
    ARMENIA.SU          whois.flexireg.net
    ASHGABAD.SU         whois.flexireg.net
    AZERBAIJAN.SU       whois.flexireg.net
    BALASHOV.SU         whois.flexireg.net
    BASHKIRIA.RU        whois.flexireg.net
    BASHKIRIA.SU        whois.flexireg.net
    BELGOROD.RU         whois.nic.ru
    BELGOROD.SU         whois.nic.ru
    BIR.RU              whois.flexireg.net
    BRYANSK.SU          whois.flexireg.net
    BUKHARA.SU          whois.flexireg.net
    CBG.RU              whois.flexireg.net
    CHELYABINSK.RU      whois.nic.ru
    CHIMKENT.SU         whois.flexireg.net
    CMW.RU              whois.nic.ru
    DAGESTAN.RU         whois.flexireg.net
    DAGESTAN.SU         whois.flexireg.net
    DUDINKA.RU          whois.nic.ru
    EAST-KAZAKHSTAN.SU  whois.flexireg.net
    FAREAST.RU          whois.nic.ru
    GEORGIA.SU          whois.flexireg.net
    GROZNY.RU           whois.flexireg.net
    GROZNY.SU           whois.flexireg.net
    IVANOVO.SU          whois.flexireg.net
    JAMBYL.SU           whois.flexireg.net
    JAR.RU              whois.nic.ru
    JOSHKAR-OLA.RU      whois.nic.ru
    KALMYKIA.RU         whois.flexireg.net
    KALMYKIA.SU         whois.flexireg.net
    KALUGA.SU           whois.flexireg.net
    KARACOL.SU          whois.flexireg.net
    KARAGANDA.SU        whois.flexireg.net
    KARELIA.SU          whois.flexireg.net
    KCHR.RU             whois.nic.ru
    KHAKASSIA.SU        whois.flexireg.net
    KOMI.SU             whois.nic.ru
    KRASNODAR.SU        whois.flexireg.net
    KURGAN.SU           whois.flexireg.net
    KUSTANAI.RU         whois.flexireg.net
    KUSTANAI.SU         whois.flexireg.net
    LENUG.SU            whois.flexireg.net
    MANGYSHLAK.SU       whois.flexireg.net
    MARINE.RU           whois.flexireg.net
    MORDOVIA.RU         whois.flexireg.net
    MORDOVIA.SU         whois.flexireg.net
    MSK.RU              whois.flexireg.net
    MSK.SU              whois.flexireg.net
    MURMANSK.SU         whois.flexireg.net
    MYTIS.RU            whois.flexireg.net
    NALCHIK.RU          whois.flexireg.net
    NALCHIK.SU          whois.flexireg.net
    NAVOI.SU            whois.flexireg.net
    NNOV.RU             whois.nnov.ru
    NORILSK.RU          whois.nic.ru
    NORTH-KAZAKHSTAN.SU whois.flexireg.net
    NOV.RU              whois.flexireg.net
    NOV.SU              whois.flexireg.net
    OBNINSK.SU          whois.flexireg.net
    PALANA.RU           whois.nic.ru
    PENZA.SU            whois.flexireg.net
    POKROVSK.SU         whois.flexireg.net
    PYATIGORSK.RU       whois.flexireg.net
    SIMBIRSK.RU         whois.nic.ru
    SOCHI.SU            whois.flexireg.net
    SPB.RU              whois.flexireg.net
    SPB.SU              whois.flexireg.net
    TASHKENT.SU         whois.flexireg.net
    TERMEZ.SU           whois.flexireg.net
    TOGLIATTI.SU        whois.flexireg.net
    TROITSK.SU          whois.flexireg.net
    TSARITSYN.RU        whois.nic.ru
    TSELINOGRAD.SU      whois.flexireg.net
    TULA.SU             whois.flexireg.net
    TUVA.SU             whois.flexireg.net
    VLADIKAVKAZ.RU      whois.flexireg.net
    VLADIKAVKAZ.SU      whois.flexireg.net
    VLADIMIR.RU         whois.flexireg.net
    VLADIMIR.SU         whois.flexireg.net
    VOLOGDA.SU          whois.flexireg.net
    YAKUTIA.SU          whois.nic.ru
    YEKATERINBURG.RU    whois.nic.ru

    NS     whois.nsiregistry.net
    RIPE   whois.ripe.net
    IP     whois.arin.net

    AERO            whois.aero
    ARPA            whois.iana.org
    ASIA            whois.nic.asia
    BIZ             whois.biz
    CAT             whois.cat
    CC              whois.nic.cc
    COM             whois.crsnic.net
    EDU             whois.educause.edu
    GOV             whois.dotgov.gov
    INFO            whois.afilias.net
    INT             whois.iana.org
    JOBS            whois.nic.jobs
    MIL             whois.nic.mil
    MOBI            whois.afilias.net
    MUSEUM          whois.museum
    NAME            whois.nic.name
    NET             whois.crsnic.net
    NOTLD           whois.iana.org
    ORG             whois.pir.org
    PRO             whois.nic.pro
    TEL             whois-tel.neustar.biz
    TRAVEL          whois.nic.travel

    ACADEMY         whois.donuts.co
    ACCOUNTANTS     whois.donuts.co
    AGENCY          whois.donuts.co
    APARTMENTS      whois.donuts.co
    ASSOCIATES      whois.donuts.co
    BAND            whois.donuts.co
    BARGAINS        whois.donuts.co
    BIKE            whois.donuts.co
    BINGO           whois.donuts.co
    BOUTIQUE        whois.donuts.co
    BUILDERS        whois.donuts.co
    BUSINESS        whois.donuts.co
    CAB             whois.donuts.co
    CAFE            whois.donuts.co
    CAMERA          whois.donuts.co
    CAMP            whois.donuts.co
    CAPITAL         whois.donuts.co
    CARDS           whois.donuts.co
    CARE            whois.donuts.co
    CAREERS         whois.donuts.co
    CASH            whois.donuts.co
    CASINO          whois.donuts.co
    CATERING        whois.donuts.co
    CENTER          whois.donuts.co
    CHAT            whois.donuts.co
    CHEAP           whois.donuts.co
    CHURCH          whois.donuts.co
    CITY            whois.donuts.co
    CLAIMS          whois.donuts.co
    CLEANING        whois.donuts.co
    CLINIC          whois.donuts.co
    CLOTHING        whois.donuts.co
    COACH           whois.donuts.co
    CODES           whois.donuts.co
    COFFEE          whois.donuts.co
    COMMUNITY       whois.donuts.co
    COMPANY         whois.donuts.co
    COMPUTER        whois.donuts.co
    CONDOS          whois.donuts.co
    CONSTRUCTION    whois.donuts.co
    CONTRACTORS     whois.donuts.co
    COOL            whois.donuts.co
    COUPONS         whois.donuts.co
    CREDIT          whois.donuts.co
    CREDITCARD      whois.donuts.co
    CRUISES         whois.donuts.co
    DATING          whois.donuts.co
    DEALS           whois.donuts.co
    DELIVERY        whois.donuts.co
    DENTAL          whois.donuts.co
    DIAMONDS        whois.donuts.co
    DIGITAL         whois.donuts.co
    DIRECT          whois.donuts.co
    DIRECTORY       whois.donuts.co
    DISCOUNT        whois.donuts.co
    DOCTOR          whois.donuts.co
    DOG             whois.donuts.co
    DOMAINS         whois.donuts.co
    EDUCATION       whois.donuts.co
    EMAIL           whois.donuts.co
    ENERGY          whois.donuts.co
    ENGINEERING     whois.donuts.co
    ENTERPRISES     whois.donuts.co
    EQUIPMENT       whois.donuts.co
    ESTATE          whois.donuts.co
    EVENTS          whois.donuts.co
    EXCHANGE        whois.donuts.co
    EXPERT          whois.donuts.co
    EXPOSED         whois.donuts.co
    EXPRESS         whois.donuts.co
    FAIL            whois.donuts.co
    FAMILY          whois.donuts.co
    FARM            whois.donuts.co
    FINANCE         whois.donuts.co
    FINANCIAL       whois.donuts.co
    FISH            whois.donuts.co
    FITNESS         whois.donuts.co
    FLIGHTS         whois.donuts.co
    FLORIST         whois.donuts.co
    FOOTBALL        whois.donuts.co
    FOUNDATION      whois.donuts.co
    FUND            whois.donuts.co
    FURNITURE       whois.donuts.co
    FYI             whois.donuts.co
    GALLERY         whois.donuts.co
    GAMES           whois.donuts.co
    GIFTS           whois.donuts.co
    GLASS           whois.donuts.co
    GMBH            whois.donuts.co
    GOLD            whois.donuts.co
    GOLF            whois.donuts.co
    GRAPHICS        whois.donuts.co
    GRATIS          whois.donuts.co
    GRIPE           whois.donuts.co
    GROUP           whois.donuts.co
    GUIDE           whois.donuts.co
    GURU            whois.donuts.co
    HEALTHCARE      whois.donuts.co
    HOCKEY          whois.donuts.co
    HOLDINGS        whois.donuts.co
    HOLIDAY         whois.donuts.co
    HOUSE           whois.donuts.co
    IMMO            whois.donuts.co
    INDUSTRIES      whois.donuts.co
    INSTITUTE       whois.donuts.co
    INSURE          whois.donuts.co
    INTERNATIONAL   whois.donuts.co
    INVESTMENTS     whois.donuts.co
    JETZT           whois.donuts.co
    JEWELRY         whois.donuts.co
    KITCHEN         whois.donuts.co
    LAND            whois.donuts.co
    LEASE           whois.donuts.co
    LEGAL           whois.donuts.co
    LIFE            whois.donuts.co
    LIGHTING        whois.donuts.co
    LIMITED         whois.donuts.co
    LIMO            whois.donuts.co
    LIVE            whois.donuts.co
    LOANS           whois.donuts.co
    LTD             whois.donuts.co
    MAISON          whois.donuts.co
    MANAGEMENT      whois.donuts.co
    MARKETING       whois.donuts.co
    MBA             whois.donuts.co
    MEDIA           whois.donuts.co
    MEMORIAL        whois.donuts.co
    MONEY           whois.donuts.co
    MOVIE           whois.donuts.co
    NETWORK         whois.donuts.co
    NEWS            whois.donuts.co
    PARTNERS        whois.donuts.co
    PARTS           whois.donuts.co
    PHOTOGRAPHY     whois.donuts.co
    PHOTOS          whois.donuts.co
    PICTURES        whois.donuts.co
    PIZZA           whois.donuts.co
    PLACE           whois.donuts.co
    PLUMBING        whois.donuts.co
    PLUS            whois.donuts.co
    PRODUCTIONS     whois.donuts.co
    PROPERTIES      whois.donuts.co
    RECIPES         whois.donuts.co
    REISEN          whois.donuts.co
    RENTALS         whois.donuts.co
    REPAIR          whois.donuts.co
    REPORT          whois.donuts.co
    RESTAURANT      whois.donuts.co
    RIP             whois.donuts.co
    RUN             whois.donuts.co
    SALON           whois.donuts.co
    SALE            whois.donuts.co
    SARL            whois.donuts.co
    SCHOOL          whois.donuts.co
    SCHULE          whois.donuts.co
    SERVICES        whois.donuts.co
    SHOES           whois.donuts.co
    SHOPPING        whois.donuts.co
    SHOW            whois.donuts.co
    SINGLES         whois.donuts.co
    SOCCER          whois.donuts.co
    SOLAR           whois.donuts.co
    SOLUTIONS       whois.donuts.co
    STUDIO          whois.donuts.co   
    STYLE           whois.donuts.co
    SUPPLIES        whois.donuts.co
    SUPPLY          whois.donuts.co
    SUPPORT         whois.donuts.co
    SURGERY         whois.donuts.co
    SYSTEMS         whois.donuts.co
    TAX             whois.donuts.co
    TAXI            whois.donuts.co
    TEAM            whois.donuts.co
    TECHNOLOGY      whois.donuts.co
    TENNIS          whois.donuts.co
    THEATER         whois.donuts.co
    TIENDA          whois.donuts.co
    TIPS            whois.donuts.co
    TIRES           whois.donuts.co
    TODAY           whois.donuts.co
    TOOLS           whois.donuts.co
    TOURS           whois.donuts.co
    TOWN            whois.donuts.co
    TOYS            whois.donuts.co
    TRAINING        whois.donuts.co
    UNIVERSITY      whois.donuts.co
    VACATIONS       whois.donuts.co
    VENTURES        whois.donuts.co
    VIAJES          whois.donuts.co
    VIDEO           whois.donuts.co
    VILLAS          whois.donuts.co
    VIN             whois.donuts.co
    VISION          whois.donuts.co
    VOYAGE          whois.donuts.co
    WATCH           whois.donuts.co
    WINE            whois.donuts.co
    WORKS           whois.donuts.co
    WORLD           whois.donuts.co
    WTF             whois.donuts.co
    XN--CZRS0T      whois.donuts.co
    XN--FJQ720A     whois.donuts.co
    XN--UNUP4Y      whois.donuts.co
    XN--VHQUV       whois.donuts.co
    ZONE            whois.donuts.co

    AUDIO           whois.uniregistry.net
    AUTO            whois.uniregistry.net
    BLACKFRIDAY     whois.uniregistry.net
    CAR             whois.uniregistry.net
    CARS            whois.uniregistry.net
    CHRISTMAS       whois.uniregistry.net
    CLICK           whois.uniregistry.net
    DIET            whois.uniregistry.net
    FLOWERS         whois.uniregistry.net
    GAME            whois.uniregistry.net
    GIFT            whois.uniregistry.net
    GUITARS         whois.uniregistry.net
    HELP            whois.uniregistry.net
    HIPHOP          whois.uniregistry.net
    HIV             whois.uniregistry.net
    HOSTING         whois.uniregistry.net
    JUEGOS          whois.uniregistry.net
    LINK            whois.uniregistry.net
    LOL             whois.uniregistry.net
    MOM             whois.uniregistry.net
    PHOTO           whois.uniregistry.net
    PICS            whois.uniregistry.net
    PROPERTY        whois.uniregistry.net
    SEXY            whois.uniregistry.net
    TATTOO          whois.uniregistry.net

    BERLIN          whois.nic.berlin
    BEST            whois.nic.best
    BROKER          whois.nic.broker
    BUILD           whois.nic.build
    CAREER          whois.nic.career
    COURSES         whois.nic.courses
    CLOUD           whois.nic.cloud
    CLUB            whois.nic.club
    EARTH           whois.nic.earth
    FILM            whois.nic.film
    FOREX           whois.nic.forex
    KIWI            whois.nic.kiwi
    LUXURY          whois.nic.luxury
    MEN             whois.nic.men
    MENU            whois.nic.menu
    MOSCOW          whois.nic.moscow
    ONE             whois.nic.one
    OOO             whois.nic.ooo
    SHOP            whois.nic.shop
    SRL             whois.nic.srl
    STUDY           whois.nic.study
    TATAR           whois.nic.tatar
    TOP             whois.nic.top
    TRADING         whois.nic.trading
    TUBE            whois.nic.tube
    WIEN            whois.nic.wien
    UNO             whois.nic.uno
    XXX             whois.nic.xxx

    BOX             whois.nic.box
    EPSON           whois.nic.epson
    IINET           whois.nic.iinet
    KRD             whois.nic.krd
    MELBOURNE       whois.nic.melbourne
    SAXO            whois.nic.saxo

    BET             whois.afilias.net
    BLACK           whois.afilias.net
    BLUE            whois.afilias.net
    GREEN           whois.afilias.net
    KIM             whois.afilias.net
    LGBT            whois.afilias.net
    LOTTO           whois.afilias.net
    LLC             whois.afilias.net
    ORGANIC         whois.afilias.net
    PET             whois.afilias.net
    PINK            whois.afilias.net
    POKER           whois.afilias.net
    RED             whois.afilias.net
    SHIKSHA         whois.afilias.net
    VOTE            whois.afilias.net
    VOTO            whois.afilias.net
    XN--6FRZ82G     whois.afilias.net

    ACTOR           whois.nic.actor
    AIRFORCE        whois.nic.airforce
    ARMY            whois.nic.army
    ATTORNEY        whois.nic.attorney
    AUCTION         whois.nic.auction
    BABY            whois.nic.baby
    BOSTON          whois.nic.boston
    BUZZ            whois.nic.buzz
    CONSULTING      whois.nic.consulting
    CYOU            whois.nic.cyou
    DANCE           whois.nic.dance
    DEGREE          whois.nic.degree
    DEMOCRAT        whois.nic.democrat
    DENTIST         whois.nic.dentist
    ENGINEER        whois.nic.engineer
    FORSALE         whois.nic.forsale
    FUN             whois.nic.fun
    FUTBOL          whois.nic.futbol
    GIVES           whois.nic.gives
    HAUS            whois.nic.haus
    HEALTH          whois.nic.health
    HOSPITAL        whois.nic.hospital
    IMMOBILIEN      whois.nic.immobilien
    KAUFEN          whois.nic.kaufen
    LAWYER          whois.nic.lawyer
    MARKET          whois.nic.market
    MODA            whois.nic.moda
    MORTGAGE        whois.nic.mortgage
    NAVY            whois.nic.navy
    NAGOYA          whois.nic.nagoya
    NINJA           whois.nic.ninja
    NYC             whois.nic.nyc
    PUB             whois.nic.pub
    QPON            whois.nic.qpon
    REHAB           whois.nic.rehab
    REPUBLICAN      whois.nic.republican
    REVIEWS         whois.nic.reviews
    ROCKS           whois.nic.rocks
    SOCIAL          whois.nic.social
    SOFTWARE        whois.nic.software
    STREAM          whois.nic.stream
    TOKYO           whois.nic.tokyo
    VET             whois.nic.vet
    YOKOHAMA        whois.nic.yokohama

    AC               whois.nic.ac
    AG               whois.nic.ag
    ALSACE           whois-alsace.nic.fr
    AM               whois.amnic.net
    AQUARELLE        whois-aquarelle.nic.fr
    AS               whois.nic.as
    AT               whois.nic.at
    CO.AT            whois.nic.at
    OR.AT            whois.nic.at
    AU               whois.audns.net.au
    BE               whois.dns.be
    BG               whois.register.bg
    BJ               whois.nic.bj
    BOSTIK           whois-bostik.nic.fr
    BR               whois.registro.br
    BY               whois.ripe.net
    BZ               whois2.afilias-grs.net
    CA               whois.cira.ca
    CD               whois.nic.cd
    CH               whois.nic.ch
    CI               whois.nic.ci
    CL               whois.nic.cl
    CM               whois.netcom.cm
    CN               whois.cnnic.net.cn
    CO               whois.nic.co
    COM.CO           whois.nic.co
    CORSICA          whois-corsica.nic.fr
    CX               whois.nic.cx
    CZ               whois.nic.cz
    DE               whois.denic.de
    DK               whois.dk-hostmaster.dk
    DM               whois.nic.dm
    EE               whois.eenet.ee
    EU               whois.eu
    FI               whois.ficora.fi
    FM               whois.nic.fm
    FO               whois.ripe.net
    FR               whois.nic.fr
    FROGANS          whois-frogans.nic.fr
    GD               whois.nic.gd
    GG               whois.channelisles.net
    GI               whois2.afilias-grs.net
    GS               whois.nic.gs
    GY               whois.registry.gy
    HK               whois.hkirc.hk
    HM               whois.registry.hm
    HN               whois.nic.hn
    HR               whois.dns.hr
    HT               whois.nic.ht
    HU               whois.nic.hu
    IE               whois.domainregistry.ie
    IL               whois.isoc.org.il
    IM               whois.nic.im
    IN               whois.registry.in
    IO               whois.nic.io
    IR               whois.nic.ir
    IS               whois.isnic.is
    IT               whois.nic.it
    JE               whois.channelisles.net
    JP               whois.jprs.jp
    KE               whois.kenic.or.ke
    KG               whois.domain.kg
    KI               whois.nic.ki
    KR               whois.nic.or.kr
    KZ               whois.nic.kz
    LANCASTER        whois-lancaster.nic.fr
    LC               whois2.afilias-grs.net
    LECLERC          whois-leclerc.nic.fr
    LI               whois.nic.li
    LT               whois.domreg.lt
    LU               whois.dns.lu
    LV               whois.nic.lv
    LY               whois.nic.ly
    MA               whois.iam.net.ma
    MC               whois.ripe.net
    MD               whois.nic.md
    ME               whois.nic.me
    MG               whois.nic.mg
    MMA              whois-mma.nic.fr
    MN               whois2.afilias-grs.net
    MS               whois.nic.ms
    MU               whois.nic.mu
    MUTUELLE         whois-mutuelle.nic.fr
    MX               whois.mx
    MY               whois.mynic.my
    NA               whois.na-nic.com.na
    NF               whois.nic.nf
    NL               whois.domain-registry.nl
    NO               whois.norid.no
    NU               whois.nic.nu
    NZ               whois.srs.net.nz
    OVH              whois-ovh.nic.fr
    PARIS            whois-paris.nic.fr
    PL               whois.dns.pl
    PM               whois.nic.pm
    PR               whois.nic.pr
    PT               whois.dns.pt
    PW               whois.centralnic.com
    PY               whois.i-dns.net
    QA               whois.registry.qa
    RE               whois.nic.re
    RO               whois.rotld.ro
    RS               whois.rnids.rs
    SA               whois.saudinic.net.sa
    SB               whois.nic.sb
    SC               whois2.afilias-grs.net
    SE               whois.iis.se
    SG               whois.nic.net.sg
    SH               whois.nic.sh
    SI               whois.arnes.si
    SK               whois.sk-nic.sk
    SM               whois.ripe.net
    SNCF             whois-sncf.nic.fr
    SO               whois.nic.so
    ST               whois.nic.st
    SX               whois.sx
    TC               whois.nic.tc
    TF               whois.nic.tf
    TH               whois.thnic.co.th
    TK               whois.dot.tk
    TL               whois.nic.tl
    TM               whois.nic.tm
    TO               whois.tonic.to
    TOTAL            whois-total.nic.fr
    TR               whois.nic.tr
    TV               whois.nic.tv
    TW               whois.twnic.net.tw
    UA               whois.com.ua
    UK               whois.nic.uk
    US               whois.nic.us
    UZ               whois.cctld.uz
    VC               whois2.afilias-grs.net
    VE               whois.nic.ve
    WF               whois.nic.wf
    WS               whois.worldsite.ws
    XN--80AO21A      whois.nic.kz
    XN--E1A4C        whois.eu
    XN--J6W193G      whois.hkirc.hk
    XN--KPRW13D      whois.twnic.net.tw
    XN--KPRY57D      whois.twnic.net.tw
    XN--MGBA3A4F16A  whois.nic.ir
    XN--WGBL6A       whois.registry.qa
    XN--Y9A3AQ       whois.amnic.net
    YT               whois.nic.yt

    ASN.AU        whois.aunic.net
    COM.AU        whois.aunic.net
    CONF.AU       whois.aunic.net
    CSIRO.AU      whois.aunic.net
    EDU.AU        whois.aunic.net
    GOV.AU        whois.aunic.net
    ID.AU         whois.aunic.net
    INFO.AU       whois.aunic.net
    NET.AU        whois.aunic.net
    ORG.AU        whois.aunic.net
    EMU.ID.AU     whois.aunic.net
    WATTLE.ID.AU  whois.aunic.net

    ADM.BR  whois.nic.br
    ADV.BR  whois.nic.br
    AGR.BR  whois.nic.br
    AM.BR   whois.nic.br
    ARQ.BR  whois.nic.br
    ART.BR  whois.nic.br
    ATO.BR  whois.nic.br
    BIO.BR  whois.nic.br
    BMD.BR  whois.nic.br
    CIM.BR  whois.nic.br
    CNG.BR  whois.nic.br
    CNT.BR  whois.nic.br
    COM.BR  whois.nic.br
    ECN.BR  whois.nic.br
    EDU.BR  whois.nic.br
    ENG.BR  whois.nic.br
    ESP.BR  whois.nic.br
    ETC.BR  whois.nic.br
    ETI.BR  whois.nic.br
    FAR.BR  whois.nic.br
    FM.BR   whois.nic.br
    FND.BR  whois.nic.br
    FOT.BR  whois.nic.br
    FST.BR  whois.nic.br
    G12.BR  whois.nic.br
    GGF.BR  whois.nic.br
    GOV.BR  whois.nic.br
    IMB.BR  whois.nic.br
    IND.BR  whois.nic.br
    INF.BR  whois.nic.br
    JOR.BR  whois.nic.br
    LEL.BR  whois.nic.br
    MAT.BR  whois.nic.br
    MED.BR  whois.nic.br
    MIL.BR  whois.nic.br
    MUS.BR  whois.nic.br
    NET.BR  whois.nic.br
    NOM.BR  whois.nic.br
    NOT.BR  whois.nic.br
    NTR.BR  whois.nic.br
    ODO.BR  whois.nic.br
    OOP.BR  whois.nic.br
    ORG.BR  whois.nic.br
    PPG.BR  whois.nic.br
    PRO.BR  whois.nic.br
    PSC.BR  whois.nic.br
    PSI.BR  whois.nic.br
    QSL.BR  whois.nic.br
    REC.BR  whois.nic.br
    SLG.BR  whois.nic.br
    SRV.BR  whois.nic.br
    TMP.BR  whois.nic.br
    TRD.BR  whois.nic.br
    TUR.BR  whois.nic.br
    TV.BR   whois.nic.br
    VET.BR  whois.nic.br
    ZLG.BR  whois.nic.br

    AC.CN  whois.cnnic.net.cn
    AH.CN  whois.cnnic.net.cn
    BJ.CN  whois.cnnic.net.cn
    COM.CN whois.cnnic.net.cn
    CQ.CN  whois.cnnic.net.cn
    FJ.CN  whois.cnnic.net.cn
    GD.CN  whois.cnnic.net.cn
    GOV.CN whois.cnnic.net.cn
    GS.CN  whois.cnnic.net.cn
    GX.CN  whois.cnnic.net.cn
    GZ.CN  whois.cnnic.net.cn
    HA.CN  whois.cnnic.net.cn
    HB.CN  whois.cnnic.net.cn
    HE.CN  whois.cnnic.net.cn
    HI.CN  whois.cnnic.net.cn
    HK.CN  whois.cnnic.net.cn
    HL.CN  whois.cnnic.net.cn
    HN.CN  whois.cnnic.net.cn
    JL.CN  whois.cnnic.net.cn
    JS.CN  whois.cnnic.net.cn
    JX.CN  whois.cnnic.net.cn
    LN.CN  whois.cnnic.net.cn
    MO.CN  whois.cnnic.net.cn
    NET.CN whois.cnnic.net.cn
    NM.CN  whois.cnnic.net.cn
    NX.CN  whois.cnnic.net.cn
    ORG.CN whois.cnnic.net.cn
    QH.CN  whois.cnnic.net.cn
    SC.CN  whois.cnnic.net.cn
    SD.CN  whois.cnnic.net.cn
    SH.CN  whois.cnnic.net.cn
    SN.CN  whois.cnnic.net.cn
    SX.CN  whois.cnnic.net.cn
    TJ.CN  whois.cnnic.net.cn
    TW.CN  whois.cnnic.net.cn
    XJ.CN  whois.cnnic.net.cn
    XZ.CN  whois.cnnic.net.cn
    YN.CN  whois.cnnic.net.cn
    ZJ.CN  whois.cnnic.net.cn

    AC.FJ       whois.domains.fj
    BIZ.FJ      whois.domains.fj
    COM.FJ      whois.domains.fj
    INFO.FJ     whois.domains.fj
    MIL.FJ      whois.domains.fj
    NAME.FJ     whois.domains.fj
    NET.FJ      whois.domains.fj
    ORG.FJ      whois.domains.fj
    PRO.FJ      whois.domains.fj

    CO.GY       whois.registry.gy
    COM.GY      whois.registry.gy
    NET.GY      whois.registry.gy

    COM.HK      whois.hknic.net.hk
    GOV.HK      whois.hknic.net.hk
    NET.HK      whois.hknic.net.hk
    ORG.HK      whois.hknic.net.hk

    AC.JP       whois.jprs.jp
    AD.JP       whois.jprs.jp
    CO.JP       whois.jprs.jp
    GR.JP       whois.jprs.jp
    NE.JP       whois.jprs.jp
    OR.JP       whois.jprs.jp

    AC.MA       whois.iam.net.ma
    CO.MA       whois.iam.net.ma
    GOV.MA      whois.iam.net.ma
    NET.MA      whois.iam.net.ma
    ORG.MA      whois.iam.net.ma
    PRESS.MA    whois.iam.net.ma

    COM.MX      whois.nic.mx
    GOB.MX      whois.nic.mx
    NET.MX      whois.nic.mx

    COM.MT      whois.nic.mt
    ORG.MT      whois.nic.mt
    NET.MT      whois.nic.mt
    EDU.MT      whois.nic.mt

    CO.RS       whois.rnids.rs
    EDU.RS      whois.rnids.rs
    IN.RS       whois.rnids.rs
    ORG.RS      whois.rnids.rs
    XN--90A3AC  whois.rnids.rs

    AC.TH       whois.thnic.co.th
    CO.TH       whois.thnic.co.th
    GO.TH       whois.thnic.co.th
    MI.TH       whois.thnic.co.th
    OR.TH       whois.thnic.co.th
    NET.TH      whois.thnic.co.th
    IN.TH       whois.thnic.co.th

    COM.TW      whois.twnic.net
    IDV.TW      whois.twnic.net
    NET.TW      whois.twnic.net
    ORG.TW      whois.twnic.net

    COM.UA      whois.com.ua
    NET.UA      whois.net.ua
    ORG.UA      whois.com.ua
    BIZ.UA      whois.biz.ua
    CO.UA       whois.co.ua
    PP.UA       whois.pp.ua
    KIEV.UA     whois.com.ua
    DN.UA       whois.dn.ua
    LG.UA       whois.lg.ua
    OD.UA       whois.od.ua
    IN.UA       whois.in.ua

    AC.UK       whois.ja.net
    CO.UK       whois.nic.uk
    ME.UK       whois.nic.uk
    GOV.UK      whois.ja.net
    LTD.UK      whois.nic.uk
    NET.UK      whois.nic.uk
    ORG.UK      whois.nic.uk
    PLC.UK      whois.nic.uk

    AFRICA      africa-whois.registry.net.za
    CAPETOWN    capetown-whois.registry.net.za
    CO.ZA       whois.registry.net.za
    DURBAN      durban-whois.registry.net.za
    JOBURG      joburg-whois.registry.net.za
    NET.ZA      net-whois.registry.net.za
    ORG.ZA      org-whois.registry.net.za
    WEB.ZA      web-whois.registry.net.za

    NGO              whois.publicinterestregistry.net
    ONG              whois.publicinterestregistry.net
    XN--C1AVG        whois.publicinterestregistry.net
    XN--E1APQ        whois.i-dns.net
    XN--I1B6B1A6A2E  whois.publicinterestregistry.net
    XN--J1AEF        whois.i-dns.net
    XN--NQV7F        whois.publicinterestregistry.net
    XN--NQV7FS00EMA  whois.publicinterestregistry.net
    XN--P1AG         ru.whois.i-dns.net

    AE.ORG      whois.centralnic.com
    AFRICA.COM  whois.centralnic.com
    AR.COM      whois.centralnic.com
    BR.COM      whois.centralnic.com
    CN.COM      whois.centralnic.com
    CO.COM      whois.centralnic.com
    DE.COM      whois.centralnic.com
    COM.DE      whois.centralnic.com
    EU.COM      whois.centralnic.com
    GB.COM      whois.centralnic.com
    GB.NET      whois.centralnic.com
    GR.COM      whois.centralnic.com
    HU.COM      whois.centralnic.com
    HU.NET      whois.centralnic.com
    IN.NET      whois.centralnic.com
    JP.NET      whois.centralnic.com
    JPN.COM     whois.centralnic.com
    KR.COM      whois.centralnic.com
    MEX.COM     whois.centralnic.com
    NO.COM      whois.centralnic.com
    QC.COM      whois.centralnic.com
    RADIO.AM    whois.centralnic.com
    RADIO.FM    whois.centralnic.com
    RU.COM      whois.centralnic.com
    SA.COM      whois.centralnic.com
    SE.COM      whois.centralnic.com
    COM.SE      whois.centralnic.com
    SE.NET      whois.centralnic.com
    UK.COM      whois.centralnic.com
    UK.NET      whois.centralnic.com
    US.COM      whois.centralnic.com
    UY.COM      whois.centralnic.com
    ZA.COM      whois.centralnic.com

    ART         whois.centralnic.com
    BAR         whois.centralnic.com
    COLLEGE     whois.centralnic.com
    CONTACT     whois.centralnic.com
    COOP        whois.centralnic.com
    DESIGN      whois.centralnic.com
    FAN         whois.centralnic.com
    FANS        whois.centralnic.com
    FEEDBACK    whois.centralnic.com
    FORUM       whois.centralnic.com
    HOST        whois.centralnic.com
    INK         whois.centralnic.com
    LOVE        whois.centralnic.com
    LPL         whois.centralnic.com
    LPLFINANCIAL whois.centralnic.com
    ONLINE      whois.centralnic.com
    PID         whois.centralnic.com
    PRESS       whois.centralnic.com
    PROTECTION  whois.centralnic.com
    REALTY      whois.centralnic.com
    REIT        whois.centralnic.com
    RENT        whois.centralnic.com
    REST        whois.centralnic.com
    SECURITY    whois.centralnic.com
    SITE        whois.centralnic.com
    SPACE       whois.centralnic.com
    STORAGE     whois.centralnic.com
    STORE       whois.centralnic.com
    TECH        whois.centralnic.com
    THEATRE     whois.centralnic.com
    TICKETS     whois.centralnic.com
    WEBSITE     whois.centralnic.com
    WIKI        whois.centralnic.com
    XYZ         whois.centralnic.com

    ORG.NS      whois.pir.org
    BIZ.NS      whois.biz
    NAME.NS     whois.nic.name
    COM.TR      whois.nic.tr
    ORG.HN      whois.nic.hn
    NET.HN      whois.nic.hn
    COM.HN      whois.nic.hn
    VIP         whois.nic.vip
    PROMO       whois.nic.promo

    ALLFINANZ                 whois.ksregistry.net
    ARCHI                     whois.ksregistry.net
    BIO                       whois.ksregistry.net
    BMW                       whois.ksregistry.net
    CAM                       whois.ksregistry.net
    DESI                      whois.ksregistry.net
    DVAG                      whois.ksregistry.net
    FRESENIUS                 whois.ksregistry.net
    MINI                      whois.ksregistry.net
    POHL                      whois.ksregistry.net
    SAARLAND                  whois.ksregistry.net
    SKI                       whois.ksregistry.net
    SPIEGEL                   whois.ksregistry.net
    TUI                       whois.ksregistry.net
    XN--VERMGENSBERATER-CTB   whois.ksregistry.net
    XN--VERMGENSBERATUNG-PWB  whois.ksregistry.net
    ZUERICH                   whois.ksregistry.net

    AE              whois.aeda.net.ae
    XN--MGBAAM7A8H  whois.aeda.net.ae

    ABARTH              whois.afilias-srs.net
    ABBOTT              whois.afilias-srs.net
    ABBVIE              whois.afilias-srs.net
    ACO                 whois.afilias-srs.net
    ACTIVE              whois.afilias-srs.net
    ADULT               whois.afilias-srs.net
    AGAKHAN             whois.afilias-srs.net
    AIGO                whois.afilias-srs.net
    AKDN                whois.afilias-srs.net
    ALFAROMEO           whois.afilias-srs.net
    ALIPAY              whois.afilias-srs.net
    ALLSTATE            whois.afilias-srs.net
    ALLY                whois.afilias-srs.net
    APPLE               whois.afilias-srs.net
    AUDI                whois.afilias-srs.net
    AUTOS               whois.afilias-srs.net
    AVIANCA             whois.afilias-srs.net
    BCG                 whois.afilias-srs.net
    BEATS               whois.afilias-srs.net
    BESTBUY             whois.afilias-srs.net
    BLOCKBUSTER         whois.afilias-srs.net
    BNL                 whois.afilias-srs.net
    BNPPARIBAS          whois.afilias-srs.net
    BOATS               whois.afilias-srs.net
    BOEHRINGER          whois.afilias-srs.net
    BUGATTI             whois.afilias-srs.net
    BUY                 whois.afilias-srs.net
    CASE                whois.afilias-srs.net
    CASEIH              whois.afilias-srs.net
    CBS                 whois.afilias-srs.net
    CEB                 whois.afilias-srs.net
    CERN                whois.afilias-srs.net
    CHRYSLER            whois.afilias-srs.net
    CIPRIANI            whois.afilias-srs.net
    CLINIQUE            whois.afilias-srs.net
    CREDITUNION         whois.afilias-srs.net
    CRUISE              whois.afilias-srs.net
    DABUR               whois.afilias-srs.net
    DELTA               whois.afilias-srs.net
    DISH                whois.afilias-srs.net
    DODGE               whois.afilias-srs.net
    DOT                 whois.afilias-srs.net
    DTV                 whois.afilias-srs.net
    DUNLOP              whois.afilias-srs.net
    DVR                 whois.afilias-srs.net
    ECO                 whois.afilias-srs.net
    EDEKA               whois.afilias-srs.net
    EMERCK              whois.afilias-srs.net
    ESURANCE            whois.afilias-srs.net
    EXTRASPACE          whois.afilias-srs.net
    FAGE                whois.afilias-srs.net
    FEDEX               whois.afilias-srs.net
    FERRARI             whois.afilias-srs.net
    FIAT                whois.afilias-srs.net
    FIDO                whois.afilias-srs.net
    GALLUP              whois.afilias-srs.net
    GEA                 whois.afilias-srs.net
    GODADDY             whois.afilias-srs.net
    GOODHANDS           whois.afilias-srs.net
    GOODYEAR            whois.afilias-srs.net
    HDFC                whois.afilias-srs.net
    HDFCBANK            whois.afilias-srs.net
    HELSINKI            whois.afilias-srs.net
    HERMES              whois.afilias-srs.net
    HKT                 whois.afilias-srs.net
    HOMEDEPOT           whois.afilias-srs.net
    HOMES               whois.afilias-srs.net
    HUGHES              whois.afilias-srs.net
    ICBC                whois.afilias-srs.net
    IMAMAT              whois.afilias-srs.net
    ISMAILI             whois.afilias-srs.net
    IST                 whois.afilias-srs.net
    ISTANBUL            whois.afilias-srs.net
    ITV                 whois.afilias-srs.net
    IVECO               whois.afilias-srs.net
    JCP                 whois.afilias-srs.net
    JEEP                whois.afilias-srs.net
    JIO                 whois.afilias-srs.net
    JLL                 whois.afilias-srs.net
    KOSHER              whois.afilias-srs.net
    LAMBORGHINI         whois.afilias-srs.net
    LAMER               whois.afilias-srs.net
    LANCIA              whois.afilias-srs.net
    LASALLE             whois.afilias-srs.net
    LATINO              whois.afilias-srs.net
    LDS                 whois.afilias-srs.net
    LOCKER              whois.afilias-srs.net
    LTDA                whois.afilias-srs.net
    MARRIOTT            whois.afilias-srs.net
    MASERATI            whois.afilias-srs.net
    MCKINSEY            whois.afilias-srs.net
    METLIFE             whois.afilias-srs.net
    MIT                 whois.afilias-srs.net
    MOPAR               whois.afilias-srs.net
    MORMON              whois.afilias-srs.net
    MOTORCYCLES         whois.afilias-srs.net
    NATURA              whois.afilias-srs.net
    NEWHOLLAND          whois.afilias-srs.net
    NOKIA               whois.afilias-srs.net
    NOWTV               whois.afilias-srs.net
    NRA                 whois.afilias-srs.net
    OLLO                whois.afilias-srs.net
    ONL                 whois.afilias-srs.net
    ORIENTEXPRESS       whois.afilias-srs.net
    ORIGINS             whois.afilias-srs.net
    OTT                 whois.afilias-srs.net
    PCCW                whois.afilias-srs.net
    PNC                 whois.afilias-srs.net
    PORN                whois.afilias-srs.net
    PROGRESSIVE         whois.afilias-srs.net
    PWC                 whois.afilias-srs.net
    REDUMBRELLA         whois.afilias-srs.net
    RELIANCE            whois.afilias-srs.net
    RICH                whois.afilias-srs.net
    RICHARDLI           whois.afilias-srs.net
    RIL                 whois.afilias-srs.net
    ROGERS              whois.afilias-srs.net
    SBI                 whois.afilias-srs.net
    SCHAEFFLER          whois.afilias-srs.net
    SCHOLARSHIPS        whois.afilias-srs.net
    SEW                 whois.afilias-srs.net
    SEX                 whois.afilias-srs.net
    SHAW                whois.afilias-srs.net
    SHOWTIME            whois.afilias-srs.net
    SHRIRAM             whois.afilias-srs.net
    SINA                whois.afilias-srs.net
    SLING               whois.afilias-srs.net
    SRT                 whois.afilias-srs.net
    STADA               whois.afilias-srs.net
    STAR                whois.afilias-srs.net
    STATEBANK           whois.afilias-srs.net
    STOCKHOLM           whois.afilias-srs.net
    TEMASEK             whois.afilias-srs.net
    THD                 whois.afilias-srs.net
    TRAVELERS           whois.afilias-srs.net
    TRAVELERSINSURANCE  whois.afilias-srs.net
    TRV                 whois.afilias-srs.net
    TVS                 whois.afilias-srs.net
    UCONNECT            whois.afilias-srs.net
    UPS                 whois.afilias-srs.net
    VEGAS               whois.afilias-srs.net
    VIG                 whois.afilias-srs.net
    VIKING              whois.afilias-srs.net
    VOLKSWAGEN          whois.afilias-srs.net
    WEIBO               whois.afilias-srs.net
    WOLTERSKLUWER       whois.afilias-srs.net
    XN--3OQ18VL8PN36A   whois.afilias-srs.net
    XN--4GBRIM          whois.afilias-srs.net
    XN--5TZM5G          whois.afilias-srs.net
    XN--9KRT00A         whois.afilias-srs.net
    XN--B4W605FERD      whois.afilias-srs.net
    XN--ESTV75G         whois.afilias-srs.net
    XN--FZYS8D69UVGM    whois.afilias-srs.net
    XN--JLQ61U9W7B      whois.afilias-srs.net
    YACHTS              whois.afilias-srs.net
    ZARA                whois.afilias-srs.net

    BOM          whois.gtlds.nic.br
    FINAL        whois.gtlds.nic.br
    GLOBO        whois.gtlds.nic.br
    RIO          whois.gtlds.nic.br
    UOL          whois.gtlds.nic.br

    BAIDU        whois.ngtld.cn
    XN--1QQW23A  whois.ngtld.cn
    XN--55QX5D   whois.ngtld.cn
    XN--IO0A7I   whois.ngtld.cn
    XN--XHQ521B  whois.ngtld.cn

    ADS             whois.nic.google
    ANDROID         whois.nic.google
    APP             whois.nic.google
    BOO             whois.nic.google
    CAL             whois.nic.google
    CHANNEL         whois.nic.google
    CHROME          whois.nic.google
    DAD             whois.nic.google
    DAY             whois.nic.google
    DCLK            whois.nic.google
    DEV             whois.nic.google
    DOCS            whois.nic.google
    DRIVE           whois.nic.google
    EAT             whois.nic.google
    ESQ             whois.nic.google
    FLY             whois.nic.google
    FOO             whois.nic.google
    GBIZ            whois.nic.google
    GLE             whois.nic.google
    GMAIL           whois.nic.google
    GOOG            whois.nic.google
    GOOGLE          whois.nic.google
    GUGE            whois.nic.google
    HANGOUT         whois.nic.google
    HERE            whois.nic.google
    HOW             whois.nic.google
    ING             whois.nic.google
    MEET            whois.nic.google
    MEME            whois.nic.google
    MOV             whois.nic.google
    NEW             whois.nic.google
    NEXUS           whois.nic.google
    PAGE            whois.nic.google
    PLAY            whois.nic.google
    PROD            whois.nic.google
    PROF            whois.nic.google
    RSVP            whois.nic.google
    SOY             whois.nic.google
    XN--FLW351E     whois.nic.google
    XN--Q9JYB4C     whois.nic.google
    XN--QCKA1PMC    whois.nic.google
    YOUTUBE         whois.nic.google
    ZIP             whois.nic.google

    ANQUAN          whois.teleinfo.cn
    SHOUJI          whois.teleinfo.cn
    XIHUAN          whois.teleinfo.cn
    XN--3DS443G     whois.teleinfo.cn
    XN--FIQ228C5HS  whois.teleinfo.cn
    XN--VUQ861B     whois.teleinfo.cn
    YUN             whois.teleinfo.cn

    NOWRUZ          whois.agitsys.net
    PARS            whois.agitsys.net
    SHIA            whois.agitsys.net
    TCI             whois.agitsys.net
    XN--MGBT3DHD    whois.agitsys.net

    WANG            whois.gtld.knet.cn
    XN--30RR7Y      whois.gtld.knet.cn
    XN--3BST00M     whois.gtld.knet.cn
    XN--6QQ986B3XL  whois.gtld.knet.cn
    XN--9ET52U      whois.gtld.knet.cn
    XN--CZRU2D      whois.gtld.knet.cn
    XN--FIQ64B      whois.gtld.knet.cn

    MK              whois.marnet.mk
    XN--D1ALF       whois.marnet.mk

    DZ               whois.nic.dz
    XN--LGBBAT1AD8J  whois.nic.dz

    DATSUN          whois.nic.gmo
    FUJITSU         whois.nic.gmo
    GOO             whois.nic.gmo
    HISAMITSU       whois.nic.gmo
    HITACHI         whois.nic.gmo
    INFINITI        whois.nic.gmo
    JCB             whois.nic.gmo
    MITSUBISHI      whois.nic.gmo
    MTPC            whois.nic.gmo
    NISSAN          whois.nic.gmo
    PANASONIC       whois.nic.gmo
    PIONEER         whois.nic.gmo
    SHARP           whois.nic.gmo
    YODOBASHI       whois.nic.gmo

    OM               whois.registry.om
    XN--MGB9AWBF     whois.registry.om

    SY               whois.tld.sy
    XN--OGBPF8FL     whois.tld.sy

    XN--FIQS8S       cwhois.cnnic.cn
    XN--FIQZ9S       cwhois.cnnic.cn

    NET.SO                  whois.nic.so

    INT.RU                  whois.int.ru

    PRIV.AT                 whois.nic.priv.at

    AI                      whois.ai

    BN                      whois.bnnic.bn

    AARP                    whois.nic.aarp

    ABC                     whois.nic.abc

    ABUDHABI                whois.nic.abudhabi

    ACCOUNTANT              whois.nic.accountant

    ADAC                    whois.nic.adac

    AEG                     whois.nic.aeg

    AF                      whois.nic.af

    AFAMILYCOMPANY          whois.nic.afamilycompany

    AFL                     whois.nic.afl

    AIRBUS                  whois.nic.airbus

    AIRTEL                  whois.nic.airtel

    ALIBABA                 whois.nic.alibaba

    ALSTOM                  whois.nic.alstom

    AMERICANFAMILY          whois.nic.americanfamily

    AMFAM                   whois.nic.amfam

    ANZ                     whois.nic.anz

    AOL                     whois.nic.aol

    ARTE                    whois.nic.arte

    ASDA                    whois.nic.asda

    AUSPOST                 whois.nic.auspost

    AW                      whois.nic.aw

    BANK                    whois.nic.bank

    BARCELONA               whois.nic.barcelona

    BARCLAYCARD             whois.nic.barclaycard

    BARCLAYS                whois.nic.barclays

    BAREFOOT                whois.nic.barefoot

    BASKETBALL              whois.nic.basketball

    BAUHAUS                 whois.nic.bauhaus

    BAYERN                  whois.nic.bayern

    BBC                     whois.nic.bbc

    BBT                     whois.nic.bbt

    BBVA                    whois.nic.bbva

    BCN                     whois.nic.bcn

    BEAUTY                  whois.nic.beauty

    BENTLEY                 whois.nic.bentley

    BID                     whois.nic.bid

    BLANCO                  whois.nic.blanco

    BLOG                    whois.nic.blog

    BMS                     whois.nic.bms

    BO                      whois.nic.bo

    BOFA                    whois.nic.bofa

    BOND                    whois.nic.bond

    BOOTS                   whois.nic.boots

    BOSCH                   whois.nic.bosch

    BRADESCO                whois.nic.bradesco

    BRIDGESTONE             whois.nic.bridgestone

    BROADWAY                whois.nic.broadway

    BROTHER                 whois.nic.brother

    BRUSSELS                whois.nic.brussels

    BZH                     whois.nic.bzh

    BW                      whois.nic.net.bw

    BI                      whois1.nic.bi

    CANCERRESEARCH          whois.nic.cancerresearch

    CANON                   whois.nic.canon

    PE                      kero.yachay.pe

    COLOGNE                 whois-fe1.pdt.cologne.tango.knipp.de
    GMX                     whois-fe1.gmx.tango.knipp.de
    KOELN                   whois-fe1.pdt.koeln.tango.knipp.de
    MOVISTAR                whois-fe.movistar.tango.knipp.de
    TELEFONICA              whois-fe.telefonica.tango.knipp.de

    SMART                   whois-gtld.smart.com.ph

    TN                      whois.ati.tn

    UG                      whois.co.ug

    GQ                      whois.dominio.gq

    CF                      whois.dot.cf

    ML                      whois.dot.ml

    POST                    whois.dotpostregistry.net

    EUS                     whois.eus.coreregistry.net
    GAL                     whois.gal.coreregistry.net
    MANGO                   whois.mango.coreregistry.net
    SCOT                    whois.scot.coreregistry.net

    IKANO                   whois.ikano.tld-box.at
    VOTING                  whois.voting.tld-box.at

    KY                      whois.kyregistry.ky

    NC                      whois.nc

    CAPITALONE              whois.nic.capitalone

    CASA                    whois.nic.casa

    CBA                     whois.nic.cba

    CEO                     whois.nic.ceo

    CFA                     whois.nic.cfa

    CFD                     whois.nic.cfd

    CHANEL                  whois.nic.chanel

    CHINTAI                 whois.nic.chintai

    CITYEATS                whois.nic.cityeats

    CLUBMED                 whois.nic.clubmed

    COMCAST                 whois.nic.comcast

    COMMBANK                whois.nic.commbank

    COMPARE                 whois.nic.compare

    COMSEC                  whois.nic.comsec

    COOKING                 whois.nic.cooking

    COOKINGCHANNEL          whois.nic.cookingchannel

    CR                      whois.nic.cr

    CRICKET                 whois.nic.cricket

    CSC                     whois.nic.csc

    CUISINELLA              whois.nic.cuisinella

    CYMRU                   whois.nic.cymru

    DATE                    whois.nic.date

    DDS                     whois.nic.dds

    DELOITTE                whois.nic.deloitte

    DIY                     whois.nic.diy

    DOHA                    whois.nic.doha

    DOWNLOAD                whois.nic.download

    DUBAI                   whois.nic.dubai

    DUCK                    whois.nic.duck

    EC                      whois.nic.ec

    ERICSSON                whois.nic.ericsson

    ERNI                    whois.nic.erni

    EUROVISION              whois.nic.eurovision

    FAIRWINDS               whois.nic.fairwinds

    FAITH                   whois.nic.faith

    FASHION                 whois.nic.fashion

    FIDELITY                whois.nic.fidelity

    FIRESTONE               whois.nic.firestone

    FIRMDALE                whois.nic.firmdale

    FISHING                 whois.nic.fishing

    FOODNETWORK             whois.nic.foodnetwork

    FRL                     whois.nic.frl

    FRONTDOOR               whois.nic.frontdoor

    FUJIXEROX               whois.nic.fujixerox

    GALLO                   whois.nic.gallo

    GDN                     whois.nic.gdn

    GENT                    whois.nic.gent

    GENTING                 whois.nic.genting

    GEORGE                  whois.nic.george

    GGEE                    whois.nic.ggee

    GIVING                  whois.nic.giving

    GL                      whois.nic.gl

    GLADE                   whois.nic.glade

    GLOBAL                  whois.nic.global

    GOLDPOINT               whois.nic.goldpoint

    GOP                     whois.nic.gop

    HAMBURG                 whois.nic.hamburg

    HGTV                    whois.nic.hgtv

    HONDA                   whois.nic.honda

    HORSE                   whois.nic.horse

    HYUNDAI                 whois.nic.hyundai

    IBM                     whois.nic.ibm

    ICE                     whois.nic.ice

    ICU                     whois.nic.icu

    IFM                     whois.nic.ifm

    INSURANCE               whois.nic.insurance

    IRISH                   whois.nic.irish

    ISELECT                 whois.nic.iselect

    JAGUAR                  whois.nic.jaguar

    JAVA                    whois.nic.java

    JUNIPER                 whois.nic.juniper

    KDDI                    whois.nic.kddi

    KERRYHOTELS             whois.nic.kerryhotels

    KERRYLOGISTICS          whois.nic.kerrylogistics

    KERRYPROPERTIES         whois.nic.kerryproperties

    KFH                     whois.nic.kfh

    KIA                     whois.nic.kia

    KN                      whois.nic.kn

    KOMATSU                 whois.nic.komatsu

    KUOKGROUP               whois.nic.kuokgroup

    KYOTO                   whois.nic.kyoto

    LA                      whois.lanic.la

    LACAIXA                 whois.nic.lacaixa

    LADBROKES               whois.nic.ladbrokes

    LANCOME                 whois.nic.lancome

    LANDROVER               whois.nic.landrover

    LAT                     whois.nic.lat

    LATROBE                 whois.nic.latrobe

    LAW                     whois.nic.law

    LEFRAK                  whois.nic.lefrak

    LEGO                    whois.nic.lego

    LEXUS                   whois.nic.lexus

    LIAISON                 whois.nic.liaison

    LIDL                    whois.nic.lidl

    LIFESTYLE               whois.nic.lifestyle

    LINDE                   whois.nic.linde

    LIPSY                   whois.nic.lipsy

    LIXIL                   whois.nic.lixil

    LOAN                    whois.nic.loan

    LOCUS                   whois.nic.locus

    LOTTE                   whois.nic.lotte

    LUNDBECK                whois.nic.lundbeck

    MACYS                   whois.nic.macys

    MAKEUP                  whois.nic.makeup

    MAN                     whois.nic.man

    MARKETS                 whois.nic.markets

    MED                     whois.nic.med

    MLS                     whois.nic.mls

    MOE                     whois.nic.moe

    MONASH                  whois.nic.monash

    MONSTER                 whois.nic.monster

    MTN                     whois.nic.mtn

    MTR                     whois.nic.mtr

    MZ                      whois.nic.mz

    NAB                     whois.nic.nab

    NADEX                   whois.nic.nadex

    NATIONWIDE              whois.nic.nationwide

    NEC                     whois.nic.nec

    NG                      whois.nic.net.ng

    NETBANK                 whois.nic.netbank

    NEXT                    whois.nic.next

    NEXTDIRECT              whois.nic.nextdirect

    NICO                    whois.nic.nico

    NIKON                   whois.nic.nikon

    NISSAY                  whois.nic.nissay

    NORTON                  whois.nic.norton

    OBI                     whois.nic.obi

    OBSERVER                whois.nic.observer

    OFF                     whois.nic.off

    OLAYAN                  whois.nic.olayan

    OLAYANGROUP             whois.nic.olayangroup

    OMEGA                   whois.nic.omega

    ONYOURSIDE              whois.nic.onyourside

    ORACLE                  whois.nic.oracle

    ORANGE                  whois.nic.orange

    UY                      whois.nic.org.uy

    OSAKA                   whois.nic.osaka

    PARTY                   whois.nic.party

    PHILIPS                 whois.nic.philips

    PHYSIO                  whois.nic.physio

    PLAYSTATION             whois.nic.playstation

    POLITIE                 whois.nic.politie

    QUEBEC                  whois.nic.quebec

    QUEST                   whois.nic.quest

    RACING                  whois.nic.racing

    RADIO                   whois.nic.radio

    RAID                    whois.nic.raid

    REALESTATE              whois.nic.realestate

    REDSTONE                whois.nic.redstone

    REISE                   whois.nic.reise

    REVIEW                  whois.nic.review

    REXROTH                 whois.nic.rexroth

    RICOH                   whois.nic.ricoh

    RIGHTATHOME             whois.nic.rightathome

    RODEO                   whois.nic.rodeo

    RUHR                    whois.nic.ruhr

    RWE                     whois.nic.rwe

    SAMSCLUB                whois.nic.samsclub

    SAMSUNG                 whois.nic.samsung

    SANDVIK                 whois.nic.sandvik

    SANOFI                  whois.nic.sanofi

    SAP                     whois.nic.sap

    SBS                     whois.nic.sbs

    SCA                     whois.nic.sca

    SCB                     whois.nic.scb

    SCHMIDT                 whois.nic.schmidt

    SCHWARZ                 whois.nic.schwarz

    SCIENCE                 whois.nic.science

    SCJOHNSON               whois.nic.scjohnson

    SEAT                    whois.nic.seat

    SEEK                    whois.nic.seek

    SELECT                  whois.nic.select

    SES                     whois.nic.ses

    SFR                     whois.nic.sfr

    SHANGRILA               whois.nic.shangrila

    SHELL                   whois.nic.shell

    SKIN                    whois.nic.skin

    SKY                     whois.nic.sky

    SN                      whois.nic.sn

    SOFTBANK                whois.nic.softbank

    SONY                    whois.nic.sony

    SPREADBETTING           whois.nic.spreadbetting

    STARHUB                 whois.nic.starhub

    STATOIL                 whois.nic.statoil

    STC                     whois.nic.stc

    STCGROUP                whois.nic.stcgroup

    SUCKS                   whois.nic.sucks

    SURF                    whois.nic.surf

    SWATCH                  whois.nic.swatch

    SWISS                   whois.nic.swiss

    SYMANTEC                whois.nic.symantec

    TAB                     whois.nic.tab

    TAIPEI                  whois.nic.taipei

    TATAMOTORS              whois.nic.tatamotors

    TELECITY                whois.nic.telecity

    TG                      whois.nic.tg

    TIAA                    whois.nic.tiaa

    TIFFANY                 whois.nic.tiffany

    TIROL                   whois.nic.tirol

    TORAY                   whois.nic.toray

    TOSHIBA                 whois.nic.toshiba

    TOYOTA                  whois.nic.toyota

    TRADE                   whois.nic.trade

    TRAVELCHANNEL           whois.nic.travelchannel

    UBANK                   whois.nic.ubank

    UBS                     whois.nic.ubs

    VANA                    whois.nic.vana

    VANGUARD                whois.nic.vanguard

    VERISIGN                whois.nic.verisign

    VERSICHERUNG            whois.nic.versicherung

    VG                      whois.nic.vg

    VISA                    whois.nic.visa

    VISTA                   whois.nic.vista

    VIVA                    whois.nic.viva

    VLAANDEREN              whois.nic.vlaanderen

    VODKA                   whois.nic.vodka

    VOLVO                   whois.nic.volvo

    WALES                   whois.nic.wales

    WALMART                 whois.nic.walmart

    WARMAN                  whois.nic.warman

    WEBCAM                  whois.nic.webcam

    WEBER                   whois.nic.weber

    WED                     whois.nic.wed

    WHOSWHO                 whois.nic.whoswho

    WIN                     whois.nic.win

    WME                     whois.nic.wme

    WTC                     whois.nic.wtc

    XEROX                   whois.nic.xerox

    XFINITY                 whois.nic.xfinity

    XIN                     whois.nic.xin

    XN--11B4C3D             whois.nic.xn--11b4c3d

    ID                      whois.pandi.or.id

    PF                      whois.registry.pf

    TZ                      whois.tznic.or.tz

    XN--55QW42G             whois.conac.cn
    XN--ZFR164B             whois.conac.cn

    XN--J1AMH               whois.dotukr.com

    XN--90AE                whois.imena.bg

    MO               whois.monic.mo
    XN--MIX891F      whois.monic.mo

    XN--MGBERP4A5D4AR  whois.nic.net.sa

    XN--3PXU8K         whois.nic.xn--3pxu8k

    XN--42C2D9A        whois.nic.xn--42c2d9a

    XN--45Q11C         whois.nic.xn--45q11c

    XN--5SU34J936BGSG  whois.nic.xn--5su34j936bgsg

    XN--9DBQ2A         whois.nic.xn--9dbq2a

    XN--C2BR7G         whois.nic.xn--c2br7g

    XN--EFVY88H        whois.nic.xn--efvy88h

    XN--FHBEI          whois.nic.xn--fhbei

    XN--HXT814E        whois.nic.xn--hxt814e

    XN--KPUT3I         whois.nic.xn--kput3i

    XN--MGBA7C0BBN0A   whois.nic.xn--mgba7c0bbn0a

    XN--MGBCA7DZDO     whois.nic.xn--mgbca7dzdo

    XN--MK1BU44C       whois.nic.xn--mk1bu44c

    XN--MXTQ1M         whois.nic.xn--mxtq1m

    XN--NGBE9E0A       whois.nic.xn--ngbe9e0a

    XN--PSSY2U         whois.nic.xn--pssy2u

    XN--T60B56A        whois.nic.xn--t60b56a

    XN--TCKWE          whois.nic.xn--tckwe

    XN--W4R85EL8FHU5DNRA  whois.nic.xn--w4r85el8fhu5dnra

    XN--W4RS40L           whois.nic.xn--w4rs40l

    XPERIA                whois.nic.xperia

    ZM                    whois.nic.zm

    XN--YGBI2AMMX         whois.pnina.ps

    XN--SES554G           whois.nic.xn--ses554g

    XN--CLCHC0EA0B2G2A9GCD  whois.sgnic.sg
    XN--YFRO4I67O           whois.sgnic.sg

    XN--O3CW4H              whois.thnic.co.th

    XN--NODE                whois.itdc.ge

    XN--3E0B707E            whois.kr
    XN--CG4BKI              whois.kr

    SANDVIKCOROMANT         whois.nic.sandvikcoromant

    SCOR                    whois.nic.scor

    SEVEN                   whois.nic.seven

    SYDNEY                  whois.nic.sydney

    TDK                     whois.nic.tdk

    TEVA                    whois.nic.teva

    TRUST                   whois.nic.trust

    VIRGIN                  whois.nic.virgin

    VISTAPRINT              whois.nic.vistaprint

    WALTER                  whois.nic.walter

    WOODSIDE                whois.nic.woodside

    XN--KCRX77D1X4A         whois.nic.xn--kcrx77d1x4a

    XN--NGBC5AZD            whois.nic.xn--ngbc5azd

    COUNTRY                 whois.nic.country

    ABOGADO                 whois.nic.abogado

    BEER                    whois.nic.beer

    BUDAPEST                whois.nic.budapest

    FIT                     whois.nic.fit

    GARDEN                  whois.nic.garden

    LONDON                  whois.nic.london

    LUXE                    whois.nic.luxe

    MIAMI                   whois.nic.miami

    NRW                     whois.nic.nrw

    WEDDING                 whois.nic.wedding

    WORK                    whois.nic.work

    YOGA                    whois.nic.yoga

    AX                      whois.ax

    XN--90AIS               whois.cctld.by

    GF                      whois.mediaserv.net

    AMSTERDAM               whois.nic.amsterdam

    ARAB                    whois.nic.arab

    AUDIBLE                 whois.nic.audible

    AUTHOR                  whois.nic.author

    AWS                     whois.nic.aws

    BIBLE                   whois.nic.bible

    BOOK                    whois.nic.book

    BOT                     whois.nic.bot

    CALL                    whois.nic.call

    CATHOLIC                whois.nic.catholic

    CHARITY                 whois.nic.charity

    CIRCLE                  whois.nic.circle

    CPA                     whois.nic.cpa

    DATA                    whois.nic.data

    DEAL                    whois.nic.deal

    DNP                     whois.nic.dnp

    DO                      whois.nic.do

    FAST                    whois.nic.fast

    FIRE                    whois.nic.fire

    FOX                     whois.nic.fox

    FREE                    whois.nic.free

    GAY                     whois.nic.gay

    GE                      whois.nic.ge

    GOT                     whois.nic.got

    HOT                     whois.nic.hot

    IMDB                    whois.nic.imdb

    INC                     whois.nic.inc

    JOT                     whois.nic.jot

    JOY                     whois.nic.joy

    KINDLE                  whois.nic.kindle

    LIKE                    whois.nic.like

    LS                      whois.nic.ls

    MOBILE                  whois.nic.mobile

    MOI                     whois.nic.moi

    MR                      whois.nic.mr

    MW                      whois.nic.mw

    NHK                     whois.nic.nhk

    NOW                     whois.nic.now

    OKINAWA                 whois.nic.okinawa

    OTSUKA                  whois.nic.otsuka

    PAY                     whois.nic.pay

    PHARMACY                whois.nic.pharmacy

    PHONE                   whois.nic.phone

    PIN                     whois.nic.pin

    PRIME                   whois.nic.prime

    READ                    whois.nic.read

    RMIT                    whois.nic.rmit

    ROOM                    whois.nic.room

    RUGBY                   whois.nic.rugby

    RYUKYU                  whois.nic.ryukyu

    SAFE                    whois.nic.safe

    SAFETY                  whois.nic.safety

    SAVE                    whois.nic.save

    SECURE                  whois.nic.secure

    SILK                    whois.nic.silk

    SMILE                   whois.nic.smile

    SPORT                   whois.nic.sport

    SPOT                    whois.nic.spot

    SS                      whois.nic.ss

    SUZUKI                  whois.nic.suzuki

    TALK                    whois.nic.talk

    TD                      whois.nic.td

    TUNES                   whois.nic.tunes

    TUSHU                   whois.nic.tushu

    UNICOM                  whois.nic.unicom

    WANGGOU                 whois.nic.wanggou

    WOW                     whois.nic.wow

    XN--80AQECDR1A          whois.nic.xn--80aqecdr1a

    XN--8Y0A063A            whois.nic.xn--8y0a063a

    XN--MGBAB2BD            whois.nic.xn--mgbab2bd

    XN--MGBI4ECEXP          whois.nic.xn--mgbi4ecexp

    XN--NGBRX               whois.nic.xn--ngbrx

    XN--TIQ49XQYJ           whois.nic.xn--tiq49xqyj

    YAMAXUN                 whois.nic.yamaxun

    YOU                     whois.nic.you

    ZAPPOS                  whois.nic.zappos

    XN--2SCRJ9C             whois.registry.in
);


our %ip_whois_servers = qw(
    AFRINIC     whois.afrinic.net
    APNIC       whois.apnic.net
    ARIN        whois.arin.net
    LACNIC      whois.lacnic.net
    RIPE        whois.ripe.net

    JPNIC       whois.nic.ad.jp
    KRNIC       whois.krnic.net
);


# for not utf8
our %codepages = (
    'whois.nic.cl'       => 'iso-8859-1',
    'whois.ttpia.com'    => 'iso-8859-1',
    'whois.registro.br'  => 'iso-8859-1',
    'whois.cira.ca'      => 'iso-8859-1',
    'whois.denic.de'     => 'iso-8859-1',
    'whois.eenet.ee'     => 'iso-8859-1',
    'whois.ficora.fi'    => 'iso-8859-1',
    'whois.isnic.is'     => 'iso-8859-1',
    'whois.nic.hu'       => 'iso-8859-1',
    'whois.dns.pt'       => 'iso-8859-1',
    'whois.net.ua'       => 'koi8-u',
    'whois.biz.ua'       => 'koi8-u',
    'whois.co.ua'        => 'koi8-u',
    'whois.dn.ua'        => 'koi8-u',
    'whois.lg.ua'        => 'koi8-u',
    'whois.od.ua'        => 'koi8-u',
    'whois.in.ua'        => 'koi8-u',
    'whois.nic.or.kr'    => 'euc-kr',
    'whois.domain.kg'    => 'cp-1251',
);


our %notfound = (
    'whois.arin.net'        => '^No match found',
    'whois.ripe.net'        => 'No entries found',

    'whois.ripn.net'          => '(?:No entries found|The queried object does not exist)',
    'whois.registry.ripn.net' => '(?:No entries found|The queried object does not exist)',
    'whois.nic.net.ru'      => 'No entries found for the selected source',
    'whois.nic.ru'          => 'No entries found',
    'whois.nnov.ru'         => 'No entries found',
    'whois.int.ru'          => 'No entries found',
    'whois.reg.ru'          => '^Domain \S+ not found',

    'whois.com.ua'              => 'No entries found for',
    'whois.co.ua'               => 'No entries found',
    'whois.biz.ua'              => 'No entries found',
    'whois.net.ua'              => 'No match record found|No entries found',
    'delta.hostmaster.net.ua'   => 'No entries found for domain',
    'whois.pp.ua'               => 'No entries found',
    'whois.dn.ua'               => 'No match record found',
    'whois.lg.ua'               => 'No match record found',
    'whois.od.ua'               => 'Domain name does not exist',
    'whois.in.ua'               => 'Domain name does not exist',

    'whois.aero'                 => '^NOT FOUND',
    'whois.nic.asia'             => '^NOT FOUND',
    'whois.biz'                  => '^No Data Found',
    'whois-tel.neustar.biz'      => 'No Domain exists for',
    'whois.cat'                  => 'no matching objects found',
    'whois.educause.edu'         => '^No Match',
    'whois.nic.mil'              => '^No match for',
    'whois.museum'               => 'NOT FOUND',
    'whois.afilias.net'          => '^NOT FOUND',
    'whois.crsnic.net'           => '^No match for',
    'whois.networksolutions.com' => '(?i)no match',
    'whois.dotmobiregistry.net'  => '^NOT FOUND',
    'whois.nic.name'             => 'No match for domain',
    'whois.iana.org'             => '^Domain \S+ not found',
    'whois.pir.org'              => '^NOT FOUND',
    'ccwhois.verisign-grs.com'   => '^No match for',
    'jobswhois.verisign-grs.com' => '^No match for',
    'tvwhois.verisign-grs.com'   => '^No match for',
    'whois.registrypro.pro'      => '^NOT FOUND',
    'whois.worldsite.ws'         => 'The queried object does not exist: ',
    'whois.nic.travel'           => '^No Data Found',
    'whois.donuts.co'            => 'Domain not found',
    'whois.nic.menu'             => 'No Data Found',
    'whois.uniregistry.net'      => 'object does not exist',
    'whois.nic.uno'              => '^No Data Found',
    'whois.nic.berlin'           => '^The queried object does not exis',
    'whois.nic.kiwi'             => 'Status\: Not Registered|Not found',
    'whois.nic.build'            => 'No Data Found',
    'whois.nic.club'             => '^No Data Found',
    'whois.nic.luxury'           => 'No Data Found',

    'whois.publicinterestregistry.net' => 'NOT FOUND',
    'whois-dub.mm-registry.com'        => 'The queried object does not exist',

    'whois.nic.ag'            => 'NOT FOUND',
    'whois.nic.as'            => '^NOT FOUND',
    'whois.nic.at'            => 'nothing found',
    'whois.nic.br'            => 'No match for',
    'whois.amnic.net'         => 'No match',
    'whois.aunic.net'         => 'No Data Found',
    'whois.dns.be'            => 'Status:\s+AVAILABLE',
    'whois.register.bg'       => '(?:^Domain name \S+ does not exist|registration status\: available)',
    'whois.registro.br'       => 'No match for',
    'whois.registry.hm'       => 'Domain not found',
    'whois.nic.ht'            => 'No Object Found',
    'whois.cira.ca'           => '^Domain status\:\s+available',
    'whois.nic.cd'            => 'Domain Status: No Object Found',
    'whois.nic.ch'            => '^We do not have an entry in our database matching your',
    'whois.nic.ci'            => 'No Object Found',
    'whois.nic.cl'            => '\: no entries found',
    'whois.nic.cx'            => 'No Object Found',
    'whois.nic.cz'            => 'no entries found',
    'whois.denic.de'          => 'Status\: free',
    'whois.member.denic.de'   => 'Status\: free',
    'whois.nic.dm'            => '^not found\.',
    'whois.dk-hostmaster.dk'  => 'No entries found for the selected source',
    'whois.eenet.ee'          => 'Domain not found',
    'whois.eu'                => 'Status:\s+AVAILABLE',
    'whois.ficora.fi'         => 'Domain not found',
    'whois.domains.fj'        => 'The domain \S+ was not found',
    'whois.nic.fm'            => 'DOMAIN NOT FOUND',
    'whois.nic.fr'            => 'No entries found',
    'whois.channelisles.net'  => '^NOT FOUND',
    'whois.nic.gd'            => '^not found\.|DOMAIN NOT FOUND',
    'whois.nic.gs'            => 'No Object Found',
    'whois.registry.gy'       => 'No Object Found',
    'whois.hkirc.hk'          => '^The domain has not been registered',
    'whois.hknic.net.hk'      => '^The domain has not been registered',
    'whois.nic.hu'            => 'No match',
    'whois.domainregistry.ie' => 'Not Registered',
    'whois.isoc.org.il'       => 'No data was found',
    'whois.nic.im'            => 'The domain \S+ was not found',
    'whois.nic.io'            => '^NOT FOUND',
    'whois.isnic.is'          => 'No entries found',
    'whois.nic.it'            => 'Status:\s+AVAILABLE',
    'whois.nic.ir'            => 'No entries found',
    'whois.jprs.jp'           => 'No match',
    'whois.kenic.or.ke'       => 'No match found',
    'whois.nic.ki'            => 'No Object Found',
    'whois.nic.or.kr'         => 'requested domain was not found',
    'whois.nic.kz'            => 'Nothing found for this query',
    'whois.nic.la'            => 'DOMAIN NOT FOUND',
    'whois.nic.li'            => 'We do not have an entry',
    'whois.domreg.lt'         => 'Status:\s+available',
    'whois.dns.lu'            => 'No such domain',
    'whois.nic.lv'            => 'Status\: free',
    'whois.nic.ly'            => 'Not found',
    'whois.iam.net.ma'        => 'No Object Found',
    'whois.nic.md'            => 'No match for',
    'whois.nic.mg'            => 'No Object Found',
    'whois.nic.ms'            => 'No Object Found',
    'whois.nic.mt'            => 'Domain is not registered',
    'whois.nic.mu'            => 'No Object Found',
    'whois.nic.mx'            => 'Object_Not_Found',
    'whois.mynic.my'          => '^Domain Name \S+ does not',
    'whois.na-nic.com.na'     => 'No Object Found',
    'whois.nic.nf'            => 'No Object Found',
    'whois.domain-registry.nl' => '^\S+ is free',
    'whois.norid.no'          => '\sNo match',
    'whois.nic.nu'            => 'domain \S+ not found',
    'whois.srs.net.nz'        => 'query_status\: (500 Invalid|220 Avail)',
    'whois.dns.pl'            => 'No information available about domain name',
    'whois.nic.pm'            => 'No entries found',
    'whois.nic.pr'            => 'domain \S+ is not registered',
    'whois.dns.pt'            => 'no match',
    'whois.nic.re'            => 'No entries found',
    'whois.rotld.ro'          => 'No entries found',
    'whois.rnids.rs'          => 'Domain is not registered',
    'whois.saudinic.net.sa'   => 'No Match for',
    'whois.nic.sb'            => 'No Object Found',
    'whois.iis.se'            => 'domain \S+ not found',
    'whois.nic.net.sg'        => '^Domain Not Found',
    'whois.nic.sh'            => '^NOT FOUND',
    'whois.arnes.si'          => 'No entries found',
    'whois.nic.st'            => '^No entries found',
    'whois.sx'                => 'Not found',
    'whois.nic.tc'            => 'No Object Found',
    'whois.adamsnames.com'    => '^\S+ is not registered',
    'whois.nic.tl'            => 'No Object Found',
    'whois.nic.tf'            => 'No entries found',
    'whois.dot.tk'            => 'domain name not known',
    'whois.nic.tm'            => 'Domain \S+ is available',
    'whois.tonic.to'          => 'No match for',
    'whois.twnic.net'         => 'No Found',
    'whois.twnic.net.tw'      => '^No Found',
    'whois.nic.uk'            => 'No match for',
    'whois.ja.net'            => 'No such domain',
    'whois.nic.us'            => '^No Data Found',
    'whois.cctld.uz'          => 'not found in database',
    'whois.nic.ve'            => 'No match for',
    'whois.nic.wf'            => 'No entries found',
    'whois.nic.yt'            => 'No entries found',
    'whois.nic.pw'            => 'DOMAIN NOT FOUND',
    'whois.nic.vip'           => 'This domain name has not been registered\.',

    'whois.nsiregistry.net'     => 'No match for',

    'whois.007names.com'        => '^The Domain Name \S+ does not exist',
    'whois.0101domain.com'      => 'No match for domain',
    'whois.1stdomain.net'       => '^No domain found',
    'whois.123registration.com' => '^No match for',
     # 'whois.1isi.com'         -- empty on not fount
     # 'whois.35.com'           -- empty on not fount
    'whois.4domains.com'        => 'Domain Not Found', # Answer on first query -- "Please try again in 4 seconds"
    'whois.activeregistrar.com' => '^Domain name not found',
    'whois.addresscreation.com' => '^No match for',
     # 'whois.advantage-interactive.com' -- show empty fields
    'whois2.afilias-grs.net'    => '^NOT FOUND',
    'whois.aitdomains.com'      => '^No match for',
    'whois.alldomains.com'      => '^No match for',
    'whois.centralnic.com'      => '(?:DOMAIN NOT FOUND|Status:\s+free)',
    'whois.communigal.net'      => '^NOT FOUND',
    'whois.desertdevil.com'     => 'No match for domain',
    'whois.directi.com'         => 'No Match for',
    'whois.directnic.com'       => '^No match for',
    'whois.domaindiscover.com'  => '^No match for',
    'whois.domainstobeseen.com' => 'No match for',
    'whois.dotregistrar.com'    => '^No match for',
    'whois.dotster.com'         => 'No match for',
    'whois.ename.com'           => 'Out of Registry',
    'whois.enameco.com'         => 'No match for',
    'whois.gandi.net'           => 'Not found',
    'whois.gdns.net'            => '^Domain Not Found',
    'whois.getyername.com'      => '^No match for',
    'whois.godaddy.com'         => '^No match for',
    'whois.joker.com'           => 'object\(s\) not found',
    'whois.markmonitor.com'     => 'No entries found',
    'whois.melbourneit.com'     => '^Invalid/Unsupported whois name check',
    'whois.moniker.com'         => '^No Match',
    'whois.names4ever.com'      => '^No match for',
     # 'whois.namesbeyond.com'  ??? my IP in black list
    'whois.nameisp.com'         => 'domain not found',
     # 'whois.namescout.com'    -- need big timeout
    'whois.namesystem.com'      => '^Sorry, Domain does not exist',
    'whois.nordnet.net'         => 'No match for',
    'whois.paycenter.com.cn'    => 'no data found',
    'whois.pir.net'             => 'NOT FOUND',
    'whois.plisk.com'           => 'No match for',
    'whois.publicdomainregistry.com' => 'No match for',
    'whois.regtime.net'         => 'Domain \S+ not found',
    'whois.schlund.info'        => '^Domain \S+ is not registered here',
    'whois.thnic.net'           => 'No entries found',
    'whois.tucows.com'          => '^Can.t get information on non-local domain',
    'whois.ttpia.com'           => 'No match for',
    'whois.worldnames.net'      => 'NO MATCH for domain',
     # 'whois.yournamemonkey.com' -- need try again
    'whois.cnnic.net.cn'        => '^No matching record',
    'whois.nic.co'              => '^No Data Found',
    'whois.nic.me'              => 'NOT FOUND',
    'whois.domain.kg'           => 'Data not found. This domain is available for registration.',
    'whois.nic.one'             => 'No Data Found',

    # for VN | TJ zones
    'www_whois'                 => '(Available|no records found|is free|Not Registered)',

    'whois.nic.xxx'             => 'NOT FOUND',

    'whois.online.rs.corenic.net' => 'no matching objects found',
    'whois.site.rs.corenic.net'   => 'no matching objects found',
    'whois.nic.xn--80adxhks'      => 'Domain not found',
    'whois.nic.moscow'            => 'Domain not found',
    'whois.nic.tatar'             => 'queried object does not exist',
    'whois.nic.press'             => 'DOMAIN NOT FOUND',
    'whois.registry.qa'           => 'No Data Found',

    'whois.registry.net.za'       => '^Available',
    'net-whois.registry.net.za'   => '^Available',
    'org-whois.registry.net.za'   => '^Available',
    'www-whois.registry.net.za'   => '^Available',
    'web-whois.registry.net.za'   => '^Available',

    'whois.i-dns.net'                      => '^NOMATCH',
    'whois.dns.hr'                         => 'No entries found',
    'whois.flexireg.net'                   => 'Domain not found',
    'whois.netcom.cm'                      => 'Not Registered',
    'whois.nic.ac'                         => 'NOT FOUND',
    'whois.audns.net.au'                   => '^No Data Found',
    'whois.nic.best'                       => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.bj'                         => 'No Object Found',
    'whois.nic.broker'                     => 'No match for',
    'whois.nic.career'                     => 'No match for',
    'whois.nic.cc'                         => 'No match for',
    'whois.nic.cloud'                      => 'No Data Found',
    'whois.nic.courses'                    => 'No Data Found',
    'whois.nic.earth'                      => '^No Data Found',
    'whois.nic.film'                       => 'No Data Found',
    'whois.nic.forex'                      => 'No match for',
    'whois.nic.men'                        => 'No Data Found',
    'whois.nic.ooo'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.priv.at'                    => 'No entries found for the selected source',
    'whois.nic.pro'                        => 'NOT FOUND',
    'whois.nic.so'                         => 'No Object Found',
    'whois.nic.srl'                        => 'NOT FOUND',
    'whois.nic.study'                      => 'No Data Found',
    'whois.nic.top'                        => 'The queried object does not exist',
    'whois.nic.trading'                    => 'No match for',
    'whois.nic.tv'                         => 'No match for',
    'whois.nic.xn--p1acf'                  => 'No Object Found',
    'whois.rightside.co'                   => 'Domain not found',
    'whois.sk-nic.sk'                      => 'Domain not found',
    'whois.ksregistry.net'                 => 'The queried object does not exist',
    'whois-alsace.nic.fr'                  => 'The queried object does not exist: Domain name',
    'whois-aquarelle.nic.fr'               => 'The queried object does not exist: Domain name',
    'whois-bostik.nic.fr'                  => 'The queried object does not exist: Domain name',
    'whois.aeda.net.ae'                    => 'No Data Found',
    'whois.afilias-srs.net'                => 'NOT FOUND',
    'whois.ai'                             => '^Domain \S+ not registered',
    'whois.bnnic.bn'                       => 'Domain Not Found',
    'whois.gtlds.nic.br'                   => 'The queried object does not exist: ',
    'whois.ngtld.cn'                       => 'No matching record\.',
    'whois.nic.aarp'                       => 'No match for "',
    'whois.nic.abc'                        => 'No match for "',
    'whois.nic.abudhabi'                   => 'No Data Found',
    'whois.nic.accountant'                 => '^No Data Found',
    'whois.nic.adac'                       => 'DOMAIN NOT FOUND',
    'whois.nic.aeg'                        => 'No match for "',
    'whois.nic.af'                         => 'Domain Status: No Object Found',
    'whois.nic.afamilycompany'             => 'No match for "',
    'whois.nic.afl'                        => 'No Data Found',
    'whois.nic.airbus'                     => 'No match for "',
    'whois.nic.airtel'                     => 'No match for "',
    'whois.nic.alstom'                     => 'The queried object does not exist: no matching objects found',
    'whois.nic.americanfamily'             => 'No match for "',
    'whois.nic.amfam'                      => 'No match for "',
    'whois.nic.anz'                        => 'No Data Found',
    'whois.nic.aol'                        => 'No match for "',
    'whois.nic.arte'                       => 'No match for "',
    'whois.nic.asda'                       => 'No match for "',
    'whois.nic.auspost'                    => 'No Data Found',
    'whois.nic.aw'                         => '\.aw is free',
    'whois.nic.bank'                       => 'No match for "',
    'whois.nic.barcelona'                  => 'The queried object does not exist: no matching objects found',
    'whois.nic.barclaycard'                => 'No Data Found',
    'whois.nic.barclays'                   => 'No Data Found',
    'whois.nic.barefoot'                   => 'No match for "',
    'whois.nic.basketball'                 => 'DOMAIN NOT FOUND',
    'whois.nic.bauhaus'                    => 'The queried object does not exist: no matching objects found',
    'whois.nic.bayern'                     => 'This domain name has not been registered\.',
    'whois.nic.bbc'                        => 'This domain name has not been registered\.',
    'whois.nic.bbt'                        => 'No match for "',
    'whois.nic.bbva'                       => 'No match for "',
    'whois.nic.bcn'                        => 'The queried object does not exist: no matching objects found',
    'whois.nic.beauty'                     => 'No match for "',
    'whois.nic.bentley'                    => 'This domain name has not been registered\.',
    'whois.nic.bid'                        => '^No Data Found',
    'whois.nic.blanco'                     => 'No match for "',
    'whois.nic.blog'                       => 'This domain name has not been registered\.',
    'whois.nic.bms'                        => 'No match for "',
    'whois.nic.bo'                         => 'whois\.nic\.bo solo acepta consultas con dominios \.bo',
    'whois.nic.bofa'                       => 'No match for "',
    'whois.nic.bond'                       => 'No Data Found',
    'whois.nic.boots'                      => 'No Data Found',
    'whois.nic.bosch'                      => 'No match for "',
    'whois.nic.bradesco'                   => 'This domain name has not been registered\.',
    'whois.nic.bridgestone'                => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.broadway'                   => 'This domain name has not been registered\.',
    'whois.nic.brother'                    => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.brussels'                   => 'The queried object does not exist',
    'whois.nic.bzh'                        => 'The queried object does not exist: Domain name',
    'whois.nic.google'                     => 'Domain not found\.',
    'whois.nic.net.bw'                     => 'Domain Status: No Object Found',
    'whois.teleinfo.cn'                    => 'No matching record',
    'whois1.nic.bi'                        => 'Domain Status: No Object Found',
    'capetown-whois.registry.net.za'       => 'Available',
    'whois.nic.cancerresearch'             => 'No Data Found',
    'whois.nic.canon'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'durban-whois.registry.net.za'         => 'Available',
    'joburg-whois.registry.net.za'         => 'Available',
    'africa-whois.registry.net.za'         => 'Available',
    'kero.yachay.pe'                       => 'Domain Status: No Object Found',
    'whois-corsica.nic.fr'                 => 'The queried object does not exist: Domain name',
    'whois-fe.movistar.tango.knipp.de'     => 'The queried object does not exist: no matching objects found',
    'whois-fe.telefonica.tango.knipp.de'   => 'The queried object does not exist: no matching objects found',
    'whois-fe1.gmx.tango.knipp.de'         => 'The queried object does not exist: no matching objects found',
    'whois-fe1.pdt.cologne.tango.knipp.de' => 'The queried object does not exist: no matching objects found',
    'whois-fe1.pdt.koeln.tango.knipp.de'   => 'The queried object does not exist: no matching objects found',
    'whois-frogans.nic.fr'                 => 'The queried object does not exist: Domain name',
    'whois-gtld.smart.com.ph'              => 'DOMAIN NOT FOUND',
    'whois-lancaster.nic.fr'               => 'The queried object does not exist: Domain name',
    'whois-leclerc.nic.fr'                 => 'The queried object does not exist: Domain name',
    'whois-mma.nic.fr'                     => 'The queried object does not exist: Domain name',
    'whois-mutuelle.nic.fr'                => 'The queried object does not exist: Domain name',
    'whois-ovh.nic.fr'                     => 'The queried object does not exist: Domain name',
    'whois-paris.nic.fr'                   => 'The queried object does not exist: Domain name',
    'whois-sncf.nic.fr'                    => 'The queried object does not exist: Domain name',
    'whois-total.nic.fr'                   => 'The queried object does not exist: Domain name',
    'whois.agitsys.net'                    => 'Domain Status: No Object Found',
    'whois.ati.tn'                         => 'NO OBJECT FOUND!',
    'whois.co.ug'                          => '^No entries found',
    'whois.dominio.gq'                     => 'Invalid query or domain name not known in Dominio GQ Domain Registry',
    'whois.dot.cf'                         => 'Invalid query or domain name not known in Dot CF Domain Registry',
    'whois.dot.ml'                         => 'Invalid query or domain name not known in Point ML Domain Registry',
    'whois.dotpostregistry.net'            => 'NOT FOUND',
    'whois.eus.coreregistry.net'           => 'The queried object does not exist: no matching objects found',
    'whois.gal.coreregistry.net'           => 'The queried object does not exist: no matching objects found',
    'whois.gtld.knet.cn'                   => 'The queried object does not exist: ',
    'whois.ikano.tld-box.at'               => 'The queried object does not exist',
    'whois.kyregistry.ky'                  => 'The queried object does not exist: Domain ',
    'whois.madrid.rs.corenic.net'          => 'The queried object does not exist: no matching objects found',
    'whois.mango.coreregistry.net'         => 'no matching objects found',
    'whois.marnet.mk'                      => 'No entries found',
    'whois.nc'                             => 'No entries found in the .nc database',
    'whois.nic.alibaba'                    => '^NOT FOUND',
    'whois.nic.alipay'                     => '^NOT FOUND',
    'whois.nic.capitalone'                 => 'No match for "',
    'whois.nic.casa'                       => 'This domain name has not been registered\.',
    'whois.nic.cba'                        => 'No Data Found',
    'whois.nic.ceo'                        => '^No Data Found',
    'whois.nic.cfa'                        => 'No match for "',
    'whois.nic.cfd'                        => 'No match for "',
    'whois.nic.chanel'                     => 'No match for "',
    'whois.nic.chintai'                    => 'No Data Found',
    'whois.nic.cityeats'                   => 'No match for "',
    'whois.nic.clubmed'                    => 'No match for "',
    'whois.nic.comcast'                    => 'This domain name has not been registered\.',
    'whois.nic.commbank'                   => 'No Data Found',
    'whois.nic.compare'                    => 'No Data Found',
    'whois.nic.comsec'                     => 'No match for "',
    'whois.nic.cooking'                    => 'This domain name has not been registered\.',
    'whois.nic.cookingchannel'             => 'No match for "',
    'whois.nic.country',                   => 'Domain \S+ is available for registration',
    'whois.nic.cr'                         => 'no entries found',
    'whois.nic.cricket'                    => '^No Data Found',
    'whois.nic.csc'                        => 'No match for "',
    'whois.nic.cuisinella'                 => 'No Data Found',
    'whois.nic.cymru'                      => 'This domain name has not been registered\.',
    'whois.nic.date'                       => '^No Data Found',
    'whois.nic.dds'                        => 'This domain name has not been registered\.',
    'whois.nic.deloitte'                   => 'Status: AVAILABLE \(No match for domain "',
    'whois.nic.diy'                        => 'No match for "',
    'whois.nic.doha'                       => 'No Data Found',
    'whois.nic.download'                   => '^No Data Found',
    'whois.nic.dubai'                      => 'No Data Found',
    'whois.nic.duck'                       => 'No match for "',
    'whois.nic.dz'                         => 'NO OBJECT FOUND!',
    'whois.nic.ec'                         => 'Status: Not Registered',
    'whois.nic.ericsson'                   => 'No match for "',
    'whois.nic.erni'                       => 'The queried object does not exist: no matching objects found',
    'whois.nic.eurovision'                 => 'The queried object does not exist: no matching objects found',
    'whois.nic.fairwinds'                  => 'No match for "',
    'whois.nic.faith'                      => '^No Data Found',
    'whois.nic.fashion'                    => 'This domain name has not been registered\.',
    'whois.nic.fidelity'                   => 'No match for "',
    'whois.nic.firestone'                  => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.firmdale'                   => 'Domain Not Found',
    'whois.nic.fishing'                    => 'This domain name has not been registered\.',
    'whois.nic.foodnetwork'                => 'No match for "',
    'whois.nic.frl'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.frontdoor'                  => 'No match for "',
    'whois.nic.fujixerox'                  => 'No match for "',
    'whois.nic.gallo'                      => 'No match for "',
    'whois.nic.gdn'                        => 'Domain Not Found',
    'whois.nic.gent'                       => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.genting'                    => 'No match for "',
    'whois.nic.george'                     => 'No match for "',
    'whois.nic.ggee'                       => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.giving'                     => 'No Data Found',
    'whois.nic.gl'                         => 'Domain Status: No Object Found',
    'whois.nic.glade'                      => 'No match for "',
    'whois.nic.global'                     => 'NOT FOUND',
    'whois.nic.gmo'                        => '^The queried object does not exist',
    'whois.nic.goldpoint'                  => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.gop'                        => 'This domain name has not been registered\.',
    'whois.dotgov.gov'                     => 'No match for "',
    'whois.nic.hamburg'                    => 'The queried object does not exist',
    'whois.nic.hgtv'                       => 'No match for "',
    'whois.nic.honda'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.horse'                      => 'This domain name has not been registered\.',
    'whois.nic.hyundai'                    => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.ibm'                        => 'No Data Found',
    'whois.nic.ice'                        => 'No match for "',
    'whois.nic.icu'                        => '(?:^registration status\: invalid|The queried object does not exist: DOMAIN NOT FOUND)',
    'whois.nic.ifm'                        => 'The queried object does not exist: no matching objects found',
    'whois.nic.insurance'                  => 'No match for "',
    'whois.nic.irish'                      => '^Domain not found',
    'whois.nic.airforce'                   => '^Domain not found',
    'whois.nic.market'                     => '^Domain not found',
    'whois.nic.forsale'                    => '^Domain not found',
    'whois.nic.degree'                     => '^Domain not found',
    'whois.nic.gives'                      => '^Domain not found',
    'whois.nic.rehab'                      => '^Domain not found',
    'whois.nic.dentist'                    => '^Domain not found',
    'whois.nic.software'                   => '^Domain not found',
    'whois.nic.auction'                    => '^Domain not found',
    'whois.nic.engineer'                   => '^Domain not found',
    'whois.nic.vet'                        => '^Domain not found',
    'whois.nic.attorney'                   => '^Domain not found',
    'whois.nic.lawyer'                     => '^Domain not found',
    'whois.nic.haus'                       => '^Domain not found',
    'whois.nic.rocks'                      => '^Domain not found',
    'whois.nic.consulting'                 => '^Domain not found',
    'whois.nic.kaufen'                     => '^Domain not found',
    'whois.nic.actor'                      => '^Domain not found',
    'whois.nic.moda'                       => '^Domain not found',
    'whois.nic.pub'                        => '^Domain not found',
    'whois.nic.social'                     => '^Domain not found',
    'whois.nic.futbol'                     => '^Domain not found',
    'whois.nic.reviews'                    => '^Domain not found',
    'whois.nic.ninja'                      => '^Domain not found',
    'whois.nic.immobilien'                 => '^Domain not found',
    'whois.nic.democrat'                   => '^Domain not found',
    'whois.nic.dance'                      => '^Domain not found',
    'whois.nic.hospital'                   => '^Domain not found',
    'whois.nic.buzz'                       => '^No Data Found',
    'whois.nic.nyc'                        => '^No Data Found',
    'whois.nic.qpon'                       => '^No Data Found',
    'whois.nic.stream'                     => '^No Data Found',
    'whois.nic.baby'                       => '^No Data Found',
    'whois.nic.health'                     => '^No Data Found',
    'whois.nic.tokyo'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.nagoya'                     => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.yokohama'                   => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.fun'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.boston'                     => 'This domain name has not been registered\.',
    'whois.nic.tr'                         => 'No match found for',
    'whois.nic.wien'                       => '^Available',
    'whois.nic.hn'                         => 'Domain Status: No Object Found',
    'whois.nic.iselect'                    => 'No Data Found',
    'whois.nic.jaguar'                     => 'No match for "',
    'whois.nic.java'                       => 'No match for "',
    'whois.nic.jobs'                       => 'No match for "',
    'whois.nic.juniper'                    => 'No match for "',
    'whois.nic.kddi'                       => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.kerryhotels'                => 'No match for "',
    'whois.nic.kerrylogistics'             => 'No match for "',
    'whois.nic.kerryproperties'            => 'No match for "',
    'whois.nic.kfh'                        => 'DOMAIN NOT FOUND',
    'whois.nic.kia'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.kn'                         => 'Domain Status: No Object Found',
    'whois.nic.komatsu'                    => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.kuokgroup'                  => 'No match for "',
    'whois.nic.kyoto'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.lanic.la'                       => 'DOMAIN NOT FOUND',
    'whois.nic.lacaixa'                    => 'The queried object does not exist: no matching objects found',
    'whois.nic.ladbrokes'                  => 'No match for "',
    'whois.nic.lancome'                    => 'No match for "',
    'whois.nic.landrover'                  => 'No match for "',
    'whois.nic.lat'                        => 'The queried object does not exists \(El objeto consultado no existe\)',
    'whois.nic.latrobe'                    => 'No Data Found',
    'whois.nic.law'                        => 'This domain name has not been registered\.',
    'whois.nic.lefrak'                     => 'No match for "',
    'whois.nic.lego'                       => 'No match for "',
    'whois.nic.lexus'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.liaison'                    => 'No match for "',
    'whois.nic.lidl'                       => 'Status: AVAILABLE \(No match for domain "',
    'whois.nic.lifestyle'                  => 'No match for "',
    'whois.nic.linde'                      => 'No match for "',
    'whois.nic.lipsy'                      => 'No match for "',
    'whois.nic.lixil'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.loan'                       => '^No Data Found',
    'whois.nic.locus'                      => 'This domain name has not been registered\.',
    'whois.nic.lotte'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.lundbeck'                   => 'No match for "',
    'whois.nic.macys'                      => 'No match for "',
    'whois.nic.makeup'                     => 'No match for "',
    'whois.nic.man'                        => 'The queried object does not exist: no matching objects found',
    'whois.nic.markets'                    => 'No match for "',
    'whois.nic.med'                        => 'No match for "',
    'whois.nic.mls'                        => 'No match for "',
    'whois.nic.moe'                        => '^No Data Found',
    'whois.nic.monash'                     => 'No Data Found',
    'whois.nic.monster'                    => '^NOT FOUND',
    'whois.nic.mtn'                        => 'No Data Found',
    'whois.nic.mtr'                        => 'The domain has not been registered\.',
    'whois.nic.mz'                         => 'Domain Status: No Object Found',
    'whois.nic.nab'                        => 'No match for "',
    'whois.nic.nadex'                      => 'No match for "',
    'whois.nic.nationwide'                 => 'No match for "',
    'whois.nic.nec'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.net.ng'                     => 'Domain Status: No Object Found',
    'whois.nic.netbank'                    => 'No Data Found',
    'whois.nic.next'                       => 'No match for "',
    'whois.nic.nextdirect'                 => 'No match for "',
    'whois.nic.nico'                       => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.nikon'                      => 'No match for "',
    'whois.nic.nissay'                     => 'No match for "',
    'whois.nic.norton'                     => 'No match for "',
    'whois.nic.obi'                        => 'No match for "',
    'whois.nic.observer'                   => 'DOMAIN NOT FOUND',
    'whois.nic.off'                        => 'No match for "',
    'whois.nic.olayan'                     => 'No Data Found',
    'whois.nic.olayangroup'                => 'No Data Found',
    'whois.nic.omega'                      => 'No match for "',
    'whois.nic.onyourside'                 => 'No match for "',
    'whois.nic.oracle'                     => 'No match for "',
    'whois.nic.orange'                     => 'No match for "',
    'whois.nic.org.uy'                     => 'No match for',
    'whois.nic.osaka'                      => '^No Data Found',
    'whois.nic.party'                      => '^No Data Found',
    'whois.nic.philips'                    => 'No Data Found',
    'whois.nic.physio'                     => 'No Data Found',
    'whois.nic.playstation'                => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.politie'                    => 'Domain Status: free',
    'whois.nic.promo'                      => 'NOT FOUND',
    'whois.nic.quebec'                     => 'The queried object does not exist: no matching objects found',
    'whois.nic.quest'                      => 'No Data Found',
    'whois.nic.racing'                     => '^No Data Found',
    'whois.nic.radio'                      => 'The queried object does not exist: no matching objects found',
    'whois.nic.raid'                       => 'No match for "',
    'whois.nic.realestate'                 => 'No match for "',
    'whois.nic.redstone'                   => 'NOT FOUND',
    'whois.nic.reise'                      => 'Domain not found\.',
    'whois.nic.review'                     => '^No Data Found',
    'whois.nic.rexroth'                    => 'No match for "',
    'whois.nic.ricoh'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.rightathome'                => 'No match for "',
    'whois.nic.rodeo'                      => 'This domain name has not been registered\.',
    'whois.nic.ruhr'                       => 'The queried object does not exist: no matching objects found',
    'whois.nic.rwe'                        => 'No match for "',
    'whois.nic.samsclub'                   => 'No match for "',
    'whois.nic.samsung'                    => '^DOMAIN NOT FOUND',
    'whois.nic.sandvik'                    => 'No Data Found',
    'whois.nic.sanofi'                     => 'No match for "',
    'whois.nic.sap'                        => 'The queried object does not exist: no matching objects found',
    'whois.nic.sbs'                        => 'No match for "',
    'whois.nic.sca'                        => 'No match for "',
    'whois.nic.scb'                        => 'NOT FOUND',
    'whois.nic.schwarz'                    => 'Status: AVAILABLE \(No match for domain "',
    'whois.nic.schmidt'                    => '^No Data Found',
    'whois.nic.science'                    => '^No Data Found',
    'whois.nic.scjohnson'                  => 'No match for "',
    'whois.nic.seat'                       => 'The queried object does not exist: no matching objects found',
    'whois.nic.ses'                        => 'No match for "',
    'whois.nic.seek'                       => '^No Data Found',
    'whois.nic.sfr'                        => 'DOMAIN NOT FOUND',
    'whois.nic.shangrila'                  => 'No match for "',
    'whois.nic.shell'                      => 'No match for "',
    'whois.nic.skin'                       => 'No match for "',
    'whois.nic.sky'                        => 'No match for "',
    'whois.nic.select'                     => '^No Data Found',
    'whois.nic.sn'                         => 'NOT FOUND',
    'whois.nic.softbank'                   => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.sony'                       => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.spreadbetting'              => 'No match for "',
    'whois.nic.starhub'                    => '^No Data Found',
    'whois.nic.statoil'                    => 'No match for "',
    'whois.nic.stc'                        => 'DOMAIN NOT FOUND',
    'whois.nic.stcgroup'                   => 'DOMAIN NOT FOUND',
    'whois.nic.sucks'                      => '^No Data Found',
    'whois.nic.surf'                       => 'This domain name has not been registered\.',
    'whois.nic.swatch'                     => 'No match for "',
    'whois.nic.swiss'                      => 'The queried object does not exist: no matching objects found',
    'whois.nic.symantec'                   => 'No match for "',
    'whois.nic.tab'                        => '^No Data Found',
    'whois.nic.taipei'                     => '^No Data Found',
    'whois.nic.tatamotors'                 => 'No match for "',
    'whois.nic.telecity'                   => 'This domain name has not been registered\.',
    'whois.nic.tg'                         => 'NO OBJECT FOUND!',
    'whois.nic.tiaa'                       => 'No match for "',
    'whois.nic.tiffany'                    => 'No match for "',
    'whois.nic.tirol'                      => 'The queried object does not exist',
    'whois.nic.toray'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.toshiba'                    => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.toyota'                     => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.trade'                      => '^No Data Found',
    'whois.nic.travelchannel'              => 'No match for "',
    'whois.nic.tube'                       => '^No Data Found',
    'whois.nic.ubank'                      => 'No match for "',
    'whois.nic.ubs'                        => 'No match for "',
    'whois.nic.vana'                       => 'No match for "',
    'whois.nic.vanguard'                   => 'No match for "',
    'whois.nic.verisign'                   => 'No match for "',
    'whois.nic.versicherung'               => 'The queried object does not exist',
    'whois.nic.vg'                         => 'not found|DOMAIN NOT FOUND',
    'whois.nic.visa'                       => 'No match for "',
    'whois.nic.viva'                       => 'DOMAIN NOT FOUND',
    'whois.nic.vlaanderen'                 => 'The queried object does not exist',
    'whois.nic.vodka'                      => 'This domain name has not been registered\.',
    'whois.nic.volvo'                      => 'No match for "',
    'whois.nic.wales'                      => 'This domain name has not been registered\.',
    'whois.nic.walmart'                    => 'No match for "',
    'whois.nic.warman'                     => 'No match for "',
    'whois.nic.webcam'                     => '^No Data Found',
    'whois.nic.weber'                      => 'No match for "',
    'whois.nic.wed'                        => 'Domain Status: No Object Found',
    'whois.nic.whoswho'                    => '^No Data Found',
    'whois.nic.win'                        => '^No Data Found',
    'whois.nic.wme'                        => 'DOMAIN NOT FOUND',
    'whois.nic.xerox'                      => 'No match for "',
    'whois.nic.xfinity'                    => 'This domain name has not been registered\.',
    'whois.nic.xin'                        => 'NOT FOUND',
    'whois.nic.xn--11b4c3d'                => 'No match for "',
    'whois.pandi.or.id'                    => 'DOMAIN NOT FOUND',
    'whois.registry.om'                    => 'No Data Found',
    'whois.registry.pf'                    => 'Domain unknown',
    'whois.scot.coreregistry.net'          => 'The queried object does not exist: no matching objects found',
    'whois.tld.sy'                         => 'Domain Status: No Object Found',
    'whois.tznic.or.tz'                    => 'No entries found',
    'whois.voting.tld-box.at'              => 'The queried object does not exist',
    'cwhois.cnnic.cn'                      => 'No matching record\.',
    'whois.conac.cn'                       => 'Not find MatchingRecord',
    'whois.dotukr.com'                     => 'No match for domain',
    'whois.imena.bg'                       => 'does not exist in database!',
    'whois.monic.mo'                       => 'No match for',
    'whois.nic.net.sa'                     => 'No Match for',
    'whois.nic.xn--3pxu8k'                 => 'No match for "',
    'whois.nic.xn--42c2d9a'                => 'No match for "',
    'whois.nic.xn--45q11c'                 => 'The queried object does not exist: ',
    'whois.nic.xn--5su34j936bgsg'          => 'No match for "',
    'whois.nic.xn--9dbq2a'                 => 'No match for "',
    'whois.nic.xn--c2br7g'                 => 'No match for "',
    'whois.nic.xn--efvy88h'                => 'The queried object does not exist: ',
    'whois.nic.xn--fhbei'                  => 'No match for "',
    'whois.nic.xn--hxt814e'                => 'The queried object does not exist: ',
    'whois.nic.xn--kput3i'                 => 'NOT FOUND',
    'whois.nic.xn--mgbca7dzdo'             => 'No Data Found',
    'whois.nic.xn--mk1bu44c'               => 'No match for "',
    'whois.nic.xn--mxtq1m'                 => 'Not Found\.',
    'whois.nic.xn--ngbe9e0a'               => 'DOMAIN NOT FOUND',
    'whois.nic.xn--pssy2u'                 => 'No match for "',
    'whois.nic.xn--t60b56a'                => 'No match for "',
    'whois.nic.xn--tckwe'                  => 'No match for "',
    'whois.nic.xn--w4r85el8fhu5dnra'       => 'No match for "',
    'whois.nic.xn--w4rs40l'                => 'No match for "',
    'whois.nic.xperia'                     => 'No match for "',
    'whois.nic.zm'                         => 'Domain Status: No Object Found',
    'whois.pnina.ps'                       => 'Domain Status: No Object Found',
    'whois.registry.knet.cn'               => 'The queried object does not exist: ',
    'whois.sgnic.sg'                       => 'Domain Not Found',
    'whois.thnic.co.th'                    => 'No match for',
    'whois.itdc.ge'                        => 'NO OBJECT FOUND',
    'whois.kr'                             => 'The requested domain was not found',
    'whois.nic.sandvikcoromant'            => 'No Data Found',
    'whois.nic.scor'                       => 'No Data Found',
    'whois.nic.seven'                      => 'No Data Found',
    'whois.nic.sydney'                     => 'No Data Found',
    'whois.nic.tdk'                        => 'No Data Found',
    'whois.nic.teva'                       => 'No Data Found',
    'whois.nic.trust'                      => 'No Data Found',
    'whois.nic.virgin'                     => 'No Data Found',
    'whois.nic.vistaprint'                 => 'No Data Found',
    'whois.nic.walter'                     => 'No Data Found',
    'whois.nic.woodside'                   => 'No Data Found',
    'whois.nic.xn--kcrx77d1x4a'            => 'No Data Found',
    'whois.nic.xn--ngbc5azd'               => 'No Data Found',
    'whois.nic.shop'                       => 'The queried object does not exist: ',
    'whois.nic.abogado'                    => 'This domain name has not been registered',
    'whois.nic.beer'                       => 'This domain name has not been registered',
    'whois.nic.budapest'                   => 'This domain name has not been registered',
    'whois.nic.fit'                        => 'This domain name has not been registered',
    'whois.nic.garden'                     => 'This domain name has not been registered',
    'whois.nic.london'                     => 'This domain name has not been registered',
    'whois.nic.luxe'                       => 'This domain name has not been registered',
    'whois.nic.miami'                      => 'This domain name has not been registered',
    'whois.nic.nrw'                        => 'The queried object does not exist: no matching objects found',
    'whois.nic.wedding'                    => 'This domain name has not been registered',
    'whois.nic.work'                       => 'This domain name has not been registered',
    'whois.nic.yoga'                       => 'This domain name has not been registered',
    'whois.ax'                             => 'Domain not found',
    'whois.cctld.by'                       => 'Object does not exist',
    'whois.mediaserv.net'                  => 'NO OBJECT FOUND!',
    'whois.nic.amsterdam'                  => 'Domain Status: free',
    'whois.nic.arab'                       => 'No Data Found',
    'whois.nic.audible'                    => 'This domain name has not been registered\.',
    'whois.nic.author'                     => 'This domain name has not been registered\.',
    'whois.nic.aws'                        => 'This domain name has not been registered\.',
    'whois.nic.bible'                      => 'No Data Found',
    'whois.nic.book'                       => 'This domain name has not been registered\.',
    'whois.nic.bot'                        => 'This domain name has not been registered\.',
    'whois.nic.call'                       => 'This domain name has not been registered\.',
    'whois.nic.catholic'                   => 'No Data Found',
    'whois.nic.charity'                    => 'Domain not found\.',
    'whois.nic.circle'                     => 'This domain name has not been registered\.',
    'whois.nic.cpa'                        => 'No Data Found',
    'whois.nic.data'                       => 'NOT FOUND',
    'whois.nic.deal'                       => 'This domain name has not been registered\.',
    'whois.nic.dnp'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.do'                         => 'Domain Status: No Object Found',
    'whois.nic.fast'                       => 'This domain name has not been registered\.',
    'whois.nic.fire'                       => 'This domain name has not been registered\.',
    'whois.nic.fox'                        => 'No Data Found',
    'whois.nic.free'                       => 'This domain name has not been registered\.',
    'whois.nic.gay'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.ge'                         => 'No match for "',
    'whois.nic.got'                        => 'This domain name has not been registered\.',
    'whois.nic.hot'                        => 'This domain name has not been registered\.',
    'whois.nic.imdb'                       => 'This domain name has not been registered\.',
    'whois.nic.inc'                        => 'is available for registration',
    'whois.nic.jot'                        => 'This domain name has not been registered\.',
    'whois.nic.joy'                        => 'This domain name has not been registered\.',
    'whois.nic.kindle'                     => 'This domain name has not been registered\.',
    'whois.nic.like'                       => 'This domain name has not been registered\.',
    'whois.nic.ls'                         => 'no entries found',
    'whois.nic.mobile'                     => 'NOT FOUND',
    'whois.nic.moi'                        => 'This domain name has not been registered\.',
    'whois.nic.mr'                         => 'Domain Status: No Object Found',
    'whois.nic.mw'                         => 'no entries found',
    'whois.nic.nhk'                        => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.now'                        => 'This domain name has not been registered\.',
    'whois.nic.okinawa'                    => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.otsuka'                     => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.pay'                        => 'This domain name has not been registered\.',
    'whois.nic.pharmacy'                   => 'No Data Found',
    'whois.nic.phone'                      => 'NOT FOUND',
    'whois.nic.pin'                        => 'This domain name has not been registered\.',
    'whois.nic.prime'                      => 'This domain name has not been registered\.',
    'whois.nic.read'                       => 'This domain name has not been registered\.',
    'whois.nic.rmit'                       => 'No Data Found',
    'whois.nic.room'                       => 'This domain name has not been registered\.',
    'whois.nic.rugby'                      => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.ryukyu'                     => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.safe'                       => 'This domain name has not been registered\.',
    'whois.nic.safety'                     => 'No Data Found',
    'whois.nic.save'                       => 'This domain name has not been registered\.',
    'whois.nic.secure'                     => 'This domain name has not been registered\.',
    'whois.nic.silk'                       => 'This domain name has not been registered\.',
    'whois.nic.smile'                      => 'This domain name has not been registered\.',
    'whois.nic.sport'                      => 'The queried object does not exist: no matching objects found',
    'whois.nic.spot'                       => 'This domain name has not been registered\.',
    'whois.nic.ss'                         => 'Domain Status: No Object Found',
    'whois.nic.suzuki'                     => 'The queried object does not exist: DOMAIN NOT FOUND',
    'whois.nic.talk'                       => 'This domain name has not been registered\.',
    'whois.nic.td'                         => 'Domain Status: No Object Found',
    'whois.nic.tunes'                      => 'This domain name has not been registered\.',
    'whois.nic.tushu'                      => 'This domain name has not been registered\.',
    'whois.nic.unicom'                     => 'The queried object does not exist',
    'whois.nic.wanggou'                    => 'This domain name has not been registered\.',
    'whois.nic.wow'                        => 'This domain name has not been registered\.',
    'whois.nic.xn--80aqecdr1a'             => 'No Data Found',
    'whois.nic.xn--8y0a063a'               => 'The queried object does not exist',
    'whois.nic.xn--mgbab2bd'               => 'The queried object does not exist: no matching objects found',
    'whois.nic.xn--mgbi4ecexp'             => 'No Data Found',
    'whois.nic.xn--ngbrx'                  => 'No Data Found',
    'whois.nic.xn--tiq49xqyj'              => 'No Data Found',
    'whois.nic.yamaxun'                    => 'This domain name has not been registered\.',
    'whois.nic.you'                        => 'This domain name has not been registered\.',
    'whois.nic.zappos'                     => 'This domain name has not been registered\.',
    'whois.registry.in'                    => 'No Data Found',
    'whois.nic.cyou'                       => 'DOMAIN NOT FOUND',
    'whois.nic.box'                        => 'No Data Found',
    'whois.nic.epson'                      => 'No Data Found',
    'whois.nic.iinet'                      => 'No Data Found',
    'whois.nic.krd'                        => 'No Data Found',
    'whois.nic.melbourne'                  => 'No Data Found',
    'whois.nic.saxo'                       => 'No Data Found',
);

# Common whois stripping REs
our @strip_regexps = (
    qr{
        ^ (?:
            \W* Last \s update \s of \s WHOIS \s database
            | Database \s last \s updated
            | \W* Whois \s database \s was \s last \s updated \s on
        )
        \b .+ \z
    }xmsi,
);

our %strip = (
    'whois.arin.net' => [
        '^The ARIN Registration Services Host contains',
        '^Network Information:.*Networks',
        '^Please use the whois server at',
        '^Information and .* for .* Information.',
    ],
    'whois.ripe.net' => [
        '^%',
    ],

    'whois.nic.berlin' => [
        '^%',
    ],
    'whois.nic.wien' => [
        '^%',
    ],

    'whois-dub.mm-registry.com' => [
        '^[^A-Z]',
        '^TERMS OF USE',
    ],

    'whois.ripn.net' => [
        '^%',
        'Last updated on ',
    ],

    'whois.registry.ripn.net' => [
        '^%',
        'Last updated on ',
    ],

    'whois.publicinterestregistry.net' => [
        '^[^A-Z]',
        '^Access to Public Interest Registry',
    ],

    'whois.aero' => [
        '^Access to \.AERO WHOIS',
        '^determining the contents',
        '^Afilias registry database',
        '^Afilias Limited for informational',
        '^guarantee its accuracy',
        '^access\. You agree that',
        '^and that, under no',
        '^enable, or otherwise support',
        '^facsimile of mass unsolicited',
        '^to entities other than the',
        '^\(b\) enable high volume',
        '^queries or data to the systems',
        '^Afilias except as reasonably',
        '^modify existing registrations',
        '^the right to modify these terms',
        '^you agree to abide by this policy',
        '^Name Server: $',
    ],
    'whois.nic.asia' => [
        '^DotAsia WHOIS LEGAL STATEMENT AND',
        '^by DotAsia and the access to',
        '^for information purposes only',
        '^domain name is still available',
        '^the registration records of',
        '^circumstances, be held liable',
        '^be wrong, incomplete, or not',
        '^you agree not to use the',
        '^otherwise support the transmission',
        '^other solicitations whether via',
        '^possible way; or to cause nuisance',
        '^sending \(whether by automated',
        '^volumes or other possible means',
        '^above, it is explicitly forbidden',
        '^in any form and by any means',
        '^quantitatively or qualitatively',
        '^database without prior and explicit',
        '^hereof, or to apply automated',
        '^You agree that any reproduction',
        '^purposes will always be considered',
        '^the content of the WHOIS database',
        '^by this policy and accept that',
        '^WHOIS services in order to protect',
        '^integrity of the database',
        '^Nameservers: $',
    ],
    'whois.biz' => [
        '^>>>> Whois database was last updated',
        '^NeuLevel, Inc\., the Registry',
        '^for the WHOIS database through',
        '^is provided to you for',
        '^persons in determining contents',
        '^NeuLevel registry database',
        '^"as is" and does not guarantee',
        '^agree that you will use this',
        '^circumstances will you use',
        '^support the transmission of',
        '^solicitations via direct mail',
        '^contravention of any applicable',
        '^enable high volume, automated',
        '^\(or its systems\)\. Compilation',
        '^WHOIS database in its entirety',
        '^allowed without NeuLevel',
        '^right to modify or change these',
        '^subsequent notification of any kind',
        '^whatsoever, you agree to abide by',
        '^NOTE\: FAILURE TO LOCATE A RECORD',
        '^OF THE AVAILABILITY OF A DOMAIN NAME',
        '^NeuStar, Inc\., the Registry',
        '^NeuStar registry database',
        '^allowed without NeuStar',
    ],
    'whois-tel.neustar.biz' => [ # .tel
        '^>>>> Whois database was last updated',
        'Telnic, Ltd., the Registry Operator',
        'for the WHOIS database through an',
        'is provided to you for informational',
        'persons in determining contents of a',
        'Telnic registry database. Telnic makes',
        '"as is" and does not guarantee its',
        'agree that you will use this data',
        'circumstances will you use this data',
        'support the transmission of mass',
        'solicitations via direct mail,',
        'contravention of any applicable',
        'enable high volume, automated,',
        '\(or its systems\). Compilation,',
        'WHOIS database in its entirety,',
        'allowed without Telnic\'s prior',
        'right to modify or change these',
        'subsequent notification of any',
        'whatsoever, you agree to abide',
        'Contact information: Disclosure',
        'of UK and EU Data Protection',
        'contact ID may be available by',
        'system. The information can also',
        'Special Access Service. Visit',
        '.TEL WHOIS DISCLAIMER AND TERMS',
        'By submitting a query and/or',
        'agree to these terms and',
        'This whois information is',
        'Telnic operates the Registry',
        'is provided for information',
        'and shall have no liability',
        'inaccurate.',
        'Telnic is the owner of all',
        'that is made available via this',
        'the information you obtain from',
        'than to obtain information about',
        'for registration or to obtain the',
        'of a domain name that is already',
        'utilise, combine or compile any',
        'to produce a list or database',
        'a license from Telnic to do so.',
        'reason, you will destroy all',
        'using this whois service.',
        'You must not use the information',
        'to: \(a\) allow, enable or otherwise',
        'unsolicited commercial advertising',
        '\(b\) harass any person; or',
    ],
    'whois.cat' => [
        '^%',
    ],
    'ccwhois.verisign-grs.com' => [ # .CC
        '^>>> Last update of',
        '^NOTICE\: The expiration date',
        'sponsorship of the domain name',
        '^currently set to expire',
        '^expiration date of the',
        '^sponsoring registrar\.  Users',
        '^Whois database to view the',
        '^for this registration',
        '^TERMS OF USE\: You are',
        '^database through the use',
        '^automated except as reasonably',
        '^modify existing registrations',
        '^database is provided by',
        '^assist persons in obtaining',
        '^registration record\. VeriSign does',
        '^By submitting a Whois query',
        '^use\: You agree that you may use',
        '^under no circumstances will you',
        '^otherwise support the transmission',
        '^advertising or solicitations via',
        '^\(2\) enable high volume, automated',
        '^VeriSign \(or its computer systems\)',
        '^dissemination or other use of this',
        '^the prior written consent of',
        '^processes that are automated and',
        '^Whois database except as reasonably',
        '^or modify existing registrations',
        '^your access to the Whois database',
        '^operational stability\.  VeriSign',
        '^Whois database for failure to',
        '^reserves the right to modify',
        '^The Registry database contains',
        '^and Registrars\.',
    ],
    'whois.networksolutions.com' => [ # for .net
        '^NOTICE AND TERMS OF USE',
        '^database through the use',
        '^Data in Network Solutions',
        '^purposes only, and to assist',
        '^to a domain name registration',
        '^By submitting a WHOIS query',
        '^You agree that you may use',
        '^circumstances will you use',
        '^the transmission of mass',
        '^via e-mail, telephone, or',
        '^electronic processes that',
        '^compilation, repackaging',
        '^prohibited without the',
        '^high-volume, automated',
        '^database\. Network Solutions',
        '^database in its sole discretion',
        '^querying of the WHOIS database',
        '^Network Solutions reserves',
        '^Get a FREE domain name',
        '^http\:\/\/www\.network',
        '^Visit AboutUs\.org for',
        '^<a href=\"http',
        '-----------',
        'Promote your business',
        'Learn how you can',
        'Learn more at http',
    ],
    'whois.educause.edu' => [
        '^This Registry database',
        '^The data in the EDUCAUSE',
        '^by EDUCAUSE for information',
        '^assist in the process',
        '^or related to \.edu domain',
        '^The EDUCAUSE Whois database',
        '^\.EDU domain\.',
        '^A Web interface for the \.EDU',
        '^available at\: http',
        '^By submitting a Whois query',
        '^will not be used to allow',
        '^the transmission of unsolicited',
        '^solicitations via e-mail',
        '^harvest information from this',
        '^except as reasonably necessary',
        '^domain names\.',
        '^You may use \"%\" as a',
        '^information regarding the use',
        '^type\: help',
    ],
    'whois.dotgov.gov' => [
        '^% DOTGOV WHOIS Server ready',
        '^Please be advised that this whois server only',
        'No match for',
    ],
    'whois.nic.mil' => [
        '^To single out one record',
        '^handle, shown in parenthesis',
        '^Please be advised that this whois',
        '^All INTERNET Domain, IP Network Number,',
        '^the Internet Registry, RS.INTERNIC.NET.',
    ],
    'whois.dotmobiregistry.net' => [ # .mobi
        '^mTLD WHOIS LEGAL STATEMENT',
        '^by mTLD and the access to',
        '^for information purposes only.',
        '^domain name is still available',
        '^the registration records of',
        '^circumstances, be held liable',
        '^be wrong, incomplete, or not',
        '^you agree not to use the information',
        '^otherwise support the transmission',
        '^other solicitations whether via',
        '^possible way; or to cause',
        '^sending \(whether by automated,',
        '^volumes or other possible means\)',
        '^above, it is explicitly forbidden',
        '^in any form and by any means',
        '^quantitatively or qualitatively',
        '^database without prior and explicit',
        '^hereof, or to apply automated,',
        '^You agree that any reproduction',
        '^purposes will always be considered',
        '^the content of the WHOIS database.',
        '^by this policy and accept that mTLD',
        '^WHOIS services in order to protect',
        '^integrity of the database.',
        '^For more information on Whois',
    ],
    'whois.museum' => [
        '^%',
    ],
    'whois.nic.name' => [
        '^Disclaimer: VeriSign, Inc',
        '^completeness and accuracy of',
        '^that the results are error-free',
        '^through the Whois service are on',
        '^warranties',
        '^BY USING THE WHOIS SERVICE AND',
        '^HEREIN OR IN ANY REPORT GENERATED',
        '^ACCEPTED THAT VERISIGN, INC',
        '^ANY DAMAGES OF ANY KIND ARISING',
        '^REPORT OR THE INFORMATION PROVIDED',
        '^OMISSIONS OR MISSING INFORMATION',
        '^INFORMATION PROVIDED BY THE WHOIS',
        '^CONTEMPLATION OF LEGAL PROCEEDINGS',
        '^DO SUCH RESULTS CONSTITUTE A LEGAL OPINION',
        '^results of the Whois constitutes',
        '^conditions and limitations',
        '^lawful purposes, in particular',
        '^obligations',
        '^limited to, unsolicited email',
        '^other improper purpose',
        '^documented by VeriSign, Inc',
        '^\s+\*\*\*',
        '^For more information on Whois',
        '^https\:',
    ],
    'whois.afilias.net' => [
        '^Access to AFILIAS WHOIS',
        '^[^A-Z]',
        '^Name Server: $',
    ],
    'whois.nic.me' => [
        '^WHOIS TERMS & CONDITIONS',
        '^assist persons in determining',
        '^record in the \.ME registry',
        '^\.ME Registry for',
        '^guarantee its accuracy',
        '^access\. You agree that',
        '^and that, under no circumstances',
        '^enable, or otherwise',
        '^facsimile, or other',
        '^advertising or solicitations',
        '^existing customers',
        '^processes that send',
        '^except as reasonably necessary',
        '^registrations\. All rights',
        '^these terms at any time',
        '^policy\.',
    ],
    'whois.nic.club' => [
        '>>>> Whois database was last updated [\s\w]+',
    ],
    'whois.nic.luxury' => [
        '>>> Last update of WHOIS',
        '^This is the future of Luxury',
    ],
    'whois.crsnic.net' => [ # .com  main .net
        '^TERMS OF USE:',
        '^database through',
        '^automated except',
        '^modify existing',
        '^Services\' \(\"VeriSign\"\)',
        '^information purposes only',
        '^about or related to a',
        '^guarantee its accuracy\.',
        '^by the following terms',
        '^for lawful purposes and',
        '^to: (1) allow, enable,',
        '^unsolicited, commercial',
        '^or facsimile; or \(2\)',
        '^that apply to VeriSign',
        '^repackaging, dissemination',
        '^prohibited without the',
        '^use electronic processes',
        '^query the Whois database',
        '^domain names or modify',
        '^to restrict your access',
        '^operational stability\.',
        '^Whois database for',
        '^reserves the right',

        '^NOTICE AND TERMS OF USE:',
        '^Data in Network Solutions',
        '^purposes only, and to assist',
        '^to a domain name registration',
        '^By submitting a WHOIS query,',
        '^You agree that you may use',
        '^circumstances will you use',
        '^the transmission of mass',
        '^via e-mail, telephone, or',
        '^electronic processes that',
        '^compilation, repackaging,',
        '^high-volume, automated,',
        '^database. Network Solutions',
        '^database in its sole discretion,',
        '^querying of the WHOIS database',
        '^Network Solutions reserves the',

        '^NOTICE: The expiration date',
        '^registrar\'s sponsorship of',
        '^currently set to expire\.',
        '^date of the domain name',
        '^registrar.  Users may',
        '^view the registrar\'s',
        '^to: \(1\) allow, enable,',
        '^The Registry database',
        '^Registrars\.',
        '^Domain not found locally,',
        '^Local WHOIS DB must be out',

        '^Whois Server Version',
        '^Domain names in the .com',
        '^with many different',
        '^for detailed information\.',

        '^>>> Last update of whois database',
    ],
    'whois.iana.org' => [
        '^q',
    ],
    'whois.pir.org' => [
        '^Access to Public Interest Registry',
        '^cord is provided by Public Interest Registry',
        '^use this data only for lawful purposes and that',
        '^al advertising or solicitations',
        '^or, a Registrar, or Afilias except',
        '^By submitting this query',
    ],
    'whois.registrypro.pro' => [
        '^Whois data provided by RegistryPro',
        '^RegistryPro Whois Terms of Use',
        '^Access to RegistryPro',
        '^is strictly limited to',
        '^guarantee the accuracy',
        '^only for lawful purposes',
        '^data to\: \(a\) allow, enable',
        '^telephone, or facsimile of',
        '^solicitations to entities',
        '^customer; or \(b\) enable',
        '^send queries or data to the',
        '^Operator or any ICANN-accredited',
        '^to register domain  names  or',
        '^reserves the right to modify',
        '^discretion\. Failure to adhere to',
        '^restriction or termination of',
        '^By submitting this query, you',
        '^All rights reserved\.  RegistryPro',
    ],
    'jobswhois.verisign-grs.com' => [ # .JOBS
        '^>>> Last update of',
        '^NOTICE\: The expiration date',
        'sponsorship of the domain name',
        '^currently set to expire',
        '^expiration date of the',
        '^sponsoring registrar\.  Users',
        '^Whois database to view the',
        '^for this registration',
        '^TERMS OF USE\: You are',
        '^database through the use',
        '^automated except as reasonably',
        '^modify existing registrations',
        '^database is provided by',
        '^assist persons in obtaining',
        '^registration record\. VeriSign does',
        '^By submitting a Whois query',
        '^use\: You agree that you may use',
        '^under no circumstances will you',
        '^otherwise support the transmission',
        '^advertising or solicitations via',
        '^\(2\) enable high volume, automated',
        '^VeriSign \(or its computer systems\)',
        '^dissemination or other use of this',
        '^the prior written consent of',
        '^processes that are automated and',
        '^Whois database except as reasonably',
        '^or modify existing registrations',
        '^your access to the Whois database',
        '^operational stability\.  VeriSign',
        '^Whois database for failure to',
        '^reserves the right to modify',
        '^The Registry database contains',
        '^and Registrars\.',
    ],
    'tvwhois.verisign-grs.com' => [ # .TV
        '^>>> Last update of',
        '^NOTICE\: The expiration date',
        'sponsorship of the domain name',
        '^currently set to expire',
        '^expiration date of the',
        '^sponsoring registrar\.  Users',
        '^Whois database to view the',
        '^for this registration',
        '^TERMS OF USE\: You are',
        '^database through the use',
        '^automated except as reasonably',
        '^modify existing registrations',
        '^database is provided by',
        '^assist persons in obtaining',
        '^registration record\. VeriSign does',
        '^By submitting a Whois query',
        '^use\: You agree that you may use',
        '^under no circumstances will you',
        '^otherwise support the transmission',
        '^advertising or solicitations via',
        '^\(2\) enable high volume, automated',
        '^VeriSign \(or its computer systems\)',
        '^dissemination or other use of this',
        '^the prior written consent of',
        '^processes that are automated and',
        '^Whois database except as reasonably',
        '^or modify existing registrations',
        '^your access to the Whois database',
        '^operational stability\.  VeriSign',
        '^Whois database for failure to',
        '^reserves the right to modify',
        '^The Registry database contains',
        '^and Registrars\.',
    ],
    'whois.enom.com' => [ # .TV .CC
        '^=-=-=-=',
        '^Visit AboutUs.org for more',
        '^<a href="',
        '^Registration Service Provided By',
        '^Contact\: \S+@',
        '^Visit\: http\:\/\/qdc\.nl',
        '^Get Noticed on the Internet',
        '^The data in this whois database is provided',
        '^purposes only, that is, to assist you in',
        '^related to a domain name registration record.',
        '^available "as is," and do not guarantee its',
        '^whois query, you agree that you will use this',
        '^purposes and that, under no circumstances will',
        '^enable high volume, automated, electronic',
        '^this whois database system providing you this',
        '^enable, or otherwise support the transmission',
        '^commercial advertising or solicitations via',
        '^mail, or by telephone. The compilation,',
        '^other use of this data is expressly',
        '^consent from us.',
        '^We reserve the right to modify these',
        '^this query, you agree to abide by these',
        '^Version ',
    ],
    'whois.worldsite.ws' => [
        '^Welcome to the .* Whois Server',
        '^Use of this service for any',
        '^than determining the',
        '^in the .* to be registered',
        '^prohibited.',
    ],

    'whois.nic.pw' => [
        '^This whois service',
        '^[^A-Z]',
        '^\s+$',
    ],

    'whois.nic.ag' => [
        '^Access to CCTLD WHOIS',
        '^determining the contents',
        '^Afilias registry database',
        '^Afilias Limited for',
        '^guarantee its accuracy',
        '^access\. You agree that',
        '^and that, under no',
        '^enable, or otherwise',
        '^facsimile of mass',
        '^to entities other than',
        '^\(b\) enable high volume',
        '^queries or data to the',
        '^Afilias except as reasonably',
        '^modify existing registrations',
        '^the right to modify these',
        '^you agree to abide by this',
        '^Name Server: $',
    ],
    'whois.nic.at' => [
        '^%',
    ],
    'whois.aunic.net' => [ # .au
        '^%',
    ],
    'whois.dns.be' => [
        'Status:\s+AVAILABLE',
    ],
    'whois.registro.br' => [
        '^%',
    ],
    'whois.cira.ca' => [
        '^%',
    ],
    'whois.nic.ch' => [
        '^whois: This information is subject',
        '^See http',
    ],
    'whois.nic.ci' => [
        '^All rights reserved',
        '^Copyright \"Generic NIC',
    ],
    'whois.nic.cl' => [
        '^ACE\:',
        '^Ъltima modificaciуn',
        '\(Database last updated on\)',
        '^Mбs informaciуn',
        'www\.nic\.cl\/cgi-bin',
        '^Este mensajes estб impreso',
        '^\(This message is printed',
        '^\s+\(\)$',
    ],
    'whois.nic.cx' => [
        '^TERMS OF USE\: You are not',
        '^CiiA makes every effort to maintain the completeness',
        'CiiA, All rights reserved',
        '^Domain Information$',
    ],
    'whois.nic.cz' => [
        '^%',
    ],
    'whois.denic.de' => [
        '^%',
    ],
    'whois.nic.dm' => [
        '^TERMS OF USE\: You are not',
        '^database through the use',
        '^automated\.  Whois database',
        '^community on behalf of',
        '^The data is for information',
        '^guarantee its accuracy',
        '^by the following terms of',
        '^for lawful purposes and that',
        '^to\: \(1\) allow, enable',
        '^unsolicited, commercial',
        '^or facsimile; or \(2',
        '^that apply to CoCCA it',
        '^compilation, repackaging,',
        '^expressly prohibited\.',
        '^CoCCA Helpdesk',
        '^Domain Information$',
    ],
    'whois.eenet.ee' => [
        '^The registry database contains',
        '^\.ORG\.EE and \.MED\.EE domains',
        '^Registrar\: EENET',
        '^URL\: http',
    ],
    'whois.dk-hostmaster.dk' => [
        '^#',
    ],
    'whois.eu' => [
        '^%',
    ],
    'whois.ficora.fi' => [
        '^More information is available',
        '^Copyright \(c\) Finnish',
    ],
    'whois.nic.fr' => [
        '^%%',
    ],
    'whois.channelisles.net' => [ # .GG .JE
        '^status\:',
        '^The CHANNELISLES.NET',
        '^for domains registered',
        '^The WHOIS facility is',
        '^basis only\. Island Networks',
        '^or otherwise of information',
        '^the WHOIS, you accept this',
        '^Please also note that some',
        '^unavailable for registration',
        '^for a number of reasons',
        '^Other names for',
        '^nonetheless be unavailable',
        '^WHOIS database copyright',
    ],
    'whois.hkirc.hk' => [
        '^Whois server',
        '^Domain names in the',
        '^and .* can now be registered',
        '^Go to http://www.hkdnr.net.hk',
        '^---------',
        '^The Registry contains ONLY',
        '^.* and .*\\.HK domains.',
    ],
    'whois2.afilias-grs.net' => [ # .GI .HN .LC .SC .VC
        '^Access to CCTLD WHOIS',
        '^determining the contents',
        '^Afilias registry database',
        '^Afilias Limited for',
        '^guarantee its accuracy',
        '^access\. You agree that',
        '^and that, under no',
        '^enable, or otherwise',
        '^facsimile of mass unsolicited',
        '^to entities other than',
        '^\(b\) enable high volume',
        '^queries or data to the',
        '^Afilias except as reasonably',
        '^modify existing registrations',
        '^the right to modify these',
        '^you agree to abide by this policy',
        '^Name Server: $',
    ],
    'whois.nic.gs' => [
        '^TERMS OF USE\: You are not',
        '^database through the use',
        '^automated\.  Whois database',
        '^community on behalf of CoCCA',
        '^The data is for information',
        '^guarantee its accuracy',
        '^by the following terms',
        '^for lawful purposes and',
        '^to\: \(1\) allow, enable',
        '^unsolicited, commercial',
        '^or facsimile; or \(2\) enable',
        '^that apply to CoCCA it',
        '^compilation, repackaging',
        '^expressly prohibited',
        '^CoCCA Helpdesk',
        '^Domain Information$',
    ],
    'whois.hkirc.hk' => [
        '----------------',
        '^ Whois server by HKDNR',
        '^ Domain names in the \.com\.hk',
        '^ \.gov\.hk, idv\.hk\. and',
        '^ Go to http',
        '^ The Registry contains ONLY',
        '^WHOIS Terms of Use',
        '^By using this WHOIS',
        '^The data in HKDNR',
        '^You are not authorised to',
        '^You agree that you will',
        '^a\.    use the data for',
        '^b\.    enable high volume',
        '^c\.    without the prior',
        '^d\.    use such data',
        '^HKDNR in its sole discretion',
        '^HKDNR may modify these',
        '^Company Chinese name', # What is Code Page?
    ],
    'whois.nic.hu' => [
        '% Whois server',
        '^Rights restricted by',
        'Legal usage of this',
        '^abide by the rules',
        '^http\:',
        'A szolgaltatas csak a',
        '^elйrhetх feltйtelek',
        '^hasznбlhatу legбlisan',
    ],
    'whois.domainregistry.ie' => [
        '^%',
    ],
    'whois.isoc.org.il' => [
        '^%',
    ],
    'whois.registry.in' => [ # .IN
        '^Access to \.IN WHOIS',
        '^determining the contents',
        '^\.IN registry database',
        '^\.IN Registry for informational',
        '^guarantee its accuracy',
        '^access\. You agree',
        '^and that, under no',
        '^enable, or otherwise',
        '^facsimile of mass unsolicited',
        '^to entities other than',
        '^\(b\) enable high volume',
        '^queries or data to the',
        '^Afilias except as reasonably',
        '^modify existing registrations',
        '^the right to modify these',
        '^you agree to abide by this',
        '^Name Server: $',
    ],
    'whois.isnic.is' => [
        '^%',
    ],
    'whois.nic.it' => [
        '^\*',
    ],
    'whois.jprs.jp' => [
        '^\[\s',
    ],
    'whois.kenic.or.ke' => [
        '^%',
        '^remarks\:',
    ],
    'whois.nic.or.kr' => [
        '^іЧАУј­№ц АМё§АМ .krАМ ѕЖґС °жїмґ',
    ],
    'whois.nic.kz' => [
        '^Whois Server for the KZ',
        '^This server is maintained',
    ],
    'whois.nic.li' => [
        '^whois\: This information',
        '^See http',
    ],
    'whois.domreg.lt' => [
        '^%',
    ],
    'whois.dns.lu' => [
        '^%',
    ],
    'whois.nic.lv' => [
        '^%',
    ],
    'whois.nic.ms' => [
        '^TERMS OF USE\: You are not',
        '^database through the use',
        '^automated\.',
        '^The data is for information',
        '^guarantee its accuracy',
        '^by the following terms of',
        '^for lawful purposes and',
        '^to\: \(1\) allow, enable',
        '^unsolicited, commercial',
        '^or facsimile; or \(2\) enable',
        '^expressly prohibited',
        '^Domain Information$'
    ],
    'whois.nic.mu' => [
        '^TERMS OF USE\: You are not',
        '^Internet Direct Ltd makes every effort to maintain the completeness',
        'Internet Direct Ltd, All rights reserved',
        '^Domain Information$',
    ],
    'whois.nic.mx' => [
        '^La informacion que ha',
        '^relacionados con la delegacion',
        '^administrado por NIC Mexico',
        '^Queda absolutamente prohibido',
        '^de Correos Electronicos no',
        '^de productos y servicios',
        '^de NIC Mexico\.',
        '^La base de datos generada',
        '^por las leyes de Propiedad',
        '^sobre la materia\.',
        '^Si necesita mayor informacion',
        '^comunicarse a ayuda@nic',
        '^Si desea notificar sobre correo',
        '^de enviar su mensaje a abuse',
    ],
    'whois.mynic.my' => [
        '^Welcome to \.my DOMAIN',
        '----------',
        'For alternative search',
        'whois -h whois\.domainregistry\.my',
        'Type the command as below',
        'Note\: Code is previously',
        'Please note that the query limit is 500 per day from the same IP', # !!!
        'SEARCH BY DOMAIN NAME',
        '^Disclaimer',
        '^MYNIC, the Registry for',
        '^database through a MYNIC-Accredited',
        '^you for informational purposes',
        '^determining contents of a',
        '^database\.',
        '^MYNIC makes this information',
        '^its accuracy\.',
        '^By submitting a WHOIS query',
        '^lawful purposes and that',
        '^\(1\) to allow, enable, or',
        'commercial advertising or',
        '^\(2\) for spamming or',
        '^\(3\) to enable high volume',
        'registry \(or its systems\) or',
        '^\(4\) for any other abusive purpose',
        '^Compilation, repackaging',
        '^its entirety, or of a substantial',
        "^MYNIC's prior written permission",
        '^these conditions at any time',
        '^kind\. By executing this query',
        '^these terms\.',
        '^NOTE\: FAILURE TO LOCATE',
        '^AVAILABILITY OF A DOMAIN NAME',
        '^All domain names are subject to',
        '^Registration of Domain Name',
        '^For details, please visit',
    ],
    'whois.na-nic.com.na' => [
        '^TERMS OF USE\: You are not',
        '^the use of electronic',
        '^WHOIS is NA-NiC',
        '^internet  community\. The',
        '^its  accuracy\.  By submitting',
        '^lawful purposes and',
        '^enable, or otherwise support',
        '^advertising or solicitations',
        '^automated, electronic processes',
        '^member computer systems\). The',
        '^this Data is expressly prohibited',
        '^Copyright 1991, 1995 Dr Lisse',
        '^Domain Information$',
    ],
    'whois.domain-registry.nl' => [
        'Record maintained by',
        'Copyright notice',
        'No part of this publication',
        'retrieval system, or',
        'mechanical, recording, or',
        'Foundation for Internet',
        'Registrars are bound by',
        'except in case of reasonable',
        'and solely for those business',
        'terms and Conditions for',
        'Any use of this material',
        'similar activities is',
        'Stichting Internet',
        'of any such activities or',
        'Copyright \(c\) The',
        'Netherlands \(SIDN\)',

        '^These restrictions apply equally',
        '^reproductions and publications',
        '^reasonable, necessary and solely',
        '^activities referred to in the',
        '^Registrars',
        '^action. Anyone who is aware',
        '^in the Netherlands',
        '^\(SIDN\) Dutch Copyright Act',
        '^subsection 1, clause 1\).',

    ],
    'whois.norid.no' => [
        '^%',
    ],
    'whois.nic.nu' => [
        '------------',
        '^\.NU Domain Ltd',
        '^Owner and Administrative Contact information for',
        '^registered in \.nu is',
        '^Copyright by \.NU Domain',
        '^Database last updated',
    ],
    'whois.srs.net.nz' => [
        '^%',
    ],
    'whois.dns.pl' => [
        '^no option',
        '^WHOIS displays data with a',
        '^Registrant data available at',
    ],
    'whois.nic.pm' => [
        '^%%',
    ],
    'whois.nic.pr' => [
        '^Whois Disclaimer',
        '^The data in nic\.pr',
        '^purposes only, that is to',
        '^a domain name registration',
        '^and does not guarantee its',
        '^will use this data only for',
        '^you use this data to',
        '^mass unsolicited, commercial',
        '^mail, including spam or by',
        '^processes or robotic',
        '^purposes that apply to nic',
        '^nation or other use of this',
        '^consent of nic\.pr\. Nic',
        '^mitting this query, you',
    ],
    'whois.nic.re' => [
        '^%%',
    ],
    'whois.rotld.ro' => [
        '^%',
    ],
    'whois.iis.se' => [
        '^#',
    ],
    'whois.nic.net.sg' => [
        '----------',
        'SGNIC WHOIS Server',
        '^The following data is',
        '^Registrant\:',
        '^Note\: With immediate effect',
        '^Contact will not be shown',
        '^Technical Contact details',
        '^Any party who has',
        '^contacts from the domain',
        '^using the organization',
    ],
    'whois.nic.sh' => [
        '^NIC Whois Server',
    ],
    'whois.arnes.si' => [
        '^%',
    ],
    'whois.nic.st' => [
        '^The data in the .* database is provided',
        '^The .* Registry does not guarantee',
        '^The data in the .* database is protected',
        '^By submitting a .* query, you agree that you will',
        '^The Domain Council of .* reserves the right',
    ],
    'whois.nic.tf' => [
        '^%%',
    ],
    'whois.dot.tk' => [
        'Rights restricted by',
        'http\:\/\/www\.dot\.tk',
        'Your selected domain name',
        'cancelled, suspended, refused',
        'It may be available for',
        'In the interim, the rights',
        'transferred to Malo Ni',
        'Please be advised that',
        'Malo Ni Advertising',
        'that was previously',
        'Please review http',
        'Due to restrictions in',
        'about the previous',
        'to the general public',
        'Dot TK is proud to work',
        'agencies to stop spam',
        'other illicit content on',
        'Dot TK Registry directly',
        'usage of this domain by',
        'Record maintained by',
    ],
    'whois.tonic.to' => [
        '^Tonic whoisd',
    ],
    'whois.twnic.net.tw' => [
        '^Registrar:',
        '^URL: http://rs.twnic.net.tw',
    ],
    'whois.net.ua' => [
        '^% This is the Ukrainian',
        '^% Rights restricted by',
        '^%$',
        '^% % \.UA whois',
        '^% ========',
        '% The object shown',
        '% It has been obtained',
        '^% \(whois\.',
        '^%$',
        '^% REDIRECT BEGIN',
        '^% REDIRECT END',
    ],
    'whois.dn.ua' => [
        '^%',
    ],
    'whois.lg.ua' => [
        '^%',
    ],
    'whois.od.ua' => [
        '^%',
    ],
    'whois.com.ua' => [
        '^% This is the Ukrainian',
        '^% Rights restricted',
        '^%$',
        '^% % .UA whois',
        '^% =====',
    ],
    'whois.nic.uk' => [
        '^This WHOIS information is',
        '^for \.uk domain names',
        'Copyright Nominet UK 1996 - 2009',
        '^You may not access the',
        '^by the terms of use available',
        '^includes restrictions on',
        '^repackaging, recompilation',
        '^or hiding any or all of this',
        '^limits\. The data is provided',
        '^register\. Access may be withdrawn',
        'WHOIS lookup made at',
        '^--',
    ],
    'whois.nic.us' => [
        '^>>>> Whois database was last',
        '^NeuStar, Inc\., the Registry',
        '^information for the WHOIS',
        '^This information is provided',
        '^designed to assist persons',
        '^registration record in the',
        '^information available to you',
        '^By submitting a WHOIS query',
        '^lawful purposes and that',
        '^\(1\) to allow, enable',
        '^unsolicited, commercial',
        '^electronic mail, or by telephone',
        '^data and privacy protection',
        '^electronic processes that',
        '^repackaging, dissemination',
        '^entirety, or of a substantial',
        'prior written permission',
        '^change these conditions at',
        '^of any kind\. By executing',
        '^abide by these terms',
        '^NOTE\: FAILURE TO LOCATE A',
        '^OF THE AVAILABILITY',
        '^All domain names are subject',
        '^rules\.  For details, please',
    ],
    'whois.nic.wf' => [
        '^%%',
    ],
    'whois.nic.yt' => [
        '^%%',
    ],



    'whois.ename.com' => [ # add .com .net .edu
        '^For more information, please go',
    ],
    'whois.ttpia.com' => [ # add .com .net .edu
        ' Welcome to TTpia.com',
        ' Tomorrow is From Today',
    ],
    'whois.directnic.com' => [
        '^By submitting a WHOIS query',
        '^lawful purposes\.  You also agree',
        '^this data to:',
        '^email, telephone,',
        '^or solicitations to',
        '^customers; or to \(b\) enable',
        '^that send queries or data to',
        '^ICANN-Accredited registrar\.',
        '^The compilation, repackaging,',
        '^data is expressly prohibited',
        '^directNIC.com\.',
        '^directNIC.com reserves the right',
        '^database in its sole discretion,',
        '^excessive querying of the database',
        '^this policy\.',
        '^directNIC reserves the right to',
        '^NOTE: THE WHOIS DATABASE IS A',
        '^LACK OF A DOMAIN RECORD DOES',
        '^Intercosmos Media Group, Inc',
        '^Registrar WHOIS database for',
        '^may only be used to assist in',
        '^registration record\.',
        '^directNIC makes this information',
        '^its accuracy\.',
    ],
    'whois.alldomains.com' => [
        '^MarkMonitor.com - ',
        '^------------------',
        '^For Global Domain ',
        '^and Enterprise DNS,',
        '^------------------',
        '^The Data in MarkMon',
        '^for information pur',
        '^about or related to',
        '^does not guarantee ',
        '^that you will use t',
        '^circumstances will ',
        '^support the transmi',
        '^solicitations via e',
        '^electronic processe',
        '^MarkMonitor.com res',
        '^By submitting this ',
    ],

    'whois.gdns.net' => [
        '^\\w+ Whois Server',
        '^Access to .* WHOIS information is provided to',
        '^determining the contents of a domain name',
        '^registrar database.  The data in',
        '^informational purposes only, and',
        '^Compilation, repackaging, dissemination,',
        '^in its entirety, or a substantial portion',
        'prior written permission.  By',
        '^by this policy.  All rights reserved.',
    ],
    'whois.worldnames.net' => [
        '^----------------------------------',
        '^.\\w+ Domain .* Whois service',
        '^Copyright by .* Domain LTD',
        '^----------------------------------',
        '^Database last updated',
    ],
    'whois.godaddy.com' => [
        '^The data contained in GoDaddy.com,',
        '^while believed by the company to be',
        '^with no guarantee or warranties',
        '^information is provided for the sole',
        '^in obtaining information about domain',
        '^Any use of this data for any other',
        '^permission of GoDaddy.com, Inc.',
        '^you agree to these terms of usage',
        '^you agree not to use this data to',
        '^dissemination or collection of this',
        '^purpose, such as the transmission of',
        '^and solicitations of any kind, including',
        '^not to use this data to enable high volume,',
        '^processes designed to collect or compile',
        '^including mining this data for your own',
        '^Please note: the registrant of the domain',
        '^in the "registrant" field.  In most cases,',
        '^is not the registrant of domain names listed',
    ],
    'whois.paycenter.com.cn' => [
        '^The Data in Paycenter\'s WHOIS database is',
        '^for information purposes, and to assist',
        '^information about or related to a domain',
        '^record\.',
        '^Paycenter does not guarantee its accuracy.',
        '^a WHOIS query, you agree that you will use',
        '^for lawful purposes and that, under no',
        '^you use this Data to:',
        '^\(1\) allow, enable, or otherwise support',
        '^of mass unsolicited, commercial',
        '^via e-mail \(spam\); or',
        '^\(2\) enable high volume, automated,',
        '^apply to Paycenter or its systems.',
        '^Paycenter reserves the right to modify',
        '^By submitting this query, you agree to',
    ],
    'whois.dotster.com' => [
        '^The information in this whois database is',
        '^purpose of assisting you in obtaining',
        '^name registration records. This information',
        '^and we do not guarantee its accuracy. By',
        '^query, you agree that you will use this',
        '^purposes and that, under no circumstances',
        '^to: \(1\) enable high volume, automated,',
        '^stress or load this whois database system',
        '^information; or \(2\) allow,enable, or',
        '^transmission of mass, unsolicited, commercial',
        '^solicitations via facsimile, electronic mail,',
        '^entitites other than your own existing customers.',
        '^compilation, repackaging, dissemination or other',
        '^is expressly prohibited without prior written',
        '^company. We reserve the right to modify these',
        '^time. By submitting an inquiry, you agree to',
        '^and limitations of warranty.  Please limit',
        '^minute and one connection.',
    ],
    'whois.nordnet.net' => [
        '^Serveur Whois version',
        '^\*\*\*\*\*\*\*\*\*',
        '^\* Base de Donnees des domaines COM, NET et ORG',
        '^\* enregistres par NORDNET.                    ',
        '^\* Ces informations sont affichees par le serve',
        '^\* Whois de NORDNET, le Registrar du           ',
        '^\* Groupe FRANCE-TELECOM                       ',
        '^\* Elles ne peuvent etre utilisees sans l accor',
        '^\* prealable de NORDNET.                       ',
        '^\*                                             ',
        '^\* Database of registration for COM, NET and   ',
        '^\* ORG by NORDNET.                             ',
        '^\* This informations is from NORDNET s Whois   ',
        '^\* Server, the Registrar for the               ',
        '^\* Group FRANCE-TELECOM.                       ',
        '^\* Use of this data is strictly prohibited with',
        '^\* out proper authorisation of NORDNET.',
        '^Deposez votre domaine sur le site http://www.nordnet.net',
        '^Copyright Nordnet Registrar',
    ],
    'whois.nsiregistry.net' => [
        '^Domain names in the \.com and',
        '^with many different competing',
        '^for detailed information',
        '^>>> Last update of whois database',
        '^NOTICE: The expiration date',
        "^registrar's sponsorship",
        '^currently set to expire',
        '^date of the domain name',
        '^registrar\.  Users may',
        '^view the registrar',
        '^TERMS OF USE: You are not',
        '^database through the use',
        '^automated except as reasonably',
        '^modify existing registrations',
        'is provided by VeriSign for $',
        '^information purposes only',
        '^about or related to a domain',
        '^guarantee its accuracy',
        '^by the following terms of',
        '^for lawful purposes and',
        '^to: \(1\) allow, enable',
        '^unsolicited, commercial',
        '^or facsimile; or \(2\) enable',
        '^that apply to VeriSign',
        '^repackaging, dissemination',
        '^prohibited without the prior',
        '^use electronic processes that',
        '^query the Whois database except',
        '^domain names or modify existing',
        '^to restrict your access to the',
        '^operational stability\.  VeriSign',
        '^Whois database for failure to',
        '^reserves the right to modify',
        '^The Registry database contains',
        '^Registrars\.$',
        '^Whois Server Version',
    ],
    'whois.nic.travel' => [
        '^>>>> Whois database was last updated',
        '^Tralliance, Inc., the Registry Operator',
        '^for the WHOIS database through',
        '^is provided to you for',
        '^persons in determining',
        '^Tralliance registry database',
        '^"as is" and does not',
        '^agree that you will',
        '^circumstances will',
        '^support the transmission',
        '^solicitations via direct mail',
        '^contravention of any applicable',
        '^enable high volume, automated',
        '^\(or its systems\).  Compilation',
        '^WHOIS database in its entirety',
        '^allowed without Tralliance',
        '^right to modify or change',
        '^subsequent notification of any',
        '^whatsoever, you agree to abide',
        '^NOTE: FAILURE TO LOCATE A RECORD',
        '^OF THE AVAILABILITY OF A DOMAIN NAME',
    ],
    'whois.donuts.co' => [
        '^Terms of Use:',
        '>>> Last update of WHOIS database',
    ],

    'whois.uniregistry.net' => [
        '>>> Last update of WHOIS database',
        '^Access  to  WHOIS  information',
        '^This service is intended only',
        '^[^A-Z]',
        '^\s+$',
    ],

    'whois.nic.uno' => [
        '^>>>> Whois database was last updated',
        '^The WHOIS service offered by Dot Latin LLC',
        '^By executing a query',
        '^NOTE: FAILURE TO LOCATE A RECORD',
        '^All domain names are subject to certain',
    ],

    'whois.nic.menu' => [
        '>>> Last update of WHOIS database',
        '^The data contained in Wedding TLD2',
        '^This information is provided',
        '^By submitting an inquiry',
        '^You further agree not to use',
        '^Wedding TLD2, LLC reserves',
    ],

    'whois.nic.kiwi' => [
        '^>>> Last update',
        '^TERMS OF USE:',
        '^The data',
        '^[^A-Z]',
    ],

    'whois.nic.build' => [
        '^>>> Last update of WHOIS database',
        '^The data',
        '^[^A-Z]',
    ],

    'whois.nic.ht' => [
        '^TERMS OF USE: You are not authorized',
        '^database through the use of electronic',
        '^automated.  Whois database is provided',
        '^community on by of Consortium FDS/RDDH',
        '^The data is for information purposes only.',
        '^guarantee its accuracy. By submitting a',
        '^by the following terms of use:',
        '^for lawful purposes and that under',
        '^to: \(1\) allow, enable, or',
        '^unsolicited, commercial',
        '^or facsimile; or \(2\) enable',
        '^that apply to Consortium FDS/RDDH',
        '^compilation, repackaging',
        '^expressly prohibited.',
        '^Domain Information$',
    ],
    'whois.nic.ki' => [
        '^TERMS OF USE: You are not',
        '^database through the',
        '^automated.  Whois database',
        '^community on behalf of CoCCA',
        '^The data is for information purposes',
        '^guarantee its accuracy. By',
        '^by the following terms of use',
        '^for lawful purposes and that',
        '^to: \(1\) allow, enable, or',
        '^unsolicited, commercial',
        '^or facsimile; or \(2\) enable',
        '^that apply to CoCCA it\'s members',
        '^compilation, repackaging',
        '^expressly prohibited.',
    ],
    'whois.nic.la' => [
        '^This whois service is provided by',
        '^pertaining to Internet domain names',
        '^using this service you are agreeing',
        '^here for any purpose other than',
        '^to store or reproduce this data',
    ],
    'whois.nic.sb' => [
        '^TERMS OF USE: You are not authorized',
        '^The data is for information purposes only',
        '^CoCCA Helpdesk \| http://helpdesk.cocca.cx',
        '^Domain Information$',
    ],
    'whois.nic.tl' => [
        '^TERMS OF USE: You are not authorized',
        '^database through the use of',
        '^automated.  Whois database is',
        '^community on behalf of CoCCA',
        '^The data is for information',
        '^guarantee its accuracy. By',
        '^by the following terms of use',
        '^for lawful purposes and that',
        '^to: \(1\) allow, enable, or',
        '^unsolicited, commercial',
        '^or facsimile; or',
        '^that apply to CoCCA',
        '^compilation, repackaging',
        '^expressly prohibited',
        '^CoCCA Helpdesk',
        '^Domain Information$',
    ],
    'whois.nic.fm' => [
        '^TERMS OF USE',
        '^dotFM makes every effort',
        'is a registered trademark of BRS Media Inc.',
        '^Domain Information$',
    ],
    'whois.nic.co' => [
        '^>>>> Whois database was last',
        '^.CO Internet, S.A.S., the',
        '^information for the WHOIS',
        '^This information is provided',
        '^designed to assist persons',
        '^registration record in the',
        '^information available to you',
        '^By submitting a WHOIS query',
        '^lawful purposes and that',
        '^\(1\) to allow, enable',
        '^unsolicited, commercial',
        '^electronic mail, or by',
        '^data and privacy protection',
        '^electronic processes that',
        '^repackaging, dissemination',
        '^entirety, or of a substantial',
        '^.CO Internet',
        '^change these conditions at',
        '^of any kind. By executing',
        '^abide by these terms.',
        '^NOTE: FAILURE TO LOCATE',
        '^OF THE AVAILABILITY',
        '^All domain names are subject',
        '^rules.  For details, please',
    ],
    'whois.domain.kg' => [
        '^%',
    ],
    'whois.belizenic.bz' => [
        '^The data in BelizeNIC registrar WHOIS database is provided to you by',
        '^BelizeNIC registrar for information purposes only, that is, to assist you in',
        '^obtaining information about or related to a domain name registration',
        '^record. BelizeNIC registrar makes this information available "as is,"',
        '^and',
        '^does not guarantee its accuracy. By submitting a WHOIS query, you',
        '^agree that you will use this data only for lawful purposes and that,',
        '^under no circumstances',
        '^or otherwise support the transmission of mass unsolicited, commercial',
        '^advertising or solicitations via direct mail, electronic mail, or by',
        '^telephone; ',
        '^that apply to BelizeNIC',
        '^repackaging, dissemination or other use of this data is expressly',
        '^prohibited without the prior written consent of BelizeNIC registrar.',
        '^BelizeNIC registrar reserves the right to modify these terms at any time.',
        '^By submitting this query, you agree to abide by these terms.',
    ],
    'whois.nic.xxx' => [
        '^Access to the .XXX WHOIS information is provided to assist persons in',
        '^determining the contents of a domain name registration record in the',
        '^ICM Registry database. The data in this record is provided by',
        '^ICM Registry for informational purposes only, and ICM does not',
        '^guarantee its accuracy. This service is intended only for query-based',
        '^access. You agree that you will use this data only for lawful purposes',
        '^and that, under no circumstances will you use this data to',
        '^enable, or otherwise support the transmission by e-mail, telephone, or',
        '^facsimile of mass unsolicited, commercial advertising or solicitations',
        '^to entities other than the data recipient',
        '^\(b\) enable high volume, automated, electronic processes that send',
        '^queries or data to the systems of Registry Operator, a Registrar, or',
        '^ICM except as reasonably necessary to register domain names or',
        '^modify existing registrations. All rights reserved. ICM reserves',
        '^the right to modify these terms at any time. By submitting this query,',
        '^you agree to abide by this policy.',
    ],
    'whois.online.rs.corenic.net' => [ '^%' ],
    'whois.site.rs.corenic.net'   => [ '^%' ],
    'whois.nic.xn--80adxhks'      => [ '^%' ],
    'whois.nic.moscow'            => [ '^%' ],

    'whois.centralnic.com' => [
        '^>>> Last update of WHOIS database:',
        '^For more information on Whois status codes, please visit https://icann.org/epp',
        '^This whois service is provided by CentralNic Ltd and only contains',
        '^information pertaining to Internet domain names registered by our',
        '^our customers. By using this service you are agreeing (1) not to use any',
        '^information presented here for any purpose other than determining',
        '^ownership of domain names, (2) not to store or reproduce this data in ',
        '^any way, (3) not to use any high-volume, automated, electronic processes',
        '^to obtain data from this service. Abuse of this service is monitored and',
        '^actions in contravention of these terms will result in being permanently',
        '^blacklisted. All data is (c) CentralNic Ltd https://www.centralnic.com/',

        '^Access to the whois service is rate limited. For more information, please',
        '^see https://registrar-console.centralnic.com/pub/whois_guidance.',
    ],
);

our %exceed = (
    'whois.eu' => '(?:Excessive querying, grace period of|Still in grace period, wait)',
    'whois.dns.lu' => 'Excessive querying, grace period of',
    'whois.mynic.my' => 'Query limitation is',
    'whois.ripn.net' => 'exceeded allowed connection rate',
    'whois.registry.ripn.net' => 'exceeded allowed connection rate',
    'whois.domain-registry.nl' => 'too many requests',
    'whois.nic.uk' => 'and will be replenished',
    'whois.networksolutions.com' => 'contained within a list of IP addresses that may have failed',
    'whois.worldsite.ws' => 'You exceeded the maximum',
    'whois.tucows.com'  => '(?:Maximum Daily connection limit reached|exceeded maximum connection limit)',
    'whois.centralnic.com'  => 'Query rate of \\d+',
    'whois.pir.org'  => 'WHOIS LIMIT EXCEEDED',
    'whois.nic.ms'   => 'Look up quota exceeded',
    'whois.nic.gs'   => 'look up quota exceeded',
    'whois.nic.tl'   => 'Lookup quota exceeded',
    'whois.nic.mg'   => 'Lookup quota exceeded',
    'whois.nic.li'   => 'You have exceeded this limit',
    'whois.nic.ch'   => 'You have exceeded this limit',
    'whois.nic.cz'   => 'Your connection limit exceeded',
    'whois.name.com' => 'Too many connection attempts. Please try again in a few seconds.',
    'whois.netcom.cm' => 'Lookup quota exceeded',
    'whois.nic.bj'    => 'Lookup quota exceeded',
);

our $default_ban_time = 60;
our %ban_time = (
    'whois.ripn.net'  => 60,
    'whois.registry.ripn.net'  => 60,
);

# Whois servers which has no idn support
our %whois_servers_with_no_idn_support = (
    'whois.melbourneit.com'  => 1,
);

# Internal postprocessing subroutines
our %postprocess = (
    'whois.pp.ua'   => sub { $_[0] =~ s/[\x00\x0A]+$//; $_[0]; },
);

# Special query prefix strings for some servers
our %query_prefix = (
    'whois.crsnic.net'         => 'domain ',
    'whois.denic.de'           => '-T dn,ace -C ISO-8859-1 ',
    'whois.nic.name'           => 'domain=',

    'whois.nic.name.ns'        => 'nameserver=',
    'whois.pir.org.ns'         => 'HO ',
    'whois.biz.ns'             => 'nameserver ',
    'whois.nsiregistry.net.ns' => 'nameserver = ',

    'whois.arin.net'           => 'n + ',
);

# Servers (within ports) to bypass recursion
our %whois_servers_no_recurse = (
    # 'rwhois.servercentral.net:4321' => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Whois::Raw::Data - Config for Net::Whois::Raw.

=head1 VERSION

version 2.99031

=head1 AUTHOR

Alexander Nalobin <alexander@nalobin.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2020 by Alexander Nalobin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
