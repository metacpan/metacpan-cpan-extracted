use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Safe::Hole',
    dist_version_from   => 'lib/Safe/Hole.pm',
    abstract_from       => 'lib/Safe/Hole.pm',
    dist_abstract       => 'lib/Safe/Hole.pm',
    license             => 'perl',
    build_requires      => {
	'Test::More'    => '0.40', 
	'Module::Build' => '0.35',
    },
    add_to_cleanup      => [qw(Safe-Hole-* lib/Safe/*.c lib/Safe/*.o)],
    meta_merge     => {
	resources => {
        homepage => 'http://github.com/toddr/Safe-Hole',
        bugtracker => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=Safe-Hole',
        MailingList => 'mailto:toddr@cpan.org',
        repository  => 'git://github.com/toddr/Safe-Hole.git',
	}
    }
    );

$builder->create_build_script;
