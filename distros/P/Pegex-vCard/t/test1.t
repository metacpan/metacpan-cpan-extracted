use Test::More;
use Pegex::vCard;

my $t = -e 't' ? 't' : 'test';
my $text = do {
    open my $fh, "$t/card1.vcard" or die;
    local $/;
    <$fh>;
};

my $vcard = Pegex::vCard->parse($text);

pass 'card1.vcard parses';
is $vcard->{ORG}, 'Bubba Gump Shrimp Co.', 'ORG parses';

done_testing;
