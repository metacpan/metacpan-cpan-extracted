use strict;
use warnings;

use Test::More;

# These test data are from:
# http://openid.net/specs/openid-connect-core-1_0.html#AuthorizationExamples

use JSON;
use Net::OpenID::Connect::IDToken;

sub test_spec {
    my ($id_token, $expect_claims_json) = @_;

    my $expect_claims = decode_json($expect_claims_json);
    my $got_claims    = decode_id_token($id_token);
    is_deeply $got_claims, $expect_claims;
}

subtest "id_token" => sub {
    my $id_token = <<BEARER;
eyJhbGciOiJSUzI1NiJ9.ew0KICJpc3MiOiAiaHR0cDovL3NlcnZlci5leGFtcGxlLmNvbSIsDQogInN1YiI6ICIyNDgyODk3NjEwMDEiLA0KICJhdWQiOiAiczZCaGRSa3F0MyIsDQogIm5vbmNlIjogIm4tMFM2X1d6QTJNaiIsDQogImV4cCI6IDEzMTEyODE5NzAsDQogImlhdCI6IDEzMTEyODA5NzAsDQogIm5hbWUiOiAiSmFuZSBEb2UiLA0KICJnaXZlbl9uYW1lIjogIkphbmUiLA0KICJmYW1pbHlfbmFtZSI6ICJEb2UiLA0KICJnZW5kZXIiOiAiZmVtYWxlIiwNCiAiYmlydGhkYXRlIjogIjAwMDAtMTAtMzEiLA0KICJlbWFpbCI6ICJqYW5lZG9lQGV4YW1wbGUuY29tIiwNCiAicGljdHVyZSI6ICJodHRwOi8vZXhhbXBsZS5jb20vamFuZWRvZS9tZS5qcGciDQp9.Bgdr1pzosIrnnnpIekmJ7ooeDbXuA2AkwfMf90Po2TrMcl3NQzUE_9dcr9r8VOuk4jZxNpV5kCu0RwqqF11-6pQ2KQx_ys2i0arLikdResxvJlZzSm_UG6-21s97IaXC97vbnTCcpAkokSe8Uik6f8-U61zVmCBMJnpvnxEJllfV8fYldo8lWCqlOngScEbFQUh4fzRsH8O3Znr20UZib4V4mGZqYPtPDVGTeu8xkty1t0aK-wEhbm6Hi-TQTi4kltJlw47McSVgF_8SswaGcW6Bf_954ir_ddi4Nexo9RBiWu4n3JMNcQvZU5xMPhu-EF-6_nJNotp-lbnBUyxTSg
BEARER

    my $expect_claims_json = <<'CLAIMS';
  {
   "iss": "http://server.example.com",
   "sub": "248289761001",
   "aud": "s6BhdRkqt3",
   "nonce": "n-0S6_WzA2Mj",
   "exp": 1311281970,
   "iat": 1311280970,
   "name": "Jane Doe",
   "given_name": "Jane",
   "family_name": "Doe",
   "gender": "female",
   "birthdate": "0000-10-31",
   "email": "janedoe@example.com",
   "picture": "http://example.com/janedoe/me.jpg"
  }
CLAIMS

    test_spec($id_token, $expect_claims_json);
};

subtest "id_token token" => sub {
    my $id_token = <<BEARER;
eyJhbGciOiJSUzI1NiJ9.ew0KICJpc3MiOiAiaHR0cDovL3NlcnZlci5leGFtcGxlLmNvbSIsDQogInN1YiI6ICIyNDgyODk3NjEwMDEiLA0KICJhdWQiOiAiczZCaGRSa3F0MyIsDQogIm5vbmNlIjogIm4tMFM2X1d6QTJNaiIsDQogImV4cCI6IDEzMTEyODE5NzAsDQogImlhdCI6IDEzMTEyODA5NzAsDQogImF0X2hhc2giOiAiNzdRbVVQdGpQZnpXdEYyQW5wSzlSUSINCn0.g7UR4IDBNIjoPFV8exQCosUNVeh8bNUTeL4wdQp-2WXIWnly0_4ZK0sh4A4uddfenzo4Cjh4wuPPrSw6lMeujYbGyzKspJrRYL3iiYWc2VQcl8RKdHPz_G-7yf5enut1YE8v7PhKucPJCRRoobMjqD73f1nJNwQ9KBrfh21Ggbx1p8hNqQeeLLXb9b63JD84hVOXwyHmmcVgvZskge-wExwnhIvv_cxTzxIXsSxcYlh3d9hnu0wdxPZOGjT0_nNZJxvdIwDD4cAT_LE5Ae447qB90ZF89Nmb0Oj2b1GdGVQEIr8-FXrHlyD827f0N_hLYPdZ73YK6p10qY9oRtMimg
BEARER

    my $expect_claims_json = <<'CLAIMS';
  {
   "iss": "http://server.example.com",
   "sub": "248289761001",
   "aud": "s6BhdRkqt3",
   "nonce": "n-0S6_WzA2Mj",
   "exp": 1311281970,
   "iat": 1311280970,
   "at_hash": "77QmUPtjPfzWtF2AnpK9RQ"
  }
CLAIMS

    test_spec($id_token, $expect_claims_json);
};

