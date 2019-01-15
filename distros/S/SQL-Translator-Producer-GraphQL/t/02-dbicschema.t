use strict;
use Test::More 0.98;
use Test::Snapshot;
use File::Spec;
use lib 't/lib-dbicschema';
use Schema;
use SQL::Translator;

my $dbic_class = 'Schema';
my $t = SQL::Translator->new(
  parser => 'SQL::Translator::Parser::DBIx::Class',
  parser_args => { dbic_schema => $dbic_class->connect },
  producer => 'GraphQL',
);
my $got = $t->translate or die $t->error;
is_deeply_snapshot $got, 'schema';

done_testing;
