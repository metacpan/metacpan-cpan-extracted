use Test::More;

use Rope::Handles::Hash;

my $data = Rope::Handles::Hash->new({a => 1, b => 2});

my @out = $data->each(sub {
	"$_[0] $_[1]"
});

is_deeply(\@out, [
	"a 1",
	"b 2"	
]);

my @out = $data->entries(sub {
	"$_[0] $_[1]"
});

is_deeply(\@out, [
	"a 1",
	"b 2"
]);

done_testing();
