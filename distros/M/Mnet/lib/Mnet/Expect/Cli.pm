package Mnet::Expect::Cli;

=head1 NAME

Mnet::Expect::Cli - Expect sessions to command line interfaces

=head1 SYNOPSIS

    # refer also to Mnet::Expect
    use Mnet::Expect::Cli;

    # prepare ssh command with host/key checking disabled
    my @ssh = qw(
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
    );

    # connect via ssh for user to specified host, prompt for password
    my $expect = Mnet::Expect::Cli->new({
        spawn       => [ @ssh, "user\@1.2.3.4" ],
        password_in => 1,
    });

    # gather output for specified command over ssh
    my $output = $expect->command("ls");

    # close ssh session
    $expect->close;

=head1 DESCRIPTION

Mnet::Expect::Cli can be used to spawn L<Expect> processes, which can be
used to programmatically control command line sessions to devices, with
support for L<Mnet> options, logging, caching, and testing.

Refer to the perl L<Expect> module for more information. Also refer to the
L<Mnet::Expect> and L<Mnet::Expect::Cli::Ios> modules.

=head1 METHODS

Mnet::Expect::Cli implements the methods listed below.

=cut

# required modules
use warnings;
use strict;
use parent qw( Mnet::Expect );
use Carp;
use Mnet::Dump;
use Mnet::Opts::Cli::Cache;
use Time::HiRes;



sub new {

=head2 new

    $expect = Mnet::Expect::Cli->new(\%opts)

This method can be used to create new Mnet::Expect::Cli objects.

The following input opts may be specified, in addition to options documented
in the L<Mnet::Expect> module new method:

    delay           millseconds delay for command prompt detection
    eol_unix        default true for output with unix /n eol chars only
    failed_re       set to speed login failures, disabled by default
    log_login       default undef uses Mnet::Expect log_expect logging
    paging_key      default space key to send for pagination prompt
    paging_re       default handles common prompts, refer to paging_re
    password        set to password for spawned command, if needed
    password_in     stderr prompt for stdin entry of password if not set
    password_re     undef to skip password/code/phrase prompt detection
    prompt_re       undef to disable prompt detect, refer to prompt_re
    timeout         seconds for Expect restart_timeout_upon_receive
    username        set to username for spawned command, if needed
    username_re     undef to skip login/user/username promt detection

    An error is issued if there are login problems.

For example, the following call will start an ssh expect session to a device
with host key checking disabled:

    # refer to SYNOPSIS example for ssh with host/key checks disabled
    my $expect = Mnet::Expect::Cli->new({
        spawn => "ssh user@1.2.3.4", password_in => 1
    });

Set failed_re to detect failed logins faster, as long as there's no conflict
with text that appears in login banners. For example:

    (?i)(closed|error|denied|fail|incorrect|invalid|refused|sorry)

Refer to the L<Mnet::Expect> module for more information.

=cut

    # read input class and options hash ref merged with cli options
    my $class = shift // croak("missing class arg");
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # create log object with input opts hash, cli opts, and pragmas in effect
    #   ensures we can log correctly even if inherited object creation fails
    my $log = Mnet::Log::Conditional->new($opts);
    $log->debug("new starting");

    # create hash that will become new object from input opts hash
    my $self = $opts;

    # note default options for this class
    #   includes recognized cli opts and opts for this object
    #       failed_re default based on educated guess, specifics noted below:
    #           /(closed|error|denied|fail|incorrect|invalid|refused|sorry)/i
    #           junos telnet =~ /^Login incorrent/m
    #       password_re default based on educated guess, specifics noted below:
    #           junos telnet =~ /^Password:$/m
    #       prompt_re default based on educated guess, specifics noted below:
    #           junos telnet =~ /^\S+> $/mi
    #       username_re default based on educated guess, specifics noted below:
    #           junos telnet =~ /^login: $/m
    #   the following keys starting with underscore are used internally:
    #       _command_cache_content => hash ref, refer to _command_cache_clear
    #       _command_cache_counter => integer, refer to _command_cache_clear
    #       _password_ => causes password value to be hidden in opts debug
    #   update perldoc for this sub with changes
    #   refer also to Mnet::Expect defaults
    my $defaults = {
        _command_cache_content => {},
        _command_cache_counter => 0,
        delay       => 250,
        eol_unix    => 1,
        failed_re   => undef,
        log_login   => undef,
        paging_key  => ' ',
        paging_re   => '(--more--|---\(more( \d\d?%)?\)---)',
        password    => undef,
        _password_  => undef,
        password_in => undef,
        password_re => '(?i)pass(code|phrase|word):?\s*(\r|\n)?$',
        prompt_re   => '(^|\r|\n)\S.*(\$|\%|#|:|>) ?(\r|\n|$)',
        record      => undef,
        replay      => undef,
        timeout     => 30,
        username    => undef,
        username_re => '(?i)(login|user(name)?):?\s*(\r|\n)?$',
    };

    # update future object $self hash with default opts
    foreach my $opt (sort keys %$defaults) {
        $self->{$opt} = $defaults->{$opt} if not exists $self->{$opt};
    }

    # debug opts, hide internal opts starting w/underscore, and passowrd
    foreach my $opt (sort keys %$self) {
        if ($opt !~ /^_/) {
            my $value = Mnet::Dump::line($self->{$opt});
            if ($opt eq "password" and defined $self->{$opt}) {
                $value = "**** (redacted)" if $self->{$opt} ne "";
            }
            $log->debug("new opt $opt = $value");
        }
    }

    # warn if timeout is not an even number, as per perldoc Expect
    $log->warn("timeout $self->{timeout} should be even number, as per Expect")
        if $self->{timeout} and $self->{timeout} % 2;

    # set _no_spawn if replay is set so Mnet::Expect skips spawn
    $self->{_no_spawn} = 1 if $self->{replay};

    # call Mnet::Expect to create new object
    $log->debug("new calling Mnet::Expect::new");
    $self = Mnet::Expect::new($class, $self);

    # return undef if new Mnet::Expect object could not be created
    if (not $self) {
        $log->debug("new Mnet::Expect object failed, returning undef");
        return undef;
    }

    # return if we are executing a replay
    if ($self->{replay}) {
        $self->debug("new finished, replay in effect, returning $self");
        return $self;
    }

    # set timeout for complete output stall only, not output completion
    $self->expect->restart_timeout_upon_receive(1);

    # return undef if login does not succeed
    if (not $self->_login) {
        $self->debug("new finished, login failed, returning undef");
        return undef;
    }

    # finished new method, return Mnet::Expect::Cli object
    $self->debug("new finished, returning $self");
    return $self;
}



