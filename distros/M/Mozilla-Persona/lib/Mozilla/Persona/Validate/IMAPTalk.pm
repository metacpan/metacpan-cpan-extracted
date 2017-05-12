# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.

use warnings;
use strict;

package Mozilla::Persona::Validate::IMAPTalk;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Mozilla::Persona::Validate';

use Log::Report    qw/persona/;
use Mail::IMAPTalk ();


sub init($)
{   my ($self, $args) = @_;
    $self->{MPVI_server} = $args->{server} or panic;
    $self;
}

#------------

sub server() {shift->{MPVI_server}}

sub isValid($$)
{   my ($self, $user, $password) = @_;

    my $imap = Mail::IMAPTalk->new
      ( Server   => $self->server
      , Username => $user
      , Password => $password
      , Uid      => 1
      );

   $imap or return 0;
   $imap->logout;
   1;
}

1;
