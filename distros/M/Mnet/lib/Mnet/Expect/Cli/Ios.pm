package Mnet::Expect::Cli::Ios;

=head1 NAME

Mnet::Expect::Cli::Ios - Expect sessions to cisco ios devices

=head1 SYNOPSIS

    # refer also to Mnet::Expect::Cli
    use Mnet::Expect::Cli::Ios

    # Mnet::Expect::Cli has example with ssh host/key checks disabled
    my $expect = Mnet::Expect::Cli::Ios->new({
        spawn => "ssh user@1.2.3.4", password_in => 1
    });

    # ensure we are in ios enable mode
    $expect->enable() or die "enable failed";

    # get output from command on connected ios device
    my $output = $expect->command("show version");

    # gracefully end/exit ios session
    $expect->close;

=head1 DESCRIPTION

Mnet::Expect::Cli::Ios can be used to spawn L<Expect> processes which can be
used to programmatically control ssh or telnet command line user, enable, and
config sessions to cisco ios and similar devices, with support for L<Mnet>
options, logging, caching, and testing.

Refer also to the L<Mnet::Expect> and L<Mnet::Expect::Cli> modules. The
methods in those modules are inherited by objects created with this module.

=head1 METHODS

Mnet::Expect::Cli::Ios implements the methods listed below.

=cut

# required modules
use warnings;
use strict;
use parent qw( Mnet::Expect::Cli );
use Carp;
use Mnet;
use Mnet::Opts::Cli::Cache;