sub _login {

# $ok = $self->_login
# purpose: used to authenticate expect session
# $ok: set true on success, false on failure

    # read input object
    my $self = shift // die "missing self arg";
    $self->debug("_login starting");

    # if log_level defined then set log_expect for login, note prior log_expect
    my $prior = undef;
    if (defined $self->{log_login}) {
        $prior = $self->log_expect($self->{log_login});
    }

    # if username is set then wait and respond to username_re prompt
    if (defined $self->{username}) {
        _login_expect($self, "username_re");
        $self->expect->send("$self->{username}\r");
    }

    # if password is set then wait and respond to password_re prompt
    #   prompt user for password if password not set and password_in is set
    #   _log_filter used to keep password out of Mnet::Expect->log
    #   reset log_expect level back to it's prior value before returning
    if (defined $self->{password} or $self->{password_in}) {
        _login_expect($self, "password_re");
        my $password = $self->{password};
        if (not defined $password and $self->{password_in}) {
            if ($self->{password_in}) {
                $self->debug("_login password_in prompt starting");
                {
                    local $SIG{INT} = sub { system("stty echo 2>/dev/null") };
                    syswrite STDERR, "\nEnter $self->{password_in}: ";
                    system("stty -echo 2>/dev/null");
                    chomp($password = <STDIN>);
                    system("stty echo 2>/dev/null");
                    syswrite STDERR, "\n";
                };
                $self->debug("_login password_in prompt finished");
            } else {
                $self->fatal("password or password_in required and not set");
                $self->log_expect($prior) if defined $self->{log_login};
                return undef;
            }
        }
        $self->debug("_login sending password");
        $self->{_log_filter} = $password;
        $self->expect->send("$password\r");
    }

    # return true if prompt_re was set undef
    #   clear any password from expect session and clear _log_filter
    #   reset log_expect level back to it's prior value before returning
    if (not defined $self->{prompt_re}) {
        $self->debug("_login detect prompt skipped, prompt_re set undef");
        $self->debug("_login finished, returning true");
        Time::HiRes::usleep($self->{delay}*1000);
        $self->expect->clear_accum;
        $self->{_log_filter} = undef;
        $self->log_expect($prior) if defined $self->{log_login};
        return 1;
    }

    # return true if we can detect command prompt
    #   send a carraige return and ensure we get the same prompt back
    #   clear _log_filter, which may have been set when password was sent
    #   clear expect buffer before sending cr, to flush out banner text, etc
    #   set prompt_re to detected command prompt when finished
    #   reset log_expect level back to it's prior value before returning
    my ($prompt1, $prompt2, $attempts) = ("", "", 3);
    foreach my $attempt (1.. $attempts) {
        $self->debug("_login detect prompt attempt $attempt");
        $prompt1 = _login_expect($self, "prompt_re") // return undef;
        $prompt1 =~ s/(^(\r|\n)|(\r|\n)$)//;
        $self->{_log_filter} = undef;
        if ($prompt1 ne "" and $prompt1 eq $prompt2) {
            $prompt1 =~ s/(\\|\/|\(|\)|\$)/\\$1/g;
            $self->{prompt_re} = '(^|\r|\n)'.$prompt1.'\r?$';
            $self->debug("_login detect prompt_re = /$self->{prompt_re}/");
            $self->debug("_login finished, returning true");
            $self->log_expect($prior) if defined $self->{log_login};
            return 1;
        } else {
            $self->debug("_login detect prompt sending cr");
            Time::HiRes::usleep($self->{delay}*1000);
            $self->expect->clear_accum;
            $self->expect->send("\r");
            $prompt2 = $prompt1;
        }
    }

    # reset log_expect level back to it's prior value before returning
    $self->log_expect($prior) if defined $self->{log_login};

    # finished _login method, return true false for failure
    $self->debug("_login finished, returning false");
    return 0;
}



