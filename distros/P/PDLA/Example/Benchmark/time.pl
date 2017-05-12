use blib ".";
use blib "../..";
use PDLA;
# use PDLA::Bench;
BEGIN{
require "Bench.pm";
PDLA::Bench->import();
}


do_benchmark();
