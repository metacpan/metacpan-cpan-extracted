#!perl
use strict;
use lib qw<bin t/lib>;
use Test::More;
use Test::Exception;
use Local::Helpers;
use Test::Output;
require 'rcon-minecraft';

# Mock standard input for the <STDIN> version of the input
{
    package MockSTDIN;
    use parent qw< Tie::Handle >;

    sub TIEHANDLE { bless $_[1], $_[0] }
    sub READLINE {
        my $s = shift;
        return unless @{$s};
        shift @{$s};
    }
};

my $mock = bin_mock();
my $p = q<--pass=secret>;
stdout_like { main($p,'--command=foo') } qr/foo/, 'Basic command';
stdout_like { main($p,'--command=foo') } qr/foo/, 'Basic command';
stdout_like { main($p,'foo args')      } qr/foo/, 'Plain command';
stdout_like { main($p,qw<--quiet foo>) } qr/^$/;
stdout_like { main($p,qw<--echo foo>)  } qr/^> foo\nRAN foo$/;
stdout_like { main($p,qw<--echo --quiet foo>) } qr/^> foo\n$/;
stdout_like { main($p,qw<--color foo>) } qr/^RAN foo\e\[0m$/;
stdout_like { main($p,qw<empty>)       } qr/^\[Command sent\]$/;

# <STDIN> input
{
    my @stdin = map { $_ . "\n" } ('command1 args', 'command2');
    tie *STDIN, 'MockSTDIN', \@stdin;
    stdout_like { main($p) } qr/^RAN command1 args\nRAN command2$/;
}

done_testing;
