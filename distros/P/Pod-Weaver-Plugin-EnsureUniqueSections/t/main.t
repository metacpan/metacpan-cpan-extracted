use strict;
use warnings;

use Test::More;
use Test::Exception;
use Moose::Autobox 0.10;

use PPI;

use Pod::Elemental;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

use Pod::Weaver;

require Software::License::Artistic_1_0;

sub slurp_file {
    do { local $/; open my $fh, '<', shift; <$fh> };
}

sub read_pod {
    Pod::Elemental->read_string(slurp_file(shift));
}

my $perl_document = do { local $/; <DATA> };
my $ppi_document  = PPI::Document->new(\$perl_document);

sub try_weave {
    my ($weaver, $pod_document) = @_;

    my $woven = $weaver->weave_document({
        pod_document => $pod_document,
        ppi_document => $ppi_document,

        version  => '1.012078',
        authors  => [
            'Ricardo Signes <rjbs@example.com>',
            'Molly Millions <sshears@orbit.tash>',
        ],
        license  => Software::License::Artistic_1_0->new({
            holder => 'Ricardo Signes',
            year   => 1999,
        }),
    });
    return $woven;
}

my $no_dups_pod = read_pod 't/eg/no-duplicates.pod';

my $inexact_dup_pod = read_pod 't/eg/inexact-duplicate.pod';

my @dup_pods = map { read_pod "t/eg/$_" }
    qw( duplicate-leftovers.pod
        duplicate-synopsis.pod
        with-author-section.pod );

my $weaver = Pod::Weaver->new_from_config({ root => 't/eg' });
my $strict_weaver = Pod::Weaver->new_from_config({ root => 't/eg/strict' });

my $error_regex = qr{The following headers appear multiple times};

lives_ok {
    try_weave($weaver, $no_dups_pod);
} "doesn't throw error on a POD document with no duplicated headings.";

throws_ok {
    try_weave($weaver, $inexact_dup_pod);
} $error_regex, 'Non-strict mode throws error on inexact duplicate headers';

lives_ok {
    try_weave($strict_weaver, $inexact_dup_pod);
} 'Strict mode does not throw error on inexact duplicate headers';

for my $pod (@dup_pods) {
    throws_ok{
        try_weave($weaver, $pod);
    } $error_regex, 'throws error on pod with duplicate sections, whether pre-existing or generated.';
}

done_testing;

__DATA__

package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';
