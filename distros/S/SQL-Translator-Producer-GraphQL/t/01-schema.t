use strict;
use Test::More 0.98;

use SQL::Translator;
use File::Spec;

my $expected = join '', <DATA>;

sub do_test {
  my ($parser) = @_;
  my $t = SQL::Translator->new();
  $t->parser($parser);
  $t->filename(File::Spec->catfile('t', 'schema', lc "$parser.sql")) or die $t->error;
  $t->producer('GraphQL');
  my $result = $t->translate or die $t->error;
  #open my $fh, '>', 'tf'; print $fh $result; # uncomment to regenerate
  is $result, $expected, $parser;
}

for my $type (qw(MySQL SQLite)) {
  subtest $type => sub {
    do_test($type);
  };
}

done_testing;

__DATA__
type Author {
  age: Int!
  get_module: [Module]
  id: Int!
  message: String!
  name: String
}

input AuthorInput {
  age: Int!
  message: String!
  name: String
}

scalar DateTime

type Module {
  author: Author
  author_id: Int
  id: Int!
  name: String
}

input ModuleInput {
  author_id: Int
  name: String
}

type Mutation {
  createAuthor(input: AuthorInput!): Author
  createModule(input: ModuleInput!): Module
  deleteAuthor(id: Int!): Boolean
  deleteModule(id: Int!): Boolean
  updateAuthor(id: Int!, input: AuthorInput!): Author
  updateModule(id: Int!, input: ModuleInput!): Module
}

type Query {
  author(id: [Int!]!): [Author]
  module(id: [Int!]!): [Module]
  # list of ORs each of which is list of ANDs
  searchAuthor(input: [[AuthorInput!]!]!): [Author]
  # list of ORs each of which is list of ANDs
  searchModule(input: [[ModuleInput!]!]!): [Module]
}
