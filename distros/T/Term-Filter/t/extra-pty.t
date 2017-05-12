#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::Temp 'tempdir';
use File::Spec;
use IO::Pty::Easy;
use IO::Select;
use POSIX ();

my $dir = tempdir(CLEANUP => 1);
my $readp = File::Spec->catfile($dir, 'read');
my $writep = File::Spec->catfile($dir, 'write');
POSIX::mkfifo($readp, 0700)
    or die "mkfifo failed: $!";
POSIX::mkfifo($writep, 0700)
    or die "mkfifo failed: $!";

my $script = <<SCRIPT;
use strict;
use warnings;
use Term::Filter::Callback;
open my \$readfh, '<', '$readp'
    or die "can't open pipe (child): \$!";
open my \$writefh, '>', '$writep'
    or die "can't open pipe (child): \$!";
my \$term = Term::Filter::Callback->new(
    callbacks => {
        setup => sub {
            my (\$t) = \@_;
            \$t->add_input_handle(\$readfh);
        },
        read => sub {
            my (\$t, \$fh) = \@_;
            if (\$fh == \$readfh) {
                my \$buf;
                sysread(\$fh, \$buf, 4096);
                if (defined(\$buf) && length(\$buf)) {
                    print "1read from pipe: \$buf\\n";
                }
                else {
                    print "2pipe error (read)!\\n";
                    \$t->remove_input_handle(\$readfh);
                }
            }
        },
        read_error => sub {
            my (\$t, \$fh) = \@_;
            if (\$fh == \$readfh) {
                print "3pipe error (exception)!\\n";
                \$t->remove_input_handle(\$readfh);
            }
        },
        munge_output => sub {
            my (\$t, \$buf) = \@_;
            syswrite(\$writefh, "4read from term: \$buf");
            \$buf;
        },
    }
);
\$term->run(\$^X, '-ple', q[last if /^\$/]);
print "5done\\n";
SCRIPT

my $crlf = "\x0d\x0a";

# just in case
alarm 60;

{
    my $pty = IO::Pty::Easy->new(handle_pty_size => 0);
    $pty->spawn($^X, (map {; '-I', $_ } @INC), '-e', $script);

    open my $readfh, '>', $readp
        or die "can't open pipe (parent): $!";
    open my $writefh, '<', $writep
        or die "can't open pipe (parent): $!";

    $pty->write("foo\n");

    is(full_read($pty), "foo${crlf}foo${crlf}");

    {
        my $got_pipe = full_read($writefh);
        like($got_pipe, qr/4read from term: /);
        $got_pipe =~ s/4read from term: //g;
        is($got_pipe, "foo${crlf}foo${crlf}");
    }

    syswrite($readfh, "bar");

    {
        my $got_pty = full_read($pty);
        like($got_pty, qr/1read from pipe: /);
        $got_pty =~ s/1read from pipe: //g;
        is($got_pty, "bar\n");
    }

    close($readfh);
    close($writefh);

    # whether this generates an exception or a failed read is system-dependent
    like(full_read($pty), qr/pipe error/);
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
