package Sentry::Util;
use Mojo::Base -strict, -signatures;

use Exporter qw(import);
use Mojo::Loader qw(load_class);
use Mojo::Util qw(dumper monkey_patch);
use UUID::Tiny ':std';

our @EXPORT_OK = qw(uuid4 truncate merge around);

sub uuid4 {
  my $uuid = create_uuid_as_string(UUID_V4);
  $uuid =~ s/-//g;
  return $uuid;
}

sub truncate ($string, $max = 0) {
  return $string if (ref($string) || $max == 0);

  return length($string) <= $max ? $string : substr($string, 0, $max) . '...';
}

sub merge ($target, $source, $key) {
  $target->{$key}
    = { ($target->{$key} // {})->%*, ($source->{$key} // {})->%* };
}

my %Patched = ();

sub around ($package, $method, $cb) {
  my $key = $package . '::' . $method;
  return if $Patched{$key};

  if (my $e = load_class $package) {
    die ref $e ? "Exception: $e" : "Module $package not found";
  }

  my $orig = $package->can($method);

  monkey_patch $package, $method => sub { $cb->($orig, @_) };

  $Patched{$key} = 1;

  return;
}

1;
