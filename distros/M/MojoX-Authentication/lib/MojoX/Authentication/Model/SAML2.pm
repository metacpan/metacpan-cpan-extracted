package MojoX::Authentication::Model::SAML2;
{ our $VERSION = '0.100' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Net::SAML2 0.86; # refuse anything lower, they changed interface!
use Net::SAML2::Protocol::AuthnRequest;
use Net::SAML2::Object::Response;
use Net::SAML2::Binding::Redirect;
use Net::SAML2::Binding::POST;
use Net::SAML2::Protocol::Assertion;
use Ouch qw< :trytiny_var >;
use File::Temp ();
use Scalar::Util qw< blessed >;
use Module::Runtime qw< use_module >;
use MojoX::Authentication::Util qw< encode_name >;

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
   if ($x !~ m{\A \s* < }mxs) {
      open my $fh, '<:raw', $x or ouch 400, 'cannot read file', $x;
      local $/;
      $x = <$fh>;
   }
   return Net::SAML2::IdP->new_from_xml(xml => $x);
}

use namespace::clean;

with 'MojoX::Authentication::Model::Role::Creator';
with 'MojoX::Authentication::Model::Role::Remap';

has cache => (is => 'ro', coerce => \&coerce_cache, default => undef);
has idp => (is => 'ro', required => 1, coerce => \&coerce_idp);
has name => (is => 'rw', default => DEFAULT_FOR->{name});
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

sub _key ($self, $prefix, $x) {
   my $bare = ref($x) eq 'HASH' ? $x->{$self->user_key} : $x;
   my $ename = encode_name($self->name);
   return "$prefix-$ename/$bare";
}

sub _cache_user ($self, $user, $ttl = undef) {
   my $key = $self->_key(user => $user);
   my $expire = time() + ($ttl //= $self->user_ttl);
   $self->cache->set($user, $key, $expire);
   return $self;
}

sub create ($class, $config, %args) {
   %args = $class->_create_args(DEFAULT_FOR->{name}, $config, %args);
   ouch 404, 'missing argument for idp' unless defined($args{idp});
   ouch 404, 'missing argument for sp_configuration'
      unless defined($args{sp_configuration});
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
   my $key = $self->_key(authnreq_id => $id);
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

sub load_user ($self, $A, $key) {
   return $self->cache->get($self->_key(user => $key));
}

sub tamed_user_record ($self, $user) {
   # the SAML2 user record does not have any secret material inside, so
   # we can pass $user through
   return $user;
}

# TODO FIXME this is an occasion to implement some clever redirection in
# the Controller to implement the logout properly (i.e. forwarding to the
# server, not just "consider this user gone here"). But we're not there
# yet, sorry!
sub logout ($self, $controller, $user) {
   $self->wipe_user($user->{uid});
   $controller->logout;
   return;
}

sub _normalize_user ($s, $user) { return $s->remap($user, $s->remaps) }

sub parse_assertion ($self, $id, $response) {
   defined($response) or ouch 400, 'No SAMLResponse';
   defined($id)
      or ouch 400, 'Not expecting anything SAML-related', 'undefined id';
   my $req_key = $self->_key(authnreq_id => $id);
   my $reqts = $self->cache->get($req_key)
      or ouch 400, 'Not expecting anything SAML-related', 'unknown id';
   $self->cache->wipe($req_key);   # single use: no replays
   time() <= $reqts->{ts} + $self->request_ttl
      or ouch 400, 'Not expecting anything SAML-related', 'expired id';

   my $idp = $self->idp;

   # the module for Assertion insists on a file-based CA certificate so we
   # save it in a temporary file. It is also useful for the POST module
   # since Net::SAML 0.88
   my $tmp = File::Temp->new;
   print {$tmp} join "\n\n", $idp->cert('signing')->@*;
   close $tmp;

   my $xml_response = Net::SAML2::Binding::POST
      ->new(cacert => $tmp->filename)
      ->handle_response($response);

   my $saml_response = Net::SAML2::Object::Response->new_from_xml(
      xml => $xml_response,
      cacert => $tmp->filename,
   );
   if (! $saml_response->success) {
      my $status = $saml_response->status;
      my $substatus = $saml_response->substatus;
      $status .= '/' . $substatus if defined($substatus);
      ouch 403, "IdP refused with $status";
   }

   my $sp_conf = $self->sp_configuration;
   my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
      xml => $xml_response,
      key_file => $sp_conf->{key},
      cacert => $tmp->filename,
      issuer => $idp->entityid,
   );

   $assertion->valid($sp_conf->{identifier}, $id, $idp->entityid)
     or ouch 400, 'Invalid SAMLResponse';

   my $uid = $assertion->nameid;
   ouch 400, 'no NameID in assertion' unless length($uid // '') > 0;
   my $user = $self->_normalize_user(
      { $assertion->attributes->%*, $self->user_key => $uid, });
   $self->_cache_user($user);

   return $user;
}

sub wipe_user ($self, $user) { $self->cache->wipe($self->_key(user => $user)) }

1;
