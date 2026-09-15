use strict;
use warnings;

BEGIN { push @INC, '.'; }
use inc::MyBuilder;

use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Sys::Path::SPc;

my @path_types = Sys::Path::SPc->_path_types;
my %option_aliases = (
    cachedir       => 'cache',
    logdir         => 'log',
    spooldir       => 'spool',
    rundir         => 'run',
    lockdir        => 'lock',
    sharedstatedir => 'state',
);
my %path_options = map { ('sp-'.$_ => { type => '=s' }) } @path_types;
my %alias_options = map {
    ('sp-'.$option_aliases{$_} => { type => '=s' })
} keys %option_aliases;

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
        'List::Util'      => '1.33',
        'Text::Diff'      => 0,
        'JSON::Util'      => '0.06',
        'IO::Any'         => '0.09',
        'Digest::MD5'     => 0,
        'Cwd'             => 0,
        'Shell::Guess'    => 0,
        'Module::Path'    => 0,
    },
    build_requires => {
        'Test::More'      => 0,
        'File::Temp'      => 0,
        'File::Path'      => 2.07,    # Introduce make_path() and rm_tree() API extension.
        'Test::Differences' => 0,
        'Capture::Tiny'   => 0,
    },
    add_to_cleanup      => [ 'Sys-Path-*' ],
    create_readme       => 1,
    script_files        => [ 'script/syspath.pl' ],
    get_options         => { %path_options, %alias_options },
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
    $path = $builder->args('sp-'.$option_aliases{$path_type})
        if not defined($path) and exists($option_aliases{$path_type});
    $path = $builder->prompt($path_type, Sys::Path::SPc->$path_type)
        if not $path;
    Sys::Path::SPc->$path_type($path);
    $builder->notes($path_type => $path);
    print $path_type, ' set to: ', $path, "\n";
}

$builder->{'properties'}->{'install_path'}->{'sharedstatedir'}
    = $builder->notes('sharedstatedir');
$builder->add_build_element('sharedstatedir');

$builder->create_build_script();
