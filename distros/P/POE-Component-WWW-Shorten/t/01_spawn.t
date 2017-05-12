use Test::More tests => 3;
use POE;
use_ok('POE::Component::WWW::Shorten');

my $self = POE::Component::WWW::Shorten->spawn( options => { default => 1 } );

isa_ok ( $self, 'POE::Component::WWW::Shorten' );

POE::Session->create(
        inline_states => { _start => \&test_start, _stop => sub { return; }, },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass('blah');
  $self->shutdown();
  undef;
}
