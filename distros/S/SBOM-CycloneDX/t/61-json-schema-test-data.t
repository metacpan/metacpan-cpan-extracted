#!perl

use strict;
use warnings;
use v5.10;

use Test::More;
use Cpanel::JSON::XS      qw(decode_json);
use File::Basename        qw(dirname basename);
use File::Spec::Functions qw(catfile);
use SBOM::CycloneDX::Util qw(file_read);
use List::Util            qw(first);

use SBOM::CycloneDX::Schema;

my @SKIP = qw[
    valid-attestation-1.6.json
    valid-attestation-1.7.json
    valid-service-empty-objects-1.6.json
    valid-signatures-1.4.json
    valid-signatures-1.5.json
    valid-signatures-1.6.json
    valid-signatures-1.7.json
    valid-standard-1.6.json
    valid-standard-1.7.json
];

my @SPEC_VERSIONS = qw[1.2 1.3 1.4 1.5 1.6 1.7];

for my $spec_version (@SPEC_VERSIONS) {

    my $test_dir = catfile(dirname(__FILE__), 'resources', $spec_version);

    my @files = glob("$test_dir/*-$spec_version.json");

FILE: foreach my $file (@files) {

        next FILE if first { basename($file) eq $_ } @SKIP;

        subtest $file => sub {

            my $bom_data = decode_json(file_read($file));

            my $validator = SBOM::CycloneDX::Schema->new(bom => $bom_data);

            my @errors = $validator->validate;

            if ($file =~ /invalid-/) {
                isnt scalar @errors, 0;
            }
            else {
                fail $_ for @errors;
                is scalar @errors, 0;
            }

        }

    }

}


done_testing();
