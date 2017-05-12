# Copyright (c) 2007, Jeremy Nixon <jnixon@cpan.org>
# 
# All rights reserved.
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer. Redistributions
# in binary form must reproduce the above copyright notice, this list of
# conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the author nor the names of any contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package News::NNTP;

# $Rev: 9 $
# $Date: 2008-02-20 18:54:35 -0500 (Wed, 20 Feb 2008) $

require 5.008; # I honestly don't know how far back this will work.
use IO::Socket;
use Scalar::Util qw(reftype blessed);
use strict;

use Exporter qw(import);
our @EXPORT_OK = qw(cmd_has_multiline_input cmd_has_multiline_output
    active_group active_hiwater active_lowater active_count
    parse_date format_date);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

our $VERSION = '0.3';

my ($default_trace,$default_die,$default_resphook);

# Pass server, username, password as args;
# or server, port, username, password, trace, on_error, connect_timeout
# as members of a hashref.
sub new {
    my $obj = shift;
    my $class = ref($obj) || $obj;

    my $self = bless {}, $class;
    $self->config(@_);

    # Currently, this will throw an exception on failure, unless _err has
    # been changed. I'm not sure if that's the best way to handle errors
    # at connect-time.
    $self->_open_socket;
    my $response = $self->getresp; ## should do something if it's 5xx or 4xx?

    return $self;
}

# Create accessors.
foreach my $item (qw(server port username password modereader
        connect_timeout)) {
    no strict 'refs';
    *$item = sub {
        my $self = shift;
        $self->{$item} = shift if (@_);
        return $self->{$item};
    };
}

# Accessors for fields that need to be read-only from outside.
foreach my $item (qw(data lastcode lastmsg lastcodetype lastcmd lastresp
        curgroup curart curgroup_count curgroup_lowater curgroup_hiwater
        overview_fmt)) {
    no strict 'refs';
    *$item = sub { return shift->{$item} };
    *{'_'.$item} = sub {
        my $self = shift;
        $self->{$item} = shift if (@_);
        return $self->{$item};
    };
}

my @default_overview_fmt = qw(subject from date message-id references
    bytes lines xref:full);

sub config {
    my $self = shift;
    $self->_overview_fmt(\@default_overview_fmt);
    my $arg = shift;
    return $self unless (defined($arg));
    if (defined($default_trace)) {
        $self->trace($default_trace);
    }
    if (defined($default_die)) {
        $self->on_error($default_die);
    }
    if (defined($default_resphook)) {
        $self->resphook($default_resphook);
    }
    if (reftype($arg) eq 'HASH') {
        foreach my $field (qw(server port username password connect_timeout
                                on_error trace)) {
            if (exists $arg->{$field}) {
                $self->$field($arg->{$field});
            }
        }
    } else {
        $self->server($arg);
        $self->username(shift);
        $self->password(shift);
    }
    if (not $self->port) { $self->port(119) }
    return $self;
}

# If defined, this coderef will be called with single-line responses
# as they are received.
sub resphook {
    my $self = shift;
    if (defined $_[0] and not reftype($_[0]) eq 'CODE') {
        warn "non-coderef passed to resphook";
        return;
    }
    if (blessed($self)) {
        $self->{'resphook'} = shift if (@_);
        return $self->{'resphook'};
    }
    $default_resphook = shift if (@_);
    return $default_resphook;
}

# Protocol trace messages will be passed to this coderef.
sub trace {
    my $self = shift;
    if (defined $_[0] and not reftype($_[0]) eq 'CODE') {
        warn "non-coderef passed to trace";
        return;
    }
    if (blessed($self)) {
        $self->{'trace'} = shift if (@_);
        return $self->{'trace'};
    }
    $default_trace = shift if (@_);
    return $default_trace;
}

# Arrange to have trace messages sent to stderr.
# Just a convenience to call ->trace with an appropriate subroutine.
sub trace_stderr {
    my $self = shift;
    my $clear = shift;
    if ($clear) {
        $self->trace(undef);
    }
    $self->trace(sub { my $m = shift; print STDERR $m,"\n"; return 1 });
}

