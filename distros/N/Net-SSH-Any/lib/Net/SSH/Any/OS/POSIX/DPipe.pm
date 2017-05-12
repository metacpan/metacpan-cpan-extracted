package Net::SSH::Any::OS::POSIX::DPipe;

use strict;
use warnings;

use Net::SSH::Any::Constants qw(SSHA_CHANNEL_ERROR);
use Net::SSH::Any::Util qw($debug _debug _debug_hexdump);

require Net::SSH::Any::OS::_Base::DPipe;
our @ISA = qw(Net::SSH::Any::OS::_Base::DPipe);

sub _upgrade_fh_to_dpipe {
    my ($class, $dpipe, $any, $proc) = @_;
    $class->SUPER::_upgrade_fh_to_dpipe($dpipe, $any, $proc);
    $dpipe->autoflush(1);
    $dpipe;
}

sub _close_fhs {
    my $dpipe = shift;
    close $dpipe and return 1;
    $dpipe->_any->_set_error(SSHA_CHANNEL_ERROR, "Unable to close socket: $!");
    undef
}

sub syswrite {
    my $dpipe = shift;
    my (undef, $len, $offset) = @_;
    $len ||= "<undef>";
    $offset ||= "<undef>";
    $debug and $debug & 8192 and
	_debug_hexdump("$dpipe->syswrite(..., $len, $offset)", $_[0]);
    $dpipe->SUPER::syswrite(@_);
}

sub send_eof {
    my $dpipe = shift;
    shutdown $dpipe, 1;
}

1;
