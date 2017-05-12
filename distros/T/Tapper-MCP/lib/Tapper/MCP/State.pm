package Tapper::MCP::State;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::State::VERSION = '5.0.6';
use 5.010;
use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use Moose;
use List::Util qw/max min reduce/;
use Perl6::Junction qw/any/;

use Tapper::MCP::State::Details;
use Tapper::Model 'model';
use Class::Load ':all';

has state_details => (is => 'rw',
                      default => sub { {current_state => 'invalid'} }
                     );
# needed for state comparison
has all_states    => (is => 'ro',
                      default => sub {
                              return
                              {
                               invalid        => 1,
                               started        => 2,
                               reboot_install => 3,
                               installing     => 4,
                               reboot_test    => 5,
                               testing        => 6,
                               finished       => 7,
                              }});

has cfg => (is => 'rw',
           isa => 'HashRef',
           default => sub {{}},
           );
has callbacks => (is => 'ro',
                  lazy => 1,
                  default => sub { my $self  = shift;
                                   return if not $self->cfg->{mcp_callback_handler}{plugin};
                                   my $class = "Tapper::MCP::State::Plugin::";
                                   $class   .= $self->cfg->{mcp_callback_handler}{plugin};
                                   load_class($class);
                                   $class->new({cfg => $self->cfg})
                           },
                 );




has valid_states  => (is => 'ro',
                      default => sub { return  {'takeoff'           => ['started'],
                                                'start-install'     => ['reboot_install'],
                                                'end-install'       => ['installing'],
                                                'error-install'     => ['installing'],
                                                'warn-install'      => ['installing'],
                                                'start-guest'       => ['reboot_test', 'testing'],
                                                'error-guest'       => ['reboot_test', 'testing'],
                                                'start-testing'     => ['reboot_test', 'testing'],
                                                'end-testing'       => ['testing'],
                                                'error-testprogram' => ['testing'],
                                                'end-testprogram'   => ['testing'],
                                                'reboot'            => ['testing'],
                                                'keep-alive'        => ['ALL'],
                                               }
                               }
                     );


# A min implementation that handles undef as bigger than anything not smaller.
sub mindef
{
        no warnings 'uninitialized'; # written for handling undef so undef is certainly ok
        reduce { if (not (defined $a  and defined $b))
                 { max($a,$b) }
                 else { min($a,$b) }
         } @_;
}

around BUILDARGS => sub {
        my $orig  = shift;
        my $class = shift;


        my $args;
        if ( @_ == 1 and not $_[0] eq 'HASH' ) {
                return $class->$orig(testrun_id => $_[0]);
        } else {
                return $class->$orig(@_);
        }

};


sub BUILD
{
        my ($self, $args) = @_;

        $self->state_details(Tapper::MCP::State::Details->new({testrun_id => $args->{testrun_id}}));

}


sub is_msg_valid
{
        my ($self, $msg) = @_;

        return 1 if $msg->{state} eq 'quit';
        return 1 if $self->valid_states->{$msg->{state}} eq 'ALL';
        if (not $self->state_details->current_state eq any(@{$self->valid_states->{$msg->{state}}})){
                my $result =
                {
                 error => 1,
                 msg   => "Received $msg->{state} in state '".$self->state_details->current_state.
                 "'. This message is only allowed in states ".join(", ",@{$self->valid_states->{$msg->{state}}})
                };

                $self->state_details->results($result);
                if (defined $msg->{prc_number}) {
                        $self->state_details->prc_results($msg->{prc_number}, $result);
                        $self->state_details->prc_state($msg->{prc_number}, 'finished');

                        if ($self->state_details->is_all_prcs_finished()) {
                                $self->state_details->current_state('finished');
                        }
                } else {
                        $self->state_details->current_state('finished');
                }
                return (0);
        }
        return(1);
}


sub compare_given_state
{
        my ($self, $given_state) = @_;
        return $self->all_states->{$given_state} <=> $self->all_states->{$self->state_details->current_state};
}


