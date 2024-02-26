use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'PGXN::Build',
    code => q{
        sub valid_licenses { { postgresql => 'PostgreSQL' } }
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

my $build = $class->new(
    module_name        => 'PGXN::Site',
    license            => 'postgresql',
    script_files       => 'bin',
    configure_requires => { 'Module::Build' => '0.4209' },
    requires => {
        'Carp'                         => 0,
        'Data::Dump'                   => '1.17',
        'Encode'                       => '2.40',
        'Gravatar::URL'                => '1.02',
        'Email::MIME'                  => '1.901',
        'Email::Sender::Simple'        => '0.093110',
        'File::Basename'               => 0,
        'File::Spec'                   => 0,
        'HTML::TagCloud'               => '0.34',
        'I18N::LangTags::Detect'       => '1.03',
        'Locale::Maketext'             => '1.16',
        'List::Util'                   => '1.20',
        'List::MoreUtils'              => '0.28',
        'namespace::autoclean'         => '0.11',
        'perl'                         => '5.14.0',
        'Plack'                        => '0.9956',
        'Plack::App::File'             => 0,
        'Plack::Builder'               => 0,
        'Plack::Request'               => '0.9956',
        'Plack::Response'              => '0.9956',
        'Router::Resource'             => '0.11',
        'SemVer'                       => '0.10.0',
        'Software::License'            => '0.102340',
        'Template::Declare'            => '0.43',
        'Template::Declare::Tags'      => '0.43',
        'WWW::PGXN'                    => '0.12.0',
    },
    test_requires => {
        'HTTP::Message::PSGI'   => 0,
        'HTTP::Request::Common' => '5.824',
        'Plack::Test'          => 0,
        'Test::File::Contents' => '0.20',
        'Test::More'           => '0.70',
        'Test::MockModule'     => '0.05',
    },
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://www.pgxn.org/',
            bugtracker => 'https://github.com/pgxn/pgxn-site/issues/',
            repository => 'https://github.com/pgxn/pgxn-site/',
        },
        prereqs => {
            test => {
                recommends => {
                    'Test::Pod'             => '1.41',
                    'Test::Pod::Coverage'   => '1.06',
                    'Test::XML'             => '0.08',
                    'Test::XPath'           => '0.13',
                    'PGXN::API::Searcher'   => '0.10.1',
                },
            },
        },
    },
);

$build->add_build_element($_) for qw(css gif png jpg js html eps svg json ico);
$build->create_build_script;
