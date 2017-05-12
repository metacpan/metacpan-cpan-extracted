# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Time;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

use POSIX::1003::Locale  qw(setlocale LC_TIME);
use Encode               qw(find_encoding is_utf8 decode);

# Blocks resp. defined in time.h, limits.h
my @constants = qw/
  CLK_TCK CLOCKS_PER_SEC NULL
  TZNAME_MAX
 /;

our @IN_CORE  = qw/gmtime localtime/;

my @functions = qw/
  asctime ctime strftime
  clock difftime mktime
  tzset tzname/;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );


sub strftime($@)
{   my $fmt = shift;

#XXX See https://github.com/abeltje/lc_time for the correct implementation,
#    using nl_langinfo(CODESET)

    my $lc  = setlocale LC_TIME;
    if($lc && $lc =~ m/\.([\w-]+)/ && (my $enc = find_encoding $1))
    {   # enforce the format string (may contain any text) to the same
        # charset as the locale is using.
        my $rawfmt = $enc->encode($fmt);
        return $enc->decode(POSIX::strftime($rawfmt, @_));
    }

    if(is_utf8($fmt))
    {   # no charset in locale, hence ascii inserts
        my $out = POSIX::strftime(encode($fmt, 'utf8'), @_);
        return decode $out, 'utf8';
    }

    # don't know about the charset
    POSIX::strftime($fmt, @_);
}


# Everything in POSIX.xs


1;
