use v5.40;
use experimental 'signatures';
use Test2::V0;
use PAGI::StructuredParameters;

# Array-value flattening ("pick last"), empty-final-index reconstruction, and
# namespace scoping — the body/query-only behaviors.

subtest 'array values are flattened to the last value by default' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { color => ['red', 'green', 'blue'] },
    );
    is $sp->permitted('color'), { color => 'blue' },
        'repeated form field collapses to the last submitted value';
};

subtest 'flatten_array_value(0) keeps the array' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { color => ['red', 'green', 'blue'] },
    );
    is $sp->flatten_array_value(0)->permitted('color'),
        { color => ['red', 'green', 'blue'] },
        'flattening can be turned off';
};

subtest 'namespace scopes the rules under a key' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { 'person.name' => 'John', 'person.age' => '52', other => 'x' },
    );
    is $sp->namespace(['person'])->permitted('name', 'age'),
        { name => 'John', age => '52' },
        'rules resolve under the namespace prefix';
};

subtest 'a leading arrayref is a namespace affix' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { 'person.name' => 'John', 'person.age' => '52' },
    );
    is $sp->permitted(['person'], 'name', 'age'),
        { name => 'John', age => '52' },
        'leading \@namespace affix works without ->namespace';
};

subtest 'empty final index appends to a reconstructed array' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {
            'person.notes[]'                => ['note one', 'note two'],
            'person.person_roles[1].role_id' => '1',
            'person.person_roles[2].role_id' => '2',
            'person.person_roles[].role_id'  => ['3', '4'],
        },
    );
    is $sp->namespace(['person'])->permitted(
        +{ notes => [] },
        +{ person_roles => ['role_id'] },
    ),
    {
        notes        => ['note one', 'note two'],
        person_roles => [
            { role_id => '1' },
            { role_id => '2' },
            { role_id => '3' },
            { role_id => '4' },
        ],
    },
    'empty-index rows are appended after the numbered ones';
};

done_testing;
