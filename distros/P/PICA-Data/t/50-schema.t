use strict;
use warnings;
use PICA::Data qw(pica_parser);
use PICA::Schema qw(field_identifier);
use PICA::Schema::Error;
use Test::More;
use YAML::Tiny;
use Test::Deep;

is field_identifier(['003@']), '003@', 'field_identifer (003@)';
is field_identifier(['012A', '01']), '012A/01', 'field_identifer (012A/01)';
is field_identifier(['209A', '01']), '209A', 'field_identifer (209A/XX)';

my $tests = YAML::Tiny->read('t/files/schema-tests.yaml')->[0];

my %records = map {
        ($_ => pica_parser('plain', fh => \($tests->{records}{$_}) )->next())
    } keys %{$tests->{records}};
my %schemas = map {
        $_ => PICA::Schema->new($tests->{schemas}{$_})
    } keys %{$tests->{schemas}};

foreach (@{$tests->{tests}}) {
    my $schema = $schemas{$_->{schema}};
    my $record = $records{$_->{record}};

    my @errors = $schema->check($record, %{$_->{options} || {}});
    my @expect = @{$_->{errors} || []};
    bless $_, 'PICA::Schema::Error' for @expect;
    if ( !cmp_deeply \@errors, \@expect, $_->{check} ) {
        note explain $_ for @errors;
    }
}

my $record = pica_parser('plain', fh => 't/files/bgb.example')->next;
my $schema = PICA::Schema->new({});
is scalar($schema->check($record)), 67, "report errors only once";

done_testing;
