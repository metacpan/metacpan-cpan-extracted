use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_tarball_name { print shift->dist_dir . ".tar.gz\n" }
        sub ACTION_latest_changes {
            my $self = shift;
            (my $dv = $self->dist_version) =~ s/^v//;
            open my $in, '<:raw', 'Changes' or die "Cannot open Changes: $!\n";
            open my $out, '>:raw', 'latest_changes.md' or die "Cannot open latest_changes.md: $!\n";
            while (<$in>) { last if /^\Q$dv\E\b/ }
            print {$out} "Changes for v$dv\n";
            while (<$in>) {
                last if /^\s*$/;
                chomp;
                if (s/^\s+-/-  /) {
                    print {$out} "\n";
                } else {
                    s/^\s+/ /;
                }
                print {$out} $_;
            }
            $self->add_to_cleanup('latest_changes.md');
        }
    },
);

$class->new(
    module_name        => 'PGXN::API::Searcher',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.4209' },
    build_requires     => {
        'Module::Build' => '0.4209',
    },
    test_requires => {
        'File::Path'            => '2.08',
        'File::Spec::Functions' => 0,
        'Test::More'            => '0.96',
    },
    requires => {
        'Carp'       => 0,
        'File::Spec' => 0,
        'Lucy'       => '0.2.1',
        'perl'       => '5.10.0',
    },
    meta_merge => {
        resources => {
            homepage   => 'https://metacpan.org/dist/PGXN-API-Searcher',
            bugtracker => 'https://github.com/pgxn/pgxn-api-searcher/issues/',
            repository => 'https://github.com/pgxn/pgxn-api-searcher/',
        }
    },
)->create_build_script;