sub _login_expect {

# $match = _login_expect($self, $re)
#   purpose: wait for specified login prompt, output debug and error messages
#   $self: current Mnet::Expect::Cli object
#   $re: set to keyword username_re, password_re, or prompt_re
#   $match: set to matched $re text, abort on errors
#   note: failed_re is checked for first if set

    # read input object and re args
    my $self = shift // die "missing self arg";
    my $re = shift // die "missing re arg";
    $self->debug("_login_expect starting for $re");

    # expect input username/password/prompt re, also failed_re if defined
    my @matches = ('-re', $self->{$re});
    unshift(@matches, '-re', $self->{failed_re}) if $self->{failed_re};
    my $expect = $self->expect->expect($self->{timeout}, @matches);

    # note match text, and dump of match text for debug logging
    my $match = $self->expect->match;
    my $match_dump = Mnet::Dump::line($match);

    # error if none of the prompts were returned
    if (not $expect) {
        $self->fatal("login timed out waiting for $re");

    # error if failed_re was matched
    } elsif ($self->{failed_re} and $expect == 1) {
        $self->fatal("login failed_re matched $match_dump");
    }

    # finished _login_expect method, return input re match
    $self->debug("_login_expect finished $re, matched $match_dump");
    return $match;
}



sub close {

=head2 close

    $expect->close($command)

This method sends closes the current expect session, sending the optional
input command first. Timeouts are gracefully handled. Refer to the close
method in the L<Mnet::Expect> module for more information.

=cut

    # read input object
    my $self = shift or croak("missing self arg");
    my $command = shift;
    $self->debug("close starting");

    # send command if specified, gracefully handle timeouts
    $self->command($command,  undef, [ "" => undef ]) if defined $command;

    # call parent module close method
    $self->SUPER::close();

    # finished close method
    $self->debug("close finished");
    return;
}



