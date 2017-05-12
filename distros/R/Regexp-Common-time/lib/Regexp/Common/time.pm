=head1 NAME

Regexp::Common::time - Date and time regexps.

=cut

use strict;
use warnings;

package Regexp::Common::time;
$Regexp::Common::time::VERSION = '0.07';
use Regexp::Common qw(pattern);
use POSIX;

sub _croak { require Carp; goto &Carp::croak}

my $can_locale;
my $can_posix;
BEGIN
{
    eval
    {
        $can_posix = 0;
        require POSIX;
        $can_posix = 1;
    };
    eval
    {
        $can_locale = 0;
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo));
        $can_locale = 1;
    };
}

# Master list of patterns
our %master
    = (
       c2   => q/\d{2}/,                                      # Century, 2 digits
       yr2  => q/\d{2}/,                                      # Year, 2 digits
       yr4  => q/\d{4}/,                                      # Year, 4 digits
       yr24 => q/(?:\d{2}(?:\d{2})?)/,                        # Year, 2 or 4 digits
       mo2  => q/(?:(?=[01])(?:0[1-9]|1[012]))/,              # Month, 2 digits
       mo12 => q/(?:0[1-9]|1[012]|(?<!\d)[1-9])/,             # Month, 1 or 2 digits
       mo_2 => q/(?:(?=[ 1])(?: [1-9]|1[012]))/,              # Month, 2 places, leading space
       dy2  => q/(?:(?=[0123])(?:0[1-9]|[12]\d|3[01]))/,      # Day, 2 digits
       dy12 => q/(?:0[1-9]|[12]\d|3[01]|(?<!\d)[1-9])/,       # Day, 1 or 2 digits
       dy_2 => q/(?:(?=[ 123])(?: [1-9]|[12]\d|3[01]))/,      # Day, 2 places, leading space
       doy3 => q/(?:(?=[0-3])(?:00[1-9]|0[1-9]\d|[12]\d\d|3(?:[0-5]\d|6[0-6])))/, # Day of year, 3 digits
       hr2  => q/(?:(?=[012])(?:[01]\d|2[0123]))/,            # Hour, 00-23, 2 digits
       hr12 => q/(?:(?=\d)(?:[01]\d|2[0123]|(?<!\d)\d))/,     # Hour, 0-23, 1 or 2 digits
       hr_2 => q/(?:(?=[ 12])(?:[ 1]\d|2[0123]))/,            # Hour,  0-23, 2 places, ld sp
       hx2  => q/(?:(?=[01])(?:0[1-9]|1[012]))/,              # Hour, 01-12, 2 digits
       hx12 => q/(?:(?=\d)(?:0[1-9]|1[012]|(?<!\d)[1-9]))/,   # Hour, 1-12, 1 or 2 digits
       hx_2 => q/(?:(?=[ 1])(?: [1-9]|1[012]))/,              # Hour,  1-12, 2 places, ld sp
       mi2  => q/(?:[0-5]\d)/,                                # Minute, 2 digits
       mi12 => q/(?:[0-5]\d|(?<!\d)\d)/,                      # Minute, 1 or 2 digits
       mi_2 => q/(?:[ 1-5]\d)/,                               # Minute, 2 places, leading sp
       sc2  => q/(?:(?=[0-6])(?:[0-5]\d|6[01]))/,             # Second, 2 digits, 00-61
       sc12 => q/(?:(?=[0-6])(?:[0-5]\d|6[01]|(?<!\d)\d))/,   # Second, 1 or 2 digits, 0-61
       sc_2 => q/(?:(?=[ 1-6])(?:[ 1-5]\d|6[01]))/,           # Second, 2 places,  0-61, ld sp
       wn2  => q/(?:(?=[0-5])(?:0[1-9]|[1-4]\d|5[0-3]))/,     # Week number, 2 digits, 01-53
       wnx2 => q/(?:(?=[0-5])(?:[0-4]\d|5[0-3]))/,            # Week number, 2 digits, 00-53
       wd1  => q/[0-6]/,                                      # Weekday number, 1 digit, 0-6
       wdx1 => q/[1-7]/,                                      # Weekday number, 1 digit, 1-7
       msec => q/\d{3}/,                                      # millisecond
       usec => q/\d{6}/,                                      # microsecond
       ampm => q/(?:(?=[AaPp])(?:[ap](?:m|\.m\.)?|[AP](?:M|\.M\.)?))/,    # am/pm indicator
       th   => q/(?:(?=[SNRTsnrt])(?:st|ST|nd|ND|rd|RD|th|TH))/,   # ordinal suffix
       tz   => q/(?:[-+](?:[01]\d|2[0-4])(?::?[0-5]\d)?|Z|GMT|UTC?|[ECMP][DS]T)/,    # Time zone
       ema  => _get_abbr_month_pattern(1),                    # English month abbreviation

       # The following are locale-specific, and will be populated later
       mname => q/TBD/,     # Full month name
       mabbr => q/TBD/,     # Month abbreviation
       dname => q/TBD/,     # Full weekday name
       dabbr => q/TBD/,     # Weekday abbreviation
       axpx  => q/TBD/,     # locale-specific AM/PM indicator
      );

my $npd  = q/(?<!\d)/;    # "No preceeding digit"
my $nfd  = q/(?!\d)/;     # "No following digit"
my $sdig = $npd . q/[1-9]/ . $nfd;     # One single digit (used for months and days)

sub _nospace
{
    my $s = shift;
    $s =~ s/([\x20\x09])/sprintf '\\x%02x', ord $1/eg;
    return $s;
}

my $anymon;   # general-purpose month capture.  Set in _setup_locale().

my $d = qq/$sdig|$master{dy2}/;
my $dcap  = qq/(?k:$d)/;

# Separator pattern: allows for certain punctuation, or none, plus optional space.
my $dsep = _nospace q{[-/. ]};

# "Middle" day.  Must be surrounded by matching separators
my $dmiddle  = _nospace qq{(?=(?>/$master{dy12}/|-$master{dy12}-| $master{dy12},? |\\.$master{dy12}\\.|(?!$dsep)$master{dy12}(?!$dsep)))$dsep?(?k:$master{dy12}),?$dsep?};
my $d2middle = _nospace qq{(?=(?>/$master{dy2}/|-$master{dy2}-| $master{dy2},? |\\.$master{dy2}\\.|(?!$dsep)$master{dy2}(?!$dsep)))$dsep?(?k:$master{dy2}),?$dsep?};

