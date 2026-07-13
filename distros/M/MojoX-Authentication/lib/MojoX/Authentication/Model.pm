package MojoX::Authentication::Model;
{ our $VERSION = '0.001' }

use v5.24;
use Moo;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;
use Scalar::Util qw< blessed refaddr >;
use Module::Runtime qw< use_module >;
use constant MISSING => [];

use namespace::clean;

# hash reference with configurations that *might* be useful to providers
has config => (is => 'ro', default => sub { return {} });

# this is what we get from the outside
has providers => (is => 'ro', default => sub { return [] });

# this is what the module uses internally, after having created the actual
# providers in case they were not object already
has _providers => (is => 'lazy', init_arg => undef);

sub _build__providers ($self) {
   my $config = $self->config;
   my (%by_name, @by_sequence, @unnamed);
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
            $provider->update_from_config($config)
               if $provider->can('update_from_config');
         }
         else {
            my ($class, $args) = $candidate->@{qw< class args >};
            my @args = ref($args) eq 'ARRAY' ? $args->@*
               : ref($args) eq 'HASH' ? $args->%*
               : ! defined($args) ? ()
               : ouch 400, 'invalid "args" in provider, array or hash refs only';
            $provider = use_module($class)->create($config, @args);
         };
         $name = $candidate->{name} // undef;
      }

      next unless defined($provider);

      $name //= $provider->name if $provider->can('name');
      ouch 400, 'two providers are named the same', $name
         if defined($name) && exists($by_name{$name});

      my $item = {
         name => $name,
         provider => $provider,
      };
      push @by_sequence, $item;
      $by_name{$name} = $provider if defined($name);
      push @unnamed, $item unless defined($name);
   }

   # give 'em all a name
   my $n = 0;
   ITEM:
   for my $item (@unnamed) {
      while ('necessary') {
         my $name = 'unnamed-' . $n++;
         next if exists($by_name{$name});
         $item->{name} = $name;
         $by_name{$name} = $item->{provider};
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

# iterate a call over providers, in the order they were set upon
# construction. Stop when one of them handles the call.
sub _iterate ($self, $method_name, @args) {
   $method_name ||= (caller(1))[3] =~ s{\A .* ::}{}rmxs;
   for my $item ($self->_providers->{sequence}->@*) {
      my $provider = $item->{provider};
      my $method = $provider->can($method_name) or next;
      my $retval = $provider->$method(@args);
      next unless defined($retval);
      return ($retval, $item->{name}) if defined($retval);
   }
   return;
}

sub provider_name_for ($self, $controller, $username) {
   my (undef, $provider_name) =
      $self->_iterate(handles_username => $controller, $username);
   return $provider_name;
}

sub load_user ($self, $app, $uid) {
   my ($user, $provider_name) = $self->_iterate(undef, $app, $uid);
   return {
      provider => $provider_name,
      uid      => $uid,
      data     => $user,
   };
}

sub validate_user ($self, $ctr, $username, $secret, $extra) {
   my ($uid) = $self->_iterate(undef, $ctr, $username, $secret, $extra);
   return $uid if defined($uid);
   return;
}

1;
