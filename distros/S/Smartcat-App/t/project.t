
=begin comment

Smartcat::App project command tests

=end comment

=cut

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Test::MockModule;
use App::Cmd::Tester;

use Cwd qw(abs_path);
use File::Basename;
use File::Spec::Functions qw(catfile);
use File::Remove qw(rm);

use lib 'lib';

use Smartcat::App;

my $test_config_path =
  catfile( dirname( abs_path(__FILE__) ), 'data', 'test.config' );
my $config_module = Test::MockModule->new('Smartcat::App::Config');
$config_module->mock( get_config_file => sub { return $test_config_path; } );

my $apiclient_module = Test::MockModule->new('Smartcat::Client::ApiClient');
my $get_project_response_content =
'{"id":"9d33d420-1b2a-46aa-b8b6-8a0772b1495e","name":"test_smartcat","description":"","creationDate":"2018-07-12T15:56:38.006Z","createdByUserId":"34045ec4-8b9e-4363-a7d4-99e3e0a95195","modificationDate":"2018-07-12T15:56:38.006Z","sourceLanguage":"en","targetLanguages":["ru","uk"],"status":"inProgress","statusModificationDate":"2018-07-14T20:33:31.564Z","workflowStages":[{"progress":12.500,"stageType":"translation"}],"documents":[{"id":"2649010_1058","name":"uk_uk","creationDate":"2018-07-13T21:24:17.11Z","sourceLanguage":"en","documentDisassemblingStatus":"success","targetLanguage":"uk","status":"updated","wordsCount":8,"statusModificationDate":"2018-07-13T21:34:09.855Z","pretranslateCompleted":false,"workflowStages":[{"progress":12.500,"wordsTranslated":1,"unassignedWordsCount":8,"status":"inProgress","executives":[]}],"externalId":"5b491881e985c114b0f00c84","placeholdersAreEnabled":true}]}';
$apiclient_module->mock(
    call_api => sub { return $get_project_response_content } );

my $test_log_path =
  catfile( dirname( abs_path(__FILE__) ), 'data', 'test.log' );
my $return = test_app(
    'Smartcat::App',
    [
        (
            'project', '--project-id=9d33d420-1b2a-46aa-b8b6-8a0772b1495e',
            "--log=$test_log_path"
        )
    ]
);
like( $return->stdout, qr/Project:\n\s*test_smartcat/, "get project" );

ok( -e $test_log_path, 'log file created' );

$return = test_app(
    'Smartcat::App',
    [
        (
            'project', '--project-id=9d33d420-1b2a-46aa-b8b6-8a0772b1495e',
            '--debug'
        )
    ]
);
like( $return->stdout, qr/DEBUG/, "get project in debug mode" );

rm($test_log_path);

1;
