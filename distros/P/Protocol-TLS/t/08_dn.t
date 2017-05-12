use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TLSTest;
use Convert::ASN1;

my $dn_schema = <<'ASN1';
    DistinguishedName ::= RDNSequence
    RDNSequence ::= SEQUENCE OF RelativeDistinguishedName
    RelativeDistinguishedName ::= SET OF AttributeTypeAndValue
    AttributeTypeAndValue ::= SEQUENCE {
        type  OBJECT IDENTIFIER,
        value CHOICE {
            v1 PrintableString,
            v2 IA5String
        }
    }
ASN1

subtest 'dn' => sub {
    my $pdu = hstr(<<'DER');
        3081 9831 0b30 0906 0355 0406 1302 5553
        310b 3009 0603 5504 0813 0243 4131 1530
        1306 0355 0407 130c 5361 6e46 7261 6e63
        6973 636f 3115 3013 0603 5504 0a13 0c46
        6f72 742d 4675 6e73 746f 6e31 0b30 0906
        0355 040b 1302 6974 310f 300d 0603 5504
        0313 0672 6164 6975 7331 0f30 0d06 0355
        0429 1306 7261 6469 7573 311f 301d 0609
        2a86 4886 f70d 0109 0116 106d 6169 6c40
        686f 7374 2e64 6f6d 6169 6e
DER

    my $asn = Convert::ASN1->new;
    ok $asn->prepare($dn_schema), "loaded DistinguishedName schema"
      or note $asn->error;
    my $filter = $asn->find('DistinguishedName');
    ok my $ret = $filter->decode($pdu), "der data decoded"
      or note $filter->error;
    is $ret->[0]->[0]->{type}, '2.5.4.6', "correct type" or note explain $ret;
};

done_testing;

