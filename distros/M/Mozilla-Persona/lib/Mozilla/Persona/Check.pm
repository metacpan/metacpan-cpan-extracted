# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package Mozilla::Persona::Check;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Exporter';

our @EXPORT = qw/check_identity/;

use open 'utf8';
use Log::Report         qw/persona/;

use LWP::UserAgent           ();

sub check_browserid_file($);
sub check_login($$$);

my $ua;


sub check_identity(%)
{   my %args = @_;

    my $identity = $args{identity} or panic;
    my $password = $args{password} or panic;

    my ($user, $domain) = split m/\@/, $identity, 2;
    defined $domain
        or error __x"identity should have a form like: username\@example.com";

    my $website  = URI->new("https://$domain");
    check_browserid_file $website;
    check_login $website, $identity, $password;
}

sub check_browserid_file($)
{   my $website  = shift;
    my $wk       = URI->new_abs('/.well-known/browserid', $website);

    $ua        ||= LWP::UserAgent->new;
    my $response = $ua->get($wk);

    $response->is_success
        or error __x"could not get {uri}: {err}"
             , uri => $wk, err => $response->status_line;

    my $ct = $response->content_type;
    unless($ct eq 'application/json')
    {   print <<__HELP;
ERROR>>>
When downloading $wk
I discovered that the content-type is not 'application/json', but
'$ct'.  You need to change the configuration of your
webserver.  For Apache, you need to add something like

    <Directory \$YOUR_DOCROOT/.well-known>
      <Files browserid>
         ForceType application/json
      </Files>
    </Directory>

to your VirtualHost.
__HELP

        error __x"the browserid file is not json";
    }
}

sub check_login($$$)
{   my ($website, $identity, $password) = @_;
    my $login = $website->clone;
    $login->path('/persona/index.pl');

    $ua       ||= LWP::UserAgent->new;
    my $resp    = $ua->post($login
      , {action => 'login', email => $identity, password => $password});

    unless($resp->is_success)
    {   print <<'__HELP_404' if $resp->code==404;
ERROR>>>
This program can only be used to check Mozilla::Persona installations,
not other persona servers.
__HELP_404

        print <<'__HELP_500' if $resp->code==500;
ERROR>>
Login failed: the persona/index.pl script produced an error.  There are
many possible causes:
  * wrong password
  * Perl libraries cannot be found
  * mistake in configuration
Look in the error log of the VirtualHost configuration of the webserver
software (f.i. Apache) for more information about the cause.
__HELP_500

        error __x"failed on {login}: {err}", login => $login
          , err => $resp->status_line;
   }

    my $content = $resp->decoded_content || $resp->content;
    if($resp->content_type =~ /perl/ || $content =~ m/^.*perl/)
    {   print <<'__HELP';
ERROR>>>
The webserver returns the perl script, not the output of that script
as run on the server.  This means that the webserver is not configured
correctly.  For Apache, you should add this to your VirtualHost:

    <Directory $YOUR_DOCROOT/persona>
       Options          +ExecCGI
       AddHandler cgi-script .pl
    </Directory>

__HELP

        error "/persona/index.pl script not executable";
    }
}

1;
