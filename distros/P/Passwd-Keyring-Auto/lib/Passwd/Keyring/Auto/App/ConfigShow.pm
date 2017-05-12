package Passwd::Keyring::Auto::App::ConfigShow;
use strict; use warnings;
use MooseX::App::Command;
extends 'Passwd::Keyring::Auto::App';

use Passwd::Keyring::Auto::Config;

sub run {
  my ($self, $opt, $arg) = @_;

  my $cfg_path = $self->config;

  # app, group ?
  my $cfg = Passwd::Keyring::Auto::Config->new(
      location=>$self->config, debug=>$self->debug);
  # environment

  print <<"END";
Passwd::Keyring::Auto configuration
==================================================
END

  print "Configuration file path: ", $cfg->config_location, "\n";
  unless($cfg->config_location->exists()) {
      print "    (file does not exist, to create use 'passwd_keyring config_create')\n";
  } else {
      print "    Config-file based settings applied by default:\n";
      print "        force:  ", $cfg->force || "<not-set>", "\n";
      print "        forbid: ", $cfg->forbid || "<not-set>", "\n";
      print "        prefer: ", $cfg->prefer || "<not-set>", "\n";
      my $per_app = $cfg->apps_with_overrides;
      if(@$per_app) {
          print "    Per-application overrides present for:\n";
          foreach my $pa (@$per_app) {
              print "        $pa\n";
          }
          print "    (check config for more details)\n";
      } else {
          print "    No per-application overrides.\n";
      }
  }

  print "Environment variables overriding config settings:\n";
  foreach my $var (qw(PASSWD_KEYRING_FORCE PASSWD_KEYRING_FORBID PASSWD_KEYRING_PREFER)) {
      print "    $var: ", $ENV{$var} || "<not-set>", "\n";
  }

}

1;

__END__

=head1 SYNOPSIS

    passwd_keyring config_show
    passwd_keyring config_show --config ~/.keyring-bld-tests.cfg

=head1 ABSTRACT

Display current Passwd::Keyring::Auto configuration.

=head1 DESCRIPTION

Show info which configuration file is in use by default, whether it contains
some settings, and which keyring backend would be picked.

=cut