# "Middle" month.  Must be surrounded by matching separators
my $mFULLmiddle;   # Full month pattern, in middle (ymd and dmy).  Set in _setup_locale().
my $m2middle = _nospace qq{(?=(?>/$master{mo2}/|-$master{mo2}-| $master{mo2} |\\.$master{mo2}\\.|$master{mo2}(?!$dsep)))$dsep?(?k:$master{mo2})$dsep?};

# "Middle" minute.  Must be surrounded by matching separators
my $tsep = _nospace q/[:. ]/;
my $min2middle = _nospace qq{(?=(?>:$master{mi2}:|\\.$master{mi2}\\.| $master{mi2} |$master{mi2}(?!$tsep)))$tsep?(?k:$master{mi2})$tsep?};


# YMD builder
sub ymd
{
    my ($self, $flags_hr, $keys_ar) = @_;
    my $pattern = $keys_ar->[1];
    _setup_locale();

    # The second separator character is REQUIRED to be the same as the
    # first for YMD patterns.  Otherwise, "2005/10/21" is ambiguous:
    # it matches "(20)(05)/(10)" and "(2005)/(10)/(21)".

    # 'ymd' is the most flexible: year: 2/4 digits; month 1/2 digits or name; day 1/2 digits.
    if ($pattern eq 'ymd')
    {
        return qq/(?k:$npd(?k:$master{yr24})$mFULLmiddle$dcap$nfd)/;
    }
    # 'y4md': 4-digit year; 1 or 2 digit month and day.  Or named month.
    elsif ($pattern eq 'y4md')
    {
        return qq/(?k:(?k:$master{yr4})$mFULLmiddle$dcap$nfd)/;
    }
    # 'y2md': 2-digit year; 1 or 2 digit month and day.
    elsif ($pattern eq 'y2md')
    {
        return qq/(?k:(?k:$master{yr2})$mFULLmiddle$dcap$nfd)/;
    }
    elsif ($pattern eq 'y4m2d2'  ||  $pattern eq 'YMD')
    {
        return qq/(?k:(?k:$master{yr4})$m2middle(?k:$master{dy2}))/;
    }
    elsif ($pattern eq 'y2m2d2')
    {
        return qq/(?k:(?k:$master{yr2})$m2middle(?k:$master{dy2}))/;
    }

    # Probably the only way to get here is if I goof up and specify this subroutine
    # for a YMD pattern that is not handled above.
    die "Programming error: Unknown y-m-d pattern '$pattern'. Contact Regexp::Common::time author.";
}

# MDY builder
sub mdy
{
    my ($self, $flags_hr, $keys_ar) = @_;
    my $pattern = $keys_ar->[1];
    _setup_locale();

    # The second separator character is REQUIRED to be the same as the
    # first for YMD patterns, for the STRICT versions of these patterns
    # (the ones containing "m2d2").

    # 'mdy' is the most flexible: year: 2/4 digits; month 1/2 digits or named; day 1/2 digits.
    if ($pattern eq 'mdy')
    {
        return qq/(?k:$npd(?k:$anymon)$dmiddle(?k:$master{yr24})$nfd)/;
    }
    # 'mdy4': 4-digit year; 1 or 2 digit month and day.
    elsif ($pattern eq 'mdy4')
    {
        return qq/(?k:$npd(?k:$anymon)$dmiddle(?k:$master{yr4}))/;
    }
    # 'mdy2': 2-digit year; 1 or 2 digit month and day.
    elsif ($pattern eq 'mdy2')
    {
        return qq/(?k:$npd(?k:$anymon)$dmiddle(?k:$master{yr2}))/;
    }
    elsif ($pattern eq 'm2d2y4'  ||  $pattern eq 'MDY')
    {
        return qq/(?k:(?k:$master{mo2})$d2middle(?k:$master{yr4}))/;
    }
    elsif ($pattern eq 'm2d2y2')
    {
        return qq/(?k:(?k:$master{mo2})$d2middle(?k:$master{yr2}))/;
    }

    # Probably the only way to get here is if I goof up and specify this subroutine
    # for a YMD pattern that is not handled above.
    die "Programming error: Unknown m-d-y pattern '$pattern'. Contact Regexp::Common::time author.";
}

# DMY builder
sub dmy
{
    my ($self, $flags_hr, $keys_ar) = @_;
    my $pattern = $keys_ar->[1];
    _setup_locale();

    # The second separator character is REQUIRED to be the same as the
    # first for YMD patterns, for the STRICT versions of these patterns
    # (the ones containing "d2m2").

    # 'dmy' is the most flexible: year: 2/4 digits; month 1/2 digits; day 1/2 digits.
    if ($pattern eq 'dmy')
    {
        return qq/(?k:$npd$dcap$mFULLmiddle(?k:$master{yr24})$nfd)/;
    }
    # 'mdy4': 4-digit year; 1 or 2 digit month and day.
    elsif ($pattern eq 'dmy4')
    {
        return qq/(?k:$npd$dcap$mFULLmiddle(?k:$master{yr4}))/;
    }
    # 'y2md': 2-digit year; 1 or 2 digit month and day.
    elsif ($pattern eq 'dmy2')
    {
        return qq/(?k:$npd$dcap$mFULLmiddle(?k:$master{yr2}))/;
    }
    elsif ($pattern eq 'd2m2y4'  ||  $pattern eq 'DMY')
    {
        return qq/(?k:(?k:$master{dy2})$m2middle(?k:$master{yr4}))/;
    }
    elsif ($pattern eq 'd2m2y2')
    {
        return qq/(?k:(?k:$master{dy2})$m2middle(?k:$master{yr2}))/;
    }

    # Probably the only way to get here is if I goof up and specify this subroutine
    # for a YMD pattern that is not handled above.
    die "Programming error: Unknown d-m-y pattern '$pattern'. Contact Regexp::Common::time author.";
}

# HMS builder
sub hms
{
    my $hr     = $npd . q/[01]\d|2[0-4]|\d/;
    my $sec    = q/\d\d/;      # Can't limit it to 00-59!  Because it's optional, and out-of-range = no match.

#   my ($self, $flags_hr, $keys_ar) = @_;
    return qq/(?k:$npd(?k:$master{hr12})$tsep/      # hour
        .  qq/(?k:$master{mi2})/                    # minute
        .  qq/(?:$tsep(?k:$sec))?/                          # second
        .  qq/(?:\\s?(?k:$master{ampm}))?)/;        # am/pm
}

