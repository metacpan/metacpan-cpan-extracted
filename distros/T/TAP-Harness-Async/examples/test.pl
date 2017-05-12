#!perl 
use strict;
use warnings;
package MySourceHandler;
use parent qw(TAP::Parser::SourceHandler::Perl);
use TAP::Parser::IteratorFactory;
use TAP::Parser::Iterator::Process::Async;
use Carp qw(carp confess cluck);
use Data::Dumper;

TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

sub _create_iterator {
	my ( $class, $source, $command, $setup, $teardown ) = @_;

	my $loop = $source->config->{$class}->{loop};
	return TAP::Parser::Iterator::Process::Async->new({
		command  => $command,
		merge    => $source->merge,
		setup    => $setup,
		teardown => $teardown,
		loop	 => $loop,
	});
}


package main;
use TAP::Harness::Async;
use IO::Async::Loop;
use TAP::Parser::Multiplexer::Async;
use Data::Dumper;

my $loop = IO::Async::Loop->new;
# TAP::Harness
my $harness = TAP::Harness::Async->new({
	loop => $loop,
	verbosity => 1,
	multiplexer_class => qw(TAP::Parser::Multiplexer::Async),
	formatter_class => qw(TAP::Formatter::Event),
	sources =>  {
		MySourceHandler => { loop => $loop }
	}
});
$harness->callback(after_runtests => sub { $loop->later(sub { $loop->loop_stop }) });
my $agg = $harness->runtests(@ARGV);
$loop->loop_forever;
warn Dumper($agg);

