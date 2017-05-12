use Test::More tests => 32;

BEGIN {
  require "t/common.pl";
}

use Net::DSML;
use Net::DSML::Filter;
use Net::DSML::Control;


diag( " " );
diag( "Testing Net::DSML $Net::DSML::VERSION" );
diag( "Testing Net::DSML::Filter $Net::DSML::Filter::VERSION" );
diag( "Testing Net::DSML::Control $Net::DSML::Control::VERSION" );

my @tests = do { local $/=""; <DATA> };

my $dsml = Net::DSML->new();
my $filter = Net::DSML::Filter->new();
my $control = Net::DSML::Control->new();
ok( defined $dsml);
ok( $dsml->isa('Net::DSML'));
ok( defined $filter);
ok( $filter->isa('Net::DSML::Filter'));
ok( defined $control);
ok( $control->isa('Net::DSML::Control'));

# Delete
$dsml = Net::DSML->new();
$dsml->setProcessId( { id => 1 } );
$dsml->delete( { dn => "uid=bugs,ou=people,dc=company,dc=com"} );
$dsml->send( { debug => 1} );
ok(compare_test($tests[0],$dsml->getOperations()));

# Delete
$dsml = Net::DSML->new();
$dsml->delete( { dn => "uid=bugs,ou=people,dc=company,dc=com"}, id => 1 );
$dsml->send( { debug => 1} );
ok(compare_test($tests[0],$dsml->getOperations()));

# Compare
$dsml = Net::DSML->new();
$dsml->setProcessId( { id => 1 } );
$dsml->compare( { dn => "uid=bugs,ou=people,dc=company,dc=com",
                  attribute => "sn",
                  value => "manager" } );
ok(compare_test($tests[1],$dsml->getOperations()));

# Compare
$dsml = Net::DSML->new();
$dsml->compare( { dn => "uid=bugs,ou=people,dc=company,dc=com",
                  id => 1,
                  attribute => "sn",
                  value => "manager" } );
ok(compare_test($tests[1],$dsml->getOperations()));

# Modrdn
$dsml = Net::DSML->new();
$dsml->setProcessId( { id => 1 } );
$dsml->modrdn( { dn => "uid=bugs,ou=people,dc=company,dc=com",
                  newrdn => "cn=mad man",
                  deleteoldrdn => "true",
                  newsuperior => "ou=people,dc=company,dc=com" } );
ok(compare_test($tests[2],$dsml->getOperations()));

# rootDSE
$dsml = Net::DSML->new();
$dsml->setProcessId( { id => 1 } );
$dsml->rootDSE( { attributes => [ "namingcontext"],
                  newrdn => "cn=mad man",
                  deleteoldrdn => "true",
                  newsuperior => "ou=people,dc=company,dc=com" } );
ok(compare_test($tests[3],$dsml->getOperations()));

# rootDSE
$dsml = Net::DSML->new();
$dsml->rootDSE( { attributes => [ "namingcontext"],
                  id => 1,
                  newrdn => "cn=mad man",
                  deleteoldrdn => "true",
                  newsuperior => "ou=people,dc=company,dc=com" } );
ok(compare_test($tests[3],$dsml->getOperations()));

# rootDSE
my $id = 1;
$dsml = Net::DSML->new();
$dsml->rootDSE( { attributes => [ "namingcontext"],
                  id => \$id,
                  newrdn => "cn=mad man",
                  deleteoldrdn => "true",
                  newsuperior => "ou=people,dc=company,dc=com" } );
ok(compare_test($tests[3],$dsml->getOperations()));

# search
$dsml = Net::DSML->new();
$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$dsml->setProcessId( { id => 1 } );
$filter = Net::DSML::Filter->new();
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter() });
ok(compare_test($tests[4],$dsml->getOperations()));

