use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;
use Term::ANSIColor qw(colored);

sub main_in_test {

    my $moment = Moment->new( dt => '2000-01-01 00:00:00' );
    is(
        $moment->_data_printer(),
        colored('2000-01-01T00:00:00Z', 'yellow'),
        '_data_printer()',
    );

    done_testing;

}
main_in_test();
