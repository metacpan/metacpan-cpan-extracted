use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'PGXN::Build',
    code => q{
        sub valid_licenses { { postgresql => 'PostgreSQL' } }
        sub process_mmd_files {
            require Text::MultiMarkdown;
            my $self  = shift;
            my $m     = Text::MultiMarkdown->new(
                img_ids     => 0,
                heading_ids => 0,
            );
            my $files = $self->_find_file_by_type('mmd', 'lib');

            while (my ($file, $to) = each %$files) {
                $to =~ s{[.]mmd$}{.html};
                $to = File::Spec->catfile($self->blib, $to);
                unless ($self->up_to_date( $file, $to )) {
                    File::Path::mkpath(File::Basename::dirname($to), 0, oct(777));
                    $self->log_verbose("Converting $file -> $to\n");
                    open my $in,  '<:utf8', $file or die "Cannot open $file: $!\n";
                    chmod 0666, $to;
                    open my $out, '>:utf8', $to   or die "Cannot open $to: $!\n";
                    local $/;
                    print $out $m->markdown(<$in>);
                    close $in;
                    chmod 0444, $to;

                }
            }
        }
    },
);

my $build = $class->new(
    module_name        => 'PGXN::Site',
    license            => 'postgresql',
    script_files       => 'bin',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'HTTP::Message::PSGI'  => 0,
        'Module::Build'        => '0.30',
        'Plack::Test'          => 0,
        'Software::License'    => '0.102340',
        'Test::File::Contents' => '0.20',
        'Test::More'           => '0.70',
        'Test::MockModule'     => '0.05',
        'Text::MultiMarkdown'  => '1.000033',
    },
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
        'perl'                         => 5.010,
        'Plack'                        => '0.9956',
        'Plack::App::File'             => 0,
        'Plack::Builder'               => 0,
        'Plack::Request'               => '0.9956',
        'Plack::Response'              => '0.9956',
        'Router::Resource'             => '0.11',
        'SemVer'                       => '0.2.0',
        'Software::License'            => '0.102340',
        'Template::Declare'            => '0.43',
        'Template::Declare::Tags'      => '0.43',
        'WWW::PGXN'                    => '0.12.0',
    },
    test_recommends => {
        'HTTP::Request::Common' => '5.824',
        'Test::Pod'             => '1.41',
        'Test::Pod::Coverage'   => '1.06',
        'Test::XML'             => '0.08',
        'Test::XPath'           => '0.13',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://www.pgxn.org/',
            bugtracker => 'http://github.com/pgxn/pgxn/issues/',
            repository => 'http://github.com/pgxn/pgxn/tree/',
        },
    },
);

$build->add_build_element($_) for qw(css gif png jpg js mmd eps svg);
$build->create_build_script;
