use Test::More tests => 2;
use Test::Exception;

use File::Basename qw(dirname);
use Cwd            qw(abs_path);

use strict;
use warnings;

use_ok('Net::AS2');

my ($a1, $a2);
my $cert_dir = abs_path(dirname(__FILE__) . '/certificates');

subtest 'Constructor' => sub {
    lives_ok {
        $a1 = Net::AS2->new(
            CertificateDirectory => $cert_dir,
            MyId => 'Mr 1', MyKeyFile => 'test.1.key', MyCertificateFile => 'test.1.cert',
            PartnerId => 'Mr 2', PartnerCertificateFile => 'test.2.cert',
            PartnerUrl => 'http://example.com/dummy/a_2/msg',
            Mdn => 'async',
            MdnAsyncUrl => 'http://example.com/dummy/a_1/mdn'
        );

        $a2 = Net::AS2->new(
            CertificateDirectory => $cert_dir,
            MyId => 'Mr 2', MyKeyFile => 'test.2.key', MyCertificateFile => 'test.2.cert',
            PartnerId => 'Mr 1', PartnerCertificateFile => 'test.1.cert',
            PartnerUrl => 'http://example.com/dummy/a_1/msg'
        );
    } 'handlers created';

    my %sample_config = (
            CertificateDirectory => $cert_dir,
            MyId => 'Mr 1', MyKeyFile => 'test.1.key', MyCertificateFile => 'test.1.cert',
            PartnerId => 'Mr 2', PartnerCertificateFile => 'test.2.cert',
            PartnerUrl => 'http://example.com/dummy/a_2/msg',
        );

    foreach (qw(MyId MyKeyFile MyCertificateFile PartnerId PartnerCertificateFile PartnerUrl))
      {
        dies_ok {
            local $sample_config{$_};
            Net::AS2->new(%sample_config);
        } "Constructor missing with $_";
    }

    foreach (qw(
        MyKeyFile MyCertificateFile MyEncryptionCertificateFile MySignatureCertificateFile
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
        local $sample_config{Signature} = 'sha2000';
        Net::AS2->new(%sample_config);
    } 'Constructor - invalid signature algorithm';

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
            MyEncryptionKeyFile => 'test.1.key', MySignatureKeyFile => 'test.2.key',
            MyEncryptionCertificateFile => 'test.1.cert', MySignatureCertificateFile => 'test.2.cert',
            PartnerEncryptionCertificateFile => 'test.1.cert', PartnerSignatureCertificateFile => 'test.2.cert',
        );
        isnt($a->{MyEncryptionKey}, $a->{MySignatureKey}, 'private keys differs');
        isnt($a->{MyEncryptionCertificate}, $a->{MySignatureCertificate}, 'private certificate differs');
        isnt($a->{PartnerEncryptionCertificate}, $a->{PartnerSignatureCertificate}, 'public certificate differs');
        isnt($a->{_smime_enc}, $a->{_smime_sign}, 'SMIME differs');
    }
};
