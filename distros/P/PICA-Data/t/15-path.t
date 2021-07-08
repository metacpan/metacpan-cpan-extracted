use strict;
use Test::More;

use PICA::Path;

my %pathes = (
    '003.$abc' => '003.$abc',
    '003.abc'  => '003.$abc',
    '001B$0'   => '001B$0',
    '123A[0.]/1-3' => '123A[0.]/1-3',
    '123+'         => undef,
    '300@'         => undef,
    '003$$'        => undef,
    '123A/-'       => undef,
    '003X/0'     => '003X/0',
    '..../10-10' => '..../10',
    '..../1-'    => '..../1-',
    '..../0-' => '....',
    '003X[0-01]' => '003X[0-1]',
    '003X[2-02]' => '003X[2]',
    '003X[7-13]' => '003X[7-13]',
    '003X[13-7]' => undef,
    #'....{}'   => undef,
    #'....{}}'   => undef,
    #    '....{$x}{$y}'   => '....{$x}{$y}',
    #'....{$x}'   => '....{$x}',
);

foreach my $path (keys %pathes) {
    my $parsed = eval {PICA::Path->new($path)};
    if ($@) {
        is $pathes{$path}, undef, "invalid path: $path";
    }
    else {
        is "$parsed", $pathes{$path}, 'stringify';
    }
}

is "" . PICA::Path->new('123A[00]'), '123A';
is "" . PICA::Path->new('003.abc')->stringify(1), '003.abc', 'stringify(1)';

my $field = ['123A', undef, _ => 'abcdefghijk'];
my %matches
    = ('123A' => ['abcdefghijk'], '123A/1' => ['b'], '123A/10-' => ['k']);

while (my ($path, $values) = each %matches) {
    is_deeply [PICA::Path->new($path)->match_subfields($field)], $values;
}

ok(PICA::Path->new('....[0-3]')->match_field(['000X','0']), 'occurrence range');
ok(!PICA::Path->new('....[0-3]')->match_field(['000X','4']), 'occurrence range');
ok(PICA::Path->new('....[7-13]')->match_field(['000X','13']), 'occurrence range');
ok(!PICA::Path->new('....[7-13]')->match_field(['000X','14']), 'occurrence range');
ok(!PICA::Path->new('....[7-13]')->match_field(['000X','6']), 'occurrence range');

# Accessors
my $path = PICA::Path->new('123A[0.]/1-3');
is $path->fields,      '123A';
is $path->occurrences, '0.';
is $path->subfields,   undef;
is $path->positions,   '1-3';

$path = PICA::Path->new('00..$0');
is $path->fields,      '00..';
is $path->occurrences, undef;
is $path->subfields,   '0';
is $path->positions,   undef;

is(PICA::Path->new('123X/0-3', position_as_occurrence => 1)->stringify,
    '123X[0-3]', 'position_as_occurrence');
is(PICA::Path->new('123X/9-10', position_as_occurrence => 1)->stringify,
    '123X[9-10]', 'position_as_occurrence');
is(PICA::Path->new('123X/42', position_as_occurrence => 1)->stringify,
    '123X[42]', 'position_as_occurrence');

done_testing;
