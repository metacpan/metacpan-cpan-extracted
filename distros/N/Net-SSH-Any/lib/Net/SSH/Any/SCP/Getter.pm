package Net::SSH::Any::SCP::Getter;

use strict;
use warnings;

use Carp;

use Net::SSH::Any::Constants qw(SSHA_SCP_ERROR SSHA_REMOTE_CMD_ERROR);
use Net::SSH::Any::Util qw($debug _debug _debugf _debug_hexdump
                           _first_defined _inc_numbered _gen_wanted
                           _scp_escape_name _scp_unescape_name);

require Net::SSH::Any::SCP::Base;
our @ISA = qw(Net::SSH::Any::SCP::Base);

sub _new {
    my ($class, $any, $opts, @srcs) = @_;
    my $g = $class->SUPER::_new($any, $opts);
    $g->{srcs} = \@srcs,
    $g->{$_} = delete $opts->{$_} for qw(recursive glob request_time);
    # TODO:
    # on_start = ...
    # on_end   = ... or enter/leave or whatever
    $g;
}

sub on_open {
    my $method = "on_open_$_[1]{type}";
    shift->$method(@_)
}

sub _open {
    my ($g, $type, $perm, $size, $name) = @_;
    my $action = $g->_push_action(type => $type,
                                  perm => $perm,
                                  size => $size,
                                  name => $name);

    if ( $g->on_open_before_wanted($action) and
         $g->_check_wanted($action)         and
         $g->on_open($action) )    { return 1 }

    $g->_pop_action;
    return;
}

sub on_close {
    my $g = shift;
    my $method = "on_close_$_[0]{type}";
    $g->$method(@_);
}

sub _close {
    my ($g, $action, $failed, $error) = @_;
    $g->_set_remote_error($action, $error) if $failed;
    $g->on_close($action, $failed);
}

sub _write {
    my $g = shift;
    $g->on_write($g->{actions}[-1], $_[0]);
}

sub _matime {
    my $g = shift;
    @{$g}{qw(mtime atime)} = @_;
}

sub _remote_error {
    my ($g, $path, $error) = @_;
    my $action =  { type         => 'remote_error',
                    path         => $path };
    $g->set_remote_error($action, $error);
    push @{$g->{log}}, $action if $g->{log};
}

sub _clean_actions {
    my $g = shift;
    while (my $action = $g->_pop_action(undef, 1)) {
        $g->_close($action, 2, "broken dpipe");
    }
}

sub on_open_before_wanted { 1 }
sub on_open_file          { 1 }
sub on_open_dir           { 1 }
sub on_close_file         { 1 }
sub on_close_dir          { 1 }
sub on_end_of_get         { 1 }

sub run {
    my ($g, $opts) = @_;
    my $any = $g->{any};

    $debug and $debug & 4096 and _debug "starting SCP Getter run...";

    my @cmd   = $any->_quote_args({quote_args => 1},
                                  # 'strace', '-o', '/tmp/out',
                                  $g->{scp_cmd},
                                  '-f',
                                  ($g->{request_time} ? '-p' : ()),
                                  ($g->{recursive}    ? '-r' : ()),
                                  ($g->{double_dash}  ? '--' : ()));
    my @files = $any->_quote_args({quote_args => 1,
                                   glob_quoting => $g->{glob}},
                                  @{$g->{srcs}});


    # $debug and $debug & 4096 and _debug "wait...";
    # sleep 5;
    # $debug and $debug & 4096 and _debug "welcome to the party!";
    # $DB::trace=1;
    my $dpipe = $any->dpipe({ %$opts, quote_args => 0 },
                            @cmd, @files);
    $any->error and return;

    local $SIG{PIPE} = 'IGNORE';
    my $buf;

    $dpipe->syswrite("\x00"); # tell remote side to start transfer
    while (1) {
        $g->_read_line($dpipe, $buf) or last;
        $debug and $debug & 4096 and _debug "cmd line: $buf";

        my $ok = 1;

        # C or D:
        if (my ($type, $perm, $size, $name) = $buf =~ /^([CD])([0-7]+) (\d+) (.*)$/) {
            _scp_unescape_name($name);
            $size = int $size;
            $perm = oct $perm;
            if ($type eq 'C') {
		if ($ok = $g->_open(file => $perm, $size, $name)) {
		    $debug and $debug & 4096 and _debug "transferring file of size $size";
		    $dpipe->syswrite("\x00");
		    $buf = '';
		    while ($size) {
			my $read = $dpipe->sysread($buf, ($size > 64000 ? 64000 : $size));
			unless ($read) {
			    $g->_or_set_error(SSHA_SCP_ERROR, "broken dpipe");
			    $g->_close($g->_pop_action('file'), 2, "broken dpipe");
			    $debug and $debug & 4096 and _debug "read failed: " . $any->error;
			    last;
			}
			$g->_write($buf) or last;
			$size -= $read;
		    }
		    my ($error_level, $error_msg) = $g->_read_response($dpipe);
		    $ok = $g->_close($g->_pop_action('file'), $error_level, $error_msg);
		    last if $error_level == 2;
		}
            }
            else { # $type eq 'D'
		unless ($g->{recursive}) {
		    $g->_or_set_error(SSHA_SCP_ERROR,
                                      "SCP protocol error, unexpected directory entry");
		    last;
		}
                $ok = $g->_open(dir => $perm, $size, $name);
            }

        }
        elsif (my ($mtime, $atime) = $buf =~ /^T(\d+)\s+\d+\s+(\d+)\s+\d+\s*$/) {
            $ok = $g->_matime($mtime, $atime);
        }
        elsif ($buf =~ /^E$/) {
            $ok = $g->_close($g->_pop_action('dir'));
        }
        elsif (my ($error_level, $path, $error_msg) = $buf =~ /^([\x01\x02])scp:(?:\s(.*))?:\s*(.*)$/) {
	    _scp_unescape_name($path) if defined $path;
	    $g->_remote_error($path, $error_msg);
	    next; # do not reply to errors!
	}
	else {
	    $g->_or_set_error(SSHA_SCP_ERROR, "SCP protocol error");
	    $debug and $debug & 4096 and _debug_hexdump "unknown command received", $buf;
	    last;
	}

	$dpipe->syswrite( $ok 
			 ? "\x00" 
			 : ( $g->{aborted} ? "\x02" : "\x01") . $g->last_error . "\x0A" )
	    or last;
    }

    $dpipe->close;

    $g->_clean_actions;

    if (not $g->on_end_of_get or $g->{error_count}) {
	$g->_or_set_error(SSHA_SCP_ERROR, "SCP transfer not completely successful");
    }

    if ($any->{error}) {
        if ($any->{error} == SSHA_REMOTE_CMD_ERROR) {
            $any->_set_error(SSHA_SCP_ERROR, $any->{error});
        }
        return;
    }
    return 1;
}

1;