# search with control
$dsml = Net::DSML->new();
$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$dsml->setProcessId( { id => 1 } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new();
$control->add({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[5],$dsml->getOperations()));

# search with control and id 
$dsml = Net::DSML->new();
$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new();
$control->add({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  id => 1,
                  control => $control->getControl() });
ok(compare_test($tests[5],$dsml->getOperations()));

# search with control and id 
$dsml = Net::DSML->new();
$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new();
$control->add({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  id => \$id,
                  control => $control->getControl() });
ok(compare_test($tests[5],$dsml->getOperations()));

my $bs = "ou=people,dc=company,dc=com";
my $pd = 1;

# search with control
$dsml = Net::DSML->new();
$dsml->setBase( { base => \$bs } );
$dsml->setProcessId( { id => \$pd } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new();
$control->add({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[5],$dsml->getOperations()));

# search with control
$dsml = Net::DSML->new();
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new();
$control->add({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  base => \$bs,
                  id => \$pd,
                  control => $control->getControl() });
ok(compare_test($tests[5],$dsml->getOperations()));

# search with control
$dsml = Net::DSML->new();
$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$dsml->setProcessId( { id => 1 } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[5],$dsml->getOperations()));

# search with control and other options being setup.
$dsml = Net::DSML->new();
$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$dsml->setProcessId( { id => 1 } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->setScope( { scope => "baseObject" } );
$dsml->setReferral( { referral => "derefInSearching" } );
$dsml->setType( { type => "true" } );
$dsml->setSize( { size => "10" } );
$dsml->setTime( { time => "100" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[6],$dsml->getOperations()));

my $ct = "1.2.840.113556.1.4.474";
my $ty = "final";
my $at = "cn";
my $vl = "Bunny";
my $sc = "baseObject";
my $rf = "derefInSearching";
my $tye = "true";
my $sz = 10;
my $tm = 100;
# search with control and other options being setup.
$dsml = Net::DSML->new();
$dsml->setBase( { base => \$bs } );
$dsml->setProcessId( { id => \$pd } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new({ control => \$ct});
$filter->subString( { type => \$ty, attribute => \$at, value => $vl } );
$dsml->setScope( { scope => \$sc } );
$dsml->setReferral( { referral => \$rf } );
$dsml->setType( { type => \$tye } );
$dsml->setSize( { size => \$sz } );
$dsml->setTime( { time => \$tm } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[6],$dsml->getOperations()));



# search with control and other options being setup in DSML constructor.
$dsml = Net::DSML->new( {scope => "baseObject",
                    referral => "derefInSearching",
                    type => "true",
                    size => "10",
                    time => "100",
                    base => "ou=people,dc=company,dc=com" });
#$dsml->setBase( { base => "ou=people,dc=company,dc=com" } );
$dsml->setProcessId( { id => 1 } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[6],$dsml->getOperations()));
#
# Do a dummy post request
#
$dsml->send( { debug => 1});
ok(compare_test($tests[7],$dsml->getPostData()));

# search with control and other options being setup in DSML constructor.
$dsml = Net::DSML->new( {scope => "baseObject",
                    referral => "derefInSearching",
                    type => "true",
                    size => "10",
                    time => "100",
                    base => "ou=people,dc=company,dc=com" });
$dsml->setProcess( { process => "parallel" } );
$dsml->setOnError( { error => "resume" } );
$dsml->setOrder( { order => "unordered" } );
$dsml->setBatchId( { id => "231" } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->setProcessId( { id => 1 } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[6],$dsml->getOperations()));

my $bh = 231;
my $or = "unordered";
my $er = "resume";
my $pc = "parallel";
my $ky1 = "size";
# search with control and other options being setup in DSML constructor.
$dsml = Net::DSML->new( {scope => \$sc,
                    referral => \$rf,
                    type => \$tye,
                    $ky1 => \$sz,
                    time => \$tm,
                    base => \$bs });
$dsml->setProcess( { process => \$pc } );
$dsml->setOnError( { error => \$er } );
$dsml->setOrder( { order => \$or } );
$dsml->setBatchId( { id => \$bh } );
$filter = Net::DSML::Filter->new();
$control = Net::DSML::Control->new({ control => "1.2.840.113556.1.4.474"});
$filter->subString( { type =>"final", attribute => "cn", value => "Bunny" } );
$dsml->setProcessId( { id => 1 } );
$dsml->search( { attributes => [ "uid","cn","mail","sn","rfc822mailbox"],
                  sfilter => $filter->getFilter(),
                  control => $control->getControl() });
ok(compare_test($tests[6],$dsml->getOperations()));

#
# Do a dummy post request
#
$dsml->send( { debug => 1});
ok(compare_test($tests[8],$dsml->getPostData()));

# add with id
$dsml = Net::DSML->new();
$dsml->add( { dn => "cn=Burning Man, ou=people, dc=yourcompany, dc=com",
            id => 1,
            attr => {
            objectClass => ["top","person","organizationalPerson","inetOrgPerson"],
            cn => "Burning Man",
            sn => "Man",
            givenName => "Fire",
            telephoneNumber => ["214-972-4677","972-987-1234"] } });
ok(compare_test($tests[9],$dsml->getOperations()));

# modify with id
$ty = "456-543-7894";
$dsml = Net::DSML->new();
$dsml->modify( { dn => "cn=Burning Man, ou=people, dc=yourcompany, dc=com",
            id => 908,
            modify => {
            replace => { telephoneNumber => \$ty },
            add => { givenName => "Smoke" },
            delete => { givenName => "Fire" } } });
ok(compare_test($tests[10],$dsml->getOperations()));


# add with id
$dsml = Net::DSML->new();
$dsml->add( { dn => "cn=Burning Man, ou=people, dc=yourcompany, dc=com",
            id => \$id,
            attr => {
            objectClass => ["top","person","organizationalPerson","inetOrgPerson"],
            cn => "Burning Man",
            sn => "Man",
            givenName => "Fire",
            telephoneNumber => ["214-972-4677","972-987-1234"] } });
ok(compare_test($tests[9],$dsml->getOperations()));

# modify with id
$id = 908;
$ty = "456-543-7894";
$dsml = Net::DSML->new();
$dsml->modify( { dn => "cn=Burning Man, ou=people, dc=yourcompany, dc=com",
            id => \$id,
            modify => {
            replace => { telephoneNumber => \$ty },
            add => { givenName => "Smoke" },
            delete => { givenName => "Fire" } } });
ok(compare_test($tests[10],$dsml->getOperations()));

__DATA__
<delRequest requestID="1" dn="uid=bugs,ou=people,dc=company,dc=com" />

<compareRequest requestID="1" dn="uid=bugs,ou=people,dc=company,dc=com"><assertion name="sn"><value>manager</value></assertion></compareRequest>

<modDNRequest requestID="1" dn="uid=bugs,ou=people,dc=company,dc=com" newrdn="cn=mad man" newSuperior="ou=people,dc=company,dc=com" deleteoldrdn="true"></modDNRequest>

<searchRequest requestID="1" dn="" scope="baseObject" derefAliases="neverDerefAliases" timeLimit="0" sizeLimit="0" typesOnly="false"><filter><present name="objectClass"/></filter><attributes><attribute name="namingcontext"/></attributes></searchRequest>

<searchRequest requestID="1" dn="ou=people,dc=company,dc=com" scope="singleLevel" derefAliases="neverDerefAliases" timeLimit="0" sizeLimit="0" typesOnly="false"><filter><substrings name="cn"><final>Bunny</final></substrings></filter><attributes><attribute name="uid"/><attribute name="cn"/><attribute name="mail"/><attribute name="sn"/><attribute name="rfc822mailbox"/></attributes></searchRequest>

<searchRequest requestID="1" dn="ou=people,dc=company,dc=com" scope="singleLevel" derefAliases="neverDerefAliases" timeLimit="0" sizeLimit="0" typesOnly="false"><filter><substrings name="cn"><final>Bunny</final></substrings></filter><attributes><attribute name="uid"/><attribute name="cn"/><attribute name="mail"/><attribute name="sn"/><attribute name="rfc822mailbox"/></attributes><control type="1.2.840.113556.1.4.474"></control></searchRequest>

<searchRequest requestID="1" dn="ou=people,dc=company,dc=com" scope="baseObject" derefAliases="derefInSearching" timeLimit="100" sizeLimit="10" typesOnly="true"><filter><substrings name="cn"><final>Bunny</final></substrings></filter><attributes><attribute name="uid"/><attribute name="cn"/><attribute name="mail"/><attribute name="sn"/><attribute name="rfc822mailbox"/></attributes><control type="1.2.840.113556.1.4.474"></control></searchRequest>

<?xml version='1.0' encoding='UTF-8'?><soap-env:Envelope xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:soap-env='http://schemas.xmlsoap.org/soap/envelope/'><soap-env:Body><batchRequest xmlns='urn:oasis:names:tc:DSML:2:0:core'  requestID="batch request" onError="exit" responseOrder="sequential" processing="sequential"><searchRequest requestID="1" dn="ou=people,dc=company,dc=com" scope="baseObject" derefAliases="derefInSearching" timeLimit="100" sizeLimit="10" typesOnly="true"><filter><substrings name="cn"><final>Bunny</final></substrings></filter><attributes><attribute name="uid"/><attribute name="cn"/><attribute name="mail"/><attribute name="sn"/><attribute name="rfc822mailbox"/></attributes><control type="1.2.840.113556.1.4.474"></control></searchRequest></batchRequest></soap-env:Body></soap-env:Envelope>

<?xml version='1.0' encoding='UTF-8'?><soap-env:Envelope xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:soap-env='http://schemas.xmlsoap.org/soap/envelope/'><soap-env:Body><batchRequest xmlns='urn:oasis:names:tc:DSML:2:0:core'  requestID="231" onError="resume" responseOrder="unordered" processing="parallel"><searchRequest requestID="1" dn="ou=people,dc=company,dc=com" scope="baseObject" derefAliases="derefInSearching" timeLimit="100" sizeLimit="10" typesOnly="true"><filter><substrings name="cn"><final>Bunny</final></substrings></filter><attributes><attribute name="uid"/><attribute name="cn"/><attribute name="mail"/><attribute name="sn"/><attribute name="rfc822mailbox"/></attributes><control type="1.2.840.113556.1.4.474"></control></searchRequest></batchRequest></soap-env:Body></soap-env:Envelope>

<addRequest requestID="1" dn="cn=Burning Man, ou=people, dc=yourcompany, dc=com"><attr name="cn"><value>Burning Man</value></attr><attr name="givenName"><value>Fire</value></attr><attr name="objectClass"><value>top</value></attr><attr name="objectClass"><value>person</value></attr><attr name="objectClass"><value>organizationalPerson</value></attr><attr name="objectClass"><value>inetOrgPerson</value></attr><attr name="sn"><value>Man</value></attr><attr name="telephoneNumber"><value>214-972-4677</value></attr><attr name="telephoneNumber"><value>972-987-1234</value></attr></addRequest>

<modifyRequest requestID="908" dn="cn=Burning Man, ou=people, dc=yourcompany, dc=com"><modification name="givenName" operation="add"><value>Smoke</value></modification><modification name="givenName" operation="delete"><value>Fire</value></modification><modification name="telephoneNumber" operation="replace"><value>456-543-7894</value></modification></modifyRequest>
