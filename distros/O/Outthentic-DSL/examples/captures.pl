use Outthentic::DSL;
use Data::Dumper;

my $otx = Outthentic::DSL->new(<<'HERE');
    1 - for one
    2 - for two
    3 - for three
HERE

$otx->validate(<<'CHECK');

regexp: (\d+)\s+-\s+for\s+(\w+)

CHECK

print Dumper($otx->{captures});

