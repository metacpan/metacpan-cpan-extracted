package Pod::Parser::Groffmom::Entities;

use strict;
use warnings;

=head1 NAME

Pod::Parser::Groffmom::Entities - Internal entity conversions

=head1 VERSION

Version 0.042

=head1 DESCRIPTION

Most characters can be typed direclty into the POD documents you wish to
translate, but if you cannot type them, or if processing a document which
already has them, the following is our conversion list for named entities
entered into POD as C<EE<lt>entity_nameE<gt>>.

List gleefully stolen from C<HTML::Entities>.

=cut

our $VERSION = '0.042';
$VERSION = eval $VERSION;

use base 'Exporter';
our @EXPORT_OK = 'entity_to_num';
my %entity2char = (
    amp  => 38,    # ampersand
    gt   => 62,    # greater than
    lt   => 60,    # less than
    quot => 34,    # double quote
    apos => 39,    # single quote

    # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
    AElig  => 198,    # capital AE diphthong (ligature)
    Aacute => 193,    # capital A, acute accent
    Acirc  => 194,    # capital A, circumflex accent
    Agrave => 192,    # capital A, grave accent
    Aring  => 197,    # capital A, ring
    Atilde => 195,    # capital A, tilde
    Auml   => 196,    # capital A, dieresis or umlaut mark
    Ccedil => 199,    # capital C, cedilla
    ETH    => 208,    # capital Eth, Icelandic
    Eacute => 201,    # capital E, acute accent
    Ecirc  => 202,    # capital E, circumflex accent
    Egrave => 200,    # capital E, grave accent
    Euml   => 203,    # capital E, dieresis or umlaut mark
    Iacute => 205,    # capital I, acute accent
    Icirc  => 206,    # capital I, circumflex accent
    Igrave => 204,    # capital I, grave accent
    Iuml   => 207,    # capital I, dieresis or umlaut mark
    Ntilde => 209,    # capital N, tilde
    Oacute => 211,    # capital O, acute accent
    Ocirc  => 212,    # capital O, circumflex accent
    Ograve => 210,    # capital O, grave accent
    Oslash => 216,    # capital O, slash
    Otilde => 213,    # capital O, tilde
    Ouml   => 214,    # capital O, dieresis or umlaut mark
    THORN  => 222,    # capital THORN, Icelandic
    Uacute => 218,    # capital U, acute accent
    Ucirc  => 219,    # capital U, circumflex accent
    Ugrave => 217,    # capital U, grave accent
    Uuml   => 220,    # capital U, dieresis or umlaut mark
    Yacute => 221,    # capital Y, acute accent
    aacute => 225,    # small a, acute accent
    acirc  => 226,    # small a, circumflex accent
    aelig  => 230,    # small ae diphthong (ligature)
    agrave => 224,    # small a, grave accent
    aring  => 229,    # small a, ring
    atilde => 227,    # small a, tilde
    auml   => 228,    # small a, dieresis or umlaut mark
    ccedil => 231,    # small c, cedilla
    eacute => 233,    # small e, acute accent
    ecirc  => 234,    # small e, circumflex accent
    egrave => 232,    # small e, grave accent
    eth    => 240,    # small eth, Icelandic
    euml   => 235,    # small e, dieresis or umlaut mark
    iacute => 237,    # small i, acute accent
    icirc  => 238,    # small i, circumflex accent
    igrave => 236,    # small i, grave accent
    iuml   => 239,    # small i, dieresis or umlaut mark
    ntilde => 241,    # small n, tilde
    oacute => 243,    # small o, acute accent
    ocirc  => 244,    # small o, circumflex accent
    ograve => 242,    # small o, grave accent
    oslash => 248,    # small o, slash
    otilde => 245,    # small o, tilde
    ouml   => 246,    # small o, dieresis or umlaut mark
    szlig  => 223,    # small sharp s, German (sz ligature)
    thorn  => 254,    # small thorn, Icelandic
    uacute => 250,    # small u, acute accent
    ucirc  => 251,    # small u, circumflex accent
    ugrave => 249,    # small u, grave accent
    uuml   => 252,    # small u, dieresis or umlaut mark
    yacute => 253,    # small y, acute accent
    yuml   => 255,    # small y, dieresis or umlaut mark

   # Some extra Latin 1 chars that are listed in the HTML3.2 draft (21-May-96)
    copy => 169,      # copyright sign
    reg  => 174,      # registered sign
    nbsp => 160,      # non breaking space

    # Additional ISO-8859/1 entities listed in rfc1866 (section 14)
    iexcl    => 161,
    cent     => 162,
    pound    => 163,
    curren   => 164,
    yen      => 165,
    brvbar   => 166,
    sect     => 167,
    uml      => 168,
    ordf     => 170,
    laquo    => 171,
    not      => 172,    # not is a keyword in perl
    shy      => 173,
    macr     => 175,
    deg      => 176,
    plusmn   => 177,
    sup1     => 185,
    sup2     => 178,
    sup3     => 179,
    acute    => 180,
    micro    => 181,
    para     => 182,
    middot   => 183,
    cedil    => 184,
    ordm     => 186,
    raquo    => 187,
    frac14   => 188,
    frac12   => 189,
    frac34   => 190,
    iquest   => 191,
    times    => 215,    # times is a keyword in perl
    divide   => 247,
    OElig    => 338,
    oelig    => 339,
    Scaron   => 352,
    scaron   => 353,
    Yuml     => 376,
    fnof     => 402,
    circ     => 710,
    tilde    => 732,
    Alpha    => 913,
    Beta     => 914,
    Gamma    => 915,
    Delta    => 916,
    Epsilon  => 917,
    Zeta     => 918,
    Eta      => 919,
    Theta    => 920,
    Iota     => 921,
    Kappa    => 922,
    Lambda   => 923,
    Mu       => 924,
    Nu       => 925,
    Xi       => 926,
    Omicron  => 927,
    Pi       => 928,
    Rho      => 929,
    Sigma    => 931,
    Tau      => 932,
    Upsilon  => 933,
    Phi      => 934,
    Chi      => 935,
    Psi      => 936,
    Omega    => 937,
    alpha    => 945,
    beta     => 946,
    gamma    => 947,
    delta    => 948,
    epsilon  => 949,
    zeta     => 950,
    eta      => 951,
    theta    => 952,
    iota     => 953,
    kappa    => 954,
    lambda   => 955,
    mu       => 956,
    nu       => 957,
    xi       => 958,
    omicron  => 959,
    pi       => 960,
    rho      => 961,
    sigmaf   => 962,
    sigma    => 963,
    tau      => 964,
    upsilon  => 965,
    phi      => 966,
    chi      => 967,
    psi      => 968,
    omega    => 969,
    thetasym => 977,
    upsih    => 978,
    piv      => 982,
    ensp     => 8194,
    emsp     => 8195,
    thinsp   => 8201,
    zwnj     => 8204,
    zwj      => 8205,
    lrm      => 8206,
    rlm      => 8207,
    ndash    => 8211,
    mdash    => 8212,
    lsquo    => 8216,
    rsquo    => 8217,
    sbquo    => 8218,
    ldquo    => 8220,
    rdquo    => 8221,
    bdquo    => 8222,
    dagger   => 8224,
    Dagger   => 8225,
    bull     => 8226,
    hellip   => 8230,
    permil   => 8240,
    prime    => 8242,
    Prime    => 8243,
    lsaquo   => 8249,
    rsaquo   => 8250,
    oline    => 8254,
    frasl    => 8260,
    euro     => 8364,
    image    => 8465,
    weierp   => 8472,
    real     => 8476,
    trade    => 8482,
    alefsym  => 8501,
    larr     => 8592,
    uarr     => 8593,
    rarr     => 8594,
    darr     => 8595,
    harr     => 8596,
    crarr    => 8629,
    lArr     => 8656,
    uArr     => 8657,
    rArr     => 8658,
    dArr     => 8659,
    hArr     => 8660,
    forall   => 8704,
    part     => 8706,
    exist    => 8707,
    empty    => 8709,
    nabla    => 8711,
    isin     => 8712,
    notin    => 8713,
    ni       => 8715,
    prod     => 8719,
    sum      => 8721,
    minus    => 8722,
    lowast   => 8727,
    radic    => 8730,
    prop     => 8733,
    infin    => 8734,
    ang      => 8736,
    and      => 8743,
    or       => 8744,
    cap      => 8745,
    cup      => 8746,
    int      => 8747,
    there4   => 8756,
    sim      => 8764,
    cong     => 8773,
    asymp    => 8776,
    ne       => 8800,
    equiv    => 8801,
    le       => 8804,
    ge       => 8805,
    sub      => 8834,
    sup      => 8835,
    nsub     => 8836,
    sube     => 8838,
    supe     => 8839,
    oplus    => 8853,
    otimes   => 8855,
    perp     => 8869,
    sdot     => 8901,
    lceil    => 8968,
    rceil    => 8969,
    lfloor   => 8970,
    rfloor   => 8971,
    lang     => 9001,
    rang     => 9002,
    loz      => 9674,
    spades   => 9824,
    clubs    => 9827,
    hearts   => 9829,
    diams    => 9830,
);

