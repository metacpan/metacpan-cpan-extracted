package STIX::Common::OpenVocabulary;

use 5.010001;
use strict;
use warnings;
use utf8;

use constant ACCOUNT_TYPE => (
    'facebook', 'ldap',    'nis',  'openid',        'radius', 'skype',
    'tacacs',   'twitter', 'unix', 'windows-local', 'windows-domain'
);

use constant ATTACK_MOTIVATION => (
    'accidental', 'coercion',            'dominance',     'ideology',
    'notoriety',  'organizational-gain', 'personal-gain', 'personal-satisfaction',
    'revenge',    'unpredictable'
);

use constant ATTACK_RESOURCE_LEVEL => ('individual', 'club', 'contest', 'team', 'organization', 'government');

use constant GROUPING_CONTEXT => ('suspicious-activity', 'malware-analysis', 'unspecified');

use constant IDENTITY_CLASS => ('individual', 'group', 'system', 'organization', 'class', 'unknown');

use constant INFRASTRUCTURE_TYPE => (
    'amplification',  'anonymization',   'botnet',               'command-and-control',
    'exfiltration',   'hosting-malware', 'hosting-target-lists', 'phishing',
    'reconnaissance', 'staging',         'unknown'
);

use constant IMPLEMENTATION_LANGUAGE => (
    'applescript',  'bash',       'c',    'c++',         'c#',    'go',
    'java',         'javascript', 'lua',  'objective-c', 'perl',  'php',
    'powershell',   'python',     'ruby', 'scala',       'swift', 'typescript',
    'visual-basic', 'x86-32',     'x86-64'
);

use constant INDICATOR_TYPE =>
    ('anomalous-activity', 'anonymization', 'benign', 'compromised', 'malicious-activity', 'attribution', 'unknown');

use constant INDUSTRY_SECTOR => (
    'agriculture',                'aerospace',           'automotive',       'chemical',
    'commercial',                 'communications',      'construction',     'defense',
    'education',                  'energy',              'entertainment',    'financial-services',
    'government',                 'emergency-services',  'government-local', 'government-national',
    'government-public-services', 'government-regional', 'healthcare',       'hospitality-leisure',
    'infrastructure',             'dams',                'nuclear',          'water',
    'insurance',                  'manufacturing',       'mining',           'non-profit',
    'pharmaceuticals',            'retail',              'technology',       'telecommunications',
    'transportation',             'utilities'
);

use constant MALWARE_RESULT => ('malicious', 'suspicious', 'benign', 'unknown');

use constant MALWARE_CAPABILITIES => (
    'accesses-remote-machines',     'anti-debugging',
    'anti-disassembly',             'anti-emulation',
    'anti-memory-forensics',        'anti-sandbox',
    'anti-vm',                      'captures-input-peripherals',
    'captures-output-peripherals',  'captures-system-state-data',
    'cleans-traces-of-infection',   'commits-fraud',
    'communicates-with-c2',         'compromises-data-availability',
    'compromises-data-integrity',   'compromises-system-availability',
    'controls-local-machine',       'degrades-security-software',
    'degrades-system-updates',      'determines-c2-server',
    'emails-spam',                  'escalates-privileges',
    'evades-av',                    'exfiltrates-data',
    'fingerprints-host',            'hides-artifacts',
    'hides-executing-code',         'infects-files',
    'infects-remote-machines',      'installs-other-components',
    'persists-after-system-reboot', 'prevents-artifact-access',
    'prevents-artifact-deletion',   'probes-network-environment',
    'self-modifies',                'steals-authentication-credentials',
    'violates-system-operational-integrity'
);

use constant MALWARE_TYPE => (
    'adware',                  'backdoor',   'bot',                  'bootkit',
    'ddos',                    'downloader', 'dropper',              'exploit-kit',
    'keylogger',               'ransomware', 'remote-access-trojan', 'resource-exploitation',
    'rogue-security-software', 'rootkit',    'screen-capture',       'spyware',
    'trojan',                  'unknown',    'virus',                'webshell',
    'wiper',                   'worm'
);

use constant PATTERN_TYPE => ('stix', 'pcre', 'sigma', 'snort', 'suricata', 'yara');

use constant PROCESSOR_ARCHITECTURE => ('alpha', 'arm', 'ia-64', 'mips', 'powerpc', 'sparc', 'x86', 'x86-64');

use constant REGION => (
    'africa',             'eastern-africa',          'middle-africa',    'northern-africa',
    'southern-africa',    'western-africa',          'americas',         'caribbean',
    'central-america',    'latin-america-caribbean', 'northern-america', 'south-america',
    'asia',               'central-asia',            'eastern-asia',     'southern-asia',
    'south-eastern-asia', 'western-asia',            'europe',           'eastern-europe',
    'northern-europe',    'southern-europe',         'western-europe',   'oceania',
    'antarctica',         'australia-new-zealand',   'melanesia',        'micronesia',
    'polynesia'
);

use constant REPORT_TYPE => (
    'attack-pattern', 'campaign',     'identity',      'indicator', 'intrusion-set', 'malware',
    'observed-data',  'threat-actor', 'threat-report', 'tool',      'vulnerability'
);

use constant THREAT_ACTOR_TYPE => (
    'activist',       'competitor',         'crime-syndicate',     'criminal',
    'hacker',         'insider-accidental', 'insider-disgruntled', 'nation-state',
    'sensationalist', 'spy',                'terrorist',           'unknown'
);

use constant THREAT_ACTOR_ROLE => (
    'agent', 'director', 'independent', 'infrastructure-architect',
    'infrastructure-operator', 'malware-author', 'sponsor'
);

use constant THREAT_ACTOR_SOPHISTICATION =>
    ('none', 'minimal', 'intermediate', 'advanced', 'expert', 'innovator', 'strategic');

use constant TOOL_TYPE => (
    'denial-of-service',       'exploitation',  'information-gathering',  'network-capture',
    'credential-exploitation', 'remote-access', 'vulnerability-scanning', 'unknown'
);

use constant WINDOWS_PEBINARY_TYPE => ('dll', 'exe', 'sys');

1;

=encoding utf-8

=head1 NAME

STIX::Common::OpenVocabulary - Open Vocabulary for STIX Objects

=head1 DESCRIPTION

L<STIX::Common::OpenVocabulary> provide a listing of common and industry accepted
terms as a guide to the user but do not limit the user to that defined list. 

=head2 CONSTANTS

=over

=item ACCOUNT_TYPE

=item ATTACK_MOTIVATION

=item ATTACK_RESOURCE_LEVEL

=item GROUPING_CONTEXT

=item IDENTITY_CLASS

=item IMPLEMENTATION_LANGUAGE

=item INDICATOR_TYPE

=item INDUSTRY_SECTOR

=item INFRASTRUCTURE_TYPE

=item MALWARE_CAPABILITIES

=item MALWARE_RESULT

=item MALWARE_TYPE

=item PATTERN_TYPE

=item PROCESSOR_ARCHITECTURE

=item REGION

=item REPORT_TYPE

=item THREAT_ACTOR_ROLE

=item THREAT_ACTOR_SOPHISTICATION

=item THREAT_ACTOR_TYPE

=item TOOL_TYPE

=item WINDOWS_PEBINARY_TYPE

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
