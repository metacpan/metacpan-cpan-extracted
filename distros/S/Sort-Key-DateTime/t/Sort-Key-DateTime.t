# -*- Mode: Perl -*-

use Test::More tests => 7;

use DateTime;
use Sort::Key::DateTime qw(dtkeysort);

my @tz = grep { eval { DateTime->new(year => 2000, month => 1, day => 1,
                                     hour => 1, minute => 1, second => 1,
                                     timezone => $_); } }
    qw(UTC Europe/Madrid Asia/Taipei America/Los_Angeles Europe/Paris Europe/London);

for (10, 20, 100, 200, 1000, 2000, 5000) {
    my @unsorted = map { DateTime->new( year => 1900+int rand(20),
					month => 1+int rand(12),
					day => 1+int rand(28),
					hour => int rand(24),
					minute => int rand(60),
					second => int rand(60),
					(@tz ? (time_zone => $tz[int rand(@tz)] ) : ()) ) } 0..$_;

    is_deeply([dtkeysort { $_ } @unsorted], [sort @unsorted], "sorting $_");
}
