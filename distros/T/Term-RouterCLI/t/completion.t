#!/usr/bin/perl
#####################################################################
# This program is not guaranteed to work at all, and by using this  #
# program you release the author of any and all liability.          #
#                                                                   #
# You may use this code as long as you are in compliance with the   #
# license (see the LICENSE file) and this notice, disclaimer and    #
# comment box remain intact and unchanged.                          #
#                                                                   #
# Package:     Term::RouterCLI                                      #
# UnitTest:    completion.t                                         #
# Description: Unit test and verification of the method             #
#              _CompletionFunction                                  #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-09                                           #
##################################################################### 
#
#
#
#

use lib "lib/";
use strict;
use Term::RouterCLI;
use Test::More;
use Test::Output;



my $cli = new Term::RouterCLI( _sConfigFilename => 'example/etc/RouterCLI.conf', _sDebuggerConfigFilename => 'example/etc/log4perl.conf' );
$cli->SetOutput();
$cli->CreateCommandTree(&TestCommandTree());

# Verify creation of object and setting inital parameters
ok( defined $cli,                                                   'verify new() created an object' );


my $sStringToComplete   = undef;
my $sCompleteRawline    = undef;
my $sCommandTokens      = undef;
my $hCommandTree        = undef;
my $hCommandTreeAtLevel = undef;
my $hCommandDirectives  = undef;
my $aFullCommandName    = undef;
my $aCommandArguments   = undef;
my $sAllCommandSummaries = undef;



print "\n";
print "######################################################################\n";
print "# Completion Test 1                                                  #\n";
print "# The user has pressed <TAB> once at any empty prompt, we should     #\n";
print "# print out all avaliable commands                                   #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
$sAllCommandSummaries .= sprintf("  %-20s enable command\n", "enable");
$sAllCommandSummaries .= sprintf("  %-20s exit command\n", "exit");
$sAllCommandSummaries .= sprintf("  %-20s help command\n", "help");
$sAllCommandSummaries .= sprintf("  %-20s hostname command\n", "hostname");
$sAllCommandSummaries .= sprintf("  %-20s show commands\n", "show");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = '';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;

 
print "\n";
print "######################################################################\n";
print "# Completion Test 2                                                  #\n";
print "# The user types in \"ex\" and presses <TAB> once. Command is found,   #\n";
print "# we should print out nothing                                        #\n";
print "######################################################################\n";
$sStringToComplete = "ex";
$sCompleteRawline = "ex";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'exit';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'exit'};
$aFullCommandName = ['exit'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 3                                                  #\n";
print "# The user types in \"exit\" and presses <TAB> once. Command is found, #\n";
print "# we should print out nothing                                        #\n";
print "######################################################################\n";
$sStringToComplete = "exit";
$sCompleteRawline = "exit";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'exit';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'exit'};
$aFullCommandName = ['exit'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 4                                                  #\n";
print "# The user types in \"exit\" and presses <TAB> twice. Command is found,#\n";
print "# we should print out <cr>                                           #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "exit";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 5); }
$sAllCommandSummaries .= sprintf("  %-20s\n", "<cr>");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = 'exit';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'exit'};
$aFullCommandName = ['exit'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;

 
print "\n";
print "######################################################################\n";
print "# Completion Test 5                                                  #\n";
print "# The user types in \"e\" and presses <TAB> once. Mulitple command     #\n";
print "# matches are found, we should print out just those options          #\n";
print "######################################################################\n";
$sStringToComplete = "e";
$sCompleteRawline = "e";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
$sAllCommandSummaries .= sprintf("  %-20s enable command\n", "enable");
$sAllCommandSummaries .= sprintf("  %-20s exit command\n", "exit");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = 'e';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['e'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 6                                                  #\n";
print "# The user types in \"e\" and presses <TAB> twice. Mulitple command    #\n";
print "# matches are found, we should print out just those options          #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "e";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
$sAllCommandSummaries .= sprintf("  %-20s enable command\n", "enable");
$sAllCommandSummaries .= sprintf("  %-20s exit command\n", "exit");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = 'e';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['e'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 7                                                  #\n";
print "# The user types in \"goo\" and presses <TAB> once. Command is not     #\n";
print "# found, we should print nothing                                     #\n";
print "######################################################################\n";
$sStringToComplete = "goo";
$sCompleteRawline = "goo";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'goo';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['goo'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 8                                                  #\n";
print "# The user types in \"goo\" and pressess <TAB> twice. Command is not   #\n";
print "# found, we should print nothing                                     #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "goo";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'goo';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['goo'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 9                                                  #\n";
print "# The user types in \"hostname switch\" and pressess <TAB> once.       #\n";
print "# Command is found with an argument, we should print nothing         #\n";
print "######################################################################\n";
$sStringToComplete = "switch";
$sCompleteRawline = "hostname switch";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 9); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'hostname';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'hostname'};
$aFullCommandName = ['hostname'];
$aCommandArguments = ['switch'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 10                                                 #\n";
print "# The user types in \"hostname switch \" and pressess <TAB> once.      #\n";
print "# Command is found with an argument, we should print <cr>            #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "hostname switch";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 9); }
$sAllCommandSummaries .= sprintf("  %-20s unknown\n", "WORD");
$sAllCommandSummaries .= sprintf("  %-20s\n", "<cr>");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = 'hostname';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'hostname'};
$aFullCommandName = ['hostname'];
$aCommandArguments = ['switch'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 11                                                 #\n";
print "# The user types in \"help sh\" and pressess <TAB> once.               #\n";
print "# Command is found with an argument, we should print <cr>            #\n";
print "######################################################################\n";
$sStringToComplete = "sh";
$sCompleteRawline = "help sh";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 5); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'show';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'help'};
$aFullCommandName = ['help'];
$aCommandArguments = ['show'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Completion Test 12                                                 #\n";
print "# The user types in \"help sh\" and pressess <TAB> twice.              #\n";
print "# Command is found with an argument, we should print <cr>            #\n";
print "######################################################################\n";
$sStringToComplete = "show";
$sCompleteRawline = "help show";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 5); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'show';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'help'};
$aFullCommandName = ['help'];
$aCommandArguments = ['show'];
&RUN_TEST();
&RESET_TEST;

