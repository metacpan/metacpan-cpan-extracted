package CertificateInfo;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    updateCertificateInfo => ['int'];
use Ui_CertificateInfo;

sub form() {
    return this->{form};
}

sub chain() {
    return this->{chain};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{form} = Ui_CertificateInfo->setupUi(this);

    this->connect(form->certificationPathView, SIGNAL 'currentRowChanged(int)',
            this, SLOT 'updateCertificateInfo(int)');
}

sub setCertificateChain
{
    my ($chain) = @_;
    this->{chain} = $chain;

    form->certificationPathView->clear();

    for (my $i = 0; $i < scalar @{$chain}; ++$i) {
        my $cert = $chain->[$i];
        form->certificationPathView->addItem(sprintf this->tr('%s%s (%s)'), (!$i ? '' : this->tr('Issued by: ')),
                                             $cert->subjectInfo(Qt::SslCertificate::Organization()),
                                             $cert->subjectInfo(Qt::SslCertificate::CommonName()));
    }

    form->certificationPathView->setCurrentRow(0);
}

sub updateCertificateInfo
{
    my ($index) = @_;
    form->certificateInfoView->clear();
    if ($index >= 0 && $index < scalar @{chain()}) {
        my $cert = chain()->[$index];

        my $Organization            = $cert->subjectInfo(Qt::SslCertificate::Organization());
        my $OrganizationalUnitName  = $cert->subjectInfo(Qt::SslCertificate::OrganizationalUnitName());
        my $CountryName             = $cert->subjectInfo(Qt::SslCertificate::CountryName());
        my $LocalityName            = $cert->subjectInfo(Qt::SslCertificate::LocalityName());
        my $StateOrProvinceName     = $cert->subjectInfo(Qt::SslCertificate::StateOrProvinceName());
        my $CommonName              = $cert->subjectInfo(Qt::SslCertificate::CommonName());
        my $iOrganization           = $cert->issuerInfo(Qt::SslCertificate::Organization());
        my $iOrganizationalUnitName = $cert->issuerInfo(Qt::SslCertificate::OrganizationalUnitName());
        my $iCountryName            = $cert->issuerInfo(Qt::SslCertificate::CountryName());
        my $iLocalityName           = $cert->issuerInfo(Qt::SslCertificate::LocalityName());
        my $iStateOrProvinceName    = $cert->issuerInfo(Qt::SslCertificate::StateOrProvinceName());
        my $iCommonName             = $cert->issuerInfo(Qt::SslCertificate::CommonName());

        $Organization            = $Organization            ? $Organization            : '';
        $OrganizationalUnitName  = $OrganizationalUnitName  ? $OrganizationalUnitName  : '';
        $CountryName             = $CountryName             ? $CountryName             : '';
        $LocalityName            = $LocalityName            ? $LocalityName            : '';
        $StateOrProvinceName     = $StateOrProvinceName     ? $StateOrProvinceName     : '';
        $CommonName              = $CommonName              ? $CommonName              : '';
        $iOrganization           = $iOrganization           ? $iOrganization           : '';
        $iOrganizationalUnitName = $iOrganizationalUnitName ? $iOrganizationalUnitName : '';
        $iCountryName            = $iCountryName            ? $iCountryName            : '';
        $iLocalityName           = $iLocalityName           ? $iLocalityName           : '';
        $iStateOrProvinceName    = $iStateOrProvinceName    ? $iStateOrProvinceName    : '';
        $iCommonName             = $iCommonName             ? $iCommonName             : '';
        my @lines = (
            sprintf( this->tr('Organization: %s'), $Organization ),
            sprintf( this->tr('Subunit: %s'), $OrganizationalUnitName ),
            sprintf( this->tr('Country: %s'), $CountryName ),
            sprintf( this->tr('Locality: %s'), $LocalityName ),
            sprintf( this->tr('State/Province: %s'), $StateOrProvinceName ),
            sprintf( this->tr('Common Name: %s'), $CommonName ),
            '',
            sprintf( this->tr('Issuer Organization: %s'), $iOrganization ),
            sprintf( this->tr('Issuer Unit Name: %s'), $iOrganizationalUnitName ),
            sprintf( this->tr('Issuer Country: %s'), $iCountryName ),
            sprintf( this->tr('Issuer Locality: %s'), $iLocalityName ),
            sprintf( this->tr('Issuer State/Province: %s'), $iStateOrProvinceName ),
            sprintf( this->tr('Issuer Common Name: %s'), $iCommonName ),
        );
        foreach my $line ( @lines ) {
            form->certificateInfoView->addItem($line);
        }
    } else {
        form->certificateInfoView->clear();
    }
}

1;
