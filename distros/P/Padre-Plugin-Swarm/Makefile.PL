use inc::Module::Install::DSL 0.91;

all_from      lib/Padre/Plugin/Swarm.pm
requires      Padre                 0.92
requires      Wx::Socket            0
requires      JSON              2.15
requires      AnyEvent		0
requires      Object::Event 	0
requires      IO::Socket::Multicast 1.11
requires      Graph
requires      Params::Util          1.00
requires      Class::XSAccessor     1.03
requires      Text::Patch           1.04
test_requires Test::More            0.42
test_requires Padre                 0.90
no_index      junkyard
install_share
