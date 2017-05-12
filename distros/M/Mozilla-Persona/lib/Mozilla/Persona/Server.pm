# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package Mozilla::Persona::Server;
use vars '$VERSION';
$VERSION = '0.12';

use open 'utf8';

use Log::Report    qw/persona/;

use Crypt::OpenSSL::Bignum ();
use Crypt::OpenSSL::RSA    ();

use CGI::Session   ();
use JSON           qw(decode_json encode_json);
use File::Slurp    qw/read_file write_file/;
use MIME::Base64   qw(encode_base64url);
use Time::HiRes    qw(time);
use List::Util     qw(first);
use File::Basename qw(dirname);
use File::Spec     ();

use constant MIME_JSON => 'application/json; charset=UTF-8';


sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($)
{   my ($self, $args) = @_;
    $self->{MP_pem_fn}   = $args->{private_pem} or panic;
    $self->{MP_cookie}   = $args->{cookie_name} or panic;
    $self->{MP_domain}   = $args->{domain}      or panic;
    $self->{MP_aliparms} = $args->{aliases}
       || { class => 'Mozilla::Persona::Aliases' };
    $self->{MP_valparms} = $args->{validator}
       || { class  => 'Mozilla::Persona::Validate::Table'
          , pwfile => '/etc/persona/passwords'
          };
    $self;
}


sub fromConfig($)
{   my ($class, $fn) = (shift, shift);
    my $config = decode_json read_file $fn;
    $class->new(%$config, @_);
}

#-----------------

sub cookie()  {shift->{MP_cookie}}
sub domain()  {shift->{MP_domain}}


sub aliases()
{   my $self = shift;
    return $self->{MP_aliases}
        if $self->{MP_aliases};

    my $config = $self->{MP_aliparms} || {};

    # load alias expansion plugin
    my $class = delete $config->{class} or panic;
    eval "require $class"; panic $@ if $@;

    $self->{MP_aliases} = $class->new(%$config);
}


sub validator()
{   my $self = shift;
    return $self->{MP_validator}
        if $self->{MP_validator};

    my $config = $self->{MP_valparms} || {};

    # load username/password validator
    my $class = delete $config->{class} or panic;
    eval "require $class"; panic $@ if $@;

    $self->{MP_validator} = $class->new(%$config);
}


sub privatePEM()
{   my $self = shift;

    my $pem  = read_file $self->{MP_pem_fn};
    my $key  = Crypt::OpenSSL::RSA->new_private_key($pem);
    $key->use_pkcs1_padding;
    $key->use_sha256_hash;
    $key;
}

#------------------------

sub getSession($)
{   my ($self, $cgi) = @_;
    my $cookie  = $cgi->cookie($self->cookie)
        or error __x"no session cookie";

    my $session = CGI::Session->new('driver:File', $cookie)
        or error __x"invalid session cookie";

    $session;
}


sub _sign($$$)
{   my ($self, $client_pubkey, $email, $duration) = @_;

   # NB.  Treating the jwcrypto code as the spec here.
    my $issued_at = int(1000*time);

    my %cert      =
      ( iss          => $self->domain
      , exp          => $issued_at + 1000*$duration
      , iat          => $issued_at
      , "public-key" => $client_pubkey
      , principal    => { email => $email }
      );

    my %header     =
      ( typ          => 'JWT'
      , alg          => 'RS256'
      );

    my $header_enc = encode_base64url encode_json \%header;
    my $cert_enc   = encode_base64url encode_json \%cert;

    my $key       = $self->privatePEM or return;
    my $sig_enc    = encode_base64url $key->sign("$header_enc.$cert_enc");

    "$header_enc.$cert_enc.$sig_enc";
}

sub actionSign($)
{   my ($self, $cgi) = @_;

    my $session  = $self->getSession($cgi);
    my $user     = $session->param('user');

    print $cgi->header(-content_type => MIME_JSON);

    my $user_pubkey  = $cgi->param('pubkey')
        or error __x"nothing to sign for {user}", user => $user;

    my $duration = $cgi->param('duration') || 24*3600;

    my $email        = $cgi->param('email')
        or error __x"no email address to sign for {user}", user => $user;

    $self->isAliasFor($user, $email)
        or error __x"user {username} is not authorized to use {email}"
            , username => $user, email => $email;
         
    trace "signed $user $email";

    my $sig = $self->_sign(decode_json($user_pubkey), $email, $duration);
    print encode_json({signature => $sig}), "\n";
}


sub actionLogin($)
{   my ($self, $cgi) = @_;

    my $email    = $cgi->param('email')
        or error __x"no email address provided";

    my $password = $cgi->param('password')
        or error __x"no password provided for {email}", email => $email;

    my $validator = $self->validator;
    my @aliases   = $self->aliases->for($email);
    my $user      = first {$validator->isValid($_, $password)} @aliases;

    defined $user
        or error __x"authentication for {email} failed (aliases {aliases})"
          , email => $email, aliases => \@aliases;

    trace "authenticated $user";

    my $session;
    if(my $cookie  = $cgi->cookie($self->cookie))
    {   $session = CGI::Session->new("driver:File", $cookie);
    }

    if($session)
    {   # session restored
        print $cgi->header(-content_type => MIME_JSON);
    }
    else
    {   # new session, new cookie
        $session = CGI::Session->new("driver:File", undef);
        my $cookie = $cgi->cookie
          ( -name     => $self->cookie
          , -value    => $session->id
          , -expires  => '+1d'
          , -secure   => 1
          , -httponly => 1
          , -domain   => $self->domain
          );
        print $cgi->header(-content_type => MIME_JSON, -cookie => $cookie);
    }

    $session->param(user => $user);
    print encode_json({user => $user}), "\n";
}


sub actionIsLoggedIn($)
{   my ($self, $cgi) = @_;

    my $is_logged_in = 0;
    if(my $cookie  = $cgi->cookie($self->cookie))
    {   my $email  = $cgi->param('email');
        if(my $session = CGI::Session->new('driver:File', $cookie))
        {   my $user   = $session->param('user');
            $is_logged_in = $email && $user && $self->isAliasFor($user, $email);
            trace "$email $user is ".($is_logged_in ? '' : ' not')."logged in";
        }
        else
        {   trace "no session for $email";
        }
    }
    else
    {   trace "not logged in";
    }

    print $cgi->header(-content_type => MIME_JSON)
        , encode_json({logged_in_p => $is_logged_in})
        , "\n";
}


sub actionPing($)
{   my ($self, $cgi) = @_;
    print $cgi->header(-content_type => 'text/plain'), "PONG\n";
}

#------------------------------

sub isAliasFor($$)
{   my ($self, $user, $email) = @_;

    my @aliases  = $self->aliases->for($email);
    @aliases
        or error __x"user {user} for {email} not found"
            , user => $user, email => $email;

    my $lc_user = lc $user;
    first {$lc_user eq lc $_} @aliases;
}


sub writeConfig($)
{   my ($self, $fn) = @_;
    my %data;
 
    @data{ qw/private_pem cookie_name domain aliases validator/ }
      = @{$self}{ qw/MP_pem_fn MP_cookie MP_domain MP_aliparms MP_valparms/ };

    # MO: it's a pity, but there is no way to add comments to json.
    $data{generated_by} = "$0 $main::VERSION";
    $data{generated_on} = localtime();

    write_file $fn, JSON->new->utf8->pretty(1)->encode(\%data);
}

1;
