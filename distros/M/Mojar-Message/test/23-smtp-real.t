use Mojo::Base -strict;

use Test::More;
use Mojar::Message::Smtp;

use Mojar::Config;
use Mojo::File 'path';

plan skip_all => 'set TEST_ACCESS to enable this test (developer only!)'
  unless $ENV{TEST_ACCESS};

my $config = Mojar::Config->load('data/smtp.conf');
my $email;

subtest q{new} => sub {
  ok $email = Mojar::Message::Smtp->new(
    From => $config->{From},
    To => $config->{To},
    domain => $config->{domain},
    debug => 1
  ), 'new';
};

subtest q{send} => sub {
  ok $email->Subject('Test')->body('Testing')->send, 'send';
  ok $email->Subject('Test 2')->body("Testing\n2")->send, 'send again';
};

subtest q{reset} => sub {
  ok $email->reset->From($config->{From})->To($config->{To})
      ->body('Should have blank Subject')->send, 'reset';
};

subtest q{attach} => sub {
  ok $email->Subject('test with attachment')->body('Body')->attach(
    Path => 'data/artistic_license_2_0.html'
  )->Cc($config->{Cc})->send, 'send attachment';
};

subtest q{HTML body} => sub {
  my $content = path('data/artistic_license_2_0.html')->slurp;
  ok $email->Subject('testing HTML body')->body($content)->Type('text/html')
    ->Cc($config->{Cc})->send, 'send html body';
};

done_testing();
