use strict;
use warnings;
use utf8;
use PICA::Data qw(pica_parser);
use PICA::Schema;
use Test::More;

my $schema = PICA::Schema->new({ fields => { '021A' => { unique => 1 } } });

sub validate(@) { ## no critic
    my ($schema, $record, $errors, %options) = @_;

    use Data::Dumper; print Dumper([ $schema->check($record) ]);

    my ($message) = map { $_->{message} } @$errors;
    is_deeply $errors, [ $schema->check($record, %options) ], $message;
}

my $record = [ ['021A', undef, a => 'title'] ];
validate $schema, $record, [];

push @$record, ['021A', undef, a => 'title'];
validate $schema, $record, [ { tag => '021A', unique => 1, message => 'field is not repeatable' } ];

$record->[1] = ['003@', undef, 0 => '12345'];
validate $schema, $record, [ { tag => '003@', message => 'unknown field' } ];
validate $schema, $record, [], ignore_unknown_fields => 1;

$schema->{fields}{'003@'} = { unique => 1, subfields => { } };
validate $schema, $record, [ { 
    tag => '003@', 
    subfields => { 
        0 => { message => 'unknown subfield' }
    } } ];
validate $schema, $record, [], ignore_unknown_subfields => 1;

$schema->{fields}{'003@'} = { unique => 1, subfields => { 0 => { unique => 1 } } };
validate $schema, $record, [];

$record->[1] = ['003@', undef, 0 => '12345', 0 => '6789'];
validate $schema, $record, [ { 
    tag => '003@', 
    subfields => { 
        0 => { message => 'subfield is not repeatable', unique => 1 }
    } } ];

# TODO: check fields in level 1 and level 2
# $record = pica_parser( 'Plain' => 't/files/bgb.example' )->next;

done_testing;