sub _trace {
    my ($self,$msg) = @_;
    unless (defined($self->{'trace'}) and reftype($self->{'trace'}) eq 'CODE') { return }
    $self->{'trace'}->($msg);
    return 1;
}

# This coderef will be called when there is a fatal error.
# The error message is passed.
# If the provided function does not die, the connection will still be
# dropped to prevent state problems.
sub on_error {
    my $self = shift;
    if (defined $_[0] and not reftype($_[0]) eq 'CODE') {
        warn "non-coderef passed to on_error";
        return;
    }
    if (blessed($self)) {
        $self->{'die'} = shift if (@_);
        return $self->{'die'};
    }
    $default_die = shift if (@_);
    return $default_die;
}

sub _err {
    my ($self,$msg) = @_;
    my $errno = $!; # ensure we preserve this for the caller.
    unless (defined($self->{'die'}) and reftype($self->{'die'}) eq 'CODE') {
        $self->drop;
        require Carp;
        $! = $errno;
        Carp::croak($msg);
    }
    $self->{'die'}->($msg);
    # If we didn't actually die, keeping the connection could present
    # a state problem, so drop it.
    $self->drop;
    $! = $errno;
    return 1;
}

sub sock { return shift->{'socket'} }

sub _open_socket {
    my $self = shift;
    if (not defined($self->server)) {
        require Carp;
        Carp::croak('no server specified for '. __PACKAGE__);
    }
    if (not defined($self->port)) { $self->port(119) }
    my $socket = IO::Socket::INET->new(PeerAddr => $self->server,
                                       PeerPort => $self->port,
                                       Timeout  => $self->connect_timeout);
    if (not defined $socket) {
        my $err = "$!";
        my $errstr = 'no socket';
        $errstr .= ": $err" if (defined($err) and length($err));
        $self->_err($errstr);
        return;
    }
    $socket->autoflush;
    $self->{'socket'} = $socket;
    return 1;
}

# 1 means command has multi-line response. 2 means it has multiline input.
# Other commands included for completeness.
my %commands = ( 'article'      => 1,
                 'head'         => 1,
                 'body'         => 1,
                 'stat'         => 0,
                 'authinfo'     => 0,
                 'help'         => 1,
                 'next'         => 0,
                 'last'         => 0,
                 'list'         => 1,
                 'over'         => 1,
                 'xover'        => 1,
                 'pat'          => 1,
                 'xpat'         => 1,
                 'hdr'          => 1,
                 'xhdr'         => 1,
                 'group'        => 0,
                 'newgroups'    => 1,
                 'listgroup'    => 1,
                 'newnews'      => 1,
                 'post'         => 2,
                 'mode'         => 0,
                 'xgtitle'      => 1,
                 'date'         => 0,
                 'xrover'       => 1,
                 'slave'        => 0,
                 'ihave'        => 2,
                 'check'        => 0,
                 'takethis'     => 2,
                 'capabilities' => 1,
                 'quit'         => 0,
               );

sub cmd_has_multiline_input {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $cmd = lc(shift);
    return $commands{$cmd} == 2 ? 1 : 0;
}

sub cmd_has_multiline_output {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $cmd = lc(shift);
    return $commands{$cmd} == 1 ? 1 : 0;
}

# Send an NNTP command and get the response.
sub command {
    my $self = shift;
    my $line = shift;
    $self->_lastcmd($line);
    return $self->_command($line,@_);
}