# Time::Format-like builder

my %tf =
    (
     yyyy   => $master{yr4},
     yy     => $master{yr2},
    'm{on}' => $master{mo12},
    'mm{on}'=> $master{mo2},
    '?m{on}'=> $master{mo_2},
     d      => $master{dy12},
     dd     => $master{dy2},
    '?d'    => $master{dy_2},
     h      => $master{hr12},
     hh     => $master{hr2},
    '?h'    => $master{hr_2},
     H      => $master{hx12},
     HH     => $master{hx2},
    '?H'    => $master{hx_2},
    'm{in}' => $master{mi12},
    'mm{in}'=> $master{mi2},
    '?m{in}'=> $master{mi_2},
     s      => $master{sc12},
     ss     => $master{sc2},
    '?s'    => $master{sc_2},
     mmm    => $master{msec},
     uuuuuu => $master{usec},
     am     => $master{ampm},
     AM     => $master{ampm},
    'a.m.'  => $master{ampm},
    'A.M.'  => $master{ampm},
     pm     => $master{ampm},
     PM     => $master{ampm},
    'p.m.'  => $master{ampm},
    'P.M.'  => $master{ampm},
     th     => $master{th},
     TH     => $master{th},
     tz     => $master{tz},
    );

my %disam;    # Disambiguator for 'm' format.
$disam{$_} = "{on}" foreach qw/yy d dd ?d/;           # If year or day is nearby, it's 'month'
$disam{$_} = "{in}" foreach qw/h hh ?h H HH ?H s ss ?s/;   # If hour or second is nearby, it's 'minute'
my $disambiguate_pat_1 = qr/
              (?<!\\)          # Must not follow a backslash
              (?=[ydhH])       # Must start with one of these
              (                # $1 begins
                (              # $2 begins.  Capture:
                    yy         #     a year
                  | [dhH]      #     a day or hour
                )
              [^?m\\]*         # Followed by something that's not part of a month
              )
              (?![?m]?m\{[io]n\})   # make sure it's not already unambiguous
              (?!mon)          # don't confuse "mon" with "m" "on"
              ([?m]?m)         # $3 is a month code
             /x;

my $disambiguate_pat_2 = qr/
              (?<!\\)         # ignore things that begin with backslash
              ([?m]?m)        # $1 is a month code
              (               # $2 begins.
                 [^a-zA-Z]*   #     any number of non-alphas
                 (?<!\\)      #     no backslash
                 (?=[?dsy])   #     Next char must be one of these
                 (            #     $3 begins.  Capture:
                    \??[ds]   #         a day or a second
                  | yy        #         or a year
                 )
              )/x;

# The Big Date/Time Pattern
my $bigpat = qr/
              (?<!\\)                      # Don't expand something preceded by backslash
              (?=[dDy?hHsaApPMmWwutT])     # Jump to one of these characters
              (
                 [Dd]ay|DAY                # Weekday abbreviation
              |  yy(?:yy)?                 # Year
              |  [?m]?m\{[oi]n\}           # Unambiguous month-minute codes
              |  th | TH                   # day suffix
              |  [?d]?d                    # Day
              |  [?h]?h                    # Hour (24)
              |  [?H]?H                    # Hour (12)
              |  [?s]?s                    # Second
              |  [apAP]\.?[mM]\.?          # am and pm strings
              |  [Mm]on(?:th)?|MON(?:TH)?  # Month names and abbrev
              |  [Ww]eekday|WEEKDAY        # Weekday names
              |  mmm|uuuuuu                # millisecond and microsecond
              |  tz                        # time zone
               )/x;

sub tf_builder
{
    my ($self, $flags_hr, $keys_ar) = @_;

    # User must specify *something* as the pattern
    _croak q{Mandatory "-pat" flag missing in tf pattern}
        if !exists $flags_hr->{-pat};

    my $pattern  = $flags_hr->{-pat};

    # Localize
    _setup_locale();

    # Copying from Time::Format...
    # "Guess" how to interpret ambiguous 'm'
    $pattern =~ s/$disambiguate_pat_1/$1$3$disam{$2}/gx;
    $pattern =~ s/$disambiguate_pat_2/$1$disam{$3}$2/gx;

    # If the pattern contains any parentheses, then the caller is
    # responsible for doing all the captures.
    if ($pattern =~ /(?<!\\)(?:\\\\)*\(/)   # even number of backslashes
    {
        $pattern =~ s/$bigpat/$tf{$1}/gx;
    }
    else        # we'll handle the capturing
    {
        $pattern =~ s/$bigpat/(?k:$tf{$1})/gx;
        $pattern = "(?k:$pattern)";
    }

    return $pattern;
}

# strftime builder
my %strftime =
    (
     C => $master{c2},     # two-digit century
     D =>"$master{mo2}/$master{dy2}/$master{yr2}",
     d => $master{dy2},    # two-digit day
     e => $master{dy_2},   # 1 or 2-digit day, leading space
     H => $master{hr2},    # hour, 00-23
     I => $master{hx2},    # hour, 01-12
     j => $master{doy3},   # day-of-year, 001-366
     m => $master{mo2},    # month, 01-12
     M => $master{mi2},    # minute, 00-59
     n => "\n",
     R =>"$master{hr2}:$master{mi2}",
     S => $master{sc2},    # Second, 00-61
     T =>"$master{hr2}:$master{mi2}:$master{sc2}",
     t => "\t",
     u => $master{wdx1},   # Weekday number, 1-7
     U => $master{wnx2},   # Week number, 00-53
     V => $master{wn2},    # Week number, 01-53
     w => $master{wd1},    # Weekday number, 0-6
     W => $master{wnx2},   # Week number, 00-53
     y => $master{yr2},    # two-digit year
     Y => $master{yr4},    # four-digit year
     Z => $master{tz},     # time zone
    '%' => '%',

     # additional useful patterns not specified by strftime
     _d => $master{dy12},  # 1- or 2-digit day number
     _H => $master{hr12},  # 1- or 2-digit 24-hour hour
     _I => $master{hx12},  # 1- or 2-digit 12-hour hour
     _m => $master{mo12},  # 1- or 2-digit month number
     _M => $master{mi12},  # 1- or 2-digit minute
   );

sub strftime_builder
{
    my ($self, $flags_hr, $keys_ar) = @_;

    # User must specify *something* as the pattern
    _croak q{Mandatory "-pat" flag missing in strftime pattern}
        if !exists $flags_hr->{-pat};

    my $pattern  = $flags_hr->{-pat};

    # Localize
    _setup_locale();

    # If the pattern contains any parentheses, then the caller is
    # responsible for doing all the captures.
    if ($pattern =~ /(?<!\\)(?:\\\\)*\(/)   # even number of backslashes
    {
        $pattern =~ s/(?<!\\)   %(_?.)   /$strftime{$1}/gx;
    }
    else        # we'll handle the capturing
    {
        # If the pattern consists of a single pattern, then
        # the enclosing (?k:) is redundant and annoying.
        my $solo = $pattern =~ /\A                 # Start of user's pattern
                                (?:
                                    \\b            # a word break
                                  |
                                    \\A            # Start of string
                                  |
                                    \^             # Start of string
                                  |
                                    \(\?[^\)]*\)   # Some other zero-width assertion
                                )*                 # (any number of such assertions)
                                %_?.        # The meat of the user's actual pattern
                                (?:
                                    \\b            # word break
                                  |
                                    \\z            # REAL end of string
                                  |
                                    \\Z            # end of string
                                  |
                                    \$             # end of line or string
                                  |
                                    \(\?[^\)]*\)   # some other assertion
                                )*
                                \z    # Actual end of user's pattern
                                /x;
        $pattern =~ s/(?<!\\)   %(_?.)   /(?k:$strftime{$1})/gx;
        $pattern = "(?k:$pattern)"  unless $solo;
    }

    return $pattern;
}