sub entity_to_num {
    my $entity = shift;
    return $entity if $entity =~ /^\d+$/;
    return $entity2char{$entity} || '';
}

1;

__END__

=head1 Entities and their names

The following list shows the allowed entity conversions for C<< E<> >>
entities.  The list is not formatted terribly well since POD is rather limited
here.  Plus, CPAN has trouble with some of the formats I attempted.

The format is <I<entity> =E<gt> I<POD escape>>.

=over 4

E<38> => EE<lt>ampE<gt>

E<62> => EE<lt>gtE<gt>

E<60> => EE<lt>ltE<gt>

E<34> => EE<lt>quotE<gt>

E<39> => EE<lt>aposE<gt>

E<198> => EE<lt>AEligE<gt>

E<193> => EE<lt>AacuteE<gt>

E<194> => EE<lt>AcircE<gt>

E<192> => EE<lt>AgraveE<gt>

E<197> => EE<lt>AringE<gt>

E<195> => EE<lt>AtildeE<gt>

E<196> => EE<lt>AumlE<gt>

E<199> => EE<lt>CcedilE<gt>

E<208> => EE<lt>ETHE<gt>

E<201> => EE<lt>EacuteE<gt>

E<202> => EE<lt>EcircE<gt>

E<200> => EE<lt>EgraveE<gt>

