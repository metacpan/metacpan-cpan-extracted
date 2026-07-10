#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $B64_URL_ENCODED_22_CHAR_RE = qr/^[A-Za-z0-9_-]{22,22}$/i;
my $B64_URL_ENCODED_43_CHAR_RE = qr/^[A-Za-z0-9_-]{43,43}$/i;

use_ok 'OIDC::Client::Utils', qw/get_values_from_space_delimited_string
                                 reach_data
                                 affect_data
                                 delete_data
                                 generate_state
                                 generate_nonce
                                 generate_jti
                                 generate_code_verifier
                                 generate_code_challenge/;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_get_values_from_space_delimited_string {
  note 'get_values_from_space_delimited_string()';

  subtest "single value" => sub {

    # Given
    my $str = 'single_value';

    # When
    my $values = get_values_from_space_delimited_string($str);

    # Then
    cmp_deeply($values, [qw/single_value/],
               'expected result');
  };

  subtest "multiple values" => sub {

    # Given
    my $str = 'value1 value2';

    # When
    my $values = get_values_from_space_delimited_string($str);

    # Then
    cmp_deeply($values, ['value1', 'value2'],
               'expected result');
  };

  subtest "multiple spaces" => sub {

    # Given
    my $str = ' value1  value2 value3   ';

    # When
    my $values = get_values_from_space_delimited_string($str);

    # Then
    cmp_deeply($values, ['value1', 'value2', 'value3'],
               'expected result');
  };
}


sub test_reach_data {
  note 'reach_data()';

  subtest "not a hashref" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key1 key11/;

    # When - Then
   throws_ok { reach_data(\%data, \@path) }
     qr/OIDC: not a hashref to reach the value of the 'key11' key/,
     'exception is thrown';
  };

  subtest "scalar is reached" => sub {

    # Given
    my %data = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key211 => 'val211',
        },
      },
    );
    my @path = qw/key2 key21 key211/;

    # When
    my $result = reach_data(\%data, \@path);

    # Then
    cmp_deeply($result, 'val211',
               'expected result');
  };

  subtest "object is reached" => sub {

    # Given
    my %data = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key211 => 'val211',
        },
      },
    );
    my @path = qw/key2 key21/;

    # When
    my $result = reach_data(\%data, \@path);

    # Then
    cmp_deeply($result, { key211 => 'val211' },
               'expected result');
  };

  subtest "not reached and optional - no autovivification" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key2 key21/;

    # When
    my $result = reach_data(\%data, \@path);

    # Then
    cmp_deeply($result, undef,
               'expected result');
    my %expected_data = (
      key1 => 'val1',
    );
    cmp_deeply(\%data, \%expected_data,
               'expected data');
  };

  subtest "not reached and mandatory" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key2 key21/;

    # When - Then
   throws_ok { reach_data(\%data, \@path, 0) }
     qr/OIDC: the 'key2' key is not present/,
     'exception is thrown';
  };
}


sub test_affect_data {
  note 'affect_data()';

  subtest "invalid path parameter" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw//;
    my $value = 'newval';

    # When - Then
   throws_ok { affect_data(\%data, \@path, $value) }
     qr/OIDC: to affect data, at least one value must be provided in the 'path' arrayref/,
     'exception is thrown';
  };

  subtest "not a hashref" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key1 key11/;
    my $value = 'newval';

    # When - Then
   throws_ok { affect_data(\%data, \@path, $value) }
     qr/OIDC: the value of the 'key1' key is not a hash reference/,
     'exception is thrown';
  };

  subtest "data is affected" => sub {

    # Given
    my %data = (
      key1 => 'val1',
      key2 => 'val2',
    );
    my @path = qw/key2/;
    my $value = 'newval';

    # When
    affect_data(\%data, \@path, $value);

    # Then
    my %expected_result = (
      key1 => 'val1',
      key2 => 'newval',
    );
    cmp_deeply(\%data, \%expected_result,
               'expected result');
  };

  subtest "data is deeply affected" => sub {

    # Given
    my %data = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key211 => 'val211',
        },
      },
    );
    my @path = qw/key2 key21 key211/;
    my $value = 'newval';

    # When
    affect_data(\%data, \@path, $value);

    # Then
    my %expected_result = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key211 => 'newval',
        },
      },
    );
    cmp_deeply(\%data, \%expected_result,
               'expected result');
  };

  subtest "new keys are created" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key2 key21 key211/;
    my $value = 'newval';

    # When
    affect_data(\%data, \@path, $value);

    # Then
    my %expected_result = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key211 => 'newval',
        },
      },
    );
    cmp_deeply(\%data, \%expected_result,
               'expected result');
  };
}


