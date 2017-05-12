package Tapper::MCP::Info;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Info::VERSION = '5.0.6';
use 5.010;
use Moose;

extends 'Tapper::MCP';

has mcp_info => (is  => 'rw',
                 isa => 'HashRef',
                 default => sub {{}},
                );



sub set_max_reboot
{
        my ($self, $prc_number, $max_reboot) = @_;
        $self->mcp_info->{prc}->[$prc_number]->{max_reboot} = $max_reboot;
        return 0;

}



sub get_max_reboot
{
        my ($self, $prc_number) = @_;
        return $self->mcp_info->{prc}->[$prc_number]->{max_reboot} || 0;
}



sub add_prc
{
        my ($self, $prc_number, $timeout) = @_;
        return "prc_number not given to add_testprc" if not defined $prc_number;
        $self->mcp_info->{prc}->[$prc_number]->{timeouts}->{boot} =  $timeout;
        return 0;
}


sub add_testprogram
{

        my ($self, $prc_number, $program) = @_;
        my $grace_period = 60 + 60; # (time between SIGTERM and SIGKILL in PRC) + (grace period for sending the message)
        return "prc_number not given to add_testprogram" if not defined $prc_number;
        $program->{timeout} = $program->{timeout_testprogram} || $program->{timeout} || 0;
        delete $program->{precondition_type};
        push(@{$self->mcp_info->{prc}->[$prc_number]->{programs}}, $program);
        push(@{$self->mcp_info->{prc}->[$prc_number]->{timeouts}->{programs}}, $program->{timeout} + $grace_period);
        return 0;
}


# This function exists for convenience in timeout handling. The same could be
# achieved with get_testprogam and reading timeout values of every element
# returned. (This comment is not part of pod to prevent it from becoming part
# of the external documentation.)
sub get_testprogram_timeouts
{


        my ($self, $prc_number) = @_;
        return unless defined $self->mcp_info->{prc}->[$prc_number]->{timeouts}->{programs};
        return @{$self->mcp_info->{prc}->[$prc_number]->{timeouts}->{programs}};
}


sub get_testprograms
{

        my ($self, $prc_number) = @_;
        return unless defined $self->mcp_info->{prc}->[$prc_number]->{programs};
        return @{$self->mcp_info->{prc}->[$prc_number]->{programs}};
}




sub get_prc_count
{

        my ($self) = @_;
        return $#{$self->mcp_info->{prc}};
}





sub get_boot_timeout
{
        my ($self, $prc_number) = @_;
        return $self->mcp_info->{prc}->[$prc_number]->{timeouts}->{boot};
}


sub set_installer_timeout
{
        my ($self, $timeout) = @_;
        $self->mcp_info->{installer}{timeouts} = $timeout;
        return 0;
}


sub get_installer_timeout
{
        my ($self) = @_;
        return $self->mcp_info->{installer}{timeouts} || 0;
}


sub push_report_msg
{
        my ($self, $msg) = @_;
        push @{$self->mcp_info->{report}}, $msg;
        return 0;
}


sub get_report_array
{
        my ($self) = @_;
        return $self->mcp_info->{report} // [];
}


sub set_keep_alive_timeout
{
        my ($self, $timeout) = @_;
        $self->mcp_info->{keep_alive}{timeout_span} = $timeout;
        return $self->mcp_info->{keep_alive}{timeout_span};
}


sub keep_alive_timeout
{
        my ($self, $timeout) = @_;
        $self->mcp_info->{keep_alive}{timeout_span} = $timeout if defined $timeout;
        return $self->mcp_info->{keep_alive}{timeout_span};
}



sub test_type
{
        my ($self, $test_type) = @_;
        $self->mcp_info->{test_type} = $test_type if $test_type;
        return $self->mcp_info->{test_type} // '';
}


