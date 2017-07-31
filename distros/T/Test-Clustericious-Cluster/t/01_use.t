use Test2::V0 -no_srand => 1;
sub require_ok ($);

BEGIN { eval q{ use EV } } # supress CHECK block warning, if EV is installed
BEGIN { eval q{ use Test::Builder } } # supress CHECK block warning, if EV is installed

require_ok 'Test::Clustericious::Cluster';
require_ok 'Mojolicious::Plugin::PlugAuthLite';
require_ok 'PlugAuth::Lite';
require_ok 'Test::PlugAuth';

done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  eval qq{ require $mod };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}

