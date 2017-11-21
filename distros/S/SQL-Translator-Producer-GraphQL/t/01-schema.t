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

input AuthorCreateInput {
  age: Int!
  message: String!
  name: String
}

input AuthorMutateInput {
  age: Int
  id: Int!
  message: String
  name: String
}

input AuthorSearchInput {
  age: Int
  message: String
  name: String
}

type Module {
  author: Author
  author_id: Int
  id: Int!
  name: String
}

input ModuleCreateInput {
  author_id: Int
  name: String
}

input ModuleMutateInput {
  author_id: Int
  id: Int!
  name: String
}

input ModuleSearchInput {
  author_id: Int
  name: String
}

type Mutation {
  createAuthor(input: [AuthorCreateInput!]!): [Author]
  createModule(input: [ModuleCreateInput!]!): [Module]
  deleteAuthor(input: [AuthorMutateInput!]!): [Boolean]
  deleteModule(input: [ModuleMutateInput!]!): [Boolean]
  updateAuthor(input: [AuthorMutateInput!]!): [Author]
  updateModule(input: [ModuleMutateInput!]!): [Module]
}

type Query {
  author(id: [Int!]!): [Author]
  module(id: [Int!]!): [Module]
  # input to search
  searchAuthor(input: AuthorSearchInput!): [Author]
  # input to search
  searchModule(input: ModuleSearchInput!): [Module]
}