# Doesn't save 'lastcmd', so can be called recursively while saving
# the current command.
sub _command {
    my $self = shift;
    my $line = shift;

    my ($command,@arg) = split / /, $line;
    $command = lc($command);

    $self->sendcmd($line) or return;
    my $response = $self->getresp;

    my $codetype = $self->_lastcodetype;
    my $msg = $self->_lastmsg;
    my $lresp = $self->_lastresp;

    # If we got a "480 auth required" and we have a username and password,
    # try to authenticate, then repeat the command.
    if ($self->_lastcode == 480) {
        if (defined($self->username) and length($self->username) and
                defined($self->password) and length($self->password)) {
            $self->_command('authinfo user '. $self->username) or return;
            if ($self->_lastcodetype == 3) {
                $self->_command('authinfo pass '. $self->password) or return;
            }
            if ($self->_lastcodetype == 2) {
                # Successful. Repeat the command.
                $self->sendcmd($line) or return;;
                $response = $self->getresp;
                $codetype = $self->_lastcodetype;
            } else {
                # Failed. Restore state as if we never tried.
                $self->_lastcode(480);
                $self->_lastmsg($msg);
                $self->_lastcodetype($codetype);
                $self->_lastresp($lresp);
                if ($commands{$command} == 1) {
                    $self->_data(undef);
                }
                return 0;
            }
        } else {
            # We got a 480, but have no username or password.
            # Clear out any lingering data.
            if ($commands{$command} == 1) {
                $self->_data(undef);
            }
            return 0;
        }
    }

    # If this command has multiline output, get it.
    if (($codetype == 1 or $codetype == 2) and $commands{$command} == 1) {
        $self->{'pending_read'} = 1;
        $self->_data(undef);
        my $code = shift;
        if (defined($code)) {
            $self->getdata($code) or return;
        } else {
            $self->_data($self->getdata);
            return unless (defined($self->_data));
        }
    }

    # If this command requires a multline input, send it.
    if ($codetype == 3 and $commands{$command} == 2 and @_) {
        $self->{'pending_write'} = 1;
        $self->senddata(@_);
        $response = $self->getresp;
    }

    # Remember group state.
    if ($command eq 'group' and $codetype == 2) {
        $self->_curgroup($arg[0]);
        my ($count,$lo,$hi) = split / +/, $self->_lastmsg, 4;
        $self->_curgroup_count($count);
        $self->_curgroup_lowater($lo);
        $self->_curgroup_hiwater($hi);
        $self->_curart($lo);
    }

    # Remember article pointer.
    if (($command eq 'article' or $command eq 'head'
        or $command eq 'body' or $command eq 'stat')
        and $response =~ /^2/ and $arg[0] =~ /^\d+$/) {
        $self->_curart($arg[0]);
    }
    if ($command eq 'last' and $codetype == 2) {
        $self->_curart($self->_curart - 1);
    }
    if ($command eq 'next' and $codetype == 2) {
        $self->_curart($self->_curart + 1);
    }

    # Remember username and password.
    if ($command eq 'authinfo' and lc($arg[0]) eq 'user') {
        $self->username($arg[1]);
    }
    if ($command eq 'authinfo' and lc($arg[0]) eq 'pass') {
        if ($codetype == 2) {
            $self->password($arg[1]);
        } else {
            $self->username(undef);
            $self->password(undef);
        }
    }

    # Remember if we did MODE READER.
    if ($command eq 'mode' and lc($arg[0]) eq 'reader') {
        $self->modereader(1);
    }

    # Remember overview format.
    if ($command eq 'list' and lc($arg[0]) eq 'overview.fmt') {
        $self->_parse_overview_fmt;
    }

    if ($codetype == 1 or $codetype == 2 or $codetype == 3) {
        return 1;
    }
    return 0;
}

# Send a command down the wire.
# Recover a dropped connection if necessary.
sub sendcmd {
    my $self = shift;
    my $cmd = shift;

    unless (defined($self->sock) and $self->sock->connected) {
        return 1 if ($cmd eq 'quit');
        unless ($self->_reestablish) {
            return;
        }
    }

    $self->_lastcode(undef);
    $self->_lastmsg(undef);
    $self->_lastcodetype(undef);
    $self->_lastresp(undef);
    $self->_trace("-> $cmd");
    my $res;
    {
        local $SIG{'PIPE'} = 'IGNORE';
        $res = $self->sock->print("$cmd\015\012");
    }
    unless ($res) {
        return 1 if ($cmd eq 'quit');
        unless ($self->_reestablish) {
            return;
        }
        $self->_lastcode(undef);
        $self->_lastmsg(undef);
        $self->_lastcodetype(undef);
        $self->_lastresp(undef);
        $self->_trace("-> $cmd");
        {
            local $SIG{'PIPE'} = 'IGNORE';
            unless ($self->sock->print("$cmd\015\012")) {
                my $err = "$!";
                my $errstr = 'socket->print failed';
                if (defined($err) and length($err)) {
                    $errstr .= " ($err)";
                }
                $errstr .= ' after re-establishing connection, giving up.';
                $self->_err($errstr);
                return;
            }
        }
    }
    return 1;
}