sub test_delete_data {
  note 'delete_data()';

  subtest "invalid path parameter" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw//;

    # When - Then
   throws_ok { delete_data(\%data, \@path) }
     qr/OIDC: to delete data, at least one value must be provided in the 'path' arrayref/,
     'exception is thrown';
  };

  subtest "not a hashref" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key1 key11/;

    # When - Then
   throws_ok { delete_data(\%data, \@path) }
     qr/OIDC: the value of the 'key1' key is not a hash reference/,
     'exception is thrown';
  };

  subtest "data is deleted" => sub {

    # Given
    my %data = (
      key1 => 'val1',
      key2 => 'val2',
    );
    my @path = qw/key2/;

    # When
    my $result = delete_data(\%data, \@path);

    # Then
    my $expected_result = 'val2';
    cmp_deeply($result, $expected_result,
               'expected result');
    my %expected_data = (
      key1 => 'val1',
    );
    cmp_deeply(\%data, \%expected_data,
               'expected data');
  };

  subtest "data is deeply deleted" => sub {

    # Given
    my %data = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key211 => {
            key2111 => 'val211',
          },
          key212 => 'val212',
        },
      },
    );
    my @path = qw/key2 key21 key211/;

    # When
    my $result = delete_data(\%data, \@path);

    # Then
    my $expected_result = {
      key2111 => 'val211',
    };
    cmp_deeply($result, $expected_result,
               'expected result');
    my %expected_data = (
      key1 => 'val1',
      key2 => {
        key21 => {
          key212 => 'val212',
        },
      },
    );
    cmp_deeply(\%data, \%expected_data,
               'expected data');
  };

  subtest "data to delete is not present - no autovivification" => sub {

    # Given
    my %data = (
      key1 => 'val1',
    );
    my @path = qw/key2 key21 key211/;

    # When
    my $result = delete_data(\%data, \@path);

    # Then
    my $expected_result = undef;
    cmp_deeply($result, $expected_result,
               'expected result');
    my %expected_data = (
      key1 => 'val1',
    );
    cmp_deeply(\%data, \%expected_data,
               'expected data');
  };
}


sub test_generate_state {
  note 'generate_state()';

  subtest "expected format and unicity" => sub {

    # When
    my $state1 = generate_state();
    my $state2 = generate_state();

    # Then
    cmp_deeply([$state1, $state2], array_each(re($B64_URL_ENCODED_22_CHAR_RE)),
               'matches expected format');
    isnt($state1, $state2,
         'two consecutive calls differ');
  };
}


sub test_generate_nonce {
  note 'generate_nonce()';

  subtest "expected format and unicity" => sub {

    # When
    my $nonce1 = generate_nonce();
    my $nonce2 = generate_nonce();

    # Then
    cmp_deeply([$nonce1, $nonce2], array_each(re($B64_URL_ENCODED_22_CHAR_RE)),
               'matches expected format');
    isnt($nonce1, $nonce2,
         'two consecutive calls differ');
  };
}


sub test_generate_jti {
  note 'generate_jti()';

  subtest "expected format and unicity" => sub {

    # When
    my $jti1 = generate_jti();
    my $jti2 = generate_jti();

    # Then
    cmp_deeply([$jti1, $jti2], array_each(re($B64_URL_ENCODED_22_CHAR_RE)),
               'matches expected format');
    isnt($jti1, $jti2,
         'two consecutive calls differ');
  };
}


sub test_generate_code_verifier {
  note 'generate_code_verifier()';

  subtest "expected format and unicity" => sub {

    # When
    my $code_verfier1 = generate_code_verifier();
    my $code_verfier2 = generate_code_verifier();

    # Then
    cmp_deeply([$code_verfier1, $code_verfier2], array_each(re($B64_URL_ENCODED_43_CHAR_RE)),
               'only Base64URL characters and always 43 characters');
    isnt($code_verfier1, $code_verfier2,
         'two consecutive calls differ');
  };
}


sub test_generate_code_challenge {
  note 'generate_code_challenge()';

  subtest "plain method" => sub {

    # Given
    my $code_verifier = 'my_code_verifier';

    # When
    my $code_challenge = generate_code_challenge($code_verifier, 'plain');

    # Then
    is($code_challenge, $code_verifier,
       'code challenge equals code verifier');
  };

  subtest "S256 method - RFC 7636 test case" => sub {

    # Given
    # Reference values from RFC 7636 Appendix B
    # https://datatracker.ietf.org/doc/html/rfc7636#appendix-B
    my $code_verifier           = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    my $expected_code_challenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

    # When
    my $code_challenge = generate_code_challenge($code_verifier, 'S256');

    # Then
    is($code_challenge, $expected_code_challenge,
       'expected code challenge');
  };

  subtest 'S256 method - deterministic output' => sub {

    # Given
    my $code_verifier = 'same-verifier-each-time';

    # When
    my $code_challenge1 = generate_code_challenge($code_verifier, 'S256');
    my $code_challenge2 = generate_code_challenge($code_verifier, 'S256');

    # Then
    is($code_challenge1, $code_challenge2,
       'same verifier produces same challenge');
  };

  subtest 'S256 method - different verifiers produce different challenges' => sub {

    # Given
    my $code_verifier1 = 'verifier-one';
    my $code_verifier2 = 'verifier-two';

    my $code_challenge1 = generate_code_challenge($code_verifier1, 'S256');
    my $code_challenge2 = generate_code_challenge($code_verifier2, 'S256');

    isnt($code_challenge1, $code_challenge2,
         'different verifiers produce different challenges');
  };
}
