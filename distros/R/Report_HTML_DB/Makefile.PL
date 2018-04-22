use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Report_HTML_DB',
    VERSION_FROM        => 'script/report_html_db.pl',
    ABSTRACT_FROM       => 'script/report_html_db.pl',
    AUTHOR              => q{Wendel Hime Lino Castro <wendelhime@hotmail.com>},
    LICENSE             => 'gpl_3',
    MIN_PERL_VERSION    => '5.022001',
    EXE_FILES           => ['script/report_html_db.pl'],
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker'   =>  0,
    },
    PREREQ_PM           => {
        'strict'                                            => 0,
        'warnings'                                          => 0,
        'Class::Load'                                       => 0,
        'Class::Load::PP'                                   => 0,
        'Class::Load::XS'                                   => 0,
        'Class::MOP'                                        => 0,
        'Data::OptList'                                     => 0,
        'Moose'                                             => 0,
        'Moose::Role'                                       => 0,
        'Moose::Exporter'                                   => 0,
        'Moose::Util::TypeConstraint'                       => 0,
        'DBIx::Class'                                       => 0,
        'DBD::Pg'                                           => 0,
        'Catalyst::Devel'                                   => 0,
        'Catalyst::Runtime'                                 => 0,
        'YAML'                                              => 0,
        'Archive::Zip'                                      => 0,
        'File::Find::Rule'                                  => 0,
        'Catalyst::Action::REST'                            => 0,
        'Catalyst::ScriptRunner'                            => 0,
        'Catalyst::View::TT'                                => 0,
        'Catalyst::View::JSON'                              => 0,
        'Catalyst::Model::DBIC::Schema'                     => 0,
        'DBIx::Class::Schema::Loader'                       => 0,
        'MooseX::NonMoose'                                  => 0,
        'DBIx::Class::Helper::ResultSet::SetOperations'     => 0,
        'Catalyst::Restarter'                               => 0,
        'Catalyst::Model::Adaptor'                          => 0,
        'Catalyst::Model::DBI'                              => 0,
        'MooseX::Storage'                                   => 0,
        'Catalyst::Controller::REST'                        => 0,
        'Catalyst::Model::DBIC::Schema'                     => 0,
        'Archive::Zip'                                      => 0,
        'Catalyst::Engine::Apache'                          => 0,
        'Capture::Tiny'                                     => 0,
        'DBI'                                               => 0,
        'Task::Catalyst'                                    => 0,
        'Task::Plack'                                       => 0,
        'Reindeer'                                          => 0,
        'SQL::Library'                                      => 0,
        'Catalyst::Model::DBI::SQL::Library'                => 0,
        'Catalyst::Model::DBI'                              => 0,
        'LWP::UserAgent::Cached'                            => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE  =>  {
                'meta-spec' => {version => 2},
                provides => {
                    'Report_HTML_DB' => {
                        'file' => 'lib/Report_HTML_DB.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Clients' => {
                        'file' => 'lib/Report_HTML_DB/Clients.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Clients::BlastClient' => {
                        'file' => 'lib/Report_HTML_DB/Clients/BlastClient.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Clients::SearchDBClient' => {
                        'file' => 'lib/Report_HTML_DB/Clients/SearchDBClient.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models' => {
                        'file' => 'lib/Report_HTML_DB/Models.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Services' => {
                        'file' => 'lib/Report_HTML_DB/Models/Services.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::AlienHunterSearch' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/AlienHunterSearch.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::Feature' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/Feature.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::NcRNASearch' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/NcRNASearch.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::RBSSearch' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/RBSSearch.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::Subevidence' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/Subevidence.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::TRFSearch' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/TRFSearch.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::TRNASearch' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/TRNASearch.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Application::TranscriptionalTerminator' => {
                        'file' => 'lib/Report_HTML_DB/Models/Application/TranscriptionalTerminator.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Services::BaseResponse' => {
                        'file' => 'lib/Report_HTML_DB/Models/Services/BaseResponse.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Models::Services::PagedResponse' => {
                        'file' => 'lib/Report_HTML_DB/Models/Services/PagedResponse.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Repositories' => {
                        'file' => 'lib/Report_HTML_DB/Repositories.pm',
                        'version' => '0.01',
                    },
                    'Report_HTML_DB::Repositories::BlastRepository' => {
                        'file' => 'lib/Report_HTML_DB/Repositories/BlastRepository.pm',
                        'version' => '0.01',
                    },
                },
                resources => {
                    repository  => {
                        type    => 'git',
                        url     => 'https://github.com/WendelHime/report_html_db.git',
                        web     => 'https://github.com/WendelHime/report_html_db',
                    }
                }
            }) : ()
    ),
);
