use strict;
use warnings;

use inc::MyBuilder;

use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Sys::Path::SPc;

my $builder = inc::MyBuilder->new(
    module_name         => 'Sys::Path',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Sys/Path.pm',
    configure_requires => {
        'Module::Build' => '0.3607',
    },
    requires => {
        'File::Spec'      => 0,
        'List::MoreUtils' => 0,
        'Text::Diff'      => 0,
        'JSON::Util'      => 0,
        'Digest::MD5'     => 0,
        'Text::Diff'      => 0,
        'Cwd'             => 0,
    },
    build_requires => {
        'Test::More'      => 0,
        'File::Temp'      => 0,
        'File::Path'      => 2.07,    # Introduce make_path() and rm_tree() API extension.
        'Test::Differences' => 0,
        'Test::Exception' => 0,
        'Capture::Tiny'   => 0,
    },
    add_to_cleanup      => [ 'Sys-Path-*' ],
    create_readme       => 1,
    get_options         => {
        'sp-prefix'        => { type => '=s' },
        'sp-localstatedir' => { type => '=s' },
        'sp-sysconfdir'    => { type => '=s' },
        'sp-datadir'       => { type => '=s' },
        'sp-docdir'        => { type => '=s' },
        'sp-cache'         => { type => '=s' },
        'sp-log'           => { type => '=s' },
        'sp-spool'         => { type => '=s' },
        'sp-run'           => { type => '=s' },
        'sp-lock'          => { type => '=s' },
        'sp-state'         => { type => '=s' },
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Sys-Path.git',
            bugtracker => 'http://github.com/jozef/Sys-Path/issues',
        },
        keywords => [ qw/ system paths instalation deployment applications / ],
    },
    sharedstatedir_files => {
        'varlib/syspath/.exists' => 'sharedstatedir/syspath/.exists',
    },
);

my @path_types = Sys::Path::SPc->_path_types;
$builder->notes('path_types' => join('|', @path_types));

print qq{
Configuring Sys::Path distribution

This module tells other perl modules/scripts where your common system
files are, and will supply reasonable guesses. If unsure just hit enter
to each of these.

For more information about the meaning, check Sys::Path documentation:
http://search.cpan.org/perldoc?Sys%3A%3APath#PATHS

};

foreach my $path_type (@path_types) {
    my $path = $builder->args('sp-'.$path_type);
    $path = $builder->prompt($path_type, Sys::Path::SPc->$path_type)
        if not $path;
    Sys::Path::SPc->$path_type($path);
    $builder->notes($path_type => $path);
    print $path_type, ' set to: ', $path, "\n";
}

$builder->{'properties'}->{'install_path'}->{'sharedstatedir'} = Sys::Path::SPc->sharedstatedir;
$builder->add_build_element('sharedstatedir');

$builder->create_build_script();
