#!perl -w
use strict;

use Test::More tests => 18;

use IO::Handle;
use File::Spec;

BEGIN{
	use_ok('PerlIO::Util');
}

sub anonio(){
	return select select my $anonio;
}

my %l;
my @layers = PerlIO::Util->known_layers();

@l{ @layers } = ();

ok scalar(@layers), 'known_layers()';
ok exists $l{raw},  ':raw exists';
ok exists $l{crlf}, ':crlf exists';


# IO::Handle::push_layer()/pop_layer()
my $s = 'bar';
@layers = DATA->get_layers();

DATA->push_layer(scalar => \$s);

is_deeply [DATA->get_layers()], [@layers, 'scalar'], 'push_layer(scalar)';

is scalar(<DATA>), 'bar', '... pushed correctly';

DATA->pop_layer();

is_deeply [DATA->get_layers()], \@layers, 'pop_layer()';
is scalar(<DATA>), "foo\n", '... popped correctly';


DATA->push_layer(':utf8');
is_deeply [DATA->get_layers()], [@layers, 'utf8'], 'allows ":foo" style';
DATA->pop_layer();

is *DATA->push_layer('crlf'), \*DATA,
	'push_layer() returns self';

is *DATA->pop_layer(), 'crlf', 'pop_layer() returns the name of the poped layer';

# open()

my $io = PerlIO::Util->open('<', \(my $x = 'foo'));
ok $io, 'PerlIO::Util->open()';
ok defined( fileno $io ), "... opened";

# checks on errors

eval{
	local $INC{'PerlIO/foo.pm'} = __FILE__;

	DATA->push_layer('foo');
};

like $@, qr/Unknown PerlIO layer/, 'push_layer(): Unknown PerlIO layer';

eval{
	anonio()->push_layer('raw');
};

like $@, qr/Invalid filehandle/, 'push_layer(): Invalid filehandle';

ok !(anonio()->pop_layer()), 'pop_layer(): returns false';

eval{
	PerlIO::Util->open('file');
};
like $@, qr/Usage/i, 'open(): too few arguments';

eval{
	PerlIO::Util->open('<', 'no such file');
};
like $@, qr/Cannot open/i, 'open(): cannot open file';

__DATA__
foo
