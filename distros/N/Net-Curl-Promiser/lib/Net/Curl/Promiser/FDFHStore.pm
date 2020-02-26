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
# The above problem appears to affect IO::Async as well—even if
# you give file descriptors to IO::Async::Loop—but does not appear
# to affect AnyEvent.

sub new { bless {}, shift }

sub _create {
    open my $s, '+>>&=' . $_[0] or die "FD ($_[0]) to Perl FH failed: $!";
    $s;
}

sub get_fh {

    # This used to stat() to ensure that the file descriptor wasn’t closed.
    # But even if the FD had been closed and reopened, that would be
    # transparent to Perl. So the stat() check shouldn’t be needed.
    return $_[0]->{ $_[1] } ||= _create( $_[1] );
}

1;
