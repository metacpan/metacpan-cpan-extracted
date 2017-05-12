package Passwd::Keyring::Auto::App::ConfigCreate;
use strict; use warnings;
use MooseX::App::Command;
extends 'Passwd::Keyring::Auto::App';

# option 'backend' => (
#     is => 'rw', isa => 'Str', required => 0,
#     documentation => q[Set preferred backend'],
#     # cmd_tags = => [qw(Important)],
#     cmd_aliases => ['b'],
#     # cmd_flag => 'provider',
#    );

# parameter - positional parameter

# Unchecked!!
sub create_default_config {
    my ($cfg_path) = @_;

    $cfg_path->spew_utf8(<<"END");
; Passwd::Keyring::Auto backend selection rules. 
; Edit to your needs. See also 
;     perldoc Passwd::Keyring::Auto

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Backend selection criteria:
;;
;; - force:  use that backend no matter what
;;           (fail if it does not work)
;; - prefer: try these backends first, in that order
;;           (but revert to other known if all those fail)
;; - forbid: never use those backends
;;
;; Use last part of backend module as backend name, for example
;; "Gnome" relates to Passwd::Keyring::Gnome module.

; prefer=KDEWallet PWSafe3
; forbid=Gnome Memory
; force=KDEWallet

;; Selected backends customizations.
;;
;; Parameters given here are forwarded to appropriate backend
;; constructor. Example below sets file parameter for PWSafe3 backend
;; constructor.

; PWSafe3.file=/home/joel/passwd-keyring.pwsafe3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Per-applicaton overrides
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Any of settings above can be overriden (or provided) for specific
;; applications. The section name should match application name (or,
;; more exactly, to whatever given applicaton provides as `app`
;; parameter to get_keyring method.

; [WebScrapers]
; force=PWSafe3
; PWSafe3.file=/home/joel/web-scrapers-keyring.pwsafe3

END

  print <<"END";
Initial configuration file has been created at
    $cfg_path

END
}

sub run {
  my ($self, $opt, $arg) = @_;

  my $cfg_path = $self->config;

  my $cfg = Passwd::Keyring::Auto::Config->new(
      location=>$self->config, debug=>$self->debug);

  my $loc = $cfg->config_location;
  if($loc->exists()) {
      print "    File $loc already exists.\n";
      exit(1);
  }

  create_default_config($loc);
}

1;

__END__

=head1 SYNOPSIS

    passwd_keyring config_create
    passwd_keyring config_create --config ~/.keyring-bld-tests.cfg

=head1 ABSTRACT

Create initial (commented-out) configuration file.

=head1 DESCRIPTION

Create initial (commented-out) Passwd::Keyring::Auto configuration,
containing examples of all configuration settings in use.

Reports an error in case file already exists.

=cut


