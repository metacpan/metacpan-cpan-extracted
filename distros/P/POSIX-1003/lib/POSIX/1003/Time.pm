# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Time;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

use POSIX::1003::Locale  qw(setlocale LC_TIME);
use Encode               qw(find_encoding is_utf8 decode);

our @IN_CORE  = qw/gmtime localtime/;

my @constants;
my @functions = qw/
  asctime ctime strftime
  clock difftime mktime
  tzset tzname strptime/;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%time' ]
  );

my  $time;
our %time;

BEGIN {
    $time = time_table;
    push @constants, keys %$time;
    tie %time, 'POSIX::1003::ReadOnlyTable', $time;
}


sub _tm_flatten($)
{   my $tm = shift;
    ( $tm->{sec}  // 0, $tm->{min}  // 0, $tm->{hour} // 0
    , $tm->{day}-1, $tm->{month}-1, $tm->{year}-1900
    , $tm->{wday} // -1, $tm->{yday} // -1, $tm->{is_dst} // -1
    );
}

sub _tm_build($@)
{   my $tm = shift;
    @{$tm}{qw/sec min hour day month year wday yday isdst/} = @_;
    $tm->{month}++;
    $tm->{year}  += 1900;
    $tm;
}

sub mktime(@)
{   my @p;

    my $time;
    if(@_==1)
    {   my $tm = shift;
        ($time, my @t) = _mktime _tm_flatten $tm;
        _tm_build $tm, @t if defined $time;  # All fields may have changed
    }
    else
    {   ($time) = _mktime @_;
    }

    $time;
}


sub strftime($@)
{   my $fmt = shift;
    local @_ = _tm_flatten $_[0] if @_==1;

#XXX See https://github.com/abeltje/lc_time for the correct implementation,
#    using nl_langinfo(CODESET)

    my $lc  = setlocale LC_TIME;
    if($lc && $lc =~ m/\.([\w-]+)/ && (my $enc = find_encoding $1))
    {   # enforce the format string (may contain any text) to the same
        # charset as the locale is using.
        my $rawfmt = $enc->encode($fmt);
        return $enc->decode(_strftime($rawfmt, @_));
    }

    if(is_utf8($fmt))
    {   # no charset in locale, hence ascii inserts
        my $out = _strftime(encode($fmt, 'utf8'), @_);
        return decode $out, 'utf8';
    }

    # don't know about the charset
    _strftime($fmt, @_);
}



sub strptime($$)
{   return _strptime @_
        if wantarray;

    my $tm = {};
    _tm_build $tm, _strptime @_;
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $time->{$name};
    sub () {$val};
}

1;
