# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.

use warnings;
use strict;

package Mozilla::Persona::Validate::Table;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Mozilla::Persona::Validate';

use Log::Report    qw/persona/;
use Digest         ();


sub init($)
{   my ($self, $args) = @_;

    my $fn = $args->{pwfile} or panic;
    $self->openFile($fn);   # pre-load
    $self->{MPVT_domain} = $args->{domain};
    $self;
}

#------------

sub pwfile() {shift->{MPVT_fn}}
sub domain() {shift->{MPVT_domain}}

sub openFile(;$)
{   my ($self, $fn) = @_;

    if($fn) { $self->{MPVT_fn} = $fn }
    else    { $fn = $self->{MPVT_fn} }

    my $mtime = (stat $fn)[9];
    defined $mtime
        or fault __x"passwd file {file}", file => $fn;

    if(my $last_mtime = $self->{MPVT_mtime})
    {   return $self->{MPVT_info} if $mtime eq $last_mtime;
    }

    my $domain = $self->domain;
    my %info;
    open PASSWD, '<:raw', $fn
        or fault __x"cannot read file {file}", file => $fn;

    while(<PASSWD>)
    {   next if m/^#|^\s*$/;
        chomp;
        my ($user, $algo, $passwd) = split /\:/;
        if(index $user, '@' < 0)
        {   # abbreviated usedname
            $user .= '@' . $domain;
        }
        elsif($user !~ m/\@\Q$domain\E$/i) 
        {   # account for other domain
            next;
        }

        defined $passwd
            or warning __x"not enough fields in {file} line {linenr}"
                 , file => $fn, linenr => $.;

        !$info{$user}
            or warning __x"found user {user} again in {file} line {linenr}"
                 , file => $fn, linenr => $.;

        $info{$user} = [$algo, $passwd];
    }
    close PASSWD
        or fault __x"read errors in {file}", file => $fn;

    $self->{MPVT_mtime} = $mtime;
    $self->{MPVT_info}  = \%info;
}

sub isValid($$)
{   my ($self, $user, $password) = @_;

    my $info = $self->openFile->{$user}
        or return 0;   # unknown user
   
    my ($algo, $expect) = @$info;
    my $digester = eval { Digest->new($algo) };
    error __x"unsupported digest algorithm {name} for {user}"
     , name => $algo, user => $user
       if $@;

    $expect eq $digester->add($password)->b64digest;
}

1;
