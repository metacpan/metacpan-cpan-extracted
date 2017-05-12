#test the functionality of TBX::Min::Note

use strict;
use warnings;
use Test::More;
plan tests => 9;
use Test::NoWarnings;
use Test::Exception;
use TBX::Min;

my $args = {
    noteKey => 'foo',
    noteValue => 'bar',
};

#test constructor without arguments
my $note = TBX::Min::Note->new();
isa_ok($note, 'TBX::Min::Note');

ok(!$note->noteKey, 'noteKey not defined by default');
ok(!$note->noteValue, 'noteValue not defined by default');

#test constructor with arguments
$note = TBX::Min::Note->new($args);
is($note->noteKey, $args->{noteKey}, 'correct noteKey from constructor');
is($note->noteValue, $args->{noteValue},
    'correct noteValue from constructor');

#test setters
$note = TBX::Min::Note->new();

$note->noteKey($args->{noteKey});
is($note->noteKey, $args->{noteKey}, 'noteKey correctly set');

$note->noteValue($args->{noteValue});
is($note->noteValue, $args->{noteValue}, 'noteValue correctly set');

throws_ok {
    TBX::Min::Note->new({key=>'foo'});
} qr{Invalid attributes for class: key},
'constructor fails with bad arguments';