# Re-establish a dropped connection. Restore all state.
sub _reestablish {
    my $self = shift;
    $self->{'eat_output'} = 1;
    $self->_open_socket or return;
    my $response = $self->getresp;

    unless ($self->_lastcodetype == 2) {
        $self->_err("failed to re-establish connection: $response");
        return;
    }

    # Restore state of the connection.
    if ($self->modereader) {
        unless ($self->_command('mode reader')) {
            $self->_err("mode reader failed while re-establishing connection: ". $self->lastresp);
            return;
        }
    }
    if (defined $self->username and defined $self->password) {
        unless ($self->_command('authinfo user '. $self->username) and
                $self->_command('authinfo pass '. $self->password)) {
            $self->_err("failed to re-authenticate while re-establishing connection: ". $self->lastresp);
            return;
        }
    }
    if ($self->_curgroup) {
        my $artnum = $self->_curart; # doing the "group" command will nuke this
        if ($self->_command('group '. $self->_curgroup)) {
            if ($artnum and $artnum != $self->_curgroup_lowater) {
                unless ($self->_command("stat $artnum")) {
                    $self->_err("failed to reset article pointer while ".
                            "re-establishing connection: ". $self->lastresp);
                    return;
                }
            }
        } else {
            $self->_err("failed to re-enter ". $self->_curgroup .
                    " while re-establishing connection: ". $self->lastresp);
            return;
        }
    }
    $self->{'eat_output'} = undef;
    return 1;
}

# Read the response line from a command.
# Sets lastcode, lastmsg, lastcodetype, lastresp.
# If the server has dropped the connection, this is where we are most likely
# to detect it; recover, re-send the previous command, and continue.
sub getresp {
    my $self = shift;
    my $resp = $self->sock->getline;
    if (not defined($resp)) {
        return '' if ($self->_lastcmd eq 'quit');
        # Got EOF. Most likely from a server idle timeout.
        unless ($self->_reestablish) {
            return;
        }
        # Need to repeat the last command on the new connection.
        # This will call back into here to get the response, so we're done.
        return $self->_command($self->_lastcmd);
    }
    $resp =~ tr/\015\012//d;
    my ($code,$msg) = split / /, $resp, 2;
    $self->_lastcode($code);
    $self->_lastmsg($msg);
    $self->_lastcodetype(substr($code,0,1));
    $self->_lastresp($resp);
    $self->_trace("<- $resp");
    if (defined($self->{'resphook'})) {
        $self->{'resphook'}->($resp);
    }
    return $resp;
}

# Read a multiline response body.
# If a coderef is passed, it is called once for each line.
# Otherwise, a listref of lines is returned.
sub getdata {
    my ($self,$code) = @_;
    if (defined($code) and reftype($code) ne 'CODE') {
        $code = undef;
    }
    $self->{'pending_read'} = 1;
    my @data;
    my $c = 0;
    while (1) {
        my $line = $self->sock->getline;
        if (not defined($line)) {
            # We got EOF in the middle of the data. This could result in
            # a partial article if we let it pass.
            $self->_err('connection dropped by server during data transfer.');
            return;
        }
        if ($line eq ".\015\012") {
            if (defined($code)) {
                eval { $code->(undef) };
                if ($@) {
                    $self->_err($@);
                }
            }
            last;
        }
        $line =~ s/^\.\././; # technically should remove any leading dot.
        $line =~ s/\015\012$/\012/;
        $c++;
        next if ($self->{'eat_output'});
        if (defined($code)) {
            eval { $code->($line) };
            if ($@) {
                $self->_err($@);
            }
        } else {
            push @data, $line;
        }
    }
    $self->{'pending_read'} = 0;
    return defined($code) ? 1 : \@data;
}

