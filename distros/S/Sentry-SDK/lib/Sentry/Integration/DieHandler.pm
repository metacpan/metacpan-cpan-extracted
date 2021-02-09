package Sentry::Integration::DieHandler;
use Mojo::Base -base, -signatures;

use Mojo::Exception;

sub setup_once ($self, $add_global_event_processor, $get_current_hub) {
  ## no critic (Variables::RequireLocalizedPunctuationVars)
  $SIG{__DIE__} = sub {
    ref $_[0] ? CORE::die $_[0] : Mojo::Exception->throw(shift);
    # ref $_[0] ? CORE::die $_[0] : Mojo::Exception->new(shift)->trace;
  };
}

1;
