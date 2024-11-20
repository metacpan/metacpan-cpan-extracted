package Tapper::MCP::State::Details;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::State::Details::VERSION = '5.0.9';
use 5.010;
use strict;
use warnings;

use Moose;
use List::Util qw/max min/;
use Tapper::Model 'model';
use YAML qw/Dump Load/;

has state_details => (is => 'rw',
                      default => sub { {current_state => 'invalid'} },
                     );

has persist       => (is  => 'rw',);


sub BUILD
{
        my ($self, $args) = @_;
        my $testrun_id = $args->{testrun_id};
        my $result = model('TestrunDB')->resultset('State')->find_or_create({testrun_id => $testrun_id});
        $self->persist($result);
        $self->state_details($result->state);
}





sub db_update
{
        my ($self) = @_;
        $self->persist->state($self->state_details);
        $self->persist->update;
        return 0;
}



sub results
{
        my ($self, $result) = @_;
        if ($result) {
                push @{$self->state_details->{results}}, $result;
                $self->db_update();
        }
        return $self->state_details->{results} if $self->state_details->{results};
}


sub state_init
{
        my ($self, $data) = @_;
        $self->state_details($data);
        $self->state_details->{current_state} = 'started';
        $self->state_details->{results} = [];
        $self->state_details->{prcs} ||= [];
        $self->state_details->{keep_alive}{timeout_date} = $self->state_details->{keep_alive}{timeout_span} + time if defined $self->state_details->{keep_alive}{timeout_span};
        foreach my $this_prc (@{$self->state_details->{prcs}}) {
                $this_prc->{results} ||= [];
        }
        $self->db_update();
        return 0;
}




sub takeoff
{
        my ($self, $skip_install) = @_;
        my $timeout_current_date;
        if ($skip_install) {
                $self->current_state('reboot_test');
                my $prc = $self->state_details->{prcs}->[0];
                $timeout_current_date = $prc->{timeout_current_date} = $prc->{timeout_boot_span} + time();
        } else {
                $self->current_state('reboot_install');
                my $install = $self->state_details->{install};
                $timeout_current_date = $install->{timeout_current_date} = $install->{timeout_boot_span} + time();
        }

        $self->db_update();
        return ($timeout_current_date);
}


sub current_state
{
        my ($self, $state) = @_;
        if (defined $state) {
                $self->state_details->{current_state} = $state;
                $self->db_update;
        }
        return $self->state_details->{current_state} if $self->state_details->{current_state};
}


sub set_all_prcs_current_state
{
        my ($self, $state) = @_;
        if (defined $state) {
                for ( my $prc_num = 0; $prc_num < @{$self->state_details->{prcs}}; $prc_num++) {
                        $self->state_details->{prcs}[$prc_num]{current_state} = $state;
                }
                $self->db_update;
        }
}


sub keep_alive_timeout_date
{
        my ($self, $timeout_date) = @_;
        if ($self->state_details) {
            $self->state_details->{keep_alive}{timeout_date} = $timeout_date if defined $timeout_date;
            $self->state_details->{keep_alive}{timeout_date};
        }
}




sub set_keep_alive_timeout_span
{
        my ($self, $timeout_span) = @_;
        $self->state_details->{keep_alive}{timeout_date} = $timeout_span;
}


sub keep_alive_timeout_span
{
        my ($self) = @_;
        return $self->state_details->{keep_alive}{timeout_span};
}



sub installer_timeout_current_date
{
        my ($self, $timeout_date) = @_;
        if (defined $timeout_date) {
                $self->state_details->{install}{timeout_current_date} = $timeout_date;
                $self->db_update;
        }
        return $self->state_details->{install}{timeout_current_date};
}


sub start_install
{
        my ($self) = @_;
        $self->state_details->{install}->{timeout_current_date} =
          time + $self->state_details->{install}->{timeout_install_span};
        $self->db_update;
        return $self->state_details->{install}->{timeout_install_span};
}



sub prc_boot_start
{
        my ($self, $num) = @_;
        $self->state_details->{prcs}->[$num]->{timeout_current_date} =
          time + $self->state_details->{prcs}->[$num]->{timeout_boot_span};
        $self->db_update;

        return $self->state_details->{prcs}->[$num]->{timeout_boot_span};
}


sub prc_timeout_current_date
{
        my ($self, $num) = @_;
        return $self->state_details->{prcs}->[$num]->{timeout_current_date};
}



sub prc_results
{
        my ($self, $num, $msg) = @_;
        if (not defined $num) {
                my @results;
                for ( my $prc_num=0; $prc_num < @{$self->state_details->{prcs}}; $prc_num++) {
                        push @results, $self->state_details->{prcs}->[$prc_num]->{results};
                }
                return \@results;
        }
        if ($msg) {
                push @{$self->state_details->{prcs}->[$num]->{results}}, $msg;
                $self->db_update;
        }
        return $self->state_details->{prcs}->[$num]->{results};
}


sub prc_count
{
        return int @{shift->state_details->{prcs}};
}



sub prc_state
{
        my ($self, $num, $state) = @_;
        return {} if $num >= $self->prc_count;
        if (defined $state) {
                $self->state_details->{prcs}->[$num]{current_state} = $state;
                $self->db_update;
        }
        return $self->state_details->{prcs}->[$num]{current_state};
}



sub is_all_prcs_finished
{
        my ($self) = @_;
        # check whether this is the last PRC we are waiting for
        my $all_finished = 1;
        for ( my $prc_num=0; $prc_num < @{$self->state_details->{prcs}}; $prc_num++) {
                if ($self->state_details->{prcs}->[$prc_num]->{current_state} ne 'finished') {
                        $all_finished = 0;
                        last;
                }
        }
        return $all_finished;
}



