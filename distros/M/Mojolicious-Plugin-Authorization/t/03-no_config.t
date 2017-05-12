#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;
use Test::Exception;

my $plugin_config = {};

for my $required_param ( qw/ has_priv is_role user_privs user_role / ) {
  if ( ! keys %{ $plugin_config } ) {
    throws_ok(
      sub { plugin 'authorization' },
      qr/missing '$required_param' subroutine ref in parameters/,
      "plugin with no config croaks",
    );
  }
  throws_ok(
    sub { plugin 'authorization' => $plugin_config; },
    qr/missing '$required_param' subroutine ref in parameters/,
    "plugin with no '$required_param' config croaks",
  );
  $plugin_config->{$required_param} = "not a code ref";
  throws_ok(
    sub { plugin 'authorization' => $plugin_config; },
    qr/missing '$required_param' subroutine ref in parameters/,
    "plugin with none code ref '$required_param' config croaks",
  );
  $plugin_config->{$required_param} = sub {};
}

done_testing();

# vim: ts=2:sw=2:et