sub get_current_timeout_span
{
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
        my ($self) = @_;
        my $new_timeout_date;
        my $keep_alive_timeout_date = $self->state_details->keep_alive_timeout_date;
        given ($self->state_details->current_state){
                when(['invalid', 'finished', 'started']){ $new_timeout_date = time + 60;}
                when(['reboot_install', 'installing']){$new_timeout_date = $self->state_details->installer_timeout_current_date }
                when('reboot_test'){ $new_timeout_date = $self->state_details->prc_timeout_current_date(0)}
                when('testing'){
                        $new_timeout_date = $self->state_details->prc_timeout_current_date(0);
                        for (my $prc_num = 1; $prc_num < $self->state_details->prc_count; $prc_num++) {
                                $new_timeout_date = mindef($new_timeout_date, $self->state_details->prc_timeout_current_date($prc_num));
                        }
                }
        }


        return (mindef($new_timeout_date, $keep_alive_timeout_date)  - time);
}


sub state_init
{
        my ($self, $data, $revive) = @_;
        if (not $revive) {
                $self->state_details->state_init($data);
        }
        return 0;
}



sub update_installer_timeout
{
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
        my ($self) = @_;
        my $now = time();
        my $installer_timeout_date = $self->state_details->installer_timeout_current_date;
        if ( $installer_timeout_date <= $now) {
                my $msg = 'timeout hit ';
                given ($self->state_details->current_state){
                        when ('started')        { $msg .= 'during preparation. Timeout was probably too low.'};
                        when ('reboot_install') { $msg .= 'while waiting for installer booting'};
                        when ('installing')     { $msg .= 'while waiting for installation'};
                }
                $self->state_details->results({error => 1, msg => $msg});
                $self->state_details->current_state('finished');
                return (1, undef);
        }
        return (0, $installer_timeout_date - $now);
}


sub update_prc_timeout
{
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
        my ($self, $prc_number) = @_;
        my $now = time();
        if ($self->state_details->prc_timeout_current_date($prc_number) < $now) {
                my $result = { error => 1,
                               msg   => "Timeout in PRC $prc_number "};
                given($self->state_details->prc_state($prc_number)){
                        when ('boot'){
                                $result->{msg} .= 'during boot';
                                $self->state_details->prc_state($prc_number, 'finished');
                                return;
                        }
                        when ('test'){
                                $result->{msg} .= 'while waiting for testprogram ';
                                $result->{msg} .= $self->state_details->prc_current_test_number($prc_number);
                        }
                        when ('lasttest'){
                                $result->{msg} .= 'while waiting for message "all tests finished"';
                                $self->state_details->prc_state($prc_number, 'finished')
                        }
                        default { return }
                }
                $self->state_details->results($result);
                $self->state_details->prc_results($prc_number, $result);
                return $self->state_details->prc_next_timeout($prc_number);
        }
        return $self->state_details->prc_timeout_current_date($prc_number) - $now;
}


sub update_test_timeout
{
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
        my ($self) = @_;
        my $now = time();

        if ($self->state_details->current_state ~~ 'reboot_test') {
                my $prc0_timeout_date = $self->state_details->prc_timeout_current_date(0);
                if ( $prc0_timeout_date <= $now) {
                        my $msg = 'Timeout while booting testmachine';
                        $self->state_details->prc_results(0, {error => 1, msg => $msg});
                        $self->state_details->results({error => 1, msg => $msg});
                        $self->state_details->current_state('finished');
                        return (1, undef);
                }
                else {
                        return (0, $prc0_timeout_date - $now);
                }
        }
        my $new_timeout_span;
        # we need the PRC number, thus not foreach
 PRC:
        for (my $prc_num = 0; $prc_num < $self->state_details->prc_count; $prc_num++) {
                given($self->state_details->prc_state($prc_num)){
                        when ( ['finished', 'preload'] ) { break}
                        when ('boot') {
                                if ($self->state_details->prc_timeout_current_date($prc_num) <= $now){
                                        my $msg = "Timeout while booting PRC$prc_num";
                                        $self->state_details->results({error => 1, msg => $msg});
                                        $self->state_details->prc_results($prc_num, {error => 1, msg => $msg});
                                        $self->state_details->prc_state($prc_num, 'finished');
                                }
                                else {
                                        $new_timeout_span = mindef($new_timeout_span,
                                                               $self->state_details->prc_timeout_current_date($prc_num) - time());
                                }
                        }
                        when ( ['test', 'lasttest'] ) {
                                $new_timeout_span = mindef($new_timeout_span, $self->update_prc_timeout($prc_num));
                        }

                }
        }

        if ($self->state_details->is_all_prcs_finished()) {
                $self->state_details->current_state('finished');
                return (1, undef);
        }

        return (0, $new_timeout_span);
}



