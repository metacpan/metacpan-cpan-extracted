package Passwd::Keyring::Auto::App::ConfigEdit;
use strict; use warnings;
use MooseX::App::Command;
extends 'Passwd::Keyring::Auto::App';

use Passwd::Keyring::Auto::Config;
require Passwd::Keyring::Auto::App::ConfigCreate;

option 'editor' => (
    is => 'rw', isa => 'Str', required => 0,
    documentation => q[Text editor to use],
    default => sub {
        my $edit = $ENV{EDITOR} or die "Editor not set. Either set EDITOR configuration variable, or specify --editor option\n";
        return $edit;
    },
   );

sub run {
  my ($self, $opt, $arg) = @_;

  my $cfg_path = $self->config;

  my $cfg = Passwd::Keyring::Auto::Config->new(
      location=>$self->config, debug=>$self->debug);
  my $editor = $self->editor;

  my $config_loc = $cfg->config_location;
  unless($config_loc->exists) {
      Passwd::Keyring::Auto::App::ConfigCreate::create_default_config($config_loc);
  }

  print "Spawning $editor on  ", $cfg->config_location, "\n";
  system($editor, $cfg->config_location->stringify);
}

1;

__END__

=head1 SYNOPSIS

    passwd_keyring config_edit
    passwd_keyring config_edit --editor emacsclient

=head1 ABSTRACT

Spawn editor on configuration file.

=head1 DESCRIPTION

Handy shortcut, open editor on Passwd::Keyring::Auto configuration
file, creating the file in case it is missing.

=cut