sub prc_next_timeout
{
        my ($self, $num) = @_;
        my $prc = $self->state_details->{prcs}->[$num];
        my $default_timeout = 60 + 60; # (time between SIGTERM and SIGKILL in PRC) + (grace period for sending the message)
        my $next_timeout = $default_timeout;
        my $state = $prc->{current_state};
                if ($state eq 'preload') { $next_timeout = $prc->{timeout_boot_span}}
                if ($state eq 'boot')    {
                        if (ref $prc->{timeout_testprograms_span} eq 'ARRAY' and
                            @{$prc->{timeout_testprograms_span}}) {
                                $next_timeout = $prc->{timeout_testprograms_span}->[0];
                        } else {
                                $next_timeout = $default_timeout;
                        }
                }
                if ($state eq 'test') {
                        my $testprogram_number = $prc->{number_current_test};
                        ++$testprogram_number;
                        if (ref $prc->{timeout_testprograms_span} eq 'ARRAY' and
                            exists $prc->{timeout_testprograms_span}[$testprogram_number]){
                                $prc->{number_current_test} = $testprogram_number;
                                $next_timeout = $prc->{timeout_testprograms_span}[$testprogram_number];
                        } else {
                                $prc->{current_state} = 'lasttest';
                                $next_timeout = $default_timeout;
                        }
                }
                if ($state eq 'lasttest') {
                        my $result = { error => 1,
                                       msg   => "prc_next_timeout called in state testfin. This is a bug. Please report it!"};
                        $self->prc_results($num, $result);
                }
                if ($state eq 'finished') {
                        return;
                }

        $self->state_details->{prcs}->[$num]->{timeout_current_date} = time() + $next_timeout;
        $self->db_update;

        return $next_timeout;
}


sub prc_current_test_number
{
        my ($self, $num, $test_number) = @_;
        if (defined $test_number) {
                $self->state_details->{prcs}->[$num]{number_current_test} = $test_number;
                $self->db_update;
        }
        return $self->state_details->{prcs}->[$num]{number_current_test};
}


sub get_min_prc_timeout
{
        my ($self) = @_;
        my $now = time();
        my $timeout = $self->state_details->{prcs}->[0]->{timeout_current_date} - $now;

        for ( my $prc_num=1; $prc_num < @{$self->state_details->{prcs}}; $prc_num++) {
                next unless $self->state_details->{prcs}->[$prc_num]->{timeout_current_date};
                $timeout = min($timeout, $self->state_details->{prcs}->[$prc_num]->{timeout_current_date} - $now);
        }
        return $timeout;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::State::Details

=head1 SYNOPSIS

 use Tapper::MCP::State::Details;
 my $state_details = Tapper::MCP::State::Details->new();
 $state_details->prc_results(0, {success => 0, mg => 'No success'});

=head2 db_update

Update database entry.

@return success - 0
@return error   - error string

=head1 NAME

Tapper::MCP::State::Details - Encapsulate state_details attribute of MCP::State

=head1 FUNCTIONS

=head2 results

Getter and setter for results array for whole test. Setter adds given
parameter instead of substituting.

@param hash ref - containing success(bool) and msg(string)

=head2 state_init

Initialize the state or read it back from database.

@return success - 0
@return error   - error string

=head2 takeoff

The reboot call was successfully executed, now update the state for
waiting for the first message.

@return int - new timeout

=head2 current_state

Getter and setter for current state name.

@param  string - state name (optional)
@return string - state name

=head2 set_all_prcs_current_state

Set current_state of all PRCs to given state.

@param  string - state name

=head2 keep_alive_timeout_date

Getter and setter for keep_alive_timeout_date

@optparam int - new timeout_date for keep_alive

@return int - timeout date for keep_alive

=head2 set_keep_alive_timeout_span

Getter for keep_alive_timeout_date

@param int  - new timeout date for keep_alive

@return int - new timeout date for keep_alive

=head2 keep_alive_timeout_span

Getter and setter for keep_alive_timeout_span.
Note: This function can not set the timeout to undef.

@optparam int - new timeout_span

@return int - timeout date for keep_alive

=head2 installer_timeout_current_date

Getter and setter for installer timeout date.

@param  int    - new installer timeout date

@return string - installer timeout date

=head2 start_install

Update timeouts for "installation started".

@return int - new timeout span

=head2 prc_boot_start

Sets timeouts for given PRC to the ones associated with booting of this
PRC started.

@param  int - PRC number

@return int - boot timeout span

=head2 prc_timeout_current_span

Get the current timeout date for given PRC

@param  int - PRC number

@return int - timeout date

=head2 prc_results

Getter and setter for results array for of one PRC. Setter adds given
parameter instead of substituting. If no argument is given, all PRC
results are returned.

@param int      - PRC number (optional)
@param hash ref - containing success(bool) and msg(string) (optional)

=head2 prc_count

Return number of PRCs

@return int - number of PRCs

=head2 prc_state

Getter and setter for current state of given PRC.

@param  int    - PRC number
@param  string - state name (optional)

@return string - state name

=head2 is_all_prcs_finished

Check whether all PRCs have finished already.

@param     all PRCs finished - 1
@param not all PRCs finished - 0

=head2 prc_next_timeout

Set next PRC timeout as current and return it as timeout span.

@param int - PRC number

@return int - next timeout span

=head2 prc_current_test_number

Get or set the number of the testprogram currently running in given PRC.

@param int - PRC number
@param int - test number (optional)

@return test running    - test number starting from 0
@return no test running - undef

=head2 get_min_prc_timeout

Check all PRCs and return the minimum of their upcoming timeouts in
seconds.

@return timeout span for the next state change during testing

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
