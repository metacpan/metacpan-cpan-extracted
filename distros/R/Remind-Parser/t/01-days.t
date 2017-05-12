use strict;
use warnings;

use Test::More 'tests' => 6;

use_ok( 'Remind::Parser' );

open my $fh, 't/test-files/001.rpo' or die;

my $parser = Remind::Parser->new;
ok( $parser, 'constructed parser' );
isa_ok( $parser, 'Remind::Parser' );

my $reminders = $parser->parse($fh);
ok( $reminders );

my $days = $parser->days;
ok( $days );

is_deeply( $days, do "t/test-files/001.days");
