# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Termios;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module', 'POSIX::Termios';

use warnings;
use strict;

my @speed = qw/
 B0 B110 B1200 B134 B150 B1800 B19200 B200 B2400
 B300 B38400 B4800 B50 B600 B75 B9600
 /;

my @flags   = qw/
 BRKINT CLOCAL ECHONL HUPCL ICANON ICRNL IEXTEN IGNBRK IGNCR IGNPAR
 INLCR INPCK ISIG ISTRIP IXOFF IXON NCCS NOFLSH OPOST PARENB PARMRK
 PARODD TOSTOP VEOF VEOL VERASE VINTR VKILL VMIN VQUIT VSTART VSTOP
 VSUSP VTIME
 /;

my @actions = qw/
 TCSADRAIN TCSANOW TCOON TCION TCSAFLUSH TCIOFF TCOOFF
 /;

my @flush     = qw/TCIOFLUSH TCOFLUSH TCIFLUSH/;
my @functions = qw/
 tcdrain tcflow tcflush tcsendbreak 
 ttyname
 /;

our %EXPORT_TAGS =
 ( speed     => \@speed
 , flags     => \@flags
 , actions   => \@actions
 , flush     => \@flush
 , constants => [@speed, @flags, @actions, @flush]
 , functions => \@functions
 );


# Only needed by manual.PL
sub _create_constant($)
{   my ($class, $name) = @_;
    no strict 'refs';
    sub { &{"POSIX::$name"} };
}

1;
