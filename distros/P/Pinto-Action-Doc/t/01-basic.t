use strict;
use warnings;
use Test::More;
use Pinto::Action::Doc;
use Pinto::Repository;
use Pinto::Chrome::Term;
use FindBin;
use File::Temp;
use File::DirCompare;

my $tmp_dir = File::Temp::newdir("$FindBin::Bin/out");

my $pap = Pinto::Action::Doc->new(
    repo   => Pinto::Repository->new(root => "$FindBin::Bin/pinto"),
    chrome => Pinto::Chrome::Term->new,
    out    => "$tmp_dir",
    title  => "Docs Test",
);

$pap->execute;


File::DirCompare->compare("$tmp_dir", "$FindBin::Bin/docs", sub {
    fail "HTML failed to generate properly";
    done_testing();
    exit;
},{
    cmp => sub { -s $_[0] != -s $_[1] },
});

pass "HTML generated successfully";

done_testing(); 
