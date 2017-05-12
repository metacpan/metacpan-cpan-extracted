package Net::SSH::W32Perl::SSH2;

use strict;

use vars qw/@ISA/;

use Net::SSH::Perl::SSH2;
use IO::Select::Trap;
use IO::String;

use constant IS_WIN32 => ($^O =~ /MSWin32/i);

@ISA = qw/Net::SSH::Perl::SSH2/;

sub _session_channel {
    return shift->SUPER::_session_channel(@_) unless IS_WIN32;
    shift->channel_mgr->new_channel(
		rfd => new IO::String(), 
		wfd => new IO::String(), 
		efd => new IO::String()
    );
}

sub select_class { 'IO::Select::Trap' }
sub Close {
	my $ssh = shift;
	my $sock = ($ssh->sock || undef);
	if ($sock) {
		$ssh->debug("Closing socket");
		$sock->close();
	}
}

1;
