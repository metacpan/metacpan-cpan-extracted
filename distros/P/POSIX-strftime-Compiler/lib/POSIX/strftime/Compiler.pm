package POSIX::strftime::Compiler;

use 5.008001;
use strict;
use warnings;
use Carp;
use Time::Local qw//;
use POSIX qw//;
use base qw/Exporter/;

our $VERSION = "0.42";
our @EXPORT_OK = qw/strftime/;

use constant {
    SEC => 0,
    MIN => 1,
    HOUR => 2,
    DAY => 3,
    MONTH => 4,
    YEAR => 5,
    WDAY => 6,
    YDAY => 7,
    ISDST => 8,
    ISO_WEEK_START_WDAY => 1,  # Monday
    ISO_WEEK1_WDAY      => 4,  # Thursday
    YDAY_MINIMUM        => -366,
};

BEGIN {
    *tzoffset = \&_tzoffset;
    *tzname = \&_tzname;

    if (eval { require Time::TZOffset; 1; }) {
        no warnings 'redefine';
        *tzoffset = \&Time::TZOffset::tzoffset;
    }
}


# copy from POSIX/strftime/GNU/PP.pm and modify
my @offset2zone = qw(
    -1100       0 SST     -1100       0 SST
    -1000       0 HAST    -0900       1 HADT
    -1000       0 HST     -1000       0 HST
    -0930       0 MART    -0930       0 MART
    -0900       0 AKST    -0800       1 AKDT
    -0900       0 GAMT    -0900       0 GAMT
    -0800       0 PST     -0700       1 PDT
    -0800       0 PST     -0800       0 PST
    -0700       0 MST     -0600       1 MDT
    -0700       0 MST     -0700       0 MST
    -0600       0 CST     -0500       1 CDT
    -0600       0 GALT    -0600       0 GALT
    -0500       0 ECT     -0500       0 ECT
    -0500       0 EST     -0400       1 EDT
    -0500       1 EASST   -0600       0 EAST
    -0430       0 VET     -0430       0 VET
    -0400       0 AMT     -0400       0 AMT
    -0400       0 AST     -0300       1 ADT
    -0330       0 NST     -0230       1 NDT
    -0300       0 ART     -0300       0 ART
    -0300       0 PMST    -0200       1 PMDT
    -0300       1 AMST    -0400       0 AMT
    -0300       1 WARST   -0300       1 WARST
    -0200       0 FNT     -0200       0 FNT
    -0200       1 UYST    -0300       0 UYT
    -0100       0 AZOT    +0000       1 AZOST
    -0100       0 CVT     -0100       0 CVT
    +0000       0 GMT     +0000       0 GMT
    +0000       0 WET     +0100       1 WEST
    +0100       0 CET     +0200       1 CEST
    +0100       0 WAT     +0100       0 WAT
    +0200       0 EET     +0200       0 EET
    +0200       0 IST     +0300       1 IDT
    +0200       1 WAST    +0100       0 WAT
    +0300       0 FET     +0300       0 FET
    +030704     0 zzz     +030704     0 zzz
    +0330       0 IRST    +0430       1 IRDT
    +0400       0 AZT     +0500       1 AZST
    +0400       0 GST     +0400       0 GST
    +0430       0 AFT     +0430       0 AFT
    +0500       0 DAVT    +0700       0 DAVT
    +0500       0 MVT     +0500       0 MVT
    +0530       0 IST     +0530       0 IST
    +0545       0 NPT     +0545       0 NPT
    +0600       0 BDT     +0600       0 BDT
    +0630       0 CCT     +0630       0 CCT
    +0700       0 ICT     +0700       0 ICT
    +0800       0 HKT     +0800       0 HKT
    +0845       0 CWST    +0845       0 CWST
    +0900       0 JST     +0900       0 JST
    +0930       0 CST     +0930       0 CST
    +1000       0 PGT     +1000       0 PGT
    +1030       1 CST     +0930       0 CST
    +1100       0 CAST    +0800       0 WST
    +1100       0 NCT     +1100       0 NCT
    +1100       1 EST     +1000       0 EST
    +1100       1 LHST    +1030       0 LHST
    +1130       0 NFT     +1130       0 NFT
    +1200       0 FJT     +1200       0 FJT
    +1300       0 TKT     +1300       0 TKT
    +1300       1 NZDT    +1200       0 NZST
    +1345       1 CHADT   +1245       0 CHAST
    +1400       0 LINT    +1400       0 LINT
    +1400       1 WSDT    +1300       0 WST
);