# Send multiline data.
# Each passed item can be a string, an iterator, a listref, or a scalar ref.
sub senddata {
    my $self = shift;
    return unless (@_);
    $self->{'pending_write'} = 1;
    $self->_senddata(@_);
    $self->finish_partial;
    return 1;
}

sub _senddata {
    my $self = shift;
    return unless (@_);
    foreach my $item (@_) {
        if (reftype($item) eq 'CODE') {
            while (defined(my $stuff = $item->())) {
                $self->senddata_partial($stuff);
            }
        } elsif (reftype($item) eq 'ARRAY') {
            # To handle each element in any allowed form, we recursively
            # call back into this function.
            foreach my $stuff (@$item) {
                $self->_senddata($stuff);
            }
        } elsif (reftype($item) eq 'SCALAR') {
            $self->senddata_partial($$item);
        } elsif (defined(reftype($item))) {
            $self->_err("senddata can't handle a ". reftype($item) .'ref.');
        } else {
            $self->senddata_partial($item);
        }        
    }
    return 1;
}

# Send partial multiline data. Use finish_partial() below to finish.
sub senddata_partial {
    my $self = shift;
    $self->{'pending_write'} = 1;
    my $data = shift;
    $data =~ s/([^\015])\012/$1\015\012/gs;
    $data =~ s/^\./../gm;
    $self->{'need_rn'} = (substr($data,-2,2) eq "\015\012") ? 0 : 1;
    $self->sock->print($data);
    return 1;
}

# Finish after calls to senddata_partial.
# senddata_partial set a flag for us if the data didn't end with CRLF.
sub finish_partial {
    my $self = shift;
    $self->sock->print("\015\012") if ($self->{'need_rn'});
    $self->sock->print(".\015\012");
    $self->{'pending_write'} = 0;
    $self->{'need_rn'} = 0;
    return 1;
}

sub _parse_overview_fmt {
    my $self = shift;
    my @list = @{ $self->data };
    local $/ = "\012";
    chomp @list;
    my @ovfmt;
    foreach my $item (@list) {
        $item =~ s/:$//;
        push @ovfmt, lc($item);
    }
    $self->_overview_fmt(\@ovfmt);
}

# Close the connection if it's opened, and clean up.
sub drop {
    my $self = shift;
    # Some rocket scientist made getpeername() throw a warning on a
    # socket that's not open, so we have to work around the idiocy
    # by suppressing warnings.
    local $^W = 0;
    if (defined($self->sock) and $self->sock->connected) {
        # If we're in the middle of a read, try to finish nicely.
        # If we're in the middle of a write, don't, to try to avoid posting
        # an incomplete article.
        if ($self->{'pending_read'}) {
            # We may want to set a timeout on this.
            $self->{'eat_output'} = 1;
            $self->getdata;
        }
        $self->sendcmd('quit');
        $self->sock->close;
    }
    # Remove any state flags.
    delete $self->{'eat_output'};
    delete $self->{'need_rn'};
    delete $self->{'pending_write'};
    delete $self->{'pending_read'};
    return 1;
}

sub DESTROY {
    my $self = shift;
    $self->drop;
}

# Convenience functions to parse active file lines.
sub active_group {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $line = shift;
    return (split /\s+/, $line)[0];
}

sub active_hiwater {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $line = shift;
    return (split /\s+/, $line)[1];
}

sub active_lowater {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $line = shift;
    return (split /\s+/, $line)[2];
}

sub active_count {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $line = shift;
    my $hi = (split /\s+/, $line)[1];
    my $lo = (split /\s+/, $line)[2];
    return $hi - $lo;
}

