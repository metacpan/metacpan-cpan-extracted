use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use Net::SAML2::Binding::Redirect;


my $cacert = << 'CACERT';
-----BEGIN CERTIFICATE-----
MIICnTCCAYUCBgF5YqtQBTANBgkqhkiG9w0BAQsFADASMRAwDgYDVQQDDAdGb3N3
aWtpMB4XDTIxMDUxMjIyMTkyNFoXDTMxMDUxMjIyMjEwNFowEjEQMA4GA1UEAwwH
Rm9zd2lraTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJMGG6jrdadw
/6rnOAGmNtmdIZy116JyocKlsoxg+iQTlRI2e3gelsiOW7rXNIYHH/f4ozQ8F4ba
7GxJMNWlrDJFN23Dij521PVqJHsu3ZA8JOP+txMCN22zhCO6OYiWx5P9wm7zWVcf
g3sS9564LQ4M7JBQ8tDYxY9RLCDR+sNNd0hWm6SrkEyghqbcxNY+rgXfxLBK5eGX
yX1Zk0NLA5XqRg5a8BDz1oUZ6O4c21tVOvV8vqCUtcnx3hWxcBgXizW8pkSQpQiQ
96zXquAvDwkLtYnQLV5GQlt6c414A7U4dsAZZCc490rqncfsjDfbFMzj89s/WCtF
DOzSa163pqECAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAPpeGsBOJN3xGUvtxJqPM
2ja3g7G7LiOJGvzZSIOFr50baebsoJNRwL2GDfYUTM1SWDz4UHnGebsme5TTmzjV
O3YEvnOMTtVC6/fYYdouAqIJ+cTmmF3Cxd/tOr5fkaPscB0x0+zqWqgBZLo0FVEC
DMt+DYk1HaQJPxsAXGahUmIIpfIKO7AUx5tD74PR8XeHWyL0w8jg1h8nVtc49P7h
08SzmSFY0phJ9plLpSubCsd/1KMPOJ0Dh7kYEaOJOOWwjLggiho5N4KBytpts6HI
jmPlKvV7UJEAmQykuhO6PyFfGjwXxpYRTtGa3fZQqu6BztRHDSZQfc+K08VTmAjr
iw==
-----END CERTIFICATE-----
CACERT

my $uri = << 'REDIRECT_FULL';
https://netsaml2-testapp.local/sls-redirect-response?SAMLResponse=jVJda%2BswDP0rxe%2BpXefDiUkKl9sNCtse1rKHvQzZUe5CXTtEDtv%2B%2FdJ2gw3GuG8SOudIR1JNcHSDvgn%2FwhTvkYbgCRevR%2BdJn0sNm0avA1BP2sMRSUerd39ub7RcCj2MIQYbHLtQfgcDEY6xD559afDflA1S7D2ckoY9xziQ5txjPInIJM5VGIalCxYcJ0fJiG0%2Foo1zcHHFFttNw7abp3K1KsoUTVKBgSRr8zwBLFYJlhJkITKQVTuD%2Fec69qFhd1f701DyqeiU6pRUuYKqy2XaCVXYDAvTZqpqK9GlYGxnlWjbKlWlEWlmcmvSrpSmtMLMwkQTbv08r48Nk0LKRJSJFHshtci1zJeFTB%2FZ4gFHOpudF8HW9Zk2rj%2BdH%2FDNugCHi2NdZlnKYYrPfERwR%2BLXgV76Q1%2FzD159OfQuQpzoe%2FY3tLh4ADfh78egM1rvJmuRiPF1zb%2BL8p%2Beaf0O&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1&Signature=iFglcHV3%2B1CTf7iII1StcDQ1QyfIFCU4%2BuuWsgLFsj4w0KN6te%2FC0SsVWBLg2OAdOzATXQyULiwaH2dq%2F1QIR44ZVJf5cHGiQX0W9blcysCzVzb7fB00mEXTyPdygYk1cip0%2FFNShWodoEUFc1JlD78Nven%2FKJbv8yP3O3igb6A5VEgx0dUtWDiJtyWA7M3pqN%2BWLQux2%2Bg80mZPacbisc%2FJvnoWxgELPwwK1y%2BIFrqstmSTTo919IXCuEBn%2F1m4oEnxCXVaCRRCyDQdDMiEj9J3AaxwYC9czGBK%2FFdkvmmuT8c8CWMAKHrWKn2m%2BeLoPt77Fqu7daBKyT6aa29pTw%3D%3D
REDIRECT_FULL

