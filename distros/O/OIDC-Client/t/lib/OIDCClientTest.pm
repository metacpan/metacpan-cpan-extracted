package OIDCClientTest;

use utf8;
use Moose;
use Moose::Exporter;
use MooseX::Params::Validate;
use List::Util qw(shuffle any);
use Test::MockObject;
use Test::MockModule;
use OIDC::Client::TokenResponse;

Moose::Exporter->setup_import_methods(as_is => [qw/launch_tests/]);

for (qw(mocked_user_agent
        mocked_response_parser
        mocked_token_response_parser
     )) { has $_ => ( is  => 'rw', isa => 'Test::MockObject' ) }

for (qw(mocked_decode_jwt
     )) { has $_ => ( is  => 'rw', isa => 'Test::MockModule' ) }

sub launch_tests {
  my @test_names = @_;

  my @all_tests = grep { $_ =~ /^test_/ } shuffle(keys %main::);
  my @to_launch;

  if (@test_names) {
    foreach my $test_name (@test_names) {
      push @to_launch, $test_name if any { $test_name eq $_ } @all_tests;
    }
  }
  else {
    @to_launch = @all_tests;
  }

  foreach my $x (@to_launch) {
    $main::{$x}->();
  }
}

sub mock_user_agent {
  my ($self, %params) = validated_hash(
    \@_,
    to_mock  => { isa => 'HashRef', optional => 0 },
  );

  my $mock_ua = Test::MockObject->new();
  $mock_ua->set_isa('Mojo::UserAgent');

  while (my ($method, $wanted_result) = each %{ $params{to_mock} }) {
    my $mock_transaction_http = Test::MockObject->new();
    $mock_transaction_http->mock(result => sub { $wanted_result });
    $mock_ua->mock($method => sub { $mock_transaction_http });
  }

  $self->mocked_user_agent($mock_ua);
}

sub mock_response_parser {
  my ($self) = @_;

  my $mock_resp_parser = Test::MockObject->new();
  $mock_resp_parser->set_isa('OIDC::Client::ResponseParser');
  $mock_resp_parser->mock(parse => sub { $_[1] });

  $self->mocked_response_parser($mock_resp_parser);
}

sub mock_token_response_parser {
  my ($self) = @_;

  my $mock_token_resp_parser = Test::MockObject->new();
  $mock_token_resp_parser->set_isa('OIDC::Client::TokenResponseParser');
  $mock_token_resp_parser->mock(parse => sub { OIDC::Client::TokenResponse->new($_[1]) });

  $self->mocked_token_response_parser($mock_token_resp_parser);
}

sub mock_decode_jwt {
  my ($self, %params) = validated_hash(
    \@_,
    claims   => { isa => 'HashRef', optional => 1 },
    callback => { isa => 'CodeRef', optional => 1 },
  );

  my $mock_crypt_jwt = Test::MockModule->new('OIDC::Client');

  if (my $cb = $params{callback}) {
    $mock_crypt_jwt->redefine('decode_jwt' => $cb);
  }
  elsif (my $claims = $params{claims}) {
    $mock_crypt_jwt->redefine('decode_jwt' => $claims);
  }
  else {
    die 'mock_decode_jwt() : unexpected params';
  }

  $self->mocked_decode_jwt($mock_crypt_jwt);
}

1;