print "\n";
print "######################################################################\n";
print "# Completion Test 13                                                 #\n";
print "# The user types in \"help show \" and pressess <TAB> once.            #\n";
print "# Command is found with an argument, we should print <cr>            #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "help show";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 5); }
$sAllCommandSummaries .= sprintf("  %-20s\n", "<cr>");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = 'show';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'help'};
$aFullCommandName = ['help'];
$aCommandArguments = ['show'];
&RUN_TEST();
&RESET_TEST;

print "\n";
print "######################################################################\n";
print "# Completion Test 14                                                 #\n";
print "# The user types in \"show interface \" and pressess <TAB> once.       #\n";
print "# Command is found with an argument                                  #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "show interface";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 5); }
$sAllCommandSummaries .= sprintf("  %-20s enter interface name\n", "WORD");
$sAllCommandSummaries .= sprintf("  %-20s (no description)\n", "eth0");
$sAllCommandSummaries .= sprintf("  %-20s (no description)\n", "wan0");
$sAllCommandSummaries .= sprintf("  %-20s\n", "<cr>");
stdout_is(\&test, "\n$sAllCommandSummaries",      'verify output to screen');
$sCommandTokens = 'show';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'}->{'interface'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'}->{'cmds'}->{'interface'};
$aFullCommandName = ['show', 'interface'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;



done_testing();

sub RESET_TEST
{
    $cli->RESET();
    $sStringToComplete   = undef;
    $sCompleteRawline    = undef;
    $sCommandTokens      = undef;
    $hCommandTree        = undef;
    $hCommandTreeAtLevel = undef;
    $hCommandDirectives  = undef;
    $aFullCommandName    = undef;
    $aCommandArguments   = undef;
    $sAllCommandSummaries = undef;
}

sub RUN_TEST
{
    is($cli->{_sStringToComplete}, "$sStringToComplete",                "verify variable _sStringToComplete" );
    is($cli->{_sCompleteRawline}, "$sCompleteRawline",                  "verify variable _sCompleteRawline" );
    is(${$cli->{_aCommandTokens}}[0], "$sCommandTokens",                "verify variable _aCommandTokens" );
    is_deeply( $cli->{_hCommandTreeAtLevel}, $hCommandTreeAtLevel,      "verify command tree hash" );
    is_deeply( $cli->{_hCommandDirectives}, $hCommandDirectives,        "verify command directives hash" );
    is_deeply( $cli->{_aFullCommandName}, $aFullCommandName,            "verify full command name array" );
    is_deeply( $cli->{_aCommandArguments}, $aCommandArguments,          "verify command arguments array" );
}



sub TestCommandTree {
    my $hash_ref = {};
    $hash_ref = {
        "exit"  => {
            desc    => "exit command",
            help    => "help for exit command",
            code    => "exit this command"
        },
        "enable"  => {
            desc    => "enable command",
            help    => "help for exit command",
        },
        "help"  => {
            desc    => "help command",
            help    => "help for help command",
            args    => sub { shift->TabCompleteArguments(); }, 
            code    => sub { shift->PrintHelp(); }
        },
        "hostname"  => {
            desc    => "hostname command",
            help    => "help for hostname command",
            maxargs => 1,
            minargs => 1,
            args    => "[string]",
            code    => sub { "this is hostname" },
        },
        "support"  => {
            desc    => "support command",
            help    => "This will change the hostname",
            maxargs => 1,
            minargs => 1,
            hidden  => 1,
            code    => sub { "this is support" },
        },
        "show"  => {
            desc    => "show commands",
            help    => "help for show commands",
            cmds => {
                "interface" => {
                    desc => "show int commands",
                    help => "help for show int commands",
                    maxargs => 1,
                    argdesc => "enter interface name",
                    code => sub { "this is interface" },
                    cmds => {
                        "eth0" => { code => "eth0 works" },
                        "wan0" => { code => "wan0 works" },
                    },
                },
            },
        },
    };
    return($hash_ref);
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  õIËàêPÓwïHœj>j" );
}



sub TestCommandTree {
    my $hash_ref = {};
    $hash_ref = {
        "exit"  => {
            desc    => "exit command",
            help    => "help for exit command",
            code    => "exit this command"
        },
        "enable"  => {
            desc    => "enable command",
            help    => "help for exit command",
        },
        "help"  => {
            desc    => "help command",
            help    => "help for help command",
            args    => sub { shift->TabCompleteArguments(); }, 
            code    => sub { shift->PrintHelp(); }
        },
        "hostname"  => {
            desc    => "hostname command",
            help    => "help for hostname command",
            maxargs => 1,
            minargs => 1,
            args    => "[string]",
            code    => sub { "this is hostname" },
        },
        "support"  => {
            desc    => "support command",
            help    => "This will change the hostname",
            maxargs => 1,
            minargs => 1,
            hidden  => 1,
            code    => sub { "this is support" },
        },
        "show"  => {
            desc    => "show commands",
            help    => "help for show commands",
            cmds => {
                "interface" => {
                    desc => "show int commands",
                    help => "help for show int commands",
                    maxargs => 1,
                    argdesc => "enter interface name",
                    code => sub { "this is interface" },
                    cmds => {
                        "eth0" => { code => "eth0 works" },
                        "wan0" => { code => "wan0 works" },
                    },
                },
            },
        },
    };
    return($hash_ref);
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  »
?ŠÛ"‹%…ñ±|_W" );
}



