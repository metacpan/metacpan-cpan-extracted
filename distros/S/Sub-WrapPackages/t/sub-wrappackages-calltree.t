package main;

use strict;
use warnings;
use lib 't/lib';

use Test::More;

use Capture::Tiny qw(capture);

use Sub::WrapPackages::CallTree 'Sub::WrapPackages::Tests::*';
use Sub::WrapPackages::Tests::Victim;

my($stdout, $stderr, @result) = capture { Sub::WrapPackages::Tests::Victim->foo() };
$stderr =~ s/\r//g; # Windows
is($stdout, '', 'good, no extraneous nonsense on STDOUT');
is_deeply(\@result, [2, 'OMG', 'ROBOTS', 5], 'right return value');
is(
    $stderr,
'Called Sub::WrapPackages::Tests::Victim::foo with: [Sub::WrapPackages::Tests::Victim]
  Called Sub::WrapPackages::Tests::Victim::bar with: [1]
    Called Sub::WrapPackages::Tests::Victim::baz with: [OMG, ROBOTS, 5]
    Return from Sub::WrapPackages::Tests::Victim::baz with: [OMG, ROBOTS, 5]
  Return from Sub::WrapPackages::Tests::Victim::bar with: [OMG, ROBOTS, 5]
Return from Sub::WrapPackages::Tests::Victim::foo with: [2, OMG, ROBOTS, 5]
',
    'exactly the right nonsense on STDERR'
);
done_testing();
