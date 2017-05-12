use strict;
use warnings;
use Test::More tests => 20;
use_ok('POE::Component::SmokeBox::Smoker');
use_ok('POE::Component::SmokeBox::Job');
use_ok('POE::Component::SmokeBox::Result');

my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $^X );

ok( $smoker->perl() eq $^X, 'The smoker perl was okay' );
ok( !$smoker->env(), 'We didn\'t set an env' );
ok( !$smoker->name(), 'We didn\'t set a name' );

$smoker = POE::Component::SmokeBox::Smoker->new( perl => $^X, name => 1 );
ok( $smoker->name(), 'We set a name' );
$smoker = POE::Component::SmokeBox::Smoker->new( perl => $^X, name => { 'foo' => 'baz' } );
ok( $smoker->name(), 'We set a name' );

my %sdump = $smoker->dump_data();

ok( $sdump{perl} eq $^X, 'The smoker perl was okay' );
ok( !$sdump{env}, 'We didn\'t set an env' );

my $job = POE::Component::SmokeBox::Job->new();
isa_ok( $job, 'POE::Component::SmokeBox::Job' );
ok( $job->idle() == 600, 'Idle okay' );
ok( $job->timeout() == 3600, 'Timeout okay' );
ok( $job->command() eq 'check', 'Check command' );
ok( $job->type() eq 'CPANPLUS::YACSmoke', 'Type is CPANPLUS::YACSmoke' );
#ok( $job->smokers(), 'There are some smokers' );
#isa_ok( $_, 'POE::Component::SmokeBox::Smoker' ) for @{ $job->smokers() };

my %jdump = $job->dump_data();

ok( $jdump{idle} == 600, 'Idle okay' );
ok( $jdump{timeout} == 3600, 'Timeout okay' );
ok( $jdump{command} eq 'check', 'Check command' );
ok( $jdump{type} eq 'CPANPLUS::YACSmoke', 'Type is CPANPLUS::YACSmoke' );

my $result = POE::Component::SmokeBox::Result->new();
isa_ok( $result, 'POE::Component::SmokeBox::Result' );
