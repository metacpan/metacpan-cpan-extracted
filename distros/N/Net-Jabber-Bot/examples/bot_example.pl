#!perl

use strict;
use warnings;

use Getopt::Euclid; # Uses POD at bottom of file to auto-parse ARGV.
use Log::Log4perl qw(:easy); # Also gives additional debug info back from bot.
use Net::Jabber::Bot;

# Init log4perl based on command line options
my %log4perl_init;
$log4perl_init{'cron'}     = 1 if(defined $ARGV{'-cron'});
$log4perl_init{'nostdout'} = 1 if(defined $ARGV{'-nostdout'});
$log4perl_init{'log_file'} = $ARGV{'-logfile'} if(defined $ARGV{'-logfile'});
$log4perl_init{'email'} = $ARGV{'-email'} if(defined $ARGV{'-email'});
$log4perl_init{'debug_level'} = $ARGV{'-debuglevel'};
InitLog4Perl(%log4perl_init);

my $bot_forum1 = "test_forum";       # Forum the bot will monitor
my $bot_forum2 = "other_test_forum"; # Second forum just to show it's possible.
my @forums = ($bot_forum1, $bot_forum2);
my $alias = "perl_bot"; # Who I will show up as in the forum

my %alerts_sent_hash;
my %next_alert_time_hash;
my %next_alert_increment;

my %forums_and_responses;
foreach my $forum (@forums) {
    my $responses = "bot:|hey you|"; # Note the pipe at the end indicates it will act on all messages
    my @response_array = split(/\|/, $responses);
    push @response_array, "" if($responses =~ m/\|\s*$/);
    $forums_and_responses{$forum} = \@response_array;
}

my $bot = Net::Jabber::Bot->new({
                                 server => $ARGV{'-server'}
                                , conference_server => $ARGV{'-conference_server'}
                                , port => $ARGV{'-port'}
                                , username => $ARGV{'-user'}
                                , password => $ARGV{'-pass'}
                                , alias => $alias
                                , message_callback => \&new_bot_message   # Called if new messages arrive.
                                , background_activity => \&background_checks # What the bot does outside jabber.
                                , loop_sleep_time => 20 # Minimum time before doing background function.
                                , process_timeout => 5 # Time to wait for new jabber messages before timing out
                                , forums_and_responses => \%forums_and_responses
                                , ignore_server_messages => 1 # Usually you don't care about admin messages from the server
                                , ignore_self_messages => 1 # Usually you don't want to see your own messages
                                , out_messages_per_second => 5 # Maximum messages allowed per second (server flood throttling)
                                , max_message_size => 1000 # Maximum byte size of the message before we chop it into pieces
                                , max_messages_per_hour => 1000 # Keep the bot from going out of control with noisy messages 
                            });


foreach my $forum (@forums) {
    $bot->SendGroupMessage($forum, "$alias logged into forum $forum");
}

$bot->Start(); #Endless loop where everything happens after initialization.

DEBUG("Something's gone horribly wrong. Jabber bot exiting...");
exit;


# This sub is called every 20 seconds (configurable) by the bot so it can do background activity
sub background_checks {
    my $bot= shift;
    my $counter = shift;

    check_a_file();
    monitor_a_web_page();
}

sub new_bot_message {
	my %bot_message_hash = @_;

    # Who to speak to if you need to.
    $bot_message_hash{'sender'} = $bot_message_hash{'from_full'};
    $bot_message_hash{'sender'} =~ s{^.+\/([^\/]+)$}{$1};

	my($command, @options) = split(' ', $bot_message_hash{body});
	$command = lc($command);
	
    my %command_actions;
    $command_actions{'subject'}  = \&bot_change_subject;
    $command_actions{'nslookup'} = \&bot_nslookup;
	$command_actions{'say'}      = \&bot_say;
	$command_actions{'help'}     = \&bot_help;
	$command_actions{'unknown_command_passed'} = \&bot_unknown_command;
                          
	if(defined $command_actions{$command}) {
		$command_actions{$command}->(\%bot_message_hash, @options);
	} else {
		$command_actions{'unknown_command_passed'}->(\%bot_message_hash, @options);
	}
}

sub bot_change_subject {
    my %bot_message_hash = %{shift @_};
    my $new_subject = join " ", @_;
    
    my $bot_object = $bot_message_hash{bot_object};
    my $reply_to   = $bot_message_hash{reply_to};
    
    if($bot_message_hash{type} ne 'groupchat') {
        $bot_object->SendJabberMessage($reply_to
                                       , "Sorry, I can't change subject outside a forum!"
                                       , $bot_message_hash{type});
        WARN("Denied subject change from $reply_to ($new_subject)");
        return;
    }

    $bot_object->SendGroupMessage($reply_to, "Setting Forum subject to: $new_subject");
    $bot_object->SetForumSubject($reply_to, $new_subject);
    return;
}

sub bot_nslookup {
    my %bot_message_hash = %{shift @_};
    my $host = CleanInput(shift @_);

    my $bot_object = $bot_message_hash{bot_object};
    my $reply_to   = $bot_message_hash{reply_to};

	if(!defined $host) {
	    $bot_object->SendJabberMessage($reply_to
                                       , "Stop screwing around $bot_message_hash{sender}!"
                                       , $bot_message_hash{type});
	    return;
	}

    my $output = `/usr/sbin/nslookup $host 2>&1`;
    $bot_object->SendJabberMessage($reply_to, $output, $bot_message_hash{type});
    
}


sub bot_say {
    my %bot_message_hash = %{shift @_};
    my $to_say = join " ", @_;
    
    my $bot_object = $bot_message_hash{bot_object};

    $bot_object->SendJabberMessage($bot_message_hash{reply_to}
                                   , $to_say
                                   , $bot_message_hash{type});
}

