#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Role::Tiny ();
use Test::Exception;
use Music::Note;
Role::Tiny->apply_roles_to_package('Music::Note', 'Music::Note::Role::Operators');

my $note = Music::Note->new('C');
my $other = Music::Note->new('G');

subtest 'edge cases' => sub {
    # Some overload gotchas I found during workup
    ok "$note", "Note stringifies according to default behaviour";
    ok !!$note, "Note boolifies ok according to default behaviour";
};

subtest 'overloading' => sub {
    # Implementation tests
    ok $other->gt($note), "note greater than other";
    ok $other > $note, "note greater than other overloaded";

    ok $note->lt($other), "note less than other";
    ok $note < $other, "note less than other overloaded";

    my $same = $note->clone;
    ok $note->lte($same), "note less than or equal to its clone";
    ok $note <= $same, "note less than or equal to clone overloaded";
    ok $note->gte($same), "note greater than or equal to its clone";

    ok $note->eq($same), "note is same val as its clone";
    ok $note == $same, "note is same value as its clone overloaded";

    dies_ok { $note < 10 } "Overloading should only be done where both entities are a Music::Note";

    is $other->subtract($note), 7, "Other is 7 semitones above note";
    is $other - $note, 7, "Other is 7 semitones above note overloaded";
    is $note->subtract($other), -7, "Other is 7 semitones below note";
    is $note - $other, -7, "Note is 7 semitones below other overloaded";

};

subtest 'intervals' => sub {

    my $interval = $other->get_interval($note);
    isa_ok($interval, 'Music::Intervals');

    my %equiv_args = ( 'equalt' => 1,
                       'interval' => 1,
                       'notes' => [ 'G', 'C' ],
                       'prime' => 1,
                       'chords' => 1,
                       'freqs' => 1,
                       'integer' => 1,
                       'cents' => 1,
                       'size' => 2
                   );

    my $same_interval = $note->get_interval(%equiv_args);
    is_deeply $interval, $same_interval, "Special constructor shortcut for interval is sane";
    my $unprocessed = $note->get_interval(%equiv_args, no_process => 1);
    is_deeply $unprocessed->eq_tempered_cents, {}, "Unprocessed calculated stuff is empty";
    $unprocessed->process;
    is_deeply $interval, $unprocessed, "Same thing after processing";
};

done_testing;
