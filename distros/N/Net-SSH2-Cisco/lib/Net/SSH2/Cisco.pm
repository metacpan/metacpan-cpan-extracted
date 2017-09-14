package Net::SSH2::Cisco;

##################################################
# Michael Vincent
# www.VinsWorld.com
##################################################

# NOTE:  This module is basically a cut/paste of:
#   70% Net::Telnet
#   20% Net::Telnet::Cisco
#    5% Net::SSH2(::Channel)
#    5% original hack to make it all work together
#
# - I tried to create a child class of Net::SSH2 to no avail due to
#   the C-type inside-out object it returns and my lack of experience.
#
# - I tried to pass a Net::SSH2 connection to Net::Telnet(::Cisco) fhopen()
#   method, but it returned:
#
#     Not a GLOB reference at [...]/perl/vendor/lib/Net/Telnet.pm line 679.
#
# - I tried to use Net::Telnet in my @ISA with AUTOLOAD to leverage the
#   accessors and code already written, but I'm not creating a Net::Telnet
#   object and I couldn't get it to work.
#
# That left me the (?only?) option - to write this Franken-module "liberally
# borrowing" from much smarter, more talented programmers than I.

use strict;
use warnings;

our $VERSION = '0.04';
our @ISA;

use version;
use Net::SSH2 0.51;
use Socket qw(inet_ntoa AF_INET IPPROTO_TCP);
my $HAVE_IO_Socket_IP = 0;
eval "use IO::Socket::IP -register";
if(!$@) {
    $HAVE_IO_Socket_IP = 1;
    push @ISA, "IO::Socket::IP"
} else {
    require IO::Socket::INET;
    push @ISA, "IO::Socket::INET"
}

my $AF_INET6 = eval { Socket::AF_INET6() };
my $AF_UNSPEC = eval { Socket::AF_UNSPEC() };
my $AI_NUMERICHOST = eval { Socket::AI_NUMERICHOST() };
my $NI_NUMERICHOST = eval { Socket::NI_NUMERICHOST() };

$|++;

##################################################
# Start Public Module
##################################################

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    my ($fh_open, $host);
    my %params = (
        always_waitfor_prompt => 1,
        autopage              => 1,
        bin_mode              => 0,
        blocking              => 0,
        buf                   => "",
        cmd_prompt            => '/(?m:^(?:[\w.\/]+\:)?[\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/',
        cmd_rm_mode           => "auto",
        dumplog               => '',
        eofile                => 1,
        errormode             => "die",
        errormsg              => "",
        fh_open               => undef,
        host                  => "localhost",
        ignore_warnings       => 0,
        inputlog              => '',
        last_cmd              => '',
        last_prompt           => '',
        maxbufsize            => 1_048_576,
        more_prompt           => '/(?m:^\s*--More--)/',
        normalize_cmd         => 1,
        ofs                   => "",
        opened                => '',
        outputlog             => '',
        ors                   => "\n",
        peer_family           => 'ipv4',
        port                  => 22,
        rs                    => "\n",
        send_wakeup           => 0,
        time_out              => 10,
        timedout              => '',
        waitfor_clear         => 1,
        waitfor_pause         => 0.2,
        warnings              => '/(?mx:^% Unknown VPN
            |^%IP routing table VRF.* does not exist. Create first$
            |^%No CEF interface information
            |^%No matching route to delete$
            |^%Not all config may be removed and may reappear after reactivating/
        )/',
    );

    $params{_SSH_} = Net::SSH2->new() or return;
    $self = bless \%params, $class;

    my %args;
    if (@_ == 1) {
        ($host) = @_
    } else {
        %args = @_;
        for (keys(%args)) {
            if (/^-?always_waitfor_prompt$/i) {
                $self->always_waitfor_prompt($args{$_});
            } elsif (/^-?autopage$/i) {
                $self->autopage($args{$_})
            } elsif (/^-?binmode$/i) {
                $self->binmode($args{$_})
            } elsif (/^-?blocking$/i) {
                $self->blocking($args{$_})
            } elsif (/^-?cmd_remove_mode$/i) {
                $self->cmd_remove_mode($args{$_})
            } elsif (/^-?dump_log$/i) {
                $self->dump_log($args{$_})
                    or return;
            } elsif (/^-?errmode$/i) {
                $self->errmode($args{$_})
            } elsif (/^-?family$/i) {
                $self->family($args{$_})
            } elsif (/^-?fhopen$/i) {
                $fh_open = $args{$_}
            } elsif (/^-?host$/i) {
                $host = $args{$_}
            } elsif (/^-?ignore_warnings$/i) {
                $self->{ignore_warnings} = $args{$_}
            } elsif (/^-?input_log$/i) {
                 $self->input_log($args{$_})
                    or return;
            } elsif (/^-?input_record_separator$/i or /^-?rs$/i) {
                $self->input_record_separator($args{$_})
            } elsif (/^-?max_buffer_length$/i) {
                $self->max_buffer_length($args{$_})
            } elsif (/^-?more_prompt$/i) {
                $self->more_prompt($args{$_})
            } elsif (/^-?normalize_cmd$/i) {
                $self->normalize_cmd($args{$_})
            } elsif (/^-?output_field_separator$/i or /^-?ofs$/i) {
                $self->output_field_separator($args{$_})
            } elsif (/^-?output_log$/i) {
                $self->output_log($args{$_})
                    or return;
            } elsif (/^-?output_record_separator$/i or /^-?ors$/i) {
                $self->output_record_separator($args{$_})
            } elsif (/^-?port$/i) {
                $self->port($args{$_})
            } elsif (/^-?prompt$/i) {
                $self->prompt($args{$_})
            } elsif (/^-?send_wakeup$/i) {
                $self->send_wakeup($args{$_})
            } elsif (/^-?timeout$/i) {
                $self->timeout($args{$_})
            } elsif (/^-?waitfor_clear$/i) {
                $self->waitfor_clear($args{$_})
            } elsif (/^-?waitfor_pause$/i) {
                $self->waitfor_pause($args{$_})
            } elsif (/^-?warnings$/i) {
                $self->{warnings} = $args{$_}
            } else {
                # pass through
                #$params{$_} = $args{$_}
                &_croak($self, "bad named parameter \"$_\" given " .
                    "to " . ref($self) . "::new()");
            }
        }
    }

    # $self->open in the if statement so open() not called
    # if neither 'fh' nor 'host' are provided.
    if (defined $fh_open) {
        $self->fhopen($fh_open);
        $self->open or return
    } elsif (defined $host) {
        $self->host($host);
        $self->open or return
    }

    return $self
}

sub always_waitfor_prompt {
    my ($self, $arg) = @_;
    $self->{always_waitfor_prompt} = $arg if defined $arg;
    return $self->{always_waitfor_prompt}
}

sub autopage {
    my ($self, $arg) = @_;
    $self->{autopage} = $arg if defined $arg;
    return $self->{autopage}
}

sub binmode {
    my ($self, $arg) = @_;
    $self->{bin_mode} = $arg if defined $arg;
    return $self->{bin_mode}
}

sub blocking {
    my ($self, $arg) = @_;
    $self->{blocking} = $arg if defined $arg;
    return $self->{blocking}
}

sub close {
    my ($self) = @_;

    $self->{eofile} = 1;
    $self->{opened} = '';
    if (defined $self->{_SSH_CHAN_}) {
        $self->{_SSH_CHAN_}->close
    }
    if (defined $self->{_SSH_}) {
        $self->{_SSH_}->disconnect
    }
    delete $self->{_SSH_CHAN_};
    delete $self->{_SSH_};
    1
}

sub cmd {
    my ($self, @args) = @_;

    my $string  = '';
    my $chan    = $self->{_SSH_CHAN_};
    my $clear   = $self->{waitfor_clear};
    my $normal  = $self->{normalize_cmd};
    my $ors     = $self->{ors};
    my $pause   = $self->{waitfor_pause};
    my $prompt  = $self->{cmd_prompt};
    my $rm      = $self->{cmd_rm_mode};
    my $rs      = $self->{rs};
    my $timeout = $self->{time_out};

    if (!defined $chan) {
        &_croak($self, "no login " .
        "for " . ref($self) . "::cmd()");
    }

    my $ok = 1;
    $self->{timedout} = '';

    my $arg_errmode = &_extract_arg_errmode($self, \@args);
    local $self->{errormode} = $arg_errmode if $arg_errmode;

    my $output = [];
    my $output_ref;
    if (@_ == 2) {
        ($string) = ($_[1])
    } else {
        my %args = @args;
        for (keys(%args)) {
            if (/^-?string$/i) {
                $string = $args{$_}
            } elsif (/^-?cmd_remove_mode$/i) {
                $rm = _parse_cmd_remove_mode($self, $args{$_})
            } elsif (/^-?input_record_separator$/i or /^-?rs$/i) {
                $rs = $args{$_}
            } elsif (/^-?normalize_cmd$/i) {
                $normal = $args{$_}
            } elsif (/^-?output$/i) {
                $output_ref = $args{$_};
                if (defined($output_ref) and ref($output_ref) eq "ARRAY") {
                    $output = $output_ref;
                }
            } elsif (/^-?output_record_separator$/i or /^-?ors$/i) {
                $ors = $args{$_}
            } elsif (/^-?prompt$/i) {
                $prompt = &_parse_prompt($self, $args{$_})
                    or return;
            } elsif (/^-?timeout$/i) {
                $timeout = _parse_timeout($self, $args{$_})
            } elsif (/^-?waitfor_clear$/i) {
                $clear = $args{$_}
            } elsif (/^-?waitfor_pause$/i) {
                $pause = _parse_waitfor_pause($self, $args{$_})
                    or return
            } else {
                # pass through
                #$params{$_} = $args{$_}
                &_croak($self, "bad named parameter \"$_\" given " .
                    "to " . ref($self) . "::cmd()");
            }
        }
    }

    #prep
    local $self->{time_out} = $timeout;
    local $self->{waitfor_clear} = $clear;
    $self->errmsg("");
    chomp $string;
    $self->{last_cmd} = $string;

    my ($lines, $last_prompt);
    {
        local $self->{errormode} = "return";

        #send
        $self->put($string . $ors);

        #wait
        select(undef,undef,undef,$pause); # sleep

        #read
        ($lines, $last_prompt) = $self->waitfor(
                                     match => $prompt,
                                     normalize_cmd => $normal
                                 );
    }

    return $self->error("command timed-out") if $self->timed_out;
    return $self->error("no output") if not defined $lines;
    return $self->error($self->errmsg) if $self->errmsg ne "";

    ## Split lines into an array, keeping record separator at end of line.
    my $firstpos = 0;
    my $rs_len = length $rs;
    while ((my $lastpos = index($lines, $rs, $firstpos)) > -1) {
        push(@$output, substr($lines, $firstpos, $lastpos - $firstpos + $rs_len));
        $firstpos = $lastpos + $rs_len
    }
    if ($firstpos < length $lines) {
        push @$output, substr($lines, $firstpos)
    }

    # clean up
    if ($rm eq "auto") {
        if ((defined @$output[0]) and (@$output[0] =~ /^$string(?:\r)?(?:\n)?/)) {
            shift @$output
        }
    } else {
        while ($rm--) {
            shift @$output
        }
    }
    ## Ensure at least a null string when there's no command output - so
    ## "true" is returned in a list context.
    unless (@$output) {
        @$output = ("")
    }

    # Look for errors in output
    for ( my ($i, $lastline) = (0, '');
        $i <= $#{$output};
        $lastline = $output->[$i++] ) {

        # This may have to be a pattern match instead.
        if ( ( substr $output->[$i], 0, 1 ) eq '%' ) {
            if ( $output->[$i] =~ /'\^' marker/ ) { # Typo & bad arg errors
                chomp $lastline;
                $self->error( join "\n",
                    "Last command and router error: ",
                    ( $self->last_prompt . $string ),
                    $lastline,
                    $output->[$i],
                );
                splice @$output, $i - 1, 3;
            } else { # All other errors.
                chomp $output->[$i];
                $self->error( join "\n",
                    "Last command and router error: ",
                    ( $self->last_prompt . $string ),
                    $output->[$i],
                );
                splice @$output, $i, 2;
            }
            $ok = 0;
            last;
        }
    }

    ## Return command output via named arg, if requested.
    if (defined $output_ref) {
        if (ref($output_ref) eq "SCALAR") {
            $$output_ref = join "", @$output;
        } elsif (ref($output_ref) eq "HASH") {
            %$output_ref = @$output;
        }
    }

    wantarray ? @$output : $ok
}

