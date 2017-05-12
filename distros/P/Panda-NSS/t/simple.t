use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More;
use Panda::NSS;

my $vfytime = 1404206968;

my $tmpdir = tempdir(CLEANUP => 1);
note "NSS DB dir = $tmpdir";

Panda::NSS::init($tmpdir);
Panda::NSS::add_builtins();

my $cert_data = slurp('t/has_aia.cer');
my $cert = Panda::NSS::Cert->new($cert_data);

ok !!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, $vfytime), 'Correctly fetch all intermediate certs and check chain';
ok !$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, 10), 'Not valid in the distant past';

is $cert->version, 3, "Version 3";
is $cert->serial_number_hex, "02485F1606A9E9776E77E39E5444F627", "serial number correct";
my $hex = uc( join("", unpack("H*", $cert->serial_number)) );
is $hex, $cert->serial_number_hex, "binary serial number correct";
is $cert->subject, 'CN=Apple Inc.,OU=Digital ID Class 3 - Java Object Signing,OU=GC Sandbox - IS Delivery Engineering,O=Apple Inc.,L=Cupertino,ST=CA,C=US', 'Subject correct';
is $cert->issuer, 'CN=VeriSign Class 3 Code Signing 2010 CA,OU=Terms of use at https://www.verisign.com/rpa (c)10,OU=VeriSign Trust Network,O="VeriSign, Inc.",C=US', 'Issuer correct';
is $cert->common_name, 'Apple Inc.', 'Common name correct';
is $cert->country_name, 'US', 'Country name correct';
is $cert->locality_name, 'Cupertino', 'Locality name correct';
is $cert->state_name, 'CA', 'State name correct';
is $cert->org_name, 'Apple Inc.', 'Org name correct';
is $cert->org_unit_name, 'GC Sandbox - IS Delivery Engineering', 'Org Unit name correct';
is $cert->domain_component_name, undef, 'Domain Component name correct';

{
    my $signature = pack('H*','6eb671f312d1da4207a1f97f50425a76d4cfda32c790096931f3d64283c75f03e1cd20f2628fed'
                       .'dab2b2e000a6a56628df8f9d2f09bf6959c7980abb950a5d8fc23be3dbe34638d774ef646af250'
                       .'ff51025996ccc3d6d5ff54b6143a1ff447e16cb18b583a67f64d85837e0b67636d67ace6ed5426'
                       .'8b9fb32282cc479a653f63591901e52fb2f5825a751677faad2e50f85c90e7f2561ea78a79b228'
                       .'36f3ef180a101893870447e8cc24dc78aef8994ca5a95f1fd659837492b1c08176e65750889879'
                       .'0e0eed6f307ca77ec243f51290efa00696ca93f6554da6d29eae6c79cbca20253f5acfc4de28b8'
                       .'e5c3e9a79831feb97173ab069503cf80c54f0c56f60a');
    my $payload = pack('H*',"473a34373039333530393072752e6372617a7970616e64612e7770636d0000014725c7a0d3d1952afb");
    ok $cert->verify_signed_data($payload, $signature, 1405088146), "data signed with this cert";
}

{
    my $cert_data = slurp('t/has_aia.pem');
    my $cert = Panda::NSS::Cert->new($cert_data);
    ok !!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, $vfytime), 'Pem cert is valid';
}

done_testing;

sub slurp {
  local $/;
  open my $file, $_[0] or die "Couldn't open file: $!";
  return <$file>;
}
