use Test::More tests => 25;
use Data::Dumper;
BEGIN { use_ok('Net::Yadis::Discovery') };

my $disc = Net::Yadis::Discovery->new(debug => 1);
$disc->identity_url("http://example.com");

my $buffer;
foreach (<DATA>) { $buffer .= $_ }

$disc->parse_xrd($buffer);

#OpenID test
my @arr = $disc->openid_servers;
is (@arr,4);
@arr = $disc->openid_servers(['1.0']);
is (@arr,2);
@arr = $disc->openid_servers(['1.1']);
is (@arr,3);
@arr = $disc->openid_servers(['1.0','1.1']);
is (@arr,4);

#Delegate test
is ($arr[0]->Delegate,"http://myid.myopenid.com/");

#LID test
@arr = $disc->lid_servers;
is (@arr,2);
@arr = $disc->lid_servers(['1.0']);
is (@arr,1);
@arr = $disc->lid_servers(['2.0']);
is (@arr,1);
@arr = $disc->lid_servers(['1.0','2.0']);
is (@arr,2);

#TypeKey test
@arr = $disc->typekey_servers;
is (@arr,1);

#MemberName test
is ($arr[0]->MemberName,"myid");

#Hybrid test
@arr = $disc->servers('lid','typekey');
is (@arr,3);
@arr = $disc->servers('openid'=>['1.0'],'typekey');
is (@arr,3);
@arr = $disc->servers('openid'=>['1.1'],'lid');
is (@arr,5);

#Coderef test
@arr = $disc->servers('openid','typekey',sub{($_[0])});
is (@arr,1);
@arr = $disc->servers('openid','typekey',sub{@_});
is (@arr,5);
@arr = $disc->servers;
is (@arr,7);
@arr = $disc->servers(sub{($_[int(rand(@_))])});
is (@arr,1);
@arr = $disc->servers(sub{@_});
is (@arr,7);

#Delegate test on server method
is ($arr[0]->Delegate,"http://myid.myopenid.com/");

#Error case
my @err = (
    ['Version',['1.0'],'openid'],
    ['Version','openid',['1.0'],['1.0']],
    ['No option',sub{},'openid'],
    ['Unknown','poppenid'],
);
foreach my $err (@err){
    my $reg = shift(@$err);
    eval{@arr = $disc->servers(@$err);};
    ok ($@ =~ /$reg/);
}

__END__
<?xml version="1.0" encoding="UTF-8"?>

<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns:typekey="http://www.sixapart.com/typekey/xmlns/1.0"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>

    <Service priority="0">
      <Type>http://openid.net/signon/1.0</Type>
      <URI>http://www.myopenid.com/server</URI>
      <openid:Delegate>http://myid.myopenid.com/</openid:Delegate>
    </Service>

    <Service priority="5">
      <Type>http://openid.net/signon/1.0</Type>
      <Type>http://openid.net/signon/1.1</Type>
      <URI>http://www.livejournal.com/openid/server.bml</URI>
      <openid:Delegate>http://www.livejournal.com/users/myid/</openid:Delegate>
    </Service>

    <Service priority="10">
      <Type>http://openid.net/signon/1.1</Type>
      <URI>http://videntity.org/server</URI>
      <openid:Delegate>http://myid.videntity.org/</openid:Delegate>
    </Service>

    <Service priority="15">
      <Type>http://openid.net/signon/1.1</Type>
      <URI>http://auth.mylevel9.com/?action=openid</URI>
      <openid:Delegate>http://mylevel9.com/user/myid</openid:Delegate>
    </Service>

    <Service priority="20">
      <Type>http://www.sixapart.com/typekey/sso/1.0</Type>
      <typekey:MemberName>myid</typekey:MemberName>
    </Service>

    <Service priority="25">
      <Type>http://lid.netmesh.org/sso/2.0</Type>
      <URI>http://mylid.net/myid</URI>
    </Service>

    <Service priority="30">
      <Type>http://lid.netmesh.org/sso/1.0</Type>
      <URI>http://mylid.net/myid</URI>
    </Service>

  </XRD>
</xrds:XRDS>