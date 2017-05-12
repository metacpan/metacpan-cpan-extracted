use strict;
use warnings;
use Test::More;
plan(tests => 5);
use lib qw(../lib lib);
use PSGI::Hector;
use PSGI::Hector::Response::TemplateToolkit;
use Test::MockModule;

#setup our cgi environment
my %env;
$env{'SCRIPT_NAME'} = "test.cgi";
$env{'SERVER_NAME'} = "www.test.com";
$env{'HTTP_HOST'} = "www.test.com";
$env{'HTTP_REFERER'} = "http://" . $env{'HTTP_HOST'};
$env{'REQUEST_METHOD'} = 'GET';

my $options = {
	'responsePlugin' => 'PSGI::Hector::Response::TemplateToolkit'
};

my $mock = Test::MockModule->new('PSGI::Hector::Response::TemplateToolkit');
my $templateContents = "FAKE CONTENT OUTPUT\n";
$mock->mock(_getContent => $templateContents);

my $m = PSGI::Hector->new($options, \%env);

my $rtt = $m->getResponse();

#1
ok($rtt->setTemplate('FAKE'), 'setTemplate()');

my $firstOutput = $rtt->display();
#2
isa_ok($firstOutput, 'ARRAY');
#3
is($firstOutput->[2]->[0], $templateContents, 'output is the contents of the template');

my $secondOutput = $rtt->display();
#4
isa_ok($secondOutput, 'ARRAY');
#5
is($secondOutput->[2]->[0], $templateContents . $templateContents, 'output is the contents of the template twice');