sub update_keep_alive_timeout
{
        my ($self) = @_;
        return (0, undef) if not defined $self->state_details->keep_alive_timeout_span;
        my $timeout_cpan = $self->state_details->keep_alive_timeout_date - time();
        if ($timeout_cpan > 0) {
                return (0, $timeout_cpan);
        } else {
                if (not $self->callbacks) {
                        my $result = { error => 1,
                                       msg   => "No plugin defined in keep_alive. I deactivate keep-alive for this testrun."};
                        $self->state_details->results($result);
                        $self->state_details->set_keep_alive_timeout_span( undef );
                        return (0, undef);
                }
                return $self->callbacks->keep_alive($self->state_details);
        }
}



sub update_timeouts {
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
        my ($self) = @_;
        my ( $error, $timeout_span );

        given($self->state_details->current_state){
                when ( ['started', 'reboot_install', 'installing'] ) {
                        ( $error, $timeout_span) =  $self->update_installer_timeout() }
                when ( ['reboot_test','testing'] ) {
                        ( $error, $timeout_span) =  $self->update_test_timeout() }
                when ('finished')               {
                        return( 1, undef) } # no timeout handling when finished
                default {
                        my $msg = 'Invalid state ';
                        $msg   .= $self->state_details->current_state;
                        $msg   .= ' during update_timeouts';
                        $self->state_details->results({error => 1, msg => $msg});
                        return( 1, undef);
                }
        }

        my ( $alive_error, $alive_timeout_span ) = $self->update_keep_alive_timeout();
        return ($1, undef) if $error or $alive_error;
        return (0, mindef($alive_timeout_span, $timeout_span));

}


sub msg_takeoff
{
        my ($self, $msg) = @_;
        my $timeout_span = $self->state_details->takeoff($msg->{skip_install});
        return (0, $timeout_span);
}



sub msg_start_install
{
        my ($self, $msg) = @_;

        $self->state_details->current_state('installing');
        if ($self->cfg->{autoinstall}) {
                my $net    = Tapper::MCP::Net->new();
                $net->write_grub_file($self->cfg->{hostname},
                                      "timeout 2\n\ntitle Boot from first hard disc\n\tchainloader (hd0,1)+1\n");

        }
        return (0, $self->state_details->start_install);
}


sub msg_end_install
{
        my ($self, $msg) = @_;

        $self->state_details->current_state('reboot_test');
        $self->state_details->results({error => 0, msg => 'Installation finished'});

        $self->state_details->prc_state(0,  'boot');
        return (0, $self->state_details->prc_boot_start(0));
}


sub msg_error_install
{
        my ($self, $msg) = @_;

        $self->state_details->results({ error => 1,
                                        msg   => "Installation failed: ".$msg->{error},
                                      });
        $self->state_details->current_state('finished');

        return (1, undef);
}


sub msg_warn_install
{
        my ($self, $msg) = @_;

        $self->state_details->results({ error => 1,
                                        msg   => "Installation issue: ".$msg->{error},
                                      });
        return (1, undef);
}



sub msg_error_guest
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};

        $self->state_details->prc_state($nr, 'finished');

        my $result = { error => 1,
                       msg   => "Starting guest $nr failed: ".$msg->{error},
                     };
        $self->state_details->results($result);
        $self->state_details->prc_results( $nr, $result);

        if ($self->state_details->is_all_prcs_finished()) {
                $self->state_details->current_state('finished');
                return (1, undef);
        }

        return (0, $self->state_details->get_min_prc_timeout());
}



sub msg_start_guest
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};

        $self->state_details->prc_state($nr, 'boot');
        $self->state_details->prc_boot_start($nr);

        $self->state_details->current_state('testing');
        return (0,  $self->state_details->get_min_prc_timeout());
}



sub msg_start_testing
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};

        $self->state_details->prc_next_timeout($nr);
        $self->state_details->current_state('testing');
        $self->state_details->prc_state($nr, 'test');
        $self->state_details->prc_current_test_number($nr, 0);

        return (0,  $self->state_details->get_min_prc_timeout());
}



sub msg_end_testing
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};

        $self->state_details->prc_state($nr, 'finished');
        my $result = {
                      error => 0,
                      msg   => "Testing finished in PRC ".$msg->{prc_number},
                     };

        $self->state_details->prc_results($nr, $result);
        $self->state_details->results($result);

        if ($self->state_details->is_all_prcs_finished()) {
                $self->state_details->current_state('finished');
                return (1, undef);
        }

        return (0,  $self->state_details->get_min_prc_timeout());
}




