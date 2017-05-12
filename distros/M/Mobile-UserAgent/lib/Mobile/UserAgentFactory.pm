package Mobile::UserAgentFactory;
use strict;
use Mobile::UserAgent;
use base qw(Class::Singleton);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ m/ (\d+) \. (\d+) /xg;


# Contructor called by Class::Singleton to initialize a new instance.
sub _new_instance {
  my $proto = shift;
  my $options = shift;
  my $class = ref($proto) || $proto;
  my %cache_options;
  if (defined($options) && (ref($options) eq 'HASH')) {
    if (defined($options->{'cache_expires_in'})) {
      $cache_options{'expires_in'} = $options->{'cache_expires_in'};
    }
    if (defined($options->{'cache_purge_interval'})) {
      $cache_options{'purge_interval'} = $options->{'cache_purge_interval'};
    }
    if (defined($options->{'cache_max_age'})) {
      $cache_options{'max_age'} = $options->{'cache_max_age'};
    }
    if (defined($options->{'cache_max_objects'})) {
      $cache_options{'max_objects'} = $options->{'cache_max_objects'};
    }
  }
  my $self = {
   'cache' => Mobile::UserAgentFactoryCache->new(\%cache_options), # internal class
	};
  bless $self,$class;
  return $self;
}



# Uses the given useragent string to return a Mobile::UserAgent object if a match can be found.
sub getMobileUserAgent {
  my $self = shift;
  my $useragent;
  my $debug = 0;
  if (@_) {
    if (ref($_[0]) eq '') {
      $useragent = shift;
    }
    elsif (UNIVERSAL::isa(ref($_[0]), 'CGI')) {
      my $q = shift;
      $useragent = $q->user_agent();
    }
  }
  if (@_ && (ref($_[0]) eq 'HASH')) {
    my $options = shift;
    if (defined($options->{'debug'})) {
      $debug = $options->{'debug'};
    }
  }
  unless(defined($useragent)) {
    $useragent = $ENV{'HTTP_USER_AGENT'};
    unless(defined($useragent)) {
      $debug && print("Returning undef, because no user-agent was found in env vars.\n");
      return undef;
    }
  }

  # Try to fetch object from internal cache.
  my $cache = $self->{'cache'};
  my $mua = $cache->get($useragent);
  if (defined($mua) || $cache->key_exists($useragent)) {
    $debug && print("Returning Mobile::UserAgent object found in internal cache.\n");
    return $mua;
  }

  # Create new Mobile::UserAgent object, cache it, and return it.
  $mua = Mobile::UserAgent->new($useragent);
  $cache->set($useragent, $mua);
  return $mua;
}

1;

#### end of Mobile::UserAgentFactory ####











# Internal cache manager class.
package Mobile::UserAgentFactoryCache;
use strict;


# Contructor. Accepts an optional hash ref of options.
sub new {
  my $proto = shift;
  my $options = shift;
  my $class = ref($proto) || $proto;
  my $expires_in = 86400; # 1 day
  my $purge_interval = 3600; # 1 hour
  my $max_age = 604800; # 1 week
  my $max_objects = 1000;
  if (defined($options) && (ref($options) eq 'HASH')) {
    if (defined($options->{'expires_in'}) && $options->{'expires_in'}) {
      $expires_in = $options->{'expires_in'};
    }
    if (defined($options->{'purge_interval'}) && $options->{'purge_interval'}) {
      $purge_interval = $options->{'purge_interval'};
    }
    if (defined($options->{'max_age'}) && $options->{'max_age'}) {
      $max_age = $options->{'max_age'};
    }
    if (defined($options->{'max_objects'}) && $options->{'max_objects'}) {
      $max_objects = $options->{'max_objects'};
    }
  }
  my $self = {
	'objects'        => {}, # Cache of key => [object, create-time, last-access-time]
	'expires_in'     => $expires_in,
	'purge_interval' => $purge_interval,
	'max_age'        => $max_age,
	'max_objects'    => $max_objects,
	'last_purge'     => time,
	'max_objects_check_interval' => int($max_objects / 10), # after this many set() calls, the limit_max_objects() call will be executed.
	'max_objects_set_counter' => 0, # increases with each set() method call and is reset with with each limit_max_objects() call.
	};
  bless $self,$class;
  return $self;
}


# Checks if a key exists in the cache.
sub key_exists {
  my $self = shift;
  my $key = shift;
  return exists($self->{'objects'}->{$key});
}


# Gets a cached object.
sub get {
  my $self = shift;
  my $key = shift;
  my $objects = $self->{'objects'};
  my $result;
  if (exists($objects->{$key})) {
    my $object = $objects->{$key};
    $result = $object->[0];
    $object->[2] = time;
  }
  $self->_purge();
  return $result;
}