sub _tzoffset {
    my $diff = (exists $ENV{TZ} and $ENV{TZ} =~ m!^(?:GMT|UTC)$!)
             ? 0
             : Time::Local::timegm(@_) - Time::Local::timelocal(@_);
    sprintf '%+03d%02u', $diff/60/60, $diff/60%60;
}

sub _tzname {
    return $ENV{TZ} if exists $ENV{TZ} and $ENV{TZ} =~ m!^(?:GMT|UTC)$!;

    my $diff = tzoffset(@_);

    my @t1 = my @t2 = @_;
    @t1[3,4] = (1, 1);  # winter
    my $diff1 = tzoffset(@t1);
    @t2[3,4] = (1, 7);  # summer
    my $diff2 = tzoffset(@t2);

    for (my $i=0; $i < @offset2zone; $i += 6) {
        next unless $offset2zone[$i] eq $diff1 and $offset2zone[$i+3] eq $diff2;
        return $diff2 eq $diff ? $offset2zone[$i+5] : $offset2zone[$i+2];
    }

    if ($diff =~ /^([+-])(\d\d)$/) {
        return sprintf 'GMT%s%d', $1 eq '-' ? '+' : '-', $2;
    };

    return 'Etc';
}

sub iso_week_days {
    my ($yday, $wday) = @_;

    # Add enough to the first operand of % to make it nonnegative.
    my $big_enough_multiple_of_7 = (int(- YDAY_MINIMUM / 7) + 2) * 7;
    return ($yday
        - ($yday - $wday + ISO_WEEK1_WDAY + $big_enough_multiple_of_7) % 7
        + ISO_WEEK1_WDAY - ISO_WEEK_START_WDAY);
}

sub isleap {
    my $year = shift;
    return ($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0)) ? 1 : 0
}

sub isodaysnum {
    my @t = @_;

    my $year = ($t[YEAR] + ($t[YEAR] < 0 ? 1900 % 400 : 1900 % 400 - 400));
    my $year_adjust = 0;
    my $days = iso_week_days($t[YDAY], $t[WDAY]);

    if ($days < 0) {
        # This ISO week belongs to the previous year.
        $year_adjust = -1;
        $days = iso_week_days($t[YDAY] + (365 + isleap($year -1)), $t[WDAY]);
    }
    else {
        my $d = iso_week_days($t[YDAY] - (365 + isleap($year)), $t[WDAY]);
        if ($d >= 0) {
            # This ISO week belongs to the next year.  */
            $year_adjust = 1;
            $days = $d;
        }
    }

    return ($days, $year_adjust);
}

sub isoyearnum {
    my ($days, $year_adjust) = isodaysnum(@_);
    return $_[YEAR] + 1900 + $year_adjust;
}

sub isoweeknum {
    my ($days, $year_adjust) = isodaysnum(@_);
    return int($days / 7) + 1;
}

our %FORMAT_CHARS = map { $_ => 1 } split //, q!%aAbBcCdDeFGghHIjklmMnNpPrRsStTuUVwWxXyYzZ!;

