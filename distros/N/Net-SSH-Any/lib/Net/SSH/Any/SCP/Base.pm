package Net::SSH::Any::SCP::Base;

use strict;
use warnings;
use Carp;
our @CARP_NOT = qw(Net::SSH::Any);

use Net::SSH::Any::Constants qw(SSHA_SCP_ERROR);
use Net::SSH::Any::Util qw($debug _debug _debugf _debug_hexdump
                           _first_defined _inc_numbered _gen_wanted
                           _scp_escape_name _scp_unescape_name);

sub _new {
    my ($class, $any, $opts) = @_;
    my $self = { any         => $any,
                 log         => delete($opts->{log}),
                 wanted      => _gen_wanted(delete @{$opts}{qw(wanted not_wanted)}),
                 double_dash => _first_defined(delete($opts->{double_dash}), 1),
                 scp_cmd     => _first_defined(delete($opts->{remote_scp_cmd}), $any->{remote_cmd}{scp}, 'scp'),
                 actions     => [],
                 error_count => 0,
                 aborted     => 0,
                 last_error  => undef };
    bless $self, $class;
}

sub _or_set_error { shift->{any}->_or_set_error(@_) }

sub _read_line {
    my $self = shift;
    my $dpipe = shift;
    $debug and $debug & 4096 and _debug("$self->_read_line($dpipe)...");
    for ($_[0]) {
        $_ = '';
        $dpipe->sysread($_, 1) or return;
        if ($_ ne "\x00") {
            while (1) {
                unless ($dpipe->sysread($_, 1, length $_)) {
                    $self->_or_set_error(SSHA_SCP_ERROR, 'broken dpipe');
                    return;
                }
                last if /\x0A$/;
            }
        }
        $debug and $debug & 4096 and _debug_hexdump("line read", $_);
        return length $_;
    }
}

sub _read_response {
    my ($self, $dpipe) = @_;
    if ($self->_read_line($dpipe, my $buf)) {
	$buf eq "\x00" and return 0;
	$buf =~ /^([\x01\x02])(.*)$/ and return(wantarray ? (ord($1), $2) : ord($1));
	$debug and $debug & 4096 and _debug_hexdump "failed to read response", $buf;
        $self->_or_set_error(SSHA_SCP_ERROR, "SCP protocol error");
    }
    else {
        $self->_or_set_error(SSHA_SCP_ERROR, "broken dpipe");
    }
    wantarray ? (2, $self->{any}->error) : 2
}

sub _push_action {
    my ($self, %a) = @_;
    push @{$self->{actions}}, \%a;
    unless (defined $a{path}) {
        # We don't use File::Spec here because we didn't know what
        # the remote file system path separator may be.
        # TODO: allow to change how paths are joined from some setting.
        $a{path} = ( $a{name} =~ m|/|
                     ? $a{name}
                     : join('/', map $_->{name}, @{$self->{actions}}) );
    }
    defined $self->{$_} and $a{$_} = $self->{$_} for qw(mtime atime);
    push @{$self->{log}}, \%a if $self->{log};
    \%a;
}

sub _pop_action {
    my ($g, $type, $may_be_undef) = @_;
    my $action = pop @{$g->{actions}};
    unless ($action) {
        $may_be_undef and return;
        croak "internal error: _pop_action called but action stack is empty!";
    }
    if (defined $type) {
        $action->{type} eq $type or
            croak "internal error: $type action expected at top of the queue but $action->{type} found";
    }
    $action
}

sub _set_error {
    my ($self, $action, $origin, $error) = @_;
    unless (defined ($action->{error})) {
        $action->{error} = $error;
        $action->{error_origin} = $origin;
        $self->{error_count}++;
    }
    return
}

sub set_local_error {
    my ($self, $action, $error) = @_;
    $error = $! unless defined $error;
    $self->{last_error} = $error;
    $self->_set_error($action, 'local', $error);
}

sub last_error {
    my $self = shift;
    my $error = $self->{last_error};
    (defined $error ? $error : 'unknown error')
}

sub abort {
    my $self = shift;
    $self->_or_set_error(SSHA_SCP_ERROR, @_) if @_;
    $self->{aborted} = 1;
}

sub set_remote_error {
    my ($self, $action, $error) = @_;
    $self->_set_error($action, 'remote', $error);
}

sub _check_wanted {
    my ($self, $action) = @_;
    if (my $wanted = $self->{wanted}) {
	unless ($wanted->($action)) {
	    $debug and $debug & 4096 and
		_debugf("%s->set_not_wanted, %s", $self, $action->{path});
	    $action->{not_wanted} = 1;
	    return;
	}
    }
    1;
}

1;
