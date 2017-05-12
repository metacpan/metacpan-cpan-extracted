package Mojolicious::Plugin::AdvancedMod::Fake;
# for test only

sub init {
  my ( $app, $helpers ) = @_;

  $app->log->debug('** AdvancedMod load Fake (test)');
}


1;
