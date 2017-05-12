# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.

use warnings;
use strict;

package Mozilla::Persona::Validate::Htpasswd;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Mozilla::Persona::Validate';

use Log::Report    qw/persona/;
use Apache::Htpasswd ();


sub init($)
{   my ($self, $args) = @_;

    my $fn = $args->{pwfile} or panic;
    $self->openFile($fn);   # pre-load
    $self;
}

#------------

sub pwfile() {shift->{MPVH_fn}}

sub openFile(;$)
{   my ($self, $fn) = @_;

    if($fn) { $self->{MPVH_fn} = $fn }
    else    { $fn = $self->{MPVH_fn} }

    my $mtime = (stat $fn)[9];
    defined $mtime
        or fault __x"htpasswd file {fn}";

    if(my $last_mtime = $self->{MPVH_mtime})
    {   return $self->{MPVH_info} if $mtime eq $last_mtime;
    }

    my $info = $self->{MPVH_info} = Apache::Htpasswd
      ->new({passwdFile => $fn, ReadOnly => 1});

    $self->{MPVH_mtime} = $mtime;
    $info;
}

sub isValid($$)
{   my ($self, $user, $password) = @_;
    $self->openFile->htCheckPassword($user, $password);
}

1;