sub new {

=head2 new

    $expect = Mnet::Expect::Cli::Ios->new(\%opts)

This method can be used to create new Mnet::Expect::Cli::Ios objects.

The following input opts may be specified, in addition to options from
the L<Mnet::Expect::Cli> and L<Mnet::Expect> modules:

    enable          set to password for enable mode during login
    enable_in       stderr prompt for stdin entry of enable if not set
    enable_user     default enable username set from username option
    failed_re       default recognizes lines starting w/ios % error char
    paging_key      default space key to send for ios pagination prompts
    paging_re       default recognizes ios pagination prompt --more--
    prompt_re       defaults for ios user or enable prompts, see below

An error is issued if there are login problems.

For example, the following call will start an ssh expect session to a device,
with a prompt for password input if necessary:

    # refer to SYNOPSIS example and Mnet::Expect::Cli for more info
    my $expect = Mnet::Expect::Cli::Ios->new({
        spawn => "ssh user@1.2.3.4", password_in => 1
    });

Set failed_re to detect failed logins faster, as long as there's no conflict
with text that appears in login banners. For example:

    (?i)(^\s*%|closed|error|denied|fail|incorrect|invalid|refused|sorry)

A default prompt_re regex string for ios devices is used by this method to
detect normal user and enable mode command prompts:

    (^|\r|\n)\S+(>|#) ?(\r|\n|$)

The default ios prompt_re will be adjusted after login to work in various
configuration modes where the prompt may be truncated with various suffixes
applied. This adjustment is disabled if prompt_re exists as an input option
to this function. Refer also to the L<Mnet::Expect::Cli> module new method
for more information on prompt_re.

Refer to the L<Mnet::Expect::Cli> and L<Mnet::Expect> modules for more
information.

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
    #   refer also to Mnet::Expect::Cli defaults, these are overlaid on top
    #   includes recognized cli opts and opts for this object
    #   update perldoc for this sub with changes
    my $defaults = {
        enable      => undef,
        enable_in   => undef,
        enable_user => undef,
        # failed_re default undef to be safe, refer to perldoc for more info
        #   add ios err /^\s*%/ to failed_re values in Mnet::Expect::Cli
        #   failed_re also used in the enable method in this module
        failed_re   => undef,
        paging_key  => ' ',
        paging_re   => '--(M|m)ore--',
        prompt_re   => '(^|\r|\n)\S+(>|#) ?(\r|\n|$)',  # ios user/enable modes
    };

    # set prompt_truncate flag only if prompt_re was not set by caller
    my $prompt_truncate = undef;
    $prompt_truncate = 1 if not exists $opts->{prompt_re};

    # update future object $self hash with default opts
    foreach my $opt (sort keys %$defaults) {
        $self->{$opt} = $defaults->{$opt} if not exists $self->{$opt};
    }

    # debug set opts here, hide internal opts w/name starting w/underscore
    foreach my $opt (sort keys %$self) {
        if ($opt !~ /^_/) {
            my $value = Mnet::Dump::line($self->{$opt});
            $log->debug("new opt $opt = $value");
        }
    }

    # call Mnet::Expect::Cli::new to create new object
    $log->debug("new calling Mnet::Expect::Cli::new");
    $self = Mnet::Expect::Cli::new($class, $self);

    # return undef if Mnet::Expect::Cli object could not be created
    if (not $self) {
        $log->debug("new Mnet::Expect::Cli object failed, returning undef");
        return undef;
    }

    # change detected prompt for configuration modes
    #   prompt_truncate is set only if prompt_re was not set by caller
    #   note that this cannot be done reliably with user supplied prompt_re
    #   regex here needs to match prompt_re changes in Mnet::Expect::Cli->new
    #   refer also to perldoc for this sub
    if ($prompt_truncate) {
        $log->debug("new prompt_truncate adjusting default ios prompt");
        my $prompt_re = $self->prompt_re;
        if ($self->prompt_re =~ /^(\([^\)]+\))(\S+)((>|#)\s?\\r\?\$)$/) {
            my ($beginning, $middle, $end) = ($1, $2, $3);
            $middle = substr($middle, 0, 5).'\S+' if length($middle) > 5;
            my $prompt_new = $beginning . $middle . $end;
            $self->prompt_re($prompt_new);
        }
    }

    # change detected prompt to ensure it works in different ios modes
    #   need to work in user, enable, config, interface config, etc
    #   also needs to work if long hostname in prompt gets truncated
    $self->debug("new updateing prompt for both enable and user modes");
    my $prompt_re = $self->prompt_re;
    $prompt_re =~ s/(>|#)/(>|#)/;
    $self->prompt_re($prompt_re);

    # call enable method if enable or enable_in option is set
    $self->enable if defined $self->{enable} or $self->{enable_in};

    # finished new method, return Mnet::Expect::Cli::Ios object
    $self->debug("new finished, returning $self");
    return $self;
}



sub enable {

=head2 enable

    $boolean = $expect->enable($password)

Use this method to check if an ios device session is currently in enable mode,
and/or to enter enable mode on the device.

The input password argument will be used if there is an enable password prompt,
otherwise the enable option set for the current object will be used, or the
user will be prompted if the enable_in option is set.

A fatal error is issued if an enable password is required and none is set.

A value of true is returned if the ios device is at an enable mode command
prompt, otherwise a value of false is returned.

=cut

    # read input object, password, and username args
    #   set undefined enable password and username args from object option
    my $self = shift or croak("missing self arg");
    my $password = shift // $self->{enable};
    my $username = shift // $self->{username};
    $self->debug("enable starting");

    # send enable comand
    #   return output if we receive normal cisco enable# prompt
    #   return output if we receive an % ios error
    #   send username if prompted for user or username
    #       return output if replay option is set
    #       return output if enable_user or username is not set
    #   send password if prompted for password_re
    #       return output if replay option is set
    #       prompt stderr/stdin for undef password if enable_in is set
    #       _log_filter is used to keep password out of Mnet::Expect->log
    #   return output if we get anything that matches prompt_re
    my $output = $self->command("enable", undef, [
        '#'  => undef,
        '\%' => undef,
        '(?i)\s*user(name)?:?\s*$' => sub {
            my ($self, $output) = (shift, shift);
            return undef if $self->{replay};
            if (defined $self->{enable_user}) {
                $self->debug("enable sending enable_user");
                return "$self->{enable_user}\r";
            } elsif (defined $self->{username}) {
                $self->debug("enable sending username");
                return "$self->{username}\r";
            }
            return undef;
        },
        $self->{password_re} => sub {
            my ($self, $output) = (shift, shift);
            return undef if $self->{replay};
            if (not defined $password) {
                if ($self->{enable_in}) {
                    $self->debug("enable enable_in prompt starting");
                    {
                        local $SIG{INT} = sub {
                            system("stty echo 2>/dev/null")
                        };
                        syswrite STDERR,
                            "\nEnter enable $self->expect->match: ";
                        system("stty -echo 2>/dev/null");
                        chomp($password = <STDIN>);
                        system("stty echo 2>/dev/null");
                        syswrite STDERR, "\n";
                    };
                    $self->debug("enable enable_in prompt finished");
                } else {
                    $self->fatal("enable or enable_in required and not set");
                }
            }
            $self->debug("enable sending enable password");
            $self->{_log_filter} = $password;
            return "$password\r";
        },
        $self->{prompt_re} => undef,
    ]);

    # return true if we confirmed we are at an enable prompt
    if (defined $output and $output =~ /#/) {
        $self->debug("enable finished, returning true");
        return 1;
    }

    # finished enable method, return true
    $self->debug("enable finished, returning false");
    return 0;
}



sub close {

=head2 close

    $expect->close

This method sends the end and exit ios commands before closing the current
expect session. Timeouts are gracefully handled. Refer to the close method
in the L<Mnet::Expect::Cli> module for more information.

=cut

    # read input object
    my $self = shift or croak("missing self arg");
    $self->debug("close starting");

    # send the end command, might be necessary on some platforms
    #   gracefully handle any timeout when sending this command
    $self->command("end",  undef, [ "" => undef ]);

   # call parent module close method
    $self->SUPER::close("exit");

    # finished close method
    $self->debug("close finished");
    return;
}



=head1 TESTING

L<Mnet::Test> --record and --replay functionality are supported. Refer to the
TESTING perldoc section of L<Mnet::Expect::Cli> module for more information.

=head1 SEE ALSO

L<Expect>

L<Mnet>

L<Mnet::Expect>

L<Mnet::Expect::Cli>

L<Mnet::Log>

L<Mnet::Opts::Cli>

L<Mnet::Test>

=cut

# normal package return
1;

