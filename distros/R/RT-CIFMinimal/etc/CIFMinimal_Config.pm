# don't change this... stuff will break
Set($RTIR_DisableBlocksQueue, 1);
Set($MinimalRegex, qr!^(?:/+Minimal/)!x );
my $rt_no_auth = RT->Config->Get('WebNoAuthRegex');
Set($WebNoAuthRegex, qr{ (?: $rt_no_auth | ^/+Minimal/+NoAuth/ ) }x);

# turn this off if you're using a self-signed cert
Set($CIFMinimal_TLS_Verify,1);

# everything here should be lower case
Set(%CIFMinimal_RestrictionMapping,
       #default         => 'amber',
       #red             => 'private',
       #amber           => 'need-to-know',
       #green          => 'need-to-know',
       #white          => 'public',
);

Set(%CIFMinimal_ConfidenceMapping,
    'very confident'    => {
        order   => 1,
        value   => 85,
     },
     'somewhat confident'   => {
        order   => 2,
        value   => 75,
     },
);

Set(%CIFMinimal_Assessments,
    'botnet'    => {
        order   => 1,
        desc    => 'things used to control or communicate with botnets',
    },
    'malware/exploit'   => {
        order   => 2,
        desc    => 'things used to drop malware, malware itself, things used to exploit the browser, etc.',
    },
    'scanner'   => {
        order   => 3,
        desc    => 'things used for scanning or bruteforcing, ssh, rdp, mssql, www etc...',
    },
    'spam'  => {
        order   => 4,
        desc    => "things used for sending spam (spam relays, open proxies, etc...)",
    },
    'hijacked'  => {
        order   => 5,
        desc    => "things that shouldn't be routed (criminally hijacked networks, domains, etc)",
    },
    'phishing'  => {
        order   => 6,
        desc    => "phishing lures, replytos, drop boxes, etc",
    },
    'fastflux'  => {
        order   => 7,
        desc    => "things that appear to be fast-flux in nature (ips, domains, etc)",
    },
    'suspicious'    => {
        order   => 8,
        desc    => "something that's suspicious, not really good, but not sure what kinda bad (other, etc)",
    },
    'whitelist' => {
        order   => 9,
        desc    => "something that needs to be whitelisted, could be bad, but could cause pain if blocked",
    },
);
Set($CIFMinimal_DefaultAssessment,'botnet');
Set($CIFMinimal_DefaultSharingPolicy,'http://en.wikipedia.org/wiki/Traffic_Light_Protocol');
Set($CIFMinimal_DefaultConfidence, 85);
Set($CIFMinimal_RejectPrivateAddress,1);
Set($CIFMinimal_HelpUrl,'http://code.google.com/p/collective-intelligence-framework/wiki/Taxonomy');

Set(%CIFMinimal_ShareWith,
    'leo.example.com'         => {
        description     => 'Anonymized with Trusted Law Enforcement',
        checked         => 1,
    },
    'partners.example.com'    => {
        description => 'Anonymized with Trusted Mitigation Partners',
        checked     => 1,
    }
);

# this allows you to wrap the RT::User::Create function
# this example we use:
# http://www.openfusion.com.au/labs/mod_auth_tkt/
# which places "tokens" (eg: groups) in $ENV:
#  $VAR59 = 'REMOTE_USER';
#  $VAR60 = 'wes@example.com';
#  $VAR61 = 'REMOTE_USER_TOKENS';
#  $VAR62 = 'group1,group2,group3';

Set(%CIFMinimal_UserGroupMapping,
    EnvVar  => 'REMOTE_USER_TOKENS',
    Pattern => qr/,/,
    Mapping => {
        mygroup1    => 'DutyTeam group1.example.com',
        mygroup2    => 'DutyTeam group2.example.com',
        mygroup3    => 'DutyTeam group3.example.com',
    },
);

# this is set in days
# how long we should generally keep each type
# on our radar
# repeat offenders should find their way back in

Set(%CIFMinimal_StaleMap,
    'ipv4-addr' => 30,
    'ipv4-net'  => 180,
    'url'       => 180,
    'domain'    => 730,
    'hash'      => 730,
    'whitelist' => 1095,
);

# turn on the embedded "CIF Results view" to Display.html
Set($CIFMinimal_CollectiveView,0);

# set default number of submissions allowed at once
# via the Minimal/Observation.html interface
Set($CIFMinimal_MaxSubmissions,15);

1;