sub bot_help {
    my %bot_message_hash = %{shift @_};
    my @options = @_;
    
    my $bot_object = $bot_message_hash{bot_object};
    my $reply_to   = $bot_message_hash{reply_to};
    my $message_type = $bot_message_hash{type};

    $bot_object->SendJabberMessage($reply_to
                                   ,  "I know how to do the following: nslookup <host>, say, "
                                    . "subject <new sub>"
                                   , $message_type);
}

sub bot_unknown_command {
    my %bot_message_hash = %{shift @_};
    my @options = @_;
    
    my $bot_object = $bot_message_hash{bot_object};
    my $reply_to   = $bot_message_hash{reply_to};
    my $message_type = $bot_message_hash{type};

    # Don't get confused about vague addresses empty messages
    return if(length $bot_message_hash{bot_address_from} <= 2);

    $bot_object->SendJabberMessage($reply_to
                                   , "Sorry $bot_message_hash{sender}, I don't know what you're asking me."
                                   , $message_type);
}

                           
sub CleanInput {
    my $string = shift;
    my $revised_string = $string;

    $revised_string =~ s{[\>\<\&\n\r;]}{}g; # Strip things that would allow enhanced commands.
    $revised_string =~ s/[^ -~]//g; #Strip out anything that's not a printable character

    return if($string ne $revised_string); # Error!
    return $string;
}


sub InitLog4Perl {
    my(%tag_hash) = @_;

    my $config_file = '';

    my $debug_level = 'DEBUG';
    $debug_level = $tag_hash{debug_level}
        if(defined $tag_hash{debug_level});
    my $log_to_line = "log4perl.category = $debug_level";

    my $layout = '%d %p (%L): %m%n';
    $layout = $tag_hash{layout}
        if(defined $tag_hash{layout});

    if(!-t STDOUT && !defined $tag_hash{cron}) {
        confess("You have run this program from cron but not acknowledged to log4perl that this is the case. I don't know where to send output!");
    }

    # Unless explicitly stated, we will send to STDOUT.
    if(!defined $tag_hash{nostdout}) {
        $config_file .= <<"CONFIG_DATA";
# Regular Screen Appender
log4perl.appender.Screen           = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr    = 0
log4perl.appender.Screen.layout    = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = $layout
CONFIG_DATA
    $log_to_line .= ", Screen";
    }

    if(defined $tag_hash{'log_file'}) {
        $config_file .= <<"CONFIG_DATA";
log4perl.appender.Log          = Log::Log4perl::Appender::File
log4perl.appender.Log.filename = $tag_hash{log_file}
log4perl.appender.Log.mode     = append
log4perl.appender.Log.layout   = PatternLayout
log4perl.appender.Log.layout.ConversionPattern = $layout
CONFIG_DATA
    $log_to_line .= ", Log";
    }

    if(defined $tag_hash{'email_to'}) {
        $config_file .= <<"CONFIG_DATA";
log4perl.appender.Mailer         = Log::Dispatch::Email::MailSendmail
log4perl.appender.Mailer.to      = $tag_hash{email_to}
log4perl.appender.Mailer.subject = Log4Perl: $0 error message.
log4perl.appender.Mailer.layout   = PatternLayout
log4perl.appender.Mailer.layout.ConversionPattern = $layout
log4perl.appender.Mailer.buffered = 0
CONFIG_DATA
    $log_to_line .= ", Mailer";
    }

    $config_file .= "$log_to_line\n";
#    print "***\n$config_file***\n";

    Log::Log4perl->init(\$config_file);
    $| = 1; #unbuffer stdout!
}

__END__

=head1 USAGE
    Euclid auto-generates this. Run program with --help for usage.

=head1 VERSION

    VERSION 1.0


=head1 NAME

$0 - Example bot to show how to use the module.

=head1 REQUIRED ARGUMENTS

=over 

=item -server <host>

=for Euclid
    host.type: string

=item -conference_server <host>

=for Euclid
    host.type: string

=item -user <username>

=for Euclid
    username.type: string

=item -pass <password>

=for Euclid
    password.type: string

=back

=head1 OPTIONS

=over

=item  -port <port_num>

    port number (defaults to 5222)

=for Euclid
    port_num.type: int > 0
    port_num.default: 5222

=item  -log[file] <file>

    Where to log to file

=for Euclid
    file.type: writeable
    file.type.error: Cannot write to file <file>. Please check permissions!

=item -nostdout

Turn off STDOUT

=item -cron

Indicate this program is running from cron.

=item -debug[level] <level>

    Set debug level (DEBUG INFO WARN ERROR FATAL ALL OFF)

    Defaults to INFO

=for Euclid:
    level.type:    string, level =~ /DEBUG|INFO|WARN|ERROR|FATAL|ALL|OFF$/
    level.default: "INFO"

=item -exiton <level>

    Exit if this level of message is detected (DEBUG INFO WARN ERROR FATAL ALL OFF)

    Defaults to OFF

=for Euclid:
    level.type:    string, level =~ /DEBUG|INFO|WARN|ERROR|FATAL|ALL|OFF$/
    level.default: "OFF"

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

Bot code to show how to use the bot

=head1 AUTHOR

Todd Rinaldo, Robert Boone, Wade Johnson (perl-net-jabber-bot@googlegroups.com)

=head1 BUGS

Send Bug Reports to perl-net-jabber-bot@googlegroups.com
or submit them yourself at: http://code.google.com/p/perl-net-jabber-bot/issues/list/entry