E<203> => EE<lt>EumlE<gt>

E<205> => EE<lt>IacuteE<gt>

E<206> => EE<lt>IcircE<gt>

E<204> => EE<lt>IgraveE<gt>

E<207> => EE<lt>IumlE<gt>

E<209> => EE<lt>NtildeE<gt>

E<211> => EE<lt>OacuteE<gt>

E<212> => EE<lt>OcircE<gt>

E<210> => EE<lt>OgraveE<gt>

E<216> => EE<lt>OslashE<gt>

E<213> => EE<lt>OtildeE<gt>

E<214> => EE<lt>OumlE<gt>

E<222> => EE<lt>THORNE<gt>

E<218> => EE<lt>UacuteE<gt>

E<219> => EE<lt>UcircE<gt>

E<217> => EE<lt>UgraveE<gt>

E<220> => EE<lt>UumlE<gt>

E<221> => EE<lt>YacuteE<gt>

E<225> => EE<lt>aacuteE<gt>

E<226> => EE<lt>acircE<gt>

E<230> => EE<lt>aeligE<gt>

E<224> => EE<lt>agraveE<gt>

E<229> => EE<lt>aringE<gt>

E<227> => EE<lt>atildeE<gt>

E<228> => EE<lt>aumlE<gt>

E<231> => EE<lt>ccedilE<gt>

E<233> => EE<lt>eacuteE<gt>

E<234> => EE<lt>ecircE<gt>

E<232> => EE<lt>egraveE<gt>

E<240> => EE<lt>ethE<gt>

E<235> => EE<lt>eumlE<gt>

E<237> => EE<lt>iacuteE<gt>

E<238> => EE<lt>icircE<gt>

E<236> => EE<lt>igraveE<gt>

E<239> => EE<lt>iumlE<gt>

E<241> => EE<lt>ntildeE<gt>

E<243> => EE<lt>oacuteE<gt>

E<244> => EE<lt>ocircE<gt>

E<242> => EE<lt>ograveE<gt>

E<248> => EE<lt>oslashE<gt>

E<245> => EE<lt>otildeE<gt>

E<246> => EE<lt>oumlE<gt>

E<223> => EE<lt>szligE<gt>

E<254> => EE<lt>thornE<gt>

E<250> => EE<lt>uacuteE<gt>

E<251> => EE<lt>ucircE<gt>

E<249> => EE<lt>ugraveE<gt>

E<252> => EE<lt>uumlE<gt>

E<253> => EE<lt>yacuteE<gt>

E<255> => EE<lt>yumlE<gt>

E<169> => EE<lt>copyE<gt>

E<174> => EE<lt>regE<gt>

E<160> => EE<lt>nbspE<gt>

E<161> => EE<lt>iexclE<gt>

E<162> => EE<lt>centE<gt>

E<163> => EE<lt>poundE<gt>

E<164> => EE<lt>currenE<gt>

E<165> => EE<lt>yenE<gt>

