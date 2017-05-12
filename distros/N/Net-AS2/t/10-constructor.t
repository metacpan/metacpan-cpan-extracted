use Test::More tests => 2;
use Test::Exception;

use strict;
use warnings;

use_ok('Net::AS2');

my ($a1, $a2);

subtest 'Constructor' => sub {
    lives_ok {
        $a1 = Net::AS2->new(
            MyId => 'Mr 1', MyKey => key(1), MyCertificate => cert(1), 
            PartnerId => 'Mr 2', PartnerCertificate => cert(2),
            PartnerUrl => 'http://example.com/dummy/a_2/msg',
            Mdn => 'async',
            MdnAsyncUrl => 'http://example.com/dummy/a_1/mdn'
        );

        $a2 = Net::AS2->new(
            MyId => 'Mr 2', MyKey => key(2), MyCertificate => cert(2), 
            PartnerId => 'Mr 1', PartnerCertificate => cert(1),
            PartnerUrl => 'http://example.com/dummy/a_1/msg'
        );
    } 'handlers created';

    my %sample_config = (
            MyId => 'Mr 1', MyKey => key(1), MyCertificate => cert(1), 
            PartnerId => 'Mr 2', PartnerCertificate => cert(2),
            PartnerUrl => 'http://example.com/dummy/a_2/msg',
        );

    foreach (qw(MyId MyKey MyCertificate PartnerId PartnerCertificate PartnerUrl))
    {
        dies_ok { 
            local $sample_config{$_};
            Net::AS2->new(%sample_config);
        } "Constructor missing with $_";
    }

    foreach (qw(
        MyKey MyCertificate MyEncryptionCertificate MySignatureCertificate
        PartnerUrl Mdn Encryption Signature
        Timeout))
    {
        dies_ok { 
            my $s = $sample_config{$_} // '';
            $s =~ s/[-:]//g;
            $s =~ tr/A-Z/a-z/;
            $s .= "123456789ABC";
            local $sample_config{$_} = $s;
            Net::AS2->new(%sample_config);
        } "Constructor corrupting $_";
    }

    dies_ok{
        local $sample_config{Mdn} = 'async';
        Net::AS2->new(%sample_config);
    } 'Constructor - async but URL not supplied';

    dies_ok{
        local $sample_config{Mdn} = 'sync';
        local $sample_config{MdnAsyncUrl} = 'http://somewhere/';
        Net::AS2->new(%sample_config);
    } 'Constructor - sync but URL supplied';

    {
        my $a = Net::AS2->new(%sample_config);
        is($a->{MyEncryptionKey}, $a->{MySignatureKey}, 'private keys equals');
        is($a->{MyEncryptionCertificate}, $a->{MySignatureCertificate}, 'private certificate equals');
        is($a->{PartnerEncryptionCertificate}, $a->{PartnerSignatureCertificate}, 'public certificate equals');
        is($a->{_smime_enc}, $a->{_smime_sign}, 'SMIME equals');
    }

    {
        my $a = Net::AS2->new(%sample_config, 
            MyEncryptionKey => key(1), MySignatureKey => key(2),
            MyEncryptionCertificate => cert(1), MySignatureCertificate => cert(2),
            PartnerEncryptionCertificate => cert(1), PartnerSignatureCertificate => cert(2),
        );
        isnt($a->{MyEncryptionKey}, $a->{MySignatureKey}, 'private keys differs');
        isnt($a->{MyEncryptionCertificate}, $a->{MySignatureCertificate}, 'private certificate differs');
        isnt($a->{PartnerEncryptionCertificate}, $a->{PartnerSignatureCertificate}, 'public certificate differs');
        isnt($a->{_smime_enc}, $a->{_smime_sign}, 'SMIME differs');
    }
};

sub key {
    my $i = shift;

    local $/;
    open my $fh, '<', "t/test.$i.key";
    return <$fh>;
}

sub cert {
    my $i = shift;

    local $/;
    open my $fh, '<', "t/test.$i.cert";
    return <$fh>;
}