sub command {

=head2 command

    $output = $expect->command($command, $timeout, \@prompts)

This method returns output from the specified command from the current expect
cli session, or undefined if there was a timeout.

The timeout input argument can be used to override the timeout for the current
object.

    # sends $command, uses default timeout, defines some prompts
    my $output = $expect->command($command, undef, [

        # send 1.2.3.4 if matched by expect -re /ip/
        'ip' => '1.2.3.4\r',

        # code ref
        'confirm? ' => sub { my $output = shift; return "y" },

        # returns prior output on timeout, might be undef
        undef => undef,

    ]);

The prompts reference argument can be used to handle prompts that occur after
entering a command, such as confirmation prompts. It should contain pairs of
regex strings and responses. The regex string values should be what goes in
between the forward slash characters of a regular expression. The response can
be a string that is sent to the expect session without a carraige return, or
may be a code reference that gets the current object and output as input args
and returns a response string. An null prompt regex string is activated for
timeouts. An undef prompt response causes an immediate return of output.

Refer also to the command_cache_clear method for more info.

=cut

    # read input arguments
    my $self = shift // croak "missing self arg";
    my $command = shift // croak "missing command arg";
    my $timeout = shift // $self->{timeout};
    my $prompts = shift // [];
    $self->debug("command starting, command '$command' (timeout $timeout)");

    # initialize output
    my $output = undef;

    # set output from _command_cache_content, if it exists in cache
    if (exists $self->{_command_cache_content}->{$command}) {
        $self->debug("command retrieving output from _command_cache_content");
        $output = $self->{_command_cache_content}->{$command};

    # set output from replay data, if replay option is set
    } elsif ($self->{replay}) {
        $self->debug("command retrieving output from replay data");
        my $data = Mnet::Test::data();
        $output = $data->{$self->{_command_cache_counter}}->{$command};

    # retrieve command output from expect session
    } else {
        $self->debug("command retrieving output from _command_expect");
        $output = $self->_command_expect($command, $timeout, $prompts);
        $self->{_command_cache_content}->{$command} = $output;
    }

    # set outut in record data, if record option is set
    if ($self->{record}) {
        my $data = Mnet::Test::data();
        $data->{$self->{_command_cache_counter}}->{$command} = $output;
    }

    # finished command method, return output
    my $output_dbg = "<undef>";
    $output_dbg = length($output)." chars" if defined $output;
    $self->debug("command finished, returning $output_dbg");
    return $output;
}