E<166> => EE<lt>brvbarE<gt>

E<167> => EE<lt>sectE<gt>

E<168> => EE<lt>umlE<gt>

E<170> => EE<lt>ordfE<gt>

E<171> => EE<lt>laquoE<gt>

E<172> => EE<lt>notE<gt>

E<173> => EE<lt>shyE<gt>

E<175> => EE<lt>macrE<gt>

E<176> => EE<lt>degE<gt>

E<177> => EE<lt>plusmnE<gt>

E<185> => EE<lt>sup1E<gt>

E<178> => EE<lt>sup2E<gt>

E<179> => EE<lt>sup3E<gt>

E<180> => EE<lt>acuteE<gt>

E<181> => EE<lt>microE<gt>

E<182> => EE<lt>paraE<gt>

E<183> => EE<lt>middotE<gt>

E<184> => EE<lt>cedilE<gt>

E<186> => EE<lt>ordmE<gt>

E<187> => EE<lt>raquoE<gt>

E<188> => EE<lt>frac14E<gt>

E<189> => EE<lt>frac12E<gt>

E<190> => EE<lt>frac34E<gt>

E<191> => EE<lt>iquestE<gt>

E<215> => EE<lt>timesE<gt>

E<247> => EE<lt>divideE<gt>

E<338> => EE<lt>OEligE<gt>

E<339> => EE<lt>oeligE<gt>

E<352> => EE<lt>ScaronE<gt>

E<353> => EE<lt>scaronE<gt>

E<376> => EE<lt>YumlE<gt>

E<402> => EE<lt>fnofE<gt>

E<710> => EE<lt>circE<gt>

E<732> => EE<lt>tildeE<gt>

E<913> => EE<lt>AlphaE<gt>

E<914> => EE<lt>BetaE<gt>

E<915> => EE<lt>GammaE<gt>

E<916> => EE<lt>DeltaE<gt>

E<917> => EE<lt>EpsilonE<gt>

E<918> => EE<lt>ZetaE<gt>

E<919> => EE<lt>EtaE<gt>

E<920> => EE<lt>ThetaE<gt>

E<921> => EE<lt>IotaE<gt>

E<922> => EE<lt>KappaE<gt>

E<923> => EE<lt>LambdaE<gt>

E<924> => EE<lt>MuE<gt>

E<925> => EE<lt>NuE<gt>

E<926> => EE<lt>XiE<gt>

E<927> => EE<lt>OmicronE<gt>

E<928> => EE<lt>PiE<gt>

E<929> => EE<lt>RhoE<gt>

E<931> => EE<lt>SigmaE<gt>

E<932> => EE<lt>TauE<gt>

E<933> => EE<lt>UpsilonE<gt>

E<934> => EE<lt>PhiE<gt>

E<935> => EE<lt>ChiE<gt>

E<936> => EE<lt>PsiE<gt>

E<937> => EE<lt>OmegaE<gt>

E<945> => EE<lt>alphaE<gt>

E<946> => EE<lt>betaE<gt>

E<947> => EE<lt>gammaE<gt>

E<948> => EE<lt>deltaE<gt>

E<949> => EE<lt>epsilonE<gt>

E<950> => EE<lt>zetaE<gt>

E<951> => EE<lt>etaE<gt>

E<952> => EE<lt>thetaE<gt>

E<953> => EE<lt>iotaE<gt>

E<954> => EE<lt>kappaE<gt>

E<955> => EE<lt>lambdaE<gt>

E<956> => EE<lt>muE<gt>

E<957> => EE<lt>nuE<gt>

E<958> => EE<lt>xiE<gt>

E<959> => EE<lt>omicronE<gt>

E<960> => EE<lt>piE<gt>

E<961> => EE<lt>rhoE<gt>

E<962> => EE<lt>sigmafE<gt>

E<963> => EE<lt>sigmaE<gt>

E<964> => EE<lt>tauE<gt>

E<965> => EE<lt>upsilonE<gt>

E<966> => EE<lt>phiE<gt>

E<967> => EE<lt>chiE<gt>

E<968> => EE<lt>psiE<gt>

E<969> => EE<lt>omegaE<gt>

E<977> => EE<lt>thetasymE<gt>

E<978> => EE<lt>upsihE<gt>

E<982> => EE<lt>pivE<gt>

E<8194> => EE<lt>enspE<gt>

E<8195> => EE<lt>emspE<gt>

E<8201> => EE<lt>thinspE<gt>

E<8204> => EE<lt>zwnjE<gt>

