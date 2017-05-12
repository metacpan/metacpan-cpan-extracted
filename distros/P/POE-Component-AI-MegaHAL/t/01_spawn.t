use Test::More tests => 8;
BEGIN { use_ok('POE::Component::AI::MegaHAL') };
use POE;

my $self;

my @questions = ('Hello World!', 'Howdy!', 'Badger! Badger! Badgers! Mushroom, mushroom', 'Buh-Bye?');

POE::Session->create(
	inline_states => {
		_start => \&test_start,
		_get_reply => \&get_reply,
		_got_reply => \&got_reply,
		_stop => sub { pass('stop'); },
	},
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub test_start {
  pass('Started Okay.');
  $self = POE::Component::AI::MegaHAL->spawn( autosave => 0, debug => 0, options => { trace => 0 } );
  isa_ok ( $self, 'POE::Component::AI::MegaHAL' );
  my $question = shift @questions;
  $poe_kernel->yield( _get_reply => $question );
  undef;
}

sub get_reply {
  $poe_kernel->post( $self->session_id => do_reply => { event => '_got_reply', text => $_[ARG0] } );
  return;
}

sub got_reply {
  diag($_[ARG0]->{reply});
  pass($_[ARG0]->{reply});
  my $question = shift @questions;
  if ( $question ) {
     $poe_kernel->yield( _get_reply => $question );
     return;
  }
  $poe_kernel->call( $self->session_id => 'shutdown' );
  undef;
}
