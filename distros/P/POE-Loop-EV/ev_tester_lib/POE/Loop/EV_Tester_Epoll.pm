=for poe_tests
BEGIN { $ENV{POE_EVENT_LOOP} = 'POE::Loop::EV'; $ENV{LIBEV_FLAGS} = 4; }
sub skip_tests {
    return "Author and automated testing only"
        unless $ENV{AUTHOR_TESTING} or $ENV{AUTOMATED_TESTING};
    return "EV module with 'epoll' backend could not be loaded: $@"
        unless eval { require EV; 1 };
    return "EV was not built with an 'epoll' backend"
        if EV::backend() != EV::BACKEND_EPOLL();
    diag("Using EV backend 'epoll'") if $_[0] eq '00_info';
    return undef;
}