subtest "code id_token" => sub {
    my $id_token = <<BEARER;
eyJhbGciOiJSUzI1NiJ9.ew0KICJpc3MiOiAiaHR0cDovL3NlcnZlci5leGFtcGxlLmNvbSIsDQogInN1YiI6ICIyNDgyODk3NjEwMDEiLA0KICJhdWQiOiAiczZCaGRSa3F0MyIsDQogIm5vbmNlIjogIm4tMFM2X1d6QTJNaiIsDQogImV4cCI6IDEzMTEyODE5NzAsDQogImlhdCI6IDEzMTEyODA5NzAsDQogImNfaGFzaCI6ICJMRGt0S2RvUWFrM1BrMGNuWHhDbHRBIg0KfQ.dAVXerlNOJ_tqMUysD_k1Q_bRXRJbLkTOsCPVxpKUis5V6xMRvtjfRg8gUfPuAMYrKQMEqZZmL87Hxkv6cFKavb4ftBUrY2qUnrvqe_bNjVEz89QSdxGmdFwSTgFVGWkDf5dV5eIiRxXfIkmlgCltPNocRAyvdNrsWC661rHz5F9MzBho2vgi5epUa_KAl6tK4ksgl68pjZqlBqsWfTbGEsWQXEfu664dJkdXMLEnsPUeQQLjMhLH7qpZk2ry0nRx0sS1mRwOM_Q0Xmps0vOkNn284pMUpmWEAjqklWITgtVYXOzF4ilbmZK6ONpFyKCpnSkAYtTEuqz-m7MoLCD_A
BEARER

    my $expect_claims_json = <<'CLAIMS';
  {
   "iss": "http://server.example.com",
   "sub": "248289761001",
   "aud": "s6BhdRkqt3",
   "nonce": "n-0S6_WzA2Mj",
   "exp": 1311281970,
   "iat": 1311280970,
   "c_hash": "LDktKdoQak3Pk0cnXxCltA"
  }
CLAIMS

    test_spec($id_token, $expect_claims_json);
};

subtest "code id_token token" => sub {
    my $id_token = <<BEARER;
eyJhbGciOiJSUzI1NiJ9.ew0KICJpc3MiOiAiaHR0cDovL3NlcnZlci5leGFtcGxlLmNvbSIsDQogInN1YiI6ICIyNDgyODk3NjEwMDEiLA0KICJhdWQiOiAiczZCaGRSa3F0MyIsDQogIm5vbmNlIjogIm4tMFM2X1d6QTJNaiIsDQogImV4cCI6IDEzMTEyODE5NzAsDQogImlhdCI6IDEzMTEyODA5NzAsDQogImF0X2hhc2giOiAiNzdRbVVQdGpQZnpXdEYyQW5wSzlSUSIsDQogImNfaGFzaCI6ICJMRGt0S2RvUWFrM1BrMGNuWHhDbHRBIg0KfQ.JQthrBsOirujair9aD5gj1Yd5qEv0j4fhLgl8h3RaH3soYhwPOiN2Iy_yb7wMCO6I3bPoGJc3zCkpjgUtdB4O2eEhFqXHdwnE4c0oVTaTHJi_PdV2ox9g-1ikDB0ckWk0f0SzBd7yM2RoYYxJCiGBQlsSSRQz6ehykonI3hLAhXFdpfbK-3_a3HBNKOv_9Mr_JJrz2pqSygk5IBNvwzf1ouVeM91KKvr7EdriKN8ysk68fctbFAga1p8rE3cfBOX7Acn4p9QSNpUx0i_x4WHktyKD
BEARER

    my $expect_claims_json = <<'CLAIMS';
  {
   "iss": "http://server.example.com",
   "sub": "248289761001",
   "aud": "s6BhdRkqt3",
   "nonce": "n-0S6_WzA2Mj",
   "exp": 1311281970,
   "iat": 1311280970,
   "at_hash": "77QmUPtjPfzWtF2AnpK9RQ",
   "c_hash": "LDktKdoQak3Pk0cnXxCltA"
  }

CLAIMS

    test_spec($id_token, $expect_claims_json);
};

done_testing;
