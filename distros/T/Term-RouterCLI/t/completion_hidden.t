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
print "# The user types in \"su\" and presses <TAB> once. Command is found,   #\n";
print "# we should print out nothing                                        #\n";
print "######################################################################\n";
$sStringToComplete = "su";
$sCompleteRawline = "su";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'su';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['su'];
&RUN_TEST();
&RESET_TEST;

print "\n";
print "######################################################################\n";
print "# Completion Test 2                                                  #\n";
print "# The user types in \"su\" and presses <TAB> twice. Command is found,  #\n";
print "# we should print out commands at parent level                       #\n";
print "######################################################################\n";
$sStringToComplete = "";
$sCompleteRawline = "su";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'su';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['su'];
&RUN_TEST();
&RESET_TEST;

print "\n";
print "######################################################################\n";
print "# Completion Test 3                                                  #\n";
print "# The user types in \"tes\" and presses <TAB> once. Command is found,  #\n";
print "# we should complete to testnothidden                                #\n";
print "######################################################################\n";
$sStringToComplete = "tes";
$sCompleteRawline = "tes";
sub test {$cli->_CompletionFunction($sStringToComplete, $sCompleteRawline, 0); }
stdout_is(\&test, "\n",                                              'verify output to screen');
$sCommandTokens = 'testnothidden';
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'testnothidden'};
$aFullCommandName = ['testnothidden'];
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
        "support"  => {
            desc    => "support command",
            help    => "This will change the hostname",
            maxargs => 1,
            minargs => 0,
            hidden  => 1,
            code    => sub { "this is support" },
        },
        "test"  => {
            desc    => "support command",
            help    => "This will change the hostname",
            maxargs => 1,
            minargs => 0,
            hidden  => 1,
            code    => sub { "this is support" },
        },
        "testnothidden"  => {
            desc    => "support command",
            help    => "This will change the hostname",
            maxargs => 1,
            minargs => 0,
            code    => sub { "this is support" },
        },
    };
    return($hash_ref);
}
