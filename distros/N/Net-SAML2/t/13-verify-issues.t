# -*- perl -*-

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MIME::Base64;

BEGIN {
    use_ok( 'Net::SAML2::XML::Sig' );
}

my %issues = (
    "Issue 49 - Wide Characters" => "49",
);

for my $issue (keys %issues) {
    my $filename = "t/issues/issue-$issues{$issue}.xml";
    open my $file, $filename or die "$filename not found!";
    my $xml;
    {
        local undef $/;
        $xml = <$file>;
    }
    my $sig = Net::SAML2::XML::Sig->new({ x509 => 1 });
    my $ret = $sig->verify($xml);
    ok($ret, "Successfully Verified " . $issue);
    ok($sig->signer_cert);
}

done_testing;
