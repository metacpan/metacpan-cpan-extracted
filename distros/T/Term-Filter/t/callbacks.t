#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use IO::Pty::Easy;
use IO::Select;

my $script = <<'SCRIPT';
use strict;
use warnings;
use Term::Filter::Callback;
my $term = Term::Filter::Callback->new(
    callbacks => {
        setup => sub {
            my ($t, @cmd) = @_;
            my $ref = ref($t);
            print "SETUP: $t ($ref): @cmd\n";
        },
        cleanup => sub {
            my ($t) = @_;
            my $ref = ref($t);
            print "CLEANUP: $t ($ref)\n";
        },
        munge_input => sub {
            my ($t, $buf) = @_;
            my $ref = ref($t);
            print "MUNGE_INPUT: $t ($ref): $buf\n";
            $buf = "\n" if $buf =~ /exit/i;
            return uc($buf);
        },
        munge_output => sub {
            my ($t, $buf) = @_;
            my $ref = ref($t);
            print "MUNGE_OUTPUT: $t ($ref): $buf\n";
            return lc($buf);
        },
    }
);
print "$term\n";
$term->run($^X, '-ple', q[last if /^$/]);
print "done\n";
SCRIPT

my $crlf = qr/\x0d\x0a/;

# just in case
alarm 60;

{
    my $pty = IO::Pty::Easy->new(handle_pty_size => 0);
    $pty->spawn($^X, (map {; '-I', $_ } @INC), '-e', $script);

    my $setup_str = full_read($pty);

    my ($term_str, $ref) = $setup_str =~ m{
        ^
        ((.*)=.*)
        \n
        SETUP: \s \1 \s \(\2\):\s
        \Q$^X\E .* \Q-ple\E .* last\ if\ /\^\$/ .*
        \n
        $
    }sx;

    is($ref, 'Term::Filter::Callback', "setup callback got a Term::Filter::Callback object");

    $pty->write("fOo\n");

    like(
        full_read($pty),
        qr{
            ^
            MUNGE_INPUT: \s \Q$term_str\E \s \($ref\): \s fOo\n
            \n
            (?:
            MUNGE_OUTPUT: \s \Q$term_str\E \s \($ref\): \s FOO$crlf
            \n
            foo$crlf
            MUNGE_OUTPUT: \s \Q$term_str\E \s \($ref\): \s FOO$crlf
            \n
            foo$crlf
            |
            MUNGE_OUTPUT: \s \Q$term_str\E \s \($ref\): \s FOO$crlf FOO$crlf
            \n
            foo$crlf
            foo$crlf
            )
            $
        }sx,
        "munge_input and munge_output got the right arguments"
    );

    $pty->write("EXIT\n");

    like(
        full_read($pty),
        qr{
            ^
            MUNGE_INPUT: \s \Q$term_str\E \s \($ref\): \s EXIT\n
            \n
            MUNGE_OUTPUT: \s \Q$term_str\E \s \($ref\): \s $crlf
            \n
            $crlf
            CLEANUP: \s \Q$term_str\E \s \($ref\)\n
            done\n
            $
        }sx,
        "cleanup got the right arguments"
    );
}

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
