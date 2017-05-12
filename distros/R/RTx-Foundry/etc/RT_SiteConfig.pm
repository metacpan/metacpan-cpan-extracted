package RT;

eval { require "/usr/local/etc/foundry.conf" };

Set($rtname, $ENV{RT_NAME} || 'OSSF');
Set($Timezone, $ENV{TZ} || 'Asia/Taipei');
Set($Host, $ENV{HOST} || 'foundry.org');

Set($WebHost, $ENV{WEB_HOST} || "rt.$Host");
Set($EmailHost, $ENV{EMAIL_HOST} || "users.$Host");
Set($DatabaseHost, $ENV{DB_HOST} || "ssh.$Host");
Set($DatabasePort, $ENV{DB_PORT} || '');

Set($DatabaseType, $ENV{DB_TYPE} || 'Pg');
Set($DatabaseUser, $ENV{DB_DBA_USER} || 'pgsql');
Set($DatabasePassword, $ENV{DB_DBA_PASSWORD} || '');
Set($DatabaseRTHost, $DatabaseHost);

Set($SympaConfig, $ENV{SYMPA_CONFIG} || "/etc/sympa.conf");

@EmailInputEncodings = qw(utf-8 big5 gb2312);

Set($Organization, $rtname);
Set($WebBaseURL, "http://$WebHost");
Set($TicketBaseURI, "fsck.com-rt://$RT::rtname/ticket/");
Set($RTAddressRegexp, "^rt\\\@$WebHost\$");
Set($CorrespondAddress="rt\@$WebHost");
Set($CommentAddress="rt-comment\@$WebHost");
Set($CanonicalizeEmailAddressMatch, "$WebHost\$");
Set($CanonicalizeEmailAddressReplace, $Host);

Set($LogToSyslog, '');
Set($LogDir, "$RT::VarPath/log");
Set($LogToFile, 'debug');

Set($NotifyActor, 1);
Set($HideQueueCcs, 1);
Set($ChangeOwnerUI, 1);
Set($UseCodeTickets, 1);
Set($UseFriendlyFromLine, 0);
Set($UseTransactionBatch, 1);
Set($TrustTextAttachments, 1);
Set($MinimumPasswordLength, 6);
Set($SkipEmptyTabs, 0); # set to 1 to gray out project tabs with no contents 

#use MasonX::Profiler;
#@MasonParameters = (preamble => 'my $p = MasonX::Profiler->new($m, $r);');

1;
