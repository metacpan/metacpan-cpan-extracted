package Net::SSH::Any::SCP::Putter;

use strict;
use warnings;

use Carp;
use Fcntl ();

use Net::SSH::Any::Constants qw(SSHA_SCP_ERROR SSHA_REMOTE_CMD_ERROR);
use Net::SSH::Any::Util qw($debug _debug _debugf _debug_dump _debug_hexdump
                           _first_defined _inc_numbered _gen_wanted
                           _scp_escape_name _scp_unescape_name);

require Net::SSH::Any::SCP::Base;
our @ISA = qw(Net::SSH::Any::SCP::Base);

sub _new {
    my ($class, $any, $opts, $target) = @_;
    my $p = $class->SUPER::_new($any, $opts);
    $p->{target} = $target;
    $p->{recursive} = delete $opts->{recursive};
    $p->{send_time} = delete $opts->{send_time};
    $p;
}

sub read_dir {}
sub _read_dir {
    my ($p, $action) = @_;
    $p->read_dir($action ? ($action, $action->{_handle}): ());
}

sub open_dir {}
sub open_file {}
sub _open {
    my ($p, $action) = @_;
    my $method = "open_$action->{type}";
    my $handle = $p->$method($action);
    if (defined $handle) {
        $action->{_handle} = $handle;
        return 1;
    }
    else {
        $p->set_local_error($action, "unable to open directory or file for $action->{path}");
        return
    }
}

sub close_dir {}
sub close_file {}
sub _close {
    my ($p, $action) = @_;
    my $method = "close_$action->{type}";
    $p->$method($action, delete $action->{_handle}) and return 1;
    $p->set_local_error($action, "unable to close directory or file $action->{path}");
    return
}

sub _read_file {
    my ($p, $action, $len) = @_;
    $debug and $debug & 4096 and _debug_dump "_read_file action", $action;
    $p->read_file($action, $action->{_handle}, $len);
}

sub _send_line_and_get_response {
    my ($p, $dpipe, $action, $line) = @_;
    $debug and $debug & 4096 and
        _debug_hexdump("writting line", $line);
    my ($fatal, $error) = ( $dpipe->print($line)
                            ? $p->_read_response($dpipe)
                            : (2, "broken dpipe"));
    if ($fatal) {
        $p->set_remote_error($action, $error);
        $fatal > 1 and $p->abort;
        return;
    }
    return 1;
}

sub _remote_open {
    my ($p, $dpipe, $action) = @_;
    my ($type, $perm, $size, $name) = @{$action}{qw(type perm size name)};
    my $cmd = ($type eq 'dir'  ? 'D' :
               $type eq 'file' ? 'C' :
               croak "bad action type $action->{type}");
    $perm = (defined $perm ? $perm : 0777) & 0777;
    $debug and $debug & 4096 and
        _debugf("remote_open type: %s, perm: 0%o, size: %d, name: %s", $type, $perm, $size, $name);
    _scp_escape_name($name);
    $p->_send_line_and_get_response($dpipe, $action, sprintf("%s%04o %d %s\x0A", $cmd, $perm, $size, $name));
}

sub _clean_actions {
    my $p = shift;
    while (my $action = $p->_pop_action(undef, 1)) {
        $p->_close($action, 2, "broken dpipe");
    }
}

sub do_stat { 1 }

sub _do_stat {
    my ($p, $action) = @_;
    unless ($p->do_stat($action)) {
        $p->set_local_error($action, "unable to retrieve file system properties for $action->{path}");
        return;
    }
    unless (defined $action->{type}) {
        $action->{type} = (Fcntl::S_ISDIR($action->{perm} || 0) ? 'dir' : 'file');
    }
    1;
}

sub _link_check {
    my ($p, $action) = @_;
    if (not $p->{follow_links} and Fcntl::S_ISLNK($action->{perm} || 0)) {
        $p->set_local_error($action, "not a regular file");
        return;
    }
    1;
}

