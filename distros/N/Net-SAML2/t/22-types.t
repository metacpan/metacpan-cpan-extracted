use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use Net::SAML2::Types qw(XsdID SAMLRequestType signingAlgorithm);

subtest 'XsdID' => sub {
    my @xsdidok = qw(thisiscorrect _so_it_this THISTOO _YES this.-123.correct);
    foreach (@xsdidok) {
        ok(XsdID->check($_), "$_ is correct as an xsd:ID");
    }

    ok(!XsdID->check("1abc"), "... and this is not a correct xsd:ID");
    like(
        XsdID->get_message("1abc"),
        qr/is not a valid xsd:ID/,
        ".. with the correct error message"
    );

    ok(!XsdID->check('asb#'), "... not an allowed character");

};

subtest 'SAMLRequestType' => sub {

    foreach (qw(SAMLRequest SAMLResponse)) {
        ok(SAMLRequestType->check($_), "$_ is correct SAMLRequestType");
    }
    ok(!SAMLRequestType->check("foo"), ".. and this is not");
    like(
        SAMLRequestType->get_message("foo"),
        qr/is not a SAML Request type/,
        ".. with the correct error message"
    );
};

subtest 'signingAlgorithm' => sub {

    foreach (qw(sha244 sha256 sha384 sha512 sha1)) {
        ok(signingAlgorithm->check($_), "$_ is correct signingAlgorithm");
    }

    ok(!signingAlgorithm->check("shafake"), ".. and this is not");
    like(
        signingAlgorithm->get_message("shafake"),
        qr/is not a supported signingAlgorithm/,
        ".. with the correct error message"
    );
};

done_testing;
