package PMCPFakeStream;
use 5.010;
use strict;
use warnings;

# A stand-in for a Punk::SSE stream: records what it is sent and whether it
# was closed, and runs its on(close) callbacks as the real one does.
sub new     { bless { events => [], open => 1, on_close => [] }, shift }
sub event   { my ($s, $name, $data) = @_; push @{ $s->{events} }, [$name, $data] if $s->{open}; $s }
sub is_open { $_[0]{open} }
sub on      { my ($s, $what, $cb) = @_; push @{ $s->{on_close} }, $cb if $what eq 'close'; $s }
sub close   {
    my ($s) = @_;
    return $s unless $s->{open};
    $s->{open} = 0;
    # deferred: the callbacks wait for fire(), as on a loop they run later
    if ($s->{deferred}) { $s->{pending} = 1; return $s }
    $_->($s) for @{ $s->{on_close} };
    $s;
}
sub deferred { $_[0]{deferred} = 1; $_[0] }
sub fire     { my ($s) = @_; if (delete $s->{pending}) { $_->($s) for @{ $s->{on_close} } } $s }
sub gone    { my ($s) = @_; $s->{open} = 0; $s }   # the client left: no callback yet
sub uris    { [map { $_->[1] =~ /"uri":"([^"]+)"/ ? $1 : () } @{ $_[0]{events} }] }

1;
