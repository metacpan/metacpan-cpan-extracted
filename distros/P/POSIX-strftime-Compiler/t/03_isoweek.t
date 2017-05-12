use strict;
use warnings;
use Test::More;
use POSIX::strftime::Compiler;

is( POSIX::strftime::Compiler::strftime('%gW%V',(0, 0, 0, 31, 11, 111)), '11W52', '2011-12-31');
is( POSIX::strftime::Compiler::strftime('%gW%V',(0, 0, 0,  1,  0, 112)), '11W52', '2012-01-01');
is( POSIX::strftime::Compiler::strftime('%gW%V',(0, 0, 0,  2,  0, 112)), '12W01', '2012-01-02');
is( POSIX::strftime::Compiler::strftime('%gW%V',(0, 0, 0, 30, 11, 112)), '12W52', '2012-12-30');
is( POSIX::strftime::Compiler::strftime('%gW%V',(0, 0, 0, 31, 11, 112)), '13W01', '2012-12-31');
is( POSIX::strftime::Compiler::strftime('%gW%V',(0, 0, 0,  1,  0, 113)), '13W01', '2013-01-01');

done_testing;

