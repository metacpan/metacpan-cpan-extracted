#!perl

use strict;
use warnings;

use SysV::SharedMem qw/shared_open shared_remove/;
use Test::More tests => 19;
use Test::Fatal;
use Test::Warnings 0.005 ':all';

sub map_named(\$@) {
	my ($ref, $name, $mode, $size) = @_;
	shared_open($$ref, $name, $mode, size => $size);
	shared_remove($$ref);
	return;
}

sub map_anonymous(\$@) {
	my ($ref, $size) = @_;
	shared_open($$ref, undef, '+<', size => $size);
	shared_remove($$ref);
	return;
}

open my $self, '<:raw', $0 or die "Couldn't open self: $!";
my $slurped = do { local $/; <$self> };

my $mmaped;
is(exception { map_anonymous $mmaped, length $slurped }, undef, 'Mapping succeeded');

substr $mmaped, 0, length $mmaped, $slurped;

is $mmaped, $slurped, '$slurped an $mmaped are equal';

like(warning { $mmaped = reverse $mmaped }, qr/^Writing directly to shared memory is not recommended at /, 'Reversing should give a warning');

is($mmaped, scalar reverse($slurped), '$mmap is reversed');

{
	no warnings 'substr';
	is(warnings { $mmaped = reverse $mmaped }, 0, 'Reversing shouldn\'t give a warning when substr warnings are disabled');
}

is(warnings { $mmaped = $mmaped }, 0, 'No warnings on self-assignment');

like(exception { map_named my $var, 'some-nonexistant-file', '<', 1024 }, qr/Invalid filename for shared memory segment: /, 'Can\'t map wth non-existant file as a key');

like(exception { map_named my $var, $0, '<', 1024 }, qr/Can't open shared memory object: No such file or directory/, 'Can\'t map wth non-existant file as a key');

my @longer_warnings = warnings { $mmaped =~ s/(.)/$1$1/ };
s/ at .*\n$// for @longer_warnings;
is_deeply(\@longer_warnings, [ 'Writing directly to shared memory is not recommended', 'Truncating new value to size of the shared memory segment' ], 'Trying to make it longer gives warnings');

is(warnings { $slurped =~ tr/r/t/ }, 0, 'Translation shouldn\'t cause warnings');

# is(exception { unmap my $foo }, qr/^Could not unmap: this variable is not memory mapped at /, 'Can\'t unmap normal variables');

like(exception { map_anonymous my $foo, 0 }, qr/^Zero length specified for shared memory segment at /, 'Have to provide a length for anonymous maps');

like(warning { $mmaped = "foo" }, qr/^Writing directly to shared memory is not recommended at /, 'Trying to make it shorter gives a warning');

is(length $mmaped, length $slurped, '$mmaped and $slurped still have the same length');

like(warning { $mmaped = 1 }, qr/^Writing directly to shared memory is not recommended at /, 'Cutting should give a warning for numbers too');

like(warning { undef $mmaped }, qr/^Writing directly to shared memory is not recommended at/, 'Survives undefing');

SKIP: {
	skip 'Your perl doesn\'t support hooking localization', 1 if $] < 5.008009;
	map_anonymous our $local, 1024;
	like(exception { local $local }, qr/^Can't localize shared memory segment at /, 'Localization throws an exception');
}

my %hash;
is(exception { map_anonymous $hash{'foo'}, 4096 }, undef, 'mapping a hash element shouldn\'t croak');

my $x;
my $y = \$x;

is(exception { map_anonymous $y, 4096 }, undef, 'mapping to a reference shouldn\'t croak');
