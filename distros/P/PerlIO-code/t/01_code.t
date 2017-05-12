#!perl
use strict;
use warnings;
use Test::More tests => 23;

use PerlIO::code;

my $o;
my @data = ("foo\n", "bar\n", "baz");
sub input{
	return shift @data;
}

sub output{
	($o) = @_;
}

sub inout{
	($o) = @_;
	return shift @data;
}

my $fh;
ok open($fh, '<', \&input), 'open for reading';

is scalar(<$fh>), "foo\n", 'readline:0';
is scalar(<$fh>), "bar\n", 'readline:1';
is scalar(<$fh>), 'baz',   'readline:2';
ok !defined(<$fh>),        'readline:undef';
ok !defined(<$fh>),        'readline:undef (again)';
ok eof($fh), 'eof';

ok close($fh), 'close';

ok open($fh, '>', \&output), 'open for writing';

print $fh "foo\n";

is $o, "foo\n", 'print';

print $fh 'bar';

is $o, 'bar', 'print';

ok close($fh), 'close';

is $o, 'bar', 'print (after closed)';

#ok open($fh, '+<', \&inout), 'open for reading/writing';
#@data = ("foo\n");
#print $fh "bar\n";
#
#is $o, "bar\n", 'print';
#is_deeply [<$fh>], ["foo\n"], 'readline';
#ok close($fh), 'close';

# binmode

ok open($fh, '<:utf8', sub{}), 'open';
is_deeply [PerlIO::get_layers($fh)], ['Code', 'utf8'], 'with :utf8';
binmode $fh;
is_deeply [PerlIO::get_layers($fh)], ['Code'], 'without :utf8';
ok close($fh), 'close';


# extra

sub foo{
	"foo\n";
}
binmode *STDIN, ':Code(foo)';
is scalar(<STDIN>), "foo\n";

binmode *STDIN, ':pop';

# errors

ok open(my $c, '+<', \&notfound), 'open';
eval{
	my $s = <$c>;
};
ok $@, 'undefined subroutine';

eval{
	print $c "foo";
};
ok $@, 'undefined subroutine';

ok !binmode(*STDIN, ':Code'), 'no args';

eval{
	binmode *STDIN, ':Code()';
};
ok $@, 'unable to create empty named subroutine';
