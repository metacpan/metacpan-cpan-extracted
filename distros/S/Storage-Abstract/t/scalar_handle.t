use Test2::V0;
use Storage::Abstract;

use lib 't/lib';
use Storage::Abstract::Test;

################################################################################
# This tests whether handle to scalar on store works fine
################################################################################

my $storage = Storage::Abstract->new(
	driver => 'Memory',
);

my $content = "one\ntwo\nthree";
open my $fh, '<', \$content
	or die "couldn't open scalar: $!";

$storage->store('foo', $fh);
my $fh2 = $storage->retrieve('foo', \my %info);

is $info{size}, length $content, 'size ok';
is slurp_handle($fh2), $content, 'content ok';

done_testing;