E<8205> => EE<lt>zwjE<gt>

E<8206> => EE<lt>lrmE<gt>

E<8207> => EE<lt>rlmE<gt>

E<8211> => EE<lt>ndashE<gt>

E<8212> => EE<lt>mdashE<gt>

E<8216> => EE<lt>lsquoE<gt>

E<8217> => EE<lt>rsquoE<gt>

E<8218> => EE<lt>sbquoE<gt>

E<8220> => EE<lt>ldquoE<gt>

E<8221> => EE<lt>rdquoE<gt>

E<8222> => EE<lt>bdquoE<gt>

E<8224> => EE<lt>daggerE<gt>

E<8225> => EE<lt>DaggerE<gt>

E<8226> => EE<lt>bullE<gt>

E<8230> => EE<lt>hellipE<gt>

E<8240> => EE<lt>permilE<gt>

E<8242> => EE<lt>primeE<gt>

E<8243> => EE<lt>PrimeE<gt>

E<8249> => EE<lt>lsaquoE<gt>

E<8250> => EE<lt>rsaquoE<gt>

E<8254> => EE<lt>olineE<gt>

E<8260> => EE<lt>fraslE<gt>

E<8364> => EE<lt>euroE<gt>

E<8465> => EE<lt>imageE<gt>

E<8472> => EE<lt>weierpE<gt>

E<8476> => EE<lt>realE<gt>

E<8482> => EE<lt>tradeE<gt>

E<8501> => EE<lt>alefsymE<gt>

E<8592> => EE<lt>larrE<gt>

E<8593> => EE<lt>uarrE<gt>

E<8594> => EE<lt>rarrE<gt>

E<8595> => EE<lt>darrE<gt>

E<8596> => EE<lt>harrE<gt>

E<8629> => EE<lt>crarrE<gt>

E<8656> => EE<lt>lArrE<gt>

E<8657> => EE<lt>uArrE<gt>

E<8658> => EE<lt>rArrE<gt>

E<8659> => EE<lt>dArrE<gt>

E<8660> => EE<lt>hArrE<gt>

E<8704> => EE<lt>forallE<gt>

E<8706> => EE<lt>partE<gt>

E<8707> => EE<lt>existE<gt>

E<8709> => EE<lt>emptyE<gt>

E<8711> => EE<lt>nablaE<gt>

E<8712> => EE<lt>isinE<gt>

E<8713> => EE<lt>notinE<gt>

E<8715> => EE<lt>niE<gt>

E<8719> => EE<lt>prodE<gt>

E<8721> => EE<lt>sumE<gt>

E<8722> => EE<lt>minusE<gt>

E<8727> => EE<lt>lowastE<gt>

E<8730> => EE<lt>radicE<gt>

E<8733> => EE<lt>propE<gt>

E<8734> => EE<lt>infinE<gt>

E<8736> => EE<lt>angE<gt>

E<8743> => EE<lt>andE<gt>

E<8744> => EE<lt>orE<gt>

E<8745> => EE<lt>capE<gt>

E<8746> => EE<lt>cupE<gt>

E<8747> => EE<lt>intE<gt>

E<8756> => EE<lt>there4E<gt>

E<8764> => EE<lt>simE<gt>

E<8773> => EE<lt>congE<gt>

E<8776> => EE<lt>asympE<gt>

E<8800> => EE<lt>neE<gt>

E<8801> => EE<lt>equivE<gt>

E<8804> => EE<lt>leE<gt>

E<8805> => EE<lt>geE<gt>

E<8834> => EE<lt>subE<gt>

E<8835> => EE<lt>supE<gt>

E<8836> => EE<lt>nsubE<gt>

E<8838> => EE<lt>subeE<gt>

E<8839> => EE<lt>supeE<gt>

E<8853> => EE<lt>oplusE<gt>

E<8855> => EE<lt>otimesE<gt>

E<8869> => EE<lt>perpE<gt>

E<8901> => EE<lt>sdotE<gt>

E<8968> => EE<lt>lceilE<gt>

E<8969> => EE<lt>rceilE<gt>

E<8970> => EE<lt>lfloorE<gt>

E<8971> => EE<lt>rfloorE<gt>

E<9001> => EE<lt>langE<gt>

E<9002> => EE<lt>rangE<gt>

E<9674> => EE<lt>lozE<gt>

E<9824> => EE<lt>spadesE<gt>

E<9827> => EE<lt>clubsE<gt>

E<9829> => EE<lt>heartsE<gt>

E<9830> => EE<lt>diamsE<gt>
