package Net::SSH::Any::OS::MSWin::DPipe;

use strict;
use warnings;

use Carp;
use Socket;
use Errno;
use Net::SSH::Any::Util qw($debug _debug _debug_hexdump _first_defined _array_or_scalar_to_list);
use Net::SSH::Any::Constants qw(SSHA_CHANNEL_ERROR);
use Time::HiRes qw(sleep);

require Net::SSH::Any::OS::_Base::DPipe;
our @ISA = qw(Net::SSH::Any::OS::_Base::DPipe);

sub _in { ${*{shift()}}{_ssha_os_in} }

for my $method (qw(syswrite print printf say autoflush)) {
    my $m = $method;
    no strict 'refs';
    *{$m} = sub { shift->_in->$m(@_) }
}

sub _upgrade_fh_to_dpipe {
    my ($class, $dpipe, $any, $proc, $in) = @_;
    $class->SUPER::_upgrade_fh_to_dpipe($dpipe, $any, $proc);
    bless $in, 'IO::Handle';
    ${*$dpipe}{_ssha_os_in} = $in;
    $in->autoflush(1);
    $dpipe;
}

sub _close_fhs {
    my $dpipe = shift;
    my $ok = $dpipe->send_eof;
    unless (close $dpipe) {
        $dpipe->_any->_set_error(SSHA_CHANNEL_ERROR, "unable to close dpipe reading side: $!");
        undef $ok;
    }
    return $ok;
}

sub send_eof {
    my $dpipe = shift;
    if (defined (my $in = delete ${*$dpipe}{_ssha_os_in})) {
        unless (close $in) {
            $dpipe->_any->_set_error(SSHA_CHANNEL_ERROR, "unable to close dpipe writing side: $!");
            return undef
        }
    }
    1
}

1;
