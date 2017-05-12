=for poe_tests
BEGIN { $ENV{POE_EVENT_LOOP} = 'POE::Loop::EV'; $ENV{LIBEV_FLAGS} = 8; }
sub skip_tests {
    return "Author and automated testing only"
        unless $ENV{AUTHOR_TESTING} or $ENV{AUTOMATED_TESTING};
    return "EV module with 'kqueue' backend could not be loaded: $@"
        unless eval { require EV; 1 };
    return "EV was not built with a 'kqueue' backend"
        if EV::backend() != EV::BACKEND_KQUEUE();
    return "wheel_readwrite test disabled for 'kqueue'"
        if $_[0] eq 'wheel_readwrite';
    diag("Using EV backend 'kqueue'") if $_[0] eq '00_info';
    return undef;
}