sub msg_end_testprogram
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};

        my $current_test_number = $self->state_details->prc_current_test_number($nr);
        if ($msg->{testprogram} != $current_test_number) {
                my $result = {error => 1,
                              msg => "Invalid order of testprograms in PRC $nr. ".
                              "Expected $current_test_number, got $msg->{testprogram}"
                             };
                $self->state_details->prc_results($nr, $result);
                $self->state_details->results($result);
                $self->state_details->prc_current_test_number($nr, $msg->{testprogram});
        }


        $self->state_details->prc_next_timeout($nr);
        return (0, $self->state_details->get_min_prc_timeout());
}



sub msg_error_testprogram
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};

        my $current_test_number = $self->state_details->prc_current_test_number($nr);
        if ($msg->{testprogram} != $current_test_number) {
                my $result = {error => 1,
                              msg => "Invalid order of testprograms in PRC $nr. ".
                              "Expected $current_test_number, got $msg->{testprograms}"
                             };
                $self->state_details->prc_results($nr, $result);
                $self->state_details->results($result);
                $self->state_details->prc_current_test_number($nr, $msg->{testprogram});
        }

        my $result = {error => 1,
                      msg => $msg->{error},
                     };
        $self->state_details->prc_results($nr, $result);
        $self->state_details->results($result);

        $self->state_details->prc_next_timeout($nr);
        return (0, $self->state_details->get_min_prc_timeout());
}


sub msg_reboot
{
        my ($self, $msg) = @_;
        my $nr = $msg->{prc_number};


        my $result = {error => 0,
                      msg => "Host rebooted",
                     };
        $self->state_details->prc_results($nr, $result);
        $self->state_details->results($result);

        # reset testprogram counter
        $self->state_details->prc_current_test_number($nr, 0);

        $self->state_details->prc_next_timeout($nr);
        return (0, $self->state_details->get_min_prc_timeout());
}


