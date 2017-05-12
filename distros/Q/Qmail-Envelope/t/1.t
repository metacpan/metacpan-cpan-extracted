
#########################

use Test;
BEGIN { plan tests => 1 };

#########################

use Qmail::Envelope;

my $E = Qmail::Envelope->new();

ok(ref($E), 'Qmail::Envelope');