# Simply calls purge() if it's time to do so.
sub _purge {
  my $self = shift;
  if ($self->{'last_purge'} + $self->{'purge_interval'} <= time) {
    return $self->purge();
  }
  return 0;
}


# Purges all cached objects that have not been accessed recently or are too old.
sub purge {
  my $self = shift;
  my $objects = $self->{'objects'};
  my $now = time;
  my $max_age = $self->{'max_age'};
  my $expires = $self->{'expires_in'};
  my $result = 0;
  foreach my $key (keys %{$objects}) {
    my $object = $objects->{$key};
    if (($object->[2] + $expires <= $now) || ($object->[1] + $max_age <= $now)) {
      print "About to purge key: $key\n";
      delete($objects->{$key});
      $result++;
    }
  }
  $self->{'last_purge'} = $now;
  return $result;
}


# Sets a new object.
sub set {
  my $self = shift;
  my $key = shift;
  my $object = shift;
  my $now = time;
  $self->{'objects'}->{$key} = [$object, $now, $now];
  if (++$self->{'max_objects_set_counter'} >= $self->{'max_objects_check_interval'}) {
    return $self->limit_max_objects();
  }
}


# Shrinks the cache to 10% below max if max has been exceeded by 10%.
sub limit_max_objects {
  my $self = shift;
  $self->_purge();
  my $objects = $self->{'objects'};
  my $size = scalar(keys(%{$objects}));
  my $max_objects = $self->{'max_objects'};
  if ($size <= $max_objects) {
    return 0;
  }
  # sort keys on last-access-time descending
  my @sorted_keys = sort { $objects->{$b}->[2] <=> $objects->{$a}->[2] } keys(%{$objects});
  my @expired_keys = splice(@sorted_keys, $max_objects - 1 - int(0.2 * $max_objects)); # shrink to 20% below max
  #print 'About to delete keys: ' . join(' ', @expired_keys) . "\n";
  foreach my $key (@expired_keys) {
    delete($objects->{$key});
  }
  $self->{'max_objects_set_counter'} = 0;
  return scalar(@expired_keys);
}

#### end of Mobile::UserAgentFactoryCache ####
1;


__END__

=head1 NAME

Mobile::UserAgentFactory - Instantiates and caches Mobile::UserAgent objects.

=head1 SYNOPSIS

 use Mobile::UserAgentFactory;
 my $factory = Mobile::UserAgentFactory->instance();

 # Get Mobile::UserAgent object using a useragent string (preferred):
 my $mua = $factory->getMobileUserAgent($ENV{'HTTP_USER_AGENT'});

 # Get Mobile::UserAgent object by letting the factory look for the useragent in
 # the HTTP_* environment variables.
 my $mua = $factory->getMobileUserAgent();

 if (defined($mua) && $mua->success()) {
   printf("Vendor: %s\nModel: %s\n", $mua->vendor(), $mua->model());
 }


=head1 DESCRIPTION

Factory class for the instantiating and caching of Mobile::UserAgent objects.
Caching occurs in this class itself.

=head1 CONSTRUCTOR

=over 4

=item $factory = Mobile::UserAgentFactory->instance($options_hash_ref)

This class method returns a Mobile::UserAgentFactory instance.

The optional $options_hash_ref supports the following options:

  cache_expires_in - The expiration time for unused Mobile::UserAgent objects in the internal cache. Defaults to 86400 (1 day) if not explicitly set.

  cache_purge_interval - Sets the internal cache purge interval. Defaults to 3600 (1 hour).

  cache_max_age - Sets the maximum time Mobile::UserAgent objects may remain in the internal cache. Defaults to 604800 (1 week).

  cache_max_objects - Sets the maximum number of objects to store in the internal cache. Defaults to 1000.

=back

=head1 PUBLIC OBJECT METHODS

The public object methods available are:

=over 4

=item $uaprof->getMobileUserAgent([$useragent | $cgi], [$options])

Returns a matching Mobile::UserAgent object or undef if none could be found.

You can optionally pass either a $useragent string or a CGI object as
first parameter. If you pass neither, then this method will attempt to
use the HTTP_USER_AGENT environment variable.

$options is an optional hash ref which may contain the following keys:

  debug - Set it to a true value to see what's going on.

=back

=head1 SEE ALSO

L<Mobile::UserAgent>.

=head1 COPYRIGHT

Copyright (C) 2005 Craig Manley.  All rights reserved.
You may not redistribute, sell, modify, copy, claim ownership of, nor
incorporate this software into any other software without the prior written
permission of the author. This software may only be used in applications
developed by the author.

=head1 AUTHOR

Craig Manley

=cut