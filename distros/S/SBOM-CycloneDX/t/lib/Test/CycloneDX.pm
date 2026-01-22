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

our @EXPORT_OK = qw(
    bom_1_7
    bom_1_6
    bom_1_5
    bom_1_4
    bom_1_3
    bom_1_2
    bom_spec
    bom_test_data
    is_valid_bom
    isnt_valid_bom
    is_bom
);

use SBOM::CycloneDX;

my $SERIAL_NUMBER = 'urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79';

sub bom_test_data {

    my ($test_name, $spec_version) = @_;

    my $test_file = undef;

    if ($spec_version) {
        $test_file = "$test_name-$spec_version.json";
    }
    else {
        # Use the test file name in t/ directory for detect spec version and test filename
        $test_file = basename($test_name, '.t') . '.json';
        $test_file =~ s/^\d{2}-//;
        ($spec_version) = ($test_name =~ /(\d\.\d)/);
    }

    my $test_file_path = catfile(dirname(__FILE__), '..', '..', 'resources', $spec_version, $test_file);

    BAIL_OUT("$test_name ($spec_version) not found") unless -f $test_file_path;

    diag("Load $test_file");
    diag("Spec Version: $spec_version");

    return decode_json(file_read($test_file_path));

}

sub bom_spec { SBOM::CycloneDX->new(spec_version => shift, serial_number => $SERIAL_NUMBER) }

sub bom_1_7 { SBOM::CycloneDX->new(spec_version => 1.7, serial_number => $SERIAL_NUMBER) }
sub bom_1_6 { SBOM::CycloneDX->new(spec_version => 1.6, serial_number => $SERIAL_NUMBER) }
sub bom_1_5 { SBOM::CycloneDX->new(spec_version => 1.5, serial_number => $SERIAL_NUMBER) }
sub bom_1_4 { SBOM::CycloneDX->new(spec_version => 1.4, serial_number => $SERIAL_NUMBER) }
sub bom_1_3 { SBOM::CycloneDX->new(spec_version => 1.3, serial_number => $SERIAL_NUMBER) }
sub bom_1_2 { SBOM::CycloneDX->new(spec_version => 1.2, serial_number => $SERIAL_NUMBER) }


sub is_valid_bom {

    my $bom = shift;
    my @errors = $bom->validate;

    diag $_ for @errors;
    is scalar @errors, 0, sprintf('JSON Schema: Valid CycloneDX %s', $bom->spec_version);

}

sub isnt_valid_bom {

    my $bom = shift;
    my @errors = $bom->validate;

    diag $_ for @errors;
    isnt scalar @errors, 0, sprintf('JSON Schema: Not Valid CycloneDX %s', $bom->spec_version);

}

sub is_bom {

    my $bom = shift;

    diag "$bom";
    isnt "$bom", '', sprintf('Is CycloneDX %s JSON file', $bom->spec_version);

}