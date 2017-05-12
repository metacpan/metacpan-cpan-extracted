package Mite::Role::HasConfig;

use feature ':5.10';
use Mouse::Role;
use Method::Signatures;

has config =>
  is            => 'ro',
  isa           => 'Mite::Config',
  lazy          => 1,
  default       => method {
      require Mite::Config;
      state $config = Mite::Config->new;
      return $config;
  };

1;