sub cmd_remove_mode {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_cmd_remove_mode($self, $arg))) {
            $self->{cmd_rm_mode} = $r
        }
    }
    return $self->{cmd_rm_mode}
}

sub connect { &open }

sub disable {
    my $self = shift;
    $self->cmd('disable');
    if ($self->is_enabled) {
        return $self->error("Failed to exit enabled mode")
    }
    1
}

sub dump_log {
    my ($self, $name) = @_;

    my $fh = $self->{dumplog};

    if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        } elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        } elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
                or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        } else {
            return $self->error("bad Dump_log argument ",
                "\"$name\": not filename or open fh");
        }
        $self->{dumplog} = $fh;
    }
    $fh;
}

sub enable {
    my $self = shift;

    my ($en_username, $en_password, $en_passcode, $en_level) = ('','','','');
    my ($error, $lastline, $orig_errmode, $reset, %seen);
    my $chan    = $self->{_SSH_CHAN_};
    my $ors     = $self->{ors};
    my $timeout = $self->{time_out};

    if (!defined $chan) {
        &_croak($self, "no login " .
        "for " . ref($self) . "::enable()");
    }

    $self->{timedout} = '';

    if (@_ == 1) {  # just passwd given
        ($en_password) = @_
    } else {
        my %args = @_;
        foreach (keys %args) {
            if (/^-?name$|^-?login$|^-?user/i) {
                $en_username = $args{$_}
            } elsif (/^-?passw/i) {
                $en_password = $args{$_}
            } elsif (/^-?passc/i) {
                $en_passcode = $args{$_}
            } elsif (/^-?level$/i) {
                $en_level    = $args{$_}
            } elsif (/^-?timeout$/i) {
                $timeout     = $args{$_}
            } else {
                # pass through
                #$params{$_} = $args{$_}
                &_croak($self, "bad named parameter \"$_\" given " .
                    "to " . ref($self) . "::enable()");
            }
        }
    }

    local $self->{time_out} = $timeout;

    ## Create a subroutine to generate an error for user.
    # $error = sub {
        # my($errmsg) = @_;

        # if ($self->timed_out) {
            # return $self->error($errmsg);
        # } elsif ($self->eof) {
            # ($lastline = $self->lastline) =~ s/\n+//;
            # return $self->error($errmsg, ": ", $lastline);
        # } else {
            # return $self->error($errmsg);
        # }
    # };

    # Store the old prompt without the //s around it.
    my ($old_prompt) = _prep_regex($self->{cmd_prompt});

    # We need to expect either a Password prompt or a
    # typical prompt. If the user doesn't have enough
    # access to run the 'enable' command, the device
    # won't even query for a password, it will just
    # ignore the command and display another [boring] prompt.
    $self->print("enable " . $en_level);

    select(undef,undef,undef,$self->{waitfor_pause}); # sleep

    {
        my ($prematch, $match) = $self->waitfor(
            -match => '/[Ll]ogin[:\s]*$/',
            -match => '/[Uu]sername[:\s]*$/',
            -match => '/[Pp]assw(?:or)?d[:\s]*$/',
            -match => '/(?i:Passcode)[:\s]*$/',
            -match => "/$old_prompt/",
        ) or do {
            return $self->error("read eof waiting for enable login or password prompt")
                if $self->eof;
            return $self->error("timed-out waiting for enable login or password prompt");
        };

        if (not defined $match) {
            return $self->error("enable failed: access denied or bad name, passwd, etc")
        } elsif ($match =~ /sername|ogin/) {
            if (!defined $self->print($en_username)) {
                return $self->error("enable failed")
            }
            $self->{last_prompt} = $match;
            if ($seen{login}++) {
                return $self->error("enable failed: access denied or bad username")
            }
            redo
        } elsif ($match =~ /[Pp]assw/ ) {
            if (!defined $self->print($en_password)) {
                return $self->error("enable failed")
            }
            $self->{last_prompt} = $match;
            if ($seen{passwd}++) {
                return $self->error("enable failed: access denied or bad password")
            }
            redo
        } elsif ($match =~ /(?i:Passcode)/ ) {
            if (!defined $self->print($en_passcode)) {
                return $self->error("enable failed")
            }
            $self->{last_prompt} = $match;
            if ($seen{passcode}++) {
                return $self->error("enable failed: access denied or bad passcode")
            }
            redo
        } elsif ($match =~ /$old_prompt/) {
            ## Success! Exit the block.
            $self->{last_prompt} = $match;
            last
        } else {
            return $self->error("enable received unexpected prompt. Aborting.")
        }
    }

    if (($en_level eq '') or ($en_level =~ /^[1-9]/)) {
        # Prompts and levels over 1 give a #/(enable) prompt.
        if ($self->is_enabled) {
            return 1
        } else {
            return $self->error("Failed to enter enable mode")
        }
    } else {
        # Assume success
        return 1
    }
}

sub eof {
    my ($self) = @_;
    exists $self->{_SSH_CHAN_} ? ($self->{_SSH_CHAN_}->eof or $self->{eofile}) : $self->{eofile};
}

sub errmode {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_errmode($self, $arg))) {
            $self->{errormode} = $r
        }
    }
    return $self->{errormode}
}

sub errmsg {
    my ($self, @errmsgs) = @_;

    if (@_ >= 2) {
        $self->{errormsg} = join "", @errmsgs;
    }

    return $self->{errormsg}
}

sub error {
    my ($self, @errmsg) = @_;

    if ($self->ignore_warnings) {
        my $errmsg = join '', @errmsg;
        my $warnings_re = _prep_regex($self->warnings);
        return if $errmsg =~ /$warnings_re/;
    }

    my ($errmsg, $func, $mode, @args);
    local $_;

    if (@_ >= 2) {
        ## Put error message in the object.
        $errmsg = join "", @errmsg;
        $self->{errormsg} = $errmsg;
        ## Do the error action as described by error mode.
        $mode = $self->{errormode};
        if (ref($mode) eq "CODE") {
            &$mode($errmsg);
            return;
        } elsif (ref($mode) eq "ARRAY") {
            ($func, @args) = @$mode;
            &$func(@args);
            return;
        } elsif ($mode =~ /^return$/i) {
            return;
        } else {  # die
            if ($errmsg =~ /\n$/) {
                die $errmsg;
            } else {
                ## Die and append caller's line number to message.
                &_croak($self, $errmsg);
            }
        }
    } else {
        return $self->{errormsg} ne "";
    }
}

sub family {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_family($self, $arg))) {
            $self->{peer_family} = $r
        }
    }
    return $self->{peer_family}
}

sub fhopen{
    my ($self, $arg) = @_;
    $self->{fh_open} = $arg if defined $arg;
    return $self->{fh_open}
}

sub host {
    my ($self, $arg) = @_;
    $self->{host} = $arg if defined $arg;
    return $self->{host}
}

sub ignore_warnings {
    my ($self, $arg) = @_;
    $self->{ignore_warnings} = $arg if defined $arg;
    return $self->{ignore_warnings}
}

sub input_log {
    my ($self, $name) = @_;

    my $fh = $self->{inputlog};

    if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        } elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        } elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
                or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        } else {
            return $self->error("bad Input_log argument ",
                "\"$name\": not filename or open fh");
        }
        $self->{inputlog} = $fh;
    }
    $fh;
}

sub input_record_separator {
    my ($self, $arg) = @_;
    $self->{rs} = $arg if (defined $arg and length $arg);
    return $self->{rs}
}

sub ios_break {
    my ($self, $arg) = @_;

    my $chan = $self->{_SSH_CHAN_};
    my $ret;
    if (defined $arg) {
        $ret = $self->put("\c^$arg")
    } else {
        $ret = $self->put("\c^")
    }

    return $ret;
}

