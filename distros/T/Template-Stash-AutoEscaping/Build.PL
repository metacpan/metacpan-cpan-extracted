use strict;
use warnings;

use lib './inc';

use Test::Run::Builder;

my $mb = Test::Run::Builder->new(
    module_name => 'Template::Stash::AutoEscaping',
    license => 'perl',
    dist_author => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from => 'lib/Template/Stash/AutoEscaping.pm',
    requires =>
    {
        'Class::Data::Inheritable' => 0,
        'Data::Dumper' => 0,
        'Template' => 0,
        'Template::Config' => 0,
        'Template::Exception' => 0,
        'UNIVERSAL::require' => 0,
        'base' => 0,
        'overload' => 0,
        'parent' => 0,
        'perl' => '5.012',
        'strict' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'Test::More' => 0,
        'URI' => 0,
        'Test::Base' => 0,
    },
    configure_requires =>
    {
        'Module::Build' => 0.36,
    },
    meta_merge =>
    {
        resources =>
        {
            repository => "http://github.com/shlomif/Template-Stash-AutoEscaping",
        },
        keywords =>
        [
            'autoescape',
            'autoescaping',
            'escape',
            'injection',
            'security',
            'stash',
            'template',
            'toolkit',
            'xss',
        ],
    },
);

$mb->create_build_script();
