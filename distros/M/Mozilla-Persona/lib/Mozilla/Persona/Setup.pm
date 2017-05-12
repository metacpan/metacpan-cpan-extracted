# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package Mozilla::Persona::Setup;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Exporter';

our @EXPORT = qw/setup_persona/;

use open 'utf8';
use Log::Report         qw/persona/;

use File::Slurp         qw/read_file write_file/;
use JSON                qw/encode_json/;
use File::Basename      qw/basename/;

use Mozilla::Persona::Server ();
use Crypt::OpenSSL::Bignum   ();
use Crypt::OpenSSL::RSA      ();
use LWP::UserAgent           ();

my $ua;
my $latest_jquery = 'http://code.jquery.com/jquery.min.js';
my $restart;

sub get_jquery($$);
sub create_private_key($$);
sub publish_config($$);
sub publish_helpers($$$);


sub setup_persona(%)
{   my %args = @_;

    ### Configuration

    my $docroot = $args{docroot} or panic;
    my $secrets = $args{secrets} or panic;
    my $domain  = $args{domain}  or panic;
    my $group   = $args{group}   or panic;
    $restart    = $args{restart} || 0;

    -d $docroot
        or fault __x"website doc-root {dir} missing", dir => $docroot;

    my $servdir = "$docroot/persona";
    my $jquery  = "$servdir/jquery.js";
    my $config  = "$secrets/$domain.json";
    my $privkey = "$secrets/$domain.pem";

    -d $secrets || mkdir $secrets
        or fault __x"cannot create directory {dir} for secrets", dir => $secrets;

    -d $servdir || mkdir $servdir
        or fault __x"cannot create directory {dir} for service", dir => $servdir;

    my $wk      = "$docroot/.well-known";
    -d $wk || mkdir $wk
        or fault __x"cannot create directory {dir} for publish", dir => $wk;

    my $publish = "$wk/browserid";

    (my $setup_src = __FILE__) =~ s!Setup.pm$!setup!;

    ### Work

    get_jquery $latest_jquery, $jquery;
    create_private_key $privkey, $group;
    publish_config $publish, $privkey;

    my $persona = Mozilla::Persona::Server->new
     ( private_pem => $privkey
     , cookie_name => 'persona'
     , domain      => $domain
     , validator   =>
        { class  => 'Mozilla::Persona::Validate::Table'
        , pwfile => "$secrets/passwords"
        , domain => $domain
        }
     );

    $persona->writeConfig($config);

    publish_helpers $setup_src, "$docroot/persona", $config;

    print __x"now you probably want to modify {fn}", fn => $config;
}

#### HELPERS

sub get_jquery($$)
{   my ($from_url, $to_fn) = @_;

    if(-f $to_fn && !$restart)
    {   info __x"reusing jquery from {fn}", fn => $to_fn;
        return;
    }

    info __x"downloading latest jquery stable into {fn}", fn => $to_fn;

    $ua ||= LWP::UserAgent->new;
    my $resp = $ua->get($from_url);
    $resp->is_success
        or error __x"failed downloading jquery from {url}: {err}"
             , url => $from_url. err => $resp->status_line;

    write_file $to_fn, $resp->decoded_content || $resp->content;
}

sub create_private_key($$)
{   my ($outfn, $group) = @_;

    my $gid = getpwnam $group
        or error __x"unknown group {name}", name => $group;

    if(-f $outfn && !$restart)
    {   info __x"reusing private key in {fn}", fn => $outfn;

        my $has_gid = (stat $outfn)[5];
        $gid == $has_gid
            or warning __x"please set group on {fn} to {group}"
                 , fn => $outfn, group => $group;

        return;
    }

    info __x"generating new private key at {fn}", fn => $outfn;

    ! -f $outfn || unlink $outfn
        or fault __x"cannot replace existing pem file in {fn}", fn => $outfn;

    my $key = Crypt::OpenSSL::RSA->generate_key(2048);
    write_file $outfn, $key->get_private_key_string;

    chmod 0440, $outfn;
    chown -1, $gid, $outfn
        or warning __x"please set group on {fn} to {group}"
             , fn => $outfn, group => $group;

    $key;
}

sub publish_config($$)
{   my ($outfn, $keyfn) = @_;

    my $pem = read_file $keyfn;
    my $key = Crypt::OpenSSL::RSA->new_private_key($pem);

    my ($n, $e, @stuff) = $key->get_key_parameters;
    write_file $outfn, encode_json
      { 'public-key'     =>
          { e => $e->to_decimal
          , n => $n->to_decimal
          , algorithm => 'RS'
          }
      , authentication => '/persona/authenticate.html'
      , provisioning   => '/persona/provision.html'
      };

    info __x"public configuration written to {fn}", fn => $outfn;
    $outfn;
}

sub publish_helpers($$$)
{   my ($indir, $outdir, $config) = @_;
    local(*FROM, *TO);
    -d $outdir or mkdir $outdir
        or fault __x"cannot create directory {dir}", dir => $outdir;

    foreach my $fn (glob "$indir/*")
    {   my $outfn = $outdir.'/'.basename $fn;
        if(-f $outfn && !$restart)
        {   info __x"keeping file {fn}", fn => $outfn;
            next;
        }

        open FROM, '<:encoding(utf8)', $fn
            or fault __x"cannot read {filename}", filename => $fn;

        open TO, '>:encoding(utf8)', $outfn
            or fault __x"cannot write to {filename}", filename => $outfn;

        while(<FROM>)
        {   s/__CONFIG__/$config/;
            print TO $_;
        }

        close TO;
        close FROM;

        my $mode = $outfn =~ m/\.pl$/i ? 0755 : 0644;
        chmod $mode, $outfn;

        info __x"created file {fn} more 0{mode%o}", fn => $outfn, mode => $mode;
    }
}

1;
