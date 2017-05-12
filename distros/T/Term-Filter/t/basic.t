#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use IO::Pty::Easy;
use IO::Select;

my $pty = IO::Pty::Easy->new(handle_pty_size => 0);

my $script = <<'SCRIPT';
use strict;
use warnings;
use Term::Filter::Callback;
my $term = Term::Filter::Callback->new;
$term->run($^X, '-ple', q[last if /^$/]);
print "done\n";
SCRIPT

my $crlf = "\x0d\x0a";

$pty->spawn($^X, (map {; '-I', $_ } @INC), '-e', $script);

# just in case
alarm 60;

$pty->write("foo\n");
is(full_read($pty), "foo${crlf}foo${crlf}");
$pty->write("bar\nbaz\n");
like(
    full_read($pty),
    qr{
        ^
        bar \Q$crlf\E
        (?:
            bar \Q$crlf\E
            baz \Q$crlf\E
        |
            baz \Q$crlf\E
            bar \Q$crlf\E
        )
        baz \Q$crlf\E
        $
    }mx,
);
$pty->write("\n");
is(full_read($pty), "${crlf}done\n");

sub full_read {
    my ($fh) = @_;

    my $select = IO::Select->new($fh);
    return if $select->has_exception(0.1);

    1 while !$select->can_read(1);

    my $ret;
    while ($select->can_read(1)) {
        my $new;
        sysread($fh, $new, 4096);
        last unless defined($new) && length($new);
        $ret .= $new;
        return $ret if $select->has_exception(0.1);
    }

    return $ret;
}

done_testing;
