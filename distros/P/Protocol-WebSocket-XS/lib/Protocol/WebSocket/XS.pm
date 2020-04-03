package Protocol::WebSocket::XS;
use 5.012;
use URI::XS();
use Export::XS();
use Encode::Base2N();

our $VERSION = '1.0.2';

XS::Loader::load();

1;
