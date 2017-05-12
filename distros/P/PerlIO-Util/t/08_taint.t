#!perl -wT
use strict;

use Test::More tests => 7;

use FindBin qw($Bin);
use File::Spec;
use Scalar::Util qw(tainted);

use PerlIO::Util;

# $^X is tainted
my $tainted = substr($^X, 0, 0);

my $path = File::Spec->join($Bin, 'util', 'taint') . $tainted;

ok tainted($path), 'using tainted string';

eval{
	open my $tee, '>:tee', File::Spec->devnull, $path;
};
like $@, qr/insecure/i, 'insecure :tee';

my $io;
eval{
	$io = PerlIO::Util->open('>:tee', File::Spec->devnull);
	$io->push_layer(tee => $path);
};
like $@, qr/insecure/i, 'insecure :tee';

ok close($io), 'close io with a uninitialized layer';

eval{
	open my $io, '+<:creat', $path;
};
like $@, qr/insecure/i, 'insecure :creat';

eval{
	open my $io, '+<:excl', $path;
};
like $@, qr/insecure/i, 'insecure :excl';

END{
	ok !-e $path, 'file not created';
}
