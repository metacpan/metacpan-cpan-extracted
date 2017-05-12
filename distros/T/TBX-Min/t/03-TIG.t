#test the functionality of TBX::Min::TIG

use strict;
use warnings;
use Test::More;
plan tests =>31;
use Test::NoWarnings;
use Test::Exception;
use TBX::Min;

my $args = {
    term => 'foo1',
    part_of_speech => 'noun',
    note_groups => [
        TBX::Min::NoteGrp->new({
            notes => [
                TBX::Min::Note->new({
                    noteKey => 'foo',
                    noteValue => 'bar'
            })]
    })],
    customer => 'foo4',
    status => 'preferred',
};


#test constructor without arguments
my $term_grp = TBX::Min::TIG->new();
isa_ok($term_grp, 'TBX::Min::TIG');

ok(!$term_grp->term, 'term not defined by default');
ok(!$term_grp->part_of_speech, 'part_of_speech not defined by default');
ok($#{$term_grp->note_groups} == -1, 'no note groups by default');
ok(!$term_grp->customer, 'customer not defined by default');
ok(!$term_grp->status, 'status not defined by default');

#test constructor with arguments
$term_grp = TBX::Min::TIG->new($args);
is($term_grp->term, $args->{term}, 'correct term from constructor');
is($term_grp->part_of_speech, $args->{part_of_speech},
    'correct part_of_speech from constructor');
is_deeply($term_grp->note_groups, $args->{note_groups}, 'correct note groups from constructor');
is($term_grp->customer, $args->{customer}, 'correct customer from constructor');
is($term_grp->status, $args->{status}, 'correct status from constructor');

#test setters
$term_grp = TBX::Min::TIG->new();

$term_grp->term($args->{term});
is($term_grp->term, $args->{term}, 'term correctly set');

$term_grp->part_of_speech($args->{part_of_speech});
is($term_grp->part_of_speech, $args->{part_of_speech}, 'part_of_speech correctly set');

$term_grp->add_note_group($args->{note_groups}->[0]);
is_deeply($term_grp->note_groups, $args->{note_groups}, 'note correctly set');

$term_grp->customer($args->{customer});
is($term_grp->customer, $args->{customer}, 'customer correctly set');

$term_grp->status($args->{status});
is($term_grp->status, $args->{status}, 'status correctly set');

# check validity of part_of_speech picklist values
for my $pos(qw(noun properNoun verb adjective adverb other)) {
    subtest "$pos is a legal part_of_speech value" => sub {
        plan tests => 2;
        lives_ok {
            $term_grp = TBX::Min::TIG->new(part_of_speech => $pos);
        } 'constructor';
        lives_ok {
            $term_grp = TBX::Min::TIG->new();
            $term_grp->part_of_speech($pos);
        } 'accessor';
    };
}

subtest 'foo is not a legal part_of_speech value' => sub {
    plan tests => 2;
    my $error = qr/illegal part of speech 'foo'/i;
    throws_ok {
        $term_grp = TBX::Min::TIG->new(part_of_speech => 'foo');
    } $error, 'constructor';
    throws_ok {
        $term_grp = TBX::Min::TIG->new();
        $term_grp->part_of_speech('foo');
    } $error, 'accessor';
};

# check validity of status picklist values
for my $status(qw(admitted preferred notRecommended obsolete)) {
    subtest "$status is a legal status value" => sub {
        plan tests => 2;
        lives_ok {
            $term_grp = TBX::Min::TIG->new(status => $status);
        } 'constructor';
        lives_ok {
            $term_grp = TBX::Min::TIG->new();
            $term_grp->status($status);
        } 'accessor';
    };
}

subtest 'foo is not a legal status value' => sub {
    plan tests => 2;
    my $error = qr/illegal status 'foo'/i;
    throws_ok {
        $term_grp = TBX::Min::TIG->new(status => 'foo');
    } $error, 'constructor';
    throws_ok {
        $term_grp = TBX::Min::TIG->new();
        $term_grp->status('foo');
    } $error, 'accessor';
};

throws_ok {
    TBX::Min::TIG->new({foo=>'bar'});
} qr{Invalid attributes for class: foo},
'constructor fails with bad arguments';

throws_ok {
    TBX::Min::TIG->new({note_groups => 'bar'});
} qr{Attribute 'note_groups' should be an array reference},
'constructor fails with incorrect data type for note_groups';
