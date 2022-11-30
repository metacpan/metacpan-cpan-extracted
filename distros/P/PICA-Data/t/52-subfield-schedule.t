use v5.14.1;
use PICA::Schema qw(parse_subfield_schedule);
use Test::More;
use Test::Deep;

my %tests = (
    'ab?c' => {
        a => { required => 1, repeatable => 0, code => 'a', order => 1 },
        b => { required => 0, repeatable => 0, code => 'b', order => 2 },
        c => { required => 1, repeatable => 0, code => 'c', order => 3 },
    },
    '0*Xz+' => {
        0 => { required => 0, repeatable => 1, code => '0', order => 1 },
        X => { required => 1, repeatable => 0, code => 'X', order => 2 },
        z => { required => 1, repeatable => 1, code => 'z', order => 3 },
    }
);

while (my ($string, $schedule) = each %tests) {
    is_deeply parse_subfield_schedule($string), $schedule;
}

done_testing;