sub msg_quit
{
        my ($self, $msg) = @_;

        my $result = {error => 1,
                      msg => "Testrun cancelled during state '".$self->state_details->current_state()."': ".($msg->{error} // "no reason provided"),
                     };
        $result->{comment} = $msg->{error} if $msg->{error};
        $self->state_details->results($result);
        $self->state_details->current_state('finished');
        $self->state_details->set_all_prcs_current_state('finished');

        return (1, undef);
}


sub msg_keep_alive
{
        my ($self) = @_;
        if (defined($self->state_details->keep_alive_timeout_span)) {
                $self->state_details->keep_alive_timeout_date( $self->state_details->keep_alive_timeout_span + time() );
        }
        return;
}



sub next_state
{
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
        my ($self, $msg) = @_;
        my ($error, $timeout_span);

        my $valid = $self->is_msg_valid($msg);
        return if not $valid;

        ########################################################################################################################
        #
        # FIXME! return values of all msg_* functions is ignored. This is ok, but why do they generate a return value then?
        #
        #######################################################################################################################
        given ($msg->{state}) {
                when ('quit')              { ($error, $timeout_span) = $self->msg_quit($msg)           };
                when ('takeoff')           { ($error, $timeout_span) = $self->msg_takeoff($msg)           };
                when ('start-install')     { ($error, $timeout_span) = $self->msg_start_install($msg)     };
                when ('end-install')       { ($error, $timeout_span) = $self->msg_end_install($msg)       };
                when ('error-install')     { ($error, $timeout_span) = $self->msg_error_install($msg)     };
                when ('warn-install')      { ($error, $timeout_span) = $self->msg_warn_install($msg)     };
                when ('start-guest')       { ($error, $timeout_span) = $self->msg_start_guest($msg)       };
                when ('error-guest')       { ($error, $timeout_span) = $self->msg_error_guest($msg)       };
                when ('start-testing')     { ($error, $timeout_span) = $self->msg_start_testing($msg)     };
                when ('end-testing')       { ($error, $timeout_span) = $self->msg_end_testing($msg)       };
                when ('error-testprogram') { ($error, $timeout_span) = $self->msg_error_testprogram($msg) };
                when ('end-testprogram')   { ($error, $timeout_span) = $self->msg_end_testprogram($msg)   };
                when ('reboot')            { ($error, $timeout_span) = $self->msg_reboot($msg)            };
                when ('keep-alive')        { ($error, $timeout_span) = $self->msg_keep_alive($msg)        };
                                # (TODO) add default
        }

        # every message resets the keep-alive timeout
        if (defined($self->state_details->keep_alive_timeout_span)) {
                $self->state_details->keep_alive_timeout_date( $self->state_details->keep_alive_timeout_span + time() );
        }

        return (1);
}



sub update_state
{
        my ($self, $msg_obj) = @_;
        my ($error, $timeout_span);
        my $now = time();

        my $guard;
        $guard = model('TestrunDB')->txn_scope_guard;
        $guard->commit() if ref model('TestrunDB')->storage() eq 'DBIx::Class::Storage::DBI::SQLite';

        if (ref $msg_obj eq 'Tapper::Schema::TestrunDB::Result::Message') {
                my $msg_hash = $msg_obj->message;
                $self->next_state($msg_hash);
                $msg_obj->delete;

        } elsif (ref $msg_obj eq 'DBIx::Class::ResultSet'){
                foreach my $msg_result ($msg_obj->all) {
                        my $msg_hash = $msg_result->message;
                        my ($success ) = $self->next_state($msg_hash);
                        $msg_result->delete;
                        last if not $success;
                }
        }
        ($error, $timeout_span) = $self->update_timeouts();
        $guard->commit if not ref model('TestrunDB')->storage() eq 'DBIx::Class::Storage::DBI::SQLite';
        return ($error, $timeout_span);
}


sub testrun_finished
{
        shift->state_details->current_state eq 'finished' ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::State

=head1 SYNOPSIS

 use Tapper::MCP::State;
 my $state_handler = Tapper::MCP::State->new($testrun_id);
 my $state = $state_handler->get_current_state();
 $self->compare_given_state($state);

=head1 NAME

Tapper::MCP::State - Keep state information for one specific test run

=head1 FUNCTIONS

=head2 is_msg_valid

Check whether received message is valid in current state.

@param hash ref - message

@return valid   - 1
@return invalid - 0

=head2 compare_given_state

Compare the current state to a given state name. Return -1 if the given
state is earlier then the current, 1 if the current state is earlier
then the given one and 0 if both are equal.

@param string - state name

@return current state is earlier -  1
@return given   state is earlier - -1
@return states are equal         -  0

=head2 get_current_timeout_span

Returns the time in seconds until the next timeout hits. When multiple
timeouts are currently running (during test with multiple PRCs) the
lowest of these timeouts is choosen. This value can be used for sleeping
in reads.

@return int - timeout span in seconds

=head2 state_init

Initialize the state or reload it from database.

@param hash ref - initial state data (ignored in revive mode)
@param bool     - are we in revive mode?

@return success - 0
@return error   - error string

=head2 update_installer_timeout

Update the timeout during installation.

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 update_prc_timeout

Check and update timeouts for one PRC.

@param  int     - PRC number

@return success - new timeout
@return error   - undef

=head2 update_test_timeout

Update timeouts during test phase.

@return success - (1, new timeout)
@return error   - (0, undef)

=head2 update_keep_alive_timeout

Check whether keep-alive timeout has ended and if so, act accordingly.

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 update_timeouts

Update the timeouts in $self->state_details structure.

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_takeoff

The reboot call was successfully executed, now update the state for
waiting for the first message.

@param hash ref - message

@return success - (0, timeout span for next state change)

=head2 msg_start_install

Handle message start-install

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_end_install

Handle message end-install

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_error_install

Handle message error-install

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_warn_install

Handle message error-install

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_error_guest

Handle message error-guest

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_start_guest

Handle message start-guest

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_start_testing

Handle message start-testing

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_end_testing

Handle message end-testing

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_end_testprogram

Handle message end-testprogram

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_error_testprogram

Handle message error-testprogram

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_reboot

Handle message reboot

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 msg_quit

Handle message quit

@param hash ref - message

@return (1, undef)

=head2 msg_keep_alive

Handle message keep-alive. This function does not return anything
because the caller ignores the return value anyway.

@param hash ref - message

=head2 next_state

Update state machine based on message.

@param Result class - message

@return success - 1
@return error   - undef

=head2

Update the state based on a message received from caller. The function
returns a timeout span value that is the lowest of all currently active
timeouts. The given message can be empty. In this case only timeouts are
checked and updated if needed.

@param hash ref - message

@return success - (0, timeout span for next state change)
@return error   - (1, undef)

=head2 testrun_finished

Tells caller whether the testrun is already finished or not.

@return TR     finished - 1
@return TR not finished - 0

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
