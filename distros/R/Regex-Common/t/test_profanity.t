# VOODOO LINE-NOISE
my ( $C, $M, $P, $N, $S );
END { print "1..$C\n$M"; print "\nfailed: $N\n" if $N }

sub ok {
    $C++;
    $M .= ( $_[0] || !@_ )
      ? "ok $C\n"
      : (
        $N++,
        "not ok $C ("
          . ( ( caller 1 )[1] || ( caller 0 )[1] ) . ":"
          . ( ( caller 1 )[2] || ( caller 0 )[2] ) . ")\n"
      );
}
sub try  { $P = qr/^$_[0]$/ }
sub fail { ok( $S = $_[0] !~ $P, $_[0] ) }
sub pass { ok( $S = $_[0] =~ $P, $_[0] ) }

# LOAD

use Regex::Common;
ok;

# MAKE THEM PROFANE

tr/A-Za-z/N-ZA-Mn-za-m/ foreach ( @profanity, @contextual );

# TEST UNEQUIVOCABLE PROFANITIES

try $RE{profanity};

pass $_ foreach @profanity;
fail $_ foreach @contextual;
fail $_ foreach @non_profanity;

# TEST CONTEXTUAL PROFANITIES

try $RE{profanity}{contextual};

pass $_ foreach @profanity;
pass $_ foreach @contextual;
fail $_ foreach @non_profanity;

BEGIN {

    @non_profanity = (
        'love',     'peace',  'joy',    'honour', 'valour', 'house',
        'street',   'parse',  'scrape', 'mishit', 'rectum', 'anus',
        'clitoris', 'vagina', 'breast', 'nipple', 'penis',  'scrotum',
        'foreskin',
    );

}

BEGIN {
    @profanity = (
        'oybj-wbo',       'oybj-wbof',
        'pbpxfhpxvat',    'pbpx-fhpxre',
        'pbpx-fhpxref',   'pbpx-fhpxvat',
        'phag',           'phagf',
        'srygpu',         'srygpuvat',
        'srygpure',       'srygpuref',
        'srygpurf',       'srygpurq',
        'zbgure-shpxre',  'zbgure-shpxref',
        'zbgure-shpxvat', 'zhgure-shpxre',
        'zhgure-shpxref', 'zhgure-shpxvat',
        'zhgun-shpxre',   'zhgun-shpxref',
        'zhgun-shpxvat',  'zhgun-shpxn',
        'zhgun-shpxn',    'zhgun-shpxn',
        'shpx',           'shpxf',
        'shpxvat',        'shpxrq',
        'ohyy-fuvg',      'ohyy-fuvgf',
        'ohyy-fuvggvat',  'ohyy-fuvggrq',
        'ohyy-fuvggre',   'ohyy-fuvggref',
        'uneq-ba',        'fuvg',
        'fuvgf',          'fuvggvat',
        'fuvggrq',        'fuvggre',
        'fuvggref',       'fuvggl',
        'fuvgr',          'fuvgrf',
        'fuvgvat',        'fuvgrq',
        'fuvgre',         'fuvgref',
        'fuvgrl',         'gjng',
        'gjngf',          'gheq',
        'gheqf',          'phzf',
        'phzvat',         'phzzvat',
        'penc',           'pencf',
        'penccre',        'penccref',
        'penccvat',       'penccrq',
        'penccl',         'nff-ubyr',
        'nff-ubyrf',      'nffvat',
        'nffrq',          'unys-nffrq',
        'nefr',           'nefrf',
        'nefr-ubyr',      'nefvat',
        'nefrq',          'unys-nefrq',
        'sneg',           'snegf',
        'snegre',         'snegvat',
        'snegrq',         'snegl',
        'cvff',           'cvffrf',
        'cvffre',         'cvffref',
        'cvffvat',        'cvffrq',
        'cvffl',          'cvff-gnxr',
        'zreqr',          'zreq',
        'dhvz',           'dhvzf',
        'qvpx-urnq',      'qvpxyrff',
        'qvpxvat',        'qvpxrq',
        'qvpxf',          'jnax',
        'jnaxf',          'jnaxre',
        'jnaxref',        'jnaxvat',
        'jnaxrq',         'oybj wbo',
        'oybj wbof',      'pbpx fhpxre',
        'pbpx fhpxref',   'pbpx fhpxvat',
        'zbgure shpxre',  'zbgure shpxref',
        'zbgure shpxvat', 'zhgure shpxre',
        'zhgure shpxref', 'zhgure shpxvat',
        'zhgun shpxre',   'zhgun shpxref',
        'zhgun shpxvat',  'zhgun shpxn',
        'zhgun shpxn',    'zhgun shpxn',
        'ohyy fuvg',      'ohyy fuvgf',
        'ohyy fuvggvat',  'ohyy fuvggrq',
        'ohyy fuvggre',   'ohyy fuvggref',
        'uneq ba',        'nff ubyr',
        'nff ubyrf',      'unys nffrq',
        'nefr ubyr',      'unys nefrq',
        'cvff gnxr',      'qvpx urnq',
        'oybjwbo',        'oybjwbof',
        'pbpxfhpxre',     'pbpxfhpxref',
        'pbpxfhpxvat',    'zbgureshpxre',
        'zbgureshpxref',  'zbgureshpxvat',
        'zhgureshpxre',   'zhgureshpxref',
        'zhgureshpxvat',  'zhgunshpxre',
        'zhgunshpxref',   'zhgunshpxvat',
        'zhgunshpxn',     'zhgunshpxn',
        'zhgunshpxn',     'ohyyfuvg',
        'ohyyfuvgf',      'ohyyfuvggvat',
        'ohyyfuvggrq',    'ohyyfuvggre',
        'ohyyfuvggref',   'uneqba',
        'nffubyr',        'nffubyrf',
        'unysnffrq',      'nefrubyr',
        'unysnefrq',      'cvffgnxr',
        'qvpxurnq'
    );

    @contextual = (
        'onyy',    'onyyf',   'onyyvat',  'onyyrq',
        'onyyre',  'onyyref', 'onfgneq',  'oybbql',
        'obar',    'obarf',   'obavat',   'obare',
        'obaref',  'ohttre',  'pbpx',     'pbpxf',
        'qvpx',    'qbat',    'qbatf',    'uhzc',
        'uhzcre',  'uhzcref', 'uhzcf',    'uhzcvat',
        'uhzcrq',  'cevpx',   'cevpxf',   'cebax',
        'cbex',    'chffl',   'chffvrf',  'ebbg',
        'ebbgf',   'ebbgre',  'ebbgref',  'ebbgvat',
        'ebbgrq',  'fperj',   'fperjf',   'fperjvat',
        'fperjrq', 'funt',    'funtf',    'funttvat',
        'funttrq', 'funttre', 'funttref', 'fbq',
        'fbqf',    'fbqqvat', 'fbqqrq',   'fchax',
        'gvg',     'gvgf'
    );
}