sub is_enabled { $_[0]->last_prompt =~ /\#|enable|config/ ? 1 : undef }

sub last_cmd {
    my $self = shift;
    exists $self->{last_cmd} ? $self->{last_cmd} : undef
}

sub last_prompt {
    my $self = shift;
    exists $self->{last_prompt} ? $self->{last_prompt} : undef
}

sub login {
    my ($self, @args) = @_;

    if (!$self->{opened}) {
        &_croak($self, "no connect " .
        "for " . ref($self) . "::login()");
    }

    my $block   = $self->{blocking};
    my $prompt  = $self->{cmd_prompt};
    my $timeout = $self->{time_out};
    my $ssh     = $self->{_SSH_};
    my $sent_wakeup = 0;
    my ($user, $pass);

    $self->{timedout} = '';

    my $arg_errmode = &_extract_arg_errmode($self, \@args);
    local $self->{errormode} = $arg_errmode if $arg_errmode;

    if (@_ == 3) { # just username and passwd given
        ($user, $pass) = (@_[1,2])
    } else {
        my %args = @args;
        for (keys(%args)) {
            if (/^-?(?:user)?name$/i) {
                $user = $args{$_}
            } elsif (/^-?passw(?:ord)?$/i) {
                $pass = $args{$_}
            } elsif (/^-?prompt$/i) {
                $prompt = _parse_prompt($self, $args{$_})
                    or return
            } elsif (/^-?timeout$/i) {
                $timeout = _parse_timeout($self, $args{$_})
            } else {
                # pass through
                #$params{$_} = $args{$_}
                &_croak($self, "bad named parameter \"$_\" given ",
                    "to " . ref($self) . "::login()");
            }
        }
    }

    if (!defined $user) {
        &_croak($self,"username argument not given to " . ref($self) . "::login()")
    }
    if (!defined $pass) {
        &_croak($self,"password argument not given to " . ref($self) . "::login()")
    }

    local $self->{time_out} = $timeout;

    # This is where we'd do 'connect' send_wakeup if Net::SSH2 supported
    if ($self->{send_wakeup} eq 'connect') {
        $sent_wakeup = 1;

        # my $old_sep = $self->output_record_separator;
        # $self->output_record_separator("\n");
        # $self->print('');
        # $self->output_record_separator($old_sep);
    }

    AUTH:
    if ($ssh->auth_password($user, $pass)) {
        my $chan = $ssh->channel();
        $chan->blocking($block); # 0 Needed on Windows
        $chan->shell();
        $self->{_SSH_CHAN_} = $chan;

        # flush buffer, read off first prompt
        if ($sent_wakeup == 0 && $self->{send_wakeup} eq 'noflush') {

            # do nothing
            $sent_wakeup = 1;
        } else {
            $sent_wakeup = 1;
            $self->waitfor($self->{cmd_prompt});
        }
    } else {
        # This is where we'd do 'timeout' send_wakeup if Net::SSH2 supported
        if ($sent_wakeup == 0 && $self->{send_wakeup} eq 'timeout') {
            $sent_wakeup = 1;

            # my $old_sep = $self->output_record_separator;
            # $self->output_record_separator("\n");
            # $self->print('');
            # $self->output_record_separator($old_sep);

            # goto AUTH;
        }
        my ($errcode, $errname, $errstr) = $ssh->error;
        return $self->error("Net::SSH2 error $errcode:$errname [$errstr]\nauthentication failed for user - `$user'")
    }
    1
}

sub max_buffer_length {
    my ($self, $arg) = @_;

    my $minbufsize = 512;

    if (defined $arg) {
        if ($arg =~ /^\d+$/) {
            $self->{maxbufsize} = $arg
        } else {
            &_carp($self, "ignoring bad Max_buffer_length " .
                "argument \"$arg\": it's not a positive integer");
        }
    }

    ## Adjust up values that are too small.
    if ($self->{maxbufsize} < $minbufsize) {
        $self->{maxbufsize} = $minbufsize;
    }

    return $self->{maxbufsize}
}

sub more_prompt {
    my ($self, $arg) = @_;

    if (defined $arg) {
        $self->_match_check($arg);
        $self->{more_prompt} = $arg;
    }
    return $self->{more_prompt};
}

sub normalize_cmd {
    my ($self, $arg) = @_;
    $self->{normalize_cmd} = $arg if defined $arg;
    return $self->{normalize_cmd}
}

sub ofs { &output_field_separator; }

sub open {
    my ($self, @args) = @_;

    return 1 if $self->{opened};

    my $ssh     = $self->{_SSH_};
    my $family  = $self->{peer_family};
    my $fh      = $self->{fh_open};
    my $host    = $self->{host};
    my $port    = $self->{port};
    my $timeout = $self->{time_out};

    $self->{timedout} = '';

    my $arg_errmode = &_extract_arg_errmode($self, \@args);
    local $self->{errormode} = $arg_errmode if $arg_errmode;

    if (@_ == 2) {
        ($host) = $_[1]
    } else {
        my %args = @args;
        for (keys(%args)) {
            if (/^-?fhopen$/i) {
                $fh = $args{$_}
            } elsif (/^-?host$/i) {
                $host = $args{$_}
            } elsif (/^-?family$/i) {
                $family = _parse_family($self, $args{$_})
            } elsif (/^-?port$/i) {
                $port = _parse_port($self, $args{$_})
            } elsif (/^-?timeout$/i) {
                $timeout = _parse_timeout($self, $args{$_})
            } else {
                # pass through
                #$params{$_} = $args{$_}
                &_croak($self, "bad named parameter \"$_\" given ",
                    "to " . ref($self) . "::connect()");
            }
        }
    }

    local $self->{time_out} = $timeout;

    my $r;
    # IO::Socket object provided
    if (defined $fh) {
        $r = $ssh->connect($fh)
    # host provided
    } else {
        # resolve
        if (defined(my $res = _resolv($self, $host, _parse_family_to_num($self, $family)))) {
            $host = $res->{addr};
            $port = $res->{port} || $port
        } else {
            return $self->error($self->errmsg)
        }
        # connect if IPv4
        if ($family eq 'ipv4') {
            $ssh->timeout($timeout*1000); # timeout is in millisecs
            $r = $ssh->connect($host, $port)

        # if IPv6, Net::SSH2 doesn't yet support,
        # so need to create our own IO::Socket::IP
        } else {
            my $socket = IO::Socket::IP->new(
                PeerHost => $host,
                PeerPort => $port,
                Timeout  => $timeout,
                Family   => _parse_family_to_num($self, $family)
            );
            if (!$socket) {
                return $self->error("unable to connect to [$family] host - `$host:$port'")
            }
            $r = $ssh->connect($socket);
        }
    }
    if (! $r) {
        my ($errcode, $errname, $errstr) = $ssh->error;
        return $self->error("Net::SSH2 error - $errcode:$errname = $errstr\nunable to connect to host - `$host:$port'")
    }

    $self->{buf} = "";
    $self->{eofile} = '';
    $self->{errormsg} = "";
    $self->{opened} = 1;
    $self->{timedout} = '';
    1
}

sub ors { &output_record_separator }

sub output_field_separator {
    my ($self, $arg) = @_;
    $self->{ofs} = $arg if (defined $arg and length $arg);
    return $self->{ofs}
}

sub output_log {
    my ($self, $name) = @_;

    my $fh = $self->{outputlog};

    if (@_ >= 2) {
        if (!defined($name) or $name eq "") {  # input arg is ""
            ## Turn off logging.
            $fh = "";
        } elsif (&_is_open_fh($name)) {  # input arg is an open fh
            ## Use the open fh for logging.
            $fh = $name;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        } elsif (!ref $name) {  # input arg is filename
            ## Open the file for logging.
            $fh = &_fname_to_handle($self, $name)
                or return;
            select((select($fh), $|=1)[$[]);  # don't buffer writes
        } else {
            return $self->error("bad Output_log argument ",
                "\"$name\": not filename or open fh");
        }
        $self->{outputlog} = $fh;
    }
    $fh;
}

sub output_record_separator {
    my ($self, $arg) = @_;
    $self->{ors} = $arg if (defined $arg and length $arg);
    return $self->{ors}
}

sub port {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_port($self, $arg))) {
            $self->{port} = $r
        }
    }
    return $self->{port}
}

sub print {
    my ($self) = shift;

    $self->{timedout} = '';

    return $self->error("write error: filehandle isn't open")
        unless $self->{opened};

    ## Add field and record separators.
    my $buf = join($self->{"ofs"}, @_) . $self->{"ors"};

    if ($self->{outputlog}) {
        &_log_print($self->{outputlog}, $buf);
    }

    ## Convert native newlines to CR LF.
#    if (!$self->{bin_mode}) {
#        $buf =~ s(\n)(\015\012)g;
#    }

    &_put($self, \$buf, "print");
}

sub prompt {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_prompt($self, $arg))) {
            $self->{cmd_prompt} = $r
        }
    }
    return $self->{cmd_prompt}
}

sub put {
    my ($self, @args) = @_;

    local $_;

    my $binmode = $self->{bin_mode};
    my $timeout = $self->{time_out};
    $self->{timedout} = '';

    my $arg_errmode = &_extract_arg_errmode($self, \@args);
    local $self->{errormode} = $arg_errmode if $arg_errmode;

    my $buf;
    if (@_ == 2) {
        $buf = $_[1];
    } elsif (@_ > 2) {
        my (undef, %args) = @_;
        foreach (keys %args) {
            if (/^-?binmode$/i) {
                $binmode = $args{$_};
            } elsif (/^-?string$/i) {
                $buf = $args{$_};
            } elsif (/^-?timeout$/i) {
                $timeout = &_parse_timeout($self, $args{$_});
            } else {
                &_croak($self, "bad named parameter \"$_\" given ",
                    "to " . ref($self) . "::put()");
            }
        }
    }

    ## If any args given, override corresponding instance data.
    local $self->{bin_mode} = $binmode;
    local $self->{time_out} = $timeout;

    ## Check for errors.
    return $self->error("write error: filehandle isn't open")
        unless $self->{opened};

    if ($self->{outputlog}) {
        &_log_print($self->{outputlog}, $buf);
    }

    ## Convert native newlines to CR LF.
#    if (!$self->{bin_mode}) {
#        $buf =~ s(\n)(\015\012)g;
#    }

    &_put($self, \$buf, "put");
}

sub rs { &input_record_separator }

