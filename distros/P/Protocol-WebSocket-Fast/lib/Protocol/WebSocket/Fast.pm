package Protocol::WebSocket::Fast;
use 5.012;
use URI::XS();
use Export::XS();
use Encode::Base2N();

our $VERSION = '1.2.9';

XS::Loader::load();

1;
