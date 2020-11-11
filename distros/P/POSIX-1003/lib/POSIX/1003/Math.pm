# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Math;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my @constants;

# Only from math.h.  The first block are defined in POSIX.xs, the
# second block present in Core. The last is from string.h
our @IN_CORE = qw/abs exp log sqrt sin cos atan2 rand srand int/;

my @functions = qw/
 acos asin atan ceil cosh floor fmod frexp
 ldexp log10 modf sinh tan tanh

 div rint pow
 strtod strtol strtoul
/;

push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%math' ]
  );

my  $math;
our %math;

BEGIN {
    $math = math_table;
    push @constants, keys %$math;
    tie %math, 'POSIX::1003::ReadOnlyTable', $math;
}


# the argument to be optional is important for expression priority!
sub acos(_)  { goto &POSIX::acos  }
sub asin(_)  { goto &POSIX::asin  }
sub atan(_)  { goto &POSIX::atan  }
sub ceil(_)  { goto &POSIX::ceil  }
sub cosh(_)  { goto &POSIX::cosh  }
sub floor(_) { goto &POSIX::floor }
sub frexp(_) { goto &POSIX::frexp }
sub ldexp(_) { goto &POSIX::ldexp }
sub log10(_) { goto &POSIX::log10 }
sub sinh(_)  { goto &POSIX::sinh  }
sub tan(_)   { goto &POSIX::tan   }
sub tanh(_)  { goto &POSIX::tanh  }

sub modf($$) { goto &POSIX::modf }
sub fmod($$) { goto &POSIX::fmod }

# All provided by POSIX.xs


sub div($$) { ( int($_[0]/$_[1]), ($_[0] % $_[1]) ) }


sub rint(;$) { my $v = @_ ? shift : $_; int($v + 0.5) }


sub pow($$) { $_[0] ** $_[1] }


#------------------------------


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $math->{$name};
    sub () {$val};
}

1;
