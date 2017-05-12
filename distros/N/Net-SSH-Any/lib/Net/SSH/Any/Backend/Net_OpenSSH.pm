package Net::SSH::Any::Backend::Net_OpenSSH;

use strict;
use warnings;

BEGIN { die "Net::OpenSSH does not work on Windows" if $^O =~ /Win32|Win64|Cygwin/i }

use Carp;
our @CARP_NOT = qw(Net::SSH::Any);

require Net::SSH::Any::Backend::_Cmd;
our @ISA = qw(Net::SSH::Any::Backend::_Cmd);

use Net::SSH::Any::Util;
use Net::SSH::Any::Constants qw(:error);
use Net::OpenSSH;
use Net::OpenSSH::Constants qw(:error);

sub _backend_api_version { 2 }

my @error_translation;
$error_translation[OSSH_MASTER_FAILED    ] = SSHA_CONNECTION_ERROR;
$error_translation[OSSH_SLAVE_FAILED     ] = SSHA_CHANNEL_ERROR;
$error_translation[OSSH_SLAVE_PIPE_FAILED] = SSHA_LOCAL_IO_ERROR;
$error_translation[OSSH_SLAVE_TIMEOUT    ] = SSHA_TIMEOUT_ERROR;
$error_translation[OSSH_SLAVE_CMD_FAILED ] = SSHA_REMOTE_CMD_ERROR;
$error_translation[OSSH_SLAVE_SFTP_FAILED] = SSHA_CHANNEL_ERROR;
$error_translation[OSSH_ENCODING_ERROR   ] = SSHA_ENCODING_ERROR;

sub __check_and_copy_error {
    my $any = shift;
    if (my $ssh = $any->{be_ssh}) {
        my $error = $ssh->error or return 1;
        $any->_set_error($error_translation[$error] // SSHA_CHANNEL_ERROR, $error);
    }
    else {
        $any->_set_error(SSHA_CONNECTION_ERROR, "Unable to create Net::OpenSSH object");
    }
    return;
}

sub _validate_backend_opts {
    my ($any, %be_opts) = @_;
    $any->SUPER::_validate_backend_opts(%be_opts) or return;

    my $instance = $be_opts{instance} // do {

        my $be_opts{ssh_cmd} //= delete $be_opts{local_ssh_cmd} // $any->_find_cmd($_, $be_opts{ssh_cmd}, 'OpenSSH');

        for (qw(rsync sshfs scp)) {
            $be_opts{"${_}_cmd"} //= delete $be_opts{"local_${_}_cmd"} //
                $any->_find_cmd({relaxed => 1}, $_, $be_opts{ssh_cmd}, 'OpenSSH');
        }
        my @master_opts = _array_or_scalar_to_list delete $be_opts{master_opts};
        my $strict_host_key_checking = delete $be_opts{strict_host_key_checking};
        push @master_opts, -o => 'StrictHostKeyChecking='.($strict_host_key_checking ? 'yes' : 'no');
        my $known_hosts_path = delete $be_opts{known_hosts_path};
        push @master_opts, -o => "UserKnownHostsFile=$known_hosts_path"
            if defined $known_hosts_path;
        push @master_opts, '-C' if delete $be_opts{compress};
        delete $be_opts{io_timeout};
        Net::OpenSSH->new(%be_opts, master_opts => \@master_opts, connect => 0);
    };
    $any->{be_opts} = \%be_opts;
    $any->{be_ssh} = $instance;
    __check_and_copy_error($any);
}

sub _make_cmd { shift->{be_ssh}->make_remote_command(@_) }

sub _check_connection {
    my $any = shift;
    $any->{be_ssh}->wait_for_master;
    __check_and_copy_error($any);
}

sub _connect { shift->_check_connection }



1;

__END__

=head1 NAME

Net::SSH::Any::Backend::Net_OpenSSH

=head1 DESCRIPTION

Custom options supported by this backend:

=over 4

=item instance => $instance

Instead of creating a new Net::OpenSSH reuses the one given.

Example:

  my $ssh = Net::OpenSSH->new($target, ...);

  my $assh = Net::SSH::Any->new($target,
                                backend => 'Net_OpenSSH',
                                backend_opts => {
                                    Net_OpenSSH => { instance => $ssh }
                                } );


=item master_opts => \@master_opts

...

=back

=cut