# Take an overview line and return a hashref of header/value pairs.
sub ov_hashref {
    my ($self,$line) = @_;
    local $/ = "\012";
    chomp($line);
    my @fields = split /\t/, $line;
    my %h;
    foreach my $fname ('NUMBER', @{ $self->_overview_fmt }) {
        my $field = shift @fields;
        if ($fname =~ /:full$/) {
            $fname =~ s/:full$//;
            if (defined $field) {
                $field =~ s/^\Q$fname\E: //i;
            }
        }
        $h{$fname} = $field;
    }
    return \%h;
}

sub _basetime {
    my ($y,$m,$d) = @_;
    use integer;
    $m = ($m + 9) % 12 + 1;
    $y = $y - ($m >= 11);
    my $days = $m*367/12 + $y*365 + $y/4 - $y/100 + $y/400;
    return 86400 * ($d + $days - 719499);
}

my %months = ( jan => 1, feb => 2, mar => 3, apr => 4, may => 5, jun => 6,
               jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12 );

# some asstunnel thought it would be a good idea to allow these,
# and damned if they don't actually get used a little.
my %stupidzones = ( gmt => '+0000', utc => '+0000', est => '-0500',
    edt => '-0400', cst => '-0600', cdt => '-0500', mst => '-0700',
    mdt => '-0600', pst => '-0800', pdt => '-0700' );

# Parse a Date header into a unixtime.
sub parse_date {
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my $date = shift;
    return unless $date =~ /^(?:(?:mon|tue|wed|thu|fri|sat|sun),\s+)?
                             (\d{1,2})\s+
                             (jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+
                             ((?:20)?\d\d)\s+
                             (\d\d):(\d\d)(?::(\d\d))?\s*
                             ([a-z]{3}|[+-]\d\d\d\d)?/xi;
    my ($day,$mon,$yr,$hr,$min,$sec,$tz) = ($1, (lc $2), $3, $4, $5, $6, $7);
    $sec = 0 unless (defined($sec));
    $yr = ($yr >= 2000) ? ($yr) : ($yr + 2000);
    $mon = $months{lc $mon};
    my $time = _basetime($yr,$mon,$day) + 3600*$hr + 60*$min + $sec;
    if ($tz =~ /^[a-z]{3}/i) {
        $tz = $stupidzones{lc $tz} || '+0000';
    }
    $tz = "+0000" if ($tz !~ /^[+-]/);
    $tz *= 1;
    $tz -= 40 * (int($tz / 100));
    $time -= 60*$tz;
    return $time;
}

# Return a formatted string suitable for a Date header.
sub format_date {
    my $ut = shift || time;
    require POSIX;
    my $dt = POSIX::strftime("%a, %d %b %Y %H:%M:%S %z",localtime($ut));
    return $dt;
}

# Run an NNTP client session on standard input and standard output,
# like "telnet news 119".
sub run_on_stdio {
    my $nntp;
    if (blessed($_[0]) and UNIVERSAL::isa($_[0],__PACKAGE__)) {
        $nntp = shift;
    } else {
        shift if UNIVERSAL::isa($_[0],__PACKAGE__);
        $nntp = __PACKAGE__->new(@_);
        unless ($nntp->lastcodetype == 2) {
            die "failed to connect.\n";
        }
        print $nntp->lastresp,"\n";
    }

    $nntp->resphook(sub { my $line = shift; print $line,"\n" });

    while (defined(my $cmd = <STDIN>)) {
        chomp $cmd;
        next unless $cmd;

        my $code;
        my $nc = lc((split / +/, $cmd, 2)[0]);
        if (cmd_has_multiline_input($nc)) {
            $code = sub { my $line = <STDIN>; chomp $line;
                        return undef if ($line eq '.'); return "$line\015\012" };
        } elsif (cmd_has_multiline_output($nc)) {
            $code = sub {
                my $line = shift;
                if (not defined $line) {
                    print ".\n";
                    return;
                }
                print $line;
            };
        }

        my $resp = $nntp->command($cmd,$code);

        last if ($nc eq 'quit');
    }
    $nntp->drop;
}


1;
