#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 51;

BEGIN {
    use_ok 'Socialtext::Resting::Getopt', 'get_rester';
}

No_args: {
    run_ok('');
}

App_args: {
    run_ok("--monkey", Monkey => 1);
    run_ok("foo bar", ARGV => 'foo bar');
}

Rester_options: {
    run_ok("--server foo", server => 'foo');
    run_ok("--workspace monkey", workspace => 'monkey');
}

Shorthand: {
    run_ok("-s foo", server => 'foo');
    run_ok("-w monkey", workspace => 'monkey');
}

sub run_ok {
    my $args = shift;
    my %args = (
        username  => 'user-name',
        password  => 'pass-word',
        workspace => 'work-space',
        server    => 'http://socialtext.net',
        monkey    => '',
        ARGV      => '',
        @_,
    );
    my @tests = @_;

    open(my $fh, ">t/rester.conf") or die;
    print $fh <<EOT;
username  = user-name
password  = pass-word
workspace = work-space
server    = http://socialtext.net
class     = Socialtext::Resting::Mock
EOT
    close $fh or die;
    my $prog = "$^X t/getopt-test.pl --rester-config=t/rester.conf";
    my $output = qx($prog $args);
    for my $f (keys %args) {
        like $output, qr/$f=$args{$f}/i, $f;
    }
    {
        local $/ = undef;
        open($fh, 't/rester.conf') or die;
        my $contents = <$fh>;
        close $fh;
        eval 'require Crypt::CBC';
        SKIP: {
            skip "no Crypt::CBC", 1 if $@;
            like $contents, qr/password = CRYPTED_\S+/, 'pw was crypted';
        }
    }
}

1;
