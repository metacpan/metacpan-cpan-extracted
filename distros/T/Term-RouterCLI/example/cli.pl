#!/usr/bin/perl


use lib "../lib/";
use strict;
use Term::RouterCLI;
use UserExec;



my $cli = new Term::RouterCLI( _sConfigFilename => 'etc/RouterCLI.conf', _sDebuggerConfigFilename => 'etc/log4perl.conf' );


my $lang = new Term::RouterCLI::Languages();
$lang->SetLangDirectory('./lang/');

# Load initial command tree
$cli->CreateCommandTree(&UserExec::CommandTree($cli));
$cli->SetHistoryFileLength("10");
$cli->SetAuditLogFileLength("10");
#$cli->PreventEscape();
#$cli->ClearScreen();
$cli->PrintMOTD();
$cli->StartCLI();
$cli->SaveConfig();

