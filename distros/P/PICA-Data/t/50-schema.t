use strict;
use warnings;
use PICA::Data qw(pica_parser);
use PICA::Schema;
use PICA::Schema::Error;
use Test::More;
use YAML::Tiny;
use Test::Deep;

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

done_testing;
