use strict;
use warnings;
use Test::More;

use Music::Chord::Note;

my $cn = Music::Chord::Note->new;

{
    my @intervals = $cn->chord_intervals('');
    is "@intervals", '0 4 3';
}

{
    my @intervals = $cn->chord_intervals('m');
    is "@intervals", '0 3 4';
}

{
    my @intervals = $cn->chord_intervals('M7');
    is "@intervals", '0 4 3 4';
}

{
    eval { $cn->chord_intervals('X'); };
    like($@, qr/undefined kind of chord/);
}

done_testing();
