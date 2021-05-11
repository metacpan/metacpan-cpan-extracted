use strict;
use warnings;
use PICA::Schema::Builder;
use Test::More;

my $builder = PICA::Schema::Builder->new;

$builder->add([['003@', undef, '0', '1234']]);

my $fields = {
    '003@' => {
        tag       => '003@',
        required  => \1,
        subfields => {'0' => {code => '0', required => \1}}
    }
};
is_deeply $builder->schema->{fields}, $fields;

$builder->add(
    [
        ['003@', undef, '0', 111, 0, 222],    # repeat existing subfield
        ['144Z', '', 'x', 333],               # introduce new field
    ]
);

$fields->{'003@'}{subfields}{0}{repeatable} = \1;
$fields->{'144Z'}
    = {tag => '144Z', subfields => {x => {code => 'x', required => \1}}};

is_deeply $builder->schema->{fields}, $fields;

$builder->add(
    [
        ['003@', '', '0', 333, 'x', 444],    # introduce new subfield
    ]
);

$fields->{'003@'}{subfields}{x} = {code => 'x'};

is_deeply $builder->schema->{fields}, $fields;

$builder->add(
    [
        # omit 003@
        ['028B', '01', 'x', 1],              # new field with occurrence
        ['144Z', '',   'y', 0],              # omit 114Z$x
    ]
);

delete $fields->{'003@'}{required};
delete $fields->{'144Z'}{subfields}{x}{required};
$fields->{'144Z'}{subfields}{y} = {code => 'y'};
$fields->{'028B/01'} = {
    tag        => '028B',
    occurrence => '01',
    subfields  => {x => {code => 'x', required => \1}}
};

is_deeply $builder->schema->{fields}, $fields;

done_testing;
