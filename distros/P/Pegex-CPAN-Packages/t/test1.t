use Test::More;
use Pegex::CPAN::Packages;

my $t = -e 't' ? 't' : 'test';
my $text = do {
    open my $fh, "$t/02packages.txt" or die;
    local $/;
    <$fh>;
};

Pegex::CPAN::Packages->parse($text);

pass 'OK';

done_testing;
