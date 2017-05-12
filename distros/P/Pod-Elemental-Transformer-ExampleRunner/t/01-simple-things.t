use Test::More;
BEGIN {
    use_ok('Pod::Elemental::Transformer::ExampleRunner');
}

diag ($Pod::Elemental::Transformer::ExampleRunner::VERSION);

use strict;
use warnings; 

use lib qw[ lib ];
use Pod::Elemental::Transformer::ExampleRunner;
use Pod::Elemental;

my $pod_document = Pod::Elemental->read_file( 't/data/pod/simple-things.pod');

my $xform = Pod::Elemental::Transformer::ExampleRunner->new( {
        command => 'pester',
        script_path => 't/data/scripts/',
        indent      => 'AWESOME CODE, RIGHT HERE --> ',
    });
$xform->transform_node($pod_document);
my $pod = $pod_document->as_pod_string();

like (
    $pod,
    qr/Lorem ipsum dolor sit amet, consectetur adipiscing elit/,
    "pod has Lorem ipsum dolor sit amet..."
);

like (
    $pod,
    qr/AWESOME CODE, RIGHT HERE --> /,
    "had the indent"
);
like (
    $pod,
    qr/# this script is aweslome!/,
    "had some stuff from well-documented-script"
);

# the script does some hard calcualtions, we check the pod for them too
like (
    $pod,
    qr/3 x 4 = 12/,
    "had some stuff from the execution of well-documented-script"
);
done_testing;