sub get_state_config
{
        my ($self) = @_;
        my $state = {
                     keep_alive => { timeout_span => $self->mcp_info->{keep_alive}{timeout_span}, timeout_date => undef},
                     current_state => 'started',
                     results => [],
                     install => { timeout_boot_span    => $self->get_installer_timeout || $self->cfg->{times}{boot_timeout},
                                  timeout_install_span => $self->cfg->{times}{installer_timeout},
                                  timeout_current_date => undef,
                                },
                     prcs    => [],
                    };
        if ($self->mcp_info->{prc}->[0]->{max_reboot}) {
                $state->{reboot}->{max_reboot} = $self->mcp_info->{prc}->[0]->{max_reboot};
                $state->{reboot}->{current} = 0;
       }
        foreach my $prc ( @{$self->mcp_info->{prc}}) {
                my $prc_state = {
                                 timeout_boot_span => $prc->{timeouts}->{boot} || $self->cfg->{times}{boot_timeout},
                                 timeout_current_date => undef,
                                 current_state => 'preload',
                                 results => [],
                                 timeout_testprograms_span => $prc->{timeouts}->{programs},
                                };
                push @{$state->{prcs}}, $prc_state;
        }

        # when we don't install, PRC 0 starts in state 'boot'
        if ($self->mcp_info->{skip_install}) {
                $state->{prcs}->[0]->{current_state} = 'boot';
        }
        return $state;
}


sub skip_install {
        my ($self, $skip_install) = @_;
        $self->mcp_info->{skip_install} = $skip_install if $skip_install;

        return $self->mcp_info->{skip_install};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Info

=head1 SYNOPSIS

 use Tapper::MCP::Info;

=head1 NAME

Tapper::MCP::Config - Object for cleaner API of handling mcp_info

=head1 FUNCTIONS

=head2 set_max_reboot

Set number of reboots to be used in a reboot test.

@param int - PRC number
@param int - number of reboots

@return success - 0

=head2 get_max_reboot

Get number of reboots to be used in a reboot test for a given PRC number.

@param int - PRC number

@return success - Number of reboots or 0 if not set

=head2 add_prc

Add a PRC with given boot timeout.

@param int - PRC number
@param int - boot timeout

@return success - 0
@return error   - string

=head2 add_testprogram

Add a testprogram for a given PRC. The given config has should have the
following elements:
program             - string - full path of the test program
timeout             - int    - timeout value for the test program
timeout_testprogram - int    - timeout value for the test program (deprecated)
parameters - array of string - parameter array as given to exec

@param int      - PRC number
@param hash ref - config options for program

@return success - 0
@return error   - string

=head2 get_testprogram_timeouts

Get all testprogram timeouts for a given PRC.

@param int          - PRC number

@returnlist success - array of ints

=head2 get_testprograms

Get all testprograms  for a given PRC.

@param int      - PRC number

@returnlist success - 0

=head2 get_prc_count

Get the number of PRCs in this object.

@return number of last PRC

=head2 get_boot_timeout

Returns the boot timeout for a given PRC

@param int - PRC number

@return success - Boot timeout, undef if not set

=head2 set_installer_timeout

Setter for installer timeout.

@param int - Timeout value

@return success - 0

=head2 get_installer_timeout

Getter for installer timeout.

@return success - Timeout value

=head2 push_report_msg

Add another message to the report we are going to send.

@param string - message

@return success - 0
@return error   - string

=head2 get_report_array

Get the report array generated by push_report_msg.

@return success - report array reference

=head2 set_keep_alive_timeout

Setter for timeout span for keep-alive handling. We need an explizit
setter because a single setter/getter function could not distinguish
between called as getter and called to set undef.

@param int - timeout span for keep-alive handling

@return new value of keep-alive timeout

=head2 keep_alive_timeout

Getter/Setter for timeout span for keep-alive handling. If you need to
set the timeout to an undefined value please use set_keep_alive_timeout.

@optparam int - timeout span for keep-alive handling

@return (new) value of keep-alive timeout

=head2 test_type

Setter and getter for test_type. This element is used to signal different
test_type variants like ssh or SimNow.

=head2 get_state_config

Returns a hash structure suitable for feeding it into

=head2 skip_install

Setter and getter for skip_install. This element is used to signal tests
without any installer at all.

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Tapper

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
