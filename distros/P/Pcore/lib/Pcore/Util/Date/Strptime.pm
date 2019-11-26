package Pcore::Util::Date::Strptime;

use Pcore -role, -const;

# %a - the abbreviated weekday name ('Sun')
# %A - the full weekday name ('Sunday')
# %b - the abbreviated month name ('Jan')
# %B - the full month name ('January')
# %c - the preferred local date and time representation
# %d - day of the month (01..31)
# %e - day of the month without leading zeroes (1..31)
# %H - hour of the day, 24-hour clock (00..23)
# %I - hour of the day, 12-hour clock (01..12)
# %j - day of the year (001..366)
# %k - hour of the day, 24-hour clock w/o leading zeroes (0..23)
# %l - hour of the day, 12-hour clock w/o leading zeroes (1..12)
# %m - month of the year (01..12)
# %M - minute of the hour (00..59)
# %p - meridian indicator ('AM' or 'PM')
# %P - meridian indicator ('am' or 'pm')
# %S - second of the minute (00..60)
# %U - week number of the current year, starting with the first Sunday as the first day of the first week (00..53)
# %W - week number of the current year, starting with the first Monday as the first day of the first week (00..53)
# %w - day of the week (Sunday is 0, 0..6)
# %x - preferred representation for the date alone, no time
# %X - preferred representation for the time alone, no date
# %y - year without a century (00..99)
# %Y - year with century
# %Z - time zone name
# %z - +/- hhmm or hh:mm
# %% - literal '%' character

const our $WEEKDAY => [qw[monday tuesday wednesday thursday friday saturday sunday]];

const our $WEEKDAY_ABBR => [qw[mon tue wed thu fri sat sun]];

const our $MONTH => [qw[january february march april may june july august september october november december]];

const our $MONTH_ABBR => [qw[jan feb mar apr may jun jul aug sep oct nov dec]];

const our $MONTH_NUM => { map { $_ => state $i++ + 1 } $MONTH->@* };

const our $MONTH_ABBR_NUM => { map { $_ => state $i++ + 1 } $MONTH_ABBR->@* };