sub TestCommandTree {
    my $hash_ref = {};
    $hash_ref = {
        "exit"  => {
            desc    => "exit command",
            help    => "help for exit command",
            code    => "exit this command"
        },
        "enable"  => {
            desc    => "enable command",
            help    => "help for exit command",
        },
        "help"  => {
            desc    => "help command",
            help    => "help for help command",
            args    => sub { shift->TabCompleteArguments(); }, 
            code    => sub { shift->PrintHelp(); }
        },
        "hostname"  => {
            desc    => "hostname command",
            help    => "help for hostname command",
            maxargs => 1,
            minargs => 1,
            args    => "[string]",
            code    => sub { "this is hostname" },
        },
        "support"  => {
            desc    => "support command",
            help    => "This will change the hostname",
            maxargs => 1,
            minargs => 1,
            hidden  => 1,
            code    => sub { "this is support" },
        },
        "show"  => {
            desc    => "show commands",
            help    => "help for show commands",
            cmds => {
                "interface" => {
                    desc => "show int commands",
                    help => "help for show int commands",
                    maxargs => 1,
                    argdesc => "enter interface name",
                    code => sub { "this is interface" },
                    cmds => {
                        "eth0" => { code => "eth0 works" },
                        "wan0" => { code => "wan0 works" },
                    },
                },
            },
        },
    };
    return($hash_ref);
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  