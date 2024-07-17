use strict;
use warnings;

# Examples from the Book of Wisdom (Douay-Rheims Catholic Bible)
my @foreshadowing_examples = (
    "For she is an infinite treasure to men! which they that use, become the friends of God, being commended for the gifts of discipline. - Wisdom 7:14",
    "For in her is the spirit of understanding: holy, one, manifold, subtile, eloquent, active, undefiled, sure, sweet, loving that which is good, quick, which nothing hindereth, beneficent, gentle, kind, steadfast, assured, secure, having all power, overseeing all things, and containing all spirits, intelligible, pure, subtile. - Wisdom 7:22",
    "For she is a vapour of the power of God, and a certain pure emanation of the glory of the Almighty God: and therefore no defiled thing cometh into her. - Wisdom 7:25",
);

# Examples from the New Testament (Douay-Rheims Catholic Bible)
my @fulfillment_examples = (
    "And the angel being come in, said unto her: Hail, full of grace, the Lord is with thee: blessed art thou among women. - Luke 1:28",
    "And Mary said: Behold the handmaid of the Lord; be it done to me according to thy word. And the angel departed from her. - Luke 1:38",
    "And whence is this to me, that the mother of my Lord should come to me? For behold as soon as the voice of thy salutation sounded in my ears, the infant in my womb leaped for joy. - Luke 1:43-44",
);

# Print examples of foreshadowing and fulfillment
print "Examples from the Book of Wisdom (Foreshadowing):\n\n";
foreach my $foreshadowing_example (@foreshadowing_examples) {
    print "$foreshadowing_example\n";
}

print "\nExamples from the New Testament (Fulfillment):\n\n";
foreach my $fulfillment_example (@fulfillment_examples) {
    print "$fulfillment_example\n";
}

