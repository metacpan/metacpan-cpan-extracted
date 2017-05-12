package Nagios::Report;

use strict;

# $Id: Report.pm,v 1.87 2006-08-23 14:26:17+10 sh1517 Exp sh1517 $

use base 'Exporter' ;
use Time::Local ;
# use POSIX qw(mktime) ;

use vars qw($VERSION @EXPORT @EXPORT_OK %stime_etime);

*t2hms = \&time2ddhhmmss ;
*d2t   = \&date2time ;
*i2t   = \&interval2time ;
*st_et = \%stime_etime ;

@EXPORT = qw(d2t t2hms comp max_l %st_et i2t) ;

$VERSION = '0.003';

use constant REQUEST_METHOD  => 'GET' ;

                                                        # Will be hacked by Makefile.PL

use constant CGI_PATH        => '' ;
use constant LYNX            => '' ;
use constant WGET            => '' ;
                                                        # EURO_DATE => \d\d?-\d\d?-\d\d\d\d
                                                        # will be interpreted as DD-MM-YYYY
use constant EURO_DATE       => 1 ;

                                                        # End scope of expected changes by Makefile.PL

                                                        # NB. I choose lynx etc over LWP because
                                                        # LWP is a big module (LWP::Simple doesn't
                                                        # fetch protected pages).
                            

use constant NAG_AVAIL_CGI   => CGI_PATH . 'avail.cgi' ;
use constant WEB_PAGE        => !! (LYNX || WGET) ;
use constant LOCAL_CGI       => !! CGI_PATH ;
use constant USE_LYNX        => !! (WEB_PAGE && LYNX) ;

use constant EXCEL_FILENAME  => './Nagios_Avail.xls' ;

use constant QS_TEMP_HOSTREP => 
q(show_log_entries=&host=all&t1=T1&t2=T2&rpttimeperiod=REPORT_PERIOD&assumeinitialstates=yes&assumestateretention=yes&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedhoststate=3&initialassumedservicestate=6&backtrack=0&csvoutput) ;

use constant QS_TEMP_SVCREP  => 
q(show_log_entries=&host=FOO&service=all&t1=T1&t2=T2&rpttimeperiod=REPORT_PERIOD&assumeinitialstates=yes&assumestateretention=yes&assumestatesduringnotrunning=yes&includesoftstates=no&initialassumedservicestate=6&backtrack=0&csvoutput=) ;

