# Perl Module
# Purpose:  One Module to provide Syslog functionality
#           Provide log parser, sender, receiver
# Author    sparsons@cpan.org
#
#
# Version
#
#  0.8.0  - initial test release
#  0.8.1  - modify listener to make report and verbose > 1 independent 
#  0.8.2  - add counters for parse, filter, error
#  0.9.0  - db storage is indexed
#  0.9.1  - single quoted all hash index
#  0.9.2  - modify parse engine
#  1.0.0  - modify parse engine, user defined TAGS, forwarder in listen object
#

package Net::Dev::Tools::Syslog;

use strict;
use Time::Local;
use IO::Socket;
use Sys::Hostname;


BEGIN {
   use Exporter();
   our @ISA     = qw(Exporter);
   our $VERSION = 1.0.0;
}

#
# Tags
#
our @PARSER_func = qw(
   parse_syslog_line
   parse_syslog_msg
   parse_tag
   syslog_stats_epoch2datestr
);

our @TIME_func = qw(
   epoch_to_syslog_timestamp
   epoch_to_datestr
   make_timeslots
   epoch_timeslot_index
   date_filter_to_epoch
);

our @SYSLOG_func = qw(
   normalize_facility
   normalize_severity
   decode_PRI
);

our @REFERENCE_func = qw(
   syslog_stats_href
   syslog_device_aref
   syslog_facility_aref
   syslog_severity_aref
   syslog_tag_aref
   syslog_timeslot_aref
);

our @COUNTERS = qw(
   syslog_error_count
   syslog_filter_count
   syslog_parse_count
);





our @EXPORT = ('syslog_error', @PARSER_func, @TIME_func, @SYSLOG_func, @REFERENCE_func, @COUNTERS );
our @EXPORT_OK  = qw();

our %EXPORT_TAGS = (
   parser  => [@PARSER_func],
   time    => [@TIME_func],
   syslog  => [@SYSLOG_func],
   counter => [@COUNTERS],
);
#
# Global variables
#
our $SYSLOG_href;
our $ERROR;
our $ERROR_count;
our $FILTER_count;
our $PARSE_count;
our $DEBUG;
our %FH;
our %STATS;
our @DEVICES;
our @TAGS;
our @FACILITYS;
our @SEVERITYS;
our @TIMESLOTS;
our %LASTMSG;
our $NOTAG = 'noTag';

our $YEAR = ((localtime)[5]) + 1900;

our %WDAY = (
      '0' => 'Sun',
      '1' => 'Mon',
      '2' => 'Tue',
      '3' => 'Wed',
      '4' => 'Thu',
      '5' => 'Fri',
      '6' => 'Sat',
);

our %MON = (
   1  => 'Jan',   2  => 'Feb',   3  => 'Mar',
   4  => 'Apr',   5  => 'May',   6  => 'Jun',
   7  => 'Jul',   8  => 'Aug',   9  => 'Sep',
   10  => 'Oct',  11 => 'Nov',   12 => 'Dec',
);


our %MON_index = (
   'JAN'  => 1,   'Jan'  => 1,  'jan'  => 1,
   'FEB'  => 2,   'Feb'  => 2,  'feb'  => 2,
   'MAR'  => 3,   'Mar'  => 3,  'mar'  => 3,
   'APR'  => 4,   'Apr'  => 4,  'apr'  => 4,
   'MAY'  => 5,   'May'  => 5,  'may'  => 5,
   'JUN'  => 6,   'Jun'  => 6,  'jun'  => 6,
   'JUL'  => 7,   'Jul'  => 7,  'jul'  => 7,
   'AUG'  => 8,   'Aug'  => 8,  'aug'  => 8,
   'SEP'  => 9,   'Sep'  => 9,  'sep'  => 9,
   'OCT'  => 10,  'Oct'  => 10, 'oct'  => 10,
   'NOV'  => 11,  'Nov'  => 11, 'nov'  => 11,
   'DEC'  => 12,  'Dec'  => 12, 'dec'  => 12,
);


our %Syslog_Facility = (
   'kern'     => 0,    'kernel' => 0,
   'user'     => 1,
   'mail'     => 2,
   'daemon'   => 3,
   'auth'     => 4,
   'syslog'   => 5,
   'lpr'      => 6,
   'news'     => 7,
   'uucp'     => 8,
   'cron'     => 9,
   'authpriv' => 10,
   'ftp'      => 11,
   'ntp'      => 12,
   'audit'    => 13,
   'alert'    => 14,
   'at'       => 15,
   'local0'   => 16,
   'local1'   => 17,
   'local2'   => 18,
   'local3'   => 19,
   'local4'   => 20,
   'local5'   => 21,
   'local6'   => 22,
   'local7'   => 23,
);


our %Facility_Index = (
   0   => 'kern',
   1   => 'user',
   2   => 'mail',
   3   => 'daemon',
   4   => 'auth',
   5   => 'syslog',
   6   => 'lpr',
   7   => 'news',
   8   => 'uucp',
   9   => 'cron',
   10  => 'authpriv',
   11  => 'ftp',
   12  => 'ntp',
   13  => 'audit',
   14  => 'alert',
   15  => 'at',
   16  => 'local0',
   17  => 'local1',
   18  => 'local2',
   19  => 'local3',
   20  => 'local4',
   21  => 'local5',
   22  => 'local6',
   23  => 'local7',
);

our %Severity_Index = (
   0  => 'emerg',
   1  => 'alert',
   2  => 'crit',
   3  => 'err',
   4  => 'warn',
   5  => 'notice',
   6  => 'info',
   7  => 'debug'
);




our %Syslog_Severity = (
   'emerg'   => 0,   'emergency' => 0,
   'alert'   => 1,
   'crit'    => 2,   'critical' => 2,
   'err'     => 3,   'error'    => 3,
   'warn'    => 4,   'warning'  => 4,
   'notice'  => 5,
   'info'    => 6,   'information' => 6,  'informational' => 6,
   'debug'   => 7,
);


our @FACILITY = qw( kern     user     mail      daemon
                    auth     syslog   lpr       news    
                    uucp     cron     authpriv  ftp
                    ntp      audit    alert     at
                    local0   local1   local2    local3
                    local4   local5   local6    local7
);
our @SEVERITY = qw( emerg alert crit err warn notice info debug);

#
# syslog message
#   PRI HEADER MSG
#     PRI:    <0-161>
#     HEADER: TIMESTAMP HOST
#         TIMESTAMP Xxx dd hh:mm:ss
#                   Xxx  d hh:mm:ss
#         HOST  hostname or ip
#     MSG:    TAG Content
#         TAG no more than 32 chars
#             
#       

#
# Define Reg expr strings
#
# PRI
#   $1 = decimal value of PRI
#
our $PRI       = '<(\d{1,3})>';
#
# Timestamp
#    $1 = whole timestamp
#    $2 = Month string
#    $3 = Month day (decimal)
#    $4 = hh:mm::ss
#
our $TIMESTAMP_strict = '(([JFMASOND]\w\w) {1,2}(\d+) (\d{2}:\d{2}:\d{2}))'; 
our $TIMESTAMP        = '(([JFMASONDjfmasond]\w\w) {1,2}(\d+) (\d{2}:\d{2}:\d{2}))'; 

#
# Hostname 
# alphanumeric string including '_', '.'
#   $1 = hostname
#
our $HOSTNAME  = '([a-zA-Z0-9_\.\-]+)';


#
# let user define TAG patterns
# 
#   $TAG_1    $1 = tag, $2 = pid, $3 = content
#   $TAG_2    $1 = tag,           $2 = content   no pid
#   $TAG_3    $1 = tag, $2 = pid, $3 = content


our $TAG_1  = '';
our $TAG_2  = '';
our $TAG_3  = '';


#
# Content
#  $1 = message
our $MESSAGE = '(.+)$';



our $SYSLOG_pattern = sprintf("^%s{1} %s %s", $TIMESTAMP, $HOSTNAME, $MESSAGE);



#
#=============================================================================
#
#                Methods and Functions
#
#
# Syslog Constructor
#
# Use the anonymous hash to hold info for rest of module
#
# Arguments
#   dump        0|1        (0)  write to file
#   append      0|1        (1)  append to existing report
#   ext         extension  (.slp)
#   report      0|1        (1) create report
#   interval               report time slot interval
#   rx_time     0|1        determine if we should use msg time or preamble time
#   lastmsg     0|1        (0) do not use last message values
#   moreTime    0|1        (0) parse and calculate more time info
#   parseTag    0|1        (0) parse TAG from SYSLOG MESSAGE
#   debug       0-3        (0) debug level
#   format      <bsd|noHost|self> (bsd) syslog format line
#   filters
#     tag              string in tag to filter
#     min_date         min date mm/dd/yyyy hh:mm:ss
#     min_date_epoch   filter_min_date => epoch 
#     max_date         max date mm/dd/yyyy hh:mm:ss
#     max_date_epoch   max_date => epoch
#     device
#   format     format of expected syslog message
#              bsd         (timestamp, host, tag, content)
#              noHost      (timestamp,       tag, content)
#
#
 
