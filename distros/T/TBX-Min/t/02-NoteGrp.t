#test the functionality of TBX::Min::NoteGrpGrp

use strict;
use warnings;
use Test::More;
plan tests => 7;
use Test::NoWarnings;
use Test::Exception;
use TBX::Min;

my $args = {
    notes => [
        TBX::Min::Note->new({
            noteKey => 'foo1',
            noteValue => 'bar1'
        }),
        TBX::Min::Note->new({
            noteKey => 'foo2',
            noteValue => 'bar2'
        })
    ],
};

#test constructor without arguments
my $note_grp = TBX::Min::NoteGrp->new();
isa_ok($note_grp, 'TBX::Min::NoteGrp');

ok($#{$note_grp->notes} == -1, 'no notes by default');

#test constructor with arguments
$note_grp = TBX::Min::NoteGrp->new($args);
is_deeply($note_grp->notes, $args->{notes},
    'correct notes from constructor');

#test setter
$note_grp = TBX::Min::NoteGrp->new();

$note_grp->add_note($args->{notes}->[0]);
is($note_grp->notes->[0], $args->{notes}->[0], 'note correctly added');

throws_ok {
    TBX::Min::NoteGrp->new({foo=>'bar'});
} qr{Invalid attributes for class: foo},
'constructor fails with bad arguments';

throws_ok {
    TBX::Min::NoteGrp->new({notes=>'bar'});
} qr{Attribute 'notes' should be an array reference},
'constructor fails with incorrect data type for notes';
