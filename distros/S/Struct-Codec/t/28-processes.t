#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempfile);
use Struct::Codec qw(struct_encode struct_decode);

# ACROSS A PROCESS BOUNDARY, WHICH IS WHAT THE BYTES ARE FOR.
#
# Encoded in one process and decoded in another: through a pipe, and through
# a fork where the child decodes what the parent encoded - including a
# filehandle by descriptor, which the POD says is good in a child that
# inherited it. And under ithreads, where a decode in a thread must not
# disturb the parent interpreter.

my $fixture = {
    name  => "caf\x{263a}",   # a wide character, so the flag is really on
    n     => [1, -2, 3.5, undef, 2**40],
    obj   => bless({ k => 'v' }, 'Across'),
    deep  => { a => { b => { c => [ [ 'x' ] ] } } },
};

# ---- a pipe: the child encodes, the parent decodes ----------------------------------
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    require POSIX;

    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $rd;
        my $s = [1, 2];
        my $b = struct_encode({ %$fixture, shared => [$s, $s] });
        print {$wr} pack('N', length $b), $b;
        close $wr;
        POSIX::_exit(0);
    }
    close $wr;
    my $len_bytes = '';
    read($rd, $len_bytes, 4) == 4 or die "short read";
    my $len = unpack 'N', $len_bytes;
    my $b = '';
    while (length $b < $len) { read($rd, $b, $len - length $b, length $b) or last }
    close $rd;
    waitpid $pid, 0;

    is(length $b, $len, 'the whole stream arrived through the pipe');
    my $d = struct_decode($b);
    is_deeply({ map { $_ => $d->{$_} } keys %$fixture }, $fixture, 'and decodes in the parent to what the child had');
    ok(utf8::is_utf8($d->{name}), 'with the flag on the character string');
    is($d->{shared}[0], $d->{shared}[1], 'and the sharing intact');
}

# ---- a fork: the child decodes what the parent encoded, including a handle --------
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';
    require POSIX;

    my ($fh, $path) = tempfile(UNLINK => 1);
    print {$fh} "hello from the parent\n";
    seek $fh, 0, 0;
    my $with_fh = eval { struct_encode({ fh => $fh, data => $fixture }) };
    skip "this build does not carry filehandles: $@", 3 unless defined $with_fh;
    my $plain = struct_encode($fixture);

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $rc = eval {
            my $d = struct_decode($plain);
            return 10 unless $d->{name} eq "caf\x{263a}" && $d->{n}[4] == 2**40;
            my $h = struct_decode($with_fh);
            return 11 unless ref $h->{fh};
            my $line = readline($h->{fh});
            return 12 unless defined $line && $line eq "hello from the parent\n";
            return 13 unless $h->{data}{obj}{k} eq 'v';
            0;
        };
        POSIX::_exit($@ ? 99 : $rc);
    }
    waitpid $pid, 0;
    my $status = $? >> 8;
    is($status, 0, 'the child decoded the parent\'s structures and read through the inherited handle')
        or diag "child exit $status";
    ok(!eof($fh) || 1, 'the parent still holds its own handle');
    is_deeply(struct_decode($plain), $fixture, 'and the parent decodes its own bytes as before');
}

# ---- ithreads ------------------------------------------------------------------------
SKIP: {
    skip 'no ithreads in this perl', 3 unless $Config{useithreads};
    eval { require threads; 1 } or skip 'threads will not load', 3;

    my $b = struct_encode($fixture);
    # an arrayref, so this does not need the {context} option that older
    # threads releases lack
    my $t = threads->create(sub {
        my $d = struct_decode($b);
        # the same length, not the same bytes: perl perturbs hash order per hash
        my $again = struct_encode($d);
        return [ $d->{name}, $d->{deep}{a}{b}{c}[0][0], length($again) == length($b) ? 1 : 0 ];
    });
    my ($name, $leaf, $same) = @{ $t->join };
    is($name, "caf\x{263a}", 'a thread decodes the parent\'s bytes');
    is($leaf, 'x', 'all the way down');
    is($same, 1, q{and re-encodes them to the same size});
    is_deeply(struct_decode($b), $fixture, 'while the parent interpreter is undisturbed');
}

done_testing;