sub _dir_check {
    my ($p, $action) = @_;
    if (not $p->{recursive} and $action->{type} eq 'dir') {
        $p->set_local_err
    }
}

sub on_end_of_put { 1 }

sub _send_time {
    my ($p, $dpipe, $action) = @_;
    return 1 unless $p->{send_time};
    my ($mtime, $atime) = @{$action}{'mtime', 'atime'};
    $p->_send_line_and_get_response($dpipe, $action,
                                    sprintf("T%d %d %d %d\x0A", $mtime, 0, $atime, 0));
}

sub _send_file {
    my ($p, $dpipe, $action) = @_;
    my $failed = 0;
    my $remaining = $action->{size} || 0;
    while ($remaining > 0) {
        my $data;
        my $len = ($remaining > 16384 ? 16386 : $remaining);
        if ($failed) {
            $data = "\0" x $len;
        }
        else {
            $data = $p->_read_file($action, $len);
            unless (defined $data and length $data) {
                $failed = 1;
                $debug and $debug & 4096 and _debug "no data from putter";
                redo;
            }
            if (length($data) > $remaining) {
                $debug and $debug & 4096 and _debug("too much data, discarding excess");
                substr($data, $remaining) = '';
                $failed = 1;
            }
        }
        $debug and $debug & 4096 and _debug_hexdump("sending data (failed: $failed)", $data);
        $dpipe->print($data) or last OUT;
        $remaining -= length $data;
    }
    $p->_close($action) or $failed = 1;
    $p->_send_line_and_get_response($dpipe, $action, ($failed ? "\x01failed\x0A" : "\x00"));
}

sub run {
    my ($p, $opts) = @_;
    my $any = $p->{any};
    my $dpipe = $any->dpipe({ %$opts, quote_args => 1 },
                            # 'strace', '-fo', '/tmp/scp.strace',
                            $p->{scp_cmd},
                            '-t',
                            ($p->{send_time}   ? '-p' : ()),
                            ($p->{recursive}   ? '-r' : ()),
                            ($p->{double_dash} ? '--' : ()),
                            $p->{target} );
    $any->error and return;

    local $SIG{PIPE} = 'IGNORE';

    my ($error_level, $error_msg) = $p->_read_response($dpipe);
    if ($error_level) {
	$any->_or_set_error(SSHA_SCP_ERROR, "remote SCP refused transfer", $error_msg);
	return;
    }

 OUT: while (not $p->{aborted}) {
        my $line;
        my $current_dir_action = $p->{actions}[-1];
        if (my $action = $p->_read_dir($current_dir_action)) {
            my $type = $action->{type};
            $action = $p->_push_action(%$action);

            $debug and $debug & 4096 and _debug_dump("next action", $action);

            # local_error actions are just pushed into the log
            unless (defined $type and $type eq 'local_error') {
                if ($p->_do_stat($action)) {
                    $type = $action->{type};
                    if ($type eq 'dir' and not $p->{recursive}) {
                        $debug and $debug & 4096 and _debug "discarding directory $action->{path}";
                        $p->set_local_error($action, "not a regular file");
                    }
                    else {
                        if ($p->_open($action)) {
                            if ($p->_send_time($dpipe, $action)) {
                                if ($p->_remote_open($dpipe, $action)) {
                                    if ($type eq 'dir') {
                                        # do not pop the action from the actions stack;
                                        next;
                                    }
                                    elsif ($type eq 'file') {
                                        $p->_send_file($dpipe, $action);
                                    }
                                }
                            }
                            else {
                                $p->_close($action);
                            }
                        }
                    }
                }
            }
            $p->_pop_action;
        }
        else { # close dir
            my $action = $p->_pop_action('dir', 1) or last;
            $p->_close($action);
            $p->_send_line_and_get_response($dpipe, $action, "E\x0A");
        }
    }

    $dpipe->close;

    $p->_clean_actions;

    $p->on_end_of_put or
        $p->_or_set_error(SSHA_SCP_ERROR, "SCP transfer not completely successful");

    not $any->error
}

1;