sub parse {
   # create object
   my $_proto = shift;
   my $_class = ref($_proto) || $_proto;
   my $_this  = {};
   # bless object
   bless($_this, $_class);

   # get object arguments
   my %_arg = @_;
   my $_a;

   $ERROR = '';

   #rg{$_a}); define defaults
   $_this->{'ext'}      = 'slp';
   $_this->{'dump'}     = 0;      # default not to dump
   $_this->{'report'}   = 1;      # default to report
   $_this->{'append'}   = 0;      # default not to append
   $_this->{'interval'} = 3600;   # default timeslot interval
   $_this->{'rx_time'}  = 0;      # default to not use time stamp from preamble
   $_this->{'lastmsg'}  = 0;      # default to not redo last message when 'last msg' line
   $_this->{'debug'}    = 0;
   $_this->{'filter'}   = 0;      # default no filtering
   $_this->{'format'}   = 'bsd';  # default syslog message string to bsd
   $_this->{'moreTime'} = 0;      # default time analysis
   $_this->{'parseTag'} = 0;      # default tha parsing of TAGs
   
   foreach $_a (keys %_arg) {
      if    ($_a =~ /^-?dump$/i)        {$_this->{'dump'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?append$/i)      {$_this->{'append'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?ext$/i)         {$_this->{'ext'}        = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?report$/i)      {$_this->{'report'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?interval$/i)    {$_this->{'interval'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?rx_time$/i)     {$_this->{'rx_time'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?lastmsg$/i)     {$_this->{'lastmsg'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?debug$/i)       {$_this->{'debug'}      = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?min_date$/i)    {$_this->{'filter_min_date'} = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?max_date$/i)    {$_this->{'filter_max_date'} = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?device$/i)      {$_this->{'filter_device'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?tag$/i)         {$_this->{'filter_tag'}      = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?message$/i)     {$_this->{'filter_message'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?format$/i)      {$_this->{'format'}          = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?moreTime$/i)    {$_this->{'moreTime'}        = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?parseTag$/i)    {$_this->{'parseTag'}        = delete($_arg{$_a}); }
      else {
         $ERROR = "unsupported option  $_a => $_arg{$_a}";
         return(wantarray ? (undef, $ERROR) : undef);
      }
   }

   # set globals
   $DEBUG        = $_this->{'debug'};
   $ERROR_count  = 0;
   $FILTER_count = 0;
   $PARSE_count  = 0;

   # init stat hash
   if ($_this->{'report'}) {%STATS = ();}


   # check format
   if ($_this->{'format'} ne 'bsd'  &&  $_this->{'format'} ne 'noHost') {
      $ERROR = "unsupported format [$_this->{'format'}]";
      return(wantarray ? (undef, $ERROR) : undef); 
   }

   #
   # check arguments
   #
   # if dump is enabled,
   if ($_this->{'dump'}) {
         $_this->{'repository'} = $_this->{'dump'};
         # make sure we have trailing '/' or '\'
         if ($^O eq 'MSWin32') {
            if ($_this->{'repository'} !~ /\\$/)
               {$_this->{'repository'} = $_this->{'repository'} . '\\';}
         }
         else {
            if ($_this->{'repository'} !~ /\/$/)
               {$_this->{'repository'} = $_this->{'repository'} . '/';}
         }
         # check if writable
         if (!-w $_this->{'repository'}) {
            $ERROR = "dump site not writeable";
            $_this = undef;
            return(wantarray ? (undef, $ERROR) : undef);
         } 
   }
   #
   # interval can not be less than 1 min (60 sec), since the index
   # only goes down to the minute
   #
   if ($_this->{'interval'} < 60) { 
      $_this->{'interval'} = 60;
      log_debug(3, "NOTICE: interval changed to 60 seconds\n");
   }
   # filtering may need other settings enabled
   if ($_this->{'filter_min_date'} || $_this->{'filter_max_date'}) {$_this->{'moreTime'} = 1;}
   if ($_this->{'filter_device'})                                  {$_this->{'format'}   = 'bsd';}
   if ($_this->{'filter_tag'})                                     {$_this->{'parseTag'} = 1;}
   if ($_this->{'report'})                                         {$_this->{'moreTime'} = 1;}

   #
   # if we have any filters defined, then enable filtering
   #
   $_this->{'filter'} = 1 if $_this->{'filter_min_date'} || $_this->{'filter_max_date'} ||
                             $_this->{'filter_device'}   || $_this->{'filter_tag'} ||
                             $_this->{'filter_message'}; 

   # check min and max date
   if ($_this->{'filter_min_date'}) {
      log_debug(3, "convert min date: [%s]\n", $_this->{'filter_min_date'});
      $_this->{'filter_min_date_epoch'} = date_filter_to_epoch($_this->{'filter_min_date'});
      unless($_this->{'filter_min_date_epoch'}) {
         $ERROR = "min date filter epoch undefined";
         return(wantarray ? (undef, $ERROR) : undef);
      }
      log_debug(3, "converted min date to: [%s]\n", $_this->{'filter_min_date_epoch'},
         epoch_to_datestr($_this->{'filter_min_date_epoch'}),
      );
   }
   if ($_this->{'filter_max_date'}) {
      log_debug(3, "convert max date: [%s]\n", $_this->{'filter_max_date'});
      $_this->{'filter_max_date_epoch'} = date_filter_to_epoch($_this->{'filter_max_date'});
      unless($_this->{'filter_max_date_epoch'}) {
         $ERROR = "max date filter epoch undefined";
         return(wantarray ? (undef, $ERROR) : undef);
      }
      log_debug(3, "converted max date to: [%s]\n", $_this->{'filter_max_date_epoch'},
         epoch_to_datestr($_this->{'filter_max_date_epoch'})
      );
   }

   if ($_this->{'filter_min_date'} && $_this->{'filter_max_date'}) {
      log_debug(3, "check min and max date range\n");
      if ($_this->{'filter_min_date_epoch'} >= $_this->{'filter_max_date_epoch'}) {
         $ERROR = sprintf("filter_min_date >= filter_max_date: %s >= %s", 
            _commify($_this->{'filter_min_date_epoch'}), 
            _commify($_this->{'filter_max_date_epoch'}),
         );
         log_debug(2, "%s\n", $ERROR);
         return(wantarray ? (undef, $ERROR) : undef);
      }
      log_debug(3, "min max date range: [%s] => [%s]\n",
         $_this->{'filter_min_date'},  $_this->{'filter_max_date'},
      );
      log_debug(3, "min max date range: [%s] => [%s]\n",
         _commify($_this->{'filter_min_date_epoch'}),  _commify($_this->{'filter_max_date_epoch'})
      ); 
   }

   if ($DEBUG) {
      foreach (sort keys %{$_this}) {
         log_debug(2, "parse object properties: %-12s => [%s]\n", $_, $_this->{$_});
      }
   }

   # return reference to object
   return(wantarray ? ($_this, $ERROR) : $_this);

}  # end sub parse
#
#.............................................................................
#
#  Function to parse syslog line and populate hash ref $SYSLOG_href
#
#     $SYSLOG_href->{'line'}      current line from syslog file
#                   {'timestamp'} timestamp from syslog message
#                   {'device'}    device name from syslog message
#                   {'message'}   syslog message, from after devname
#  
#                   {'month_str'} month from syslog message timestamp (Jan, Feb, ..) 
#                   {'month'}     month index 0->11
#                   {'day'}       day from syslog message timestamp
#                   {'time_str'}  hh:mm:ss from syslog message timestamp
#                   {'hour'}      hh from syslog message timestamp
#                   {'min'}       mm from syslog message timestamp
#                   {'sec'}       ss from syslog message timestamp
#                   {'year'}      year assumed from localtime
#                   {'epoch'}     epoch time converted from syslog message timestamp
#                   {'wday'}      wday integer derived from epoch (0-6) = (Sun-Sat)
#                   {'wday_str'}  wday string converted, (Sun, Mon, ...)
#                   {'date_str'}  syslog message {'epoch'} convert to common format
#
#                   {'tag'}       syslog message content tag
#                   {'pid'}       syslog message content tag pid
#                   {'content'}   syslog message content after tag parsed out
#
#                   {'preamble'}
#                   {'rx_epoch'}     extra info: rx time epoch
#                   {'rx_timestamp'} extra info: rx timestamp
#                   {'rx_priority'}  extra info: priority (text)
#                   {'rx_facility'}  extra info: syslog facility (text)
#                   {'rx_severity'}  extra info: syslog severity (text)
#                   {'srcIP'}        extra info: src IP address
#
#                   {'rx_epoch'}     extra info: rx time epoch
#                   {'rx_date_str'}  extra info: rx time date string
#                   {'rx_time_str'}  extra info: rx time (hh:mm:ss)
#                   {'rx_year'}      extra info: rx time year value
#                   {'rx_month'}     extra info: rx time month value
#                   {'rx_month_str'} extra info: rx time month value string (Jan, Feb,..)
#                   {'rx_day'}       extra info: rx time day value
#                   {'rx_wday'}      extra info: rx time weekday (0-6) (Sun, Mon,..)
#                   {'rx_hour'}      extra info: rx time hour value
#                   {'rx_min'}       extra info: rx time minute value
#                   {'rx_sec'}       extra info: rx time second value
# Arg
#   $_[0] - line from syslog file
#
sub parse_syslog_line {
   my $_obj  = shift;
   my $_line = shift || $_;

   my ($_preamble, $_msg, $_ok, $_last);
   my @_pre = ();

   %{$SYSLOG_href} = ();

   $SYSLOG_href->{'device'} = '';
   $SYSLOG_href->{'format'} = $_obj->{'format'};

   $PARSE_count++;
   $_line =~ s/\n$//;
   $SYSLOG_href->{'line'} = $_line;

   log_debug(2, "func: parse_syslog_line\n");
   log_debug(1, "[%s]:  [%s]\n", $., $_line);

   # if given line is blank ignore it,
   # it can throw off the stats
   if ($_line =~ /^\s*$/) {
      $ERROR = 'disregarding current line: blank line';
      $ERROR_count++;
      return(wantarray ? (undef, $ERROR) : undef);
   }

   #
   # Set syslog message parser
   #
   if ($_obj->{'format'} eq "bsd") 
      {$SYSLOG_pattern = sprintf("%s{1} %s %s", $TIMESTAMP,$HOSTNAME,$MESSAGE);}
   elsif ($_obj->{'format'} eq "noHost")
      {$SYSLOG_pattern = sprintf("%s{1} %s", $TIMESTAMP, $MESSAGE);}
   elsif ($_obj->{'format'} eq "self")
      { 1; }
   else {
      $ERROR = "unsupported syslog message format: $_obj->{'format'}";
      $ERROR_count++;
      return(wantarray ? (undef, $ERROR) : undef);
   }
   log_debug(3, "pattern [%s]: %s\n", $_obj->{'format'}, $SYSLOG_pattern);


   # see if we have more than just the syslog message
   if    ($_line =~ /^(\<\d{1,3}\>)?($SYSLOG_pattern)/) {$_preamble = $1;    $_msg = $2}
   elsif ($_line =~ /^(.+)\s+($SYSLOG_pattern)/)  {$_preamble = $1;    $_msg = $2}
   elsif ($_line =~ /^(.+),($SYSLOG_pattern)/)    {$_preamble = $1;    $_msg = $2, 
                                                  $_preamble =~ s/\,/ /g; 
   }
   else                                          {$_preamble = undef; $_msg = $_line;}

   log_debug(2, "syslog preamble: %s\n", $_preamble || 'none');
   log_debug(2, "syslog message:  %s\n", $_msg      || 'NO MESSAGE');
   # 
   # parse syslog message
   #
   parse_syslog_msg($_msg, $_obj->{'moreTime'}, $_obj->{'parseTag'}, 1);
   if ($SYSLOG_href->{'device'} eq '' && $_obj->{'format'} ne 'noHost') {
      $ERROR = 'no device name parsed from line';
      $ERROR_count++; 
      #return(wantarray ? (undef, $ERROR) : undef);
   }
   #
   # if we have a preamble, parse it out
   #
   if ($_preamble) {
      $_preamble =~ s/UTC//;
      log_debug(2, "syslog line contains preamble:\n");
      # preamble:  yyyy-mm-dd hh:mm:ss prio ip
      parse_preamble($_preamble);

      # determine what time we want to keep
      if ($_obj->{'rx_time'}) {
         $SYSLOG_href->{'timestamp'} = $SYSLOG_href->{'rx_timestamp'} || $SYSLOG_href->{'timestamp'};
         $SYSLOG_href->{'epoch'}     = $SYSLOG_href->{'rx_epoch'}     || $SYSLOG_href->{'epoch'};
         $SYSLOG_href->{'month'}     = $SYSLOG_href->{'rx_month'}     || $SYSLOG_href->{'month'};
         $SYSLOG_href->{'month_str'} = $SYSLOG_href->{'rx_month_str'} || $SYSLOG_href->{'month_str'}; 
         $SYSLOG_href->{'day'}       = $SYSLOG_href->{'rx_day'}       || $SYSLOG_href->{'day'};
         $SYSLOG_href->{'time_str'}  = $SYSLOG_href->{'rx_time_str'}  || $SYSLOG_href->{'time_str'};
         $SYSLOG_href->{'hour'}      = $SYSLOG_href->{'rx_hour'}      || $SYSLOG_href->{'hour'};
         $SYSLOG_href->{'min'}       = $SYSLOG_href->{'rx_min'}       || $SYSLOG_href->{'min'};
         $SYSLOG_href->{'sec'}       = $SYSLOG_href->{'rx_sec'}       || $SYSLOG_href->{'sec'};
         $SYSLOG_href->{'year'}      = $SYSLOG_href->{'rx_year'}      || $SYSLOG_href->{'year'};
         $SYSLOG_href->{'wday'}      = $SYSLOG_href->{'rx_wday'}      || $SYSLOG_href->{'wday'};
         $SYSLOG_href->{'wday_str'}  = $SYSLOG_href->{'rx_wday_str'}  || $SYSLOG_href->{'wday_str'};
         $SYSLOG_href->{'date_str'}  = $SYSLOG_href->{'rx_date_str'}  || $SYSLOG_href->{'date_str'};
         
         log_debug(2, "INFO: using rx_time info instead of message timestamp info\n");
      }
   }

   #
   # make sure we have device name from the syslog line
   #
   log_debug(2, "device name check: dev: [%s] srcIP: [%s] \n", 
      $SYSLOG_href->{'device'}, $SYSLOG_href->{'rx_srcIP'}
   ); 

   # check we have device name
   if ($SYSLOG_href->{'device'}) {
      log_debug(2, "device name check: keep syslog message device name: %s\n", $SYSLOG_href->{'device'});
   }
   elsif ( $SYSLOG_href->{'rx_srcIP'} ) {
      log_debug(2, "device name change dev: [%s] <= srcIP [%s]\n",
         $SYSLOG_href->{'device'}, $SYSLOG_href->{'rx_srcIP'},
      );
      $SYSLOG_href->{'device'} = $SYSLOG_href->{'rx_srcIP'};
   }
   else {
      log_debug(2, "device name change: no device name or srcIP, change to noHost\n");
      $SYSLOG_href->{'device'} = 'noHost';
   }
   log_debug(2, "device name: set to [%s]\n", $SYSLOG_href->{'device'});



   #
   # check filters
   #
   if ($_obj->{'filter'}) {
      # check min date filter
      if ($_obj->{'filter_min_date_epoch'}) {
         log_debug(3, "INFO: MIN filter: min_date_epoch [%s] [%s]\n", 
            _commify($_obj->{'filter_min_date_epoch'}), $_obj->{'filter_min_date'},
         );
         if ($SYSLOG_href->{'rx_epoch'} && $_obj->{'rx_time'}) {
            log_debug(3, "rx_epoch and rx_time : true\n");
            log_debug(3, "is %s < %s\n", _commify($SYSLOG_href->{'rx_epoch'}), 
               _commify($_obj->{'filter_min_date_epoch'})
            );
            if ($SYSLOG_href->{'rx_epoch'} < $_obj->{'filter_min_date_epoch'}) { 
               $ERROR = sprintf("FILTER: rx date %s less than min filter date %s",
                  $SYSLOG_href->{'rx_date_str'}, $_obj->{'filter_min_date'}
               );
               log_debug(3, "%s\n", $ERROR);
               $FILTER_count++;
               return(wantarray ? (undef, $ERROR) : undef);
            }
         }
         elsif ($SYSLOG_href->{'epoch'}) {
            log_debug(3, "examine message timestamp epoch: %s\n", _commify($SYSLOG_href->{'epoch'}));
            log_debug(3, "check %s < %s\n", 
               _commify($SYSLOG_href->{'epoch'}), _commify($_obj->{'filter_min_date_epoch'})
            );
            if ($SYSLOG_href->{'epoch'} < $_obj->{'filter_min_date_epoch'}) {
               $ERROR = sprintf("FILTER: message date %s less than min filter date %s",
                  $SYSLOG_href->{'date_str'}, $_obj->{'filter_min_date'}
               );
               log_debug(3, "NULL line: %s\n", $ERROR);
               $FILTER_count++;
               return(wantarray ? (undef, $ERROR) : undef);
            }
            log_debug(3, "keep line\n");
         }
         else {
            $ERROR = sprintf("assert min date filter: no date from message");
            log_debug(3, "%s\n", $ERROR);
            $FILTER_count++;
            $ERROR_count++;
            return(wantarray ? (undef, $ERROR) : undef);
         }
      }
      # check max date filter
      if ($_obj->{'filter_max_date_epoch'}) {
         log_debug(3, "INFO: MAX filter: max_date_epoch [%s]\n", 
            _commify($_obj->{'filter_max_date_epoch'}), $_obj->{'filter_max_date'},
         );
         if ($SYSLOG_href->{'rx_epoch'} && $_obj->{'rx_time'}) { 
            log_debug(3, "rx_epoch and rx_time : true\n");
            log_debug(3, "is %s < %s\n", _commify($SYSLOG_href->{'rx_epoch'}),
               _commify($_obj->{'filter_max_date_epoch'})
            );
            if ($SYSLOG_href->{'rx_epoch'} > $_obj->{'filter_max_date_epoch'}) { 
               $ERROR = sprintf("FILTER: rx date %s greater than than max filter date %s",
                  $SYSLOG_href->{'rx_date_str'}, $_obj->{'filter_max_date'}
               ); 
               log_debug(3, "%s\n", $ERROR);
               $FILTER_count++;
               return(wantarray ? (undef, $ERROR) : undef); 
            }
         }
         elsif ($SYSLOG_href->{'epoch'}) {
            log_debug(3, "examine message timestamp epoch: %s\n", _commify($SYSLOG_href->{'epoch'}));
            log_debug(3, "check %s < %s\n",
               _commify($SYSLOG_href->{'epoch'}), _commify($_obj->{'filter_max_date_epoch'})
            );
            if ($SYSLOG_href->{'epoch'} > $_obj->{'filter_max_date_epoch'}) {
               $ERROR = sprintf("FILTER: message date %s greater than max filter date %s",
                  $SYSLOG_href->{'date_str'}, $_obj->{'filter_max_date'}
               );
               log_debug(3, "NULL line: %s\n", $ERROR);
               $FILTER_count++;
               return(wantarray ? (undef, $ERROR) : undef);
            }
            log_debug(3, "keep line\n");
         }
         else {
            $ERROR = sprintf("assert min date filter: no date from message");
            log_debug(3, "%s\n", $ERROR);
            $FILTER_count++;
            $ERROR_count++;
            return(wantarray ? (undef, $ERROR) : undef);
         }
      }
      # check device filter
      if ($_obj->{'filter_device'}) {
         if ($SYSLOG_href->{'device'} !~ /$_obj->{'filter_device'}/) {
            $ERROR = sprintf("FILTER: device [%s] not match filter [%s]", 
                     $SYSLOG_href->{'device'}, $_obj->{'filter_device'}
            );
            $FILTER_count++;
            return(wantarray ? (undef, $ERROR) : undef);
         }
      }
      # check tag filter
      if ($_obj->{'filter_tag'}) {
         if ($SYSLOG_href->{'tag'} !~ /$_obj->{'filter_tag'}/) { 
            $ERROR = sprintf("FILTER: tag [%s] not match filter [%s]", 
               $SYSLOG_href->{'tag'}, $_obj->{'filter_tag'}
            );
            $FILTER_count++;
            return(wantarray ? (undef, $ERROR) : undef);
         }
      }
      # check message filter
      if ($_obj->{'filter_message'}) {
         if ($SYSLOG_href->{'message'} !~ /$_obj->{'filter_message'}/) { 
            $ERROR = sprintf("FILTER: message not match filter [%s]", $_obj->{'filter_message'});
            $FILTER_count++;
            return(wantarray ? (undef, $ERROR) : undef);
         }
      }
   }  # end filtering

   # 
   # Dump and/or Report line
   #
   # if a 'last message line'
   if ($_obj->{'lastmsg'} && $SYSLOG_href->{'line'} =~ /last message repeated (\d+) time/) {
      $_last = $1;
      $SYSLOG_href = undef;
      %{$SYSLOG_href} = %LASTMSG;
      log_debug(2, "syslog line repeated: [%s] times\n", $_last);
      foreach  (1..$_last) {
         log_debug(3, "syslog line repeat: [%s]\n", $_);
         if ($_obj->{'dump'}) 
            {&dump_line_to_file($_obj, $SYSLOG_href->{'device'}, $SYSLOG_href->{'line'});}
         if ($_obj->{'report'}) 
            {&syslog_stats;}
      } 
   }
   else {
      # see if we want to dump file
      if ($_obj->{'dump'} && $SYSLOG_href->{'device'}) {
         ($_ok, $ERROR) = &dump_line_to_file($_obj, $SYSLOG_href->{'device'}, $_line);
         unless ($_ok)
            {return(wantarray ? (undef, $ERROR) : undef);}
      }

      # see if we want a report
      if ($_obj->{'report'}) 
         {&syslog_stats;}
   }

   # store this line for next iteration
   %LASTMSG = %{$SYSLOG_href};

   {return(wantarray ? ($SYSLOG_href, $ERROR) : $SYSLOG_href);}

}   # end parse_syslog_line 
#
#.............................................................................
#
# Function/method to parse portion of syslog line thought to contain
# the syslog message
#
# Break syslog line into parts
#   timestamp device message
#                  message = tag content
#
# $_[0] - syslog line or rfc 3164 portion
# $_[1] - more time info
#             0 - do not derive more time info
#             1 - derive more time info
# $_[2] - parse tag
#              0 - do not try to parse tag info from messag
#              1 - parse tag and content
# $_[3] - undef | 1  
#                     1 set if called internally, populate hash 
#                     0 returns has reference
#
# Return
#   (timestamp, host, message, $ERROR) : \%hash


sub parse_syslog_msg {

   my $_msg       = shift;
   my $_moretime  = shift || 0;
   my $_parsetag  = shift || 0; 
   my $_ret       = shift || 0;

   my ($_ok, $_err,
       $_x1, $_x2, 
   );

   log_debug(2, "func parse_syslog_msg:\n");
   log_debug(3, "format: [%s] pattern: %s\n", $SYSLOG_href->{'format'}, $SYSLOG_pattern);

   #
   # Match Sylog pattern and extract parts for desired format
   #
   if ($_msg =~ /$SYSLOG_pattern/) {
      log_debug(1, "matched syslog_pattern\n");
      # bsd format
      if ($SYSLOG_href->{'format'} eq 'bsd' or $SYSLOG_href->{'format'} eq 'self') {
         # timstamp anchors
         $SYSLOG_href->{'timestamp'} = $1;
         $SYSLOG_href->{'month_str'} = $2;
         $SYSLOG_href->{'day'}       = $3;
         $SYSLOG_href->{'time_str'}  = $4;
         # hostname
         $SYSLOG_href->{'device'}    = $5;
         # Message
         $SYSLOG_href->{'message'}   = $6;
      }
      # noHost format
      elsif ($SYSLOG_href->{'format'} eq 'noHost') {
         # timstamp anchors
         $SYSLOG_href->{'timestamp'} = $1;
         $SYSLOG_href->{'month_str'} = $2;
         $SYSLOG_href->{'day'}       = $3;
         $SYSLOG_href->{'time_str'}  = $4;
         # Message
         $SYSLOG_href->{'message'}   = $5;
      }
      else {
         $ERROR = "unmatched syslog_pattern: $SYSLOG_href->{'format'}";
         log_debug(1, "%s\n", $ERROR);
         if ($_ret) {return(undef);}
         return(wantarray ? (undef, undef, undef, $ERROR) : undef);
      }
   }
   else {
      $ERROR = 'syslog message line does not match syslog_pattern';
      log_debug(1, " %s\n", $ERROR);
      if ($_ret) {return(undef);}
      return(wantarray ? (undef, undef, undef, $ERROR) : undef);
   }
   if ($DEBUG) {
         log_debug(1, "timestamp: [%s]\n", $SYSLOG_href->{'timestamp'});
         log_debug(1, "device:    [%s]\n", $SYSLOG_href->{'device'});
         log_debug(1, "message:   [%s]\n", $SYSLOG_href->{'message'});
   }

   #
   # see if device has been substituted with ip:port info [a.a.a.a.p.p]
   # such as 10.1.1.1.4.0
   # convert last two octets to srcPort
   #   convert decimal octet to hex, join together, convert hex to decimal
   if ($SYSLOG_href->{'device'} =~ /(\d+\.\d+\.\d+\.\d+)\.(\d+)\.(\d+)/) {
      $SYSLOG_href->{'device'} = $1;
      $SYSLOG_href->{'device_port'} = hex( join('', sprintf("%02x", $2), sprintf("%02x", $3))); 
   }
   else {
      $SYSLOG_href->{'device_port'} = '?';
   }


   #
   # Get more info from timestamp
   #
   if ($_moretime) {
      if ( defined($SYSLOG_href->{'timestamp'}) ) {
         # Mmm  d hh:mm:ss    mmm  d hh:mm:ss
         # Mmm dd hh:mm:ss    mmm dd hh:mm:ss
         if ($SYSLOG_href->{'timestamp'} =~ /[JFMASOND]\w\w\s+\d+\s(\d\d):(\d\d):(\d\d)/i) {
            $SYSLOG_href->{'hour'}      = $1;
            $SYSLOG_href->{'min'}       = $2;
            $SYSLOG_href->{'sec'}       = $3;
   
            $SYSLOG_href->{'month'}     = $MON_index{$SYSLOG_href->{'month_str'}};
            $SYSLOG_href->{'year'}      = $YEAR;
            log_debug(2, 
               "syslog message timestamp values: Mmm: [%s] [%s] dd: [%s] hh: [%s] mm: [%s] ss: [%s]\n",
               $SYSLOG_href->{'month_str'}, $SYSLOG_href->{'month'},
               $SYSLOG_href->{'day'}, $SYSLOG_href->{'hour'},
               $SYSLOG_href->{'min'}, $SYSLOG_href->{'sec'}
            );
    
            # determine some time info
            #   year, epoch seconds, weekday
            #
            ($SYSLOG_href->{'epoch'}, $SYSLOG_href->{'wday'}) = &_extra_time_values(
                  $SYSLOG_href->{'sec'}, $SYSLOG_href->{'min'}, $SYSLOG_href->{'hour'},
                  $SYSLOG_href->{'day'}, $SYSLOG_href->{'month'},
            );
            $SYSLOG_href->{'wday_str'} = $WDAY{$SYSLOG_href->{'wday'}};
            $SYSLOG_href->{'date_str'} = &epoch_to_datestr($SYSLOG_href->{'epoch'});
    
            log_debug(2, "syslog message timestamp extra: yyyy: [%s] epoch: [%s] wday: [%s] [%s]\n",
                  $SYSLOG_href->{'year'}, $SYSLOG_href->{'epoch'}, $SYSLOG_href->{'wday'},
                  $SYSLOG_href->{'wday_str'}
            );
         }
      }
      else {
         $ERROR = "unsupported timestamp syntax: $SYSLOG_href->{'timestamp'}";
         log_debug(1, "%s\n", $ERROR);
         if ($_ret) {return(undef);}
         else       {return(wantarray ? (undef, undef, undef, $ERROR) : undef) }
      }
   }

   # 
   # Check if we got a TAG, if try to find one
   #
   if ($_parsetag) {
      if (defined($SYSLOG_href->{'message'})) {
         ($SYSLOG_href->{'tag'}, $SYSLOG_href->{'pid'}, $SYSLOG_href->{'content'}) = 
            parse_tag($SYSLOG_href->{'message'}
         );
         log_debug(2, "syslog message tag: [%s] pid: [%s]\n", 
            $SYSLOG_href->{'tag'}, $SYSLOG_href->{'pid'}
         );
         log_debug(2, "syslog message content: %s\n", $SYSLOG_href->{'content'});
      }
      else {
         log_debug(2, 'no message to parse tag from');
      }   
   }
   else {
      $SYSLOG_href->{'content'} = $SYSLOG_href->{'message'};
      log_debug(2, "parseTag [$_parsetag], content = message\n");
   }


   # return some values
   if ($_ret) {return(1);}
   else {
      return(wantarray ? ($SYSLOG_href->{'timestamp'},
                          $SYSLOG_href->{'device'},
                          $SYSLOG_href->{'message'},
                          undef,
                         )
                         : $SYSLOG_href
      );
   }
}   # end parse_syslog_msg 
#
#.............................................................................
#
#  function to parse preamble
#     yyyy-mm-dd hh:mm::ss facility.severity src_ip
#     mm-dd-yyyy hh:mm::ss facility.severity src_ip
#
#  Arg
#   $_[0]  preamble
#
# Return
#   (epoch, date, facility, severity, srcIP)
#
sub parse_preamble  {

   my @_tokens = ();
   my ($_t, $_epoch, $_timestamp, $_date, $_time,
       $_yr, $_mon, $_day,
       $_hr, $_min, $_sec,
       $_prio, $_fac, $_sev, $_srcIp
   );

   if ($_[0] =~ /^<(\d+)>$/) {
      $_prio = $1;
      @_tokens= decode_PRI($_prio);
      $_prio = $_tokens[3];
      $_fac  = $_tokens[4];
      $_sev  = $_tokens[5];
   }
   else {
      @_tokens = split(/\s+/, $_[0]);
      foreach $_t (@_tokens) {
         # yyyy-mm-dd
         if ($_t =~ /(\d\d\d\d)\-(\d\d)\-(\d\d)/) {
            $_yr  = $1;  $_mon = $2;   $_day = $3;
            $_date = $_t;
         }
         # mm-dd-yyyy
         if ($_t =~ /(\d\d)\-(\d\d)\-(\d\d\d\d)/) {
            $_mon = $1; $_day = $2; $_yr = $3;
            $_date = $_t;
         }
         # hh:mm::ss
         if ($_t =~ /(\d\d):(\d\d):(\d\d)/) {
            $_hr = $1;  $_min = $2;   $_sec = $3; 
            $_time = $_t;
         }
         # facility.severity
         if ($_t =~ /([a-zA-Z0-9]+)\.([a-zA-Z]+)/)
            {$_fac = $1;  $_sev = $2;  $_prio = $_t;}
         # source IP
         if ($_t =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)
            {$_srcIp = $1;}
      }
      $_timestamp = sprintf("%s %s", $_date, $_time);
      $_timestamp =~ s/^\s+//;
      $_timestamp =~ s/\s+$//;
    
      if (defined($_hr) && defined($_day) ) {
         $_epoch = timelocal($_sec, $_min, $_hr, $_day, $_mon-1, $_yr);
      }
      else {
         $_epoch = '??';
      }
   }

   $SYSLOG_href->{'preamble'}      = $_[0];

   if ($_prio) {
      $SYSLOG_href->{'rx_priority'}   = $_prio;
      $SYSLOG_href->{'rx_facility'}   = $_fac;
      $SYSLOG_href->{'rx_severity'}   = $_sev;
   }

   if ($_timestamp) {
      $SYSLOG_href->{'rx_timestamp'}  = $_timestamp;
      $SYSLOG_href->{'rx_epoch'}      = $_epoch;
      $SYSLOG_href->{'rx_date_str'}   = epoch_to_datestr($SYSLOG_href->{'rx_epoch'});
      $SYSLOG_href->{'rx_year'}       = $_yr;
      $SYSLOG_href->{'rx_month'}      = $_mon-1;
      $SYSLOG_href->{'rx_month_str'}  = $MON{$_mon-1};
      $SYSLOG_href->{'rx_day'}        = $_day;
      $SYSLOG_href->{'rx_wday'}       = (localtime($SYSLOG_href->{'rx_epoch'}))[6];
      $SYSLOG_href->{'rx_wday_str'}   = $WDAY{$SYSLOG_href->{'rx_wday'}};
      $SYSLOG_href->{'rx_time_str'}   = $_time;
      $SYSLOG_href->{'rx_hour'}       = $_hr;
      $SYSLOG_href->{'rx_min'}        = $_min;
      $SYSLOG_href->{'rx_sec'}        = $_sec;
   }

   if ($_srcIp) {
      $SYSLOG_href->{'rx_srcIP'}      = $_srcIp;
   }

   # normalize facility and severity strings
   if (!defined($Syslog_Facility{$SYSLOG_href->{'rx_facility'}})) {
      $SYSLOG_href->{'rx_facility'} = normalize_facility($SYSLOG_href->{'rx_facility'});
      log_debug(3, "normalized facility string to [%s]\n",$SYSLOG_href->{'rx_facility'});
   }
   if (!defined($Syslog_Severity{$SYSLOG_href->{'rx_severity'}})) {
      $SYSLOG_href->{'rx_severity'} = normalize_severity($SYSLOG_href->{'rx_severity'});
      log_debug(3, "normalized severity string to [%s]\n", $SYSLOG_href->{'rx_severity'});
   }


   if ($DEBUG) {
      log_debug(2, "syslog line preamble: timestamp: [%s] priority: [%s] srcIP: [%s]\n",
         $SYSLOG_href->{'rx_timestamp'}, $SYSLOG_href->{'rx_priority'},
         $SYSLOG_href->{'rx_srcIP'}
      );
      log_debug(3, "syslog line preamble: epoch: [%s] facility: [%s] severity: [%s]\n",
         $SYSLOG_href->{'rx_epoch'}, $SYSLOG_href->{'rx_facility'}, $SYSLOG_href->{'rx_severity'}
      );
      log_debug(3, "syslog line preamble: datestr: [%s]\n",
         $SYSLOG_href->{'rx_date_str'}
      );
   }

   1;

}   # parse_preamble


#
#.............................................................................
#
# function to parse tag/pid
# Argument
#   $_[0] string to find tag in
# Return
# (tag,pid)
#
sub parse_tag {

   my $_tag     = '';
   my $_pid     = '';
   my $_content = '';
   my $_match   = 0;

   log_debug(2, "parse tag from: [%s]\n", $_[0]);

   #
   # see if match a user defined pattern
   #
   if ($TAG_1 || $TAG_2 || $TAG_3) {
      log_debug(3, "tag match: user defined %s %s %s\n",
         defined($TAG_1) ? 1 : '-',
         defined($TAG_2) ? 2 : '-',
         defined($TAG_3) ? 3 : '-',     
      );
      if ($TAG_1 && $_[0] =~ /$TAG_1/) {
         $_tag     = $1;
         $_pid     = $2;
         $_content = $3;
         log_debug(3, "tag match: TAG_1  tag: [%s] pid: [%s]\n",
               $_tag, $_pid
         );
      }
      elsif ($TAG_2 && $_[0] =~ /$TAG_2/) {
         $_tag     = $1;
         $_pid     = '';
         $_content = $2;
         log_debug(3, "tag match: TAG_2  tag: [%s] pid: [%s]\n",
            $_tag, $_pid
         );
      }
      elsif ($TAG_3 && $_[0] =~ /$TAG_3/) {
         $_tag     = $1;
         $_pid     = $2;
         $_content = $3;
         log_debug(3, "tag match: TAG_3  tag: [%s] pid: [%s]\n",
            $_tag, $_pid
         );
      }
      else {
         log_debug(3, "tag match: user defined not matched\n");
      }
      #$_content =~ s/^ +//;
      return($_tag, $_pid, $_content);
   }

   #
   # If we are this point, try to match some of these common ones
   #
   #
   # tag[pid]: content   pid delimited with []
   if    ($_[0] =~ /^(([\w\d]+)\[([\w\d]+)\]:){1,32}? *(\w+.+)/) {
      $_tag     = $2;
      $_pid     = $3;
      $_content = $4;
      $_match   = 1;
   }
   # 
   # tag[pid]: content   pid delimited with non-alphnumeric
   elsif    ($_[0] =~ /^(([\w\d\-_]+)\W([\w\d]+)\W:){1,32}? *(\w+.+)/) {
      $_tag     = $2;
      $_pid     = $3;
      $_content = $4;
      $_match   = 2;
   }
   # tag[pid] content pid delimited with non-alphnumeric no colon
   elsif    ($_[0] =~ /^(([\w\d\-_]+)\W([\w\d]+)\W){1,32}? *(\w+.+)/) {
      $_tag     = $2;
      $_pid     = $3;
      $_content = $4;
      $_match   = 3;
   }
   elsif    ($_[0] =~ /^(([\w\d\-_]+)\W([\w\d]+)\W){1,32}? *(.+)/) {
      $_tag     = $2;
      $_pid     = $3;
      $_content = $4;
      $_match   = 4;
   }

   # last message
   elsif ($_[0] =~ /last message repeated (\d+) time/) {
      $_tag     = 'lastmsg';
      $_pid     = $1;
      $_content = '';
      $_match   = 'last';
   }
   else  {
      $_tag     = 'NOTAG';
      $_pid     = 'NOPID';
      $_content = $_[0];
      log_debug(3, "tag match: none, set content = message\n");
   }

   log_debug(3, "tag match: pattern [%s]  tag: [%s] pid: [%s]\n",
      $_match, $_tag, $_pid
   );
   #$_content =~ s/^ +//;
   return($_tag, $_pid, $_content);
}


#
#.............................................................................
#
#  Init the object
sub init {
   #$SYSLOG_href = {};
   %{$SYSLOG_href} = ();
}
#
#=======================================================================
#
#                   Syslog Send Message
#
#=======================================================================
#
#
#........................................................................
#
# Syslog Send message constructor
#
# Args
#   server     => <syslog server>
#   port       => <syslog port>  (514)
#   facility   => <facility> 
#   severity   => <severity>
#   tag        => <tag>
#   timestamp  => <timstamp>   # timestamp value to use in syslog message
#   device     => <devname>    # device name to use in syslog message
#   tag        => <string>     # tag string to use in syslog message
#   pid        => <pid>        # pid to append to tag enclosed in []
#   message    => <message>    # message to send
#   content    => <content>    # content of message
#   strict     => 0|1          # enforce message syntax rules
#   noHost     => 0|1          # whether we should put HOSTNAME in message
#   noTag      => 0|1          # hether we should put TAG in message
#   debug      => 0-5          # debug

sub send {

   # create object
   my $_proto = shift;
   my $_class = ref($_proto) || $_proto;
   my $_send  = {};
   # bless object
   bless($_send, $_class);

   $ERROR = '';

   my %_arg = @_;
   my $_a;

   # default some values
   $_send->{'server'}    = '127.0.0.1';
   $_send->{'port'}      = '514';
   $_send->{'proto'}     = 'udp';
   $_send->{'facility'}  = 'user';
   $_send->{'severity'}  = 'debug';
   $_send->{'strict'}    = 1;
   $_send->{'noHost'}    = 0;
   $_send->{'noTag'}     = 0;
   $_send->{'debug'}     = 0;

   # check arguments
   foreach $_a (keys %_arg) {
      if    ($_a =~ /^-?server/)    { $_send->{'server'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?port/)      { $_send->{'port'}      = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?proto/)     { $_send->{'proto'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?facility/)  { $_send->{'facility'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?severity/)  { $_send->{'severity'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?timestamp/) { $_send->{'timestamp'} = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?device/)    { $_send->{'device'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?tag/)       { $_send->{'tag'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?pid/)       { $_send->{'pid'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?content/)   { $_send->{'content'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?message/)   { $_send->{'message'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?strict/)    { $_send->{'strict'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?noHost/)    { $_send->{'noHost'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?hostname/)  { $_send->{'hostname'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?noTag/)     { $_send->{'noTag'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?debug/)     { $_send->{'debug'}     = delete($_arg{$_a}); }
      else {
         $ERROR = sprintf("unsupported argument: %s => %s", $_a, $_arg{$_a});
         return(wantarray ? (undef, $ERROR) : undef);
      }
   }
   return(wantarray ? ($_send, $ERROR) : $_send);
}


#
#.............................................................................
#
# send message
#  max length = 1024
#  PRI HEADER MSG
#    PRI 3,4 or 5 char bounded by '<' '>'
#      <#>
#
sub send_message {

   my $_send = shift;
   my ($_facility, $_severity, 
       $_timestamp, $_devname, $_tag, $_pid, $_message,
       $_pri, $_content, $tx_msg, $msg_l, $tag_l,
       $_sock,
   );

   $ERROR = '';

   my %_arg = @_;
   my $_a;
   my $_format = '';

   # check arguments
   foreach $_a (keys %_arg) {
      if    ($_a =~ /^-?server/)    { $_send->{'server'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?port/)      { $_send->{'port'}      = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?facility/)  { $_send->{'facility'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?severity/)  { $_send->{'severity'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?timestamp/) { $_send->{'timestamp'} = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?device/)    { $_send->{'device'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?tag/)       { $_send->{'tag'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?pid/)       { $_send->{'pid'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?content/)   { $_send->{'content'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?message/)   { $_send->{'message'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?strict/)    { $_send->{'strict'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?noHost/)    { $_send->{'noHost'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?hostname/)  { $_send->{'hostname'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?noTag/)     { $_send->{'noTag'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?debug/)     { $_send->{'debug'}     = delete($_arg{$_a}); }
      else {
         $ERROR = sprintf("unsupported argument: %s => %s", $_a, $_arg{$_a});
         return(wantarray ? (undef, $ERROR) : undef);
      }
   }

   # error check facility and severity value
   if (!defined($Syslog_Facility{$_send->{'facility'}})) {
      $ERROR = "unsupported argument: facility => $_send->{'facility'}";
      return(wantarray ? (undef, $ERROR) : undef);
   }
   if (!defined($Syslog_Severity{$_send->{'severity'}})) {
      $ERROR = "unsupported argument: severity => $_send->{'severity'}";
      return(wantarray ? (undef, $ERROR) : undef);
   }

   $_tag     = undef;
   $_message = '';

   $DEBUG = $_send->{'debug'};


   $_facility = $Syslog_Facility{$_send->{'facility'}};
   $_severity = $Syslog_Severity{$_send->{'severity'}};
   # PRI = (facility x 8) + severity
   $_pri = ($_facility * 8) + $_severity;

   # 
   # TIMESTAMP
   #
   # use timestamp given 
   if ($_send->{'timestamp'}) {
      if (!validate_timestamp_syntax($_send->{'timestamp'})) {
         $ERROR = "invalid timestamp: $_send->{'timestamp'}";
         return(wantarray ? (undef, $ERROR) : undef);
      } 
      $_timestamp = $_send->{'timestamp'};
   }
   # use system time 
   else {
      $_timestamp = epoch_to_syslog_timestamp();
   }
   $_format = 'T';
   #
   # HOSTNAME (not required)
   #  if noHost=0 meaning populate hostname
   unless ( $_send->{'noHost'} ) {
      if    ($_send->{'device'})    { $_devname = $_send->{'device'}; }
      elsif ($_send->{'hostname'})  { $_devname = hostname();}
      else                          { $_devname = 'netdevsyslog';} 
      $_format = 'TH';
   }
   #
   # MESSAGE or (TAG CONTENT)
   #
   if ( defined($_send->{'message'}) ) {
      $_content = $_send->{'message'}; 
      $_format = $_format . 'M';
   }
   elsif ( defined($_send->{'content'}) ) {
     # -noTag = 0
      unless ($_send->{'noTag'}) {
         if   ( defined($_send->{'tag'}) && $_send->{'pid'} ) { 
            $_tag = sprintf("%s[%s]:", $_send->{'tag'}, $_send->{'pid'}); 
         }
         elsif   ( defined($_send->{'tag'}) ) {
            $_tag = $_send->{'tag'};
         }
         else {
            if ( defined($_send->{'pid'}) ) {$_tag = sprintf("NetDevSyslog[%s]:", $_send->{'pid'});}
            else                            {$_tag = sprintf("NetDevSyslogp[%s]:", $$);}
         }
         $_format = $_format . 'T';    # THT or TT
      }
      $_content = $_send->{'content'};
      $_format = $_format . 'C';
   }
   else {
      $_content = sprintf("Net::Dev::Syslog TEST Message:  facility: %s [%s] severity: %s [%s]",
         $_send->{'facility'}, $_facility,
         $_send->{'severity'}, $_severity,
      );
      $_format = $_format . 'C';
   }

   #
   # SYSLOG MESSAGE
   #
   # timestamp hostname tag content
   if ( $_format eq "THTC") {
      $_message = sprintf("%s %s %s %s", $_timestamp, $_devname, $_tag, $_content);
   }
   # timestamp hostname content
   elsif ( $_format eq "THC") {
       $_message = sprintf("%s %s %s", $_timestamp, $_devname, $_content);
   }
   # timestamp tag content
   elsif ( $_format eq "TTC") {
      $_message = sprintf("%s %s %s", $_timestamp, $_tag, $_content);
   }
   # timestamp content
   elsif ( $_format eq "TC") {
      $_message = sprintf("%s %s", $_timestamp, $_content);
   }
   # timestamp hostname message
   elsif ( $_format eq "THM") {
       $_message = sprintf("%s %s %s", $_timestamp, $_devname, $_content);
   }
   # timestamp message
   elsif ( $_format eq "TM") {
      $_message = sprintf("%s %s", $_timestamp, $_content);
   }
   # ???
   else {
      $ERROR = sprintf("unknown format: [%s] [%s] [%s] [%s]",  
          $_timestamp, $_devname, $_tag, $_content
      );
      return(wantarray ? (undef, $ERROR) : undef);
   }

   #
   #  MESSAGE to transmit
   #
   $tx_msg = sprintf("<%s>%s", $_pri, $_message);
   $msg_l  = length($tx_msg);

   # check allowed lengths
   $msg_l  = length($tx_msg);
   if ($_tag =~ /(.+)\[/)
      {$tag_l = length($1);}
   else 
      {$tag_l = length($_tag);}

   if ($_send->{'strict'}) {
      # syslog message length can not exceed 1024
      if ($msg_l > 1024) {
         $ERROR = "syslog message length $msg_l greater than 1024";
         return(wantarray ? (undef, $ERROR) : undef);
      }
      # syslog tag length can not exceed 32
      if ($tag_l > 32) {
         $ERROR = "syslog message tag length $tag_l greater than 32";
         return(wantarray ? (undef, $ERROR) : undef);
      }
   }
  
   if ($_send->{'debug'}){
      log_debug(1, "sendto:     %s  port %s  proto %s\n", 
         $_send->{'server'}, $_send->{'port'}, $_send->{'proto'}
      );
      log_debug(2, "pri:        %s  facility: %s [%s]  severity: %s [%s]\n",
         $_pri,
         $_send->{'facility'}, $_facility,
         $_send->{'severity'}, $_severity,
      );
      log_debug(3, "format:     %s\n", $_format);
      log_debug(3, "timestamp:  %s  [%s]\n", $_send->{'timestamp'} || 'localtime', $_timestamp);
      log_debug(3, "device:     %s  [%s]\n", $_send->{'device'} || 'none', $_devname);
      log_debug(3, "tag:        %s  [%s] [%s]\n", $_tag || 'noTag', $_send->{'tag'}||'-', $_send->{'pid'}||'-'); 
      log_debug(4, "content:    %s\n", $_content);
      log_debug(4, "message:    %s\n", $_message);
      log_debug(5, "tx msg:     %s\n", $tx_msg);
   }
   
   # send the message
   $_sock = IO::Socket::INET->new(
      PeerAddr  => $_send->{'server'},
      PeerPort  => $_send->{'port'},
      Proto     => $_send->{'proto'}
   ); 
   unless ($_sock) {
      $ERROR = sprintf("could not open socket to %s:%s  [%s]", 
         $_send->{'server'}, $_send->{'port'}, $!
      );
      return( wantarray ? (undef, $ERROR) : undef) ;
   }
   print $_sock $tx_msg; 

   $_sock->close();
   return(wantarray ? (1, '') : 1);

}   # end send_message

#
#=======================================================================
#
#                   Syslog Receive Message
#
#=======================================================================
#
#
#........................................................................
#
# Syslog Receive message constructor
#
#  port       => <port>        port to listen on (514)
#  proto      => <protocol>    protocol (udp)
#  maxlength  => <max length>  max length of packet (1024)
#  verbose    => 0|1|2|3       verbose level  (0)
#                0 - pure message
#                1 - bsd format
#                2 - bsd_plus format
#
sub listen {

   # create object
   my $_proto = shift;
   my $_class = ref($_proto) || $_proto;
   my $_listen  = {};
   # bless object
   bless($_listen, $_class);

   $ERROR = '';

   # define CTRL-C
   $SIG{INT} = \&interupt_listen;

   my %_arg = @_;
   my ($_a, $_err, 
       $_sock, $_port, $ipaddr, $_ipaddr_packed, $_rhost, 
       $_msg, $_msg_count, 
       $_parse_obj, $_parse,
       $_report,
       $_fwd_sock, $_fwd,
   );


   # set defaults
   $_listen->{'port'}       = 514;
   $_listen->{'proto'}      = 'udp';
   $_listen->{'maxlength'}  = '1024';
   $_listen->{'verbose'}    = 0;
   $_listen->{'packets'}    = -1;

   $_listen->{'report'}     = 0;
   $_listen->{'format'}     = 'bsd';
   $_listen->{'moreTime'}   = 0;
   $_listen->{'parseTag'}   = 0;

   $_listen->{'fwd_port'}   = '514';
   $_listen->{'fwd_proto'}  = 'udp';

   $_fwd = 0;


   foreach $_a (keys %_arg) {
      if    ($_a =~ /^-?port$/)       { $_listen->{'port'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?proto$/)      { $_listen->{'proto'}      = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?maxlength$/)  { $_listen->{'maxlength'}  = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?packets$/)    { $_listen->{'packets'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?verbose$/)    { $_listen->{'verbose'}    = delete($_arg{$_a}); }
      # parser options
      elsif ($_a =~ /^-?dump$/i)        {$_listen->{'dump'}       = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?append$/i)      {$_listen->{'append'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?ext$/i)         {$_listen->{'ext'}        = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?report$/i)      {$_listen->{'report'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?interval$/i)    {$_listen->{'interval'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?rx_time$/i)     {$_listen->{'rx_time'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?lastmsg$/i)     {$_listen->{'lastmsg'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?debug$/i)       {$_listen->{'debug'}      = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?min_date$/i)    {$_listen->{'filter_min_date'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?max_date$/i)    {$_listen->{'filter_max_date'}   = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?device$/i)      {$_listen->{'filter_device'}     = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?tag$/i)         {$_listen->{'filter_tag'}        = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?message$/i)     {$_listen->{'filter_message'}    = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?format$/i)      {$_listen->{'format'}            = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?moreTime$/i)    {$_listen->{'moreTime'}          = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?parseTag$/i)    {$_listen->{'parseTag'}          = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?fwd_server/i)   {$_listen->{'fwd_server'}        = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?fwd_port/i)     {$_listen->{'fwd_port'}          = delete($_arg{$_a}); }
      elsif ($_a =~ /^-?fwd_proto/i)    {$_listen->{'fwd_proto'}         = delete($_arg{$_a}); }
      else {
         $ERROR = sprintf("unsupported argument: %s => %s", $_a, $_arg{$_a});
         return(wantarray ? (undef, $ERROR) : undef);
      } 
   }

   # on unix, you need to be root if port < 1024
   if ($^O !~ /win/i) {
      if ($_listen->{'port'} < 1024 && $> != 0) {
         $ERROR = "must have root uid, not $> for port $_listen->{'port'}";
	 return(wantarray ? (undef, $ERROR) : undef);
      }
   }

   # see if we need to parse the syslog line
   if ($_listen->{'report'} || $_listen->{'verbose'} > 1) {
      ($_parse_obj, $_err) = Syslog->parse(
         -report  => $_listen->{'report'},
         exists($_listen->{'dump'})     ? (-dump     => $_listen->{'dump'})     : (),
         exists($_listen->{'append'})   ? (-append   => $_listen->{'append'})   : (),
         exists($_listen->{'ext'})      ? (-ext      => $_listen->{'ext'})      : (),
         exists($_listen->{'report'})   ? (-report   => $_listen->{'report'})   : (),
         exists($_listen->{'interval'}) ? (-interval => $_listen->{'interval'}) : (),
         exists($_listen->{'rx_time'})  ? (-rx_time  => $_listen->{'rx_time'})  : (),
         exists($_listen->{'lastmsg'})  ? (-lastmsg  => $_listen->{'lastmsg'})  : (),
         exists($_listen->{'debug'})    ? (-debug    => $_listen->{'debug'})    : (),
         exists($_listen->{'msg_plus'}) ? (-msg_plus => $_listen->{'msg_plus'}) : (),
         exists($_listen->{'min_date'}) ? (-min_date => $_listen->{'min_date'}) : (),
         exists($_listen->{'max_date'}) ? (-max_date => $_listen->{'max_date'}) : (),
         exists($_listen->{'device'})   ? (-device   => $_listen->{'device'})   : (),
         exists($_listen->{'tag'})      ? (-tag      => $_listen->{'tag'})      : (),
         exists($_listen->{'message'})  ? (-message  => $_listen->{'message'})  : (),
         exists($_listen->{'format'})   ? (-format   => $_listen->{'format'})   : (),
         exists($_listen->{'moreTime'}) ? (-moreTime => $_listen->{'moreTime'}) : (),
         exists($_listen->{'parseTag'}) ? (-parseTag => $_listen->{'parseTag'}) : (),
      );
      unless($_parse_obj) {
         $ERROR = "listener failed to open parser: $_err";
         return(wantarray ? (undef, $ERROR) : undef);
      }
   }

   $_fwd = 1 if defined($_listen->{'fwd_server'});

   # open socket
   #
   # fwd socket
   if ($_fwd) {
      printf("forwarding to %s:%s %s\n", 
         $_listen->{'fwd_server'}, $_listen->{'fwd_port'}, $_listen->{'fwd_proto'}
      );
      $_fwd_sock = IO::Socket::INET->new(
         PeerAddr  => $_listen->{'fwd_server'},
         PeerPort  => $_listen->{'fwd_port'},
         Proto     => $_listen->{'fwd_proto'}
      );
      unless ($_fwd_sock) {
         $ERROR = sprintf("could not open forward socket to %s:%s  [%s]",
            $_listen->{'fwd_server'}, $_listen->{'port'},  $!
         );
         return(wantarray ? (undef, $ERROR) : undef);
      }
   }
   # rx socket
   printf("opening rx socket port %s proto %s  %s\n",
      $_listen->{'port'}, $_listen->{'proto'},
      $_fwd ? 'forwarding' : 'not forwarding',
   );
   $_sock = IO::Socket::INET->new(
      LocalPort =>  $_listen->{'port'},
      Proto     =>  $_listen->{'proto'},
   );
   unless ($_sock) {
      $ERROR = sprintf("socket failed port: %s %s : %s", 
         $_listen->{'port'}, $_listen->{'proto'}, $@,
      );
      return(wantarray ? (undef, $ERROR) : undef); 
   }

   # listen on socket
   $_msg_count = 0;
   while ($_sock->recv($_msg, $_listen->{'maxlength'})) {
      printf("%s\n", $_msg);
      if ($_fwd) {
         print $_fwd_sock $_msg;
      }
      $_msg_count++;
      # print out  little more if we are verbose
      if ($_listen->{'verbose'}) {
         ($_port, $_ipaddr_packed) = sockaddr_in($_sock->peername);
         $ipaddr = inet_ntoa($_ipaddr_packed);
         $_rhost = gethostbyaddr($_ipaddr_packed, AF_INET);
         printf("    Packet:     %s  from %s:%s [%s]\n",
            $_msg_count, $ipaddr, $_port, $_rhost
         );
      }
      # parse the line if we want a report 
      if ($_listen->{'report'} || $_listen->{'verbose'} > 1) { 
         ($_parse, $_err)  = $_parse_obj->parse_syslog_line($_msg);
         if ($_parse) {
            if ($_listen->{'verbose'} > 1) {
               printf("    Priority:   %s  Facility [%s]   Severity [%s]\n",
                  $_parse->{'rx_priority'}, $_parse->{'rx_facility'}, $_parse->{'rx_severity'}
               );
               printf("    Timestamp:  %s\n", $_parse->{'timestamp'});
               printf("    Device:     %s\n", $_parse->{'device'});
               printf("    Tag:        %s %s\n", $_parse->{'tag'}, $_parse->{'pid'});
               printf("    Content:    %s\n", $_parse->{'content'}); 
            }
         }
         else {
            printf("parse_syslog_line failed: %s\n", $_err) if $_listen->{'verbose'};
         }
      }
      # check if we are counting packets
      #if ($_listen->{'packets'} > 0) {last if  $_msg_count == $_listen->{'packets'};}
      if ($_listen->{'packets'} > 0) {
         if ($_msg_count == $_listen->{'packets'}) {
            printf("received %s packets set for %s\n", $_msg_count, $_listen->{'packets'});
            last;
         }
      }
   }
   $_sock->close if $_sock;
   $_fwd_sock->close if $_fwd_sock;

   # close files if we reported and dumped
   if ($_listen->{'report'} && $_listen->{'dump'}) {$_parse_obj->close_dumps;}


   # function to handle CTRL-C
   sub interupt_listen {
       printf("CTRL-C detected: closing socket\n");
       $_sock->shutdown(0);
       $_fwd_sock->shutdown(0) if $_fwd_sock;
   }

   if ($_listen->{'report'}) {
      printf("Returning object reference\n");
      return(wantarray ? ($_parse, $ERROR) : $_parse);
   }
   else {
      return(wantarray ? ($_msg_count, "$_msg_count messages") : $_msg_count);
   }
}   # end sub listen



#
#=============================================================================
#
#                   handle the files
#
#=============================================================================
#
# function to dump line to file
#
# Arg 
#   $_[0]  class
#   $_[1]  devicename
#   $_[2]  line
#
# Return 
#   1 or undef
#
sub dump_line_to_file {

   my $_h = $_[1];
   $_h =~ s/ +//g;
   my $_dstfile = sprintf("%s%s.%s",  $_[0]->{'repository'}, $_[1], $_[0]->{'ext'});

   $ERROR = '';

   log_debug(3, "syslog line dump to file: [%s]\n", $_dstfile);
   # see if we have a file handle   
   if (!defined($FH{$_h})) {
      # open for overwrite or appending
      if ($_[0]->{'append'} == 1) {
         open($FH{$_h}, ">>$_dstfile") or $ERROR = "open append failed: $_h: $!";
      }
      else {
         open($FH{$_h}, ">$_dstfile") or $ERROR = "open overwright failed: $_h: $!";
      }
      select $FH{$_h}; $| = 1;
      select STDOUT;   $| = 1;
   }

   # exit out if we errored
   if ($ERROR) {
      log_debug(3, "%s\n", $ERROR);
      return(wantarray ? (undef, $ERROR) : $ERROR);
   }

   my $fh = $FH{$_h};
   printf $fh ("%s\n", $_[2]);

   return(wantarray ? (1, $ERROR) : 1);

}
#
#.............................................................................
#
# function to close all files
#
#
sub close_dumps {
   my $_f;
   # close any filehandle opened for parse
   foreach $_f (keys %FH) { close($FH{$_f});}
   1; 
}

##############################################################################
#
#                      Report Functions
#
#
#.............................................................................
#
#
# function to derive stats
# stats are generated if -report => 1
#
# user will have to access the %STATS hash created
#
#
#    @DEVICES    = list of each device found
#    @TAGS       = list of each tag found
#    @FACILITYS  = list of each facility found
#    @SEVERITYS  = list of each of each severity found
# 
#    %STATS{'syslog'}{'messages'}
#                  {'tag'}{<tag>}{'messages'}
#                  {'facility'}{<facility>}{'messages'}
#                  {'severity'}{<severity>}{'messages'}
#                  {'min_epoch'}
#                  {'min_date_str'}    # done with &syslog_stats_epoch2datestr
#                  {'max_epoch'}
#                  {'max_date_str'}    # done with &syslog_stats_epoch2datestr
#
#
#          {'device'}{<dev>}{'messages'}
#                         {'tag'}{<tag>}{'messages'}
#                         {'facility'}{<facility>}{'messages'}
#                         {'severity'}{<severity>}{'messages'}
#                         {'min_epoch'}
#                         {'min_date_str'}    # done with &syslog_stats_epoch2datestr
#                         {'max_epoch'}
#                         {'max_date_str'}    # done with &syslog_stats_epoch2datestr
#
#
sub syslog_stats {

   my $_tag  = $SYSLOG_href->{'tag'}          || $NOTAG;
   my $_prio = $SYSLOG_href->{'rx_priority'}  || 'noFacility.noSeverity';
   my $_fac  = $SYSLOG_href->{'rx_facility'}  || 'noFacility';
   my $_sev  = $SYSLOG_href->{'rx_severity'}  || 'noSeverity';


   # set min,max epoch for date
   # needed to be able to find min max dates
   if (!defined($STATS{'syslog'}{'min_epoch'})) {$STATS{'syslog'}{'min_epoch'} = 2**32;}
   if (!defined($STATS{'syslog'}{'max_epoch'})) {$STATS{'syslog'}{'max_epoch'} = 1;}

   #
   # populate arrays
   #
   # device list
   if ( !defined($STATS{'device'}{$SYSLOG_href->{'device'}}) ) 
      { push(@DEVICES,   $SYSLOG_href->{'device'}); }

   # TAG list
   if ( !defined($STATS{'syslog'}{'tag'}{$_tag}) )
      { push(@TAGS,      $_tag); }

   # FACILITY list
   if ( !defined($STATS{'syslog'}{'facility'}{$_fac}) )
      { push(@FACILITYS, $_fac); }

   # SEVERITY list
   if ( !defined($STATS{'syslog'}{'severity'}{$_sev}) )
      { push(@SEVERITYS, $_sev ); }

   #
   # per syslog
   #
   $STATS{'syslog'}{'messages'}++;
   $STATS{'syslog'}{'tag'}{$_tag}{'messages'}++;
   $STATS{'syslog'}{'facility'}{$_fac}{'messages'}++;
   $STATS{'syslog'}{'severity'}{$_sev}{'messages'}++;

   if ($SYSLOG_href->{'epoch'} < $STATS{'syslog'}{'min_epoch'}) 
      {$STATS{'syslog'}{'min_epoch'} = $SYSLOG_href->{'epoch'};}

   if ($SYSLOG_href->{'epoch'} > $STATS{'syslog'}{'max_epoch'})
      {$STATS{'syslog'}{'max_epoch'} = $SYSLOG_href->{'epoch'};}

   #
   # per device 
   #
   $STATS{'device'}{$SYSLOG_href->{'device'}}{'messages'}++;
   $STATS{'device'}{$SYSLOG_href->{'device'}}{'tag'}{$_tag}{'messages'}++;
   $STATS{'device'}{$SYSLOG_href->{'device'}}{'facility'}{$_fac}{'messages'}++;
   $STATS{'device'}{$SYSLOG_href->{'device'}}{'severity'}{$_sev}{'messages'}++;

   # check for min/max epoch existence 
   if (!defined($STATS{'device'}{$SYSLOG_href->{'device'}}{'min_epoch'}))
      {$STATS{'device'}{$SYSLOG_href->{'device'}}{'min_epoch'} = 2**32;}
   if (!defined($STATS{'device'}{$SYSLOG_href->{'device'}}{'max_epoch'}))
      {$STATS{'device'}{$SYSLOG_href->{'device'}}{'max_epoch'} = 1;}

   # find min/max epoch per device
   if($SYSLOG_href->{'epoch'} < $STATS{'device'}{$SYSLOG_href->{'device'}}{'min_epoch'})
      {$STATS{'device'}{$SYSLOG_href->{'device'}}{'min_epoch'} = $SYSLOG_href->{'epoch'};}
   if($SYSLOG_href->{'epoch'} > $STATS{'device'}{$SYSLOG_href->{'device'}}{'max_epoch'})
      {$STATS{'device'}{$SYSLOG_href->{'device'}}{'max_epoch'} = $SYSLOG_href->{'epoch'};}

   1;

}   # end sub syslog_stats


#
#.............................................................................
#
# function to convert epoch values in %STAT to date strings
# do this separate so as to do it once per device and whole syslog
#
#

sub syslog_stats_epoch2datestr {

  my $dev;

   $STATS{'syslog'}{'min_date_str'} = epoch_to_datestr($STATS{'syslog'}{'min_epoch'});
   $STATS{'syslog'}{'max_date_str'} = epoch_to_datestr($STATS{'syslog'}{'max_epoch'});

   foreach $dev (keys %{$STATS{'device'}}) {
      $STATS{'device'}{$dev}{'min_date_str'} = epoch_to_datestr($STATS{'device'}{$dev}{'min_epoch'});
      $STATS{'device'}{$dev}{'max_date_str'} = epoch_to_datestr($STATS{'device'}{$dev}{'max_epoch'});
   }

   1;
}


#############################################################################
#
#                   Timestamp Functions
#
#.............................................................................
#
# function to convert epoch to (month, day, hour, epoch_start_of_day)
#    epoch_time_of_day for this (month, day, hour)
#
# Arg 
#  epoch seconds
# Return
#  (month, day, hr, min, epoch_start_of_day, epoch_end_of_day);
#
sub _epoch_to_mdhm  {

   #                     0    1    2     3     4    5     6     7     8
   # localtime(epoch) = ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
   my @_val = localtime($_[0]);

   #                                   sec min hr  mday      mon       yr
   my $_epoch_start_of_day = timelocal(0,  0,  0,  $_val[3], $_val[4], $YEAR);
   my $_epoch_end_of_day   = timelocal(59, 59, 23, $_val[3], $_val[4], $YEAR);  

   return($MON{$_val[4]}, $_val[3], $_val[2], $_val[1], $_epoch_start_of_day, $_epoch_end_of_day);
}
# 
#.............................................................................
#
# function to convert epoch seconds to timestamp
# if no epoch seconds are given, current epoch seconds are used
#
# Arg
#   $_[0] = epoch seconds
# Return
#   Mmm  d hh:mm:ss
#   Mmm dd hh:mm:ss
#
sub epoch_to_syslog_timestamp {

   my $epoch = shift || time;
   my @t     = localtime($epoch);

   sprintf("%3s %2s %02s:%02s:%02s", 
      $MON{$t[4]+1}, $t[3], $t[2], $t[1], $t[0]
   ); 

}
#.............................................................................
#
# function to convert epoch seconds to common date string (datestr)
#
# Arg
#  $_[0] = epoch
#
# Return
#   date string
#
#
sub epoch_to_datestr {

   my $_epoch   = shift || time;
   my $_datestr = '';

   my @_tokens = localtime($_epoch);

   my $_month = $MON{$_tokens[4]+1}; 

   $_datestr = sprintf("%s/%s/%s %02s:%02s:%02s",
      $_month, $_tokens[3], $_tokens[5]+1900,
      $_tokens[2], $_tokens[1], $_tokens[0],
   );

   log_debug(3, "epoch_to_datestr %s => [%s]    [%s] [%s] [%s]\n",
      $_epoch, $_datestr, 
      $_month, $_tokens[3], $_tokens[5]+1900,
   );

   $_datestr;
}


#
#.............................................................................
#
# function to convert date give as a filter to an epoch
#
# Arg
#  $_[0]  = mm/dd/yyyy hh:mm:ss
sub date_filter_to_epoch {

   my $_str = shift;
   my ($_mon, $_day, $_yr, $_hr, $_min, $_sec, $_epoch);

   # if Mmm/dd/yyyy   convert month alpha string to decimal
   if ($_str =~ /([JFMASONDjfmasond]\w\w)\/\d{1,2}\//) {
      $_str =~ s/$1/$MON_index{$1}/;
   }

   # mm/dd/yyyy hh:mm:ss
   if ($_str =~ /^(\d{1,2})\/(\d{1,2})\/(\d{1,4}) (\d{1,2}):(\d{1,2}):(\d{1,2})$/) {
      $_mon = $1;   $_day = $2;  $_yr  = $3;
      $_hr  = $4;   $_min = $5;  $_sec = $6;
   }
   # mm/dd/yyyy hh:mm
   elsif ($_str =~ /^(\d{1,2})\/(\d{1,2})\/(\d{1,4}) (\d{1,2}):(\d{1,2})$/) {
      $_mon = $1;   $_day = $2;  $_yr  = $3;
      $_hr  = $4;   $_min = $5;   $_sec = 0;
   }
   # mm/dd/yyyy hh
   elsif ($_str =~ /^(\d{1,2})\/(\d{1,2})\/(\d{1,4}) (\d{1,2})$/) {
      $_mon = $1;   $_day = $2;  $_yr  = $3;
      $_hr  = $4;   $_min = 0;   $_sec = 0;
   }

   # mm/dd/yyyy
   elsif ($_str =~ /^(\d{1,2})\/(\d{1,2})\/(\d{1,4})$/) {
      $_mon = $1;   $_day = $2;  $_yr  = $3;
      $_hr  = 23;   $_min = 59;  $_sec = 59;
   }
   # assert
   else {
      $ERROR = "unsupported date filter: $_str";
      return(undef);
   }

   $_epoch = timelocal($_sec, $_min, $_hr, $_day, $_mon-1, $_yr);

   return($_epoch);

}   # end date_filter_to_epoch


#
#.............................................................................
#
# function to validate syslog timestamp
#
#   Mmm  d hh:mm:ss
#   Mmm dd hh:mm:ss
#
# Arg
#  $_[0] = timestamp
#
# Return 
#   0 - not valid
#   1 - valid
sub validate_timestamp_syntax {
   if ($_[0] =~ /[JFMASONDjfmasond]\w\w  \d \d\d:\d\d:\d\d/) 
      {return(1);}
   elsif ($_[0] =~ /[JFMASONDjfmasond]\w\w \d\d \d\d:\d\d:\d\d/) 
      {return(1);}
   else
      {return(0);}
}


# 
#.............................................................................
#
# function to timeslots based on min/max epoch 
# make global array
#   @TIMESLOTS = ([index, low, high], ...)
#          index = Mmm-dd-hh:mm

#
# Arg
#   $_[0] = min epoch
#   $_[1] = max epoch
#   $_[2] = interval
#
#
sub make_timeslots {

   my $_min_epoch = shift;
   my $_max_epoch = shift;
   my $_int       = shift || 3600;

   my ($_time, $_idx);

   # check that we have min/max
   if (!$_min_epoch || !$_max_epoch) {
      $ERROR = "min epoch [$_min_epoch] or max epoch [$_min_epoch] not defined";
      return( wantarray ? (undef, $ERROR) : undef);
   }
   # check min < max
   if ($_min_epoch > $_max_epoch) {
      $ERROR = "min epoch [$_min_epoch] > max epoch [$_min_epoch]";
      return( wantarray ? (undef, $ERROR) : undef);
   }
   # interval can be no less than 60
   if ($_int < 60) {
      $_int = 60;
   }

   for ($_time = $_min_epoch; $_time <= $_max_epoch; $_time = $_time + $_int) {
      log_debug(3, "report time: %s\n", $_time);
      $_idx = epoch_to_datestr($_time);
      push(@TIMESLOTS, [$_idx, $_time, $_time + ($_int - 1)]);
      log_debug(3, "report timeslot: %s  %s => %s\n",
         $_idx, $_time, $_time + ($_int - 1)
      );
   }
   return( wantarray ? (1, undef) : 1);
}



# 
#.............................................................................
#
# function to return index that tx_time belongs to, info stored @TIMESLOTS
# read in epoch seconds, find element in @INFO whose whose rang include
# this arg value
# return index
#  @TIMESLOTS = ([index, low_epoch, high_epoch], ...)
#  
# Arg
#   $_[0] = epoch of timestamp
#
# Return
#  timeslot index for stats
#
sub epoch_timeslot_index {

   my $_i;
   foreach $_i (@TIMESLOTS) {
      if($_[0] >= $_i->[1] && $_[0] <= $_i->[2]) {
         return($_i->[0]);
      }
   }
   undef;

}

#
#.............................................................................
#
# function to get extra time info:  year and weekday
#
# Arg
#   sec, min, hour, day, month
# Return
#   wantarray ? ($_epoch, $_wday) : $_epoch
#
sub _extra_time_values {

   $_[4]--;   # 0 base the month

   my $_epoch  = timelocal(@_, $YEAR);
   my $_wday   = (localtime($_epoch))[6];
   if ($DEBUG) {
      log_debug(3, "determine epoch and wday: s:%s m:%s h:%s d:%s mon: %s\n",
         @_
      );
      log_debug(3, "epoch: %s  wday: [%s]\n", $_epoch, $_wday);
   }
   
   return(wantarray ? ($_epoch, $_wday) : $_epoch);

}
#
#=============================================================================
#
# function to decode PRI to facility and severity
#
# Arg
#  $_[0]  = PRI  
#
# Return  (lower case are decimal, upper case are strings)
#   pri, facility, severity, PRI, Facility, Severity

sub decode_PRI {

   my ($_p, $_f, $_s, $_F, $_S, $_P);

   $_p = $_[0];
   # strip out '<>' that bound PRI
   if ($_[0] =~ /[<|>]/) {
      $_p =~ s/<//;
      $_p =~ s/>//;
   }

   # check that decimal number is between 0->191
   if ($_p >= 0 && $_p <= 191) {
      $_f = int($_p/8);
      $_s = $_p - ($_f*8);

      $_F = $Facility_Index{$_f} || "?$_f?";
      $_S = $Severity_Index{$_s} || "?$_s?";
      $_P = sprintf("%s.%s", $_F, $_S);

      return(wantarray ? ($_p, $_f, $_s, $_P, $_F, $_S) : $_P );
   }
   # otherwise error out
   else {
      return(wantarray ? (-1, -1, -1, 'P?', 'F?', 'S?') : undef );
   }

}


#
#.............................................................................
#
#  function to normalize facility string
#
sub normalize_facility {

   my $_str = '';

   if    ($_[0] =~ /kern/i)     {$_str = 'kern'}
   elsif ($_[0] =~ /user/i)     {$_str = 'user'}
   elsif ($_[0] =~ /mail/i)     {$_str = 'mail'}
   elsif ($_[0] =~ /daemon/i)   {$_str = 'daemon'}
   elsif ($_[0] =~ /auth/i)     {$_str = 'auth'}
   elsif ($_[0] =~ /syslog/i)   {$_str = 'syslog'}
   elsif ($_[0] =~ /lpr/i)      {$_str = 'lpr'}
   elsif ($_[0] =~ /news/i)     {$_str = 'news'}
   elsif ($_[0] =~ /uucp/i)     {$_str = 'uucp'}
   elsif ($_[0] =~ /cron/i)     {$_str = 'cron'}
   elsif ($_[0] =~ /auth/i)     {$_str = 'authpriv'}
   elsif ($_[0] =~ /ftp/i)      {$_str = 'ftp'}
   elsif ($_[0] =~ /ntp/i)      {$_str = 'ntp'}
   elsif ($_[0] =~ /audit/i)    {$_str = 'audit'}
   elsif ($_[0] =~ /alert/i)    {$_str = 'alert'}
   elsif ($_[0] =~ /at/i)       {$_str = 'at'}
   elsif ($_[0] =~ /local0$/i)  {$_str = 'local0'}
   elsif ($_[0] =~ /local1$/i)  {$_str = 'local1'}
   elsif ($_[0] =~ /local2$/i)  {$_str = 'local2'}
   elsif ($_[0] =~ /local3$/i)  {$_str = 'local3'}
   elsif ($_[0] =~ /local4$/i)  {$_str = 'local4'}
   elsif ($_[0] =~ /local5$/i)  {$_str = 'local5'}
   elsif ($_[0] =~ /local6$/i)  {$_str = 'local6'}
   elsif ($_[0] =~ /local7$/i)  {$_str = 'local7'}
   else                         {$_str = $_[0];}

   return($_str);
}
#
#.............................................................................
#
#  function to normalize severity string
#
sub normalize_severity {

   my $_str = '';

   if    ($_[0] =~ /emerg/i)   {$_str = 'emerg'}
   elsif ($_[0] =~ /alert/i)   {$_str = 'alert'}
   elsif ($_[0] =~ /crit/i)    {$_str = 'crit'}
   elsif ($_[0] =~ /err/i)     {$_str = 'err'}
   elsif ($_[0] =~ /warn/i)    {$_str = 'warn'}
   elsif ($_[0] =~ /notice/i)  {$_str = 'notice'}
   elsif ($_[0] =~ /info/i)    {$_str = 'info'}
   elsif ($_[0] =~ /debug/i)   {$_str = 'debug'}
   else                        {$_str = $_[0];}

   return($_str);

}

#
#.............................................................................
#
#
sub log_debug {

   my $_level  = shift;
   my $_format = shift;


   if ($_level <= $DEBUG) {
      printf("debug:  %s: $_format", (caller(1))[3], @_);
   }

   1;
}
#
#.............................................................................
# 
# function to set $YEAR
#
# call
#   $_obj->set_year(1988);
#
# Arg
#    $_[0] = class
#    $_[1] = year to set to, else set to current year
#
# Return
#    $YEAR
#
#
sub set_year {
   my $_class = shift;
   $YEAR     = shift || ((localtime)[5]) + 1900;
   $YEAR;
}

#
#.............................................................................
# 
# functions to return references to data structures
#
sub syslog_stats_href     { return(\%STATS); }
sub syslog_device_aref    { return(\@DEVICES); }
sub syslog_facility_aref  { return(\@FACILITY); }
sub syslog_severity_aref  { return(\@SEVERITY); }
sub syslog_tag_aref       { return(\@TAGS); }
sub syslog_timeslot_aref  { return(\@TIMESLOTS); }
sub syslog_error_count    { $ERROR_count; }
sub syslog_filter_count   { $FILTER_count; }
sub syslog_parse_count    { $PARSE_count; }

sub syslog_error          {return($ERROR);}



#
#.............................................................................
#
# from perl cookbook to put comma's in integer
sub _commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}


1;  # end package Syslog


#=============================================================================
#
#                                 POD
#
#=============================================================================

=pod

=head1 NAME

Net::Dev::Tools::Syslog - Send, Listen Parse Syslog messages.

=head1 VERSION

Syslog 1.0.0

=head1 SYNOPSIS

    use Syslog;

    #
    # Syslog Parser
    #
    ($syslog, $error) = Syslog->parse(
        -dump        =>  <directory>,
        -append      =>  <0|1>,
        -ext         =>  <extension>,
        -report      =>  <0|1>,
        -interval    =>  <seconds>,
        -debug       =>  <0|1|2|3>,
        -rx_time     =>  <0|1>,
        -lastmsg     =>  <0|1>,
        -min_date    =>  <mm/dd/yyyy [hh:mm]>,
        -max_date    =>  <mm/dd/yyyy [hh:mm]>,
        -device      =>  <pattern>,
        -tag         =>  <pattern>,
        -message     =>  <pattern>,
        -format      =>  <bsd|noHost|self>
        -moreTime    =>  <0|1>
        -parseTag    =>  <0|1>
    );

    $parse = $syslog->parse_syslog_line(<line>);

    #
    # Syslog Send
    #
    ($send, $error) = Syslog->send(
         -server    => <address>,
         -port      => <IP port>,
         -proto     => <udp|tcp>,
         -facility  => <facility>,
         -severity  => <severity>,
         -timestamp => <timestamp>,
         -device    => <device name>,
         -tag       => <tag>,
         -pid       => <pid>,
         -message   => <message>,
         -strict    => <0|1>,
    );

    $send->send_message(
         -server    => <address>,
         -port      => <IP port>,
         -proto     => <udp|tcp>,
         -facility  => <facility>,
         -severity  => <severity>,
         -timestamp => <timestamp>,
         -device    => <device name>,
         -tag       => <tag>,
         -pid       => <pid>,
         -message   => <message>,
         -strict    => <0|1>,
    );

    #
    # Syslog Listen
    #
    ($listen, $error) = Syslog->listen(
        -port       => <IP port>, 
        -proto      => <udp|tcp>,
        -maxlength  => <integer>
        -verbose    => <0|1|2|3>,
        -fwd_server => <IP address>,
        -fwd_port   => <integer>,
        -fwd_proto  => <udp|tcp>,
    );


=head1 DESCRIPTION

Module provides methods to parse syslog files, send syslog messages to
syslog server, listen for syslog message on localhost.

=over 4

=item Parser

    parse method creates a class that configures the parser used 
    on each syslog file entry (line) sent to the parser.
    The object is first created with properties that define how 
    a syslog line is to be worked on. The parse_syslog_line function
    (method) is then used to parse the syslog line and return a 
    reference to a hash.

=item Send

    send method will send a syslog message to a syslog sever. The user
    can provide as much or as little information desired. The class
    will then create a syslog message from the information given
    or from default values and send the message to the desired server.

=item Listen

    listen will open the desired port on the local host to listen
    for sylog messages. Message received on the port are assumed to 
    be syslog messages and are printed to STDOUT. Messages can also
    be forwarded 'as received' to another address. The functionality
    of the parser can also be used when in this mode. 

=back

See documentation for individual function/methods for more detail
on usage and operation.


=head1 REQUIRES

    Time::Local  used to convert TIMESTAMP to epoch
    IO::Socket   used by send and listen methods
    Sys::Hostname used to support DNS 

=head1 EXPORTS

    parse_syslog_msg
    epoch_to_syslog_timestamp
    make_timeslots
    epoch_timeslot_index
    normalize_facility
    normalize_severity

=head1 EXPORT TAGS

    :parser  parse_syslog_msg
    :time    epoch_to_syslog_timestamp, make_timeslots, epoch_timeslot_index
    :syslog  normalize_facility, normalize_severity


=head1 Parser Methods and Functions

=head2 parse

Constructor to create an object to parse the lines of a syslog file.
Arguments are used to define parsing. See function parse_syslog_line
section to see how to parse the line.

    ($syslog, $error) = Syslog->parse(
        -dump        =>  <directory>,
        -append      =>  <0|1>,
        -ext         =>  <extension>,
        -report      =>  <0|1>,
        -interval    =>  <seconds>,
        -debug       =>  <0|1|2|3>,
        -rx_time     =>  <0|1>,
        -lastmsg     =>  <0|1>,
        -min_date    =>  <mm/dd/yyyy [hh:mm]>,
        -max_date    =>  <mm/dd/yyyy [hh:mm]>,
        -device      =>  <pattern>,
        -tag         =>  <pattern>,
        -message     =>  <pattern>,
        -format      =>  <bsd|noHost|self>,
        -moreTime    =>  <0|1>,
        -parseTag    =>  <0|1>,
    );


Argument Checks:

If -dump is used, then argument must be a directory, current
directory is not assumed. The directory provided must exist and
allow user write access. 

If -interval is less than 60, it is set to 60.

If -min_date and/or -max_date are given the syntax and range are checked.


Return, in list context will return reference to object and error.
In scalar context returns reference to object. If object fails to create,
then the reference is undef.

=over 4

=item -dump <directory>

    Enable creation of separate syslog files. Each file created will only
    contain lines for the device defined in the syslog message HOSTNAME. 
    The <directory> argument defines a directory to where device specific 
    syslog files are dumped. Current directory is not assumed.
    Directories are checked for existence and writability.

    Default = FALSE, no dumps

=item -append <0|1>

    If 0, device files created due to -dump are overwritten.
    If 1, device files created due to -dump are appended to.
    Default = 0, (overwrite)

=item -ext <extension>

    File extension to use for device files created due to -dump
    being enabled.
    Default = 'slp', (SysLog Parsed)

=item -report <0|1>

    If 0 no stats are recorded.
    If 1 stats are extracted. For each line successfully parsed, information
    is stored in a hash. This hash can be referenced with the function
    syslog_stats_href.

=item -interval <seconds>

    The amount of seconds to use when making timeslots. 
    make_timeslots function will make timeslot ranging from
    min and max time found or given. The timeslot info can then
    be used to create stats for desired time intervals.
    See @TIMESLOTS for more info.
    Min value is 60 (1 minute).
    Default is 3600 (1 hour).

=item -debug  <0|1|2|3>

   Set debug level, verbosity increases as number value increases.


=item -rx_time <0|1>

   Set flag to use the localhost receive time and not the timestamp from the
   sylog message. Some syslog deamon prepend information to the syslog
   message when writing to a file. If a receive time is one of these
   fields, then it can be used. This will normalize all times to when
   they are received by the serever.
   Default is 0

=item -lastmsg  <0|1>

   Set flag to to handle last message as previous message.
   If true and the syslog message has the pattern 
   'last message repeated <N> time',then we replace this current
   line with the previous line. Otherwise the 'last message' line
   is treated as all other syslog lines. The tag will be defined as
   'lastmsg', pid and content set to ''.
   Default is 0.


=item -min_date <mm/dd/yyyy [hh:mm::ss]>

   If given, then will be used to filter dates. Only lines with dates
   greater to or equal to this will be be parsed. This check is performed
   after -rx_time, thus filter applies to whatever date you decide to keep.

   You must enter mm/dd/yyyy, other values will default:
      ss defaults to 0 if hh:mm given, 59 if no time given
      mm defaults to 0 if hh: given, 59 if no time given
      hh defaults to 23 if no time given

   Mmm/dd/yyyy can also be use, where Mmm is Jan, Feb, Mar,...


=item -max_date <mm/dd/yyyy [hh:mm::ss]> 

   If given, then will be used to filter dates. Only lines with dates
   less than or equal to this will be be parsed. This check is performed
   after -rx_time, thus filter applies to whatever date you decide to keep.

   Apply same syntax rules as -min_date

=item -device <pattern>

    If given, only device fields matching the pattern are kept. Text strings
    or Perl regexp can be given.


=item -tag <pattern>

    If given, only tag fields matching the pattern are kept. Text strings
    or Perl regexp can be given.

=item -message <pattern>

    If given, only message fields matching the pattern are kept. Text strings
    or Perl regexp can be given.

=item -format <bsd|noHost|self>

    Defines how $SYSLOG_pattern is constructed to use match the syslog line 
    against to parse out the component parts. 
    bsd will use $TIMESTAMP, $HOSTNAME, $MESSAGE. 
    noHost will use $TIMESTAMP, $MESSAGE. 
    self will use $SYSLOG_pattern as defined by the user, by default 
    $SYSLOG_pattern is defined same as bsd

=item -moreTime <0|1>

    If defined, derive more time information from the timestamp. This will
    convert time strings to epoch second using localtime function. This
    will slow down processing. This will be enabled if needed, such as when 
    -min_date, -max_date, -report are used.

=item -parseTag <0|1>

    If enabled, will parse TAGs from Syslog Message. TAG syntax varys greatly
    from different devices/vendors. This module tries to parse out the common
    style but realizes it can not assume a common syntax so the user is allowed 
    to define their own. See the Data Access section on TAGs for more information.

    Common style is considered to be: foo[123]: 

=back


=head2 parse_syslog_line

    ($parse, $error) = $syslog->parse_syslog_line(<line>);

Method to parse the syslog line. If syslog line <line> is not given 
as argument then $_ is parsed.

The pattern used to parse the given line is a pattern made by the strings
defined by $TIMESTAMP,$HOSTNAME,$MESSAGE.  If -format is bsd, then
$TIMESTAMP,$HOSTNAME,$MESSAGE are used to make the pattern. If -format
is noHost, then $TIMESTAMP, $MESSAGE are used to make the pattern. These
strings are used to make $SYSLOG_pattern

Some syslog daemons may prepend other information when writing 
syslog message to syslog file. parse_syslog_line will try to detect this
by applying a regexp match for an RFC 3164 syslog message to 
$SYSLOG_pattern. The match will be treated as the syslog message, any string 
found before the match will be considered a preamble. The preamble will be 
parsed for receive time, syslog priority (facility.severity) and 
source IP address. This info is extracted and made avaliable to the user.

parse_syslog_line calls parse_syslog_msg to parse respective information.
The string given to parse_syslog_msg is the string matched by 
$SYSLOG_pattern. Any facility or severity parsed is normalized to 
the strings listed in @FACILITY and @SEVERITY. 

Syslog messages are the strings matched by $SYSLOG_pattern. Changing
this string to something else allows the user to modify the parser.

The information parsed from the line given to parse_syslog_line is then 
checked against any filters.

If the filtering determines we keep the line the function checks if the
-dump or -report options are enabled and performs the required task.


See Data Access Section for hash structure made by parse_syslog_line.
Each call to this function clears the previous information stored.

The user has external control over the parser through the global variables
$TIMESTAMP,$HOSTNAME,$MESSAGE, $SYSLOG_pattern. See the Data Access Section
for requirements of these strings. 


In list context a reference to a hash and error are returned.
In scalar context, a reference to a hash is returned.

Events to Return Error:

=over 

=item  blank line

=item  outside of date range, if date filters are applied

=item  no date parsed and date filters are applied

=item  unable to dump line to file, if -dump option true

=back


=head2 parse_syslog_msg

    @fields = parse_syslog_msg($msg, [$moreTime, $parseTag, <0|1>]);

    $fields[0] = timestamp portion of syslog message

    $fields[1] = hostname portion of syslog message

    $fields[2] = message portion of syslog message

    $fields[3] = error string


This function can be used externally as a function call.
When called internally by parse_syslog_line the 4th argument is set 
to 1 and the function populates the respective data structure. If called
externally, then will return in list context (timestamp, device, 
message, error) or in scalar context a reference to a hash whose keys
are 'timestamp', 'device', 'message'. If an error occurs then everthing
is undef and the error is a string detailing the error.


The given line is pattern matched against $SYSLOG_pattern and the 
information is gather from the $1, $2, $3, ... placeholders. 
See Data Access for syntax if defining your own $TIMESTAMP,$HOSTNAME,$MESSAGE,
$SYSLOG_pattern strings.

If the -moreTime argument is true (non zero) then the $TIMESTAMP is picked 
apart for more information. This would be the -moreTime argument to 
parse_syslog_line when doing OOP, otherwise user must define on a user call.

If the -parseTag argument is true (non zero) then the parse_tag function
attempts to parse a TAG.  This would be the -parseTag argument to 
parse_syslog_line when doing OOP, otherwise user must define on a user call. 

See Data Access section, Syslog Line Hash Reference for the syntax of the hash
populated with the information parsed with parse_syslog_msg.


=head2 parse_tag

    ($tag, $pid, $content) = parse_tag(<string>);

This function will parse TAG and PID from the given string and return the 
TAG and PID and CONTENT. If the user defines $TAG_1 or $TAG_2 or $TAG_3, 
then those patterns are used to match. See Data Access for syntax of $TAG_x. 
Otherwise will look at beginning of the string for the common practice of 
some text string and pid, such as foo[1234]: content. The given string
is assumed to be the MESSAGE portion of the syslog message, the MESSAGE 
portion can be made of TAG and CONTENT fields. The MESSAGE portion follows
the HEADER which consist of TIMESTAMP and HOSTNAME, hostname field mandatory.

When used by the object, hash key/value entries are populated for the 
syslog line, see Data Access section. When used as a standalone function
then TAG, PID and CONTENT fields are returned in list context.


=head2 parse_preamble

This function is not external but is described since debugging will
indicate this function.


   ($epoch, $date, $facility, $severity, $srcIP) = parse_preamble($preamble);

Some syslog daemon will prepend information to the RFC3164 format. This 
information is: 

=over

=item local sytem time when the message was received

=item the facility and severity, derived from PRI

=item the source IP address

=back

When used by the object, hash key/value entries are populated for the 
syslog line, see Data Access section. 


This function will attempt to parse this information out and return in
list context, the receive time in epoch seconds, the local receive time,
the syslog message facility, the syslog message severity, the source IP 
address. Date information is assumed to be delimited with dash '-', 
time information is delimited with ':'. Since the syntax of this information
is unique, any one of the fields are parsed for, thus they can be in any order
in the preamble.


=head1 Send Methods and Functions

=head2 send

Constructor to create object that define the fields used in syslog messages to
be sent from the localhost. Arguments define all portions of a RFC 3164 
Syslog message. Message is sent when &send_message is called.

Any argument can be defined now or when calling &send_message. This allows the user
to set values that are static for their needs or change dynamically each time
a message is sent.

    ($syslog, $error) = Syslog->send(
        -server    =>   <server IP>,
        [-port      =>  <destination port>,]
        [-proto     =>  <udp|tcp>,]
        [-facility  =>  <facility string>,]
        [-severity  =>  <severity string>,]
        [-timestamp =>  <message timestamp>,]
        [-device    =>  <device name>,]
        [-tag       =>  <tag>,]
        [-pid       =>  <tag PID>,]
        [-content   =>  <syslog messsage content>,]
        [-message   =>  <syslog message>,]
        [-strict    =>  <0|1>,]
        [-noHost    => <0|1>,]
        [-hostname  => <0|1>,]
        [-noTag     => <0|1>,]
        [-debug     => <0-5>,]
    );


=over

=item -server

Destination Syslog Server IP Address. Default 127.0.0.1

=item -port

Destination Port. Default is 514.
On UNIX systems, ports 0->1023 require user to be root (UID=0).

=item -proto

IP protocol to use, default is udp.

=item -facility

Syslog FACILITY (text) to use. Default is 'user'.

=item -severity

Syslog SEVERITY (text) to use. Default is 'debug'.

=item -timestamp

TIMESTAMP to put in to syslog message. Default is current time.
Syntax is Mmm dd hh:mm:ss or Mmm  d hh:mm:ss

=item -noHost

Tell function to insert HOSTNAME field into syslog message.
If 1, HOSTNAME field is not inserted into syslog message.
If 0, HOSTNAME field is determined by -device or -hostname arguments.
Default is 0.

=item -device

HOSTNAME to put in to syslog message. If not given then -hostname
determines HOSTNAME, if -hostname is not true, then 'netdevsyslog'
is used for HOSTNAME field.

=item -hostname

Use sytem hostname value for HOSTNAME field, if -device does not give
a hostname to use, then a call to the systems hostname function
is called to get value for HOSTNAME field of syslog message. If 
-device and -hostname are not used then 'netdevsyslog' is used 
for HOSTNAME field.

=item -noTag

Tell function to insert a TAG into the syslog message. 
If 1, do not put a TAG into syslog message.
If 0, insert a TAG into syslog message.

=item -tag

Syslog message TAG to insert into syslog message. If this
is given and -noTag = 0 then this string will be used as the TAG of the 
syslog MESSAGE, a single space will separate it from the CONTENT.
This value will not be used if -message is given.
If not given and -noTag = 0 the function will create a TAG with the syntax
of 'NetDevSyslog[$pid]:', If -pid is given.
Otherwise 'NetDevSyslogp:[$$]', where system PID is used.


=item -pid

Syslog message TAG PID to use. If given, will create
NetDevSyslog[$pid], otherwise the system PID for the the current
script will be used NetDevSyslogp[$$]. 
This value will not be used if -message is given.



=item -content

String to use for syslog message CONTENT. The message portion of a 
syslog message is defined as a TAG and CONTENT, with TAG not being 
mandatory. This field will be combined with -tag and -pid to
create the syslog MESSAGE portion. 


=item -message

String to use as syslog MESSAGE portion. User may opt to not use
the -tag, -pid, -content message and just pass in the complete
MESSAGE portion to follow the TIMESTAMP and HOSTNAME fields. 
If this is given it will have precedence over -content.



=item -strict

By default strict syntax is enforced, this can be disabled with -strict 0.
Strict rules allow message to be no longer than 1024 characters and TAG 
within the message to be no longer than 32 characters.

=back


=head2 send_message

Function will create a RFC 3164 syslog message and send to destination IP:port.
For values not defined by user, defaults will be used. The same arguments given
for the constructor 'send' apply to this function. Thus any value can be changed
before transmission. 

    ($ok, $error) = $syslog->send_message(
        [-server    =>   <server IP>],
        [-port      =>  <destination port>,]
        [-proto     =>  <udp|tcp>,]
        [-facility  =>  <facility string>,]
        [-severity  =>  <severity string>,]
        [-timestamp =>  <message timestamp>,]
        [-device    =>  <device name>,]
        [-tag       =>  <tag>,]
        [-pid       =>  <tag PID>,]
        [-content   =>  <syslog messsage content>],
        [-message   =>  <syslog message>,]
        [-strict    =>  <0|1>],
        [-noHost    => <0|1>],
        [-hostname  => <0|1>],
        [-noTag     => <0|1>],
        [-debug     => <0-5>],
    );

See above send method for descriptions of send_message options.

For any error detected, the message will not be sent and undef returned.
For each message sent, the socket is opened and closed.

In list context the status and error are returned, in scalar context just the
status is returned. If the message is sent successfully, then status is 1, 
otherwise undef. If an error occurs then the error variable is a descriptive 
string, otherwise undef.


=head3 Syslog Message Creation.

Using the options/arguments of send and send_message the syslog message is created
with the following logic:

PRI (decimal) is calculated from FACILITY and SEVERITY values, defaults are
used if not given in function call.


TIMESTAMP is either given with -timestamp or taken from local system time.


HOSTNAME is created if -noHost set to 0. If -device given, then this 
becomes HOSTNAME. Else if -hostname is 1, then system hostname is used.
Else 'netdevsyslog' is used. If -noHost is 1 then no HOSTNAME field is
put into the Syslog message.


MESSAGE is created either from user giving the full message with the
-message argument. Otherwise MESSAGE is created by combining TAG, PID,
CONTENT. CONTENT is the message of the sylog line.

CONTENT creation follows this:

    if -content given, then CONTENT is the given string 
        if -noTag =0
            if -tag and -pid are defined TAG becomes tag[pid]:
            if -tag only then TAG is the argument string
            if -pid only then NetDevSyslog[pid]:
            otherwise NetDevSyslogp[$$]
    otherwise CONTENT becomes the default message.




SYSLOG MESSAGE to be put on the wire is then created by joining
the different variables, $TIMESTAMP, [$HOSTNAME], [$TAG], 
$MESSAGE | $CONTENT 



=head1 Listen Methods and Functions

=head2 listen

Constructor to create object that listens on desired port and prints out
messages received. Message are assumed to be syslog messages. Messages
can also be forward unaltered to a defined address:port.

    ($syslog, $error) = Syslog->listen(
        [-port       => <port>,]
        [-proto      => <udp|tcp>,]
        [-maxlength  => <max message length>,]
        [-packets    => <integer>,]
        [-verbose    => <0|1|2>,]
        [-report     => <0|1>],
        [-fwd_server => <ip>],
        [-fwd_port   => port>,]
        [-fwd_proto  => <udp|tcp>,]
    );


If -report or -verbose <true> is used, then a parse oject is created
and the same options that can be given to the parse object can be given 
to this object.


Message received will be printed to STDOUT.


On UNIX systems, if -port is less than 1024 then the the user
must have UID=0 (root). To listen on ports 1024 and above
any userid is allowed.


CTRL-C ($SIG{INT}) is redefined to shutdown the socket and then return 
control back to caller, it will not exit your program.

If -report option is enabled, then a reference to object that can be
used to access %STATS will be returned. 

Otherwise a counter value indicating the number of messages received 
is returned.


=over

=item -port

Local port to listen for messages. Messages are assumed to be syslog messages.
Some OS's may require root access.
Default is 514.

=item -proto

Protocol to use. 
Default is udp.


=item -maxlength

Max message length. Default is 1024

=item -packets

Shutdown the socket listening on after N packets are received on the
given port. At least one packet must be received for packet count
to be checked. 

=item -verbose

Verbosity level 0-3


=item -report

Perform same reporting as the parse method does. All arguments to the parse
method can be used on this method. Unlike the parse method, reporting
is off by default for listen method.

=item -fwd_server

Forward received message to address given. Message is sent as it is received
off the wire. Dotted decimal IP address or DNS name can be given. 

=item -fwd_port

Define TCP port for forward message to be sent. Default is 514 

=item -fwd_proto

Define transport protocol for forwarded message to be sent. Default is UDP.
String 'udp' or 'tcp' can be given.


=back



=head1 General Functions

=head2 init

Initialize the hash storing the current syslog line information.

    $syslog->init();


=head2 close_dumps

Function to loop through all filehandles opened for dumping a syslog
line to a device specific file. The parsing function will take care
of closing any files created with the -dump option, this is available
to give the user the control if needed.

    $syslog->close_dumps();


=head2 syslog_stats_epoch2datestr

Function to convert epoch seconds, in the hash created with -report option,
to a date string of Mmm/dd/yyyy hh:mm:ss. This function acts on the hash
and convert epoch min, max time value for the whole syslog file and per
each device. If you reference the hash before running this function
you will not get the date string. This process is kept separate to save
time in waiting for this to complete if done during parsing, since
we only need to do it after the min and max are found. The syntax
is purposely different than the syntax of a sylog message, but does contain
the same information with a year value added. 

    &syslog_stats_epoch2datestr;


=head2 epoch_to_syslog_timestamp

Function to convert epoch seconds to a RFC 3164 syslog message timestamp.
If epoch seconds not given, then current time is used.

   $timestamp = epoch_to_syslog_timestamp($epoch);

=head2 epoch_to_datestr

Function to convert epoch seconds to a common date string.
If epoch seconds not given, then current time is used.

   $date_str = epoch_to_datestr($epoch)

Date string format  Mmm/dd/yyyy hh:mm:ss

=head2 date_filter_to_epoch

Function to convert date given for a filter to epoch seconds.

   $epoch = date_filter_to_epoch(<mm/dd/yyyy [hh:mm:ss]>);

=head2 validate_timestamp_syntax

Function to validate that a given timestamp matches the syntax
defined by RFC 3164. If valid, then '1' is returned, if invalid
then '0' is returned.

   $ok = validate_timestamp_syntax($timestamp);

=head2 make_timeslots

Function to create @TIMESLOTS given the min/max epoch seconds and
the interval. Will start at min epoch value and increment until
reaching or exceeding the max epoch value. For each increment an
index is made based on the min epoch for that interval. The index
is created with &epoch_to_datestr.

    make_timeslots($min_epoch, $max_epoch, $interval);

Min and max values are mandatory and are checked to be greater or less
than the other value. If $interval is not given, function defaults
to 60 seconds.

The created list is built as such

    @TIMESLOTS = ([$index, min_epoch, $max_epoch], ...);

This list can be used to group syslog messages to a specific timeslot.
From the syslog line we have epoch seconds, this list provides a range
to check the epoch seconds against and the index for that range.

=head2 epoch_timeslot_index

Function that takes a given epoch second value and returns the timeslot
index value for that value from @TIMESLOTS.

    $index = epoch_timeslot_index($epoch);

If no match is found, undef is returned.

=head2 normalize_facility

Function to take a character string representing a facility and 
return a normalize string contained in @FACILITY.

   $facility = normalize_facility($facility);

If given string is not normailized, it is returned

=head2 normalize_severity

Function to take a character string representing a severity and 
return a normalize string contained in @SEVERITY.

   $severity = normalize_severity($severity);

If given string is not normailized, it is returned

=head2 decode_PRI

Function to decode PRI in decimal format to a Facility and Severity.
Can accept either decimal number or decimal number bounded by '<' '>'.

In list context will return list of information, in scalar context will
return respective Facility and Severity strings joined with '.'.


   @pri = decode_PRI($pri_dec);
   $PRI = decode_PRI($pri_dec);

   $pri[0]  PRI decimal value
   $pri[1]  Facility decimal value
   $pri[2]  Severity decimal value
   $pri[3]  PRI character string (join facility and severity string) 
   $pri[4]  Facility charater string
   $pri[5]  Severity charater string

Given PRI value is checked to be between 0 and 191. If not, then undef
is returned in scalar context and for list values any decimal
number is -1, P?, F?, S? for PRI, Facility Severity character strings
respectively


=head2 set_year

Set the value used by methods and functions of this module to the current
year as known by localtime.  Syslog message timestamps do not conatain year
information. A user may need to change this when looking at a syslog from 
a different year.

If no value is given, then the current year is assumed, otherwise
the year is set to the argument.

   $syslog->set_year(2003);   # set year to 2003
   $syslog->set_year();       # set year to ((localtime)[5]) + 1900



=head2 syslog_stats_href

Return reference to %STATS, this is the hash created with the -report option
to the parser and listener. 

=head2 syslog_device_aref

Return reference to @DEVICES, list of HOSTNAMEs parsed.
This is created with the -report option to the parser and listener.

=head2 syslog_facility_aref

Return reference to @FACILITY, list of FACILITIES parsed.
This is created with the -report option to the parser and listener.

=head2 syslog_severity_aref

Return reference to @SEVERITY, list of SEVERITIES parsed.
This is created with the -report option to the parser and listener.

=head2 syslog_tag_aref

Return reference to @TAGS, list of TAGS parsed
This is created with the -report option to the parser and listener.

=head2 syslog_timeslot_ref

Return reference to @TIMESLOTS, list of time slots made by 
make_timeslot function.

=head2 syslog_error

Return last error.

=head2 syslog_error_count

Return error counter value, incremented each time the parser errors.

=head2 syslog_filter_count

Return filter counter value, incremented each time a line is filtered

=head2  syslog_parse_count

Return parser count, increments each time a line is given to parser


=head1  Data Access

=head2 @FACILITY

List of all syslog facilities strings as defined by RFC 3164.
Any facility string parse or given by the user is normalized 
to strings found in this list. 

=head2 @SEVERITY

List of all syslog severities strings as defined by RFC 3164.
Any severity string parse or given by the user is normalized 
to strings found in this list. 

=head2 %Syslog_Facility

Hash whose keys are syslog facility strings and whose value
is the decimal representation of that facility.

=head2 %Syslog_Severity

Hash whose keys are syslog severity strings and whose value
is the decimal representation of that severity.

=head2 $TIMESTAMP

The pattern used to parse TIMESTAMP from RFC 3164 syslog message.

(([JFMASONDjfmasond]\w\w) {1,2}(\d+) (\d{2}:\d{2}:\d{2}))

$1 = TIMESTAMP

$2 = Month string

$3 = Month day (decimal)

$4 = hh:mm::ss


=head2 $HOSTNAME

The patterm used to parse HOSTNAME from RFC 3164 syslog message.

([a-zA-Z0-9_\.\-]+)

$1 = HOSTNAME


=head2 $TAG_1 $TAG_2  $TAG_3 

The user defined pattern used to parse a TAG from RFC 3164 syslog message.
If any of these are defined, then the TAG is to be parsed against these
patterns, otherwise the modules regexp pattern will be used.

$TAG_1    $1 = task, $2 = pid, $3 = content

$TAG_2    $1 = task,           $2 = content,   no pid

$TAG_3    $1 = task, $2 = pid, $3 = content


=head2 $MESSAGE

The pattern used to parse MESSAGE from RFC 3164 syslog message.

(.+)$

$1 = MESSAGE


=head2 $SYSLOG_pattern

The pattern used to parse any RFC 3164 syslog message.
Combination of $TIMESTAMP, $HOSTNAME, $MESSAGE are used to parse the 
different parts from RFC 3164 syslog message. The user can 
define this by defining the individual variables that make this
up or just define this directly.

If used when -format is 'self' then

$1 = TIMESTAMP

$2 = Month string

$3 = Month day (decimal)

$4 = hh:mm::ss

$5 = HOSTNAME

$6 = MESSAGE




=head2 Syslog Line Hash Reference (parse_syslog_line)

The hash reference returned by function parse_syslog_line has
the following keys:

    ($hash_ref, $error) = $syslog->parse_syslog_line($message);


    $hash_ref->{'line'}      current line from syslog file
               {'timestamp'} timestamp from syslog message
               {'device'}    device name from syslog message
               {'message'}   syslog message, from after devname
               {'month_str'} month from syslog message timestamp (Jan,Feb,...) 
               {'month'}     month index 0->11
               {'day'}       day from syslog message timestamp
               {'time_str'}  hh:mm:ss from syslog message timestamp
               {'hour'}      hh from syslog message timestamp
               {'min'}       mm from syslog message timestamp
               {'sec'}       ss from syslog message timestamp
               {'year'}      year assumed from localtime
               {'epoch'}     epoch time converted from syslog message timestamp
               {'wday'}      wday integer derived from epoch (0-6) = (Sun-Sat)
               {'wday_str'}  wday string converted, (Sun, Mon, ...)
               {'date_str'}  syslog message {'epoch'} convert to common format
               {'tag'}       syslog message content tag
               {'pid'}       syslog message content tag pid
               {'content'}   syslog message content after tag parsed out
               {'preamble'}  string prepended to syslog message
               {'rx_epoch'}     extra info: rx time epoch
               {'rx_timestamp'} extra info: rx timestamp
               {'rx_priority'}  extra info: priority (text)
               {'rx_facility'}  extra info: syslog facility (text)
               {'rx_severity'}  extra info: syslog severity (text)
               {'srcIP'}        extra info: src IP address
               {'rx_epoch'}     extra info: rx time epoch
               {'rx_date_str'}  extra info: rx time date string
               {'rx_time_str'}  extra info: rx time (hh:mm:ss)
               {'rx_year'}      extra info: rx time year value
               {'rx_month'}     extra info: rx time month value
               {'rx_month_str'} extra info: rx time month value string (Jan,Feb,..)
               {'rx_day'}       extra info: rx time day value
               {'rx_wday'}      extra info: rx time weekday (0-6) (Sun, Mon,..)
               {'rx_hour'}      extra info: rx time hour value
               {'rx_min'}       extra info: rx time minute value
               {'rx_sec'}       extra info: rx time second value


=head3 More hash key details

key = timestamp is $TIMESTAMP

key = device is $HOSTNAME

key = message is $MESSAGE

key = month, day, time_str, hour, minute, sec is parsed from $TIMESTAMP. 
month_str is derived

key = tag and pid may come from $TAG_x if defined

key = content is the message part after a TAG, if parsed, otherwise the whole message
after $HOSTNAME for bsd format, $TIMESTAMP for noHost format.

key = preamble is the entire preamble string if found.

key = rx_* is any information found and parsed from the preamble


=head2 %STATS

Multi-level hash (HoH) that store statisticis.
This hash is created as each line is parsed if -report is enabled.
This only represent some basic stats that I thought everyone would want. 
A user can derive their own by examining the different fields in hash 
reference returned by parse_syslog_line.

   All of the values listed below are incremented (counter).
   Strings enclosed in '<' '>' denote keys derived from information
   found in the syslog file, in other words they are variable whereas the
   single quoted strings are constant (hardcoded).

    $STATS{'syslog'}{'messages'} 
                    {'min_epoch'}
                    {'max_epoch'}
                    {'min_date_str'}
                    {'max_date_str'}
                    {'tag'}{<$tag>}{'messages'}
                    {'facility'}{<$rx_facility>}{'messages'}
                    {'severity'}{<$rx_severity>}{'messages'}


   $STATS{'device'}{<$dev>}{'messages'}
                           {'min_epoch'}
                           {'max_epoch'}
                           {'min_date_str'}
                           {'max_date_str'}
                           {'tag'}{<$tag>}{'messages'}
                           {'facility'}{<$rx_facility>}{'messages'}
                           {'severity'}{<$rx_severity>}{'messages'}


=head2 @TIMESLOTS

@TIMESLOTS is a list (AoA) of time intervals ranging from the min
to max value provided to &make_timeslots function.
A @TIMESLOTS element contains 3 values
 
    @TIMESLOTS = ([index, min_epoch, max_epoch], ...);

       index - Unique string created to indicate start of timeslot
               Mmm/dd/yyyy hh:mm
       min_epoch - is begining of the timeslot interval in epoch seconds.
       max_epoch - is ending of the timeslot interval in epoch seconds.


=head2 @DEVICES

List of devices found. Created when -report is true. When a device
is firsted learned, its device name as known from the syslog message
is pushed on to this list.

=head2 @TAGS

List of tags found. Created when -report is true. When a tag
is firsted learned, its name as known from the sylog message
is pushed on to this list.


=head2 $ERROR_count

Counter for each error occuring in parser.

=head2 $FILTER_count

Counter for each line filtered by parser.

=head2 $PARSE_count

Counter for each line parsed by parser.


=head1 Syslog Message Syntax

RFC 3164 describes the syntax for syslog message. This modules
intends to adhere to this RFC as well as account for common
practices.

As described in the RFC, 'device' is a machine that can generate a message.
A 'server' is a machine that receives the message and does not relay it to 
any other machine. Syslog uses UDP for its transport and port 514 (server side)
has been assigned to syslog. It is suggested that the device source port also
be 514, since this is not mandatory, this module does not enforce it. 

Section 4.1 of RFC 3164 defines syslog message parts, familiarity with these
descriptions will give the user a better understanding of the functions
and arguments of this module. Maximum length of a syslog message must be 1024
bytes. There is no minimum length for a syslog message. A message of 0 bytes
should not be transmitted. 

=head2 PRI

4.1.1 PRI Part of RFC 3164 describes PRI. The PRI represents the syslog 
Priority value which represents the Facility and Severity as a decimal 
number bounded by angle brackets '<' '>'. The PRI will have 3,4 or 5 characters. 
Since two characters are always the brackets, the decimal number is then 
1-3 characters.

The Facility and Severity of a message are numerically coded with 
decimal values.

       Numerical        Facility
          Code
           0             kernel messages
           1             user-level messages
           2             mail system
           3             system daemons
           4             security/authorization messages (note 1)
           5             messages generated internally by syslogd
           6             line printer subsystem
           7             network news subsystem
           8             UUCP subsystem
           9             clock daemon (note 2)
          10             security/authorization messages (note 1)
          11             FTP daemon
          12             NTP subsystem
          13             log audit (note 1)
          14             log alert (note 1)
          15             clock daemon (note 2)
          16             local use 0  (local0)
          17             local use 1  (local1)
          18             local use 2  (local2)
          19             local use 3  (local3)
          20             local use 4  (local4)
          21             local use 5  (local5)
          22             local use 6  (local6)
          23             local use 7  (local7)

        Note 1 - Various operating systems have been found to utilize
           Facilities 4, 10, 13 and 14 for security/authorization,
           audit, and alert messages which seem to be similar.
        Note 2 - Various operating systems have been found to utilize
           both Facilities 9 and 15 for clock (cron/at) messages.


        Numerical         Severity
          Code

           0       Emergency: system is unusable
           1       Alert: action must be taken immediately
           2       Critical: critical conditions
           3       Error: error conditions
           4       Warning: warning conditions
           5       Notice: normal but significant condition
           6       Informational: informational messages
           7       Debug: debug-level messages


Priority is calculated as: (Facility*8) + Severity. After calculating the Priority,
bound it with barckets and its now a PRI. For example a daemon debug would
be (3*8)+7 => 31 Priority, PRI <31>.

=head2 HEADER

The header portion contains a timestamp and the device name or IP. The device
name is not mandatory.

=head3 TIMESTAMP

The TIMESTAMP immediately follows the trailing ">" from the PRI when received
on the wire.
The TIMESTAMP is separated from the HOSTNAME by single space characters.

The TIMESTAMP field is the local time of the sending device and is in the i
format of  'Mmm dd hh:mm:ss'. 

    Mmm is the month abbreviation, such as:
    Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec.

    dd is day of month. If numeric day value is a single digit,
    then the first character is a space. This would make the format
    'Mmm  d hh:mm:ss'.

    hh:mm::ss are hour minute seconds, 0 padded. Hours range from
    0-23 and minutes and seconds range from 0-59.
 
A single space charater must follow the the TIMESTAMP field.

=head3 HOSTNAME

The HOSTNAME is separated from the precedding TIMESTAMP by single 
space character. The HOSTNAME will be the name of the device as it
knows itself. If it does not have a hostname, then its IP address is
used.

=head2 MSG (message part)

The MSG part will fill the rest of the syslog packet.
The MSG part is made of two parts the TAG and CONTENT.
The TAG value is the name of the originating process and must
not exceed 32 characters.

Since there is no specific rule governing TAGs, the user of this module
is allowed to define 3 TAG patterns to be matched. Otherwise the module
trys to extract common practices.

The CONTENT is the details of the message.

=head1 Examples

Examples are also in ./examples directory of distribution. This directory
also contains syslog generator script that is a bit more elaborate
than a simple example but is good for generating syslog message
from a range of dummy host name. Can generate a file or be used
to send to a server. The comments in the code should give you
a general idea of what is being done and what the varaibles mean.


=head3 Sample script to listen for syslog messages on local host.

    #!/usr/bin/perl
    # Perl script to test Net::Dev::Tools::Syslog listen

    use strict;
    use Net::Dev::Tools::Syslog;

    my ($listen_obj, $error, $ok);

    my $port  = 7971;
    my $proto = 'udp';
    # create object to listen
    # CTRL-C will close sock and return to caller
    ($listen_obj, $error) =  Syslog->listen(
        -port       => $port,
        -proto      => $proto,
        #-verbose    => 3,
        #-packets    => 150,
        #-parseTag   => 1,
    );
    unless ($listen_obj) {
       printf("ERROR: syslog listen failed: %s\n", $error);
       exit(1);
    }

    exit(0);


=head3 Sample script to send syslog messages.

    #!/usr/bin/perl
    # Perl script to test Net::Dev::Tools::Syslog sending
    #

    use strict;
    use Net::Dev::Tools::Syslog;

    my ($send_obj, $error,
        $facility, $severity,
        $ok,
    );

    my $server = '192.168.1.1';
    my $port   = 7971;
    my $proto  = 'udp';

    my $test_send_all = 1;
    my $sleep         = 0;
    my $pid           = $$;

    # create send object
    ($send_obj, $error) = Syslog->send(
       -server    => $server,
       -port      => $port,
       -proto     => $proto,
    );
    unless ($send_obj) {
       myprintf("ERROR: Syslog send failed: %s\n", $error);
       exit(1);
    }

    # send syslog message
    printf("Sending syslog to %s:%s proto: %s  pid: %s\n", $server, $port, $proto, $pid );
    # send all syslog type message
    if ($test_send_all) {
       foreach $facility (@Syslog::FACILITY) {
          foreach $severity (@Syslog::SEVERITY) {
             #printf("send message:  %-10s  %s\n", $facility, $severity);
             ($ok, $error) = $send_obj->send_message(
                -facility  => $facility,
                -severity  => $severity,
                -hostname  => 1,
                -device    => 'myTestHost',
                -noTag     => 0,
                #-tag       => 'myTag',
                -pid       => 1,
                -content   => 'my syslog message content',
             );
             if(!$ok) {
                printf("ERROR: syslog->send_msg: %s\n", $error);
             }
             sleep $sleep;
          }
       }
    }
    else {
       ($ok, $error) = $send_obj->send_message(
          -hostname  => 1,
       );
       if(!$ok) {
          printf("ERROR: syslog->send_msg: %s\n", $error);
       }
    }

    exit(0);

=head3 Sample script to parse syslog messages from file.

    #!/usr/bin/perl
    # Perl script to test Net::Dev::Tools::Syslog parsing
    #
    use strict;
    use Net::Dev::Tools::Syslog;

    # get sylog file from cli 
    my $syslog_file = shift || die "usage: $0 <syslog file>\n";

    my ($syslog_obj, $error,
        $parse_href,
        $report_href,
        $fh,
        $device, $tag, $facility, $severity,
    );

    # create syslog parsing object
    ($syslog_obj, $error) = Syslog->parse(
       -report    => 1,
       -parseTag  => 1,
       -dump      => './dump2',
       -debug     => 0,
       -moreTime  => 1,
       -format    => 'noHost',
    );
    unless ($syslog_obj) {
       printf("sylog object constructor failed: %s\n", $error);
       exit(1);
    }

    # open syslog file to parse
    printf("parse syslog file: %s\n", $syslog_file);
    open ($fh, "$syslog_file") || die "ERROR: open failed: $!\n";
    while(<$fh>) {
       ($parse_href, $error) = $syslog_obj->parse_syslog_line($_);
       unless ($parse_href) {
          printf("ERROR: line %s: %s\n", $., $error);
       }
    }
    close($fh);
    printf("parse syslog file done: %s lines\n", $.);

    # convert epoch time in report hash
    &syslog_stats_epoch2datestr;

    # reference report hash and display
    $report_href = &syslog_stats_href;

    # stats for entire syslog file
    printf("Syslog:  messages %s   %s -> %s\n\n\n",
       $report_href->{'syslog'}{'messages'},
       $report_href->{'syslog'}{'min_date_str'},
       $report_href->{'syslog'}{'max_date_str'},
    );

    # stats for each device found in syslog
    foreach $device (keys %{$report_href->{'device'}}) {
       printf("Device: %s  messages: %s   %s -> %s\n", 
          $device, 
          $report_href->{'device'}{$device}{'messages'},
          $report_href->{'device'}{$device}{'min_date_str'},
          $report_href->{'device'}{$device}{'max_date_str'},
       );
       printf("   Tags:\n",);
       foreach $tag (keys %{$report_href->{'device'}{$device}{'tag'}}) {
          printf("     %8s %s\n", 
             $report_href->{'device'}{$device}{'tag'}{$tag}{'messages'}, $tag
          );  
       }
       printf("   Facility:\n",);
       foreach $facility (keys %{$report_href->{'device'}{$device}{'facility'}}) {
          printf("     %8s %s\n", 
             $report_href->{'device'}{$device}{'facility'}{$facility}{'messages'}, 
             $facility
          );
       }
       printf("   Severity:\n",);
       foreach $severity (keys %{$report_href->{'device'}{$device}{'severity'}}) {
          printf("     %8s %s\n", 
             $report_href->{'device'}{$device}{'severity'}{$severity}{'messages'}, 
             $severity
          );
       }
       printf("\n");
    }

    exit(0);

=cut


=head1 AUTHOR

    sparsons@cpan.org

=head1 COPYRIGHT

    Copyright (c) 2004-2006 Scott Parsons All rights reserved.
    This program is free software; you may redistribute it 
    and/or modify it under the same terms as Perl itself.





