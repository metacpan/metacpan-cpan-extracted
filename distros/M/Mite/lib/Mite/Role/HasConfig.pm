package Mite::Role::HasConfig;
use Mite::MyMoo -Role;

has config =>
  is            => ro,
  isa           => InstanceOf['Mite::Config'],
  lazy          => 1,
  default       => sub {
      require Mite::Config;
      state $config = Mite::Config->new;
      return $config;
  };

1;