use constant AVAIL_URL_TEMP_HOST =>
q(http://SERVER/nagios/cgi-bin/avail.cgi?host=HOST&t1=T1&t2=T2&show_log_entries=&assumeinitialstates=yes&assumestateretention=yes&includesoftstates=no&backtrack=0) ;

use constant TREND_URL_TEMP_HOST =>
q(http://SERVER/nagios/cgi-bin/trends.cgi?host=HOST&t1=T1&t2=T2&assumeinitialstates=yes&assumestateretention=yes&includesoftstates=no) ;

use constant AVAIL_URL_TEMP_SVC =>
q(http://SERVER/nagios/cgi-bin/avail.cgi?host=HOST&service=SVC&t1=T1&t2=T2&show_log_entries=&assumeinitialstates=yes&assumestateretention=yes&includesoftstates=no&assumestatesduringnotrunning=yes&backtrack=0&initialassumedservicestate=6) ;

use constant TREND_URL_TEMP_SVC =>
q(http://SERVER/nagios/cgi-bin/trends.cgi?host=HOST&service=SVC&t1=T1&t2=T2&assumeinitialstates=yes&assumestatesduringnotrunning=yes&initialassumedhoststate=0&initialassumedservicestate=0&assumestateretention=yes&includesoftstates=no) ;

use constant {
    SEC                 => 0,
    MIN                 => 1,
    HOUR                => 2,
    MDAY                => 3,
    MON                 => 4,
    YEAR                => 5,
    WDAY                => 6,
    YDAY                => 7,
    ISDST               => 8,
};

use constant MONTH => {
    Jan                 => 0,
    Feb                 => 1,
    Mar                 => 2,
    Apr                 => 3,
    May                 => 4,
    Jun                 => 5,
    Jul                 => 6,
    Aug                 => 7,
    Sep                 => 8,
    Oct                 => 9,
    Nov                 => 10,
    Dec                 => 11,
} ;

use constant T          => { w => 7*86_400, d => 86_400, h => 60*60, m => 60, s => 1 } ;

sub Iterator (&) { $_[0] } ;

my %default_sort = (
    alpha               => 1,                           # 0 implies numeric
    ascend              => 1,
    fields              => [ qw(HOST_NAME) ],
) ;
            
   %stime_etime = (
    last12hours => sub { my $t = defined($_[1]) ? timelocal(@{$_[1]}) : time(); ( $t - 12 *  3_600, $t) },
    last24hours => sub { my $t = defined($_[1]) ? timelocal(@{$_[1]}) : time(); ( $t - 1  * 86_400, $t) },
    last7days   => sub { my $t = defined($_[1]) ? timelocal(@{$_[1]}) : time(); ( $t - 7  * 86_400, $t) },
    last31days  => sub { my $t = defined($_[1]) ? timelocal(@{$_[1]}) : time(); ( $t - 31 * 86_400, $t) },
    today       => sub {
                $_[1] ||= [localtime];
                my $t   = timelocal( @{$_[1]} );
                #( mktime(0, 0, 0, $_[1]->[MDAY], $_[1]->[MON], $_[1]->[YEAR]), 
                (
                  $t - ( $_[1]->[SEC] + 60 *( $_[1]->[MIN] + 60*$_[1]->[HOUR] ) ),
                  $t
                )
                   },
    yesterday   => sub { 
                 $_[1]      ||= [localtime] ;
                 my $midnight = timelocal( @{$_[1]} ) - ( $_[1]->[SEC] + 60 *( $_[1]->[MIN] + 60*$_[1]->[HOUR] ) ) ;
                (
                  $midnight - 86_400,
                  $midnight
                )
    },
    last_n_mins => sub {
                $_[1]              ||= [localtime] ;
                my ($mins, $t_ar)   = @_ ;
                my $t               = timelocal( @$t_ar ) ;
                (
                  $t - $mins * 60,
                  $t
                )
    },
    last_n_hours    => sub {
                $_[1]             ||= [localtime] ;
                my ($hours, $t_ar)  = @_ ;
                my $t               = timelocal(@$t_ar) ;
                (
                  $t - $hours * 3_600,
                  $t
                )
    },
    last_n_days => sub {
                $_[1]             ||= [localtime] ;
                my ($days, $t_ar)   = @_ ;
                my $t               = timelocal(@$t_ar ) ;
                                                        # XXX Fails for days > 120.
                (
                  $t - $days * 86_400,
                  $t,
                )
    },
    thisweek    => sub { 
                                                        # thisweek is wrt to MONDAY.
                $_[1] ||= [localtime] ;
                my $t   = timelocal( @{$_[1]} ) ;
                (
                  $t - ( $_[1]->[SEC] + 60*($_[1]->[MIN] + 60*$_[1]->[HOUR]) + ($_[1]->[WDAY] - 1)*86_400 ),
                  $t
                )
    },
    lastweek    => sub { 
                $_[1]   ||= [localtime] ;
                my $sweek = 
                   timelocal( @{$_[1]} ) - ( $_[1]->[SEC] + 60*($_[1]->[MIN] + 60*$_[1]->[HOUR]) + ($_[1]->[WDAY]-1)*86_400 ) ;
                (
                  $sweek - 7 * 86_400,
                  $sweek - 1
                )
    },
    thismonth    => sub { 
                $_[1] ||= [localtime] ;
                (
                  timelocal( 0, 0, 0, 1, $_[1]->[MON], $_[1]->[YEAR] ),
                  timelocal( @{$_[1]}                                )
                )
    },
    lastmonth   => sub {
                $_[1]     ||= [localtime] ;
                my ($m, $y) = @{$_[1]}[MON, YEAR] ;
                (
                  timelocal( 0, 0, 0, 1, ($m - 1) % 12, $y - ($m == 0), ),
                  timelocal( 0, 0, 0, 1,  $m          , $y              ) - 1
                )
    },
    thisyear    => sub {
                $_[1] ||= [localtime] ;
                (
                  timelocal( 0, 0, 0, 1, 0, $_[1]->[YEAR]),
                  timelocal( @{$_[1]}                    )
                )
    },
    lastyear    => sub { 
                $_[1] ||= [localtime] ;
                ( timelocal( 0, 0, 0, 1, 0, $_[1]->[YEAR] - 1 ),
                  timelocal( 0, 0, 0, 1, 0, $_[1]->[YEAR]     ) -1
                )
    },
    __DEFAULT__ => sub {
                                                        # The 'tag' or the name of the interval supplied to the constructor
                                                        # The tag describes the interval either absolutely (eg DD.MM.YY) or
                                                        # wrt to the second arg (the right edge of the interval).
                local $_= shift @_ ;
                                                        # Usually this arg is the upper bound of the interval. 
                                                        # Most often it is [localtime].
                my $t   = @_ ? shift @_ : [localtime] ;

                my @t   = @$t ;
                my ($t1, $t2) = 
                    /^ last(\d+)day /x  ?   $stime_etime{last_n_days}->(  $1, $t )      :
                    /^ last(\d+)hour /x ?   $stime_etime{last_n_hours}->( $1, $t )      :
                    /^ last(\d+)min /x  ?   $stime_etime{last_n_mins}->(  $1, $t )      :
                                                        # Define a time period with a string like so
                                                        # time: HHMM | HH:MM        => from that time today to now
                                                        # date: DD.MM.YY | DD.MM.YYYY | MM/DD/YYYY | MM/DD/YY
                                                        #                => midnight on that day to now
                                                        # time date            => that time on that day to now 
                                                        # The time and date formats are inspired by the at command.
                    /^ (\d\d) :? (\d\d) $/x
                                        ? do {          # HHMM | HH:MM
                                            @t[SEC, MIN, HOUR] = 
                                              (0,   $2,  $1  ) ;
                                            ( timelocal(@t), timelocal(@$t) ) ;
                                        }                                               :
                    m{^ (\d\d?) [\./] (\d\d?) [\./] ( \d\d (?:\d\d)? ) $}x
                                        ? do {          # DD.MM.YY(YY)? | MM/DD/YY(YY)?
                                            my ($dd, $mm, $yy) = ($1, $2, $3) ;
                                            ($mm, $dd) = ($dd, $mm)
                                                if m{/} ;
                                            @t[SEC, MIN, HOUR, MDAY, MON,     YEAR] = 
                                              (0,   0,   0,    $dd,  $mm - 1, $yy ) ;
                                            ( timelocal(@t), timelocal(@$t) ) ;
                                        }                                               :
                    m{^ (\d\d) :? (\d\d) \s+ (\d\d?) [\./] (\d\d?) [\./] ( \d\d (?:\d\d)? ) $ }x
                                        ? do {            # HHMM | HH:MM DD.MM.YY(YY)? | MM/DD/YY(YY)?
                                            my ($h, $m, $dd, $mm, $yy) = ($1, $2, $3, $4, $5) ;
                                            ($mm, $dd) = ($dd, $mm)
                                                if m{/} ;
                                            @t[SEC, MIN, HOUR, MDAY, MON,     YEAR] = 
                                              (0,   $m,  $h,   $dd,  $mm - 1, $yy ) ;
                                            ( timelocal(@t), timelocal(@$t) ) ;
                                        }                                               :
                    m{^ (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \s* (\d{4})? }ix
                                        ? do {
                                                        # I'd like to be able to use 'Mar-2006' here but I can't because
                                                        # the constructor will recognise date ranges (intervals) as strings
                                                        # containing '-'.
                                            my ($mm, $yy, @t1, @t2) ;
                                            $mm = MONTH->{"\u$1"} ;
                                            $yy = $2 || $t[YEAR] ;
                                            @t1[SEC, MIN, HOUR, MDAY, MON,            YEAR] = 
                                               (0,   0,   0,    1,    $mm,            $yy ) ;
                                            @t2[SEC, MIN, HOUR, MDAY, MON,            YEAR] = 
                                               (0,   0,   0,    1,    ($mm + 1) % 12, $yy + ($mm == 11) ) ;
                                            ( timelocal(@t1), timelocal(@t2) - 1 ) ;
                                        }                                               :
                    (999_999, 999_999) ;
                    die "\%stime_etime: non existent tag '$_' - no handler defined for this tag. Outahere."
                        if $t1 == 999_999 && $t2 == 999_999 ;
                    return ($t1, $t2) ;
    },
) ;

my %data_source = (
                                                        # All these subroutines return a code reference
                                                        # (a closure encapsulating auth data) that actually gets the data.
  web_page      => WEB_PAGE  ?  \&gen_web_page                                                        :
                                sub { die 'No CLI web browser (lynx or wget) found. Use local_cgi or report bug' },
  local_cgi     => LOCAL_CGI ?  \&gen_local_cgi                                                       :
                                sub { die 'Nagios availability CGI not found on this host. Use web_page or report bug' },
                                                        # Return a ref to the subroutine in main:: (the client code)
                                                        # that will return the CSV data.
  dev_debug     => sub {
                    die "dev_debug source tag must be followed by the name of a callback in main::."
                        unless $_[0] ;
                    no strict 'refs' ;
                    my $cb = 'main::' . $_[0] ;
                    return \&$cb ;
                },
  __DEFAULT__    => sub { die "Outahere: bad source tag '$_[0]'" },
) ;

sub new {

  my ($class, $source_tag, $rpt_period, $tme_period, $rep_type, $pre_filter) = @_ ;

  my @report_period = $rpt_period  ? @$rpt_period  : qw(24x7) ;
  my $time_period   = $tme_period  ? $tme_period   : q(thismonth) ;
  my $report_type   = $rep_type    ? q(service)    : q(host) ;

  die 'new() called with a pre_filter parm that is _not_ a code ref. Caller ' . join(' ', caller)
    if $pre_filter        and ref($pre_filter)        ne 'CODE' ;

  $pre_filter ||= sub { 1 } ;

  my $me        = {} ;
  my $schema    = q{} ;
  my @fieldnames= () ;
  my @fieldnums = () ;
  my %fields    = () ;

  $me->{REPORTS}= {} ;
  $me->{REPORT_PERIODS} = [ @report_period ] ;
                                                        # Date ranges: $time_period =~ start_at_date / \s* - \s*/x  end_at_date
                                                        # start_at_date and end_at_dates look like time stamps.
  my ($t1, $t2) ;
  if ( my ($s, $e)  = $time_period =~ /^([^-]+)-([^-]+)$/ ) {
                                                        # XXX
    $s =~ s/\s+$// ;
    $e =~ s/^\s+// ;
    ($t1, undef)    = $stime_etime{__DEFAULT__}->( $s, [ localtime ] ) ;
    ($t2, undef)    = $stime_etime{__DEFAULT__}->( $e, [ localtime ] )
  } else {
    ($t1, $t2)      = exists $stime_etime{$time_period} ? $stime_etime{$time_period}->( $time_period, [localtime] )
                                                        : $stime_etime{__DEFAULT__}->(  $time_period, [localtime] )
  }

  my $data ;
   $source_tag          =~ s/dev_debug/dev_debug BOGON_SERVER/
     if $source_tag     =~ /^dev_debug/ ;
  ($source_tag, $data)  = split /\s+/, $source_tag, 2 ;

  die "new() called with either null source_tag or null parms: \$source_tag: '$source_tag' \$data: '$data'. Caller " . 
       join(' ', caller)
    unless $source_tag && $data ; 

  my ($server, $auth)   = split /\s+/, $data, 2 ;

  die "new() called with a source_tag that failed to contain a non null server name. Caller " . join(' ', caller)
    unless $server ;

  $me->{DATA_SOURCE}    = $data_source{$source_tag}->(split /\s+/, $auth) ;
  $me->{SERVER}         = $server ;
  $me->{SOURCE_TAG}     = $source_tag ;
  $me->{REPORT_TYPE}    = $report_type ;
  $me->{T1}             = $t1 ;
  $me->{T2}             = $t2 ;

  foreach my $rep_period ( @report_period ) {

    my $user_data ;
    $user_data          = $report_type eq 'host' ? QS_TEMP_HOSTREP : QS_TEMP_SVCREP ;
    $user_data          =~ s/t1=T1&t2=T2/t1=$t1&t2=$t2/ ;
    $user_data          =~ s/REPORT_PERIOD/$rep_period/ ;
    $user_data          =
      $me->{SOURCE_TAG} eq 'web_page'   ? "http://$me->{SERVER}/nagios/cgi-bin/avail.cgi?$user_data"    :
      $me->{SOURCE_TAG} eq 'dev_debug'  ? $rep_period                                                   :
      $me->{SOURCE_TAG} eq 'local_cgi'  ? $user_data                                                    :
                                          '__DEFAULT__' ;

    my @avail_rep       = $me->{DATA_SOURCE}->($user_data) ;

    $schema             = shift @avail_rep ;
    $schema            .= ', AVAIL_URL, TREND_URL' ;
    $me->{FIELDNAMES} ||= [ @fieldnames = split /,\s+/, $schema ] ;
    @fields{@fieldnames}= (0 .. $#fieldnames) ;
    $me->{FIELDS}     ||= { %fields } ;

    my @avail_report    = () ;

    local $_ ;

    foreach (@avail_rep) {
      my @vals = split /,\s+/ ;

      my $host = $vals[$fields{HOST_NAME}] ;
      my $svc ;
      $host    =~ s/"//g ;
      $vals[$fields{HOST_NAME}]  = $host ;
      if ( $report_type eq 'service' ) {
        $svc = $vals[$fields{SERVICE_DESCRIPTION}] ;
        $svc =~ s/"//g ;
        $vals[$fields{SERVICE_DESCRIPTION}] = $svc ;
      }

      my $avail_url =  $report_type eq 'host' ? AVAIL_URL_TEMP_HOST : AVAIL_URL_TEMP_SVC ;
         $avail_url =~ s/HOST/$host/ ;
         $avail_url =~ s/SVC/$svc/
           if $report_type eq 'service' ;
         $avail_url =~ s/t1=T1&t2=T2/t1=$t1&t2=$t2/ ;
         $avail_url =~ s/SERVER/$me->{SERVER}/ ;
      $vals[$fields{AVAIL_URL}] = $avail_url ;

      my $trend_url =  $report_type eq 'host' ? TREND_URL_TEMP_HOST : TREND_URL_TEMP_SVC ;
         $trend_url =~ s/HOST/$host/ ;
         $trend_url =~ s/SVC/$svc/
           if $report_type eq 'service' ;
         $trend_url =~ s/t1=T1&t2=T2/t1=$t1&t2=$t2/ ;
         $trend_url =~ s/SERVER/$me->{SERVER}/ ;
      $vals[$fields{TREND_URL}] = $trend_url ;

      my %F ;
         @F{@fieldnames} = @vals ;

      next
        unless $pre_filter->(%F) ;

      push @avail_report, [ @vals ] ;
    }

    $me->{AVAIL_REPORTS}{$rep_period}    =  [ @avail_report ] ;

  }

  bless $me, ref($class) || $class ;

}

                                                        # Runs while object 'loads'
                                                        # Creates accessors for the callers convenience.

                                                        # XXX
                                                        # This class will _not_ use the accessors itself
                                                        # since it doesn't believe it will be inherited from.

foreach my $acc (qw(FIELDS FIELDNAMES REPORT_PERIODS T1 T2 SERVER AVAIL_REPORTS REPORTS DATA_SOURCE SOURCE_TAG REPORT_TYPE)) {
  no strict 'refs' ;
  *$acc = sub {
      my $me = shift @_ ;
      $me->{$acc} = @_
        if @_ ;
      $me->{$acc} ;
  }
}

sub mkreport {
  my ($me, $these_fields, $select_these, $this_order, $alter, $add_downs) = @_ ;

                                                        # $these_fields: fields which will appear in output
                                                        #                in the same order as specified (in
                                                        #                the array pointed to).
                                                        # $select_these: callback specifying which records
                                                        #                to report on.
                                                        # $this_order  : callback for sort to order the
                                                        #                records.
                                                        # $alter       : callback to add fields to or other
                                                        #                wise mangle a record. Should return
                                                        #                the names of any added fields.
                                                        # $add_downs   : duplicate the rec by the
                                                        #                number of outage recs, appending
                                                        #                time down, up and outage duration.

                                                        # XXX
                                                        # $these_fields should specify the names and orders
                                                        # of any fields added by $alter->().

  my $usage =<<'USAGE' ;

mkreport(  $these_fields, $select_these, $this_order, $alter, $add_downs )

$these_fields := optional array ref enumerating the fields, and there order to appear in the report.
$select_these := optional callback returning true if the availability record is to appear in the report. Called
                 with pairs of all fields and values for this record.
$this_order   := optional callback specifiying sort order. Called with pairs of all fieldnames and their offsets
$alter        := optional callback that munges fields (transforming field values or adding new fields).
$add_downs    := optional flag. If set, each availability record is duplicated by the number of outage records,
                   and the time down, time up and duration of the outage is appended to each record.

USAGE

  die $usage
    if $these_fields and ref($these_fields) ne 'ARRAY' ;

  die $usage
    if $select_these and ref($select_these) ne 'CODE' ;

  die $usage
    if $this_order   and ref($this_order)   ne 'CODE' ;

  die $usage
    if $alter        and ref($alter)        ne 'CODE' ;

  $these_fields   ||= [] ;
  $select_these   ||= sub { 1 } ;
  $this_order     ||= sub { my %f = @_ ; $a->[$f{HOST_NAME}] cmp $b->[$f{HOST_NAME}] } ;

  my @field_names = scalar(@$these_fields) ? @$these_fields : @{ $me->{FIELDNAMES} } ;
  my @fieldnames  = @{ $me->{FIELDNAMES} } ;
  my %fields      = %{ $me->{FIELDS} } ;

  $me->{REPORTS}{$_}{RECORDS} = []
    foreach keys %{ $me->{AVAIL_REPORTS} } ;

                                                        # map 
                                                        #     slice
                                                        #       sort
                                                        #         filter
                                                        #           alter
                                                        #             add_downs list

                                                        # Do the transforms - to add
                                                        # fields - first, and then 
                                                        # update the fieldnames so
                                                        # the new fields can be used
                                                        # to select and sort.

  foreach my $rep ( keys %{ $me->{AVAIL_REPORTS} } ) {

    my (%F, @r, @avail_recs, $avail_url) ;

    @avail_recs = @{ $me->{AVAIL_REPORTS}{$rep} } ;

    next
      unless @avail_recs ;

    @r          = shift @avail_recs ;

    $add_downs  = 0
      unless $me->{SOURCE_TAG} =~ /^(?:web_page|local_cgi)/ ;

    if ( $add_downs ) {
      my @ofn   = qw(DOWN UP OUTAGE) ;
      push @fieldnames,  @ofn ;
                                                        # The new fields are added to the list
                                                        # of those appearing in the report
      push @field_names, @ofn
        unless grep $_ eq $ofn[0], @field_names ;
      @r        =
        map { get_downs($_, $me->{DATA_SOURCE}, $_->[$fields{AVAIL_URL}], $me->{T1}) } shift @r ;
    }

    if ( $alter ) {
      my @downs         = @r ;
      @F{@fieldnames}   = @{$r[0]} ;
                                                        # XXX - don't modify the rec, only get the added fields.
      my @afn           =  $alter->(\%F) ;
      # my @afn         =  $alter->($r[0], \%F) ;
      # my @afn         =  $alter->($r[0], %F) ;
      push @fieldnames,  @afn ;
      push @field_names, @afn
        unless grep $_ eq $afn[0], @field_names ;
      @r                =
        map { @F{@fieldnames} = @$_; $alter->(\%F); [ @F{@fieldnames} ] } @downs ;
    }

    $me->{FIELDNAMES}   = [ @fieldnames ] ;
    @fields{@fieldnames}= 0 .. $#fieldnames ;
    $me->{FIELDS}       = { %fields } ;

                                                        # Transform rec by adding or munging fields
                                                        # NB, the one attempt I made to move the
                                                        # tests outside map actually slowed the benchmark
                                                        # 'make tests'.
    push @r,
        map {
            @F{@fieldnames} = @$_ ;
            $alter->(\%F)
              if $alter ;
            [ @F{@fieldnames} ]
            }
        map {
            $add_downs 
              ? get_downs($_, $me->{DATA_SOURCE}, $_->[$fields{AVAIL_URL}], $me->{T1})
              : $_
            }
            @avail_recs ;

                                                        # Slice
    my @rep = map [ @{$_}[@fields{@field_names}] ],
                                                        # Sort
                 sort { $this_order->(%fields) }
                                                        # Filter
                   grep { @F{@{$me->{FIELDNAMES}}} = @$_; $select_these->(%F) }
                       @r ;

    $me->{REPORTS}{$rep}{RECORDS}    = [ @rep ] ;
    $me->{REPORTS}{$rep}{FIELDNAMES} = [ @field_names ] ;
  }

}


sub excel_dump {
  my ($me, $excel_filename, $chart_details) = @_ ;

  eval { require Spreadsheet::WriteExcel } ;
  die "John McNamara's _excellent_ CPAN module, Spreadsheet::WriteExcel is needed by excel_dump(). Outahere. "
    if $@ ;

  my $workbook  = Spreadsheet::WriteExcel->new($excel_filename || EXCEL_FILENAME) ;
  die "Spreadsheet::WriteExcel constructor failed, prob opening '$excel_filename': $!"
    unless $workbook ;

  my $format     = $workbook->add_format() ;
     $format->set_bold() ;

  foreach my $rep (@{ $me->{REPORT_PERIODS} }) {

    my $down_times = $me->{REPORTS}{$rep}{RECORDS} ;

    my $worksheet  = $workbook->addworksheet($rep) ;

    my @max_col_width = () ;
                                                        # The general syntax is write($row, $column, $token).
                                                        # Note that row and column are zero indexed
    my ($row, $col) = (0, 0) ;
                                                        # XXX
                                                        # Scan all data to determine widest column.
                                                        # The column width needs to be set before any
                                                        # cells are written.

    foreach my $c ( @{ $me->{REPORTS}{$rep}{FIELDNAMES} } ) {
      $max_col_width[$col++] = 1.5 * length($c) ;
                                                        # Fieldnames are bold so are wider than usual.
    }

    foreach my $r (@$down_times) {
      $col = 0 ;
      foreach my $c (@$r) {
        my $h ;
                                                        # XXX
                                                        # Set col width to width of label _not_ the URL.

        my $len = (($h) = $c =~ m#^http://.+?host=([^&]+)&#) ? length($h) : length($c) ;
        $max_col_width[$col] = $len 
          if $len >= $max_col_width[$col] ;
        $col++ ;
      }
    }

    $col = 0 ;

    foreach my $c ( @{ $me->{REPORTS}{$rep}{FIELDNAMES} } ) {
      $worksheet->set_column($col, $col, $max_col_width[$col]) ;
      $worksheet->write(0, $col, $c, $format) ;
      $col++
    }
 
    $row = 1 ; 

    foreach my $r (@$down_times) {
      $col = 0 ;
      foreach my $c ( @$r ) {
        if ( my ($h) = $c =~ m#^http://.+?host=([^&]+)&# ) {
          $worksheet->write_url($row, $col, $c, $h ? $h : "URL without hostname: $c") ;
        } else {
          $worksheet->write($row, $col, $c)
        }
        $col++ ;
      }
      $row++ ;
    }
  }

  &add_chart($workbook, $chart_details) 
    if $chart_details ;

}


sub csv_dump {
  my $me = shift @_ ;

  foreach my $rep (@{ $me->{REPORT_PERIODS} }) {

    print "==> $rep reporting period.\n" ;

    my $down_times = $me->{REPORTS}{$rep}{RECORDS} ;

    print
    join(',',  @{ $me->{REPORTS}{$rep}{FIELDNAMES} }), "\n" ;

    foreach my $r ( @{$down_times} ) {
      print
    join(',', @$r), "\n" ;
    }

    print "\n\n" ;

  }
}

sub debug_dump {
  my ($me, $field_width, $fields_per_line) = @_ ;

  $field_width    ||= 15 ;
  $fields_per_line||= 7 ;

  my $format        = 0 ;

  foreach my $rep (@{ $me->{REPORT_PERIODS} }) {

    format STDOUT_TOP = 

                          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                          $rep

.

    $- = 0 ;

    my @line ;
    @line = map { my $x = $_ ; $x =~ s/PERCENT/%/; $x }
        @{ $me->{REPORTS}{$rep}{FIELDNAMES} } ;

    &mkform($field_width, $fields_per_line, @line)
      unless $format++ ;
    &do_write(@line) ;

    foreach my $r ( @{ $me->{REPORTS}{$rep}{RECORDS} } ) {
      @line = @$r ;
      &do_write(@line) ;
    }
  }
}

{ 
  my @base = (
    { b => 60, u => 's' },
    { b => 60, u => 'm' },
    { b => 24, u => 'h' },
    { b =>  7, u => 'd' },
    { b =>  4, u => 'w' },
    { b => 12, u => 'm' },
  ) ;

  sub time2ddhhmmss {
                                                        # Rounds arg to nearest 5 minute interval
                                                        # and returns hhmmss string.
    my $d = shift @_ ;

    $d += 150 ;
    $d =  int($d/300) * 300 ;

    return ' '
      unless $d ;

    my ($s, $r, $i) ;
    $s = ' ' ;

    for ($i = 0; $d > 0; $i++) {
      $r = $d % $base[$i]{b} ;
      $s = "${r}$base[$i]{u} $s"
             if $r > 0 ;
      $d = ($d - $r) / $base[$i]{b} ;
    }

    $s ;

  }

}

sub mkform {

  my ($field_width, $fields_per_line) = @_ ;

  my ($pics, $vals, $f1, $f, $form_body) ;

  $f1   = '@' . '<' x 24 ;
  $f    = '@' . '<' x $field_width ;

  $pics = $f1 . " $f"   x ($fields_per_line - 1) ;
  $vals = 'shift(@_), ' x  $fields_per_line ;
  $form_body = "format STDOUT = \n" ;

  $form_body .= <<EOFORM ;
$pics
$vals
EOFORM

  my $fields_remaining    = @_ - $fields_per_line ;

  if ( $fields_remaining <= 0 ) {
    $form_body .= <<EOFORM ;
.
EOFORM

    eval $form_body ;

  } else {
    my $lines_remaining     = int($fields_remaining / ($fields_per_line - 1)) ;
    my $fields_on_last_line =     $fields_remaining % ($fields_per_line - 1) ;
    my $spaces              = ' ' x 25 ;

    $pics = $spaces . " $f"               x ($fields_per_line - 1) ;
    $vals = $spaces . ' shift(@_), '      x ($fields_per_line - 1) ;

    $form_body .= <<EOFORM x $lines_remaining ;
$pics
$vals
EOFORM

    $pics = $spaces . " $f"               x $fields_on_last_line ;
    $vals = $spaces . ' shift(@_), '      x $fields_on_last_line ;

    $form_body .= <<EOFORM ;
$pics
$vals
.
EOFORM

    eval  $form_body ;
  }

}

sub do_write {
                                                        # Only exists to get vals into @_ ;
  write ;
}

sub max_l {
  # my $max = shift @_ or
  return undef 
    unless @_ ;

  my $max = shift @_ ;

  local $_ ;
  while ( defined($_ = shift @_) ) {
    $max = $_
      if $_ >= $max
  }

  $max ;

}

sub comp {
                                                        # Returns a comparator function to sort the avail records

                                                        # Call with (alpha => 0|1, ascend => 0|1, fields =. [ f1.. ])

            my %sort_parms = (%default_sort, @_) ;

                                                        # eg
                                                        # alpha => 0, $ascend => 1, fields = [TOTAL_TIME_DOWN, TOTAL_TIME_UNREACH]
                                                        # TIME_DOWN and TIME_UNREACH are the same to the reader of the report;
                                                        # they should be consolidated with some consolidation function (eg max
                                                        # or sum of values).

            my $r ;

            if ( $sort_parms{alpha} ) {
              $r = $sort_parms{ascend}
                 ?  sub {
                    my %f = @_ ;

                    # package Nagios::Report ;
                    $a->[$f{HOST_NAME}] cmp $b->[$f{HOST_NAME}]
                    }
                 :  sub {
                    my %f = @_ ;

                    # package Nagios::Report ;
                    $b->[$f{HOST_NAME}] cmp $a->[$f{HOST_NAME}]
                    } ;
              return $r ;
            } else {
              my $fields = $sort_parms{fields} ;
              $r = $sort_parms{ascend}
                 ?  sub {
                    my %f            = @_ ;

                    my @field_indices    = @f{@$fields} ;

                    my $a_max        = &max_l( @{$a}[@field_indices] ) ;
                    my $b_max        = &max_l( @{$b}[@field_indices] ) ;
                    $a_max             <=> $b_max ;
                    }
                :  sub {
                    my %f            = @_ ;

                    my @field_indices    = @f{@$fields} ;

                    my $a_max        = &max_l( @{$a}[@field_indices] ) ;
                    my $b_max        = &max_l( @{$b}[@field_indices] ) ;
                    $b_max             <=> $a_max ;
                    } ;
              return $r ;
            }
                    
}

sub gen_local_cgi {
  my $user = shift @_ ;
                                                        # Generate a closure that will get an
                                                        # availability report by running the CGI
                                                        # from the shell.
  die "gen_local_cgi() called without username for access to local availability CGI: \$user: '$user'. Caller "
       . join(' ', caller)
    unless $user ;

  $ENV{REMOTE_USER}    = $user ;
  $ENV{REQUEST_METHOD} = REQUEST_METHOD ;

  return sub {
    my $url           = shift @_ ;
                                                        # Must convert URL to query_string 
    my $qs ;
       ($qs = $url)      =~ s|http:.*?\?|| ;

    $ENV{QUERY_STRING} = $qs ;
    my @x              = `${\NAG_AVAIL_CGI}` ;
                                                        # Drop HTTP headers
    splice @x, 0, 6 ;
    chomp  @x ;
    wantarray ? @x : join('', @x) ;
  } ;

}

sub gen_web_page {
  my ($user, $pass) = @_ ;

  die "gen_web_page() called without username or password for web page access: \$user: '$user', \$pass: '$pass'."
      . ' Caller ' . join(' ', caller)
    unless $user && $pass ;

  return sub {
                                                        # lynx -dump will render the page as text
                                                        # regardless of its content.
    USE_LYNX ?    `${\LYNX} -nolist -dump -width=1000 -auth=$user:$pass                '$_[0]'`
         :    `${\WGET} --output-document=- --http-user=$user --http-passwd=$pass  '$_[0]' 2>/dev/null` ;
  } ;
}

sub down_records {
  my ($data_source, $avail_url, $start_time) = @_ ;

  my $avail_rep = $data_source->($avail_url) ;

  my ($downs, @down_recs, @downs) ;

  if ( $avail_rep =~ /<html>/i ) {
                                                        # XXX
                                                        # Will fail if the availability CGI contains
                                                        # different tags
                                                        # <tr class='logEntriesEven'>
                                                        # <td class='logEntriesEven'>01-11-2005 00:00:00</td>
                                                        # <td class='logEntriesEven'>09-11-2005 15:09:59</td>
                                                        # <td class='logEntriesEven'>8d 15h 9m 59s</td>
                                                        # <td class='logEntriesUP'>HOST UP (HARD)</td>

    ($downs) = $avail_rep =~ /(<tr class='logEntriesEven'>.*)/s ;
    my @rows = $downs     =~ m|(<tr.*?/tr>)|g ;
    @down_recs            = map { s/<.*?>/ /g; $_ } @rows ;
  } else {
                                                        # Parsed HTML (by lynx -dump) looks like
                                                        # 01-11-2005 00:00:00 09-11-2005 15:09:59 8d 15h 9m 59s
                                                        # HOST UP (HARD)
    ($downs) = $avail_rep =~ m|( \d+-\d+-\d+ \s+ \d+:\d+:\d+ \s+ \d+-\d+-\d+ \s+ \d+:\d+:\d+ .* \Z) |msx ;
    @down_recs            = split /\n/, $downs ;
  }

  local $_ ;

  foreach (@down_recs) {

=begin comment

                                                        # Must also deal with scheduled downtime.

  01-02-2006 00:00:00  01-02-2006 14:27:54  0d 14h 27m 54s  HOST UP (HARD)  PING OK - Packet loss = 0%, RTA = 7.26 ms  
  02-02-2006 20:24:42  02-02-2006 20:24:42  0d 0h 0m 0s     HOST DOWN (HARD)  CRITICAL - Plugin timed out after 10 seconds  

                            VVVV This appears to be the correct entry
  02-02-2006 20:24:42  02-02-2006 20:47:54  0d 0h 23m 12s   HOST DOWNTIME START  Start of scheduled downtime  
                            ^^^^
  02-02-2006 20:47:54  02-02-2006 22:24:42  0d 1h 36m 48s   HOST UP (HARD)  PING OK - Packet loss = 0%, RTA = 0.66 ms  
  02-02-2006 22:24:42  03-02-2006 12:54:29  0d 14h 29m 47s  HOST DOWNTIME END  End of scheduled downtime  

=end comment

=cut

    next
      if /HOST UP|SERVICE OK|HOST DOWNTIME END/ ;

    my ($down, $up, $outage) = /
                (\d+-\d+-\d+ \s+ \d+:\d+:\d+) \s+
                (\d+-\d+-\d+ \s+ \d+:\d+:\d+) \s+
                ( (?:\d+[wdhms] \s*)+ )
                   /x ;

    next
      if &before_start($down, $start_time) ;

    $outage =~ s/^(?:0[wdh] )*//g ;

    push @downs, [$down, $up, $outage] ;
  }

  @downs = ( [ (' ') x 3 ] ) 
    unless @downs ;
  @downs 

}

sub before_start {
  my ($t1_str, $t2) = @_ ;
  my $t1 = &date2time($t1_str) ;

  return $t1 < $t2 ? 1 : 0 ;

}

sub date2time {
  local $_ = shift @_ ;

  my ($dd, $mm, $mon, $yyyy, $h, $m, $s) ;

  if ( ($dd, $mm, $yyyy, $h, $m, $s) = m< (\d+)-(\d+)-(\d+) \s+ (\d+):(\d+):(\d+) >x ) {
                                                        # 01-11-2005 00:00:00

                                                        # DD-MM-YYYY HH:MM:SS Euro style dates with day   first
    return EURO_DATE    ? timelocal($s, $m, $h, $dd, $mm - 1, $yyyy) 
                                                        # MM-DD-YYYY HH:MM:SS US   style dates with month first
                        : timelocal($s, $m, $h, $mm, $dd - 1, $yyyy)

  } elsif ( ($mon, $dd, $h, $m, $s, $yyyy) = /\w{3} (\w{3})\s+(\d+) (\d+):(\d+):(\d+) \w{3} (\d{4})/ ) {
                                                        # Tue Nov 29 20:19:17 EST 2005
    $mon = "\u\L$mon" ;
    $mm  = MONTH->{$mon} ;
    return timelocal($s, $m, $h, $dd, $mm - 1, $yyyy) ;
  } elsif ( /now/ ) {
    return time() + 0 ;
  } else {

  }

}

sub interval2time {
  local $_ = shift @_ ;
  my $t = 0 ;
  foreach my $x ( /(\d+[wdhms])/g ) {
                                                        # XXX
                                                        # Would be nice to do this without two matches but
                                                        # /g only counts the first match not the pair.
    my ($u, $b) = $x =~ /(\d+)([wdhms])/ ;
    $t += T->{$b} * $u ;
  }

  return $t ;

}

sub get_downs {
  my $r     = shift @_ ;

  my @downs = &down_records(@_) ;
  my @r     = map [ @$r, @$_ ], @downs ;
  @r ;
}

sub avail {
  my ($me, $rep_period) = @_ ;
     $rep_period      ||= '24x7' ;
  die "Non existent report period '$rep_period': choose from " . join(' ', keys %{$me->{AVAIL_REPORTS}}) . '. Outahere.' 
    unless exists $me->{AVAIL_REPORTS}{$rep_period} ;

  my @avail_recs        = @{ $me->{AVAIL_REPORTS}{$rep_period} } ;
  return wantarray
    ? @avail_recs 
    : Iterator    { shift @avail_recs ; } ;
}

sub report {
  my ($me, $rep_period) = @_ ;
     $rep_period      ||= '24x7' ;

  die "Non existent report period '$rep_period': choose from " . join(' ', keys %{$me->{REPORTS}}) . '. Outahere.' 
    unless exists $me->{REPORTS}{$rep_period} ;

  my @report_recs       = @{ $me->{REPORTS}{$rep_period}{RECORDS} } ;
  return wantarray
    ? @report_recs 
    : Iterator    { shift @report_recs ; } ;
}


sub to_dbh {
  my $me = shift @_ ;

  eval { require DBI } ;
  die "Jeff Zuckers's _excellent_ CPAN module, DBI is needed by to_dbh(). Outahere. "
    if $@ ;

  my @dbh = () ;
                                                        # Fruitless attempts to silence DBI - 
                                                        # this appears to be a known issue of DBD::AnyData
                                                        # as of Mar 2006.

                                                        # local $SIG{__WARN__} = sub {} ;

  foreach my $rep_period ( @{$me->REPORT_PERIODS} ) {

    my $dbh = DBI->connect('dbi:AnyData:') ;
                                                        # my $dbh = DBI->connect('dbi:AnyData(Warn => 0, ...
                                                        # Also fails to check warnings.
    $dbh->func(
    "tab_${rep_period}",
    'ARRAY',
    $me->{AVAIL_REPORTS}{$rep_period},
    # [ $me->avail($rep_period) ],
    { col_names => join(',', @{$me->FIELDNAMES}) },
    'ad_import'
    ) ;

    push @dbh, $dbh ;

  }

  @dbh ;

}

sub add_chart {
  my ($wkbook, $chart) = @_ ;

  die "add_chart() called without hash ref to chart details eg { template => '/path/to/chart/template', link => .. }. Outahere."
    unless ref($chart) eq 'HASH' ;

  die "add_chart() called without a well formed 'template' value in \$chart_detail. Must be to a filename containing the Chart template. Outahere."
    unless exists($chart->{template}) && $chart->{template} && -e $chart->{template} && -s $chart->{template} ;

                                                        # Add some extra formats to cover formats used in the charts.

  $wkbook->add_format(color => 1, bold => 1);
  $wkbook->add_format(color => 2);
  $wkbook->add_format(color => 3);

  $chart->{title} ||= 'Chart 24x7' ;
  $chart->{link}  ||= '=24x7!A1' ;

  $wkbook->add_chart_ext($chart->{template}, $chart->{title}) ;

  $wkbook->sheets(0)->store_formula($chart->{link}) ;

}
   
1 ;

# ---> That's all folks <-----

=head1 NAME

Nagios::Report - Perl class to filter and munge Nagios availability data

=head1 SYNOPSIS

  use Nagios::Report ;

  my $x = Nagios::Report->new(q<local_cgi nagios_web_server nagios_user>, [ '24x7' ], 'thismonth')
    or die "Can't construct Nagios::Report object." ;

  my @these_fields = qw(
    HOST_NAME
    PERCENT_TOTAL_TIME_UP
    TOTAL_TIME_DOWN
    TIME_DOWN_HHMMSS
    TOTAL_TIME_UNREACHABLE
    TIME_UNREACH_HHMMSS
    AVAIL_URL
    TREND_URL
  ) ;

  $x->mkreport(
                            # Field selector; display these fields only (in the listed order)

                            # [] means display all the fields.

        \@these_fields,
                            # Record selector

                            # Called with @_ loaded # with a list of field names and
                            # their vals for this record. Usually copied to a hash
                            # so it can be used as one.

                            # All records
                            #   sub { 1 },
                            # All records whose HOST_NAME starts with 'Alb'
                            #   sub { my %F = @_; my $h = $F{HOST_NAME}; $h =~ /^Alb/ },
                            # Regrettably, this is _NOT_ the same since
                            # @_ can't be used as a hash.
                            #   sub { $_{HOST_NAME} =~ /^Alb/ }
                            # All records with an up time percent < 98%

        sub { my %F = @_; my $u = $F{PERCENT_TOTAL_TIME_UP}; $u =~ s/%//; $u < 98 },

                            # Sort order

        &comp( alpha => 0, ascend => 0, fields => [ qw(TOTAL_TIME_DOWN TOTAL_TIME_UNREACHABLE) ]),

                            # Sorts descending by max of TOTAL_TIME_DOWN and TOTAL_TIME_UNREACHABLE

                            # DIY sorters remember that $a and $b _must_ be in Nagios::Report package.
                            # eg by TOTAL_DOWN_TIME descending.
                            #   sub { my %f = @_ ;
                            #         package Nagios::Report;
                            #         $b->[$f{TOTAL_TIME_DOWN}] <=> $a->[$f{TOTAL_TIME_DOWN}]
                            #        },
                            # Same as
                            #  &comp(alpha => 0, ascend => 0, fields => ['TOTAL_TIME_DOWN'])
                            # Same but harder,
                            #  sub { package Nagios::Report; $b->[16] <=> $a->[16] },

                            # Optional callback to add or mangle fields.

                            # Add 2 fields for downtime vals in hours minutes and secs.

        sub {    $F = shift @_;
            $F->{TIME_DOWN_HHMMSS}    =    t2hms( $F->{TOTAL_TIME_DOWN} ),
            $F->{TIME_UNREACH_HHMMSS}=    t2hms( $F->{TOTAL_TIME_UNREACHABLE} ) ;
            qw(TIME_DOWN_HHMMSS TIME_UNREACH_HHMMSS)
            }

  ) ;

  $x->debug_dump ;
                            # $x->csv_dump ;



=head1 DESCRIPTION

Gets the Nagios (http://wwww.Nagios.ORG/) B<All Hosts or Services> availability report (getting the results in CSV format)
and applies grep like filters, map like munging, and slice like field masks to produce a report which can be output in
various ways.

This class provides extra control over the content and disposition of the data produced by the
Nagios availability CGI, by writing for example a spreadsheet containing the selected data. 

Since the data originates from standard Nagios availability CGI, its results are no more accurate - and should be
exactly the same - as that CGI.


=head1 METHODS

=over 4

=item * new (DATA_SOURCE, REPORT_PERIODS, TIME_PERIOD, HOST_OR_SERVICE, PRE_FILTER)


This is the constructor of the Nagios::Report object.

C<DATA_SOURCE> is one of

  1 local_cgi - get the data by running the availability report CGI on the local host.
                Space separated values of the Nagios web server name/address and a Nagios user should follow.

  2 web_page  - get the data with LYNX or WGET from the named web server with the credential.
                Space separated values of the Nagios web server name/address, a Nagios user and that users password
                should follow.

  3 dev_debug - get __development__ data by running a client supplied callback.
                The _name_ of the callback should follow the tag, separated by spaces.
                NB the callback is assumed to be in the __main__ package.
                The callback is expected to return a string consisting of a schema
        (of CSV fieldnames) followed by lines of CSV data.

C<REPORT_PERIODS> is an optional reference to a list of names of Nagios time periods (conventionally defined in timeperiods.cfg) for which the availability data will be computed (by the CGI).

C<TIME_PERIOD> is an optional specification of the interval containing eligible availability records. It is scalar whose value 
is one of the Nagios interval names such as C<thisday>, C<thismonth>, or B<some> of the time forms used by the B<at> command.
(These forms include HHMM, HH:MM, DD.MM.YYYY MM/DD/YYYY and 24hour-time date). It can also be a month abbreviation followed by
any amount of white space and an optional 4 digit year. This form, like Mar 2006, selects all the days in that month. If the year
is missing, the month refers to this year.


Usually the timeperiod specifies an interval from some time in the past to now from which availability data will be selected.


However, if the argument is of the form B<start_24hour-time_date> B<-> B<end_24hour-time_date>, the availability data will be extracted from
the corresponding interval. 


If this argument is omitted, the report is compiled for the B<thismonth> time period (ie any host availability record from the first of the current
month to the current time).

C<HOST_OR_SERVICE> is an optional scalar specifying the service report instead of the host report. If not set, the host
report is produced.

C<PRE_FILTER> is a callback that is called with the B<%F> hash (vi) set to the values of the field names for this availability
record. The constructor saves the availability report for B<all> the hosts and therefore if mkreport() then
requests the down records (vi), the availability CGI will be run for every host, whether or not the
filter in mkreport() actually selects them. To eliminate this waste and speed up the report, supply a callback like
  sub { my %F = @_; $u = $F{PERCENT_TOTAL_TIME_UP}; $u =~ s/%//; $u < 99 } or
  sub { my %F = @_; $F{TOTAL_TIME_DOWN} >= 600 }

The constructor gets the Nagios availability data by running the all hosts or all services report (in CSV format) 
and storing it in the object.

=item * mkreport (FIELD_LIST, SELECTOR_CALLBACK, ORDER_CALLBACK, MUNGE_CALLBACK, DOWNS)

E<10>
C<FIELD_LIST> is a reference to an array containing the field names that will appear in the report (a logical slice of the reports fields).
The fields appear in the report in the same order they have in this list. Fields added by C<MUNGE_CALLBACK> B<must> be specified
by C<FIELD_LIST> or they will not be shown in the report B<unless> this parameter is omitted. If the C<FIELD_LIST> is omitted,
B<all> the fields appear in the report, no matter where they come from (ie if fields are added by the C<MUNGE_CALLBACK>, the
new fields will appear in the report). If a field in C<FIELD_LIST> does not exist in the schema, it will not
appear in the report; the caller B<must> spell the field names correctly.


C<SELECTOR_CALLBACK> is a reference to a user supplied subroutine that will return B<true> if the record is to be included in the report.
The subroutine is called with an argument list of field names and their values for this record. This argument list
can be copied to a hash in the callback, conventionally named B<%F>, so that the field names can be used in expressions like

$F{HOST_NAME} =~ /^foo/

to select eligible records.

C<ORDER_CALLBACK> is a reference to a user supplied sort subroutine that determines the order of the records in the report. The
subroutine is called with an argument list of field names and their offsets in the records (eg (HOST_NAME, 0)). This argument list
can be copied to a hash in the callback, conventionally named B<%f>, so that the field names can be used in expressions like

$a->[$f{TOTAL_TIME_DOWN}] <=> $b->[$f{TOTAL_TIME_DOWN}]

to sort the records based on the field values.

C<MUNGE_CALLBACK> is a reference to a user supplied subroutine that is used to munge (transform input to output) the records. The subroutine
is called with a pointer to a hash of field names and their values for this record. The callback is expected to modify the record
by setting the values of this hash, munging fields with expressions like

    $F->{TOTAL_TIME_DOWN} = 0

If the callback adds fields to the record, it should add the new field value in the same way (by setting a value for
a new key in the hash, like for example,

    $F->{TOTAL_TIME_DOWN_HMS} = t2hms($F->{TOTAL_TIME_DOWN})

).

If the callback adds no fields (modifies values only), it B<must> return an empty list.

A complete callback to set TOTAL_TIME_DOWN to zero is therefore

  sub {
      my $F = shift @_;
    $F->{TOTAL_TIME_DOWN} = 0;
    ()
  }

mkreport() takes the availability data for each time period, adds outage data (which involves duplicating the
C<original> availability record as many times as there are outages), does any specified munging,  applies the filter discarding
records not rated as C<interesting> by the selector callback, before sorting and
slicing the results - dropping fields unwanted fields - and storing them as a C<report> for each time period.

mkreport() must be run before any of the output methods.

C<DOWNS> is an optional scalar flag. If the flag is set the availability
report - the detailed report with the outage log - for B<each> host is fetched and the outage records extracted.

Then, for each of the outage records, the availability record is duplicated followed by the outage data: when the host went down, when
it came back up, and the hours minutes seconds formatted value of the outage. These fields are named DOWN, UP, and OUTAGE.

Since the availability data is repeated for each outage record, C<DOWNS> can make the report look messy. It is best used
with a small number of report fields (eg HOST_NAME, PERCENT_TOTAL_UP_TIME). Also, since the outage records are added B<before>
filtering by the selector callback, you B<should> set a pre-filter in the constructor.


The callbacks are run in this order

=over 4

=item 1 DOWNS (the availability report is retrieved for B<all> hosts/services so that the selector
        can filter on the added fields, by for example, discarding all records with small outages).

=item 2 MUNGE_CALLBACK

=item 3 SELECTOR_CALLBACK

=item 4 ORDER_CALLBACK

=item 5 the field slice (ie discard all but the FIELD_LIST fields)

=back

=item * to_dbh

If the DBD::AnyData module is installed, returns an array of DBI data handles
connected to the pseudo-databases containing one table populated
with the availability data corresponding to each of the REPORT_PERIODS
specified in the constructor call.

Each table is named C<tab_REPORT_PERIOD>. For example, after constructing the
Nagios::Report object with the default report period, the table is named B<tab_24x7>.

This method allows the use of SQL statements as an alternative means of filtering
and modifying the data. For example,

  $SQL =<<SQL;
  SELECT host_name,
       total_time_down,
       time_down_scheduled,
       time_down_unscheduled,
  FROM tab_24x7
    WHERE total_time_down   >= 300
  SQL

  $x   = Nagios::Report->new(local_cgi Nagios-server Nagios-contact) ;
  ($d) = $x->to_dbh ;
  $s   = $d->prepare($SQL) ;
  $s->execute ;
  $s->dump_results ;

Unfortunately, the use of DBD::AnyData does not invalidate this module because
the SQL grammar implemented by SQL::Statement (and used by DBD::AnyData) is not as
extensive as the SQL grammar provided by an RDBMS, or as useful as the record selector
mechanism provided by this.

If one is determined to process with SELECT, load the data into an RDBMS of choice ( 
MySQL comes to mind) and use the corresponding Perl DBD module on that. There is an example of
a script to do so included in the distribution.

Also, as of version 0.002, there were noisy complaints from DBI when DBD::AnyData
processes SQL.

=item * excel_dump (EXCEL_FILENAME, CHART_DETAIL)

excel_dump writes a Workbook in the specified filename. The workbook contains a worksheet for each report (ie one for each time period
specified by the constructor). excel_dump() requires the John McNamara's B<excellent> CPAN module, Spreadsheet::WriteExcel.

E<10>
C<EXCEL_FILENAME> is the path of the file in which the Excel workbook will be written.

C<CHART_DETAIL> is an optional reference to a hash that specifies the details of an Excel Chart that will be linked to the
data from the report.

The keys of his hash are

E<10>
template - the path to a binary file, produced by the Spreadsheet::WriteExcel chartex utility, containing the
chart to be linked to the data. 

link - an optional scalar that specifies the data to be linked to the chart. Defaults to "q<'24x7'!A1>".
You almost certainly will need to change this.

title - an optional scalar that specifies the name of the chart to be added to the workbook. Defaults to '24x7 Chart'.

Note that only one chart can be added to a workbook (by this module).

=item * csv_dump 

CSV formatted output on STDOUT. Note that this mainly useful for debugging since the 
cell data is not formatted should it be imported by Excel

=item * dev_debug (FIELD_WIDTH, FIELDS_PER_LINE)

report formatted output on STDOUT.

=head1 ACCESSORS/MUTATORS

Acessors and mutators are provided for most of the attributes in the object. The module makes B<no>
use of them and, except for those below, are probably of little interest. Unless noted, the caller is
responsible for processing the attribute type correctly; the acessor does nothing more
than hand back a ref.

=over 4

=item * report (REPORT_PERIOD)

Accessor that returns, in scalar context, an iterator that when kicked returns each of the
records produced by mkreport() for that report period; in array context, returns the list of those records.

Note that the 'records' are refs to anonymous lists containing only those fields specified by the field list parameter of
mkreport().

=item * avail (REPORT_PERIOD)

Accessor that returns, in scalar context, an iterator that when kicked returns each of the
records returned by the constructor; in array context, returns the list of those records.
Note that the 'records' are refs to anonymous lists containing all of the Nagios availability report fields
augmented by the two extra fields AVAIL_URL and TREND_URL (vi).

The iterator is a code ref that, when called, will return a ref to the next
availability record. Without a REPORT_PERIOD,
returns an iterator to the B<24x7> data, otherwise the availability data corresponding
to that report period (if it exists). If the methods of this class are not
useful, then the iterator allows the caller transform the availability data with
B<imap> and filter it with B<igrep>. 

=item * FIELDNAMES

Ref to a list of field names eg @fields = @{$me->FIELDNAMES}

=item * FIELDS

Ref to a hash of field indices keyed by field name eg %f = %{$me->FIELDS}}

=item * SERVER

Hostname of the server on which the Nagios CGIs can be found.

=item * SOURCE_TAG

How the availability data will be fetched.

=item * REPORT_TYPE

host | service report

=item * DATA_SOURCE

Reference to a subroutine that will fetch the availability data.

=item * REPORTS

Ref to a hash keyed by report period containing a hash keyed by FIELDNAMES and RECORDS.
The latter key refers to a list containing the records selected and munged by mkreport().
Note that each record contains only those fields specified by the field list parm of 
mkreport().

See report (REPORT_PERIOD).

=item * AVAIL_REPORTS

Ref to a hash keyed by report period containing a ref to a list containing all
those records returned by the Nagios availability report that are accepted by the
pre-filter.

Unlike REPORTS, each record contains all the Nagios reporting fields including
the fields AVAIL_URL and TREND_URL whose values are hyperlinks to the Nagios
trend and availability reports for the host named HOST_NAME.


See avail (REPORT_PERIOD).

=back

=head1 SUBROUTINES

=over 4

=item * max_l ( LIST_OF_NUMERIC_VALS)

Returns the maximum value in the list. Does not handle non-numeric values.

=item * comp ( OPTION_HASH )

Returns a ref to a comparator function that determines the order of the records and can be used 
as the B<ORDER_CALLBACK> argument of B<mkreport()>.

C<OPTION_HASH> is an B<optional> hash with keys

C<alpha> Sort by the HOST_NAME field if set, otherwise by the maximum of the fields value.

C<ascend> Sort in ascending order if set.

C<fields> The comparator function orders the records based on the B<maximum> of the B<numeric> field values. Only applies if alpha
is not set. C<fields> is a reference to an array of numeric field names. 

  eg &comp( alpha => 1, ascend => 1 )

  Returns a ref to function that orders the records by the HOST_NAME field.

  eg &comp()

  Same as calling comp with ( alpha => 1, ascend => 1 )

  eg &comp( alpha => 0, ascend => 1, fields => [TOTAL_TIME_DOWN, TOTAL_TIME_UNREACHABLE] )

  Returns a ref to a function that orders the records by the maximum of the values of the
  TOTAL_TIME_DOWN and TOTAL_TIME_UNREACHABLE fields.  


=item * t2hms (TIME_T)

Returns the argument formatted by weeks, days, hours, minutes and seconds eg &t2hms(300) -> 5m.

=item * d2t (time_string)

Returns the time_t value of the string formatted as either a localtime, US (MM-DD-YYYY) or EURO date (DD-MM-YYY).

=item * i2t (interval)

Returns the time_t value of the string formatted as an interval of time ie one that matches (?:\d+[wdhms]\s*)+
eg 3h 5m 30s (3 hours 5 minutes and 30 seconds).

=item * $st_et{TAG}->(TAG, [ STRUCT TM ] )

A hash of code refs indexed by an interval selecting tag. The second optinal argument is a ref to
a STRUCT TM. If this arg is missing, [localtime] is used.

Returns the pair of time_ts bounding the interval named by the tag. The
upper boundary of the interval is usually the time_t value corresponding to the second argument. The lower boundary is this less 
the tags value.

Tags include last_n_days, last_n_hours, last_n_mins, thisweek, lastweek, thismonth, lastmonth, thisyear, lastyear and variable strings like the 'at' style time stamps such as 'MMM YYYY' (eg Mar 2006) or HHMM DD.MM.YYYY. When the tag represents a fixed date or time, the interval
returned is from 'then' to 'now'.

When called by this module, the second argument is always 'now' (ie [localtime]).
eg join('-', map { scalar(localtime($_)) } $st_et{today}->('today') eq 'Fri Aug 18 00:00:00 2006-Fri Aug 18 10:13:00 2006'
eg join('-', map { scalar(localtime($_)) } $st_et{today}->('today', [ 0, 0, 0, 18, 7, 106])) eq 'Fri Aug 18 00:00:00 2006-Fri Aug 18 10:13:00 2006'



=back

=head1 BUGS

=over 4

=item * Does not do much more than the standard availability CGI. The reports
        has the same bugs as those produced by the CGI.

=item * The B<comp()> subroutine does not behave well if called with fields whose values are non numeric.

=item * The hand done date and time functions are poor.

=item * Anything good in this module comes from B<Higher Order Perl>; the rest comes from the author.

=item * The module does not buy much more than rolling ones own with DBD::AnyData. Had I been more
        aware of the fundamental utility and importance of RDBMS data, this module would probably
        not exist. OTOH, this module now provides some sort of programmatic access to Nagios availability
        data that Nagios has not had (AFAIK) hitherto.

=back


=head1 SEE ALSO

perl(1).

Nagios (http://www.Nagios.ORG/)


=head1 AUTHOR

Stanley Hopcroft <HopcroftS@CPAN.Org>

=head1 COPYRIGHT

Copyright (c) 2006 Stanley Hopcroft. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



