use Test::More tests => 31;

BEGIN
{
  require "t/common.pl";
}

use Net::DSML::Control;

my $oid = "1.2.840.113556.1.4.612";
my $vt = "base64Binary";
my $cr = "true";
my $vl = "U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==";

diag( " " );
diag( "Testing Net::DSML::Control $Net::DSML::Control::VERSION" );
my @tests = do { local $/=""; <DATA> };

my $control = Net::DSML::Control->new();

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));

$control->add( { control => "1.2.840.113556.1.4.612",
                 valuetype => "base64Binary",
                 criticality => "true",
                 value => "U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==" });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[0], $control->getControl()));


$control->clear();
ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
$control->add( { control => "1.2.840.113556.1.4.612",
                 valuetype => "base64Binary",
                 criticality => "true",
                 value => "U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==" });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[0], $control->getControl()));



$control = Net::DSML::Control->new( { control => "1.2.840.113556.1.4.612",
                               valuetype => "base64Binary",
                               criticality => "true",
                               value => "U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==" });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[0], $control->getControl()));



$control = Net::DSML::Control->new( { control => $oid,
                               valuetype => $vt,
                               criticality => $cr,
                               value => $vl });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[0], $control->getControl()));


$control = Net::DSML::Control->new( { control => \$oid,
                               valuetype => \$vt,
                               criticality => \$cr,
                               value => \$vl });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[0], $control->getControl()));


$control = Net::DSML::Control->new( { control => "1.2.840.113556.1.4.643",
                            valuetype => "string",
                            criticality => "false",
                            value => "This is a test case." });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[1], $control->getControl()));


$control = Net::DSML::Control->new( { control => "1.2.840.113556.1.4.612",
                            valuetype => "anyURI",
                            criticality => "false",
                            value => "http://www.test.com" });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[2], $control->getControl()));


$control = Net::DSML::Control->new( { control => "1.2.840.113556.1.4.474" });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[3], $control->getControl()));

$control->add( { control => "1.2.840.113556.1.4.612",
                 valuetype => "base64Binary",
                 criticality => "true",
                 value => "U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==" });

ok( defined $control);
ok( $control->isa('Net::DSML::Control'));
ok( compare_test($tests[4], $control->getControl()));



__DATA__
<control type="1.2.840.113556.1.4.612" critical="true"><controlValue xsi:type="xsd:base64Binary">U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==</controlValue></control>

<control type="1.2.840.113556.1.4.643" critical="false"><controlValue xsi:type="xsd:string">This is a test case.</controlValue></control>

<control type="1.2.840.113556.1.4.612" critical="false"><controlValue xsi:type="xsd:anyURI">http://www.test.com</controlValue></control>

<control type="1.2.840.113556.1.4.474"></control>

<control type="1.2.840.113556.1.4.474"></control><control type="1.2.840.113556.1.4.612" critical="true"><controlValue xsi:type="xsd:base64Binary">U2VhcmNoIFJlcXVlc3QgRXhhbXBsZQ==</controlValue></control>
