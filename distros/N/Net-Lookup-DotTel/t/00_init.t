use Test::More tests => 2;

use Net::Lookup::DotTel;

my $lookup = Net::Lookup::DotTel->new;
ok ( defined $lookup, 'new()' );
ok ( $lookup->isa ('Net::Lookup::DotTel'), 'correct class' );
