package MojoX::Authentication::Model;
{ our $VERSION = '0.100' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;
use Try::Catch;
use Scalar::Util qw< blessed refaddr >;
use Storable qw< dclone >;
use Module::Runtime qw< use_module >;
use MojoX::Authentication::Util qw< decode_name encode_name >;

use namespace::clean;

# hash reference with configurations that *might* be useful to providers
has config => (is => 'ro', default => sub { return {} });

# this is what we get from the outside
has providers => (is => 'ro', default => sub { return [] });

# this is what the module uses internally, after having created the actual
# providers in case they were not object already
has _providers => (is => 'lazy', init_arg => undef);

sub BUILD ($self, $args) {
   $self->_providers; # trigger _build__providers to fail fast
   return;
}

sub _build__providers ($self) {
   my $config = $self->config;

   my $name_setter = sub ($provider, $name) {
      # the following check is mostly paranoia
      ouch 400, 'undefined name for a provider' unless defined($name);

      return unless $provider->can('name');
      my $pname;
      try {
         $pname = $provider->name; # in case ->name() fails below
         $provider->name($name);
         $pname = $provider->name; # for double checking
         die '' if (! defined($pname)) || ($pname ne $name);
      }
      catch {
         $pname = defined($pname) ? qq{'$pname'} : 'undef';
         ouch 400, "cannot change provider name from $pname to '$name'";
      };
   };

   my (%by_name, @by_sequence, @unnamed, %seen);
   for my $candidate ($self->providers->@*) {
      next unless defined($candidate);

      my ($name, $provider);
      if (blessed($candidate)) { # $candidate is a $provider already
         $provider = $candidate;
         $provider->update_from_config($config)
            if $provider->can('update_from_config');
      }
      elsif (ref($candidate) eq 'CODE') { # $candidate is a factory
         $provider = $candidate->($config);
      }
      else { # $candidate has "means" for getting the $provider
         if (defined(my $instance = $candidate->{instance})) {
            $provider = $instance;
            $provider->update_from_config($config, $candidate)
               if $provider->can('update_from_config');
         }
         else {
            my ($class, $args, $name) = $candidate->@{qw< class args name >};
            my @args = ref($args) eq 'ARRAY' ? $args->@*
               : ref($args) eq 'HASH' ? $args->%*
               : ! defined($args) ? ()
               : ouch 400, 'invalid "args" in provider, array or hash refs only';
            push @args, name => $name if defined($name);
            $provider = use_module($class)->create($config, @args);
         };
         $name = $candidate->{name} // undef;
      }

      next unless defined($provider);

      ouch 400, 'cannot use the same provider instance twice'
         if $seen{refaddr($provider)}++;

      $name //= $provider->name if $provider->can('name');
      ouch 400, 'two providers are named the same', $name
         if defined($name) && exists($by_name{$name});

      # fail fast: do not accept providers that have load_user but do not
      # have tamed_user_record
      ouch 400, 'provider with load_user must also have tamed_user_record'
         if $provider->can('load_user')
         && ! $provider->can('tamed_user_record');

      my $item = {
         name => $name,
         provider => $provider,
      };
      push @by_sequence, $item;

      if (defined($name)) { # make sure $name sticks in the instance too
         $by_name{$name} = $provider;
         $name_setter->($provider, $name);
      }
      else {
         push @unnamed, $item;
      }
   }

   # give 'em all a name, make sure it sticks
   my $n = 0;
   ITEM:
   for my $item (@unnamed) {
      while ('necessary') {
         my $name = 'unnamed-' . $n++;
         next if exists($by_name{$name});
         $item->{name} = $name;
         my $provider = $by_name{$name} = $item->{provider};
         $name_setter->($provider, $name);
         next ITEM;
      }
   }

   return {
      sequence => \@by_sequence,
      by_name  => \%by_name,
   };
}

sub provider_named ($self, $name) {
   return $self->_providers->{by_name}{$name} // undef;
}

sub euid_join ($self, $provider_name, $uid) {
   return join('/', encode_name($provider_name), $uid);
}

sub euid_split ($self, $euid) {
   my ($encoded_name, $uid) = split m{/}mxs, $euid, 2;
   return unless defined($uid);
   return (decode_name($encoded_name), $uid);
}

sub run_fake_validation ($self) {
   for my $item ($self->_providers->{sequence}->@*) {
      my $provider = $item->{provider};
      next unless $provider->can('run_fake_validation');
      return $provider->run_fake_validation;
   }
   ouch 401, 'Unauthorized';
}

sub _item_for ($self, $controller, $username) {
   for my $item ($self->_providers->{sequence}->@*) {
      my $provider = $item->{provider};
      return $item if $provider->handles_username($controller, $username);
   }
   return undef;
}

sub provider_for ($self, $controller, $username) {
   my $item = $self->_item_for($controller, $username) or return;
   return $item->@{qw< name provider >} if wantarray();
   return $item->{provider};
}

sub provider_name_for ($self, $controller, $username) {
   my $item = $self->_item_for($controller, $username) or return undef;
   return $item->{name};
}

sub load_user ($self, $app, $euid) {
   my ($provider_name, $uid) = $self->euid_split($euid) or return;
   my $provider = $self->provider_named($provider_name) or return;
   ouch 401, 'cannot load user' unless $provider->can('load_user');
   my $user = $provider->load_user($app, $uid) // return;
   ouch 500, 'invalid user' unless ref($user) eq 'HASH';
   return {
      provider => $provider_name,
      uid      => $uid,
      data     => dclone($provider->tamed_user_record($user)),
   };
}

sub validate_user ($self, $ctr, $username, $secret, $extra) {
   my ($provider_name, $provider) = $self->provider_for($ctr, $username);
   return $self->run_fake_validation
      unless ($provider && $provider->can('validate_user'));
   my $uid = $provider->validate_user($ctr, $username, $secret, $extra);
   return undef unless defined($uid); # can it ever happen now?
   return $self->euid_join($provider_name, $uid);
}

1;
