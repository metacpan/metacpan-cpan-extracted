
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'Plack Middleware for mapping urls to status code-driven responses',
                       'script_files' => [],
                       'license' => 'perl',
                       'build_requires' => {
                                             'Test::More' => '0',
                                             'Plack::Test' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0',
                                             'Module::Build' => '0.3601',
                                             'Plack::Builder' => '0',
                                             'HTTP::Request::Common' => '0'
                                           },
                       'dist_name' => 'Plack-Middleware-Status',
                       'dist_author' => [
                                          'Patrick Donelan <pat@patspam.com>'
                                        ],
                       'module_name' => 'Plack::Middleware::Status',
                       'requires' => {
                                       'Plack::Middleware' => '0',
                                       'parent' => '0',
                                       'Plack::Util::Accessor' => '0',
                                       'HTTP::Status' => '0',
                                       'Carp' => '0'
                                     },
                       'recommends' => {},
                       'configure_requires' => {
                                                 'ExtUtils::MakeMaker' => '6.31',
                                                 'Module::Build' => '0.3601'
                                               },
                       'dist_version' => '1.101150'
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