sub send_wakeup {
    my ($self, $arg) = @_;
    $self->{send_wakeup} = $arg if defined $arg;
    return $self->{send_wakeup}
}

sub sock {
    my $self = shift;
    exists $self->{_SSH_} ? $self->{_SSH_}->sock : undef
}

sub ssh2 {
    my $self = shift;
    exists $self->{_SSH_} ? $self->{_SSH_} : undef
}

sub ssh2_chan {
    my $self = shift;
    exists $self->{_SSH_CHAN_} ? $self->{_SSH_CHAN_} : undef
}

sub timed_out {
    my $self = shift;
    exists $self->{timedout} ? $self->{timedout} : undef
}

sub timeout {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_timeout($self, $arg))) {
            $self->{time_out} = $r
        }
    }
    return $self->{time_out}
}

sub waitfor {
    my ($self, @args) = @_;

    my $ap      = $self->{autopage};
    my $awfp    = $self->{always_waitfor_prompt};
    my $binmode = $self->{bin_mode};
    my $chan    = $self->{_SSH_CHAN_};
    my $clear   = $self->{waitfor_clear};
    my $cmd     = $self->{last_cmd};
    my $normal  = $self->{normalize_cmd};
    my $rm      = $self->{cmd_rm_mode};
    my $timeout = $self->{time_out};

    if (!defined $chan) {
        &_croak($self, "no login " .
        "for " . ref($self) . "::waitfor()");
    }

    local $@;
    local $_;
    my $DONE   = 0;
    my $MORE   = _prep_regex($self->{more_prompt});
    my $PROMPT = _prep_regex($self->{cmd_prompt});
    my ($match, $buffer, $errmode);
    my @matches;
    if ($awfp) {
        push @matches, $PROMPT
    }

    $self->{timedout} = '';
    return if $self->{eofile};
    return unless @args;

    if (@_ == 2) {
        push @matches, _prep_regex($_[1])
    } else {
        my $arg;
        while (($_, $arg) = splice @args, 0, 2 ) {
            if (/^-?binmode$/i) {
                $binmode = $arg
            } elsif (/^-?errmode$/i) {
                $errmode = &_parse_errmode($self, $arg);
            } elsif (/^-?match$/i) {
                push @matches, _prep_regex($arg)
            } elsif (/^-?normalize_cmd$/i) {
                $normal = $arg
            } elsif (/^-?string$/i) {
                $arg =~ s/'/\\'/g;  # quote ticks
                push @matches, $arg
            } elsif (/^-?timeout$/i) {
                $timeout = _parse_timeout($self, $arg)
            } elsif (/^-?waitfor_clear$/i) {
                $clear = $arg
            } else {
                # pass through
                #$params{$_} = $args{$_}
                &_croak($self, "bad named parameter \"$_\" given " .
                    "to " . ref($self) . "::waitfor()");
            }
        }
    }

    local $self->{errormode} = $errmode if defined $errmode;
    local $self->{waitfor_clear} = $clear;

    eval {
        local $SIG{ALRM} = sub { die "timed-out\n" };
        alarm $timeout;

        if ($self->{waitfor_clear}) {
            $chan->flush;
        }

        # Read until $DONE
        while (1) {
            last if $DONE;
            last if $self->eof;
            # Read chunk
            while (defined (
                my $len = $chan->read($self->{buf},$self->{maxbufsize}))) {

                ## Display network traffic if requested.
                if ($self->{dumplog} and ($self->{buf} ne '')) {
                    &_log_dump('<', $self->{dumplog}, \$self->{buf}, 0, $len);
                }

                # behave like Net::Telnet(::Cisco) CRLF
                _interpret_cr($self, 0);

                # input logging
                if ($self->{inputlog}) {
                    &_log_print($self->{inputlog}, $self->{buf});
                }

                # Found match then $DONE
                for my $m (@matches) {
                    if ($self->{buf} =~ /($m)/) {
                        $match = $1;
                        $self->{buf} =~ s/$m//;
                        $DONE++
                    }
                }

                # autopage
                if ($ap and ($self->{buf} =~ /($MORE)/)) {
                    $self->put(" ");
                }

                $buffer .= $self->{buf}
            }
        }

        if ($ap and $normal and defined $buffer) {
            $buffer = _normalize($buffer);
        }
    };
    alarm 0;
    if ($@ =~ /^timed-out$/) {
        $self->errmsg("timed-out during read");
        $self->{timedout} = 1;
        # If previous call to waitfor timed out, there may still be
        # stuff in the channel - e.g., "show run" takes time to "build
        # configuration" and that may time out, but the output will fill
        # the channel after the return and if term length is a finite
        # value - like the default 24 - a MORE prompt is waiting.  So
        # we need to send a character to cancel that; otherwise, the first
        # character of the subsequent $chan->write() (usually from cmd())
        # will "disappear" from the output - satisfying the MORE prompt
        # and being lost forever.
        # The following is 'Control-Shift-Z', which breaks a MORE and
        # returns the prompt.
        #$chan->write("\cZ")
        if ($self->{waitfor_clear}) {
            $self->ios_break("Z")
        }
    }

    if ($self->{waitfor_clear}) {
        $chan->flush;
    }

    if (defined $match and ($match =~ /$PROMPT/)) {
        $self->{last_prompt} = $match
    }

    wantarray ? ($buffer, $match) : 1;
}

sub waitfor_clear {
    my ($self, $arg) = @_;
    $self->{waitfor_clear} = $arg if defined $arg;
    return $self->{waitfor_clear}
}

sub waitfor_pause {
    my ($self, $arg) = @_;

    if (defined $arg) {
        if (defined (my $r = _parse_waitfor_pause($self, $arg))) {
            $self->{waitfor_pause} = $r
        }
    }
    return $self->{waitfor_pause}
}

sub warnings {
    my ($self, $arg) = @_;
    $self->{warnings} = $arg if defined $arg;
    return $self->{warnings}
}

#### PRIVATE ####

sub _append_lineno {
    my ($obj, @msgs) = @_;

    my ( $file, $line, $pkg);

    ## Find the caller that's not in object's class or one of its base classes.
    ($pkg, $file , $line) = &_user_caller($obj);
    join("", @msgs, " at ", $file, " line ", $line, "\n");
}

sub _carp {
    my ($self) = @_;

    $self->{errormsg} = &_append_lineno(@_);
    warn $self->{errormsg}, "\n";
}

sub _croak {
    my ($self) = @_;

    $self->{errormsg} = &_append_lineno(@_);
    die $self->{errormsg}, "\n";
}

sub _extract_arg_errmode {
    my ($self, $args) = @_;
    my (%args);
    local $_;
    my $errmode = '';

    ## Check for named parameters.
    return '' unless @$args >= 2;

    ## Rebuild args without errmode parameter.
    %args = @$args;
    @$args = ();

    ## Extract errmode arg.
    foreach (keys %args) {
        if (/^-?errmode$/i) {
            $errmode = &_parse_errmode($self, $args{$_});
        } else {
            push @$args, $_, $args{$_};
        }
    }
    $errmode;
}

sub _fname_to_handle {
    my ($self, $filename) = @_;

    no strict "refs";

    my $fh = &_new_handle();
    CORE::open $fh, ">", $filename
        or return $self->error("problem creating $filename: $!");

    $fh;
}

sub _interpret_cr {
    my ($s, $pos) = @_;
    my (
    $nextchar,
    );

    while (($pos = index($s->{buf}, "\015", $pos)) > -1) {
        $nextchar = substr($s->{buf}, $pos + 1, 1);
        if ($nextchar eq "\0") {
            ## Convert CR NULL to CR when in telnet mode.
            if ($s->{telnet_mode}) {
                substr($s->{buf}, $pos + 1, 1) = "";
            }
        }
        elsif ($nextchar eq "\012") {
            ## Convert CR LF to newline when not in binary mode.
            if (!$s->{bin_mode}) {
                substr($s->{buf}, $pos, 2) = "\n";
            }
        }
        elsif (!length($nextchar) and ($s->{telnet_mode} or !$s->{bin_mode})) {
            ## Save CR in alt buffer for possible CR LF or CR NULL conversion.
            $s->{pushback_buf} .= "\015";
            chop $s->{buf};
        }

        $pos++;
    }

    1;
} # end sub _interpret_cr

sub _is_open_fh {
    my ($fh) = @_;
    my $is_open = '';
    local $@;

    eval {
        local $SIG{"__DIE__"} = "DEFAULT";
        $is_open = defined(fileno $fh);
    };

    $is_open;
}

sub _log_dump {
    my ($direction, $fh, $data, $offset, $len) = @_;

    my $addr = 0;
    $len = length($$data) - $offset
        if !defined $len;
    return 1 if $len <= 0;

    my ($hexvals, $line);
    ## Print data in dump format.
    while ($len > 0) {
        ## Convert up to the next 16 chars to hex, padding w/ spaces.
        if ($len >= 16) {
            $line = substr $$data, $offset, 16;
        } else {
            $line = substr $$data, $offset, 16;
        }
        $hexvals = unpack("H*", $line);
        $hexvals .= ' ' x (32 - length $hexvals);

        ## Place in 16 columns, each containing two hex digits.
        $hexvals = sprintf("%s %s %s %s  " x 4, unpack("a2" x 16, $hexvals));

        ## For the ASCII column, change unprintable chars to a period.
        $line =~ s/[\000-\037,\177-\237]/./g;

        ## Print the line in dump format.
        &_log_print($fh, sprintf("%s 0x%5.5lx: %s%s\n",
            $direction, $addr, $hexvals, $line));

        $addr += 16;
        $offset += 16;
        $len -= 16;
    }

    &_log_print($fh, "\n");

    1;
}

sub _log_print {
    my ($fh, $buf) = @_;
    local $\ = '';

    if (ref($fh) eq "GLOB") {  # fh is GLOB ref
        print $fh $buf;
    } else {  # fh isn't GLOB ref
        $fh->print($buf);
    }
}

