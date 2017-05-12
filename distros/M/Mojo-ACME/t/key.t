use Mojo::Base -strict;

use Test::More;
use Mojo::Util;

use Mojo::ACME::Key;

subtest 'generated key' => sub {
  my $key = Mojo::ACME::Key->new;
  isa_ok $key->key, 'Crypt::OpenSSL::RSA';
  is $key->generated, 1, 'key was generated';
  ok $key->key->is_private, 'generated key is a private key';
  isa_ok $key->pub, 'Crypt::OpenSSL::RSA';
  ok !$key->pub->is_private, 'generated key can created a related public key';
};

subtest 'pre-existing key' => sub {
  my $key = Mojo::ACME::Key->new(path => 't/test.key');
  isa_ok $key->key, 'Crypt::OpenSSL::RSA';
  is $key->generated, 0, 'key was not generated';
  ok $key->key->is_private, 'pre-existing key is a private key';
  isa_ok $key->pub, 'Crypt::OpenSSL::RSA';
  ok !$key->pub->is_private, 'pre-existing key can created a related public key';
  my $jwk = {
    "e" => "AQAB",
    "kty" => "RSA",
    "n" => "wQilzSWSTokWyJiaM96txR01X7Kr9iaxI3uuo_uquKZbySvwQE-8Qu_YKQHrssHYnZtJm5rJ3tdWcVJO9OBYlIDGz03L96jkEa_s8p3IuC2A6CCOWPUXWUx4lXvWQS2apvifoku5CE8YJ813-gh1KaGKzbQtFYtjPUKZvbE4yrkzysCZJbEYABqePutVwizQI_nA-9Fuv7S57_wF2T2L6rX_2yccDxkK2MN__NhHFbFj94gVoryDbvXk-MTQ4FoZHj93r27zVE-0Zm07P6Og2zQSkGsHS-bLNjtlHdd_r5-b766GkKKm3vQaJ2vHHVBdfZMmmxq3Q5mdiCBnrfEoJpe7sVpMRDjVqsQPLcGDL_vwUT5yS-FBGY9_fmL1ZUoOuohXnp4f9-Z7WGANoUh_Nlc0bwXIlSBd1YT5c5QoONx7X_9nu-wLQlQ3goFkDfPPCaj1m-HDSSuTCt61FuuyWaMtMdZzmjtPWTzUU1R_CKm9bqK2IZ1axrC9PBbK43zpqoH9FniTuP7yD4k-7CIwyCINZwprw1IiK3dnyyOfvX1nhRetIpuWERfns_ZHGE0MmjkB2gbqTujeM8gLjxf_M8TPXl75vpQkDpiIsoMZhNcVgPoNLJ-I74CBhyixdEp-s1arq9K6QPpC0UmLAfE_O5VFSRj04Ouar2x2AWpp7tE"
  };
  is_deeply $key->jwk, $jwk, 'jwk is as previously computed';
  is $key->thumbprint, 'oIePSSg18GEOJIadc6j-HOC0ZC-gdXPHCzP077RQX2o', 'thumbprint is as previously computed';
  my $sig = 'tOZ3Q3UOjkoBKA/SITPG7EiSciziz8AiNqYCLN6cR5KKxHFDVNCbY5CRgbVl0Yl1xY1F+8i29+NOMYhqnG0NvTyCc3XvEqb6s1N8KfH/wMMaqWlg36/ocfWMLFgnRMFpEd3y+OYOs5i5m9vHwZkZ+n+sovIkx/p396ZFIl4Y9rxEtRIAq/E0QKf5iMvMJEekie8AGV02zVVAa/C+Bq2Cc446+VjZDomJhqVB0qN9toA/23bX2+55eK8qFP8e0EjTO12/ZOBKJh0MgAV+L2ykLD9Fb0nTx7mwTesK9mfMe8lKRGtJLUEyRnFzNydsX0ZyN78mNJ1SPu1AKsXa+YKw9Ti+dtqo9+BhEH+PULD4XljV/3YA4BVpQlIQYhg2hOq+2Q5TC6F6NaTzKxPSOmMnVvnb2UXvYtmUYXlqUauOgN3iW/qhOfazzz+y5T0gLRvnQx6tMgpKEUvU4CedZpRV/kslpssewDncXt2VSmbdVBvu+Gkie18zQXomu2dOEaDNesd0CAG7F/U+ZFeiuG7Ozg6+OJlnjaqxSu1WNQfAENuUHMvAt6/RTeReZKXp7XmcHw0EnxHNjU4ANmQeeiIQVMwSbuehSvRRo7dRu7Adq0VU1aGSW6s0zeCWcAjjl88lsl5JlCh2QqcHEWeFgI6CaLCIWHF1/tJ1pEhzRYy5sqM=';
  is Mojo::Util::encode_base64($key->sign('abc123'), ''), $sig, 'signed value is as previously computed';

  # check clone
  my $clone = $key->key_clone;
  isa_ok $clone, 'Crypt::OpenSSL::RSA';
  isnt $key->pub, $clone, 'clone is not the same object';
  is $key->key->get_private_key_string, $clone->get_private_key_string, 'key strings are equivalent';
};

done_testing;

