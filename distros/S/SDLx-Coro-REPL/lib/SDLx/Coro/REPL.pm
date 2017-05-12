package SDLx::Coro::REPL;

=head1 NAME

SDLx::Coro::REPL - A REPL for your SDL

=head1 SYNOPSIS

  use SDLx::Controller::Coro;
  use SDLx::Coro::REPL;
  SDLx::Coro::REPL::start();
  my $controller = SDLx::Controller::Coro->new;
  $controller->run();

  # More coming soon!
  # Also see eg/sdl_coro_repl.pl

=cut

BEGIN { $ENV{PERL_RL} = 'Perl' }

use Devel::REPL;
use Coro;
use SDLx::Controller::Coro;

our $VERSION = '0.03';

use Term::ReadLine::readline;
{
  package readline;

  no warnings 'redefine';
  sub rl_getc {
    my $key;
    # $Term::ReadLine::Perl::term->Tk_loop if $Term::ReadLine::toloop && defined &Tk::DoOneEvent;
    until(defined ($key = Term::ReadKey::ReadKey(-1, $readline::term_IN))) {
      # print "Waiting for key...\n";
      SDLx::Controller::Coro::yield();
    }
    return $key;
  }

  $readline::rl_getc = \&rl_getc;
}


sub start {
  # use perl5i;
  use vars qw( $repl );
  $repl = Devel::REPL->new;
  $repl->load_plugin($_) for qw(
    History DumpHistory
    OutputCache
    LexEnv
    Colors
    MultiLine::PPI
    FancyPrompt
    DDS
    Refresh
    Interrupt
    Packages
    ShowClass
    Completion CompletionDriver::LexEnv CompletionDriver::Keywords
  );
    # Completion CompletionDriver::LexEnv
    # CompletionDriver::Keywords

  $repl->fancy_prompt(sub {
    my $self = shift;
    sprintf '%s:%03d%s> ',
      $self->can('current_package') ? $self->current_package : 'main',
      $self->lines_read,
      $self->can('line_depth') ? ':' . $self->line_depth : '';
  });

  $repl->fancy_continuation_prompt(sub {
    my $self = shift;
    my $pkg = $self->can('current_package') ? $self->current_package : 'main';
    $pkg =~ s/./ /g;
    sprintf '%s     %s* ',
      $pkg,
      $self->lines_read,
      $self->can('line_depth') ? $self->line_depth : '';
  });

  $repl->current_package('main');
  $repl->eval('use lib "lib"');
  # $repl->eval('use perl5i');


  async {
    # print "Startin REPL\n";
    while(1) {
      # print "Running once...\n";
      $repl->run_once_safely;
      SDLx::Controller::Coro::yield();
    }
  };

  return $repl;

}

1;

