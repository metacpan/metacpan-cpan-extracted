# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 31;
BEGIN { use_ok('Security::CVSS') };

#########################

use strict;
use warnings;

my $CVSS;

ok($CVSS = new Security::CVSS, 'instantiate empty CVSS object');

# Examples from the CVSS guide
# Apache Chunked-Encoding Memory Corruption Vulnerability (CVE-2002-0392)

ok($CVSS->AccessVector('Remote'), 'set AccessVector by accessor');
ok($CVSS->AccessComplexity('Low'), 'set AccessComplexity by accessor');
ok($CVSS->Authentication('Not-Required'), 'set Authentication by accessor');
ok($CVSS->ConfidentialityImpact('Partial'), 'set ConfidentialityImpact by accessor');
ok($CVSS->IntegrityImpact('Partial'), 'set IntegrityImpact by accessor');
ok($CVSS->AvailabilityImpact('Complete'), 'set AvailabilityImpact by accessor');
ok($CVSS->ImpactBias('Availability'), 'set ImpactBias by accessor');
ok($CVSS->BaseScore() == 8.5, 'base score of CVE-2002-0392 is expected value');

# Temporal Score
ok($CVSS->Exploitability('Functional'), 'set Exploitability by accessor');
ok($CVSS->RemediationLevel('Official-Fix'), 'set RemediationLevel by accessor');
ok($CVSS->ReportConfidence('Confirmed'), 'set ReportConfidence by accessor');
ok($CVSS->TemporalScore() == 7, 'temporal score of CVE-2002-0392 is expected value');

# Environmental Score
ok($CVSS->CollateralDamagePotential('Medium'), 'set CollateralDamagePotential by accessor');
ok($CVSS->TargetDistribution('Medium'), 'set TargetDistribution by accessor');
ok($CVSS->EnvironmentalScore() == 5.9, 'environmental score of CVE-2002-0392 is expected value');

# Microsoft Windows ASN.1 Library Integer Handling Vulnerability (CVE-2003-0818)
ok($CVSS = new Security::CVSS({
                     AccessVector => 'R',
                     AccessComplexity => 'Low',
                     Authentication => 'Not-Required',
                     ConfidentialityImpact => 'Complete',
                     IntegrityImpact => 'Complete',
                     AvailabilityImpact => 'Complete',
                     ImpactBias => 'Normal'}),
                    'instantiate CVSS object with hash parameters');
ok($CVSS->BaseScore() == 10.0, 'base score of CVE-2003-0818 is as expected');

$CVSS->UpdateFromHash({Exploitability => 'Functional',
                      RemediationLevel => 'Official-Fix',
                      ReportConfidence => 'Confirmed'});

ok($CVSS->TemporalScore() == 8.3, 'temporal score of CVE-2003-0818 is expected value');

# Buffer Overflow In NOD32 Antivirus Software (CVE-2003-0062)
ok($CVSS = new Security::CVSS({
                     AccessVector => 'Local',
                     AccessComplexity => 'High',
                     Authentication => 'Not-Required',
                     ConfidentialityImpact => 'Complete',
                     IntegrityImpact => 'Complete',
                     AvailabilityImpact => 'Complete',
                     ImpactBias => 'Normal',
                     Exploitability => 'Proof-Of-Concept',
                     RemediationLevel => 'Official-Fix',
                     ReportConfidence => 'Confirmed'}),
                    'instantiate another CVSS object with hash parameters');

ok($CVSS->BaseScore() == 5.6, 'base score of CVE-2003-0062 is as expected');
ok($CVSS->TemporalScore() == 4.4, 'temporal score of CVE-2003-0062 is as expected');

# NIST vector examples from http://nvd.nist.gov/cvss.cfm?vectorinfo
$CVSS = new Security::CVSS;

$CVSS->Vector('(AV:L/AC:H/Au:NR/C:N/I:P/A:C/B:C)');
ok($CVSS->BaseScore() == 2.4, 'base score of NIST example is as expected');
is($CVSS->Vector, '(AV:L/AC:H/Au:NR/C:N/I:P/A:C/B:C)', 'output vector is same as input');

$CVSS->Vector('(AV:R/AC:L/Au:R/C:C/I:N/A:P/B:N)');
ok($CVSS->BaseScore() == 3.4, 'base score of 2nd NIST example is as expected');
is($CVSS->Vector, '(AV:R/AC:L/Au:R/C:C/I:N/A:P/B:N)', 'output vector is same as input');

$CVSS->Vector('(AV:L/AC:H/Au:NR/C:N/I:P/A:C/B:C/E:U/RL:O/RC:U)');
ok($CVSS->BaseScore() == 2.4, 'base score of NIST example with temporal values is as expected');
is($CVSS->Vector, '(AV:L/AC:H/Au:NR/C:N/I:P/A:C/B:C/E:U/RL:O/RC:U)', 'output vector is same as input');

$CVSS->Vector('(AV:R/AC:L/Au:R/C:C/I:N/A:P/B:N/E:P/RL:T/RC:Uc)');
ok($CVSS->BaseScore() == 3.4, 'base score of 2nd NIST example with temporal values is as expected');
is($CVSS->Vector, '(AV:R/AC:L/Au:R/C:C/I:N/A:P/B:N/E:P/RL:T/RC:Uc)', 'output vector is same as input');
