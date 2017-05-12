package Music::Intervals::Ratios;
$Music::Intervals::Ratios::VERSION = '0.0502';
BEGIN {
  $Music::Intervals::Ratios::AUTHORITY = 'cpan:GENE';
}
use strict;
use warnings;

#> perl -Ilib -MMusic::Intervals::Ratios -le'$x=shift;print $Music::Intervals::Ratios::ratio->{$x}{name}' C
#unison, perfect prime, tonic

# Note ratios, names and descriptions:
our $ratio = {
    C => {
        ratio => '1/1',
        name => q|unison, perfect prime, tonic|,
    },
    "C'" => {
        ratio => '2/1',
        name => q|octave|,
    },
    G => {
        ratio => '3/2',
        name => q|perfect fifth|,
    },
    F => {
        ratio => '4/3',
        name => q|perfect fourth|,
    },
    A => {
        ratio => '5/3',
        name => q|major sixth, BP sixth|,
    },
    E => {
        ratio => '5/4',
        name => q|major third|,
    },
    Eb => {
        ratio => '6/5',
        name => q|minor third|,
    },
    m10 => {
        ratio => '7/3',
        name => q|minimal tenth, BP tenth|,
    },
    '7h' => {
        ratio => '7/4',
        name => q|seventh harmonic|,
    },
    stt => {
        ratio => '7/5',
        name => q|septimal or Huygens' tritone, BP fourth|,
    },
    sm3 => {
        ratio => '7/6',
        name => q|septimal minor third|,
    },
    Ab => {
        ratio => '8/5',
        name => q|minor sixth|,
    },
    swt => {
        ratio => '8/7',
        name => q|septimal whole tone|,
    },
    M9 => {
        ratio => '9/4',
        name => q|major ninth|,
    },
    Bb => {
        ratio => '9/5',
        name => q|just minor seventh, BP seventh, large minor seventh|,
    },
    sM3 => {
        ratio => '9/7',
        name => q|septimal major third, BP third|,
    },
    D => {
        ratio => '9/8',
        name => q|major whole tone|,
    },
    et => {
        ratio => '10/7',
        name => q|Euler's tritone, septimal tritone|,
    },
    mwt => {
        ratio => '10/9',
        name => q|minor whole tone|,
    },
    P2 => => {
        ratio => '11/10',
        name => q|4/5-tone, Ptolemy's second|,
    },
    n9 => {
        ratio => '11/5',
        name => q|neutral ninth|,
    },
    un7 => {
        ratio => '11/6',
        name => q|21/4-tone, undecimal neutral seventh, undecimal "median" seventh|,
    },
    ua5 => {
        ratio => '11/7',
        name => q|undecimal augmented fifth, undecimal minor sixth|,
    },
    '11h' => {
        ratio => '11/8',
        name => q|undecimal semi-augmented fourth, undecimal tritone (11th harmonic)|,
    },
    un3 => {
        ratio => '11/9',
        name => q|undecimal neutral third, undecimal "median" third|,
    },
    un2 => {
        ratio => '12/11',
        name => q|3/4-tone, undecimal neutral second, undecimal "median" 1/2-step|,
    },
    sM6 => {
        ratio => '12/7',
        name => q|septimal major sixth|,
    },
    tsd4 => {
        ratio => '13/10',
        name => q|tridecimal semi-diminished fourth|,
    },
    tm3 => {
        ratio => '13/11',
        name => q|tridecimal minor third|,
    },
    t23t => {
        ratio => '13/12',
        name => q|tridecimal 2/3-tone, 3/4-tone (Avicenna)|,
    },
    '163t' => {
        ratio => '13/7',
        name => q|16/3-tone|,
    },
    tn10 => {
        ratio => '13/8',
        name => q|tridecimal neutral sixth, overtone sixth|,
    },
    td5 => {
        ratio => '13/9',
        name => q|tridecimal diminished fifth|,
    },
    ud4 => {
        ratio => '14/11',
        name => q|undecimal diminished fourth or major third|,
    },
    '23t' => {
        ratio => '14/13',
        name => q|2/3-tone|,
    },
    sm6 => {
        ratio => '14/9',
        name => q|septimal minor sixth|,
    },
    ua4 => {
        ratio => '15/11',
        name => q|undecimal augmented fourth|,
    },
    t54t => {
        ratio => '15/13',
        name => q|tridecimal 5/4-tone|,
    },
    Mds => {
        ratio => '15/14',
        name => q|major diatonic semitone, Cowell just half-step|,
    },
    sm9 => {
        ratio => '15/7',
        name => q|septimal minor ninth, BP ninth|,
    },
    B => {
        ratio => '15/8',
        name => q|classic major seventh|,
    },
    usd5 => {
        ratio => '16/11',
        name => q|undecimal semi-diminished fifth|,
    },
    tnt => {
        ratio => '16/13',
        name => q|tridecimal neutral third|,
    },
    mds => {
        ratio => '16/15',
        name => q|minor diatonic semitone, major half-step|,
    },
    sM9 => {
        ratio => '16/7',
        name => q|septimal major ninth|,
    },
    pm7 => {
        ratio => '16/9',
        name => q|Pythagorean small minor seventh|,
    },
    sdds => {
        ratio => '17/10',
        name => q|septendecimal diminished seventh|,
    },
    ssm6 => {
        ratio => '17/11',
        name => q|septendecimal subminor sixth|,
    },
    '2st' => {
        ratio => '17/12',
        name => q|2nd septendecimal tritone|,
    },
    ss4 => {
        ratio => '17/13',
        name => q|septendecimal sub-fourth|,
    },
    st => {
        ratio => '17/14',
        name => q|supraminor third|,
    },
    spwt => {
        ratio => '17/15',
        name => q|septendecimal whole tone|,
    },
    '17h' => {
        ratio => '17/16',
        name => q|17th harmonic, overtone half-step|,
    },
    sdm9 => {
        ratio => '17/8',
        name => q|septendecimal minor ninth|,
    },
    sdM7 => {
        ratio => '17/9',
        name => q|septendecimal major seventh|,
    },
    un6 => {
        ratio => '18/11',
        name => q|undecimal neutral sixth, undecimal "median" sixth|,
    },
    ta4 => {
        ratio => '18/13',
        name => q|tridecimal augmented fourth|,
    },
    alif => {
        ratio => '18/17',
        name => q|Arabic lute index finger, ET half-step approximation|,
    },
    uvM7 => {
        ratio => '19/10',
        name => q|undevicesimal major seventh|,
    },
    uvm6 => {
        ratio => '19/12',
        name => q|undevicesimal minor sixth|,
    },
    uvd => {
        ratio => '19/15',
        name => q|undevicesimal ditone|,
    },
    '19h' => {
        ratio => '19/16',
        name => q|19th harmonic, overtone minor third|,
    },
    qm => {
        ratio => '19/17',
        name => q|quasi-meantone|,
    },
    uvs => {
        ratio => '19/18',
        name => q|undevicesimal semitone|,
    },
    lm7 => {
        ratio => '20/11',
        name => q|large minor seventh|,
    },
    tsa5 => {
        ratio => '20/13',
        name => q|tridecimal semi-augmented fifth|,
    },
    sda2 => {
        ratio => '20/17',
        name => q|septendecimal augmented second|,
    },
    suvs => {
        ratio => '20/19',
        name => q|small undevicesimal semitone|,
    },
    s9 => {
        ratio => '20/9',
        name => q|small ninth|,
    },
    uM7 => {
        ratio => '21/11',
        name => q|undecimal major seventh|,
    },
    n4 => {
        ratio => '21/16',
        name => q|narrow fourth, septimal fourth|,
    },
    s3 => {
        ratio => '21/17',
        name => q|submajor third|,
    },
    ms => {
        ratio => '21/20',
        name => q|minor semitone|,
    },
    tM6 => {
        ratio => '22/13',
        name => q|tridecimal major sixth|,
    },
    ud5 => {
        ratio => '22/15',
        name => q|undecimal diminished fifth|,
    },
    ssM3 => {
        ratio => '22/17',
        name => q|septendecimal supermajor third|,
    },
    mmt => {
        ratio => '22/19',
        name => q|minimal minor third, godzilla third|,
    },
    ums => {
        ratio => '22/21',
        name => q|undecimal minor semitone, hard 1/2-step (Ptolemy, Avicenna, Safiud)|,
    },
    vM7 => {
        ratio => '23/12',
        name => q|vicesimotertial major seventh|,
    },
    'G#' => {
        ratio => '23/16',
        name => q|23rd harmonic|,
    },
    vM3 => {
        ratio => '23/18',
        name => q|vicesimotertial major third|,
    },
    tn7 => {
        ratio => '24/13',
        name => q|tridecimal neutral seventh|,
    },
    '1sdt' => {
        ratio => '24/17',
        name => q|1st septendecimal tritone|,
    },
    suvM3 => {
        ratio => '24/19',
        name => q|smaller undevicesimal major third|,
    },
    cao => {
        ratio => '25/12',
        name => q|classic augmented octave|,
    },
    mm7 => {
        ratio => '25/14',
        name => q|middle minor seventh|,
    },
    ca5 => {
        ratio => '25/16',
        name => q|classic augmented fifth (G#?)|,
    },
    'F#' => {
        ratio => '25/18',
        name => q|classic augmented fourth|,
    },
    qtm3 => {
        ratio => '25/21',
        name => q|BP second, quasi-tempered minor third|,
    },
    'C#' => {
        ratio => '25/24',
        name => q|classic chromatic semitone, minor chroma, minor half-step|,
    },
    ca11 => {
        ratio => '25/9',
        name => q|classic augmented eleventh, BP twelfth|,
    },
    tsa6 => {
        ratio => '26/15',
        name => q|tridecimal semi-augmented sixth|,
    },
    sds5 => {
        ratio => '26/17',
        name => q|septendecimal super-fifth|,
    },
    '13t' => {
        ratio => '26/25',
        name => q|1/3-tone (Avicenna)|,
    },
    sM7 => {
        ratio => '27/14',
        name => q|septimal major seventh|,
    },
    pM6 => {
        ratio => '27/16',
        name => q|Pythagorean major sixth|,
    },
    sdm6 => {
        ratio => '27/17',
        name => q|septendecimal minor sixth|,
    },
    a4 => {
        ratio => '27/20',
        name => q|acute fourth|,
    },
    n3 => {
        ratio => '27/22',
        name => q|neutral third, Zalzal wosta of al-Farabi|,
    },
    vm3 => {
        ratio => '27/23',
        name => q|vicesimotertial minor third|,
    },
    Db => {
        ratio => '27/25',
        name => q|large limma, BP small semitone (minor second), alternate Renaissance half-step|,
    },
    tc => {
        ratio => '27/26',
        name => q|tridecimal comma|,
    },
    gM7 => {
        ratio => '28/15',
        name => q|grave major seventh|,
    },
    subM6 => {
        ratio => '28/17',
        name => q|submajor sixth|,
    },
    m2 => {
        ratio => '28/25',
        name => q|middle second|,
    },
    a13t => {
        ratio => '28/27',
        name => q|Archytas' 1/3-tone, inferior quarter-tone|,
    },
    '29h' => {
        ratio => '29/16',
        name => q|29th harmonic|,
    },
    suvm6 => {
        ratio => '30/19',
        name => q|smaller undevicesimal minor sixth|,
    },
    sm7 => {
        ratio => '30/17',
        name => q|septendecimal minor seventh|,
    },
    '31h' => {
        ratio => '31/16',
        name => q|31st harmonic|,
    },
    sen => {
        ratio => '31/24',
        name => q|sensi supermajor third|,
    },
    '31pc' => {
        ratio => '31/30',
        name => q|31st-partial chroma, superior quarter-tone (Didymus)|,
    },
    m9 => {
        ratio => '32/15',
        name => q|minor ninth|,
    },
    '17sh' => {
        ratio => '32/17',
        name => q|17th subharmonic|,
    },
    '19sh' => {
        ratio => '32/19',
        name => q|19th subharmonic|,
    },
    w5 => {
        ratio => '32/21',
        name => q|wide fifth|,
    },
    '23sh' => {
        ratio => '32/23',
        name => q|23rd subharmonic|,
    },
    Fb => {
        ratio => '32/25',
        name => q|classic diminished fourth|,
    },
    pm3 => {
        ratio => '32/27',
        name => q|Pythagorean minor third|,
    },
    '29sh' => {
        ratio => '32/29',
        name => q|29th subharmonic|,
    },
    ge14t => {
        ratio => '32/31',
        name => q|Greek enharmonic 1/4-tone, inferior quarter-tone (Didymus)|,
    },
    '2p' => {
        ratio => '33/25',
        name => q|2 pentatones|,
    },
    tM3 => {
        ratio => '33/26',
        name => q|tridecimal major third|,
    },
    um3 => {
        ratio => '33/28',
        name => q|undecimal minor third|,
    },
    '33h' => {
        ratio => '33/32',
        name => q|undecimal comma, al-Farabi's 1/4-tone, 33rd harmonic|,
    },
    supm6 => {
        ratio => '34/21',
        name => q|supraminor sixth|,
    },
    sdM3 => {
        ratio => '34/27',
        name => q|septendecimal major third|,
    },
    ssdo => {
        ratio => '35/18',
        name => q|septimal semi-diminished octave|,
    },
    ssd5 => {
        ratio => '35/24',
        name => q|septimal semi-diminished fifth|,
    },
    ssd4 => {
        ratio => '35/27',
        name => q|9/4-tone, septimal semi-diminished fourth|,
    },
    dwmt => {
        ratio => '35/29',
        name => q|doublewide minor third|,
    },
    '35h' => {
        ratio => '35/32',
        name => q|septimal neutral second, 35th harmonic|,
    },
    sd14t => {
        ratio => '35/34',
        name => q|septendecimal 1/4-tone, E.T. 1/4-tone approximation|,
    },
    suvM7 => {
        ratio => '36/19',
        name => q|smaller undevicesimal major seventh|,
    },
    Gb => {
        ratio => '36/25',
        name => q|classic diminished fifth|,
    },
    sd => {
        ratio => '36/35',
        name => q|septimal diesis, 1/4-tone, superior quarter-tone (Archytas)|,
    },
    '37h' => {
        ratio => '37/32',
        name => q|37th harmonic|,
    },
    '39h' => {
        ratio => '39/32',
        name => q|39th harmonic, Zalzal wosta of Ibn Sina|,
    },
    sqt => {
        ratio => '39/38',
        name => q|superior quarter-tone (Eratosthenes)|,
    },
    aM7 => {
        ratio => '40/21',
        name => q|acute major seventh|,
    },
    g5 => {
        ratio => '40/27',
        name => q|grave fifth, dissonant "wolf" fifth|,
    },
    tmd => {
        ratio => '40/39',
        name => q|tridecimal minor diesis|,
    },
    '41h' => {
        ratio => '41/32',
        name => q|41st harmonic|,
    },
    qtM6 => {
        ratio => '42/25',
        name => q|quasi-tempered major sixth|,
    },
    '43h' => {
        ratio => '43/32',
        name => q|43rd harmonic|,
    },
    n6 => {
        ratio => '44/27',
        name => q|neutral sixth|,
    },
    dt => {
        ratio => '45/32',
        name => q|diatonic tritone, high tritone|,
    },
    '15t' => {
        ratio => '45/44',
        name => q|1/5-tone|,
    },
    '23pc' => {
        ratio => '46/45',
        name => q|23rd-partial chroma, inferior quarter-tone (Ptolemy)|,
    },
    '47h' => {
        ratio => '47/32',
        name => q|47th harmonic|,
    },
    Cb => {
        ratio => '48/25',
        name => q|classic diminished octave|,
    },
    ssa4 => {
        ratio => '48/35',
        name => q|septimal semi-augmented fourth|,
    },
    bp8 => {
        ratio => '49/25',
        name => q|BP eighth|,
    },
    lan6 => {
        ratio => '49/30',
        name => q|larger approximation to neutral sixth|,
    },
    '49h' => {
        ratio => '49/32',
        name => q|49th harmonic|,
    },
    ala4 => {
        ratio => '49/36',
        name => q|Arabic lute acute fourth|,
    },
    lan3 => {
        ratio => '49/40',
        name => q|larger approximation to neutral third|,
    },
    wm2 => {
        ratio => '49/44',
        name => q|werckismic minor second|,
    },
    bpms => {
        ratio => '49/45',
        name => q|BP minor semitone|,
    },
    sld => {
        ratio => '49/48',
        name => q|slendro diesis, 1/6-tone|,
    },
    gM72 => {
        ratio => '50/27',
        name => q|grave major seventh|,
    },
    '3p' => {
        ratio => '50/33',
        name => q|3 pentatones|,
    },
    ttd => {
        ratio => '50/49',
        name => q|Erlich's decatonic comma, tritonic diesis|,
    },
    '51h' => {
        ratio => '51/32',
        name => q|51st harmonic|,
    },
    '17pc' => {
        ratio => '51/50',
        name => q|17th-partial chroma|,
    },
    tm6 => {
        ratio => '52/33',
        name => q|tridecimal minor sixth|,
    },
    '53h' => {
        ratio => '53/32',
        name => q|53rd harmonic|,
    },
    ssa5 => {
        ratio => '54/35',
        name => q|septimal semi-augmented fifth|,
    },
    zm => {
        ratio => '54/49',
        name => q|Zalzal's mujannab|,
    },
    keen => {
        ratio => '55/48',
        name => q|keenanismic supermajor second|,
    },
    qeM2 => {
        ratio => '55/49',
        name => q|quasi-equal major second|,
    },
    '55h' => {
        ratio => '55/64',
        name => q|55th harmonic|,
    },
    nps => {
        ratio => '56/45',
        name => q|narrow perde segah, marvelous major third|,
    },
    pe => {
        ratio => '56/55',
        name => q|Ptolemy's enharmonic|,
    },
    '57h' => {
        ratio => '57/32',
        name => q|57th harmonic|,
    },
    '59h' => {
        ratio => '59/32',
        name => q|59th harmonic|,
    },
    san3 => {
        ratio => '60/49',
        name => q|smaller approximation to neutral third|,
    },
    '61h' => {
        ratio => '61/32',
        name => q|61st harmonic|,
    },
    myn => {
        ratio => '61/51',
        name => q|myna third|,
    },
    orw => {
        ratio => '62/53',
        name => q|orwell subminor third|,
    },
    qeM10 => {
        ratio => '63/25',
        name => q|quasi-equal major tenth, BP eleventh|,
    },
    '63h' => {
        ratio => '63/32',
        name => q|octave - septimal comma, 63rd harmonic|,
    },
    nm6 => {
        ratio => '63/40',
        name => q|narrow minor sixth|,
    },
    qeM3 => {
        ratio => '63/50',
        name => q|quasi-equal major third|,
    },
    werc => {
        ratio => '63/55',
        name => q|werckismic supermajor second|,
    },
    '33sh' => {
        ratio => '64/33',
        name => q|33rd subharmonic|,
    },
    sn7 => {
        ratio => '64/35',
        name => q|septimal neutral seventh|,
    },
    '37sh' => {
        ratio => '64/37',
        name => q|37th subharmonic|,
    },
    '39sh' => {
        ratio => '64/39',
        name => q|39th subharmonic|,
    },
    '2tt' => {
        ratio => '64/45',
        name => q|2nd tritone, low tritone|,
    },
    stM3 => {
        ratio => '64/49',
        name => q|2 septatones or septatonic major third|,
    },
    kst => {
        ratio => '64/55',
        name => q|keenanismic subminor third, octave reduced 55th subharmonic|,
    },
    hms => {
        ratio => '64/61',
        name => q|harry minor semitone|,
    },
    sc => {
        ratio => '64/63',
        name => q|septimal comma, Archytas' comma|,
    },
    '65h' => {
        ratio => '65/64',
        name => q|13th-partial chroma, 65th harmonic|,
    },
    win => {
        ratio => '66/65',
        name => q|winmeanma|,
    },
    '67h' => {
        ratio => '67/64',
        name => q|67th harmonic|,
    },
    '234t' => {
        ratio => '68/35',
        name => q|23/4-tone|,
    },
    val => {
        ratio => '68/65',
        name => q|valentine semitone|,
    },
    '69h' => {
        ratio => '69/64',
        name => q|69th harmonic|,
    },
    wit => {
        ratio => '71/57',
        name => q|witchcraft major third|,
    },
    '71h' => {
        ratio => '71/64',
        name => q|71st harmonic|,
    },
    alg5 => {
        ratio => '72/49',
        name => q|Arabic lute grave fifth|,
    },
    amit => {
        ratio => '73/60',
        name => q|amity supraminor third|,
    },
    '73h' => {
        ratio => '73/64',
        name => q|73rd harmonic|,
    },
    bp5 => {
        ratio => '75/49',
        name => q|BP fifth|,
    },
    mv4 => {
        ratio => '75/56',
        name => q|marvelous fourth|,
    },
    'D#' => {
        ratio => '75/64',
        name => q|classic augmented second|,
    },
    mMt => {
        ratio => '76/61',
        name => q|magic major third|,
    },
    ssMt => {
        ratio => '77/60',
        name => q|swetismic supermajor third|,
    },
    k77h => {
        ratio => '77/64',
        name => q|keenanismic minor third, octave reduced 77th harmonic|,
    },
    use => {
        ratio => '77/72',
        name => q|undecimal secor|,
    },
    a53tc => {
        ratio => '77/76',
        name => q|approximation to 53-tone comma|,
    },
    por => {
        ratio => '78/71',
        name => q|porcupine neutral second|,
    },
    '79h' => {
        ratio => '79/64',
        name => q|79th harmonic|,
    },
    san6 => {
        ratio => '80/49',
        name => q|smaller approximation to neutral sixth|,
    },
    wM3 => {
        ratio => '80/63',
        name => q|wide major third|,
    },
    '2un7' => {
        ratio => '81/44',
        name => q|2nd undecimal neutral seventh|,
    },
    am6 => {
        ratio => '81/50',
        name => q|acute minor sixth|,
    },
    ucat => {
        ratio => '81/55',
        name => q|undecimal catafifth|,
    },
    pM3 => {
        ratio => '81/64',
        name => q|Pythagorean major third|,
    },
    pw => {
        ratio => '81/68',
        name => q|Persian wosta|,
    },
    lmf => {
        ratio => '81/70',
        name => q|Al-Hwarizmi's lute middle finger |,
    },
    syc => {
        ratio => '81/80',
        name => q|syntonic comma, Didymus comma|,
    },
    '83h' => {
        ratio => '83/64',
        name => q|83rd harmonic|,
    },
    '85h' => {
        ratio => '85/64',
        name => q|85th harmonic|,
    },
    '87h' => {
        ratio => '87/64',
        name => q|87th harmonic|,
    },
    wrck => {
        ratio => '88/63',
        name => q|werckismic augmented fourth|,
    },
    '2un2' => {
        ratio => '88/81',
        name => q|2nd undecimal neutral second|,
    },
    '89h' => {
        ratio => '89/64',
        name => q|89th harmonic|,
    },
    aes => {
        ratio => '89/84',
        name => q|approximation to equal semitone|,
    },
    swst => {
        ratio => '90/77',
        name => q|swetismic subminor third|,
    },
    '154t' => {
        ratio => '91/59',
        name => q|15/4-tone|,
    },
    '91h' => {
        ratio => '91/64',
        name => q|91st harmonic|,
    },
    supl => {
        ratio => '91/90',
        name => q|Superleap|,
    },
    '93h' => {
        ratio => '93/64',
        name => q|93rd harmonic|,
    },
    '95h' => {
        ratio => '95/64',
        name => q|95th harmonic|,
    },
    ups => {
        ratio => '96/77',
        name => q|undecimal perde segah, keenanismic major third|,
    },
    '19pc' => {
        ratio => '96/95',
        name => q|19th-partial chroma|,
    },
    '97h' => {
        ratio => '97/64',
        name => q|97th harmonic|,
    },
    qem7 => {
        ratio => '98/55',
        name => q|quasi-equal minor seventh|,
    },
    '99h' => {
        ratio => '99/64',
        name => q|99th harmonic|,
    },
    '2qett' => {
        ratio => '99/70',
        name => q|2nd quasi-equal tritone|,
    },
    suc => {
        ratio => '99/98',
        name => q|small undecimal comma, Mothwellsma|,
    },
    qem6 => {
        ratio => '100/63',
        name => q|quasi-equal minor sixth|,
    },
    gM3 => {
        ratio => '100/81',
        name => q|grave major third|,
    },
    shr => {
        ratio => '100/97',
        name => q|shrutar quarter tone|,
    },
    ptc => {
        ratio => '100/99',
        name => q|Ptolemy's comma|,
    },
    '101h' => {
        ratio => '101/64',
        name => q|101st harmonic|,
    },
    '103h' => {
        ratio => '103/64',
        name => q|103rd harmonic|,
    },
    sn6 => {
        ratio => '105/64',
        name => q|septimal neutral sixth, 105th harmonic|,
    },
    '107h' => {
        ratio => '107/64',
        name => q|107th harmonic|,
    },
    swaf => {
        ratio => '108/77',
        name => q|swetismic augmented fourth|,
    },
    '109h' => {
        ratio => '109/64',
        name => q|109th harmonic|,
    },
    '111h' => {
        ratio => '111/64',
        name => q|111th harmonic|,
    },
    mv5 => {
        ratio => '112/75',
        name => q|marvelous fifth|,
    },
    '113h' => {
        ratio => '113/64',
        name => q|113th harmonic|,
    },
    '115h' => {
        ratio => '115/64',
        name => q|115th harmonic|,
    },
    '117h' => {
        ratio => '117/64',
        name => q|117th harmonic|,
    },
    '119h' => {
        ratio => '119/64',
        name => q|119th harmonic|,
    },
    u2c => {
        ratio => '121/120',
        name => q|undecimal seconds comma, Biyatisma|,
    },
    '121h' => {
        ratio => '121/64',
        name => q|121st harmonic|,
    },
    '123h' => {
        ratio => '123/64',
        name => q|123rd harmonic|,
    },
    sawt => {
        ratio => '125/108',
        name => q|semi-augmented whole tone|,
    },
    cas => {
        ratio => '125/112',
        name => q|classic augmented semitone|,
    },
    'B#' => {
        ratio => '125/64',
        name => q|classic augmented seventh, octave - minor diesis|,
    },
    'A#' => {
        ratio => '125/72',
        name => q|classic augmented sixth|,
    },
    'E#' => {
        ratio => '125/96',
        name => q|classic augmented third|,
    },
    smsc => {
        ratio => '126/125',
        name => q|small septimal comma|,
    },
    '127h' => {
        ratio => '127/64',
        name => q|127th harmonic|,
    },
    sn3 => {
        ratio => '128/105',
        name => q|septimal neutral third|,
    },
    us => {
        ratio => '128/121',
        name => q|undecimal semitone|,
    },
    mdd => {
        ratio => '128/125',
        name => q|minor diesis, diesis, diminished second|,
    },
    d7 => {
        ratio => '128/75',
        name => q|diminished seventh|,
    },
    pm6 => {
        ratio => '128/81',
        name => q|Pythagorean minor sixth|,
    },
    '134t' => {
        ratio => '131/90',
        name => q|13/4-tone|,
    },
    Mc => {
        ratio => '135/128',
        name => q|major chroma, major limma, limma ascendant|,
    },
    qett => {
        ratio => '140/99',
        name => q|quasi-equal tritone|,
    },
    cd3 => {
        ratio => '144/125',
        name => q|classic diminished third|,
    },
    '29pc' => {
        ratio => '145/144',
        name => q|29th-partial chroma|,
    },
    '74t' => {
        ratio => '153/125',
        name => q|7/4-tone|,
    },
    osyc => {
        ratio => '160/81',
        name => q|octave minus syntonic comma|,
    },
    '194t' => {
        ratio => '161/93',
        name => q|19/4-tone|,
    },
    pn2 => {
        ratio => '162/149',
        name => q|Persian neutral second|,
    },
    vali => {
        ratio => '176/175',
        name => q|Valinorsma|,
    },
    cd6 => {
        ratio => '192/125',
        name => q|classic diminished sixth|,
    },
    ci => {
        ratio => '196/169',
        name => q|consonant interval (Avicenna)|,
    },
    sa6 => {
        ratio => '216/125',
        name => q|semi-augmented sixth|,
    },
    a6 => {
        ratio => '225/128',
        name => q|augmented sixth|,
    },
    sk => {
        ratio => '225/224',
        name => q|septimal kleisma|,
    },
    '54t' => {
        ratio => '231/200',
        name => q|5/4-tone|,
    },
    m34t => {
        ratio => '241/221',
        name => q|Meshaqah's 3/4-tone|,
    },
    omaxd => {
        ratio => '243/125',
        name => q|octave - maximal diesis|,
    },
    pM7 => {
        ratio => '243/128',
        name => q|Pythagorean major seventh|,
    },
    a5 => {
        ratio => '243/160',
        name => q|acute fifth|,
    },
    am3 => {
        ratio => '243/200',
        name => q|acute minor third|,
    },
    ssu => {
        ratio => '243/224',
        name => q|septimal subtone|,
    },
    n3c => {
        ratio => '243/242',
        name => q|neutral third comma|,
    },
    mbpd => {
        ratio => '245/243',
        name => q|minor BP diesis|,
    },
    m14t => {
        ratio => '246/239',
        name => q|Meshaqah's 1/4-tone|,
    },
    tpc => {
        ratio => '248/243',
        name => q|tricesoprimal comma|,
    },
    '174t' => {
        ratio => '250/153',
        name => q|17/4-tone|,
    },
    maxd => {
        ratio => '250/243',
        name => q|maximal diesis|,
    },
    oMc => {
        ratio => '256/135',
        name => q|octave - major chroma|,
    },
    d3 => {
        ratio => '256/225',
        name => q|diminished third|,
    },
    pm2 => {
        ratio => '256/243',
        name => q|limma, Pythagorean minor second|,
    },
    sdk => {
        ratio => '256/255',
        name => q|septendecimal kleisma|,
    },
    vnc => {
        ratio => '261/256',
        name => q|vicesimononal comma|,
    },
    pwt => {
        ratio => '272/243',
        name => q|Persian whole tone|,
    },
    ism2 => {
        ratio => '273/256',
        name => q|Ibn Sina's minor second|,
    },
    g4 => {
        ratio => '320/243',
        name => q|grave fourth|,
    },
    da4 => {
        ratio => '375/256',
        name => q|double augmented fourth|,
    },
    bpMs => {
        ratio => '375/343',
        name => q|BP major semitone|,
    },
    uk => {
        ratio => '385/384',
        name => q|undecimal kleisma|,
    },
    gM6 => {
        ratio => '400/243',
        name => q|grave major sixth|,
    },
    wa5 => {
        ratio => '405/256',
        name => q|wide augmented fifth|,
    },
    werc => {
        ratio => '441/440',
        name => q|Werckisma|,
    },
    st5 => {
        ratio => '512/343',
        name => q|3 septatones or septatonic fifth|,
    },
    dd5 => {
        ratio => '512/375',
        name => q|double diminished fifth|,
    },
    nd4 => {
        ratio => '512/405',
        name => q|narrow diminished fourth|,
    },
    uvc => {
        ratio => '513/512',
        name => q|undevicesimal comma, Boethius' comma|,
    },
    aed => {
        ratio => '525/512',
        name => q|Avicenna enharmonic diesis|,
    },
    swc => {
        ratio => '540/539',
        name => q|Swets' comma|,
    },
    oMd => {
        ratio => '625/324',
        name => q|octave - major diesis|,
    },
    bpgs => {
        ratio => '625/567',
        name => q|BP great semitone|,
    },
    Md => {
        ratio => '648/625',
        name => q|major diesis|,
    },
    wa3 => {
        ratio => '675/512',
        name => q|wide augmented third|,
    },
    pari => {
        ratio => '676/675',
        name => q|Parizeksma|,
    },
    '114t' => {
        ratio => '687/500',
        name => q|11/4-tone|,
    },
    am7 => {
        ratio => '729/400',
        name => q|acute minor seventh|,
    },
    ptt => {
        ratio => '729/512',
        name => q|high Pythagorean tritone|,
    },
    aM2 => {
        ratio => '729/640',
        name => q|acute major second|,
    },
    uMd => {
        ratio => '729/704',
        name => q|undecimal major diesis|,
    },
    vtc => {
        ratio => '736/729',
        name => q|vicesimotertial comma|,
    },
    acqe5 => {
        ratio => '749/500',
        name => q|ancient Chinese quasi-equal fifth|,
    },
    act => {
        ratio => '750/749',
        name => q|ancient Chinese tempering|,
    },
    gwt => {
        ratio => '800/729',
        name => q|grave whole tone|,
    },
    usc => {
        ratio => '896/891',
        name => q|undecimal semicomma|,
    },
    nd6 => {
        ratio => '1024/675',
        name => q|narrow diminished sixth|,
    },
    pd5 => {
        ratio => '1024/729',
        name => q|Pythagorean diminished fifth, low Pythagorean tritone|,
    },
    gr => {
        ratio => '1029/1024',
        name => q|gamelan residue|,
    },
    tMd => {
        ratio => '1053/1024',
        name => q|tridecimal major diesis|,
    },
    dap => {
        ratio => '1125/1024',
        name => q|double augmented prime|,
    },
    wa2 => {
        ratio => '1215/1024',
        name => q|wide augmented second|,
    },
    ec => {
        ratio => '1216/1215',
        name => q|Eratosthenes' comma|,
    },
    gm7 => {
        ratio => '1280/729',
        name => q|grave minor seventh|,
    },
    tp => {
        ratio => '1288/1287',
        name => q|triaphonisma|,
    },
    oc => {
        ratio => '1728/1715',
        name => q|Orwell comma|,
    },
    a1c => {
        ratio => '1732/1731',
        name => q|approximation to 1 cent|,
    },
    da6 => {
        ratio => '1875/1024',
        name => q|double augmented sixth|,
    },
    '2tts' => {
        ratio => '2025/1024',
        name => q|2 tritones|,
    },
    ddo => {
        ratio => '2048/1125',
        name => q|double diminished octave|,
    },
    nd7 => {
        ratio => '2048/1215',
        name => q|narrow diminished seventh|,
    },
    dd3 => {
        ratio => '2048/1875',
        name => q|double diminished third|,
    },
    dch => {
        ratio => '2048/2025',
        name => q|diaschisma|,
    },
    xen => {
        ratio => '2058/2057',
        name => q|xenisma|,
    },
    aM6 => {
        ratio => '2187/1280',
        name => q|acute major sixth|,
    },
    ap => {
        ratio => '2187/2048',
        name => q|apotome|,
    },
    sdc => {
        ratio => '2187/2176',
        name => q|septendecimal comma|,
    },
    br => {
        ratio => '2401/2400',
        name => q|Breedsma|,
    },
    gm3 => {
        ratio => '2560/2187',
        name => q|grave minor third|,
    },
    leh => {
        ratio => '3025/3024',
        name => q|lehmerisma|,
    },
    smd => {
        ratio => '3125/3072',
        name => q|small diesis|,
    },
    Mbpd => {
        ratio => '3125/3087',
        name => q|major BP diesis|,
    },
    da5 => {
        ratio => '3375/2048',
        name => q|double augmented fifth|,
    },
    ssc => {
        ratio => '4000/3969',
        name => q|septimal semicomma, Octagar|,
    },
    wiz => {
        ratio => '4000/3993',
        name => q|Wizardharry|,
    },
    pdo => {
        ratio => '4096/2187',
        name => q|Pythagorean diminished octave|,
    },
    stM6 => {
        ratio => '4096/2401',
        name => q|4 septatones or septatonic major sixth|,
    },
    dd4 => {
        ratio => '4096/3375',
        name => q|double diminished fourth|,
    },
    ts => {
        ratio => '4096/4095',
        name => q|tridecimal schisma, Sagittal schismina|,
    },
    rag => {
        ratio => '4375/4374',
        name => q|ragisma|,
    },
    an2 => {
        ratio => '4608/4235',
        name => q|Arabic neutral second|,
    },
    b5 => {
        ratio => '5120/5103',
        name => q|Beta 5|,
    },
    da3 => {
        ratio => '5625/4096',
        name => q|double augmented third|,
    },
    osd => {
        ratio => '6144/3125',
        name => q|octave - small diesis|,
    },
    por => {
        ratio => '6144/6125',
        name => q|Porwell|,
    },
    pa5 => {
        ratio => '6561/4096',
        name => q|Pythagorean augmented fifth, Pythagorean "schismatic" sixth|,
    },
    aM3 => {
        ratio => '6561/5120',
        name => q|acute major third|,
    },
    bpMl => {
        ratio => '6561/6125',
        name => q|BP major link|,
    },
    msd => {
        ratio => '6561/6400',
        name => q|Mathieu superdiesis|,
    },
    dd6 => {
        ratio => '8192/5625',
        name => q|double diminished sixth|,
    },
    pd4 => {
        ratio => '8192/6561',
        name => q|Pythagorean diminished fourth, Pythagorean "schismatic" third|,
    },
    umd => {
        ratio => '8192/8019',
        name => q|undecimal minor diesis|,
    },
    gc => {
        ratio => '9801/9800',
        name => q|kalisma, Gauss' comma|,
    },
    da2 => {
        ratio => '10125/8192',
        name => q|double augmented second|,
    },
    gm6 => {
        ratio => '10240/6561',
        name => q|grave minor sixth|,
    },
    har => {
        ratio => '10648/10647',
        name => q|harmonisma|,
    },
    '4s' => {
        ratio => '10935/8192',
        name => q|fourth + schisma, approximation to ET fourth|,
    },
    gbpd => {
        ratio => '15625/15309',
        name => q|great BP diesis|,
    },
    scm => {
        ratio => '15625/15552',
        name => q|kleisma, semicomma majeur|,
    },
    dd7 => {
        ratio => '16384/10125',
        name => q|double diminished seventh|,
    },
    '5s' => {
        ratio => '16384/10935',
        name => q|fifth - schisma, approximation to ET fifth|,
    },
    sbpd => {
        ratio => '16875/16807',
        name => q|small BP diesis|,
    },
    gh => {
        ratio => '19657/19656',
        name => q|greater harmonisma|,
    },
    omind => {
        ratio => '19683/10000',
        name => q|octave - minimal diesis|,
    },
    aM72 => {
        ratio => '19683/10240',
        name => q|acute major seventh|,
    },
    pa2 => {
        ratio => '19683/16384',
        name => q|Pythagorean augmented second|,
    },
    mind => {
        ratio => '20000/19683',
        name => q|minimal diesis|,
    },
    gm2 => {
        ratio => '20480/19683',
        name => q|grave minor second|,
    },
    lh => {
        ratio => '23232/23231',
        name => q|lesser harmonisma|,
    },
    sdo => {
        ratio => '32768/16807',
        name => q|5 septatones or septatonic diminished octave|,
    },
    pd7 => {
        ratio => '32768/19683',
        name => q|Pythagorean diminished seventh|,
    },
    sch => {
        ratio => '32805/32768',
        name => q|schisma|,
    },
    pa6 => {
        ratio => '59049/32768',
        name => q|Pythagorean augmented sixth|,
    },
    hc => {
        ratio => '59049/57344',
        name => q|Harrison's comma|,
    },
    os => {
        ratio => '65536/32805',
        name => q|octave - schisma|,
    },
    pd3 => {
        ratio => '65536/59049',
        name => q|Pythagorean diminished third|,
    },
    orgo => {
        ratio => '65536/65219',
        name => q|Orgonisma|,
    },
    msc => {
        ratio => '78732/78125',
        name => q|medium semicomma|,
    },
    bpml => {
        ratio => '83349/78125',
        name => q|BP minor link|,
    },
    pa3 => {
        ratio => '177147/131072',
        name => q|Pythagorean augmented third|,
    },
    land => {
        ratio => '250047/250000',
        name => q|Landscape Comma|,
    },
    pd6 => {
        ratio => '262144/177147',
        name => q|Pythagorean diminished sixth|,
    },
    owc => {
        ratio => '390625/196608',
        name => q|octave - Würschmidt's comma|,
    },
    wc => {
        ratio => '393216/390625',
        name => q|Würschmidt's comma|,
    },
    bpsl => {
        ratio => '413343/390625',
        name => q|BP small link|,
    },
    pa7 => {
        ratio => '531441/262144',
        name => q|Pythagorean augmented seventh|,
    },
    pc => {
        ratio => '531441/524288',
        name => q|Pythagorean comma, ditonic comma|,
    },
    pd9 => {
        ratio => '1048576/531441',
        name => q|Pythagorean diminished ninth|,
    },
    pda4 => {
        ratio => '1594323/1048576',
        name => q|Pythagorean double augmented fourth|,
    },
    ks => {
        ratio => '1600000/1594323',
        name => q|kleisma - schisma|,
    },
    pdd5 => {
        ratio => '2097152/1594323',
        name => q|Pythagorean double diminished fifth|,
    },
    fsc => {
        ratio => '2109375/2097152',
        name => q|semicomma, Fokker's comma|,
    },
    pdap => {
        ratio => '4782969/4194304',
        name => q|Pythagorean double augmented prime|,
    },
    pddo => {
        ratio => '8388608/4782969',
        name => q|Pythagorean double diminished octave|,
    },
    pda5 => {
        ratio => '14348907/8388608',
        name => q|Pythagorean double augmented fifth|,
    },
    pdd4 => {
        ratio => '16777216/14348907',
        name => q|Pythagorean double diminished fourth|,
    },
    ssch => {
        ratio => '33554432/33480783',
        name => q|Beta 2, septimal schisma|,
    },
    ac => {
        ratio => '34171875/33554432',
        name => q|Ampersand's comma|,
    },
    pda2 => {
        ratio => '43046721/33554432',
        name => q|Pythagorean double augmented second|,
    },
    pdd7 => {
        ratio => '67108864/43046721',
        name => q|Pythagorean double diminished seventh|,
    },
    dschs => {
        ratio => '67108864/66430125',
        name => q|diaschisma - schisma|,
    },
    pda6 => {
        ratio => '129140163/67108864',
        name => q|Pythagorean double augmented sixth|,
    },
    pdd3 => {
        ratio => '134217728/129140163',
        name => q|Pythagorean double diminished third|,
    },
    pda3 => {
        ratio => '387420489/268435456',
        name => q|Pythagorean double augmented third|,
    },
    pdd6 => {
        ratio => '536870912/387420489',
        name => q|Pythagorean double diminished sixth|,
    },
    p19c => {
        ratio => '1162261467/1073741824',
        name => q|Pythagorean-19 comma|,
    },
    pda7 => {
        ratio => '1162261467/536870912',
        name => q|Pythagorean double augmented seventh|,
    },
    pkl => {
        ratio => '1224440064/1220703125',
        name => q|parakleisma|,
    },
    vc => {
        ratio => '6115295232/6103515625',
        name => q|Vishnu comma|,
    },
    stc => {
        ratio => '274877906944/274658203125',
        name => q|semithirds comma|,
    },
    phi => {
        ratio => '1001158530539/618750000000',
        name => q|approximation of the golden ratio|,
    },
    enlc => {
        ratio => '7629394531250/7625597484987',
        name => q|ennealimmal comma|,
    },
    '19tc' => {
        ratio => '19073486328125/19042491875328',
        name => q|'19-tone' comma|,
    },
    inv => {
        ratio => '123606797749979/200000000000000',
        name => q|approximation of the inverse of the golden ratio|,
    },
    mz => {
        ratio => '450359962737049600/450283905890997363',
        name => q|monzisma|,
    },
    '41tc' => {
        ratio => '36893488147419103232/36472996377170786403',
        name => q|'41-tone' comma|,
    },
    mercc => {
        ratio => '19383245667680019896796723/19342813113834066795298816',
        name => q|Mercator's comma|,
    },
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Intervals::Ratios

=head1 VERSION

version 0.0502

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