const our $TIMEZONE => {
    A      => '+0100',
    ACDT   => '+1030',
    ACST   => '+0930',
    ADT    => undef,
    AEDT   => '+1100',
    AES    => '+1000',
    AEST   => '+1000',
    AFT    => '+0430',
    AHDT   => '-0900',
    AHST   => '-1000',
    AKDT   => '-0800',
    AKST   => '-0900',
    AMST   => '+0400',
    AMT    => '+0400',
    ANAST  => '+1300',
    ANAT   => '+1200',
    ART    => '-0300',
    AST    => undef,
    AT     => '-0100',
    AWST   => '+0800',
    AZOST  => '+0000',
    AZOT   => '-0100',
    AZST   => '+0500',
    AZT    => '+0400',
    B      => '+0200',
    BADT   => '+0400',
    BAT    => '+0600',
    BDST   => '+0200',
    BDT    => '+0600',
    BET    => '-1100',
    BNT    => '+0800',
    BORT   => '+0800',
    BOT    => '-0400',
    BRA    => '-0300',
    BST    => undef,
    BT     => undef,
    BTT    => '+0600',
    C      => '+0300',
    CAST   => '+0930',
    CAT    => undef,
    CCT    => undef,
    CDT    => undef,
    CEST   => '+0200',
    CET    => '+0100',
    CETDST => '+0200',
    CHADT  => '+1345',
    CHAST  => '+1245',
    CKT    => '-1000',
    CLST   => '-0300',
    CLT    => '-0400',
    COT    => '-0500',
    CST    => undef,
    CSUT   => '+1030',
    CUT    => '+0000',
    CVT    => '-0100',
    CXT    => '+0700',
    CHST   => '+1000',
    D      => '+0400',
    DAVT   => '+0700',
    DDUT   => '+1000',
    DNT    => '+0100',
    DST    => '+0200',
    E      => '+0500',
    EASST  => '-0500',
    EAST   => undef,
    EAT    => '+0300',
    ECT    => undef,
    EDT    => undef,
    EEST   => '+0300',
    EET    => '+0200',
    EETDST => '+0300',
    EGST   => '+0000',
    EGT    => '-0100',
    EMT    => '+0100',
    EST    => undef,
    ESUT   => '+1100',
    F      => '+0600',
    FDT    => undef,
    FJST   => '+1300',
    FJT    => '+1200',
    FKST   => '-0300',
    FKT    => '-0400',
    FST    => undef,
    FWT    => '+0100',
    G      => '+0700',
    GALT   => '-0600',
    GAMT   => '-0900',
    GEST   => '+0500',
    GET    => '+0400',
    GFT    => '-0300',
    GILT   => '+1200',
    GMT    => '+0000',
    GST    => undef,
    GT     => '+0000',
    GYT    => '-0400',
    GZ     => '+0000',
    H      => '+0800',
    HAA    => '-0300',
    HAC    => '-0500',
    HAE    => '-0400',
    HAP    => '-0700',
    HAR    => '-0600',
    HAT    => '-0230',
    HAY    => '-0800',
    HDT    => '-0930',
    HFE    => '+0200',
    HFH    => '+0100',
    HG     => '+0000',
    HKT    => '+0800',
    HL     => undef,     # 'local',
    HNA    => '-0400',
    HNC    => '-0600',
    HNE    => '-0500',
    HNP    => '-0800',
    HNR    => '-0700',
    HNT    => '-0330',
    HNY    => '-0900',
    HOE    => '+0100',
    HST    => '-1000',
    I      => '+0900',
    ICT    => '+0700',
    IDLE   => '+1200',
    IDLW   => '-1200',
    IDT    => undef,
    IOT    => '+0500',
    IRDT   => '+0430',
    IRKST  => '+0900',
    IRKT   => '+0800',
    IRST   => '+0430',
    IRT    => '+0330',
    IST    => undef,
    IT     => '+0330',
    ITA    => '+0100',
    JAVT   => '+0700',
    JAYT   => '+0900',
    JST    => '+0900',
    JT     => '+0700',
    K      => '+1000',
    KDT    => '+1000',
    KGST   => '+0600',
    KGT    => '+0500',
    KOST   => '+1200',
    KRAST  => '+0800',
    KRAT   => '+0700',
    KST    => '+0900',
    L      => '+1100',
    LHDT   => '+1100',
    LHST   => '+1030',
    LIGT   => '+1000',
    LINT   => '+1400',
    LKT    => '+0600',
    LST    => undef,     # 'local',
    LT     => undef,     # 'local',
    M      => '+1200',
    MAGST  => '+1200',
    MAGT   => '+1100',
    MAL    => '+0800',
    MART   => '-0930',
    MAT    => '+0300',
    MAWT   => '+0600',
    MDT    => '-0600',
    MED    => '+0200',
    MEDST  => '+0200',
    MEST   => '+0200',
    MESZ   => '+0200',
    MET    => undef,
    MEWT   => '+0100',
    MEX    => '-0600',
    MEZ    => '+0100',
    MHT    => '+1200',
    MMT    => '+0630',
    MPT    => '+1000',
    MSD    => '+0400',
    MSK    => '+0300',
    MSKS   => '+0400',
    MST    => '-0700',
    MT     => '+0830',
    MUT    => '+0400',
    MVT    => '+0500',
    MYT    => '+0800',
    N      => '-0100',
    NCT    => '+1100',
    NDT    => '-0230',
    NFT    => undef,
    NOR    => '+0100',
    NOVST  => '+0700',
    NOVT   => '+0600',
    NPT    => '+0545',
    NRT    => '+1200',
    NST    => undef,
    NSUT   => '+0630',
    NT     => '-1100',
    NUT    => '-1100',
    NZDT   => '+1300',
    NZST   => '+1200',
    NZT    => '+1200',
    O      => '-0200',
    OESZ   => '+0300',
    OEZ    => '+0200',
    OMSST  => '+0700',
    OMST   => '+0600',
    OZ     => undef,     # 'local',
    P      => '-0300',
    PDT    => '-0700',
    PET    => '-0500',
    PETST  => '+1300',
    PETT   => '+1200',
    PGT    => '+1000',
    PHOT   => '+1300',
    PHT    => '+0800',
    PKT    => '+0500',
    PMDT   => '-0200',
    PMT    => '-0300',
    PNT    => '-0830',
    PONT   => '+1100',
    PST    => undef,
    PWT    => '+0900',
    PYST   => '-0300',
    PYT    => '-0400',
    Q      => '-0400',
    R      => '-0500',
    R1T    => '+0200',
    R2T    => '+0300',
    RET    => '+0400',
    ROK    => '+0900',
    S      => '-0600',
    SADT   => '+1030',
    SAST   => undef,
    SBT    => '+1100',
    SCT    => '+0400',
    SET    => '+0100',
    SGT    => '+0800',
    SRT    => '-0300',
    SST    => undef,
    SWT    => '+0100',
    T      => '-0700',
    TFT    => '+0500',
    THA    => '+0700',
    THAT   => '-1000',
    TJT    => '+0500',
    TKT    => '-1000',
    TMT    => '+0500',
    TOT    => '+1300',
    TRUT   => '+1000',
    TST    => '+0300',
    TUC    => '+0000',
    TVT    => '+1200',
    U      => '-0800',
    ULAST  => '+0900',
    ULAT   => '+0800',
    USZ1   => '+0200',
    USZ1S  => '+0300',
    USZ3   => '+0400',
    USZ3S  => '+0500',
    USZ4   => '+0500',
    USZ4S  => '+0600',
    USZ5   => '+0600',
    USZ5S  => '+0700',
    USZ6   => '+0700',
    USZ6S  => '+0800',
    USZ7   => '+0800',
    USZ7S  => '+0900',
    USZ8   => '+0900',
    USZ8S  => '+1000',
    USZ9   => '+1000',
    USZ9S  => '+1100',
    UTZ    => '-0300',
    UYT    => '-0300',
    UZ10   => '+1100',
    UZ10S  => '+1200',
    UZ11   => '+1200',
    UZ11S  => '+1300',
    UZ12   => '+1200',
    UZ12S  => '+1300',
    UZT    => '+0500',
    V      => '-0900',
    VET    => '-0400',
    VLAST  => '+1100',
    VLAT   => '+1000',
    VTZ    => '-0200',
    VUT    => '+1100',
    W      => '-1000',
    WAKT   => '+1200',
    WAST   => undef,
    WAT    => '+0100',
    WEST   => '+0100',
    WESZ   => '+0100',
    WET    => '+0000',
    WETDST => '+0100',
    WEZ    => '+0000',
    WFT    => '+1200',
    WGST   => '-0200',
    WGT    => '-0300',
    WIB    => '+0700',
    WIT    => '+0900',
    WITA   => '+0800',
    WST    => undef,
    WTZ    => '-0100',
    WUT    => '+0100',
    X      => '-1100',
    Y      => '-1200',
    YAKST  => '+1000',
    YAKT   => '+0900',
    YAPT   => '+1000',
    YDT    => '-0800',
    YEKST  => '+0600',
    YEKT   => '+0500',
    YST    => '-0900',
    Z      => '+0000',
    UTC    => '+0000',
};

