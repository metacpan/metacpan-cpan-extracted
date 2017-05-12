package Devel::Movie;
package DB;
use Internals::DumpArenas ();
our $Frame;
sub tracer {
    $Frame //= 0;

    local $, = ' ';
    ++$Frame;
    print STDOUT 'Runops::Movie frame',$Frame, @_;
    print STDERR 'Runops::Movie frame',$Frame, @_
        or warn "Can't write to STDERR: $!";
    Internals::DumpArenas::DumpArenas();
}
sub DB { tracer }
sub sub {
    tracer( $sub );
    goto &$sub;
}

q(Go drinking with mst);
