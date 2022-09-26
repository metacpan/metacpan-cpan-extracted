#!/usr/bin/env perl

#------------------------------------------------------------------------------
# 设定模块依赖
#------------------------------------------------------------------------------
use 5.018;
use warnings;
use IO::File;
use IO::Select;

#------------------------------------------------------------------------------
# 接受脚本传参
#------------------------------------------------------------------------------
&logHandler();

#------------------------------------------------------------------------------
# 生成特定样式的路径
#------------------------------------------------------------------------------
sub logHandler {
  my $basePath = $ARGV[0];
  my $lastPath;

  # 将系统日志信息转储到 logHandler，并读取到另外的 FileHandle
  my $ioStdin = IO::File->new;
  $ioStdin->open("<-") or die "ERROR: can't read from STDIN: $!\n";
  my $ioSelect = IO::Select->new();
  $ioSelect->add($ioStdin);

  # 设定文件句柄和缓存
  my $fileHandler = IO::File->new;
  my $cacheSize   = 1024 * 1024;

  my $cache = "";
  while (1) {
    my @ready = $ioSelect->can_read(1);
    if (@ready > 0) {

      # 判定是否需要刷新日志文件
      my $baseTime;
      my $logParams = {
        init => sub { $baseTime = time() },
        '%%' => sub { return ('%') },
        '%d' => sub { return (sprintf("%02d", (localtime($baseTime))[3])) },
        '%m' => sub { return (sprintf("%02d", (localtime($baseTime))[4] + 1)) },
        '%Y' => sub { return (sprintf("%04d", (localtime($baseTime))[5] + 1900)) },
      };
      $logParams->{init}();
      $basePath =~ s/(\%[a-zA-Z\%])/$logParams->{$1}()/ge;

      if (not defined $lastPath or $lastPath ne $basePath) {
        $lastPath = $basePath;
        $fileHandler->open(">> $basePath") or die "ERROR: write log $basePath failed: $!\n";
        $fileHandler->autoflush();
      }

      # 读取日志到 $fileHandler
      my $buffer;
      my $readSize = sysread($ioStdin, $buffer, 1024);
      if ($readSize == 0) {
        if (length $cache > 0) {
          $fileHandler->print($cache);
        }
        $fileHandler->close();
        exit();
      }
      elsif ($readSize > 0) {
        $cache .= $buffer;
        while ($cache =~ s/^([^\n]*\n)//) {
          $fileHandler->print($1);
        }
        while (length $cache >= $cacheSize) {
          $fileHandler->print(substr($cache, 0, $cacheSize));
          $cache = substr($cache, $cacheSize);
        }
      }
      else {
        exit();
      }
    }
  }
}

=wildcard
  %%   a literal %
  %a   locale's abbreviated weekday name (Sun..Sat)
  %A   locale's full weekday name, variable length (Sunday..Saturday)
  %b   locale's abbreviated month name (Jan..Dec)
  %B   locale's full month name, variable length (January..December)
  %c   locale's date and time (Sat Nov 04 12:02:33 EST 1989)
  %C   century (year divided by 100 and truncated to an integer) [00-99]
  %d   day of month (01..31)
  %D   date (mm/dd/yy)
  %e   day of month, blank padded ( 1..31)
  %F   same as %Y-%m-%d
  %g   the 2-digit year corresponding to the %V week number
  %G   the 4-digit year corresponding to the %V week number
  %h   same as %b
  %H   hour (00..23)
  %I   hour (01..12)
  %j   day of year (001..366)
  %k   hour ( 0..23)
  %l   hour ( 1..12)
  %m   month (01..12)
  %M   minute (00..59)
  %n   a newline
  %N   nanoseconds (000000000..999999999)
  %p   locale's upper case AM or PM indicator (blank in many locales)
  %P   locale's lower case am or pm indicator (blank in many locales)
  %r   time, 12-hour (hh:mm:ss [AP]M)
  %R   time, 24-hour (hh:mm)
  %s   seconds since `00:00:00 1970-01-01 UTC' (a GNU extension)
  %S   second (00..60); the 60 is necessary to accommodate a leap second
  %t   a horizontal tab
  %T   time, 24-hour (hh:mm:ss)
  %u   day of week (1..7);  1 represents Monday
  %U   week number of year with Sunday as first day of week (00..53)
  %V   week number of year with Monday as first day of week (01..53)
  %w   day of week (0..6);  0 represents Sunday
  %W   week number of year with Monday as first day of week (00..53)
  %x   locale's date representation (mm/dd/yy)
  %X   locale's time representation (%H:%M:%S)
  %y   last two digits of year (00..99)
  %Y   year (1970...)
  %z   RFC-2822 style numeric timezone (-0500) (a nonstandard extension)
  %Z   time zone (e.g., EDT), or nothing if no time zone is determinable
=cut

1;
