package MojoX::Authentication::Model::SAML2;
{ our $VERSION = '0.001' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Net::SAML2;
use Net::SAML2::Protocol::AuthnRequest;
use Net::SAML2::Binding::Redirect;
use Net::SAML2::Binding::POST;
use Net::SAML2::Protocol::Assertion;
use Net::SAML2::XML::Sig;
use Ouch qw< :trytiny_var >;
use Try::Catch;
use JSON::PP qw< encode_json decode_json >;
use Storable qw< dclone >;
use File::Temp qw< tempfile >;
use Scalar::Util qw< blessed >;
use Module::Runtime qw< use_module >;

use constant DEFAULT_FOR => {
   name => 'saml2',
   request_ttl => 30,
   user_key => 'key',
   user_ttl => 5 * 60,
   sig_hash => undef,

   # we don't need to worry about backwards mappings here
   remaps => [
      {
         okey => 'givenname',
         ikey => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
         op => \&join_if_array,
      },
      {
         okey => 'surname',
         ikey => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
         op => \&join_if_array,
      },
      sub ($user, $is_backwards) {
         $user->{fullname} = join(' ',
            grep { defined } $user->@{qw< givenname surname >}) // '';
      },
   ],
};

sub join_if_array ($x) {
   return $x unless ref($x) eq 'ARRAY';
   return join(', ', $x->@*);
}

sub coerce_cache ($x) {
   # as a shortcut, if we're passed a MojoX::MojoDbWrap instance, we assume
   # that we want a ::SAML2::Db cache using $x as its wmdb
   $x = {
      class => 'MojoX::Authentication::Model::SAML2::Db',
      args => { wmdb => $x },
   } if eval { $x->isa('MojoX::MojoDbWrap') };

   # anything still blessed at this point is assumed to be a valid cache
   return $x if blessed($x);

   # set defaults and normalize
   $x //= 'MojoX::Authentication::Model::SAML2::Hash';
   $x = { class => $x } unless ref($x);

   # extract (optional) args, normalizing them too
   my $args = $x->{args} // [];
   my @args = ref($args) eq 'ARRAY' ? $args->@* : $args->%*;

   # time to create something
   return use_module($x->{class})->new(@args);
}

sub coerce_idp ($x) {
   return $x if blessed($x);
   require Net::SAML2::IdP;
   return Net::SAML2::IdP->new_from_url(url => $x)
      if $x =~ m{\A (?: \w+) :// }imxs;
   if (-e $x) {
      open my $fh, '<:raw', $x or ouch 400, 'cannot read file', $x;
      local $/;
      $x = <$fh>;
   }
   return Net::SAML2::IdP->new_from_xml(xml => $x);
}

sub __key ($prefix, $x) { join '-', $prefix, (ref($x) ? $x->{key} : $x) }

use namespace::clean;

with 'MojoX::Authentication::Model::Role::Creator';
with 'MojoX::Authentication::Model::Role::Remap';

has cache => (is => 'ro', coerce => \&coerce_cache, default => undef);
has idp => (is => 'ro', required => 1, coerce => \&coerce_idp);
has name => (is => 'ro', default => DEFAULT_FOR->{name});
has remaps => (is => 'ro', default => sub { DEFAULT_FOR->{remaps} });
has request_ttl => (is => 'ro', default => DEFAULT_FOR->{request_ttl});
has sig_hash => (is => 'ro', default => DEFAULT_FOR->{sig_hash});
has sp_configuration => (is => 'ro', required => 1);
has user_key  => (is => 'ro', default => DEFAULT_FOR->{user_key});
has user_ttl  => (is => 'ro', default => DEFAULT_FOR->{user_ttl});
has username_validator => (is => 'lazy');

sub _build_username_validator ($self) {
   return sub ($name) { return 'by all means' };
};

sub _cache_user ($self, $user, $ttl = undef) {
   my $key = __key(user => $user);
   my $expire = time() + ($ttl //= $self->user_ttl);
   $self->cache->set($user, $key, $expire);
   return $self;
}

sub create ($class, $config, %args) {
   %args = $class->_create_args(DEFAULT_FOR->{name}, $config, %args);
   return unless defined($args{idp}) && defined($args{sp_configuration});
   return $class->new(%args);
}

sub handles_username ($self, $controller, $name) {
   return 'sure' if $self->username_validator->($name);
   return undef;
}

# returns id of request and redirect URL
sub idp_login ($self) {
   my $sp_conf  = $self->sp_configuration;
   my $idp = $self->idp;

   my $sso_url =
      $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

   my $assertion_url = $sp_conf->{'sso-post-url-override'} // undef;
   my $authnreq = Net::SAML2::Protocol::AuthnRequest->new(
      issuer        => $sp_conf->{identifier},
      destination   => $sso_url,
      (defined($assertion_url) ? (assertion_url => $assertion_url) : ()),
   );

   # Store the request's id for later verification
   my $id = $authnreq->id;
   my $key = __key(authnreq_id => $id);
   my $ts = time();
   my $expire = $ts + $self->request_ttl;
   $self->cache->set({ ts => $ts }, $key, $expire);

   my $sig_hash = $self->sig_hash;
   my $redirect = Net::SAML2::Binding::Redirect->new(
      key   => $sp_conf->{key},    # to sign the redirect
      param => 'SAMLRequest',      # what's this about
      url   => $sso_url,           # where it's heading to
      (defined($sig_hash) ? (sig_hash => $sig_hash) : ()),
   );
   my $url = $redirect->sign($authnreq->as_xml);

   return ($id, $url);
}

sub load_user ($s, $A, $key) { return $s->cache->get(__key(user => $key)) }

# TODO FIXME this is an occasion to implement some clever redirection in
# the Controller to implement the logout properly (i.e. forwarding to the
# server, not just "consider this user gone here"). But we're not there
# yet, sorry!
sub logout ($self, $controller, $user) {
   $self->wipe_user($user);
   $controller->logout;
   return;
}

sub _normalize_user ($s, $user) { return $s->remap($user, $s->remaps) }

sub parse_assertion ($self, $id, $response) {
   defined($response) or ouch 400, 'No SAMLResponse';
   defined($id)
      or ouch 400, 'Not expecting anything SAML-related', 'undefined id';
   my $reqts = $self->cache->get(__key(authnreq_id => $id))
      or ouch 400, 'Not expecting anything SAML-related', 'unknown id';
   time() <= $reqts->{ts} + 30
      or ouch 400, 'Not expecting anything SAML-related', 'expired id';

   my $xml_response =
      Net::SAML2::Binding::POST->new->handle_response($response);

   # the module insists on a file-based CA certificate...
   my ($fh, $cacert_path) = tempfile();
   print {$fh} join "\n\n", $self->idp->cert('signing')->@*;
   close $fh;

   my $sp_conf = $self->sp_configuration;
   my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
      xml => $xml_response,
      key_file => $sp_conf->{key},
      cacert => $cacert_path,
   );
   unlink $cacert_path;

   $assertion->valid($sp_conf->{identifier}, $id)
     or ouch 400, 'Invalid SAMLResponse';

   my $uid = $assertion->nameid;
   my $user = $self->_normalize_user(
      { $assertion->attributes->%*, $self->user_key => $uid, });
   $self->_cache_user($user);

   return $user;
}

# this should never (arguably) be called if "auto_validate" in
# Mojolicious::Plugin::Authentication is used. Anyway...
sub validate_user ($self, $controller, $name, $secret, $extra) {
   ...;
   return defined($self->load_user($name)) ? $name : undef;
}

sub wipe_user ($self, $user) { $self->cache->wipe(__key(user => $user)) }

1;