sub _match_check {
    my ($self, $code) = @_;
    my $error;
    my @warns = ();
    local $@;

    ## Use eval to check for syntax errors or warnings.
    {
        local $SIG{"__DIE__"} = "DEFAULT";
        local $SIG{"__WARN__"} = sub { push @warns, @_ };
        local $^W = 1;
        local $_ = '';
        eval "\$_ =~ $code;";
    }
    if ($@) {
        ## Remove useless lines numbers from message.
        ($error = $@) =~ s/ at \(eval \d+\) line \d+.?//;
        chomp $error;
        return $self->error("bad match operator: $error");
    } elsif (@warns) {
        ## Remove useless lines numbers from message.
        ($error = shift @warns) =~ s/ at \(eval \d+\) line \d+.?//;
        $error =~ s/ while "strict subs" in use//;
        chomp $error;
        return $self->error("bad match operator: $error");
    }

    1;
}

sub _new_handle {
    if ($INC{"IO/Handle.pm"}) {
        return IO::Handle->new;
    } else {
        require FileHandle;
        return FileHandle->new;
    }
}

sub _normalize {
    $_ = join "", @_;

    1 while s/[^\cH\c?][\cH\c?]//mg; # ^H ^?
    s/^.*\cU//mg;            # ^U

    return wantarray ? split /^/, $_ : $_; # ORS instead?
}

sub _parse_cmd_remove_mode {
    my ($self, $arg) = @_;

    my $crm;
    if ($arg =~ /^\d+$/) {
        $crm = $arg
    } elsif ($arg =~ /^\s*auto\s*$/i) {
        $crm = "auto"
    } else {
        &_carp($self, "ignoring bad Cmd_remove_mode " .
            "argument \"$arg\": it's not \"auto\" or a " .
            "non-negative integer");
        $crm = $self->{cmd_rm_mode}
    }
    $crm
}

sub _parse_errmode {
    my ($self, $errmode) = @_;

    ## Set the error mode.
    if (!defined $errmode) {
        &_carp($self, "ignoring undefined Errmode argument");
        $errmode = $self->{errormode};
    } elsif ($errmode =~ /^\s*return\s*$/i) {
        $errmode = "return";
    } elsif ($errmode =~ /^\s*die\s*$/i) {
        $errmode = "die";
    } elsif (ref($errmode) eq "CODE") {
    } elsif (ref($errmode) eq "ARRAY") {
        unless (ref($errmode->[0]) eq "CODE") {
            &_carp($self, "ignoring bad Errmode argument: " .
                "first list item isn't a code ref");
            $errmode = $self->{errormode};
        }
    } else {
        &_carp($self, "ignoring bad Errmode argument \"$errmode\"");
        $errmode = $self->{errormode};
    }
    $errmode;
}

sub _parse_family {
    my ($self, $arg) = @_;

    my $family;
    if ($arg =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
        if ($arg =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
            $family = 'ipv4' # AF_INET
        } else {
            if (!$HAVE_IO_Socket_IP) {
                return $self->error("IO::Socket::IP required for IPv6")
            }
            $family = 'ipv6' # $AF_INET6
        }
    } else {
        return $self->error("bad Family argument \"$arg\": " .
            "must be \"ipv4\" or \"ipv6\"");
    }
    $family
}

sub _parse_family_to_num {
    my ($self, $arg) = @_;
    if ($arg eq 'ipv4') {
        return AF_INET
    } elsif ($arg eq 'ipv6') {
        return $AF_INET6
    } else {
        return $self->error("invalid address family - `$arg'");
    }
}

sub _parse_port {
    my ($self, $arg) = @_;

    my $port;
    if ($arg =~ /^\d{1,5}$/) {
        if (($arg > 0) and ($arg < 65536)) {
            $port = $arg
        } else {
            return $self->error("not a valid port - `$arg'")
        }
    } else {
        return $self->error("port not a valid number - `$arg'")
    }
    $port
}

sub _parse_prompt {
    my ($self, $prompt) = @_;

    unless (defined $prompt) {
        $prompt = "";
    }

    return $self->error("bad Prompt argument \"$prompt\": " .
        "missing opening delimiter of match operator")
        unless $prompt =~ m(^\s*/) or $prompt =~ m(^\s*m\s*\W);

    $prompt;
}

sub _parse_timeout {
    my ($self, $arg) = @_;

    my $timeout;
    if ($arg =~ /^\d+$/) {
        $timeout = $arg
    } else {
        return $self->error("not a valid timeout - `$arg'")
    }
    $timeout
}

sub _parse_waitfor_pause {
    my ($self, $arg) = @_;

    my $wfp;
    if ($arg =~ /^[0-9]*\.?[0-9]+$/) {
        $wfp = $arg
    } else {
        return $self->error("not a valid waitfor_pause - `$arg'")
    }
    $wfp
}

sub _put {
    my ($self, $buf, $subname) = @_;

    return $self->error("write error: filehandle isn't open")
        unless $self->{opened};

    if (exists $self->{_SSH_CHAN_}) {
        my $nwrote = $self->{_SSH_CHAN_}->write($$buf);

        ## Display network traffic if requested.
        if ($self->{dumplog}) {
            &_log_dump('>', $self->{dumplog}, $buf, 0, $nwrote);
        }
    } else {
        return $self->error("Net::SSH2::Channel not created")
    }
    1
}

sub _prep_regex {
    my ($regex) = @_;
    # strip leading / if found
    $regex =~ s/^\///;
    # strip trailing / if found
    $regex =~ s/\/$//;

    return $regex
}

##################################################
# DNS hostname resolution
# return:
#   $host->{name}   = host - as passed in
#   $host->{host}   = host - as passed in without :port
#   $host->{port}   = OPTIONAL - if :port, then value of port
#   $host->{addr}   = resolved numeric address
#   $host->{family} = AF_INET/6
############################
sub _resolv {
    my ($self, $name, $family) = @_;

    my %h;
    $h{name} = $name;

    # Default to IPv4 for backward compatiblity
    # THIS MAY CHANGE IN THE FUTURE!!!
    if (!defined $family) {
        $family = AF_INET
    }

# START - host:port
    my $cnt = 0;

    # Count ":"
    $cnt++ while ($name =~ m/:/g);

    # 0 = hostname or IPv4 address
    if ($cnt == 0) {
        $h{host} = $name
    # 1 = IPv4 address with port
    } elsif ($cnt == 1) {
        ($h{host}, $h{port}) = split /:/, $name
    # >=2 = IPv6 address
    } elsif ($cnt >= 2) {
        #IPv6 with port - [2001::1]:port
        if ($name =~ /^\[.*\]:\d{1,5}$/) {
            ($h{host}, $h{port}) = split /:([^:]+)$/, $name # split after last :
        # IPv6 without port
        } else {
            $h{host} = $name
        }
    }

    # Clean up host
    $h{host} =~ s/\[//g;
    $h{host} =~ s/\]//g;
    # Clean up port
    if (defined $h{port} && (($h{port} !~ /^\d{1,5}$/) || ($h{port} < 1) || ($h{port} > 65535))) {
        $self->errmsg("Invalid port `$h{port}' in `$name'");
        return undef
    }
# END - host:port

    # address check
    # new way
    if (version->parse($Socket::VERSION) >= version->parse(1.94)) {
        my %hints = (
            family   => $AF_UNSPEC,
            protocol => IPPROTO_TCP,
            flags => $AI_NUMERICHOST
        );

        # numeric address, return
        my ($err, @getaddr) = Socket::getaddrinfo($h{host}, undef, \%hints);
        if (defined $getaddr[0]) {
            $h{addr}   = $h{host};
            $h{family} = $getaddr[0]->{family};
            return \%h
        }
    # old way
    } else {
        # numeric address, return
        my $ret = gethostbyname($h{host});
        if (defined $ret && (inet_ntoa($ret) eq $h{host})) {
            $h{addr}   = $h{host};
            $h{family} = AF_INET;
            return \%h
        }
    }

    # resolve
    # new way
    if (version->parse($Socket::VERSION) >= version->parse(1.94)) {
        my %hints = (
            family   => $family,
            protocol => IPPROTO_TCP
        );

        my ($err, @getaddr) = Socket::getaddrinfo($h{host}, undef, \%hints);
        if (defined $getaddr[0]) {
            my ($err, $address) = Socket::getnameinfo($getaddr[0]->{addr}, $NI_NUMERICHOST);
            if (defined $address) {
                $h{addr} = $address;
                $h{addr} =~ s/\%(.)*$//; # remove %ifID if IPv6
                $h{family} = $getaddr[0]->{family};
                return \%h
            } else {
                $self->errmsg("getnameinfo($getaddr[0]->{addr}) failed - $err");
                return undef
            }
        } else {
            my $LASTERROR = sprintf "getaddrinfo($h{host},,%s) failed - $err", ($family == AF_INET) ? "AF_INET" : "AF_INET6";
            $self->errmsg($LASTERROR);
            return undef
        }
    # old way
    } else {
        if ($family == $AF_INET6) {
            $self->errmsg("Socket >= 1.94 required for IPv6 - found Socket $Socket::VERSION");
            return undef
        }

        my @gethost = gethostbyname($h{host});
        if (defined $gethost[4]) {
            $h{addr} = inet_ntoa($gethost[4]);
            $h{family} = AF_INET;
            return \%h
        } else {
            $self->errmsg("gethostbyname($h{host}) failed - $^E");
            return undef
        }
    }
}

sub _user_caller {
    my ($obj) = @_;

    my ($class, $curr_pkg, $file, $i, $line, $pkg, %isa, @isa);
    local $@;
    local $_;

    ## Create a boolean hash to test for isa.  Make sure current
    ## package and the object's class are members.
    $class = ref $obj;
    @isa = eval "\@${class}::ISA";
    push @isa, $class;
    ($curr_pkg) = caller 1;
    push @isa, $curr_pkg;
    %isa = map { $_ => 1 } @isa;

    ## Search back in call frames for a package that's not in isa.
    $i = 1;
    while (($pkg, $file, $line) = caller ++$i) {
        next if $isa{$pkg};

        return ($pkg, $file, $line);
    }

    ## If not found, choose outer most call frame.
    ($pkg, $file, $line) = caller --$i;
    return ($pkg, $file, $line);
}

1;

__END__

=head1 NAME

Net::SSH2::Cisco - interact with a Cisco router via SSH