our %SPRINTF_CHARS = (
    '%' => [q!%s!, q!%!],
    'a' => [q!%s!, q!$weekday_abbr[$_[WDAY]]!],
    'A' => [q!%s!, q!$weekday_name[$_[WDAY]]!],
    'b' => [q!%s!, q!$month_abbr[$_[MONTH]]!],
    'B' => [q!%s!, q!$month_name[$_[MONTH]]!],
    'c' => [q!%s %s %2d %02d:%02d:%02d %04d!,
            q!$weekday_abbr[$_[WDAY]], $month_abbr[$_[MONTH]], $_[DAY], $_[HOUR], $_[MIN], $_[SEC], $_[YEAR]+1900!],
    'C' => [q!%02d!, q!($_[YEAR]+1900)/100!],
    'd' => [q!%02d!, q!$_[DAY]!],
    'D' => [q!%02d/%02d/%02d!, q!$_[MONTH]+1,$_[DAY],$_[YEAR]%100!],
    'e' => [q!%2d!, q!$_[DAY]!],
    'F' => [q!%04d-%02d-%02d!, q!$_[YEAR]+1900,$_[MONTH]+1,$_[DAY]!],
    'h' => [q!%s!, q!$month_abbr[$_[MONTH]]!],
    'H' => [q!%02d!, q!$_[HOUR]!],
    'I' => [q!%02d!, q!$_[HOUR]%12 || 1!],
    'j' => [q!%03d!, q!$_[YDAY]+1!],
    'k' => [q!%2d!, q!$_[HOUR]!],
    'l' => [q!%2d!, q!$_[HOUR]%12 || 1!],
    'm' => [q!%02d!, q!$_[MONTH]+1!],
    'M' => [q!%02d!, q!$_[MIN]!],
    'n' => [q!%s!, q!"\n"!],
    'N' => [q!%s!, q!substr(sprintf('%.9f', $_[SEC] - int $_[SEC]), 2)!],
    'p' => [q!%s!, q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'P' => [q!%s!, q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "am" : "pm"!],
    'r' => [q!%02d:%02d:%02d %s!, q!$_[HOUR]%12 || 1, $_[MIN], $_[SEC], $_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'R' => [q!%02d:%02d!, q!$_[HOUR], $_[MIN]!],
    'S' => [q!%02d!, q!$_[SEC]!],
    't' => [q!%s!, q!"\t"!],
    'T' => [q!%02d:%02d:%02d!, q!$_[HOUR], $_[MIN], $_[SEC]!],
    'u' => [q!%d!, q!$_[WDAY] || 7!],
    'w' => [q!%d!, q!$_[WDAY]!],
    'x' => [q!%02d/%02d/%02d!, q!$_[MONTH]+1,$_[DAY],$_[YEAR]%100!],
    'X' => [q!%02d:%02d:%02d!, q!$_[HOUR], $_[MIN], $_[SEC]!],
    'y' => [q!%02d!, q!$_[YEAR]%100!],
    'Y' => [q!%02d!, q!$_[YEAR]+1900!],
    '%' => [q!%s!, q!'%'!],
);

if ( eval { require Time::TZOffset; 1 } ) {
    $SPRINTF_CHARS{z} = [q!%s!,q!Time::TZOffset::tzoffset(@_)!];
}

our %LOCALE_CHARS = (
    '%' => [q!'%%'!],
    'a' => [q!$weekday_abbr[$_[WDAY]]!,1],
    'A' => [q!$weekday_name[$_[WDAY]]!,1],
    'b' => [q!$month_abbr[$_[MONTH]]!],
    'B' => [q!$month_name[$_[MONTH]]!],
    'c' => [q!$weekday_abbr[$_[WDAY]] . ' ' . $month_abbr[$_[MONTH]] . ' ' . substr(' '.$_[DAY],-2) . ' %H:%M:%S %Y'!,1],
    'C' => [q!substr('0'.int(($_[YEAR]+1900)/100), -2)!],  #century
    'h' => [q!$month_abbr[$_[MONTH]]!],
    'k' => [q!substr(' '.$_[HOUR],-2)!],
    'l' => [q!substr(' '.($_[HOUR]%12 || 1),-2)!],
    'N' => [q!substr(sprintf('%.9f', $_[SEC] - int $_[SEC]), 2)!],
    'n' => [q!"\n"!],
    'p' => [q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'P' => [q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "am" : "pm"!],
    'r' => [q!sprintf('%02d:%02d:%02d %s',$_[HOUR]%12 || 1, $_[MIN], $_[SEC], $_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM")!],
    't' => [q!"\t"!],
    'x' => [q!'%m/%d/%y'!],
    'X' => [q!'%H:%M:%S'!],
    'z' => [q!'%z'!,1],
    'Z' => [q!'%Z'!,1],
);

if ( $^O =~ m!^(MSWin32|cygwin)$!i ) {
    %LOCALE_CHARS = (
        %LOCALE_CHARS,
        'D' => [q!'%m/%d/%y'!],
        'F' => [q!'%Y-%m-%d'!],
        'G' => [q!substr('0000'. isoyearnum(@_), -4)!,1],
        'R' => [q!'%H:%M'!],
        'T' => [q!'%H:%M:%S'!],
        'V' => [q!substr('0'.isoweeknum(@_),-2)!,1],
        'e' => [q!substr(' '.$_[DAY],-2)!],
        'g' => [q!substr('0'.isoyearnum(@_)%100,-2)!,1],
        's' => [q!int(Time::Local::timegm(@_))!,1],
        'u' => [q!$_[WDAY] || 7!,1],
        'z' => [q!tzoffset(@_)!,1],
        'Z' => [q!tzname(@_)!,1],
    );
}
elsif ( $^O =~ m!^solaris$!i ) {
    $LOCALE_CHARS{s} = [q!int(Time::Local::timegm(@_))!,1];
}

my $sprintf_char_handler = sub {
    my ($char,$args) = @_;
    return q|! . '%%' .q!| if $char eq ''; #last %
    return q|! . '%%| . $char . q|' . q!| if ! exists $FORMAT_CHARS{$char}; #escape %%
    my ($format, $code) = @{$SPRINTF_CHARS{$char}};
    push @$args, $code;
    return $format;
};

my $char_handler = sub {
    my ($char,$need9char_ref) = @_;
    return q|! . '%%' .q!| if $char eq ''; #last %
    return q|! . '%%| . $char . q|' . q!| if ! exists $FORMAT_CHARS{$char}; #escape %%
    return q|! . '%| . $char . q|' . q!| if ! exists $LOCALE_CHARS{$char}; #stay
    my ($code,$flag) = @{$LOCALE_CHARS{$char}};
    $$need9char_ref++ if $flag;
    q|! . | . $code . q| . q!|;
};

sub compile {
    my ($fmt) = @_;

    my @weekday_name = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @weekday_abbr = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @month_name = qw(January February March April May June July August September October November December);
    my @month_abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    $fmt =~ s/!/\\!/g;
    $fmt =~ s!\%E([cCxXyY])!%$1!g;
    $fmt =~ s!\%O([deHImMSuUVwWy])!%$1!g;

    my $sprintf_fmt = $fmt;
    my $disable_sprintf=0;
    my $sprintf_code = '';
    while ( $sprintf_fmt =~ m~ (?:\%([\%\+a-zA-Z])) ~gx ) {
        if ( exists $FORMAT_CHARS{$1} && ! exists $SPRINTF_CHARS{$1} ) {
            $disable_sprintf++
        }
    }
    if ( !$disable_sprintf ) {
        my @args;
        $sprintf_fmt =~ s!
            (?:
                 \%([\%\+a-zA-Z]|$)
            )
        ! $sprintf_char_handler->($1,\@args) !egx;
        $sprintf_code = q~if ( @_ == 9 ) {
            return sprintf(q!~ . $sprintf_fmt .  q~!,~ . join(",", @args) . q~);
        }~;
    }

    my $posix_fmt = $fmt;
    my $need9char=0;
    $posix_fmt =~ s!
        (?:
             \%([\%\+a-zA-Z]|$)
        )
    ! $char_handler->($1,\$need9char) !egx;
    
    my $need9char_code='';
    if ( $need9char ) {
        $need9char_code = q~if ( @_ == 6 ) {
          my $sec = $_[0];
          @_ = gmtime Time::Local::timegm(@_);
          $_[0] = $sec;
        }~;
    }
    my $code = q~sub {
        if ( @_ != 9  && @_ != 6 ) {
            Carp::croak 'Usage: strftime(sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)';
        }
        ~ . $sprintf_code . q~
        ~ . $need9char_code . q~
        POSIX::strftime(q!~ . $posix_fmt . q~!,@_);
    }~;
    my $sub = eval $code; ## no critic
    die $@ ."\n=====\n".$code."\n=====\n" if $@;
    wantarray ? ($sub,$code) : $sub;
}

my %STRFTIME;
sub strftime {
    my $fmt = shift;
    ($STRFTIME{$fmt} ||= compile($fmt))->(@_);
}

sub new {
    my $class = shift;
    my $fmt = shift;
    my ($sub,$code) = compile($fmt);
    bless [$sub,$code], $class;
}

sub to_string {
    my $self = shift;
    $self->[0]->(@_);
}

sub code_ref {
    my $self = shift;
    $self->[0];
}

1;
__END__

=encoding utf-8

=head1 NAME

POSIX::strftime::Compiler - GNU C library compatible strftime for loggers and servers

=head1 SYNOPSIS

    use POSIX::strftime::Compiler qw/strftime/;

    say strftime('%a, %d %b %Y %T %z',localtime):
    
    my $fmt = '%a, %d %b %Y %T %z';
    my $psc = POSIX::strftime::Compiler->new($fmt);
    say $psc->to_string(localtime);

=head1 DESCRIPTION

POSIX::strftime::Compiler provides GNU C library compatible strftime(3). But this module will not affected
by the system locale.  This feature is useful when you want to write loggers, servers and portable applications.

For generate same result strings on any locale, POSIX::strftime::Compiler wraps POSIX::strftime and 
converts some format characters to perl code

=head1 FUNCTION

=over 4

=item strftime($fmt:String, @time)

Generate formatted string from a format and time.

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  strftime('%d/%b/%Y:%T %z',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst):

Compiled codes are stored in C<%POSIX::strftime::Compiler::STRFTIME>. This function is not exported by default.

=back

=head1 METHODS

=over 4

=item new($fmt)

create instance of POSIX::strftime::Compiler

=item to_string(@time)

Generate formatted string from time.

=back

=head1 FORMAT CHARACTERS

POSIX::strftime::Compiler supports almost all characters that GNU strftime(3) supports. 
But C<%E[cCxXyY]> and C<%O[deHImMSuUVwWy]> are not supported, just remove E and O prefix.

=head1 A RECOMMEND MODULE

=over

=item L<Time::TZOffset>

If L<Time::TZOffset> is available, P::s::Compiler use it for more faster time zone offset calculation.
I strongly recommend you to install this if you use C<%z>.

=back

=head1 PERFORMANCE ISSUES ON WINDOWS

Windows and Cygwin and some system may not support C<%z> and C<%Z>. For these system, 
POSIX::strftime::Compiler calculate time zone offset and find zone name. This is not fast.
If you need performance on Windows and Cygwin, please install L<Time::TZOffset>

=head1 SEE ALSO

=over 4

=item L<POSIX::strftime::GNU>

POSIX::strftime::Compiler is built on POSIX::strftime::GNU::PP code

=item L<POSIX>

=item L<Apache::LogFormat::Compiler>

=back

=head1 LICENSE

Copyright (C) Masahiro Nagano.

Format specification is based on strftime(3) manual page which is a part of the Linux man-pages project.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

