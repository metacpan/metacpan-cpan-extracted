use strict;
use warnings;
use utf8;
use PICA::Data qw(pica_parser);
use PICA::Schema;
use Test::More;

my $schema = PICA::Schema->new({ fields => { '021A' => { required => 1 } } });

sub validate(@) { ## no critic
    my ($schema, $record, $errors, %options) = @_;

    # note explain [ $schema->check($record) ];

    my ($message) = map { $_->{message} } @$errors;
    is_deeply $errors, [ $schema->check($record, %options) ], $message;
}

my $record = [ ['021A', undef, a => 'title'] ];
validate $schema, $record, [];

push @$record, ['021A', undef, a => 'title'];
validate $schema, $record,
    [ { tag => '021A', repeated => 1, message => 'field 021A is not repeatable' } ];

$record->[1] = ['003@', undef, 0 => '12345'];
validate $schema, $record, [ { tag => '003@', message => 'unknown field 003@' } ];
validate $schema, $record, [], ignore_unknown_fields => 1;

$schema->{fields}{'003@'} = { subfields => { } };
validate $schema, $record, [ { 
    tag => '003@', 
    subfields => { 
        0 => { message => 'unknown subfield 003@$0', code => '0' }
    } } ];
validate $schema, $record, [], ignore_unknown_subfields => 1;

$schema->{fields}{'003@'} = {
    subfields => { 0 => { required => 1 } }
};
validate $schema, $record, [];

$record->[1] = ['003@', undef, 0 => '12345', 0 => '6789'];
validate $schema, $record, [ { 
    tag => '003@', 
    subfields => { 
        0 => {
            message => 'subfield 003@$0 is not repeatable',
            repeated => 1,
            code => '0',
        }
    } } ];

$record->[1] = ['003@', '', x => 1 ];
validate $schema, $record, [ { 
    tag => '003@', 
    subfields => { 
        0 => {
            message => 'missing subfield 003@$0',
            required => 1,
            code => '0',
        }
    } } ], ignore_unknown_subfields => 1;

validate $schema, [], [ {
    tag => '021A', 
    required => 1,
    message => 'missing field 021A',
}];

# TODO:
# - check fields in level 1 and level 2 (uniqueness per local copy!)
# $record = pica_parser( 'Plain' => 't/files/bgb.example' )->next;

done_testing;