sub _command_expect {

# $output = $self->_command_expect($command, $timeout, \@prompts)
# purpose: retrieve command output from expect session, refer to command method
# note: command cache, record, and replay, are handled in command sub

    # read inputs, set default timeout from current object
    my $self = shift // die "missing self arg";
    my $command = shift // die "missing command arg";
    my $timeout = shift // $self->{timeout};
    my $prompts = shift // [];

    # return undef if expect session not defined
    return undef if not $self->expect;

    # initialize output to undef
    my $output = undef;

    # store input prompt regexes and responses, also timeout regex/response
    #   timeout prompt is separated because it's not an expect -re like others
    my $prompt_regexes = [];
    my $prompt_responses = [];
    my ($timeout_regex_flag, $timeout_response) = (undef, undef);
    while (@$prompts) {
        my ($regex, $response) = (shift @$prompts, shift @$prompts);
        if ($regex eq "") {
            $timeout_regex_flag = 1;
            $timeout_response = $response;
            $regex = "(null=timeout)";
        } else {
            push @$prompt_regexes, $regex;
            push @$prompt_responses, $response;
        }
        $response = Mnet::Dump::line($response);
        $self->debug("_command_expect input prompt /$regex/ = $response");
    }

    # prepare regexes used for expect call
    #   this includes input prompts, and paging_re if defined
    my $expect_regexes = [];
    push @$expect_regexes, "-re", $_ foreach @$prompt_regexes;
    push @$expect_regexes, "-re", $self->{paging_re} if $self->{paging_re};

    # send input command to expect session
    $self->debug("_command_expect sending $command");
    $self->expect->send("$command\r");

    # loop to collect command output and process input prompts
    while (1) {

        # wait for input prompt regex, or pagination regex and/or prompt regex
        my $expect = $self->expect->expect($timeout,
            @$expect_regexes,
            '-re', $self->{prompt_re},
        );

        # append new output to prior output
        $output .= $self->expect->before;

        # process prompt_response for timeout handled by undef prompt_regex
        #   return prior output if response undef or code ref returning undef
        #   otherwise return undef output
        if (not $expect and $timeout_regex_flag) {
            $self->debug("_command_expect matched prompts null for timeout");
            $self->_command_expect_prompt($timeout_response, $output) // last;
            $output = undef;
            last;

        # process timeout not handled by undef prompt_regex
        #   returns undef output
        } elsif (not $expect) {
            $self->debug("_command_expect timeout");
            $output = undef;
            last;

        # process prompt_response for matched input prompt_regex
        #   return prior output if response undef or code ref returning undef
        } elsif ($expect <= scalar(@$prompt_regexes)) {
            my $regex = $prompt_regexes->[$expect-1];
            $self->debug("_command_expect matched prompts regex /$regex/");
            $output .= $self->expect->match;
            my $prompt_response = $prompt_responses->[$expect-1];
            $self->_command_expect_prompt($prompt_response, $output) // last;

        # process prompt_response for matched paging_re
        #   return prior output if response undef or code ref returning undef
        #   expect paging_key so it doesn't appear in output
        } elsif ($self->{paging_re} and $expect == scalar(@$prompt_regexes)+1) {
            $self->debug("_command_expect matched paging_re");
            $self->_command_expect_prompt($self->{paging_key}, $output) // last;
            $self->expect->expect($timeout, '-re', $self->{paging_key});

        # process prompt_response for matched prompt_re
        #   exit loop if we are not getting any more oupput after a small delay
        #       this allows us to skip prompts that might be embedded in data
        #   otherwise we are getting more data, reset accumulater and continue
        } else {
            $self->debug("_command_expect matched prompt_re");
            my $match = $self->expect->match;
            Time::HiRes::usleep($self->{delay}*1000);
            my $expect = $self->expect->expect(0, '-re', '(\s|\S)+');
            last if not $expect;
            $self->debug("_command_expect prompt_re detected more output");
            $self->expect->set_accum($self->expect->match);
            $output .= $match;
            next;
        }

    # continue loop to collect command output and process input prompts
    }

    # remove echod command from start of output, fix eol chars, remove last eol
    #   normalize eol chars to be unix newlines only if eol_unix opt is set
    if (defined $output) {
        $output =~ s/^\s*\Q$command\E\s*\r?\n?//;
        if ($self->{eol_unix}) {
            $output =~ s/\r\n/\n/g;
            $output =~ s/\r/\n/g;
        }
        $output =~ s/\r$//;
        chomp($output);
    }

    # finished _command_expect, return output
    return $output;
}



sub _command_expect_prompt {

# $ok = $self->_command_expect_prompt($prompt_response)
# purpose: handle prompt_response processing for _command_expect method
# $prompt_response: set undef to return undef, text to send, or code to execute
# $ok: true for caller to continue processing, undef to return current output

    # read inputs
    my $self = shift // die "missing self arg";
    my ($prompt_response, $output) = (shift, shift);

    # return undef for undef prompt response
    if (not defined $prompt_response) {
        $self->debug("_command_expect_prompt response = undef");
        return undef;

    # handle code prompt response, returning undef of sending returned text
    } elsif (ref $prompt_response eq "CODE") {
        $self->debug("_command_expect_prompt code response executing");
        my $code_response = &{$prompt_response}($self, $output);
        if (not defined $code_response) {
            $self->debug("_command_expect_prompt code response = undef");
            return undef;
        } else {
            $self->debug("_command_expect_prompt code response = text");
            $self->expect->send($code_response);
        }

    # handle sending text prompt response
    } else {
        $self->debug("_command_expect_prompt response = text");
        $self->expect->send($prompt_response);
    }

    # finished _command_expect_prompt, return true
    return 1;
}



