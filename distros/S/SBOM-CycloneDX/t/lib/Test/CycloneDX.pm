package Test::CycloneDX;

use 5.010001;
use strict;
use warnings;

use Test::More;
use Cpanel::JSON::XS      qw(decode_json);
use File::Basename        qw(dirname basename);
use File::Spec::Functions qw(catfile);
use SBOM::CycloneDX::Util qw(file_read);

use Exporter 'import';

our @EXPORT_OK = qw(bom_1_7 bom_1_6 bom_1_5 bom_1_4 bom_1_3 bom_1_2 bom_test_data);

use SBOM::CycloneDX;

my $SERIAL_NUMBER = 'urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79';

sub bom_test_data {

    my ($test_file) = @_;
    my $json_file = basename($test_file, '.t') . '.json';
    $json_file =~ s/^\d{2}-//;

    my ($spec_version) = ($test_file =~ /(\d\.\d)\.t/);

    diag("Load $json_file");

    return decode_json(file_read(catfile(dirname($test_file), 'resources', $spec_version, $json_file)));

}

sub bom_1_7 { SBOM::CycloneDX->new(spec_version => 1.7, serial_number => $SERIAL_NUMBER) }
sub bom_1_6 { SBOM::CycloneDX->new(spec_version => 1.6, serial_number => $SERIAL_NUMBER) }
sub bom_1_5 { SBOM::CycloneDX->new(spec_version => 1.5, serial_number => $SERIAL_NUMBER) }
sub bom_1_4 { SBOM::CycloneDX->new(spec_version => 1.4, serial_number => $SERIAL_NUMBER) }
sub bom_1_3 { SBOM::CycloneDX->new(spec_version => 1.3, serial_number => $SERIAL_NUMBER) }
sub bom_1_2 { SBOM::CycloneDX->new(spec_version => 1.2, serial_number => $SERIAL_NUMBER) }