const our $OFFSET => { map { $_ => abs $TIMEZONE->{$_} >= 100 ? ( int( abs $TIMEZONE->{$_} / 100 ) * 60 + abs( $TIMEZONE->{$_} ) % 100 ) / ( $TIMEZONE->{$_} < 0 ? -1 : 1 ) : $TIMEZONE->{$_} } grep { defined $TIMEZONE->{$_} } keys $TIMEZONE->%* };

const our $STRPTIME_TOKEN => {
    a => [    # the abbreviated weekday name ('Sun')
        '(?i:' . join( q[|], $WEEKDAY_ABBR->@* ) . ')',
    ],
    A => [    # the full weekday  name ('Sunday')
        '(?i:' . join( q[|], sort $WEEKDAY->@* ) . ')',
    ],
    b => [    # the abbreviated month name ('Jan')
        '((?i:' . join( q[|], sort $MONTH_ABBR->@* ) . '))',
        '\$args{month} = \$MONTH_ABBR_NUM->{lc $1}',
    ],
    B => [    # the full  month  name ('January')
        '((?i:' . join( q[|], sort $MONTH->@* ) . '))',
        '\$args{month} = \$MONTH_NUM->{lc $1}',
    ],
    d => [    # day of the month (01..31)
        '(\d\d)',
        '\$args{day} = \$1',
    ],
    e => [    # day of the month without leading zeroes (1..31)
        '(\d\d?)',
        '\$args{day} = \$1',
    ],
    H => [    # hour of the day, 24-hour clock (00..23)
        '(\d\d)',
        '\$args{hour} = \$1',
    ],
    m => [    # month of the year (01..12)
        '(\d\d?)',
        '\$args{month} = \$1',
    ],
    M => [    # minute of the hour (00..59)
        '(\d\d)',
        '\$args{minute} = \$1',
    ],
    S => [    # second of the minute (00..60)
        '(\d\d)',
        '\$args{second} = \$1',
    ],
    y => [    # year without a century (00..99)
        '(\d\d)',
        '\$args{year} = \( $1 + ( $1 >= 69 ? 1900 : 2000 ) )',
    ],
    Y => [    # year with century
        '(\d\d\d\d)',
        '\$args{year} = \$1',
    ],
    Z => [    # time zone name
        '((?i:' . join( q[|], sort { length $b <=> length $a } grep { defined $OFFSET->{$_} } keys $OFFSET->%* ) . '))',
        '\$args{offset} = \$OFFSET->{uc $1}',
    ],
    z => [    # +/-hhmm, +/-hh:mm
        '([+-])(\d\d):?(\d\d)',
        '\$args{offset} = \( ($2 * 60 + $3) / ($1 eq q[-] ? -1 : 1) )',
    ],
};

