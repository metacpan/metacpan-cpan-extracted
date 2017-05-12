use inc::Module::Install;

name           'Task-Litmus';
all_from       'lib/Task/Litmus.pm';
#build_requires 'Test::More'                => '0.42';
#build_requires 'File::Spec'                => '0.80';

requires     'perl'                             => '5.008';
requires     'CGI'                              => '0';
requires     'Class::DBI'                       => '0';
requires     'Class::DBI::mysql'                => '0';
requires     'Class::DBI::Pager'                => '0';
requires     'Class::DBI::Plugin::RetrieveAll'  => '0';
requires     'Class::DBI::Search::Basic'        => '0';
requires     'Data::Dumper'                     => '0';
requires     'Data::JavaScript'                 => '0';
requires     'Date::Manip'                      => '0';
requires     'DBIx::ContextualFetch'            => '0';
requires     'Encode'                           => '0';
requires     'File::Find'                       => '0';
requires     'Getopt::Long'                     => '0';
requires     'HTML::StripScripts'               => '0';
requires     'HTML::StripScripts::Parser'       => '0';
requires     'JSON'                             => '2.0';
requires     'JSON::XS'                         => '0';
requires     'JSON::PP'                         => '0';
requires     'Sys::Hostname'                    => '0';
requires     'Template'                         => '0';
requires     'Test::Harness'                    => '0';
requires     'Text::Markdown'                   => '0';
requires     'Time::HiRes'                      => '0';
requires     'Time::Piece'                      => '0';
requires     'Time::Piece::MySQL'               => '0';
requires     'Time::Seconds'                    => '0';
requires     'XML::XPath'                       => '0';
requires     'utf8'                             => '0';

repository 'https://github.com/szabgab/Task-Litmus';

WriteAll;