=head1 SYNOPSIS

  use Net::SSH2::Cisco;

  my $session = Net::SSH2::Cisco->new(host => '123.123.123.123');
  $session->login('login', 'password');

  # Execute a command
  my @output = $session->cmd('show version');
  print @output;

  # Enable mode
  if ($session->enable("enable_password") ) {
      @output = $session->cmd('show privilege');
      print "My privileges: @output\n";
  } else {
      warn "Can't enable: " . $session->errmsg;
  }

  $session->close;

=head1 DESCRIPTION

Net::SSH2::Cisco provides additional functionality to Net::SSH2
for dealing with Cisco routers in much the same way Net::Telnet::Cisco
enhances Net::Telnet.  In fact, this module borrows B<heavily> from
both of those excellent modules.

This module is basically a cut/paste of:

=over 2

=item *

70% Net::Telnet

=item *

20% Net::Telnet::Cisco

=item *

5% Net::SSH2(::Channel)

=item *

5% original hack to make it all work together

=back

I tried many ways first:

=over 2

=item *

Create a child class of Net::SSH2 to no avail due to the C-type 
inside-out object it returns and my lack of experience.

=item *

Pass a Net::SSH2(::Channel) connection to Net::Telnet(::Cisco) fhopen()
method, but it returned:

C<Not a GLOB reference at [...]/perl/vendor/lib/Net/Telnet.pm line 679.>

=item *

Use Net::Telnet in C<@ISA> with C<AUTOLOAD> to leverage the accessors and 
code already written, but I'm not creating a Net::Telnet object and 
I couldn't get it to work.

=back

That left me the I<(?only?)> option - to write this Franken-module "liberally
borrowing" from much smarter, more talented programmers than I.

Why Net::SSH2?  Because it's the only SSH module on CPAN that works for me.

=over 2

=item *

B<Net::SSH::Perl> - too many dependencies making it too difficult to install;
especially on Windows.

=item *

B<Net::OpenSSH> - does not work on Windows (partial success).

=item *

B<Control::CLI> - does a great job of being a parent to Net::SSH2 and
Net::Telnet.  Unfortunately, not Net::Telnet::Cisco, so no Cisco-specific 
enhancements.

=item *

B<Net::Appliance::Session> - seemed promising, but has more dependencies
than Net::SSH::Perl; no go.

=back

B<Net::SSH2> comes bundled in vendor\lib with Strawberry Perl distributions
and I've heard no complaints on Perl boards about use on *nix; so we're
ready to go!

=head1 CAVEATS

Before you use Net::SSH2::Cisco, you should have a good
understanding of Net::SSH2, Net::Telnet and Net::Telnet::Cisco, so read
their documentation first, and then come back here.

=head1 METHODS

=over 4

=item B<new> - create new Net::SSH2::Cisco object

    $obj = Net::SSH2::Cisco->new(
        [Always_waitfor_prompt   => $mode,]       # 1
        [Autopage                => $mode,]       # 1
        [Binmode                 => $mode,]       # 0
        [Blocking                => $mode,]       # 0
        [Cmd_remove_mode         => $mode,]       # "auto"
        [Dump_Log                => $file,]       # ''
        [Family                  => $family,]     # "ipv4"
        [Fhopen                  => $filehandle,]
        [Host                    => $host,]       # "localhost"
        [Ignore_warnings         => $mode,]       # 0
        [Input_log               => $file,]       # ''
        [Input_record_separator  => $char,]       # "\n"
        [Max_buffer_length       => $len,]        # 1,048,576 bytes (i.e., 1MB)
        [More_prompt             => $matchop,]    # '/(?m:^\s*--More--)/',
        [Normalize_cmd           => $boolean,]    # 1
        [Output_field_separator  => $chars,]      # ""
        [Output_log              => $file,]       # ''
        [Output_record_separator => $char,]       # "\n"
        [Port                    => $port,]       # 22
        [Prompt                  => $matchop,]    # '/(?m:^(?:[\w.\/]+\:)?[\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/'
        [Send_wakeup             => $when,]       # 0
        [Timeout                 => $secs,]       # 10
        [Waitfor_clear           => $mode,]       # 0
        [Waitfor_pause           => $millisecs,]  # 0.2
        [Warnings]               => $matchop,]    # /(?mx:^% Unknown VPN
                                                        |^%IP routing table VRF.* does not exist. Create first$
                                                        |^%No CEF interface information
                                                        |^%No matching route to delete$
                                                        |^%Not all config may be removed and may reappear after reactivating
                                                    )/
    );

This is the constructor for Net::SSH2::Cisco objects.  A new object is
returned on success, failure returns undefined.  The optional arguments
are short-cuts to methods of the same name.

If the I<$host> argument is given then the object is opened by
connecting to TCP I<$port> on I<$host>.  Also see C<connect()>.  The new
object returned is given the defaults listed above.

=item B<always_waitfor_prompt> - waitfor and cmd prompt behavior

    $mode = $obj->always_waitfor_prompt;

    $mode = $obj->always_waitfor_prompt($mode);

If you pass a Prompt argument to cmd() or waitfor() a String or Match,
they will return control on a successful match of your argument(s) or
the default prompt. Set always_waitfor_prompt to 0 to return control
only for your arguments.

This method has no effect on login(). login() will always wait for a
prompt.

=item B<autopage> - Turn autopaging on and off

    $mode = $obj->autopage;

    $mode = $obj->autopage($mode);

IOS pages output by default. It expects human eyes to be reading the
output, not programs.  Humans hit the spacebar to scroll page by
page so autopage() mimics that behavior.  This is the slow way to
handle paging.  Consider sending "terminal length 0" as the first C<cmd()>.

=item B<binmode> - toggle newline translation

    $mode = $obj->binmode;

    $mode = $obj->binmode($mode);

This method controls whether or not sequences of carriage returns and
line feeds (CR LF or more specifically C<"\015\012">) are translated.
By default they are translated (i.e. binmode is C<0>).

If no argument is given, the current mode is returned.

If I<$mode> is C<1> then binmode is I<on> and newline translation is
not done.

If I<$mode> is C<0> then binmode is I<off> and newline translation is
done.  In the input stream, each sequence of CR LF is converted to
C<"\n">.

=item B<blocking> - toggle channel blocking

    $mode = $obj->blocking;

    $mode = $obj->blocking($mode);

This method controls whether or not to enable C<blocking> on the
underlying Net::SSH2::Channel object created in C<connect()>.

If no argument is given, the current mode is returned.

=item B<close> - close object

    $ok = $obj->close;

This method closes the object.

=item B<cmd> - issue command and retrieve output

    $ok = $obj->cmd($string);
    $ok = $obj->cmd(
         String  => $string,
        [Output  => $ref,]
        [Cmd_remove_mode => $mode,]
        [Errmode => $mode,]
        [Input_record_separator  => $chars,]
        [Output_record_separator => $chars,]
        [Prompt  => $match,]
        [Timeout => $secs,]
        [Waitfor_clear => $mode,]
        [Waitfor_pause => $millisecs,]
    );

    @output = $obj->cmd($string);
    @output = $obj->cmd(
         String  => $string,
        [Output  => $ref,]
        [Cmd_remove_mode => $mode,]
        [Errmode => $mode,]
        [Input_record_separator  => $chars,]
        [Output_record_separator => $chars,]
        [Prompt  => $match,]
        [Timeout => $secs,]
        [Waitfor_clear => $mode,]
        [Waitfor_pause => $millisecs,]
    );

This method sends the command I<$string>, and reads the characters
sent back by the command up until and including the matching prompt.
It's assumed that the program to which you're sending is some kind of
command prompting interpreter such as a shell.

The command I<$string> is automatically appended with the
output_record_separator, by default it is C<"\n">.  This is similar
to someone typing a command and hitting the return key.  Set the
output_record_separator to change this behavior.

In a scalar context, the characters read from the remote side are
discarded and C<1> is returned on success.  On time-out, eof, or other
failures, the error mode action is performed.  See C<errmode()>.

In a list context, just the output generated by the command is
returned, one line per element.  In other words, all the characters in
between the echoed back command string and the prompt are returned.
If the command happens to return no output, a list containing one
element, the empty string is returned.  This is so the list will
indicate true in a boolean context.  On time-out, eof, or other
failures, the error mode action is performed.  See C<errmode()>.

The characters that matched the prompt may be retrieved using
C<last_prompt()>.

Many command interpreters echo back the command sent.  In most
situations, this method removes the first line returned from the
remote side (i.e. the echoed back command).  See C<cmd_remove_mode()>
for more control over this feature.

The I<Output> named parameter provides an alternative method of
receiving command output.  If you pass a scalar reference, all the
output (even if it contains multiple lines) is returned in the
referenced scalar.  If you pass an array or hash reference, the lines
of output are returned in the referenced array or hash.  You can use
C<input_record_separator()> to change the notion of what separates a
line.

=item B<cmd_remove_mode> - toggle removal of echoed commands

    $mode = $obj->cmd_remove_mode;

    $mode = $obj->cmd_remove_mode($mode);

This method controls how to deal with echoed back commands in the
output returned by cmd().  Typically, when you send a command to the
remote side, the first line of output returned is the command echoed
back.  Use this mode to remove the first line of output normally
returned by cmd().

If no argument is given, the current mode is returned.

If I<$mode> is C<0> then the command output returned from cmd() has no
lines removed.  If I<$mode> is a positive integer, then the first
I<$mode> lines of command output are stripped.

By default, I<$mode> is set to C<"auto">.  Auto means that whether or
not the first line of command output is stripped, depends on whether
or not it is matched in the first line of command output.

=item B<connect> - connect to port on remote host

    $ok = $obj->connect($host);

    $ok = $obj->connect(
        [Fhopen  => $filehandle,]
        [Host    => $host,]
        [Port    => $port,]
        [Family  => $family,]
        [Timeout => $secs,]
    );

This method opens a TCP connection to I<$port> on I<$host> for the IP
address I<$family>.  If C<$filehandle> is provided, other options are
ignored.  If any of the arguments are missing then the current attribute
value for the object is used.  Specifying any optional named parameters
overrides the current setting for this call to C<connect()>.

This essentially performs a Net::SSH2 C<connect()> call.

=item B<disable> - leave enabled mode

    $ok = $obj->disable;

This method exits the router's privileged mode.

