use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'String::UnicodeUTF8',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/String/UnicodeUTF8.pm',
    requires          => {
        'Test::More'          => 0,     # for testing, I know I know: Test::XT
        'String::Unquotemeta' => 0,
        'Module::Want'        => 0.6,
        'B::Flags'            => 0,     # make optional?
    },
    add_to_cleanup => ['String-UnicodeUTF8-*'],
);

$builder->create_build_script();
