package Protocol::WebSocket::Fast;
use 5.012;
use URI::XS();
use Export::XS();
use Encode::Base2N();

our $VERSION = '1.1.3';

XS::Loader::load();

1;
