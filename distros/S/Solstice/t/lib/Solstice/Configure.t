
use strict;
use warnings;
use 5.006_000;

use Test::More;
use FindBin;
use Data::Dumper;
use constant TRUE => 1;
use constant FALSE => 0;

use Solstice::Configure;

plan(tests => 97);


#METHODOLOGY
#
# We have two sets of the same tests: The first one parses a solstice config file with no apps,
# and then we munge the object's data to simulate a new config object with a namespace.
# This tests the two main ways the object can be built.

$ENV{'SOLSTICE_CONFIG_PATH'} = $FindBin::Bin .'/configure_testing_resources/solstice_config.xml';
$Solstice::Service::Memory::data_store = {};



ok(my $configure = Solstice::Configure->new(), 'create config object');
my $root = $configure->getRoot();

is($configure->getWebServiceRestRoot(), 'rest', 'getWebServiceRestRoot');
is($configure->getURL(), '/tools/', 'getURL');
is($configure->getDataRoot(), '/home/fakeuser/data', 'getDataRoot');
is($configure->getVirtualRoot(), '/tools/', 'getVirtualRoot');
is($configure->getServerString(), 'Inkey Dev', 'getServerString');
is($configure->getAdminEmail(),   'fakeuser@u.washington.edu', 'getAdminEmail');
is($configure->getSupportEmail(), 'fakeuser@u.washington.edu', 'getSupportEmail');
is($configure->getDBHost (), 'example.washington.edu', 'getDBHost');
is($configure->getDBPort (), 3306, 'getDBPort');
is($configure->getDBUser (), 'ctlt', 'getDBUser');
is($configure->getCentralDebugLevel (), 'scam', 'getCentralDebugLevel');
is($configure->getDBPassword (), 'foopassword', 'getDBPassword');
is($configure->getDBName (), 'solstice', 'getDBName');
is($configure->getEncryptionKey (), "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 'getEncryptionKey');
is($configure->getLang (), 'en', 'getLang');
is($configure->getBoilerplateView (), 'Foo::View::Boilerplate::BlueSwoosh', 'getBoilerplateView');
is($configure->getErrorHTML (), 'error', 'getErrorHTML'); 
is($configure->getErrorHandler (), undef, 'getErrorHandler');
is($configure->getSessionBackend (), 'MySQL', 'getSessionBackend');
is($configure->getSessionDB (), 'sessions', 'getSessionDB');
is($configure->getSessionCookie (), 'solsticeSessionID', 'getSessionCookie');
is($configure->getSMTPServer (), 'localhost', 'getSMTPServer');
is($configure->getSMTPMailname (), 'localhost', 'getSMTPMailname');
is($configure->getSMTPMessageWait (), '0.5', 'getSMTPMessageWait');
is($configure->getSMTPUseQueue (), 'never', 'getSMTPUseQueue');
is($configure->getCompiledViewPath (), '/home/fakeuser/data/solstice_compiled_views', 'getCompiledViewPath');
is($configure->getDevelopmentMode (), 1, 'getDevelopmentMode');
is($configure->getSlowQueryTime (), 1, 'getSlowQueryTime');
is($configure->getNoConfig (), 0, 'getNoConfig');

is_deeply($configure->getNamespaces (), [], 'getNamespaces');
is_deeply($configure->getDBSlaves (), [
    {
        'password' => 'foopassword',
        'database_name' => 'solstice',
        'user' => 'ctlt',
        'host_name' => 'example-slave1.washington.edu',
        'type' => 'slave',
        'port' => '3306'
    },
    {
        'password' => 'foopassword',
        'database_name' => 'solstice',
        'user' => 'ctlt',
        'host_name' => 'example-slave2.washington.edu',
        'type' => 'slave',
        'port' => '3306'
    }
    ], 'getDBSlaves');

is_deeply($configure->getRemoteDefs (), {
        'Solstice' => {
            'subsession_check' => 'Solstice::Controller::Remote::SubsessionCheck',
            'upload_meter' => 'Solstice::Controller::Remote::UploadMeter'
        }
    }, 'getRemoteDefs');

is_deeply($configure->getMemcachedServers (), [
    '127.0.0.1:11211'
    ], 'getMemcachedServers');
is_deeply($configure->getAppDirs (), [
    '/home/fake/apps/'
    ], 'getAppDirs');
is_deeply($configure->getCSSFiles (), [
    'styles/solstice.css'
    ], 'getCSSFiles');
is_deeply($configure->getJSFiles (), [
    'javascript/solstice.js',
    'javascript/remote.js',
    'javascript/yui/build/yahoo/yahoo-min.js',
    'javascript/yui/build/event/event-min.js',
    'javascript/yui/build/dom/dom-min.js',
    'javascript/yui/build/dragdrop/dragdrop-min.js',
    'javascript/yui/build/connection/connection-min.js',
    'javascript/yui/build/container/container-min.js',
    'javascript/yahooui.js'
    ], 'getJSFiles');
is_deeply($configure->getLogModules (),  [
    'Solstice::Logger::File',
    'Solstice::Logger::Database'
    ], 'getLogModules');
is_deeply($configure->getStaticDirs (), {
        '/tools/images/' => {
            'virtual_path' => 'images',
            'filesys_path' => $root.'/images'
        },
        '/tools/javascript/' => {
            'virtual_path' => 'javascript',
            'filesys_path' => $root.'/javascript'
        },
        '/tools/content/' => {
            'virtual_path' => 'content',
            'filesys_path' => $root.'/content'
        },
        '/tools/styles/' => {
            'virtual_path' => 'styles',
            'filesys_path' => $root.'/styles'
        }
    }, 'getStaticDirs');
is_deeply($configure->getCGIUrls (), {
        '/tools/remote/locking.cgi' => {
            'virtual_path' => 'remote/locking.cgi',
            'filesys_path' => $root.'/cgis/locking.cgi',
            'requires_auth' => '1',
            'config_namespace'  => 'Solstice',
            'url_is_prefix' => 0,
        },
        '/tools/file_thumbnail.cgi' => {
            'virtual_path' => 'file_thumbnail.cgi',
            'filesys_path' => $root.'/cgis/file_thumbnail.cgi',
            'requires_auth' => '0',
            'config_namespace'  => 'Solstice',
            'url_is_prefix' => 0,
        },
        '/tools/file_download.cgi' => {
            'virtual_path' => 'file_download.cgi',
            'filesys_path' => $root.'/cgis/file_download.cgi',
            'requires_auth' => '0',
            'config_namespace'  => 'Solstice',
            'url_is_prefix' => 0,
        },
        '/tools/file_latex.cgi' => {
            'virtual_path' => 'file_latex.cgi',
            'filesys_path' => $root.'/cgis/file_latex.cgi',
            'requires_auth' => '0',
            'config_namespace'  => 'Solstice',
            'url_is_prefix' => 0,
        },
        '/tools/file_upload.cgi' => {
            'virtual_path' => 'file_upload.cgi',
            'filesys_path' => $root.'/cgis/file_upload.cgi',
            'requires_auth' => '0',
            'config_namespace'  => 'Solstice',
            'url_is_prefix' => 0,
        }
    }, 'getCGIUrls');
is_deeply($configure->getWebserviceUrls (), {}, 'getWebserviceUrls');
is_deeply($configure->getStartupFiles (), [], 'getStartupFiles');
is_deeply($configure->getStateFiles (), {}, 'getStateFiles');

is_deeply($configure->getAppUrls (), {} , 'getAppUrls');
is($configure->getAppVirtualRoot(), undef, 'getAppVirtualRoot');
is($configure->getAppURL (), undef, 'getAppURL');
is($configure->getAppRoot (), undef, 'getAppRoot');
is($configure->getAppDBName (), '', 'getAppDBName');

# Okay, now we jimmy the app dir to include our test application
# we also need to re-run these few lines lifted from the end of 
# Configure's _initialize method to pull in the app config

my $ginned_up_app_dir = $FindBin::Bin .'/configure_testing_resources/';
$configure->setValue('STANDARD__solstice__app_dirs', [$ginned_up_app_dir]);
$configure->setValue('__solstice_app_config_files', undef);

#and the app-specific ones
for my $config_file ($configure->_getAppConfigFiles()) {
    $configure->_parseAppConfig($config_file);
}

#now that all of our app libs are in @INC we may load up all application files
for my $config_file ($configure->_getAppConfigFiles()) {
    $configure->_initApplicationObject($config_file);
}

$configure->setSection('Solstice');

# Okay, we're ready to re-run our tests, this time with application data loaded
is($configure->getRoot(), $root, 'getRoot');
is($configure->getWebServiceRestRoot(), 'rest', 'getWebServiceRestRoot');
is($configure->getURL(), '/tools/', 'getURL');
is($configure->getDataRoot(), '/home/fakeuser/data', 'getDataRoot');
is($configure->getVirtualRoot(), '/tools/', 'getVirtualRoot');
is($configure->getServerString(), 'Inkey Dev', 'getServerString');
is($configure->getAdminEmail(),   'fakeuser@u.washington.edu', 'getAdminEmail');
is($configure->getSupportEmail(), 'fakeuser@u.washington.edu', 'getSupportEmail');
is($configure->getDBHost (), 'example.washington.edu', 'getDBHost');
is($configure->getDBPort (), 3306, 'getDBPort');
is($configure->getDBUser (), 'ctlt', 'getDBUser');
is($configure->getCentralDebugLevel (), 'scam', 'getCentralDebugLevel');
is($configure->getDBPassword (), 'foopassword', 'getDBPassword');
is($configure->getDBName (), 'solstice', 'getDBName');
is($configure->getEncryptionKey (), "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", 'getEncryptionKey');
is($configure->getLang (), 'en', 'getLang');
is($configure->getBoilerplateView (), 'Foo::View::Boilerplate::BlueSwoosh', 'getBoilerplateView');
is($configure->getErrorHTML (), 'error', 'getErrorHTML'); 
is($configure->getErrorHandler (), 'WebQ::ErrorHandler', 'getErrorHandler');
is($configure->getSessionBackend (), 'MySQL', 'getSessionBackend');
is($configure->getSessionDB (), 'sessions', 'getSessionDB');
is($configure->getSessionCookie (), 'solsticeSessionID', 'getSessionCookie');
is($configure->getSMTPServer (), 'localhost', 'getSMTPServer');
is($configure->getSMTPMailname (), 'localhost', 'getSMTPMailname');
is($configure->getSMTPMessageWait (), '0.5', 'getSMTPMessageWait');
is($configure->getSMTPUseQueue (), 'never', 'getSMTPUseQueue');
is($configure->getCompiledViewPath (), '/home/fakeuser/data/solstice_compiled_views', 'getCompiledViewPath');
is($configure->getDevelopmentMode (), 1, 'getDevelopmentMode');
is($configure->getSlowQueryTime (), 1, 'getSlowQueryTime');
is($configure->getNoConfig (), 0, 'getNoConfig');

is_deeply($configure->getNamespaces (), ['Solstice'], 'getNamespaces');
is_deeply($configure->getDBSlaves (), [
    {
        'password' => 'foopassword',
        'database_name' => 'solstice',
        'user' => 'ctlt',
        'host_name' => 'example-slave1.washington.edu',
        'type' => 'slave',
        'port' => '3306'
    },
    {
        'password' => 'foopassword',
        'database_name' => 'solstice',
        'user' => 'ctlt',
        'host_name' => 'example-slave2.washington.edu',
        'type' => 'slave',
        'port' => '3306'
    }
    ], 'getDBSlaves');



is_deeply($configure->getRemoteDefs (), {
        'Solstice' => {
            'response_content' => 'WebQ::Controller::Remote::ResponseContent',
            'subsession_check' => 'Solstice::Controller::Remote::SubsessionCheck',
            'participant_moniker' => 'WebQ::Controller::Remote::ParticipantMoniker',
            'download_progress' => 'WebQ::Controller::Remote::DownloadProgress',
            'upload_meter' => 'Solstice::Controller::Remote::UploadMeter',
            'email_urls' => 'WebQ::Controller::Remote::EmailURLs',
            'question_content' => 'WebQ::Controller::Remote::QuestionContent'
        }
    }, 'getRemoteDefs');

is_deeply($configure->getMemcachedServers (), [
    '127.0.0.1:11211'
    ], 'getMemcachedServers');

is_deeply($configure->getAppDirs (), [$ginned_up_app_dir], 'getAppDirs');
is_deeply($configure->getCSSFiles (), [
    'content/webq.css'
    ], 'getCSSFiles');
is_deeply($configure->getJSFiles (), [
    'content/webq.js'
    ], 'getJSFiles');
is_deeply($configure->getLogModules (),  [
    'Solstice::Logger::File',
    'Solstice::Logger::Database'
    ], 'getLogModules');

is_deeply($configure->getStaticDirs (), {
        '/tools/webq/content/' => {
            'virtual_path' => 'content',
            'filesys_path' => $ginned_up_app_dir.'/testapp//content'
        },
        '/tools/images/' => {
            'virtual_path' => 'images',
            'filesys_path' => $root.'/images'
        },
        '/tools/javascript/' => {
            'virtual_path' => 'javascript',
            'filesys_path' => $root.'/javascript'
        },
        '/tools/content/' => {
            'virtual_path' => 'content',
            'filesys_path' => $root.'/content'
        },
        '/tools/webq/images/' => {
            'virtual_path' => 'images',
            'filesys_path' => $ginned_up_app_dir.'/testapp//images'
        },
        '/tools/styles/' => {
            'virtual_path' => 'styles',
            'filesys_path' => $root.'/styles'
        }
    }, 'getStaticDirs');
is_deeply($configure->getCGIUrls (),{
        '/tools/remote/locking.cgi' => {
            'virtual_path' => 'remote/locking.cgi',
            'filesys_path' => $root.'/cgis/locking.cgi',
            'requires_auth' => '1',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => 0,
        },
        '/tools/file_thumbnail.cgi' => {
            'virtual_path' => 'file_thumbnail.cgi',
            'filesys_path' => $root.'/cgis/file_thumbnail.cgi',
            'requires_auth' => '0',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => 0,

        },
        '/tools/file_download.cgi' => {
            'virtual_path' => 'file_download.cgi',
            'filesys_path' => $root.'/cgis/file_download.cgi',
            'requires_auth' => '0',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => 0,

        },
        '/tools/webq/testing.cgi' => {
            'virtual_path' => 'testing.cgi',
            'filesys_path' => $ginned_up_app_dir.'/testapp//testo.cgi',
            'requires_auth' => '0',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => 0,
        },
        '/tools/file_latex.cgi' => {
            'virtual_path' => 'file_latex.cgi',
            'filesys_path' => $root.'/cgis/file_latex.cgi',
            'requires_auth' => '0',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => 0,

        },
        '/tools/file_upload.cgi' => {
            'virtual_path' => 'file_upload.cgi',
            'filesys_path' => $root.'/cgis/file_upload.cgi',
            'requires_auth' => '0',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => 0,

        }
    }, 'getCGIUrls');
is_deeply($configure->getWebserviceUrls (),{
        '/tools/rest/webq/v1/{user}/{id}/results/' => {
            'controller' => 'WebQ::Controller::REST::v1::SurveyResults',
            'virtual_path' => 'v1/{user}/{id}/results',
            'filesys_path' => $ginned_up_app_dir.'/testapp//',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => '1',
            'requires_auth' => '0',
        },
        '/tools/rest/webq/v1/' => {
            'controller' => 'WebQ::Controller::REST::v1::List',
            'virtual_path' => 'v1/',
            'filesys_path' => $ginned_up_app_dir.'/testapp//',
            'config_namespace' => 'Solstice',
            'url_is_prefix' => '0',
            'requires_auth' => '0',
        }
    }, 'getWebserviceUrls');
is_deeply($configure->getStartupFiles (), [
    $ginned_up_app_dir.'/testapp/startup.pl'
    ], 'getStartupFiles');
is_deeply($configure->getStateFiles (), {
        'Solstice' => $ginned_up_app_dir.'/testapp/pageflow.xml'
    }, 'getStateFiles');
is_deeply($configure->getAppUrls (), {
          '/tools/webq/admin/' => {
                                  'filesys_path' => "$ginned_up_app_dir/testapp//",
                                  'debug_level' => '0',
                                  'requires_auth' => 1,
                                  'require_session' => 1,
                                  'pageflow' => 'webq_admin',
                                  'initial_state' => 'admin_menu',
                                  'url_is_prefix' => 0,
                                  'boilerplate_view' => 'Sol::View',
                                  'virtual_path' => 'admin',
                                  'escape_frames' => 1,
                                  'config_namespace' => 'Solstice',
                                  'disable_back_button' => 0,
                                  'title' => 'WebQ',
                                  'view_top_nav' => 1,
                                },
          '/tools/webq/results/' => {
                                    'filesys_path' => "$ginned_up_app_dir/testapp//",
                                    'debug_level' => '0',
                                    'requires_auth' => 1,
                                    'require_session' => 1,
                                    'pageflow' => undef,
                                    'initial_state' => 'results_hub',
                                    'url_is_prefix' => 1,
                                    'boilerplate_view' => 'BlueSlash::View',
                                    'virtual_path' => 'results',
                                    'escape_frames' => 1,
                                    'config_namespace' => 'Solstice',
                                    'disable_back_button' => 0,
                                    'title' => 'WebQ',
                                    'view_top_nav' => 1,
                                  },
          '/tools/webq/begin_preview/' => {
                                          'filesys_path' => "$ginned_up_app_dir/testapp//",
                                          'debug_level' => '0',
                                          'requires_auth' => 1,
                                          'require_session' => 1,
                                          'pageflow' => undef,
                                          'initial_state' => 'begin_preview',
                                          'url_is_prefix' => 1,
                                          'boilerplate_view' => 'BlueBerry::View',
                                          'virtual_path' => 'begin_preview',
                                          'escape_frames' => 0,
                                          'config_namespace' => 'Solstice',
                                          'disable_back_button' => 1,
                                          'title' => 'WebQ Preview',
                                          'view_top_nav' => 0,
                                        },
          '/tools/webq/summary/' => {
                                    'filesys_path' => "$ginned_up_app_dir/testapp//",
                                    'debug_level' => '0',
                                    'requires_auth' => 1,
                                    'require_session' => 1,
                                    'pageflow' => undef,
                                    'initial_state' => 'survey_summary',
                                    'url_is_prefix' => 1,
                                    'boilerplate_view' => 'BlueSlash::View',
                                    'virtual_path' => 'summary',
                                    'escape_frames' => 1,
                                    'config_namespace' => 'Solstice',
                                    'disable_back_button' => 0,
                                    'title' => 'WebQ',
                                    'view_top_nav' => 1,
                                  },
          '/tools/webq/' => {
                            'filesys_path' => "$ginned_up_app_dir/testapp//",
                            'debug_level' => '',
                            'requires_auth' => 1,
                            'require_session' => 1,
                            'pageflow' => undef,
                            'initial_state' => 'home',
                            'url_is_prefix' => 0,
                            'boilerplate_view' => 'BlueSlash::View',
                            'virtual_path' => '/',
                            'escape_frames' => 1,
                            'config_namespace' => 'Solstice',
                            'disable_back_button' => 0,
                            'title' => 'WebQ',
                            'view_top_nav' => 1,
                          },
          '/tools/webq/build/' => {
                                  'filesys_path' => "$ginned_up_app_dir/testapp//",
                                  'debug_level' => '0',
                                  'requires_auth' => 1,
                                  'require_session' => 1,
                                  'pageflow' => undef,
                                  'initial_state' => 'survey_build',
                                  'url_is_prefix' => 1,
                                  'boilerplate_view' => 'BlueSlash::View',
                                  'virtual_path' => 'build',
                                  'escape_frames' => 1,
                                  'config_namespace' => 'Solstice',
                                  'disable_back_button' => 0,
                                  'title' => 'WebQ',
                                  'view_top_nav' => 1,
                                },
          '/tools/webq/graph/' => {
                                  'filesys_path' => "$ginned_up_app_dir/testapp//",
                                  'debug_level' => '0',
                                  'requires_auth' => 1,
                                  'require_session' => 1,
                                  'pageflow' => undef,
                                  'initial_state' => 'generate_survey_graph',
                                  'url_is_prefix' => 0,
                                  'boilerplate_view' => undef,
                                  'virtual_path' => 'graph',
                                  'escape_frames' => 0,
                                  'config_namespace' => 'Solstice',
                                  'disable_back_button' => 0,
                                  'title' => undef,
                                  'view_top_nav' => 1,
                                },
          '/tools/webq/preview/' => {
                                    'filesys_path' => "$ginned_up_app_dir/testapp//",
                                    'debug_level' => '0',
                                    'requires_auth' => 1,
                                    'require_session' => 1,
                                    'pageflow' => undef,
                                    'initial_state' => 'survey_preview',
                                    'url_is_prefix' => 0,
                                    'boilerplate_view' => 'BlueBerry::View',
                                    'virtual_path' => 'preview',
                                    'escape_frames' => 1,
                                    'config_namespace' => 'Solstice',
                                    'disable_back_button' => 0,
                                    'title' => 'WebQ Preview',
                                    'view_top_nav' => 0,
                                  },
          '/tools/webq/survey/login/' => {
                                         'filesys_path' => "$ginned_up_app_dir/testapp//",
                                         'debug_level' => '0',
                                         'requires_auth' => 1,
                                         'require_session' => 1,
                                         'pageflow' => 'webq_participant',
                                         'initial_state' => 'authenticate_user',
                                         'url_is_prefix' => 0,
                                         'boilerplate_view' => 'BlueBerry::View',
                                         'virtual_path' => 'survey/login',
                                         'escape_frames' => 1,
                                         'config_namespace' => 'Solstice',
                                         'disable_back_button' => 0,
                                         'title' => 'WebQ',
                                         'view_top_nav' => 1,
                                       },
          '/tools/webq/survey/' => {
                                   'filesys_path' => "$ginned_up_app_dir/testapp//",
                                   'debug_level' => '0',
                                   'requires_auth' => 0,
                                   'require_session' => 1,
                                   'pageflow' => 'webq_participant',
                                   'initial_state' => 'login_choice',
                                   'url_is_prefix' => 1,
                                   'boilerplate_view' => 'BlueBerry::View',
                                   'virtual_path' => 'survey',
                                   'escape_frames' => 1,
                                   'config_namespace' => 'Solstice',
                                   'disable_back_button' => 0,
                                   'title' => 'WebQ',
                                   'view_top_nav' => 1,
                                 }
        } , 'getAppUrls');



#warn Dumper $configure->getAppUrls();
is($configure->getAppTemplatePath (), $ginned_up_app_dir.'/testapp/templates', 'getAppTemplatePath');
is($configure->getAppVirtualRoot(), 'webq', 'getAppVirtualRoot');
is($configure->getAppURL (), 'webq', 'getAppURL');
is($configure->getAppRoot (), $ginned_up_app_dir.'/testapp/', 'getAppRoot');
is($configure->getAppDBName (), 'webq', 'getAppDBName');


