package Miril::DateTime;

use strict;
use warnings;
use autodie;

use overload '""' => \&epoch;

use POSIX;
use Time::Local qw(timelocal);
use Miril::DateTime::ISO::Simple qw(time2iso);

sub new      { bless \$_[1], $_[0] }
sub epoch    { ${$_[0]} }
sub iso      { time2iso(${$_[0]}) }

no warnings qw(redefine);
sub strftime { POSIX::strftime($_[1], localtime(${$_[0]})) };
use warnings qw(redefine);

1;