my $redirect = Net::SAML2::Binding::Redirect->new(
    cert => $cacert,
    param => 'SAMLResponse',
);

my ($response, $relaystate) = $redirect->verify($uri);

like($response, qr/urn:oasis:names:tc:SAML:2.0:status:Success/, "Full URI is correct");

$uri = << 'REDIRECT_URI';
/sls-redirect-response?SAMLResponse=jVJda%2BswDP0rxe%2BpXefDiUkKl9sNCtse1rKHvQzZUe5CXTtEDtv%2B%2FdJ2gw3GuG8SOudIR1JNcHSDvgn%2FwhTvkYbgCRevR%2BdJn0sNm0avA1BP2sMRSUerd39ub7RcCj2MIQYbHLtQfgcDEY6xD559afDflA1S7D2ckoY9xziQ5txjPInIJM5VGIalCxYcJ0fJiG0%2Foo1zcHHFFttNw7abp3K1KsoUTVKBgSRr8zwBLFYJlhJkITKQVTuD%2Fec69qFhd1f701DyqeiU6pRUuYKqy2XaCVXYDAvTZqpqK9GlYGxnlWjbKlWlEWlmcmvSrpSmtMLMwkQTbv08r48Nk0LKRJSJFHshtci1zJeFTB%2FZ4gFHOpudF8HW9Zk2rj%2BdH%2FDNugCHi2NdZlnKYYrPfERwR%2BLXgV76Q1%2FzD159OfQuQpzoe%2FY3tLh4ADfh78egM1rvJmuRiPF1zb%2BL8p%2Beaf0O&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1&Signature=iFglcHV3%2B1CTf7iII1StcDQ1QyfIFCU4%2BuuWsgLFsj4w0KN6te%2FC0SsVWBLg2OAdOzATXQyULiwaH2dq%2F1QIR44ZVJf5cHGiQX0W9blcysCzVzb7fB00mEXTyPdygYk1cip0%2FFNShWodoEUFc1JlD78Nven%2FKJbv8yP3O3igb6A5VEgx0dUtWDiJtyWA7M3pqN%2BWLQux2%2Bg80mZPacbisc%2FJvnoWxgELPwwK1y%2BIFrqstmSTTo919IXCuEBn%2F1m4oEnxCXVaCRRCyDQdDMiEj9J3AaxwYC9czGBK%2FFdkvmmuT8c8CWMAKHrWKn2m%2BeLoPt77Fqu7daBKyT6aa29pTw%3D%3D
REDIRECT_URI

$redirect = Net::SAML2::Binding::Redirect->new(
    cert => $cacert,
    param => 'SAMLResponse',
);

($response, $relaystate) = $redirect->verify($uri);

like($response, qr/urn:oasis:names:tc:SAML:2.0:status:Success/, "Path only URI is correct");

