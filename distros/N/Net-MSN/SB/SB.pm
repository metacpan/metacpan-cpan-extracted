# Net::MSN::SB - SwitchBoard class for Net::MSN.
# Originally written by: 
#  Adam Swann - http://www.adamswann.com/library/2002/msn-perl/
# Modified by:
#  David Radunz - http://www.boxen.net/
#
# $Id: SB.pm,v 1.3 2003/07/02 14:14:55 david Exp $ 

package Net::MSN::SB;

use strict;
use warnings;

BEGIN {
  use base 'Net::MSN::Base';

  use vars qw($VERSION);

  $VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r }; 
}

sub new {
  my ($class, %args) = @_;

  my %defaults = (
    _Type	=>	'SB'
  );
  my $self = __PACKAGE__->SUPER::new(
    __PACKAGE__->SUPER::merge_opts(\%defaults, \%args)
  );

  return $self;
}

sub sendmsg {
  my ($self, $message, $type) = @_;

  $type = $type || 'N';

  my $header = qq{MIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\nX-MMS-IM-Format: FN=MS%20Shell%20Dlg; EF=; CO=0; CS=0; PF=0\n\n};

  $message = $header. $message;
  $message =~ s/\n/\r\n/gs;

  $self->sendraw('MSG', $type. ' ' . length($message) . "\r\n" . $message);
}

return 1;
