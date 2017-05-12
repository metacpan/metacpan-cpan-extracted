package Net::WAMP::RawSocket::Message;

sub new {
    return bless \$_[1], $_[0];
}

sub get_payload {
    return ${ $_[0] };
}

sub to_bytes {
    return $_[0]->_get_header() . $_[0]->get_payload();
}

sub _get_header {
    return pack(
        'CCn',
        $_[0]->TYPE_CODE(),
        (length(${$_[0]}) >> 16),
        (length(${$_[0]}) & 0xffff),
    );
}

1;