sub command_cache_clear {

=head2 command_cache_clear

    $expect->command_cache_clear

This method can be used to clear the cache used by the command method.

Normally the the command method caches the outputs for all executed commands,
returning cached output when the same command is executed subsequently. When
the cache is cleared the command method will execute the next instance of any
specific command instead of returning cached output.

=cut

    # clear command cache content and increment counter
    #   cache content is used to return same command output on susequent calls
    #   cache counter is used to to save same command output to replay
    my $self = shift // croak "missing self arg";
    $self->{_command_cache_content} = {};
    $self->{_command_cache_counter}++;
    return;
}



sub delay {

=head2 delay

    $delay = $expect->delay($delay)

Get and/or set a new delay time in milliseconds for the current object. This
delay is used when detecting extra command, prompt, or pagination output.

A good rule of thumb may be to set this delay to at least the round trip
response time for a response from the connected process.

=cut

    # read input object and new delay
    my $self = shift // croak "missing self arg";
    my $delay = shift;

    # set new delay, if defined
    if (defined $delay) {
        $self->debug("delay set = $delay");
        $self->{delay} = $delay;
    }

    # finished, return delay
    return $self->{delay};
}



sub paging_re {

=head2 paging_re

    $paging_re = $expect->paging_re($paging_re)

Get and/or set new paging_re for the current object.

Following are known pagination prompts covered by the default paging_re:

    junos           =~ /^---\(more( \d\d?%)?\)---$/
    cisco ASA       =~ /<--- More --->/
    cisco ios       =~ /--more--/
    cisco ios 15    =~ /--More--/

Following are other observed pagination prompts, not covered by default:

    linux more cmd  =~ /--More--\(\d\d?%\)/

Note that matched pagination text is not appended to command output. Refer also
to the command method in this module for more information.

=cut

    # read input object and new paging_re
    my $self = shift // croak "missing self arg";
    my $paging_re = shift;

    # set new paging_re, if defined
    if (defined $paging_re) {
        $self->debug("paging_re set = $paging_re");
        $self->{paging_re} = $paging_re;
    }

    # finished, return paging_re
    return $self->{paging_re};
}



sub prompt_re {

=head2 prompt_re

    $prompt_re = $expect->prompt_re($prompt_re)

Get and/or set new prompt_re for the current object.

By default prompts that end with $ % # : > are recognized, and the first prompt
detected after login is used as prompt_re for the rest of the expect session.

Note that prompt_re should start with a regex caret symbol and end with a regex
dollar sign, to ensure it works correctly. Also the /Q and /E escape sequences
do not appear to work in an expect regex.

=cut

    # read input object and new prompt_re
    my $self = shift // croak "missing self arg";
    my $prompt_re = shift;

    # set new prompt_re, if defined
    if (defined $prompt_re) {
        $self->debug("prompt_re set = $prompt_re");
        $self->{prompt_re} = $prompt_re;
    }

    # finished, return prompt_re
    return $self->{prompt_re};
}



sub timeout {

=head2 timeout

    $timeout = $expect->timeout($timeout)

Get and/or set a new timeout for the current object, refer to the L<Expect>
module for more information.

=cut

    # read input object and new timeout
    my $self = shift // croak "missing self arg";
    my $timeout = shift;

    # set new timeout, if defined
    if (defined $timeout) {
        $self->debug("timeout set = $timeout");
        $self->{timeout} = $timeout;
    }

    # finished, return timeout
    return $self->{timeout};
}



=head1 TESTING

L<Mnet::Test> --record and --replay command line options are supported by this
module, and will record and replay command method outputs associated with calls
to the command method, integrated with the command_cache_clear method.

Refer to the L<Mnet::Test> module for more information.

=head1 SEE ALSO

L<Expect>

L<Mnet>

L<Mnet::Expect>

L<Mnet::Expect::Cli::Ios>

L<Mnet::Log>

L<Mnet::Opts::Cli>

L<Mnet::Test>

=cut

# normal package return
1;