sub american
{
    my ($self, $flags_hr, $keys_ar) = @_;
    _setup_locale();

    return join '',
           qq/(?k:\\b/,           # must start on word boundary
           qq/(?k:$master{mname}|$master{mabbr})/,   # Month name or abbr
           qq/ {1,2}/,            # one or two spaces
           qq/(?k:$master{dy12})/,      # one- or two-digit day
           qq/(?:,| |, )/,        # Comma or space or both
           qq/(?k:'$master{yr2}|$master{yr24})/,     # Year: 'yy or yyyy or yy
           qq/$nfd)/;             # No following digits
}



# Localization.
# Bug: This is bulky and inefficient, and sets up many patterns that may never be used.
# On the other hand, it's generally only ever called once.
my $latest_setup_locale;
sub _setup_locale
{
    # Do nothing if locale has not changed since we set it up
    my $current_locale;
    $current_locale = $can_posix?  POSIX::setlocale(POSIX::LC_TIME())  :  q{};
    $current_locale = q{} if  !defined $current_locale;

    # No changes needed
    return if defined $latest_setup_locale
           &&  $latest_setup_locale eq $current_locale;

    $latest_setup_locale = $current_locale;

    my $dt_fmt;      # locale-specific date/time format
    my $d_fmt;       # locale-specific date format
    my $t_fmt;       # locale-specific time format
    my $t_ap_fmt;    # locale-specific time with am/pm format
    my $am_str;      # locale-specific ante-meridian string
    my $pm_str;      # locale-specific post-meridian string

    if ($can_locale)
    {
        eval
        {
            ($dt_fmt, $d_fmt, $t_fmt, $t_ap_fmt) = map langinfo($_),
                (
                 I18N::Langinfo::D_T_FMT(),
                 I18N::Langinfo::D_FMT(),
                 I18N::Langinfo::T_FMT(),
                 I18N::Langinfo::T_FMT_AMPM(),
                );
            ($am_str, $pm_str) = map langinfo($_),
                (
                 I18N::Langinfo::AM_STR(),
                 I18N::Langinfo::PM_STR(),
                );

        };
    }
    if (!$can_locale  ||  $@)    # Internationalization didn't work for some reason
    {
        $dt_fmt   = q{%a %b %e %H:%M:%S %Y};
        $d_fmt    = q{%m/%d/%y};
        $t_fmt    = q{%H:%M:%S};
        $t_ap_fmt = q{%I:%M:%S %p};
        $am_str   = q{AM};
        $pm_str   = q{PM};
    }

    # Update master patterns
    $master{dname} = _get_full_weekday_pattern();
    $master{dabbr} = _get_abbr_weekday_pattern();
    $master{mname} = _get_full_month_pattern();
    $master{mabbr} = _get_abbr_month_pattern();
    $master{axpx}  = qq/(?:\Q$am_str\E|\Q$pm_str\E)/;

    # Pattern variables for dmy-mdy-ymd patterns
    $anymon = _nospace qq/(?>(?i)$master{mo2}|$sdig|$master{mname}|$master{mabbr})/;
    $mFULLmiddle = _nospace qq{(?=(?>/$anymon/|-$anymon-| $anymon |\\.$anymon\\.|(?!$dsep)$anymon(?!$dsep)))$dsep?(?k:$anymon)$dsep?};

    # Pattern variables for Time::Format
    $tf{Weekday} = $tf{WEEKDAY} = $tf{weekday} = $master{dname};
    $tf{Day}     = $tf{DAY}     = $tf{day}     = $master{dabbr};
    $tf{Month}   = $tf{MONTH}   = $tf{month}   = $master{mname};
    $tf{Mon}     = $tf{MON}     = $tf{mon}     = $master{mabbr};

    # Pattern variables for strftime
    $strftime{A} = $master{dname};
    $strftime{a} = $master{dabbr};
    $strftime{B} = $master{mname};
    $strftime{b} = $master{mabbr};
    $strftime{h} = $strftime{b};    # defined synonym
    $strftime{r} ="$master{hx2}:$master{mi2}:$master{sc2} (?:$am_str|$pm_str)",

    # Set up locale-dependent strftime patterns
    $strftime{p} = $master{axpx};
    foreach ($dt_fmt, $d_fmt, $t_fmt, $t_ap_fmt)
    {
        # the "|| q{}" below is to avoid "uninitialized" warnings.
        s/%(.)/$strftime{$1} || q{}/eg;
    }
    $strftime{c} = _nospace $dt_fmt;
    $strftime{r} = _nospace $t_ap_fmt;
    $strftime{x} = _nospace $d_fmt;
    $strftime{X} = _nospace $t_fmt;
}

sub _first_chars
{
    my %uniq = map {substr ($_,0,1) => 1} @_;
    return join q{}, map quotemeta, keys %uniq;
}

sub _get_full_month_pattern
{
    my @Mon_Name;
    if ($can_locale)
    {
        eval
        {
            @Mon_Name = map langinfo($_),
                (
                 I18N::Langinfo::MON_1(),
                 I18N::Langinfo::MON_2(),
                 I18N::Langinfo::MON_3(),
                 I18N::Langinfo::MON_4(),
                 I18N::Langinfo::MON_5(),
                 I18N::Langinfo::MON_6(),
                 I18N::Langinfo::MON_7(),
                 I18N::Langinfo::MON_8(),
                 I18N::Langinfo::MON_9(),
                 I18N::Langinfo::MON_10(),
                 I18N::Langinfo::MON_11(),
                 I18N::Langinfo::MON_12(),
                );
        };
    }
    if (!$can_locale  ||  $@)
    {
        @Mon_Name = qw(January February March April May June July August September October November December);
    }

    my $prematch = _first_chars(@Mon_Name);
    my $alternat = join '|', map quotemeta, @Mon_Name;
    return qq/(?=[$prematch])(?>$alternat)/;
}

sub _get_abbr_month_pattern
{
    my $english_only = shift;
    my @Mon_Abbr;
    if (!$english_only  &&  $can_locale)
    {
        eval
        {
            @Mon_Abbr = map langinfo($_),
                (
                 I18N::Langinfo::ABMON_1(),
                 I18N::Langinfo::ABMON_2(),
                 I18N::Langinfo::ABMON_3(),
                 I18N::Langinfo::ABMON_4(),
                 I18N::Langinfo::ABMON_5(),
                 I18N::Langinfo::ABMON_6(),
                 I18N::Langinfo::ABMON_7(),
                 I18N::Langinfo::ABMON_8(),
                 I18N::Langinfo::ABMON_9(),
                 I18N::Langinfo::ABMON_10(),
                 I18N::Langinfo::ABMON_11(),
                 I18N::Langinfo::ABMON_12(),
                );
        };
    }
    if ($english_only  ||  !$can_locale  ||  $@)
    {
        @Mon_Abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    }

    my $prematch = _first_chars(@Mon_Abbr);
    my $alternat = join '|', map quotemeta, @Mon_Abbr;
    return qq/(?=[$prematch])(?>$alternat)/;
}

sub _get_full_weekday_pattern
{
    my @Day_Name;
    if ($can_locale)
    {
        eval
        {
            @Day_Name = map langinfo($_),
                (
                 I18N::Langinfo::DAY_1(),
                 I18N::Langinfo::DAY_2(),
                 I18N::Langinfo::DAY_3(),
                 I18N::Langinfo::DAY_4(),
                 I18N::Langinfo::DAY_5(),
                 I18N::Langinfo::DAY_6(),
                 I18N::Langinfo::DAY_7(),
                );
        };
    }
    if (!$can_locale  ||  $@)
    {
        @Day_Name = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    }

    my $prematch = _first_chars(@Day_Name);
    my $alternat = join '|', map quotemeta, @Day_Name;
    return qq/(?=[$prematch])(?>$alternat)/;
}

sub _get_abbr_weekday_pattern
{
    my $english_only = shift;
    my @Day_Abbr;
    if (!$english_only  &&  $can_locale)
    {
        eval
        {
            @Day_Abbr = map langinfo($_),
                (
                 I18N::Langinfo::ABDAY_1(),
                 I18N::Langinfo::ABDAY_2(),
                 I18N::Langinfo::ABDAY_3(),
                 I18N::Langinfo::ABDAY_4(),
                 I18N::Langinfo::ABDAY_5(),
                 I18N::Langinfo::ABDAY_6(),
                 I18N::Langinfo::ABDAY_7(),
                );
        };
    }
    if ($english_only  ||  !$can_locale  ||  $@)
    {
        @Day_Abbr = qw(Sun Mon Tue Wed Thu Fri Sat);
    }

    my $prematch = _first_chars(@Day_Abbr);
    my $alternat = join '|', map quotemeta, @Day_Abbr;
    return qq/(?=[$prematch])(?>$alternat)/;
}

# Set up all the patterns

for (qw(ymd y4md y2md y4m2d2 y2m2d2 YMD))
{
    pattern name   => ['time', $_],
            create => \&ymd,
}

for (qw(mdy mdy4 mdy2 m2d2y4 m2d2y2 MDY))
{
    pattern name   => ['time', $_],
            create => \&mdy,
}

for (qw(dmy dmy4 dmy2 d2m2y4 d2m2y2 DMY))
{
    pattern name   => ['time', $_],
            create => \&dmy,
}

for (qw(hms))
{
    pattern name   => ['time', $_],
            create => \&hms,
}

for (qw(strftime))
{
    pattern name   => ['time', $_],
            create => \&strftime_builder,
}

for (qw(tf))
{
    pattern name   => ['time', $_],
            create => \&tf_builder,
}
for (qw(american))
{
    pattern name   => ['time', $_],
            create => \&american,
}


my $dt_sep = q/(?:(?<=\\d)[T_ ](?=\\d))?/;
pattern name => ['time', 'iso'],
        create => join '',
    qq/(?k:/,
    qq/(?=\\d)/,     # Expect a digit
    qq/(?:/,         # Begin optional date portion
        qq/(?k:$master{yr4})/,   $m2middle,   qq/(?k:$master{dy2})/,
    qq/)?/,          # End optional date portion
    $dt_sep,
    qq/(?:/,         # Begin optional time portion
        qq/(?k:$master{hr2})/,  $min2middle,  qq/(?k:$master{sc2})/,
    qq/)?)/;         # End optional time portion

pattern name => ['time', 'mail'],
    create => join '',
                   qq/(?k:$npd/,    # No preceeding digit
                   qq/(?=\\d)/,     # Expect a digit
                   qq/(?k:$master{dy12})\\s*/,     # Day
                   qq/(?k:$master{ema})\\s*/,      # Month (english name abbreviation)
                   qq/(?k:$master{yr24})\\s+/,     # Year
                   qq/(?k:$master{hr2}):/,         # Hour
                   qq/(?k:$master{mi2}):/,         # Minute
                   qq/(?k:$master{sc2})\\s*/,      # Second
                   qq/(?k:$master{tz})/,           # Time zone
                   qq/$nfd)/;       # No trailing digit

pattern name => ['time', 'MAIL'],
    create => join '',
                   qq/(?k:$npd/,    # No preceeding digit
                   qq/(?=\\d)/,     # Expect a digit
                   qq/(?k:$master{dy12})\\s*/,     # Day
                   qq/(?k:$master{ema})\\s*/,      # Month (english name abbreviation)
                   qq/(?k:$master{yr4})\\s+/,      # Year
                   qq/(?k:$master{hr2}):/,         # Hour
                   qq/(?k:$master{mi2}):/,         # Minute
                   qq/(?k:$master{sc2})\\s*/,      # Second
                   qq/(?k:[-+]\\d{4})/,            # Time zone
                   qq/$nfd)/;       # No trailing digit


1;
__END__

=head1 SYNOPSIS

 use Regexp::Common qw(time);

 # Piecemeal, Time::Format-like patterns
 $RE{time}{tf}{-pat => 'pattern'}

 # Piecemeal, strftime-like patterns
 $RE{time}{strftime}{-pat => 'pattern'}

 # Match ISO8601-style date/time strings
 $RE{time}{iso}

 # Match RFC2822-style date/time strings
 $RE{time}{mail}
 $RE{time}{MAIL}    # more-strict matching

 # Match informal American date strings
 $RE{time}{american}

 # Fuzzy date patterns
 #               YEAR/MONTH/DAY
 $RE{time}{ymd}         # Most flexible
 $RE{time}{YMD}         # Strictest (equivalent to y4m2d2)
                 # Other available patterns: y2md, y4md, y2m2d2, y4m2d2

 #               MONTH/DAY/YEAR  (American style)
 $RE{time}{mdy}         # Most flexible
 $RE{time}{MDY}         # Strictest (equivalent to m2d2y4)
                 # Other available patterns: mdy2, mdy4, m2d2y2, m2d2y4

 #               DAY/MONTH/YEAR  (European style)
 $RE{time}{mdy}         # Most flexible
 $RE{time}{MDY}         # Strictest (equivalent to d2m2y4)
                 # Other available patterns: dmy2, dmy4, d2m2y2, d2m2y4

 # Fuzzy time pattern
 #               HOUR/MINUTE/SECOND
 $RE{time}{hms}    # H: matches 1 or 2 digits; 12 or 24 hours
                   # M: matches 2 digits.
                   # S: matches 2 digits; may be omitted
                   # May be followed by "a", "am", "p.m.", etc.


=head1 DESCRIPTION

This module creates regular expressions that can be used for parsing
dates and times.  See L<Regexp::Common> for a general description of
how to use this interface.

Parsing dates is a dirty business. Dates are generally specified in
one of three possible orders: year/month/day, month/day/year, or
day/month/year.  Years can be specified with four digits or with two
digits (with assumptions made about the century).  Months can be
specified as one digit, two digits, as a spelled-out name, or as a
three-letter abbreviation.  Day numbers can be one digit or two
digits, with limits depending on the month (and, in the case of
February, even the year).  Also, different people use different
punctuation for separating the various elements.

A human can easily recognize that "October 21, 2005" and "21.10.05"
refer to the same date, but it's tricky to get a program to come to
the same conclusion.  This module attempts to make it possible to do
so, with a minimum of difficulty.

=over 4

=item *

If you know the exact format of the data to be matched, use one of the
specific, piecemeal pattern builders: C<tf> or C<strftime>.

=item *

If you are parsing RFC-2822 mail headers, use the C<mail> pattern.

=item *

If you are parsing informal American dates, use the C<american> pattern.

=item *

If there is some variability in your input data, use one of the
fuzzy-matching patterns in the C<dmy>, C<mdy>, or C<ymd> families.

=item *

If the data are wildly variable, such as raw user input, you should
probably give up and use L<Date::Manip> or L<Date::Parse>.

=back

Time values are generally much simpler to parse than date values.
Only one fuzzy pattern is provided, and it should suffice for most
needs.

=head1 Time::Format PATTERNS

The L<Time::Format> module uses simple, intuitive strings for
specifying date and time formats.  You can use these patterns here as
well.  See L<Time::Format> for details about its format specifiers.

I<Example:>

    $str = 'Thu November 2, 2005';
    $str =~ $RE{time}{tf}{-pat => 'Day Month d, yyyy'};

The patterns can contain more complex regexp expressions as well:

    $str =~ $RE{time}{tf}{-pat => '(Weekday|Day) (Month|Mon) d, yyyy'};

Time zone matching (the C<tz> format code) attempts to adhere to RFC2822
and ISO8601 as much as possible.  The following time zones are matched:

    Z
    UT        UTC
    +hh:mm    -hh:mm
    +hhmm     -hhmm
    +hh       -hh
    GMT   EST EDT   CST CDT   MST MDT   PST PDT

=head1 strftime PATTERNS

The POSIX C<strftime> function is a long-recognized standard for
formatting dates and times.  This module supports most of C<stftime>'s
codes for matching; specifically, the C<aAbBcCDdeHIjmMnprRSTtuUVwWyxXYZ%>
codes.  The C<%Z> format matches time zones in the same manner as
described above under L</Time::Format PATTERNS>.

Also, this module provides the following nonstandard codes:

C<   %_d  -> 1- or 2-digit day number (1-31)

C<   %_H  -> 1- or 2-digit hour (0-23)

C<   %_I  -> 1- or 2-digit hour (1-12)

C<   %_m  -> 1- or 2-digit month number (1-12)

C<   %_M  -> 1- or 2-digit minute (0-59)

I<Example:>

    $str = 'Thu November 2, 2005';
    $str =~ $RE{time}{strftime}{-pat => '%a %B %_d, %Y'};

The patterns can contain more complex regexp expressions as well:

    $str =~ $RE{time}{strftime}{-pat => '(%A|%a)? (%B|%b) ?%_d, %Y'};

=head1 ISO-8601 DATE/TIME MATCHING

The C<$RE{time}{iso}> pattern will match most (all?) strings formatted
as recommended by ISO-8601.  The canonical ISO-8601 form is:

    YYYY-MM-DDTHH:MM:SS

(where "C<T>" is a literal T character).  The C<$RE{time}{iso}>
pattern will match this form, and some variants:

=over 4

=item *

The date separator character may be a hyphen, slash (C</>), period, or
empty string (omitted).  The two date separators must match.

=item *

The time separator character may be a colon, a period, a space, or
empty string (omitted).  The two time separators must match.

=item *

The date-time separator may be a C<T>, an underscore, a space, or
empty string (omitted).

=item *

Either the date or the time may be omitted.  But at least one must be
there.

=item *

If the date is not omitted, all three of its components must be present.

=item *

If the time is not omitted, all three of its components must be present.

=back

=head1 RFC 2822 MATCHING

RFC 2822 specifies the format of date/time values in e-mail message
headers.  In a nutshell, the format is:

    dd Mon yyyy hh:mm:ss +zzzz

where C<dd> is the day of the month; C<Mon> is the abbreviated month
name (apparently always in English); C<yyyy> is the year; C<hh:mm:ss>
is the time; and C<+zzzz> is the time zone, generally specified as an
offset from GMT.

RFC 2822 requires that the weekday also be specified, but this module
ignores the weekday, as it is redundant and only supplied for human
readability.

RFC 2822 requires that older, obsolete date forms be allowed as well;
for example, alphanumeric time zone codes (e.g. EDT).  This module's
C<mail> allows for these obsolete date forms.  If you want to match
only the proper date forms recommended by RFC 2822, you can use the
C<MAIL> pattern instead.

In either case, C<mail> or C<MAIL>, the pattern generated is very
flexible about whitespace.  The main differences are: with C<MAIL>,
two-digit years are not permitted, and the time zone must be four
digits preceded by a + or - sign.

=head1 INFORMAL AMERICAN MATCHING

People in North America, particularly in the United States, are fond
of specifying dates as "Month dd, yyyy", or sometimes with a two-digit
year and apostrophe: "Month dd, 'yy".  The C<american> pattern matches
this style of date.  It allows either a month name or abbreviation,
and is flexible with respect to commas and whitespace.

=head1 FUZZY PATTERN OVERVIEW

Fuzzy date patterns have the following properties in common:

=over

=item *

The pattern names consist of the letters C<y>, C<m>, and C<d>, each
optionally followed by a digit (C<2> for C<m> and C<d>; C<2>
or C<4> for C<y>).

=item *

If a C<y> is followed by a 2 or a 4, it must match that many digits.

=item *

If a C<y> has no trailing digit, it can match I<either> 2 or 4 digits,
trying 4 first.

=item *

If an C<m> is followed by a 2, then only two-digit matches for the
month are considered, and month names are not matched.

=item *

If an C<m> is not followed by a 2, then the month may be 1 or 2
digits, or a spelled-out name.

=item *

Just like for months, if a C<d> is followed by a 2, then only
two-digit matches for the day are considered.

=item *

Just like for months, if a C<d> has no trailing digit, then the day
may be 1 or 2 digits, and a 1-digit match may not have any adjacent
digits.

=item *

The uppercase C<DMY>, C<MDY>, and C<YMD> patterns are synonyms for the
strict C<d2m2y4>, C<m2d2y4>, and C<y4m2d2> patterns, respectively.

=item *

If a one-digit match is considered for the month, then no adjacent
digits are allowed.  (e.g.: "1/23/45" in M/D/Y format has a valid
one-digit month match, but "12345" does not.  Nor does "91/23/45").

=item *

If a pattern begins with an digitless C<d>, C<m>, or C<y>, then, in
the string to be matched, any leading digits will cause the pattern to
fail.  For example: C<"012/23/45"> will I<not> match C<$RE{time}{mdy}>.
However, it I<will> match C<$RE{time}{m2d2y2}>.  If you specify an
exact pattern by using C<m2> instead of C<m>, this module assumes you
know what you're doing.

=item *

Likewise, a pattern ending with a digitless C<d> or C<y> will not
match if there are trailing digits in the string.

=back

=head1 FUZZY PATTERN DETAILS

=head2 Year-Month-Day order

=over

=item $RE{time}{ymd}

 "05/4/2"      =~ $RE{time}{ymd};
 "2005-APR-02" =~ $RE{time}{ymd};

This is the most flexible of the numeric-only year/month/day formats.
It matches a date of the form "year/month/day", where the year may be
2 or 4 digits; the month may be 1 or 2 digits or a spelled-out name or
name abbreviation, and the day may be 1 or 2 digits.  The
year/month/day elements may be directly adjacent to each other, or may
be separated by a space, period, slash (C</>), or hyphen.

=item $RE{time}{y4md}

 "2005/4/2"    =~ $RE{time}{y4md};
 "2005 APR 02" =~ $RE{time}{y4md};

This works as L<$RE{time}{ymd}>, except that the year is restricted to
be exactly 4 digits.

=item $RE{time}{y4m2d2}

 "2005/04/02" =~ $RE{time}{y4m2d2};

This works as L<$RE{time}{ymd}>, except that the year is restricted to
be exactly 4 digits, and the month and day must be exactly 2 digits each.

=item $RE{time}{y2md}

 "05/4/2"    =~ $RE{time}{y2md};
 "05.APR.02" =~ $RE{time}{y2md};

This works as L<$RE{time}{ymd}>, except that the year is restricted to
be exactly 2 digits.

=item $RE{time}{y2m2d2}

 "05/04/02" =~ $RE{time}{y2m2d2};

This works as L<$RE{time}{ymd}>, except that the year is restricted to
be exactly 2 digits, and the month and day must be exactly 2 digits each.

=item $RE{time}{YMD}

 "2005/04/02" =~ $RE{time}{YMD};

This is a shorthand for the "canonical" year/month/day format, C<y4m2d2>.

=back

=head2 Month-Day-Year (American) order

=over

=item $RE{time}{mdy}

=item $RE{time}{mdy4}

=item $RE{time}{m2d2y4}

=item $RE{time}{mdy2}

=item $RE{time}{m2d2y2}

=item $RE{time}{MDY}

These patterns function as the equivalent year/month/day patterns,
above; the only difference is the order of the elements.  C<MDY> is a
synonym for C<m2d2y4>.

=back

=head2 Day-Month-Year (European) order

=over

=item $RE{time}{dmy}

=item $RE{time}{dmy4}

=item $RE{time}{d2m2y4}

=item $RE{time}{dmy2}

=item $RE{time}{d2m2y2}

=item $RE{time}{DMY}

These patterns function as the equivalent year/month/day patterns,
above; the only difference is the order of the elements.  C<DMY> is a
synonym for C<d2m2y4>.

=back

=head1 Time pattern (Hour-minute-second)

=over

=item $RE{time}{hms}

 "10:06:12a" =~ /$RE{time}{hms}/;
 "9:00 p.m." =~ /$RE{time}{hms}/;

Matches a time value in a string.

The hour must be in the range 0 to 24.  The minute and second values
must be in the range 0 to 59, and must be two digits (i.e., they must
have leading zeroes if less than 10).

The hour, minute, and second components may be separated by colons
(C<:>), periods, or spaces.

The "seconds" value may be omitted.

The time may be followed by an "am/pm" indicator; that is, one of the
following values:

  a   am   a.m.  p   pm   p.m.   A   AM   A.M.  P   PM   P.M.

There may be a space between the time and the am/pm indicator.

=back

=head1 CAPTURES (-keep)

Under C<-keep>, the C<tf> and C<strftime> patterns capture the entire
match as C<$1>, plus one capture variable for each format specifier.
However, if your pattern contains any parentheses, C<tf> and
C<strftime> will I<not> capture anything additional beyond what you
specify, C<-keep> or not.  In other words: if you use parentheses, you
are responsible for all capturing.

The C<iso> pattern captures:

C<  $1  -> the entire match

C<  $2  -> the year

C<  $3  -> the month

C<  $4  -> the day

C<  $5  -> the hour

C<  $6  -> the minute

C<  $7  -> the second

The year, month, and day (C<$2>, C<$3>, and C<$4>) will be C<undef> if
the matched string contains only a time value (e.g., "12:34:56").  The
hour, minute, and second (C<$5>, C<$6>, and C<$7>) will be C<undef> if
the matched string contains only a date value (e.g., "2005-01-23").


The C<mail> and C<MAIL> patterns capture:

C<  $1  -> the entire match

C<  $2  -> the day

C<  $3  -> the month

C<  $4  -> the year

C<  $5  -> the hour

C<  $6  -> the minute

C<  $7  -> the second

C<  $8  -> the time zone


The C<american> pattern captures:

C<  $1  -> the entire match

C<  $2  -> the month

C<  $3  -> the day

C<  $4  -> the year


The fuzzy y/m/d patterns capture

C<  $1  -> the entire match

C<  $2  -> the year

C<  $3  -> the month

C<  $4  -> the day


The fuzzy m/d/y patterns capture

C<  $1  -> the entire match

C<  $2  -> the month

C<  $3  -> the day

C<  $4  -> the year


The fuzzy d/m/y patterns capture

C<  $1  -> the entire match

C<  $2  -> the day

C<  $3  -> the month

C<  $4  -> the year


The fuzzy h/m/s pattern captures

C<  $1  -> the entire match

C<  $2  -> the hour

C<  $3  -> the minute

C<  $4  -> the second  (C<undef> if omitted)

C<  $5  -> the am/pm indicator (C<undef> if omitted)


=head1 EXAMPLES

 # Typical usage: parsing a data record.
 #
 $rec = "blah blah 2005/10/21 blah blarrrrrgh";
 @date = $rec =~ m{^blah blah $RE{time}{YMD}{-keep}};
 # or
 @date = $rec =~ m{^blah blah $RE{time}{tf}{-pat=>'yyyy/mm/dd'}{-keep}};
 # or
 @date = $rec =~ m{^blah blah $RE{time}{strftime}{-pat=>'%Y/%m/%d'}{-keep}};

 # Typical usage: parsing variable-format data.
 #
 use Time::Normalize;

 $record = "10-SEP-2005";

 # This block tries M-D-Y first, then D-M-Y, then Y-M-D
 my $matched;
 foreach my $pattern (qw(mdy dmy ymd))
 {
     @values = $record =~ /^$RE{time}{$pattern}{-keep}/
         or next;

     $matched = $pattern;
 }
 if ($matched)
 {
     eval{ ($year, $month, $day) = normalize_rct($matched, @values) };
     if ($@)
     {
         .... # handle erroneous data
     }
 }
 else
 {
     .... # no match
 }
 #
 # $day is now 10; $month is now 09; $year is now 2005.


 # Time examples

 $time = '9:10pm';

 @time_data = $time =~ /$RE{time}{hms}{-keep}/;
 # captures '9:10pm', '9', '10', undef, 'pm'

 @time_data = $time =~ /$RE{time}{tf}{-pat => '(h):(mm)(:ss)?(am)?'}{-keep}/;
 # captures '9', '10', undef, 'pm'

=head1 EXPORTS

This module exports no symbols to the caller's namespace.

=head1 SEE ALSO

It's not enough that the date regexps can match various formats.  You
then have to parse those matched data values and translate them into
useful values.  The L<Time::Normalize> module is highly recommended
for performing this repetitive, error-prone task.

=head1 REQUIREMENTS

Requires L<Regexp::Common>, of course.

If L<POSIX> and L<I18N::Langinfo> are available, this module will use
them; otherwise, it will use hardcoded English values for month and
weekday names.

L<Test::More> is required for the test suite.

=head1 AUTHOR / COPYRIGHT

Copyright (c) 2005-2008 by Eric J. Roode, ROODE I<-at-> cpan I<-dot-> org

All rights reserved.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

This module is copyrighted only to ensure proper attribution of
authorship and to ensure that it remains available to all.  This
module is free, open-source software.  This module may be freely used
for any purpose, commercial, public, or private, provided that proper
credit is given, and that no more-restrictive license is applied to
derivative (not dependent) works.

Substantial efforts have been made to ensure that this software meets
high quality standards; however, no guarantee can be made that there
are no undiscovered bugs, and no warranty is made as to suitability to
any given use, including merchantability.  Should this module cause
your house to burn down, your dog to collapse, your heart-lung machine
to fail, your spouse to desert you, or George Bush to be re-elected, I
can offer only my sincere sympathy and apologies, and promise to
endeavor to improve the software.


=cut

