
use strict;
use warnings;

use Test::More 0.96 tests => 1;

{

  package Model;
  use Moose;
  use MooseX::AttributeIndexes;
  use MooseX::Types::Moose qw( :all );

  has id => (
    isa           => Int,
    is            => 'rw',
    lazy_build    => 1,
    primary_index => 1,
  );

  has name => (
    isa      => Str,
    is       => 'rw',
    required => 1,
    indexed  => 1,
  );

  has password => (
    isa      => Str,
    is       => 'rw',
    required => 1,
  );

  my $idn = 0;

  sub _build_id {
    ++$idn;
  }

  __PACKAGE__->meta->make_immutable;

}

use Search::GIN::Extract::AttributeIndexes;

my $extractor = Search::GIN::Extract::AttributeIndexes->new();

my @testlist;

push @testlist, Model->new( name => 'Bob',   password => 'z7Gm@^wq' );
push @testlist, Model->new( name => 'Sue',   password => 'W-M}-wal' );
push @testlist, Model->new( name => 'Bruce', password => q(4%ugdLmQX9']n_cK{,aD"A{bebXS+]) );

my @outlist;

for (@testlist) {
  push @outlist, sort { $a cmp $b } $extractor->extract_values($_);
}

use Data::Dump qw( dump );
is_deeply( \@outlist, [ 'id:1', 'name:Bob', 'id:2', 'name:Sue', 'id:3', 'name:Bruce' ], 'Proper Key Extraction' );

