use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Net::BitTorrent::Emitter;
#
class Net::BitTorrent::Tracker::Base v2.1.0 : isa(Net::BitTorrent::Emitter) {
    field $url : param : reader;
    field $ssrf_bypass : param : reader = 0;

    method perform_announce ( $params, $cb = undef ) {
        $self->_emit_log( 'fatal', 'Not implemented in base class' );
    }

    method perform_scrape ( $infohashes, $cb = undef ) {
        $self->_emit_log( 'fatal', 'Not implemented in base class' );
    }
};
1;
