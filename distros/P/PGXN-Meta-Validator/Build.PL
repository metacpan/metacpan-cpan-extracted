use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_install {
            my $self = shift;
            my $ret = $self->SUPER::ACTION_install(@_);
            my $pgxn = $self->find_command('pgxn') or return $ret;
            my $libexec = $self->_backticks($pgxn, 'help', '--libexec');
            chomp $libexec;
            File::Path::mkpath($libexec, 0, 0755);
            if (-d $libexec) {
                my $dst = File::Spec->catfile($libexec, 'pgxn-validate-meta');
                $self->log_info("Creating $dst");
                unlink $dst;
                link File::Spec->catfile(
                    $self->install_map->{'blib/script'}, 'validate_pgxn_meta'
                ), $dst;
            }
        }
    },
);

$class->new(
    module_name        => 'PGXN::Meta::Validator',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30' },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.88',
    },
    requires => {
        'Carp'   => 0,
        'Getopt::Long' => 0,
        'JSON'         => 0,
        'perl'         => 5.010,
        'Pod::Usage'   => 0,
        'SemVer'       => '0.5.0',
    },
    recommends => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/PGXN-Meta-Validator/',
            bugtracker => 'http://github.com/pgxn/pgxn-meta-validator/issues/',
            repository => 'http://github.com/pgxn/pgxn-meta-validator/tree/',
        }
    },
)->create_build_script;
