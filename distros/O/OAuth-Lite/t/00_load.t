use Test::More tests => 10;

BEGIN {
  use_ok("OAuth::Lite");  
  use_ok("OAuth::Lite::AuthMethod");  
  use_ok("OAuth::Lite::Token");  
  use_ok("OAuth::Lite::Consumer");  
  use_ok("OAuth::Lite::Util");  
  use_ok("OAuth::Lite::SignatureMethod");  
  use_ok("OAuth::Lite::SignatureMethod::PLAINTEXT");  
  use_ok("OAuth::Lite::SignatureMethod::HMAC_SHA1");  
  use_ok("OAuth::Lite::SignatureMethod::RSA_SHA1");  
  use_ok("OAuth::Lite::ServerUtil");  
}