$uri = << 'REDIRECT2_URI';
SAMLResponse=jVJda%2BswDP0rxe%2BpXefDiUkKl9sNCtse1rKHvQzZUe5CXTtEDtv%2B%2FdJ2gw3GuG8SOudIR1JNcHSDvgn%2FwhTvkYbgCRevR%2BdJn0sNm0avA1BP2sMRSUerd39ub7RcCj2MIQYbHLtQfgcDEY6xD559afDflA1S7D2ckoY9xziQ5txjPInIJM5VGIalCxYcJ0fJiG0%2Foo1zcHHFFttNw7abp3K1KsoUTVKBgSRr8zwBLFYJlhJkITKQVTuD%2Fec69qFhd1f701DyqeiU6pRUuYKqy2XaCVXYDAvTZqpqK9GlYGxnlWjbKlWlEWlmcmvSrpSmtMLMwkQTbv08r48Nk0LKRJSJFHshtci1zJeFTB%2FZ4gFHOpudF8HW9Zk2rj%2BdH%2FDNugCHi2NdZlnKYYrPfERwR%2BLXgV76Q1%2FzD159OfQuQpzoe%2FY3tLh4ADfh78egM1rvJmuRiPF1zb%2BL8p%2Beaf0O&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1&Signature=iFglcHV3%2B1CTf7iII1StcDQ1QyfIFCU4%2BuuWsgLFsj4w0KN6te%2FC0SsVWBLg2OAdOzATXQyULiwaH2dq%2F1QIR44ZVJf5cHGiQX0W9blcysCzVzb7fB00mEXTyPdygYk1cip0%2FFNShWodoEUFc1JlD78Nven%2FKJbv8yP3O3igb6A5VEgx0dUtWDiJtyWA7M3pqN%2BWLQux2%2Bg80mZPacbisc%2FJvnoWxgELPwwK1y%2BIFrqstmSTTo919IXCuEBn%2F1m4oEnxCXVaCRRCyDQdDMiEj9J3AaxwYC9czGBK%2FFdkvmmuT8c8CWMAKHrWKn2m%2BeLoPt77Fqu7daBKyT6aa29pTw%3D%3D
REDIRECT2_URI

$redirect = Net::SAML2::Binding::Redirect->new(
    cert => $cacert,
    param => 'SAMLResponse',
);

($response, $relaystate) = $redirect->verify($uri);

like($response, qr/urn:oasis:names:tc:SAML:2.0:status:Success/, "Parameters only URI is correct");

$uri = << 'REDIRECT3_URI';
?SAMLResponse=jVJda%2BswDP0rxe%2BpXefDiUkKl9sNCtse1rKHvQzZUe5CXTtEDtv%2B%2FdJ2gw3GuG8SOudIR1JNcHSDvgn%2FwhTvkYbgCRevR%2BdJn0sNm0avA1BP2sMRSUerd39ub7RcCj2MIQYbHLtQfgcDEY6xD559afDflA1S7D2ckoY9xziQ5txjPInIJM5VGIalCxYcJ0fJiG0%2Foo1zcHHFFttNw7abp3K1KsoUTVKBgSRr8zwBLFYJlhJkITKQVTuD%2Fec69qFhd1f701DyqeiU6pRUuYKqy2XaCVXYDAvTZqpqK9GlYGxnlWjbKlWlEWlmcmvSrpSmtMLMwkQTbv08r48Nk0LKRJSJFHshtci1zJeFTB%2FZ4gFHOpudF8HW9Zk2rj%2BdH%2FDNugCHi2NdZlnKYYrPfERwR%2BLXgV76Q1%2FzD159OfQuQpzoe%2FY3tLh4ADfh78egM1rvJmuRiPF1zb%2BL8p%2Beaf0O&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1&Signature=iFglcHV3%2B1CTf7iII1StcDQ1QyfIFCU4%2BuuWsgLFsj4w0KN6te%2FC0SsVWBLg2OAdOzATXQyULiwaH2dq%2F1QIR44ZVJf5cHGiQX0W9blcysCzVzb7fB00mEXTyPdygYk1cip0%2FFNShWodoEUFc1JlD78Nven%2FKJbv8yP3O3igb6A5VEgx0dUtWDiJtyWA7M3pqN%2BWLQux2%2Bg80mZPacbisc%2FJvnoWxgELPwwK1y%2BIFrqstmSTTo919IXCuEBn%2F1m4oEnxCXVaCRRCyDQdDMiEj9J3AaxwYC9czGBK%2FFdkvmmuT8c8CWMAKHrWKn2m%2BeLoPt77Fqu7daBKyT6aa29pTw%3D%3D
REDIRECT3_URI

$redirect = Net::SAML2::Binding::Redirect->new(
    cert => $cacert,
    param => 'SAMLResponse',
);

($response, $relaystate) = $redirect->verify($uri);

like($response, qr/urn:oasis:names:tc:SAML:2.0:status:Success/, "Parameters only begin with '?' URI is correct");

done_testing;
