package Net::Curl::Promiser::FDFHStore;

# Mojo::IOLoop doesn’t track FDs, just Perl filehandles. That means
# that, in order to track libcurl’s file descriptors, we have to
# create Perl filehandles for them. But we also have to ensure that
# those filehandles aren’t garbage-collected (GC) because GC will
# cause Perl to close() the file descriptors, which will break
# libcurl.
#
# So we keep a reference to each created socket via this object.
#
# The above problem appears to affect IO::Async as well,
# but not AnyEvent.

sub new { bless {}, shift }

sub _create {
    open my $s, '+>>&=' . $_[0] or die "FD ($_[0]) to Perl FH failed: $!";
    $s;
}

sub get_checked {
    if (my $s = $_[0]->{ $_[1] }) {

        # What if libcurl has closed the underlying file descriptor, though?
        # We need to ensure that that hasn’t happened; if it has, then
        # get rid of the filehandle and create a new one. This incurs an
        # unfortunate overhead, but is there a better way?
        return $s if _fh_is_active($s);
    }

    return $_[0]->{ $_[1] } = _create( $_[1] );
}

sub _fh_is_active {
    local $!;

    stat $_[0] or do {
        return 0 if $!{'EBADF'};
        die "stat() on socket: $!";
    };

    return 1;
}

1;