our $CACHE = {};

sub from_strptime ( $self, $str, $pattern, $use_cache = 1 ) {
    return $CACHE->{$pattern}->($str) if $use_cache and $CACHE->{$pattern};

    return $self->_strptime_compile_pattern( $pattern, $use_cache )->($str);
}

sub expand_strptime_re ( $self, $re ) {
    state $split_re = qr/%([@{[ join q[|], keys $STRPTIME_TOKEN->%* ]}])/sm;

    my $expanded_re;

    for my $token ( split $split_re, $re ) {
        if ( !exists $STRPTIME_TOKEN->{$token} ) {
            $expanded_re .= $token;
        }
        else {
            state $cache = {};

            $cache->{$token} //= $STRPTIME_TOKEN->{$token}->[0] =~ s/[(](?![?])/(?:/smrg;

            $expanded_re .= $cache->{$token};
        }
    }

    return $expanded_re;
}

sub _strptime_compile_pattern ( $self, $pattern, $use_cache = 1 ) {
    state $split_re = qr/%([@{[ join q[|], keys $STRPTIME_TOKEN->%* ]}])/sm;

    return $CACHE->{$pattern} if $use_cache and $CACHE->{$pattern};

    my $re;

    my $match_id = 0;

    my $sub;

    for my $token ( split $split_re, $pattern ) {
        if ( !exists $STRPTIME_TOKEN->{$token} ) {
            $re .= $token;
        }
        else {
            $re .= $STRPTIME_TOKEN->{$token}->[0];

            if ( $STRPTIME_TOKEN->{$token}->[1] ) {
                my $code = $STRPTIME_TOKEN->{$token}->[1];

                my $id = 1;

              NEXT: if ( $code =~ /\$$id/sm ) {
                    $code =~ s/\$$id/\$match[$match_id]/smg;

                    $id++;

                    $match_id++;

                    goto NEXT;
                }

                $sub .= "        $code;\n";
            }
        }
    }

    $sub = <<"PERL";
sub ( \$str ) {
    if ( my \@match = \$str =~ m[$re]sm ) {
        my \%args;

$sub
        return \$self->new( \%args );
    }
    else {
        die q[Strftime pattern does not match];
    }
};
PERL

    $sub = eval $sub || die;    ## no critic qw[BuiltinFunctions::ProhibitStringyEval]

    $CACHE->{$pattern} = $sub if $use_cache;

    return $sub;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 369, 373, 377, 381,  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## |      | 385, 389, 393, 397,  |                                                                                                                |
## |      | 401, 405, 409, 413   |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 408                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Date::Strptime

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
