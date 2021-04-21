package Protocol::HTTP;
use 5.012;
use URI::XS();
use Export::XS();
use XS::librangeV3;
use XS::libboost::mini;

our $VERSION = '1.1.1';

XS::Loader::bootstrap;

# Brotli compression will register self. There is nothing fatal,
# if the package is not found, just additional compression will
# not be supported (at runtime)
eval "use Protocol::HTTP::Compression::Brotli";

1;
