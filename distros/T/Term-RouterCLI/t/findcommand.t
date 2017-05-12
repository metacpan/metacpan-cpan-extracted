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
# UnitTest:    findcommand.t                                        #
# Description: Unit test and verification of the method             #
#              _FineCommandInCommandTree                            #
#                                                                   #
# Written by:  Bret Jordan (jordan at open1x littledot org)         #
# Created:     2011-04-12                                           #
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

my $hCommandTree        = undef;
my $hCommandTreeAtLevel = undef;
my $hCommandDirectives  = undef;
my $aFullCommandName    = undef;
my $aCommandArguments   = undef;


print "\n";
print "######################################################################\n";
print "# Find Test 1.0                                                      #\n";
print "# Lookup \"hist\"                                                      #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['hist'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree;
$hCommandDirectives = {};
$aFullCommandName = [];
$aCommandArguments = ['hist'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.0                                                      #\n";
print "# Lookup \"sh\"                                                        #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['sh'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'};
$aFullCommandName = ['show'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.1                                                      #\n";
print "# Lookup \"show\"                                                      #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['show'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'};
$aFullCommandName = ['show'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.2                                                      #\n";
print "# Lookup \"show hist\"                                                 #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['show', 'hist'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'};
$aFullCommandName = ['show'];
$aCommandArguments = ['hist'];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.3                                                      #\n";
print "# Lookup \"show int\"                                                  #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['show', 'int'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'}->{'interface'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'}->{'cmds'}->{'interface'};
$aFullCommandName = ['show', 'interface'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.4                                                      #\n";
print "# Lookup \"sh int\"                                                    #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['sh', 'int'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'}->{'interface'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'}->{'cmds'}->{'interface'};
$aFullCommandName = ['show', 'interface'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.5                                                      #\n";
print "# Lookup \"show int eth\"                                              #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['show', 'int', 'eth'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'show'}->{'cmds'}->{'interface'}->{'cmds'}->{'eth0'};
$aFullCommandName = ['show', 'interface', 'eth0'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.6                                                      #\n";
print "# Lookup \"sh int eth\"                                                #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['sh', 'int', 'eth'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'show'}->{'cmds'}->{'interface'}->{'cmds'}->{'eth0'};
$aFullCommandName = ['show', 'interface', 'eth0'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 2.7                                                      #\n";
print "# Lookup \"show interface eth0\"                                       #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['show', 'interface', 'eth0'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = {};
$hCommandDirectives = $hCommandTree->{'show'}->{'cmds'}->{'interface'}->{'cmds'}->{'eth0'};
$aFullCommandName = ['show', 'interface', 'eth0'];
$aCommandArguments = [];
&RUN_TEST();
&RESET_TEST;


print "\n";
print "######################################################################\n";
print "# Find Test 3.0                                                      #\n";
print "# Lookup \"show hist eth\"                                             #\n";
print "######################################################################\n";
$cli->{_aCommandTokens} = ['show', 'hist', 'eth'];
$cli->_FindCommandInCommandTree();
$hCommandTree = &TestCommandTree();
$hCommandTreeAtLevel = $hCommandTree->{'show'}->{'cmds'};
$hCommandDirectives = $hCommandTree->{'show'};
$aFullCommandName = ['show'];
$aCommandArguments = ['hist', 'eth'];
&RUN_TEST();
&RESET_TEST;

done_testing();

sub RESET_TEST
{
    $cli->RESET();
    $hCommandTree        = undef;
    $hCommandTreeAtLevel = undef;
    $hCommandDirectives  = undef;
    $aFullCommandName    = undef;
    $aCommandArguments   = undef;
}

sub RUN_TEST
{
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
        },
        "show"  => {
            desc    => "show commands",
            help    => "help for show commands",
            cmds => {
                "interface" => {
                    desc => "show int commands",
                    help  => "help for show int commands",
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
