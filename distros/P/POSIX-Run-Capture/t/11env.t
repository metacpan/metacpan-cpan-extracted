# -*- perl -*-

use lib 't';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 6;
use POSIX::Run::Capture qw(:std);

my $obj = new POSIX::Run::Capture(['/bin/sh', '-c', 'echo $FOO-$BAZ']);

$ENV{FOO}='foo';
$ENV{BAZ}='baz';
$obj->run;
is($obj->next_line(SD_STDOUT), "foo-baz\n");

# Set environment
$obj->set_env('FOO=bar', 'BAZ=quux');
is(0+@{$obj->env}, 2);
is_deeply($obj->env, [ 'FOO=bar', 'BAZ=quux' ]);

$obj->run;
is($obj->next_line(SD_STDOUT), "bar-quux\n");

# Unset environment
$obj->set_env();
$obj->run;
is($obj->next_line(SD_STDOUT), "foo-baz\n");

ok(TestCapture({ argv => ['/bin/sh', '-c', 'echo $FOO-$BAZ'],
		 env => ['FOO=bar', 'BAZ=quux'] },
	       stdout => {
		   content => "bar-quux\n"
	       }));
