use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Exception;

BEGIN { $INC{'IPC/Cmd.pm'} = 1 }

our $can_run = 0;
our @run;

package IPC::Cmd;

sub can_run { $can_run }
sub run { ( 0, 1 ) }

package main;

use lib 't/lib';

BEGIN {
    use_ok('Test::Cmd::Perl');
}

isa_ok( my $wrapper = Test::Cmd::Perl->new, 'Test::Cmd::Perl' );
throws_ok { $wrapper->run } qr/couldn't find command 'perl'/;
$can_run = 'perl';
throws_ok { $wrapper->run } qr/error running 'perl': 1/;