=item B<dump_log> - log all I/O in dump format

    $fh = $obj->dump_log;

    $fh = $obj->dump_log($fh);

    $fh = $obj->dump_log($filename);

This method starts or stops dump format logging of all the object's
input and output.  The dump format shows the blocks read and written
in a hexadecimal and printable character format.  This method is
useful when debugging, however you might want to first try
C<input_log()> as it's more readable.

If no argument is given, the log filehandle is returned.  A returned
empty string indicates logging is off.

To stop logging, use an empty string as an argument.  The stopped
filehandle is not closed.

If an open filehandle is given, it is used for logging and returned.
Otherwise, the argument is assumed to be the name of a file, the
filename is opened for logging and a filehandle to it is returned.  If
the filehandle is not already opened or the filename can't be opened
for writing, the error mode action is performed.

B<NOTE:> Logging starts I<after> login so the initial login sequence 
(i.e., banner, username and password exchange) is I<not> captured.  This 
is due to Net::SSH2 not having a logging function.

=item B<enable> - enter enabled mode

    $ok = $obj->enable;

    $ok = $obj->enable($password);

    $ok = $obj->enable(
        [Name => $name,]
        [Password => $password,]
        [Level => $level,]
    );

This method changes privilege level to enabled mode.

If a single argument is provided by the caller, it will be used as
a password.  Returns 1 on success and undef on failure.

=item B<eof> - end of file indicator

    $eof = $obj->eof;

This method returns C<1> if end of file has been read, otherwise it
returns an empty string.

=item B<errmode> - define action to be performed on error

    $mode = $obj->errmode;

    $mode = $obj->errmode($mode);

This method gets or sets the action used when errors are encountered
using the object.  The first calling sequence returns the current
error mode.  The second calling sequence sets it to I<$mode>.  Valid values
for I<$mode> are C<"die"> (the default), C<"return">, a I<coderef>
or an I<arrayref>.

When mode is C<"die"> and an error is encountered using the object,
then an error message is printed to standard error and the program
dies.

When mode is C<"return"> then the method generating the error places
an error message in the object and returns an undefined value in a
scalar context and an empty list in list context.  The error message
may be obtained using C<errmsg()>.

When mode is a I<coderef>, then when an error is encountered
I<coderef> is called with the error message as its first argument.
Using this mode you may have your own subroutine handle errors.  If
I<coderef> itself returns then the method generating the error returns
undefined or an empty list depending on context.

When mode is an I<arrayref>, the first element of the array must be a
I<coderef>.  Any elements that follow are the arguments to I<coderef>.
When an error is encountered, the I<coderef> is called with its
arguments.  Using this mode you may have your own subroutine handle
errors.  If the I<coderef> itself returns then the method generating
the error returns undefined or an empty list depending on context.

A warning is printed to STDERR when attempting to set this attribute
to something that is not C<"die">, C<"return">, a I<coderef>, or an
I<arrayref> whose first element isn't a I<coderef>.

=item B<errmsg> - most recent error message

    $msg = $obj->errmsg;

    $msg = $obj->errmsg(@msgs);

The first calling sequence returns the error message associated with
the object.  The empty string is returned if no error has been
encountered yet.  The second calling sequence sets the error message
for the object to the concatenation of I<@msgs>.  Normally, error
messages are set internally by a method when an error is encountered.

=item B<error> - perform the error mode action

    $obj->error(@msgs);

This method concatenates I<@msgs> into a string and places it in the 
object as the error message.  Also see C<errmsg()>.  It then performs 
the error mode action.  Also see C<errmode()>.

If the error mode doesn't cause the program to die, then an undefined 
value or an empty list is returned depending on the context.

This method is primarily used by this class or a sub-class to perform 
the user requested action when an error is encountered.

=item B<family> - IP address family for remote host

    $family = $obj->family;

    $family = $obj->family($family);

This method designates which IP address family C<host()> refers to,
i.e. IPv4 or IPv6.  IPv6 support is available when using perl 5.14 or
later.  With no argument it returns the current value set in the
object.  With an argument it sets the current address family to
I<$family> returns.  Valid values are C<"ipv4"> or C<"ipv6">.

This returns when attempting to set an invalid family or attempting
to set C<"ipv6"> when the Socket module is less than version 1.94
or IPv6 is not supported.

Note, Net::SSH2 does not support IPv6 natively, so setting C<"ipv6">
requires IO::Socket::IP be installed.

=item B<fhopen> - use already open filehandle for I/O

    $ok = $obj->fhopen($fh);

This method associates the open filehandle I<$fh> with I<$obj> for
further I/O.  Filehandle I<$fh> must already be opened.

To support IPv6 in older versions of Net::SSH2, you may need to open an 
IO::Socket::IP object and pass that to C<connect()>.  In this module, 
Net::SSH2::Cisco takes care of IPv6 for you with the C<family()> method 
by essentially doing the same thing in the background.  If for some reason 
you're dropping this into existing code, you may already create your own 
IO object, so this allows for those existing instances.

=item B<host> - name or IP address of remote host

    $host = $obj->host;

    $host = $obj->host($host);

This method designates the remote host for C<open()>.  It is either a
hostname or an IP address.  With no argument it returns the current
value set in the object.  With an argument it sets the current host
name to I<$host>.  Use C<family()> to control which IP address family,
IPv4 or IPv6, hostnames should resolve to.

It may also be set by C<new()> or C<connect()>.

=item B<ignore_warnings> - Don't call error() for warnings

    $mode = $obj->ignore_warnings;

    $mode = $obj->ignore_warnings($mode);

Not all strings that begin with a '%' are really errors. Some are just
warnings. By setting this, you are ignoring them.

=item B<input_log> - log all input

    $fh = $obj->input_log;

    $fh = $obj->input_log($fh);

    $fh = $obj->input_log($filename);

This method starts or stops logging of input.  This is useful when
debugging.  Also see C<dump_log()>.  Because most command interpreters
echo back commands received, it's likely all your output will also be
in this log.  Note that input logging occurs after newline
translation.  See C<binmode()> for details on newline translation.

If no argument is given, the log filehandle is returned.  A returned
empty string indicates logging is off.

To stop logging, use an empty string as an argument.  The stopped
filehandle is not closed.

If an open filehandle is given, it is used for logging and returned.
Otherwise, the argument is assumed to be the name of a file, the
filename is opened for logging and a filehandle to it is returned.  If
the filehandle is not already opened or the filename can't be opened
for writing, the error mode action is performed.

B<NOTE:> Logging starts I<after> login so the initial login sequence 
(i.e., banner, username and password exchange) is I<not> captured.  This 
is due to Net::SSH2 not having a logging function.

=item B<input_record_separator> - input line delimiter

    $char = $obj->input_record_separator;

    $char = $obj->input_record_separator($char);

This method designates the line delimiter for input.  It's used with
C<cmd()> to determine lines in the input.

With no argument this method returns the current input record
separator set in the object.  With an argument it sets the input
record separator to I<$char>.  Note that I<$char> must have length.

Alias:

=over 4

=item B<rs>

=back

=item B<ios_break> - send a break (control-^)

    $ok = $obj->ios_break;

    $ok = $obj->ios_break($char);

Send an IOS break.  This is sent without a newline.  Optional I<$char>
appends.  For example, no argument sends "Control-^".  Argument "X"
effectively sends "Control-Shift-6-X".

=item B<is_enabled> - enable mode check

    $ok = $obj->is_enabled;

A trivial check to see whether we have a root-style prompt, with
either the word "(enable)" in it, or a trailing "#".

B<Warning>: this method will return false positives if the prompt has
"#"s in it.  You may be better off calling C<$obj-E<gt>cmd("show
privilege")> instead.

=item B<last_cmd> - last command entered

    $cmd = $obj->last_cmd;

This method returns the last command executed by C<cmd()>.

=item B<last_prompt> - last prompt read

    $prompt = $obj->last_prompt;

This method returns the last prompt read by C<cmd()>.  See C<prompt()>.

=item B<login> - login to a router

    $ok = $obj->login($username, $password);

    $ok = $obj->login(
        [Name     => $username,]
        [Password => $password,]
        [Timeout  => $secs,]
    );

This method performs a login with Net::SSH2 authentication methods.
Currently, only C<auth_password> is supported.

Upon successful connection, a Net::SSH2::Channel object is created and:

=over 2

=item *

C<blocking()> is called on the channel

=item *

C<shell()> from Net::SSH2::Channel is opened

=item *

C<binmode()> is called on the channel

=item *

The first prompt (see C<prompt()>)is read off.

=back

Must be connected by calling C<new> or C<connect> first.

=item B<max_buffer_length> - maximum size of input buffer

    $len = $obj->max_buffer_length;

    $prev = $obj->max_buffer_length($len);

This method designates the maximum size of the input buffer.

With no argument, this method returns the current maximum buffer
length set in the object.  With an argument it sets the maximum buffer
length to I<$len>.  Values of I<$len> smaller than 512 will be adjusted
to 512.

A warning is printed to STDERR when attempting to set this attribute
to something that isn't a positive integer.

=item B<more_prompt> - Matchop used by autopage()

    $matchop = $obj->prompt;

    $matchop = $obj->prompt($matchop);

Match prompt for paging used by C<autopage()>.

=item B<normalize_cmd> - Turn normalization on and off

    $mode = $obj->normalize_cmd;

    $mode = $obj->normalize_cmd($mode);

IOS clears '--More--' prompts with backspaces (e.g., ^H). If 
you're excited by the thought of having raw control characters 
like ^H (backspace), ^? (delete), and ^U (kill) in your command 
output, turn this feature off.

Logging is unaffected by this setting.

See C<waitfor_clear()>

=item B<open> - connect to port on remote host

See C<connect()>.

=item B<output_field_separator> - field separator for print

    $chars = $obj->output_field_separator;

    $prev = $obj->output_field_separator($chars);

This method designates the output field separator for C<print()>.
Ordinarily the print method simply prints out the comma separated
fields you specify.  Set this to specify what's printed between
fields.

With no argument this method returns the current output field
separator set in the object.  With an argument it sets the output
field separator to I<$chars>.

Alias:

=over 4

=item B<ofs>

=back

=item B<output_log> - log all output

    $fh = $obj->output_log;

    $fh = $obj->output_log($fh);

    $fh = $obj->output_log($filename);

This method starts or stops logging of output.  This is useful when
debugging.  Also see C<dump_log()>.  Because most command interpreters
echo back commands received, it's likely all your output would also be
in an input log.  See C<input_log()>.  Note that output logging occurs
before newline translation.  See C<binmode()> for details on newline
translation.

If no argument is given, the log filehandle is returned.  A returned
empty string indicates logging is off.

To stop logging, use an empty string as an argument.  The stopped
filehandle is not closed.

If an open filehandle is given, it is used for logging and returned.
Otherwise, the argument is assumed to be the name of a file, the
filename is opened for logging and a filehandle to it is returned.  If
the filehandle is not already opened or the filename can't be opened
for writing, the error mode action is performed.

B<NOTE:> Logging starts I<after> login so the initial login sequence 
(i.e., banner, username and password exchange) is I<not> captured.  This 
is due to Net::SSH2 not having a logging function.

=item B<output_record_separator> - output line delimiter

    $char = $obj->output_record_separator;

    $char = $obj->output_record_separator($char);

This method designates the output line delimiter for C<cmd()>.

The output record separator is set to C<"\n"> by default, so there's
no need to append all your commands with a newline.

With no argument this method returns the current output record
separator set in the object.  With an argument it sets the output
record separator to I<$char>.

Alias:

=over 4

=item B<ors>

=back

=item B<port> - remote port

    $port = $obj->port;

    $port = $obj->port($port);

This method designates the remote TCP port for C<open()>.  With no
argument this method returns the current port number.  With an
argument it sets the current port number to I<$port>.

=item B<print> - write to object

    $ok = $obj->print(@list);

This method writes I<@list> followed by the I<output_record_separator>
to the open object and returns C<1> if all data was successfully
written.  On time-out or other failures, the error mode action is
performed.  See C<errmode()>.

By default, the C<output_record_separator()> is set to C<"\n"> so all
your commands automatically end with a newline.  In most cases your
output is being read by a command interpreter which won't accept a
command until newline is read.  This is similar to someone typing a
command and hitting the return key.  To avoid printing a trailing
C<"\n"> use C<put()> instead or set the output_record_separator to an
empty string.

You may also use the output field separator to print a string between
the list elements.  See C<output_field_separator()>.

=item B<prompt> - pattern to match a prompt

    $matchop = $obj->prompt;

    $matchop = $obj->prompt($matchop);

This method sets the pattern used to find a prompt in the input
stream.  It must be a string representing a valid perl pattern match
operator.  The methods C<login()> and C<cmd()> try to read until
matching the prompt.  They will fail if the pattern you've chosen
doesn't match what the remote side sends.

With no argument this method returns the prompt set in the object.
With an argument it sets the prompt to I<$matchop>.

For an explanation of the default prompt, see Net::Telnet::Cisco.

For an explanation of valid prompts and creating match operators,
see Net::Telnet.

=item B<put> - write to object

    $ok = $obj->put($string);

    $ok = $obj->put(
        String      => $string,
        [Binmode    => $mode,]
        [Errmode    => $errmode,]
        [Timeout    => $secs,]
    );

This method writes I<$string> to the opened object and returns C<1> if
all data was successfully written.  This method is like C<print()>
except that it doesn't write the trailing output_record_separator
("\n" by default).  On time-out or other failures, the error mode
action is performed.  See C<errmode()>.

=item B<send_wakeup> - send a newline to the router at login time

    $when = $obj->send_wakeup;

    $when = $obj->send_wakeup('connect');
    $when = $obj->send_wakeup('timeout');
    $when = $obj->send_wakeup('noflush');
    $when = $obj->send_wakeup(0);

B<Note:>  This is provided only for compatibility with drop-in replacement 
in Net::Telnet::Cisco scripts.  This has limited functionality in this 
module.

Some routers quietly allow you to connect but don't display the
expected login prompts. This I<would> send a newline in the hopes 
it spurs the routers to print something.

The issue is a Net::SSH2::Channel to send the newline over isn't 
opened until I<after> login.

However, sometimes there is contention on who talks first.  With non-blocking 
mode by default, if the router sends a prompt, it must be "flushed" from the 
channel before subsequent commands can be issues to the router.  Using the 
'noflush' argument skips this step during login.

=item B<sock> - return underlying socket object

    $sock = $obj->sock;

Returns the underlying IO::Socket (::INET or ::IP) object for the Net::SSH2
connection or undefined if not yet connected.  This allows for socket
accessors to be called.

For example:

    printf "Connected to %s:%s\n", $obj->sock->peerhost, $obj->sock-peerport;

=item B<ssh2> - return Net::SSH2 object

    $ssh2 = $obj->ssh2;

Returns the Net::SSH2 object created by C<connect()>.

=item B<ssh2_chan> - return Net::SSH2::Channel object

    $chan = $obj->ssh2_chan;

Returns the Net::SSH2::Channel object created by C<login()>.

=item B<timed_out> - time-out indicator

    $to = $obj->timed_out;

This method indicates if a previous read, write, or open method
timed-out.

=item B<timeout> - I/O time-out interval

    $secs = $obj->timeout;

    $secs = $obj->timeout($secs);

This method sets the timeout interval used when performing I/O
or connecting to a port.

If I<$secs> is C<0> then time-out occurs if the data cannot be
immediately read or written.

With no argument this method returns the timeout set in the object.
With an argument it sets the timeout to I<$secs>.

=item B<waitfor> - wait for pattern in the input

    $ok = $obj->waitfor($matchop);
    $ok = $obj->waitfor(
        [Match   => $matchop,]
        [String  => $string,]
        [Binmode => $mode,]
        [Errmode => $errmode,]
        [Timeout => $secs,]
        [Waitfor_clear => $mode,]
    );

    ($prematch, $match) = $obj->waitfor($matchop);
    ($prematch, $match) = $obj->waitfor(
        [Match   => $matchop,]
        [String  => $string,]
        [Binmode => $mode,]
        [Errmode => $errmode,]
        [Timeout => $secs,]
        [Waitfor_clear => $mode,]
    );

This method reads until a pattern match or string is found in the
input stream.  All the characters before and including the match are
removed from the input stream.

In a list context the characters before the match and the matched
characters are returned in I<$prematch> and I<$match>.  In a scalar
context, the matched characters and all characters before it are
discarded and C<1> is returned on success.  On time-out, eof, or other
failures, for both list and scalar context, the error mode action is
performed.  See C<errmode()>.

You can specify more than one pattern or string by simply providing
multiple I<Match> and/or I<String> named parameters.  A I<$matchop>
must be a string representing a valid Perl pattern match operator.
The I<$string> is just a substring to find in the input stream.

=item B<waitfor_clear> - clear read buffer in waitfor()

    $mode = $obj->waitfor_clear;

    $mode = $obj->waitfor_pause($mode);

This issues an C<ios_break> with "Z" (i.e., CTRL-Z) after a C<waitfor()> 
timeout and performs a C<flush()> on the Net::SSH::Channel before the 
C<read()>.  This tries to compensate for a call to C<waitfor> that times 
out and potentially leaves stuff in the channel.  For best effect, this 
should be set at an object property in C<new()>, but can be set on a 
local basis in C<cmd()> and C<waitfor()>.

The default is '1' - meaning on.  This complements the behavior 
of C<normalize_cmd()>.

Why do this?  For example, "show running-config" takes time while "Building 
configuration..." and that may time out if a I<timeout> is set too 
small.  But in non-blocking mode, the output may start and fill the 
channel after the return from C<waitfor> and if terminal length is a finite 
value - like the default 24 - a 'MORE' prompt is waiting - regardless of 
whether C<autopage> is enabled.

To address the possible above scenario, we can send an C<ios_break> with 
"Z" (i.e., CTRL-Z) to cancel the 'MORE' prompt.  Otherwise, the first 
character of the subsequent command (usually from C<cmd()>) will 
"satisfy" the MORE prompt, "disappear" from the output and potentially 
cause a router error (% Invalid input detected at ...).  See the following 
example:

  R1#sh run
  "Building configuration..."

TIMEOUT OCCUR!  However, non-blocking mode allows output to fill buffer 
in the background up to a 'MORE' prompt:

  Current configuration : 9721 bytes
  !
  upgrade fpd auto
  version 12.4
  no service pad
  [... output truncated ...]
  clock summer-time EDT recurring
  no ip source-route
   --More--

The buffer now has the above in it.  The next command "show version" is 
issued and the following happens:

  R1#how version
      ^
  % Invalid input detected at '^' marker.

Where did the "s" in "show version" go?  It "satisfied" the 'MORE' prompt 
and returned the regular router prompt where the rest of the command "how 
version" was entered, run and generated an error.  You can see this for 
yourself at a router console by trying:

  terminal length 24
  show run
  [DO NOT PRESS SPACE OR ENTER AT THE --MORE-- PROMPT]
  show version

Alternatively, try this, which is what C<waitfor_clear> effectively does:

  terminal length 24
  show run
  [DO NOT PRESS SPACE OR ENTER AT THE --MORE-- PROMPT]
  [PRESS CTRL-Z KEY COMBINATION]
  show version

=item B<waitfor_pause> - insert a small delay before waitfor()

    $millisecs = $obj->waitfor_pause;

    $millisecs = $obj->waitfor_pause($millisecs);

There is a timing issue between SSH write() and read() manifested in 
C<cmd()> and C<enable>.  This adds a slight delay after sending the 
command and before reading the result to compensate.  You should not 
have to change the default.

=item B<warnings> - matchop used by ignore_warnings()

    $boolean = $obj->warnings;

    $boolean = $obj->warnings($matchop);

Not all strings that begin with a '%' are really errors. Some are just 
warnings. Cisco calls these the CIPMIOSWarningExpressions.

=back

=head1 EXAMPLES

See the B<EXAMPLES> sections of both Net::Telnet and Net::Telnet::Cisco.

=head1 SEE ALSO

L<Net::SSH2>, L<Net::Telnet>, L<Net::Telnet::Cisco>

=head1 ACKNOWLEDGEMENTS

B<Jay Rogers> - author of Net::Telnet

B<Joshua Keroes> - author of Net::Telnet::Cisco

B<David B. Robins> - author of Net::SSH2

Without all of their excellent work, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2015 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
